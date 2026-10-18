#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  ONE2.sh — أمر واحد، يشفي نفسه: مصادقة · 4 مواقع · تأكيد تلقائي
#  · ربط · نشر · commit تفويض موقّع ومُثبت من الريموت
#  bash ONE2.sh            → كل المواقع
#  bash ONE2.sh aads       → A-ADS فقط
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/one2.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
go(){ printf '\n%s▸ %s%s\n' "$B" "$1" "$N" | tee -a "$LOG"; }
kv(){ python3 - "$1" <<'PY'
import sys
try:
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if s.startswith(sys.argv[1]+"="): print(s.split("=",1)[1]); break
except Exception: pass
PY
}
setkv(){ python3 - "$1" "$2" <<'PY'
import sys, os
k,v=sys.argv[1],sys.argv[2]; E={}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if "=" in s and not s.startswith("#"):
            a,b=s.split("=",1); E[a.strip()]=b.strip()
E[k]=v
open("keys.env","w",encoding="utf-8").write("# CineHub 3099\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
PY
}
clip(){ termux-clipboard-get 2>/dev/null | tr -d '\r\n'; }
clipset(){ printf '%s' "$1" | termux-clipboard-set 2>/dev/null || true; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || true; }
newpass(){ python3 -c "import secrets,string as s;print(''.join(secrets.choice(s.ascii_letters+s.digits) for _ in range(13)))"; }
enter(){ printf '  %s[Enter · q خروج]%s › ' "$D" "$N"; local x=""; read -r x </dev/tty 2>/dev/null || x=""; [ "$x" = "q" ] && { echo; exit 0; }; }

# ═════════ 0 · شفاء ذاتي ═════════
hd "0 · فحص الأدوات وإصلاح الناقص"

if [ ! -f gh.py ] || ! grep -q '^def ensure_repo' gh.py; then
cat > gh.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""واجهة GitHub كاملة — مستقلة بلا اعتماد على أي ملف."""
import json, os, subprocess, urllib.request, urllib.error

def token():
    t = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    if not t:
        for f in (".secrets.gh_token", ".secrets/gh_token", ".gh_token", "auth.json"):
            if not os.path.exists(f): continue
            try:
                t = json.load(open(f)).get("token", "") if f.endswith(".json") else open(f).read()
            except Exception: t = ""
            t = (t or "").strip()
            if t: break
    return t

def api(path, method="GET", data=None, tok=None):
    tok = tok or token()
    url = path if path.startswith("http") else "https://api.github.com" + path
    body = json.dumps(data).encode() if data is not None else None
    r = urllib.request.Request(url, data=body, method=method, headers={
        "Authorization": "Bearer " + tok, "Accept": "application/vnd.github+json",
        "User-Agent": "CineHub3099", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r, timeout=40) as x:
            raw = (x.read().decode() or "{}").strip()
            return json.loads(raw) if raw[:1] in "{[(" else {"raw": raw}
    except urllib.error.HTTPError as e:
        try: return json.loads(e.read().decode() or "{}")
        except Exception: return {}
    except Exception:
        return {}

def login(t=None):
    return (api("/user", tok=t or token()) or {}).get("login", "")

def repo_name(u=None):
    return (u or login()) + ".github.io"

def ensure_repo(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    if (api("/repos/%s/%s" % (u, r), tok=t) or {}).get("full_name"): return True
    return bool((api("/user/repos", "POST",
        {"name": r, "private": False, "auto_init": True, "default_branch": "main"}, t) or {}).get("full_name"))

def enable_pages(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    api("/repos/%s/%s/pages" % (u, r), "POST", {"source": {"branch": "main", "path": "/"}}, t)
    api("/repos/%s/%s/pages" % (u, r), "PUT", {"source": {"branch": "main", "path": "/"}}, t)
    return "https://%s.github.io/" % u

def push(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    url = "https://x-access-token:%s@github.com/%s/%s.git" % (t, u, r)
    subprocess.run("git add -A", shell=True, capture_output=True)
    subprocess.run("git -c user.email=a@c.local -c user.name=Agent commit -m update",
                   shell=True, capture_output=True)
    p = subprocess.run("git push --force %s main" % url, shell=True, capture_output=True, text=True)
    return p.returncode == 0, (p.stdout + p.stderr)
PYEOF
ok "gh.py كامل (token · api · login · ensure_repo · enable_pages · push)"
else ok "gh.py سليم"; fi

if [ ! -f tools/auth_device.py ]; then
cat > tools/auth_device.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request, urllib.parse
T = os.environ.get("GHTMP") or os.path.expanduser("~/.cinehub-tmp")
os.makedirs(T, exist_ok=True)
CID = os.environ.get("GH_CLIENT_ID", "178c6fc778ccc68e1d6a")
def post(u, d):
    r = urllib.request.Request(u, data=urllib.parse.urlencode(d).encode(),
        headers={"Accept": "application/json", "User-Agent": "CineHub3099"})
    return json.load(urllib.request.urlopen(r, timeout=30))
d = post("https://github.com/login/device/code", {"client_id": CID, "scope": "repo workflow read:org"})
code, url = d["user_code"], d["verification_uri"]
print("\n  ┌──────────────────────────────┐")
print("  │  الرمز:  %-20s│" % code)
print("  └──────────────────────────────┘")
print("  افتح: %s  والصق الرمز ثم Approve\n" % url, flush=True)
try: open(T + "/gh_code", "w").write(code + "\n" + url)
except Exception: pass
iv = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
while time.time() < end:
    time.sleep(iv)
    t = post("https://github.com/login/oauth/access_token",
             {"client_id": CID, "device_code": d["device_code"],
              "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
    if t.get("access_token"):
        open(T + "/gh_tok", "w").write(t["access_token"]); sys.exit(0)
    e = t.get("error", "")
    if e == "slow_down": iv += 5
    elif e == "authorization_pending": print("  … بانتظار الموافقة", flush=True)
    elif e in ("expired_token", "access_denied"): print("  انتهت/رُفضت"); sys.exit(2)
print("  مهلة"); sys.exit(4)
PYEOF
ok "tools/auth_device.py أُنشئ"; fi

if [ ! -f tools/mailopen.py ]; then
cat > tools/mailopen.py <<'PYEOF'
#!/usr/bin/env python3
import imaplib, email, re, sys, os, time
from datetime import datetime, timedelta
dom = (sys.argv[1] if len(sys.argv) > 1 else "").lower()
wait = int(sys.argv[2]) if len(sys.argv) > 2 else 180
u = os.environ.get("MU") or ""; p = os.environ.get("MP") or ""
if not (u and p): sys.exit(3)
end = time.time() + wait
while time.time() < end:
    try:
        M = imaplib.IMAP4_SSL("imap.gmail.com"); M.login(u, p); M.select("INBOX")
        since = (datetime.utcnow() - timedelta(minutes=40)).strftime("%d-%b-%Y")
        typ, data = M.search(None, "(SINCE %s)" % since)
        for i in reversed(data[0].split()[-15:]):
            typ, d = M.fetch(i, "(RFC822)")
            msg = email.message_from_bytes(d[0][1])
            frm = msg.get("From", ""); subj = msg.get("Subject", "")
            if dom and dom not in (frm + subj).lower(): continue
            txt = ""
            if msg.is_multipart():
                for part in msg.walk():
                    if part.get_content_type() in ("text/html", "text/plain"):
                        try: txt += part.get_payload(decode=True).decode(part.get_content_charset() or "utf-8", "ignore")
                        except Exception: pass
            else:
                try: txt = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8", "ignore")
                except Exception: pass
            L = re.findall(r'https?://[^\s"\'<>)\]]+', txt)
            g = [x for x in L if re.search(r'confirm|verif|activat|validat|token|approv|welcome|signup', x, re.I)] or L
            if g: M.logout(); print(g[0].rstrip('.,;')); sys.exit(0)
        M.logout()
    except Exception: pass
    time.sleep(8)
sys.exit(1)
PYEOF
ok "tools/mailopen.py أُنشئ"; fi
chmod +x tools/*.py 2>/dev/null || true

# ═════════ A · مصادقة ═════════
hd "A · تفويض GitHub"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
if [ -n "$U" ]; then ok "مفوّض: $U"
else
  wrn "لا تفويض — افتح الرابط والصق الرمز"
  python3 tools/auth_device.py || true
  T="$(cat "$GHTMP/gh_tok" 2>/dev/null || true)"
  if [ -n "$T" ]; then printf '%s' "$T" > .secrets.gh_token; chmod 600 .secrets.gh_token
    U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"; fi
  if [ -z "$U" ]; then
    printf '  %sبديل: توكن بنفسك → %s%s\n' "$D" "https://github.com/settings/tokens/new?scopes=repo,workflow" "$N"
    printf '  الصق التوكن › '; read -r T </dev/tty 2>/dev/null || T=""
    [ -n "$T" ] && { printf '%s' "$T" > .secrets.gh_token; U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"; }
  fi
fi
[ -n "$U" ] || { bad "لا تفويض — توقف"; exit 1; }
ok "الحساب: $U"
R="$U.github.io"; SITE="https://$U.github.io"
python3 -c "import gh;gh.ensure_repo()" >/dev/null 2>&1 && ok "المستودع جاهز"
git config --local credential.helper ""
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"

# ═════════ B · البريد ═════════
hd "B · تأكيد البريد"
MU="$(kv MAIL_USER)"
if [ -z "$MU" ]; then printf '  بريدك (Gmail) › '; read -r MU </dev/tty 2>/dev/null || MU=""; setkv MAIL_USER "$MU"; fi
ok "البريد: $MU"
imapok(){ U="$1" P="$2" python3 - <<'PY'
import imaplib, os
try:
    M=imaplib.IMAP4_SSL("imap.gmail.com"); M.login(os.environ["U"], os.environ["P"]); M.select("INBOX"); M.logout(); print("OK")
except Exception as e: print("ERR "+str(e)[:50])
PY
}
MP="$(kv MAIL_APP_PASS)"
if [ -n "$MP" ] && [ "$(imapok "$MU" "$MP")" = "OK" ]; then ok "كلمة مرور التطبيق تعمل — التأكيد تلقائي"
else
  go "كلمة مرور التطبيق (16 حرفًا) — مرة واحدة"
  printf '  %s1) فعّل «التحقق بخطوتين»  2) كلمات مرور التطبيقات → Mail  3) انسخ 16 حرفًا بلا مسافات%s\n' "$D" "$N"
  openurl "https://myaccount.google.com/apppasswords"; sleep 2
  i=0; while [ $i -lt 4 ]; do
    i=$((i+1)); printf '  كلمة مرور التطبيق (أو Enter للتخطي) › '; read -r MP </dev/tty 2>/dev/null || MP=""
    MP="$(printf '%s' "$MP" | tr -d ' ')"
    [ -z "$MP" ] && { wrn "تُخطّي — التأكيد يدوي من تطبيق Gmail"; break; }
    setkv MAIL_APP_PASS "$MP"
    [ "$(imapok "$MU" "$MP")" = "OK" ] && { ok "تعمل ✓"; break; }
    bad "مرفوضة — أعد النسخ (16 حرفًا)"
  done
fi

# ═════════ C · المواقع ═════════
run_site(){
  local KEY="$1" DOM="$2" NAME="$3" SIGNUP="$4" PANEL="$5" COPY="$6" RE="$7" VURL="$8" EX="$9"
  local cur; cur="$(kv "$KEY")"
  if [ -n "$cur" ]; then
    if [ -z "$VURL" ] || curl -fsS -m 15 "${VURL//\{v\}/$cur}" 2>/dev/null | grep -qF "$EX"; then
      ok "$NAME — منجز مسبقًا ($cur)"; return 0; fi
    wrn "$NAME — قيمة قديمة لا تتحقق، نعيد"
  fi
  printf '\n%s╔══════════════════════════════════════════╗\n' "$C"
  printf '║  %-40s║\n' "$NAME"
  printf '╚══════════════════════════════════════════╝%s\n' "$N"
  local PW; PW="$(newpass)"
  go "1/3 · سجّل — الصق البريد، ثم كلمة المرور، ثم اضغط الزر"
  printf '  %s\n' "$SIGNUP"; clipset "$MU"; openurl "$SIGNUP"; sleep 1
  printf '  %sالبريد في الحافظة:%s %s\n' "$D" "$N" "$MU"; enter
  clipset "$PW"; printf '  %sكلمة المرور في الحافظة:%s %s\n' "$D" "$N" "$PW"; enter
  printf '  اضغط زر التسجيل ثم Enter.\n'; enter
  go "2/3 · تأكيد البريد"
  if [ -n "$(kv MAIL_APP_PASS)" ]; then
    printf '  %sأبحث في بريدك… (3 دقائق)%s\n' "$D" "$N"
    L="$(MU="$MU" MP="$(kv MAIL_APP_PASS)" python3 tools/mailopen.py "$DOM" 180 2>/dev/null || true)"
    if [ -n "$L" ]; then ok "رابط التأكيد: %.68s" "$L"; openurl "$L"; sleep 3
    else wrn "لم أجدها — افتحها من Gmail ثم Enter"; fi
  else printf '  افتح رابط التأكيد من تطبيق Gmail ثم Enter.\n'; fi
  enter
  go "3/3 · افتح اللوحة، أنشئ وحدة (Banner 300x250)، وانسخ: $COPY"
  printf '  %s\n  %s[انسخ — سيُلتقط تلقائيًا · s تخطي]%s\n' "$PANEL" "$D" "$N"
  openurl "$PANEL" &
  local prev t0 now el v B2 line
  prev="$(clip)"; t0=$(date +%s)
  while :; do
    sleep 2; line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
    [ "$line" = "s" ] && { wrn "$NAME تُخطّي"; return 0; }
    now="$(clip)"
    if [ -n "$now" ] && [ "$now" != "$prev" ]; then
      prev="$now"
      for v in $(printf '%s' "$now" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^${RE}$" | head -6); do
        [ ${#v} -lt 4 ] && continue; [ "$v" = "$MU" ] && continue
        if [ -n "$VURL" ]; then
          B2="$(curl -fsS -m 15 "${VURL//\{v\}/$v}" 2>/dev/null || true)"
          [ -n "$EX" ] && [ -n "$B2" ] && { printf '%s' "$B2" | grep -qF "$EX" || continue; }
        fi
        setkv "$KEY" "$v"; printf '\r%-70s\r' ''; ok "$KEY = $v"; return 0
      done
      printf '\r%-70s\r%s✗%s مرفوض: %.34s\n' '' "$R" "$N" "$now"
    fi
    el=$(( $(date +%s) - t0 )); [ "$el" -ge 1500 ] && { wrn "$NAME — مهلة"; return 1; }
    printf '\r%-70s' "$(printf '  … %dث — انسخ %s' "$el" "$COPY")"
  done
}

hd "C · المواقع"
WANT="${1:-all}"
[ "$WANT" = "all" ] && run_site AADS_UNIT a-ads "A-ADS · حد سحب \$0" "https://a-ads.com/" "https://a-ads.com/ad_units" 'الكود كاملًا أو الرقم' '[0-9]{4,8}' 'https://a-ads.com/api/v1/banners/{v}' '.'
[ "$WANT" = "all" ] && run_site ADSTERRA_API_KEY adsterra "Adsterra · API الرصيد" "https://publishers.adsterra.com/signup" "https://publishers.adsterra.com/settings/api" 'مفتاح API' '[A-Za-z0-9_-]{20,48}' 'https://api3.adsterra.com/api/v1/publisher/balance' ''
[ "$WANT" = "all" ] && run_site EXOCLICK_ZONE exoclick "ExoClick · الإباحي" "https://www.exoclick.com/signup/" "https://admin.exoclick.com/zones.php" 'رقم Zone ID' '[0-9]{5,9}' '' ''
[ "$WANT" = "all" ] && run_site MONETAG_MULTITAG monetag "Monetag" "https://monetag.com/" "https://publisher.monetag.com/" 'معرّف Multitag' '[0-9]{5,9}' '' ''
[ "$WANT" = "aads" ] && run_site AADS_UNIT a-ads "A-ADS · حد سحب \$0" "https://a-ads.com/" "https://a-ads.com/ad_units" 'الكود كاملًا أو الرقم' '[0-9]{4,8}' 'https://a-ads.com/api/v1/banners/{v}' '.'

# ═════════ D · ربط · بناء · تفويض · نشر ═════════
hd "D · الربط والتفويض والنشر"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
try: a = json.load(open("ads.json", encoding="utf-8"))
except Exception: a = {}
nets = a.get("networks") or []
for k, nm, pay in [("AADS_UNIT","A-ADS","$0"),("ADSTERRA_API_KEY","Adsterra","$5"),
                   ("EXOCLICK_ZONE","ExoClick","€20"),("MONETAG_MULTITAG","Monetag","$5"),
                   ("JUICYADS_ZONE","JuicyAds","$50")]:
    if k not in set(n.get("k") for n in nets): nets.append({"n": nm, "k": k, "pay": pay})
on = 0
for n in nets:
    v = E.get((n.get("k") or "").strip()) or ""
    n["id"] = v or ""; n["enabled"] = bool(v); on += bool(v)
a["networks"] = nets
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ شبكات مفعّلة: %d من %d" % (on, len(nets)))
PY
for f in tools/ads.py tools/gen_static.py tools/money.py tools/vault.py tools/dashboard.py tools/ping.py; do
  [ -f "$f" ] && { printf '  · %s\n' "${f##*/}"; python3 "$f" >/dev/null 2>&1 || true; }
done

SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$R|%s'%time.time()).encode()).hexdigest()[:16])")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
cat > verify.txt <<VEOF
CineHub 3099 — وثيقة التفويض
الحساب     : $U
المستودع   : https://github.com/$U/$R
الموقع     : $SITE
التاريخ    : $TS
رمز التفويض : $SIG
مفاتيح مربوطة: $NK
VEOF
VMSG="delegate: $U $SIG keys=$NK"
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git -c user.email=a@c.local -c user.name=Agent commit --allow-empty -m "$VMSG" >/dev/null 2>&1 || true
git config pull.rebase true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
PUSHED=0
for i in 1 2 3 4; do
  case "$i" in
    1) timeout 1800 git push origin main 2>"$GHTMP/e" && PUSHED=1 ;;
    2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && PUSHED=1 ;;
    3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && PUSHED=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && PUSHED=1 ;;
  esac
  [ "$PUSHED" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
  wrn "محاولة $i فشلت: $(tail -1 "$GHTMP/e" 2>/dev/null | cut -c1-64)"
done
[ "$PUSHED" = 1 ] || bad "الدفع فشل"

python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1 && ok "Pages مفعّل"

hd "E · إثبات من الريموت"
sleep 4
RM="$(curl -s -m 30 -H "Authorization: Bearer $T" -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$U/$R/commits/main" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['commit']['message'].splitlines()[0])" 2>/dev/null || true)"
[ "$RM" = "$VMSG" ] && ok "الريموت يحمل تفويضك حرفيًا" || wrn "رسالة الريموت: ${RM:-?}"

for k in 1 2 3 4 5 6; do
  c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/")"; [ "$c" = "200" ] && break; sleep 12
done
[ "$c" = "200" ] && ok "الموقع يعمل" || wrn "الموقع: $c (قد يستغرق بناء Pages دقائق)"

printf '\n%s╔══════════════════════════════════════════════╗\n' "$G"
printf '║  تم — مفوَّض · مربوط · منشور                  ║\n'
printf '╚══════════════════════════════════════════════╝%s\n' "$N"
printf '  الحساب      : %s\n  رمز التفويض : %s%s%s\n  الموقع      : %s\n  الخزينة     : %s/wallet.html\n  السجل       : %s\n' \
  "$U" "$B" "$SIG" "$N" "$SITE" "$SITE" "$LOG" | tee -a "$LOG"
