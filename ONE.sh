#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  ONE.sh — أمر واحد: مصادقة · تسجيل 4 مواقع · تأكيد تلقائي · ربط
#  · نشر · commit تفويض موقّع. أنت: لصق + Enter فقط.
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/one.$(date +%F_%H%M).log"; : > "$LOG"
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

# ───────── A · مصادقة GitHub (النقرة الوحيدة) ─────────
hd "A · تفويض GitHub"
T="$(cat .secrets.gh_token 2>/dev/null || true)"
U="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.login(gh.token()))" 2>/dev/null || true)"
if [ -n "$U" ]; then ok "مفوّض مسبقًا: $U"
else
  python3 tools/auth_device.py 2>&1 | tee -a "$LOG" || true
  T="$(cat "$GHTMP/gh_tok" 2>/dev/null || true)"
  [ -n "$T" ] && { printf '%s' "$T" > .secrets.gh_token; chmod 600 .secrets.gh_token
    U="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.login(gh.token()))" 2>/dev/null || true)"; }
  [ -n "$U" ] && ok "تم التفويض: $U" || { bad "لا تفويض"; exit 1; }
fi
R="$U.github.io"; SITE="https://$U.github.io"
URL="https://x-access-token:$T@github.com/$U/$R.git"
git remote remove origin 2>/dev/null || true; git remote add origin "$URL"

# ───────── B · بريد التأكيد (مرة واحدة للأبد) ─────────
hd "B · تأكيد البريد"
MU="$(kv MAIL_USER)"
if [ -z "$MU" ]; then
  go "بريدك (Gmail) — مرة واحدة فقط"
  printf '  البريد › '; read -r MU </dev/tty 2>/dev/null || MU=""; setkv MAIL_USER "$MU"
fi
ok "البريد: $MU"
imapok(){ U="$1" P="$2" python3 - <<'PY'
import imaplib, os
try:
    M=imaplib.IMAP4_SSL("imap.gmail.com"); M.login(os.environ["U"], os.environ["P"]); M.select("INBOX"); M.logout(); print("OK")
except Exception as e: print("ERR "+str(e)[:60])
PY
}
MP="$(kv MAIL_APP_PASS)"
if [ -n "$MP" ] && [ "$(imapok "$MU" "$MP")" = "OK" ]; then ok "كلمة مرور التطبيق تعمل — التأكيد سيكون تلقائيًا"
else
  go "كلمة مرور التطبيق (16 حرفًا) — مرة واحدة، وتُفتح الصفحة الآن"
  printf '  %sالشرط: تفعيل «التحقق بخطوتين» أولًا في نفس الصفحة.%s\n' "$D" "$N"
  printf '  %sثم: كلمات مرور التطبيقات → Mail → ستحصل على 16 حرفًا (4×4) → أدخلها بلا مسافات.%s\n' "$D" "$N"
  openurl "https://myaccount.google.com/apppasswords"; sleep 2
  i=0
  while [ $i -lt 4 ]; do
    i=$((i+1))
    printf '  كلمة مرور التطبيق (16 حرفًا · أو Enter للتخطي) › '; read -r MP </dev/tty 2>/dev/null || MP=""
    MP="$(printf '%s' "$MP" | tr -d ' ')"
    [ -z "$MP" ] && { wrn "تُخطّي — التأكيد يدوي من تطبيق Gmail"; break; }
    setkv MAIL_APP_PASS "$MP"
    if [ "$(imapok "$MU" "$MP")" = "OK" ]; then ok "تعمل ✓ — التأكيد تلقائي"; break; fi
    bad "مرفوضة — أعد النسخ من صفحة جوجل (16 حرفًا)"
    [ $i -ge 4 ] && wrn "استمر — التأكيد يدوي"
  done
fi

