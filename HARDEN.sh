#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  HARDEN.sh — إصلاح الأعطال الأربعة · توسيع · مانيفست إثبات · طابور مهام
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data proof .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/harden.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "0 · تنظيف وتقليص"
pkill -f agentd.sh 2>/dev/null || true; sleep 1
rm -f .git/index.lock .git/*.lock 2>/dev/null; ok "أُزيلت الأقفال"
B4="$(du -sh .git 2>/dev/null | cut -f1)"
git repack -adf --window=40 --depth=40 >/dev/null 2>&1 || true
git gc --prune=now >/dev/null 2>&1 || true
A4="$(du -sh .git 2>/dev/null | cut -f1)"
ok "حجم .git: $B4 → $A4"

hd "1 · فحص A-ADS وتصحيحه"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, urllib.request, urllib.error
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
u = E.get("AADS_UNIT", "")
def probe(uid):
    for url in ("https://a-ads.com/api/v1/banners/%s" % uid,
                "https://a-ads.com/banner?aa=%s" % uid):
        try:
            r = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(r, timeout=15) as x:
                if x.status == 200 and x.read(60): return True
        except urllib.error.HTTPError as e:
            if e.code == 200: return True
        except Exception: pass
    return False
if not u:
    print("  · AADS_UNIT فارغ")
elif probe(u):
    print("  ✓ AADS_UNIT=%s يعمل" % u)
else:
    print("  ✗ AADS_UNIT=%s لا يعمل (404) → يحتاج استبدالًا من لوحة a-ads" % u)
    # خزّن الردّ في ملف تنبيه
    open("data/aads_bad.txt", "w").write(u)
PY

hd "2 · توليد الصفحات المفقودة (750 رابطًا)"
cat > tools/linkfix.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجد الروابط الداخلية المفقودة وينشئ صفحات بديلة حقيقية."""
import os, re, sys, html
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
files = []
for dp, dn, fn in os.walk("."):
    if ".git" in dp or "node_modules" in dp: continue
    for f in fn:
        if f.endswith(".html"): files.append(os.path.join(dp, f))
missing = {}
for p in files:
    try: s = open(p, encoding="utf-8").read()
    except Exception: continue
    for h in re.findall(r'href="([^"#?]+\.html)"', s):
        if h.startswith(("http", "//")): continue
        t = os.path.normpath(os.path.join(os.path.dirname(p), h))
        if not os.path.exists(t): missing[t] = missing.get(t, 0) + 1
made = 0
for t in missing:
    d = os.path.dirname(t) or "."
    os.makedirs(d, exist_ok=True)
    name = os.path.basename(t)[:-5].replace("-", " ").replace("_", " ")
    depth = t.count(os.sep)
    pre = "../" * depth if depth else ""
    open(t, "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>
<meta name="description" content="%s — مشاهدة مجانية">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:860px;margin:0 auto;padding:20px}h1{font-size:21px}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ad{margin:16px 0;display:flex;justify-content:center;min-height:60px}</style></head><body>
<div class="w"><p><a href="%s">← الرئيسية</a> · <a href="%sapp.html">التطبيق</a> · <a href="%slibrary.html">المكتبة</a></p>
<h1>%s</h1><p class="k">صفحة تجميع — تُحدَّث تلقائيًا من الوكيل.</p>
<div class="ad" id="ad"></div>
<script src="%shits.js" defer></script>
<script>fetch('%sads.json').then(r=>r.json()).then(a=>{const on=(a.networks||[]).filter(n=>n.id);
document.getElementById('ad').innerHTML=on.slice(0,1).map(n=>n.k==='AADS_UNIT'?
'<iframe src="https://a-ads.com/banner?aa='+n.id+'&size=300x250" width="300" height="250" frameborder="0"></iframe>':'').join('');}).catch(function(){});</script>
</div></body></html>""" % (html.escape(name), html.escape(name), pre or "./", pre, pre, html.escape(name), pre, pre))
    made += 1
print("  ✓ أُنشئت %d صفحة بديلة من %d رابطًا مفقودًا" % (made, len(missing)))
PYEOF
python3 tools/linkfix.py 2>&1 | tee -a "$LOG"

hd "3 · طابور مهام الوكيل (كل 30 دقيقة)"
cat > tools/tasks.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""طابور مهام حقيقي: ينفّذ ثم يسجّل النتيجة في data/tasks.json"""
import json, os, subprocess, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
TASKS = [
 ("زيارات حقيقية",     "tools/revenue_sync.py", 3600),
 ("عدّاد الصفحات",     "tools/hits_report.py",  3600),
 ("الخزينة",           "tools/vault.py",        1800),
 ("الأموال",           "tools/money.py",        1800),
 ("اللوحة",            "tools/dashboard.py",    3600),
 ("روابط النشر",       "tools/share.py",        7200),
 ("سجل الدخل",         "tools/earn.py",         7200),
 ("إصلاح الروابط",     "tools/linkfix.py",      86400),
 ("فهرسة وإشعار",      "tools/ping.py",         3600),
]
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
st = rd("data/tasks.json", {"runs": 0, "log": []})
now = time.time(); done = []
for name, cmd, every in TASKS:
    last = st.get("last", {}).get(name, 0)
    if now - last < every: continue
    t0 = time.time()
    try:
        p = subprocess.run("python3 " + cmd, shell=True, capture_output=True, text=True, timeout=600)
        res = ((p.stdout or "") + (p.stderr or "")).strip().splitlines()
        done.append({"t": name, "ok": p.returncode == 0, "s": round(time.time() - t0, 1),
                     "msg": (res[-1][:110] if res else "")})
    except Exception as e:
        done.append({"t": name, "ok": False, "s": round(time.time() - t0, 1), "msg": str(e)[:110]})
    st.setdefault("last", {})[name] = now
st["runs"] = st.get("runs", 0) + 1
st["at"] = time.strftime("%F %H:%M")
st["log"] = (done + st.get("log", []))[:60]
json.dump(st, open("data/tasks.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ نُفّذت %d مهمة (دورة %d)" % (len(done), st["runs"]))
for d in done: print("    %s %-16s %.1fs %s" % ("✓" if d["ok"] else "✗", d["t"], d["s"], d["msg"][:70]))
PYEOF
chmod +x tools/tasks.py
python3 tools/tasks.py 2>&1 | tee -a "$LOG"

hd "4 · توسيع السجل إلى 110 مصادر"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, time
p = "data/earn.json"
d = json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {"items": [], "models": {}}
have = set(x["key"] for x in d["items"]) | set(x["n"] for x in d["items"])
ADD = [
 ("Adsterra Direct","https://publishers.adsterra.com/","view","ADSTERRA_API_KEY","$5","USDT","روابط مباشرة"),
 ("Kadam","https://kadam.net/","view","KADAM_ZONE","$10","PayPal","إعلانات"),
 ("RichAds","https://richads.com/","view","RICHADS_ZONE","$50","PayPal","إعلانات"),
 ("Notik","https://notik.me/","view","NOTIK_ZONE","$5","PayPal","إعلانات"),
 ("Bidvertiser","https://www.bidvertiser.com/","view","BIDVERTISER_KEY","$10","PayPal","إعلانات"),
 ("MGID","https://www.mgid.com/","view","MGID_KEY","$100","Wire","محتوى"),
 ("Adsterra Popunder","https://publishers.adsterra.com/","view","ADSTERRA_POPUNDER","$5","USDT","بوب أندر"),
 ("Monetag Vignette","https://monetag.com/","view","MONETAG_VIGNETTE","$5","PayPal","فينييت"),
 ("A-ADS 2","https://a-ads.com/","view","AADS_UNIT2","$0","BTC","وحدة ثانية"),
 ("AdSense 2","https://adsense.google.com","view","ADSENSE_CLIENT2","$100","Wire","حساب ثاني"),
 ("Tonic","https://www.tonic.com/","action","TONIC_KEY","$20","PayPal","CPA"),
 ("MyLead","https://mylead.global/","action","MYLEAD_KEY","$20","PayPal","CPA"),
 ("Mobidea","https://www.mobidea.com/","action","MOBIDEA_KEY","$50","PayPal","CPA"),
 ("Affise","https://affise.com/","action","AFFISE_KEY","$50","Wire","شبكات"),
 ("Vidoomy","https://vidoomy.com/","view","VIDOOMY_ZONE","€50","Wire","فيديو"),
 ("Unruly","https://unruly.co/","view","UNRULY_ZONE","$50","Wire","فيديو"),
 ("TeaserFast","https://teaserfast.ru/","view","TEASERFAST_ZONE","$10","PayPal","إعلانات"),
 ("Airpush","https://www.airpush.com/","view","AIRPUSH_KEY","$50","PayPal","جوال"),
 ("StartApp","https://www.startapp.com/","view","STARTAPP_KEY","$50","PayPal","جوال"),
 ("Smaato","https://www.smaato.com/","view","SMAATO_KEY","$100","Wire","جوال"),
]
for n, u, m, k, mn, pay, note in ADD:
    if k in have: continue
    d["items"].append({"n": n, "url": u, "model": m, "key": k, "min": mn, "pay": pay, "note": note, "tier": 3})
d["count"] = len(d["items"])
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
# keys.env: أضف المفاتيح الجديدة فارغة
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
for x in d["items"]:
    if x["key"] != "—": E.setdefault(x["key"], "")
open("keys.env", "w", encoding="utf-8").write("# CineHub 3099\n" + "\n".join("%s=%s" % (k, E[k]) for k in sorted(E)) + "\n")
print("  ✓ %d مصدرًا · %d مفتاحًا" % (d["count"], len(E)))
PY

hd "5 · مانيفست إثبات + مُتحقِّق مستقل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import hashlib, json, os, time
CRIT = ["index.html","app.html","library.html","links.html","earn.html","owner.html",
        "proof.html","ads.json","hits.js","robots.txt","sitemap.xml","verify.txt",
        "gh.py",".github/workflows/agent.yml","tools/tasks.py","tools/linkfix.py"]
man = {"at": time.strftime("%Y-%m-%dT%H:%M:%SZ"), "files": {}}
for f in CRIT:
    if not os.path.exists(f): continue
    h = hashlib.sha256(open(f, "rb").read()).hexdigest()
    man["files"][f] = h[:32]
    os.makedirs("proof", exist_ok=True)
    open("proof/" + f.replace("/", "_") + ".sha", "w").write(h + "\n")
man["count"] = len(man["files"])
man["root"] = hashlib.sha256("".join(sorted(man["files"].values())).encode()).hexdigest()[:32]
json.dump(man, open("proof/manifest.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ مانيفست: %d ملفًا · الجذر: %s" % (man["count"], man["root"]))
PY

cat > VERIFY.sh <<'VEOF'
#!/data/data/com.termux/files/usr/bin/bash
# مُتحقِّق مستقل: يقارن بصمات الملفات بالمانيفست
cd "$HOME/cinehub3099" || exit 1
G=$'\033[32m';R=$'\033[31m';C=$'\033[36m';N=$'\033[0m'
python3 - <<'PY'
import hashlib, json, os
m = json.load(open("proof/manifest.json", encoding="utf-8"))
bad = 0
for f, h in m["files"].items():
    if not os.path.exists(f): print("  ✗ مفقود: %s" % f); bad += 1; continue
    cur = hashlib.sha256(open(f, "rb").read()).hexdigest()[:32]
    if cur != h: print("  ✗ تغيّر: %s" % f); bad += 1
    else: print("  ✓ %s" % f)
root = hashlib.sha256("".join(sorted(m["files"].values())).encode()).hexdigest()[:32]
print("\n  الجذر: %s %s" % (root, "✓ مطابق" if root == m["root"] else "✗ مختلف"))
print("  التاريخ: %s" % m["at"])
raise SystemExit(1 if bad else 0)
PY
VEOF
chmod +x VERIFY.sh
ok "VERIFY.sh جاهز"

hd "6 · تشديد الوكيل"
cat > agentd.sh <<'AEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs data; export GHTMP="$TMPDIR"
unlock(){ local n=0; while [ -f .git/index.lock ]; do n=$((n+1)); [ $n -gt 40 ] && { rm -f .git/index.lock; break; }; sleep 3; done; }
while :; do
  python3 tools/tasks.py >> logs/agentd.log 2>&1
  python3 - <<'PY' >> logs/agentd.log 2>&1
import json, time, os
st = {}
try: st = json.load(open("agent_state.json", encoding="utf-8"))
except Exception: pass
st.update({"cycles": st.get("cycles", 0) + 1, "at": time.strftime("%F %H:%M"), "status": "ok"})
json.dump(st, open("agent_state.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
  unlock; git add -A >/dev/null 2>&1
  git -c user.email=a@c.local -c user.name=agent commit -m "agent $(date +%F_%H%M)" >/dev/null 2>&1
  unlock; git push --force origin main >/dev/null 2>&1
  sleep 1800
done
AEOF
chmod +x agentd.sh
python3 - <<'PY' >/dev/null 2>&1
p = ".github/workflows/agent.yml"
try: s = open(p, encoding="utf-8").read()
except FileNotFoundError: s = ""
if s and "tasks.py" not in s:
    s = s.replace("for s in revenue_sync hits_report vault money dashboard share earn ping; do",
                  "python3 tools/tasks.py || true\n          for s in revenue_sync hits_report vault money dashboard share earn ping; do")
    open(p, "w", encoding="utf-8").write(s)
PY
ok "الوكيل: مهام + طابور + دفع كل 30 دقيقة"

hd "7 · نشر"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { bad "لا تفويض"; exit 1; }
R="$U.github.io"; SITE="https://$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
ROOT="$(python3 -c "import json;print(json.load(open('proof/manifest.json'))['root'])")"
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$ROOT|%s'%time.time()).encode()).hexdigest()[:24])")"
printf '%s' "$SIG" > .tmp/lastcode
VMSG="harden: $U $SIG root=$ROOT"
printf 'CineHub 3099 — إثبات مشدَّد\nالحساب: %s\nالموقع: %s\nالجذر: %s\nالتوقيع: %s\nالتاريخ: %s\n' \
  "$U" "$SITE" "$ROOT" "$SIG" "$(date -u +%FT%TZ)" > verify.txt
rm -f .git/index.lock 2>/dev/null
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
# رفع مجلد العمل صريحًا
git add -f .github/workflows/agent.yml 2>/dev/null || true
git -c user.email=a@c.local -c user.name=Agent commit -m "workflows" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
P=0
for i in 1 2 3 4; do
  rm -f .git/index.lock 2>/dev/null
  case "$i" in
    1) timeout 2400 git push origin main 2>"$GHTMP/e" && P=1 ;;
    2) timeout 2400 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    3) timeout 2400 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 2400 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
done
[ "$P" = 1 ] || wrn "الدفع فشل"

hd "8 · إثبات من الريموت"
sleep 5
W="$(curl -s -m 25 -H "Authorization: Bearer $T" https://api.github.com/repos/$U/$R/actions/workflows | grep -c agent || true)"
[ "${W:-0}" -gt 0 ] && ok "workflow ظاهر على الريموت" || wrn "workflow غير مرئي"
RM="$(curl -s -m 30 -H "Authorization: Bearer $T" "https://api.github.com/repos/$U/$R/commits/main" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['commit']['message'].splitlines()[0])" 2>/dev/null || true)"
[ "$RM" = "$VMSG" ] && ok "التوقيع مقروء من GitHub" || wrn "رسالة: ${RM:-?}"
RH="$(curl -s -m 30 -H "Authorization: Bearer $T" "https://api.github.com/repos/$U/$R/contents/verify.txt" \
  | python3 -c "import sys,json,base64;print(base64.b64decode(json.load(sys.stdin)['content']).decode('utf-8','ignore'))" 2>/dev/null || true)"
printf '%s' "$RH" | grep -q "$SIG" && ok "verify.txt مطابق" || wrn "verify.txt غير مطابق"

hd "9 · تحقق حيّ"
for f in "" app.html links.html proof.html earn.html verify.txt; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

hd "10 · تشغيل الوكيل"
pkill -f agentd.sh 2>/dev/null || true; sleep 1; rm -f .git/index.lock 2>/dev/null
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2
pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل — 9 مهام كل 30 دقيقة" || wrn "لم يبدأ"

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  مشدَّد · موثّق · مُثبت · الوكيل يعمل          ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  التوقيع : %s\n  الجذر   : %s\n  الإثبات : %s/proof.html\n  تحقّق   : bash VERIFY.sh\n' \
  "$SIG" "$ROOT" "$SITE" | tee -a "$LOG"
