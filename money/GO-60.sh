#!/usr/bin/env bash
# أمر واحد: تسجيل 60 موقعًا + فحص مفاتيح + ربط + وكيل + حصد + نشر
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; cd "$ROOT"
AUTO=0; [ "${1:-}" = "--auto" ] && AUTO=1
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
echo "###### 0/7 بيئة العمل ######"
for c in curl python3 node git openssl; do command -v $c >/dev/null && echo "  ✔ $c" || echo "  ✗ $c ناقص"; done
node -e 'require("ethers")' 2>/dev/null && echo "  ✔ ethers" || { (cd "$HERE" && npm install --no-audit --no-fund --silent >/dev/null 2>&1) && echo "  ✔ ethers مثبت" || echo "  ✗ ethers فشل"; }
echo "###### 1/7 سجل المواقع وصفحة التسجيل ######"
python3 "$HERE/lib/sites.py"
[ -f register.html ] || cp register.html "$ROOT/" 2>/dev/null || true
echo "###### 2/7 فحص كل مفتاح حقيقيًا ######"
bash "$HERE/KEYCHECK.sh" || true
echo "###### 3/7 تسجيل آلي (اختياري) ######"
if [ "$AUTO" = 1 ]; then
  if [ ! -d "$HERE/node_modules/playwright" ]; then (cd "$HERE" && npm i -D playwright --no-audit --no-fund --silent >/dev/null 2>&1 && npx --prefix "$HERE" playwright install chromium >/dev/null 2>&1); fi
  node "$HERE/AUTOREG.js" 2>/dev/null || echo "  تخطي Playwright (شغّل: cd money && npm i -D playwright && npx playwright install chromium)"
else echo "  شغّل مع --auto للتسجيل الآلي، أو: bash money/REGISTER.sh open"; fi
echo "###### 4/7 ربط المفاتيح داخل التطبيق ######"
bash "$HERE/MONEY-UP.sh" --force
echo "###### 5/7 حصد أولي ######"
bash "$HERE/HARVEST.sh"
echo "###### 6/7 حالة الوكيل ######"
[ -s "$DATA/agent.pid" ] && kill -0 "$(cat "$DATA/agent.pid")" 2>/dev/null && echo "  ✔ الوكيل يعمل (pid $(cat "$DATA/agent.pid"))" || { nohup bash "$HERE/AGENT-MONEY.sh" >> "$ROOT/logs/agent-money.log" 2>&1 & sleep 1; echo "  ✔ الوكيل بدأ"; }
echo "###### 7/7 النشر على GitHub ######"
bash "$HERE/PUSH-GH.sh" || true
echo; echo "################ ملخص صادق ################"
python3 - "$DATA" "$ROOT" <<'PY'
import json,os,sys
d,root=sys.argv[1],sys.argv[2]
def g(n,f="{}"):
    p=os.path.join(d,n)
    return json.load(open(p)) if os.path.exists(p) else json.loads(f)
ks=g("keys-status.json",'{"summary":{},"keys":[]}'); s=ks.get("summary",{})
tr=g("treasury.json",'{}'); st=g("sites.json")
api=[k for k in ks["keys"] if k["status"]=="LIVE"]; rev=[k["id"] for k in api if k.get("revenue_source")]
print(f"  مفاتيح تعمل فعليًا      : {s.get('live',0)}")
print(f"  مفاتيح موجودة (لوحة فقط): {s.get('set',0)}")
print(f"  مفاتيح ناقصة            : {s.get('missing',0)}")
print(f"  مصادر ربح حيّة          : {len(rev)}  {rev}")
print(f"  إجمالي الأرباح المسجلة  : ${tr.get('lifetime_usd',0)}")
print(f"  قابل للسحب              : ${tr.get('available_usd',0)} (الحد ${tr.get('threshold_usd',10)})")
print(f"  رصيد المحفظة on-chain   : ${tr.get('onchain_usd',0)}")
print(f"  مواقع مسجّلة في السجل   : {sum(1 for v in st.values() if v.get('status') in ('registered','key_set','live'))}/{len(st)}")
PY
echo
echo "  التطبيق    : http://127.0.0.1:${PORT:-8787}/"
echo "  التسجيل    : http://127.0.0.1:${PORT:-8787}/register.html"
echo "  الحالة     : http://127.0.0.1:${PORT:-8787}/api/status"
echo "  سجل المواقع: bash money/REGISTER.sh list"
echo
echo "  يحتاج يدك: إكمال تسجيل المواقع + لصق المفاتيح في keys.env"
echo "  ثم أعد: bash money/GO-60.sh"