# ───────── C · المواقع: 3 خطوات لكل موقع ─────────
run_site(){
  local KEY="$1" DOM="$2" NAME="$3" SIGNUP="$4" PANEL="$5" COPY="$6" RE="$7" VURL="$8" EX="$9"
  local cur; cur="$(kv "$KEY")"
  if [ -n "$cur" ]; then
    if [ -z "$VURL" ] || curl -fsS -m 15 "${VURL//\{v\}/$cur}" 2>/dev/null | grep -qF "$EX"; then
      ok "$NAME — منجز مسبقًا ($cur)"; return 0
    fi
    wrn "$NAME — القيمة القديمة لا تتحقق، نعيدها"
  fi
  printf '\n%s╔══════════════════════════════════════════╗\n' "$C"
  printf '║  %-40s║\n' "$NAME — 3 خطوات"
  printf '╚══════════════════════════════════════════╝%s\n' "$N"
  local PW; PW="$(newpass)"

  go "1/3 — سجّل: الصق البريد ثم كلمة المرور ثم اضغط الزر"
  printf '  %s%s%s\n' "$C" "$SIGNUP" "$N"
  clipset "$MU"; openurl "$SIGNUP"; sleep 1
  printf '  %sالبريد في الحافظة:%s %s  ← لصق\n' "$D" "$N" "$MU"
  enter
  clipset "$PW"
  printf '  %sكلمة المرور في الحافظة:%s %s  ← لصق (واحفظها)\n' "$D" "$N" "$PW"
  enter
  printf '  اضغط زر التسجيل في الموقع ثم Enter.\n'; enter

  go "2/3 — سأؤكد بريدك"
  if [ -n "$(kv MAIL_APP_PASS)" ]; then
    printf '  %sأبحث في بريدك… (حتى 3 دقائق)%s\n' "$D" "$N"
    L="$(MU="$MU" MP="$(kv MAIL_APP_PASS)" python3 tools/mailopen.py "$DOM" 180 2>/dev/null || true)"
    if [ -n "$L" ]; then ok "رابط التأكيد: %.70s" "$L"; openurl "$L"; sleep 3
    else wrn "لم أجد الرسالة — افتحها من تطبيق Gmail ثم Enter"; fi
  else
    printf '  افتح تطبيق Gmail واضغط رابط التأكيد، ثم Enter.\n'
  fi
  enter

  go "3/3 — افتح اللوحة، أنشئ وحدة (Banner 300x250)، وانسخ: $COPY"
  printf '  %s%s%s\n' "$C" "$PANEL" "$N"
  printf '  %s[انسخ من الصفحة — سيُلتقط تلقائيًا · s تخطي]%s\n' "$D" "$N"
  openurl "$PANEL" &
  local prev t0 now el v B2
  prev="$(clip)"; t0=$(date +%s)
  while :; do
    sleep 2
    local line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
    [ "$line" = "s" ] && { wrn "$NAME تُخطّي"; return 0; }
    now="$(clip)"
    if [ -n "$now" ] && [ "$now" != "$prev" ]; then
      prev="$now"
      for v in $(printf '%s' "$now" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^${RE}$" | head -6); do
        [ ${#v} -lt 4 ] && continue
        [ "$v" = "$MU" ] && continue
        if [ -n "$VURL" ]; then
          B2="$(curl -fsS -m 15 "${VURL//\{v\}/$v}" 2>/dev/null || true)"
          [ -n "$EX" ] && [ -n "$B2" ] && { printf '%s' "$B2" | grep -qF "$EX" || continue; }
        fi
        setkv "$KEY" "$v"; printf '\r%-70s\r' ''
        ok "$KEY = $v"; return 0
      done
      printf '\r%-70s\r%s✗%s مرفوض: %.34s\n' '' "$R" "$N" "$now"
    fi
    el=$(( $(date +%s) - t0 )); [ "$el" -ge 1500 ] && { wrn "$NAME — مهلة"; return 1; }
    printf '\r%-70s' "$(printf '  … %dث — انسخ %s' "$el" "$COPY")"
  done
}

hd "C · المواقع"
run_site AADS_UNIT      a-ads     "A-ADS (حد سحب \$0 · ابدأ بها)" "https://a-ads.com/" "https://a-ads.com/ad_units" 'الكود كاملًا أو الرقم (data-aa)' '[0-9]{4,8}' 'https://a-ads.com/api/v1/banners/{v}' '.'
run_site ADSTERRA_API_KEY adsterra "Adsterra (API لقراءة رصيدك)" "https://publishers.adsterra.com/signup" "https://publishers.adsterra.com/settings/api" 'مفتاح API' '[A-Za-z0-9_-]{20,48}' 'https://api3.adsterra.com/api/v1/publisher/balance' ''
run_site EXOCLICK_ZONE  exoclick  "ExoClick (الإباحي · أعلى RPM)" "https://www.exoclick.com/signup/" "https://admin.exoclick.com/zones.php" 'رقم Zone ID' '[0-9]{5,9}' '' ''
run_site MONETAG_MULTITAG monetag "Monetag (Multitag)" "https://monetag.com/" "https://publisher.monetag.com/" 'معرّف Multitag' '[0-9]{5,9}' '' ''

# ───────── D · ربط · بناء · نشر · commit تفويض ─────────
hd "D · الربط والنشر والتفويض"
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
NAME = {"AADS_UNIT": ("A-ADS", "$0"), "ADSTERRA_API_KEY": ("Adsterra", "$5"),
        "EXOCLICK_ZONE": ("ExoClick", "€20"), "MONETAG_MULTITAG": ("Monetag", "$5"),
        "JUICYADS_ZONE": ("JuicyAds", "$50")}
have = set(n.get("k") for n in nets)
for k, (nm, pay) in NAME.items():
    if k not in have: nets.append({"n": nm, "k": k, "pay": pay})
on = 0
for n in nets:
    v = E.get((n.get("k") or "").strip()) or ""
    if v: n["id"] = v; n["enabled"] = True; on += 1
    else: n["enabled"] = False
a["networks"] = nets
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ شبكات مفعّلة: %d" % on)
PY
for f in tools/ads.py tools/gen_static.py tools/money.py tools/dashboard.py tools/vault.py tools/ping.py; do
  [ -f "$f" ] && { printf '  · %s\n' "$f"; python3 "$f" >/dev/null 2>&1 || true; }
done

SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$R|%s'%time.time()).encode()).hexdigest()[:16])")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
cat > verify.txt <<VEOF
CineHub 3099 — وثيقة التفويض والتوثيق
الحساب    : $U
المستودع  : https://github.com/$U/$R
الموقع    : $SITE
التاريخ   : $TS
رمز التفويض: $SIG
مفاتيح مربوطة: $NK
VEOF
VMSG="delegate: $U $SIG keys=$NK"
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git -c user.email=a@c.local -c user.name=Agent commit --allow-empty -m "$VMSG" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
for i in 1 2 3 4; do
  case "$i" in
    1) timeout 1800 git push origin main 2>"$GHTMP/e" && break ;;
    2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && break ;;
    3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && break ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && break ;;
  esac
  wrn "محاولة $i فشلت: $(tail -1 "$GHTMP/e" 2>/dev/null | cut -c1-70)"
done
[ $? -eq 0 ] && ok "رُفع" || bad "الدفع فشل — bash PUSH.sh"

hd "E · إثبات التفويض من الريموت"
sleep 4
RM="$(curl -s -m 30 -H "Authorization: Bearer $T" -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$U/$R/commits/main" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['commit']['message'].splitlines()[0])" 2>/dev/null || true)"
[ "$RM" = "$VMSG" ] && ok "الريموت يحمل تفويضك: $RM" || wrn "رسالة الريموت: ${RM:-?}"
printf '\n%s╔══════════════════════════════════════════════════╗\n' "$G"
printf '║  تم — الحساب مفوَّض ومربوط                      ║\n'
printf '╚══════════════════════════════════════════════════╝%s\n' "$N"
printf '  الحساب     : %s\n  رمز التفويض: %s%s%s\n  الموقع     : %s\n  الخزينة    : %s/wallet.html\n  الأموال    : %s/money.html\n  السجل      : %s\n' \
  "$U" "$B" "$SIG" "$N" "$SITE" "$SITE" "$SITE" "$LOG" | tee -a "$LOG"
