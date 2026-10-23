#!/usr/bin/env bash
###############################################################################
# FINAL-ALL — كل شيء: 83 موقعًا + إباحة + قنوات + ربط + وكيل + حصد + سحب + نشر
#   bash money/FINAL-ALL.sh              تجهيز كامل
#   WITH_BROWSER=1 bash money/FINAL-ALL.sh   مع بوت المشاهدة
#   bash money/FINAL-ALL.sh --status
###############################################################################
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; cd "$ROOT"
mkdir -p "$DATA" "$ROOT/logs"; [ "${1:-}" = "--status" ] && exec bash "$HERE/STATUS.sh"
echo "########## 1/9 بيئة ##########"
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock 2>/dev/null && echo "  ✔ wake-lock"
OK=1; for c in node curl python3 openssl git; do command -v $c >/dev/null && echo "  ✔ $c" || { echo "  ✗ $c — pkg install $c"; OK=0; }; done
[ "$OK" = 1 ] || exit 1
node -e 'require("ethers")' 2>/dev/null || (cd "$HERE" && npm install --no-audit --no-fund --silent >/dev/null 2>&1)
node -e 'require("ethers")' 2>/dev/null && echo "  ✔ ethers" || echo "  ℹ ethers سيتثبت عند الحاجة"
echo "########## 2/9 دمج السجلات ##########"
python3 - "$HERE" <<'PY'
import os,sys
h=sys.argv[1]; main=os.path.join(h,"sites.tsv"); cur=open(main).read(); add=0
for extra in ("sites-adult.tsv","sites-channels.tsv"):
    p=os.path.join(h,extra)
    if not os.path.exists(p): continue
    for l in open(p):
        if not l.strip() or l.startswith("id|"): continue
        if l.split("|")[0]+"|" not in cur: cur+=l; add+=1
open(main,"w").write(cur)
tot=len([x for x in cur.split("\n") if x and not x.startswith("id|")])
print(f"  ✔ أُضيف {add} — الإجمالي {tot} موقعًا/قناة")
PY
echo "########## 3/9 اشتقاق + أسرار + فحص حقيقي ##########"
bash "$HERE/lib/derive.sh"
bash "$HERE/KEYCHECK.sh" || true
echo "########## 4/9 ربط عادي + إباحة ##########"
bash "$HERE/WIRE.sh"
bash "$HERE/ADULT-WIRE.sh"
echo "########## 5/9 تشغيل البوابة ##########"
bash "$HERE/GATEWAY.sh" restart || exit 1
echo "########## 6/9 تشغيل الخدمات ##########"
stop(){ [ -s "$DATA/$1.pid" ] && kill "$(cat "$DATA/$1.pid")" 2>/dev/null; true; }
for n in keepalive agent watchkeys autopost watchbot; do stop $n; done; sleep 1
nohup bash "$HERE/KEEPALIVE.sh" </dev/null >> "$ROOT/logs/keepalive.log" 2>&1 & echo $! > "$DATA/keepalive.pid"
sleep 6
for n in agent watchkeys autopost; do [ -s "$DATA/$n.pid" ] && echo "  ✔ $n (pid $(cat "$DATA/$n.pid"))" || echo "  ✗ $n"; done
if [ "${WITH_BROWSER:-0}" = "1" ]; then
  if [ ! -d "$HERE/node_modules/playwright" ]; then
    echo "  ⏳ تثبيت Playwright (قد يأخذ دقائق)..."; (cd "$HERE" && npm i -D playwright --no-audit --no-fund --silent >/dev/null 2>&1 && npx playwright install chromium >/dev/null 2>&1)
  fi
  [ -d "$HERE/node_modules/playwright" ] && echo "  ✔ playwright" || echo "  ✗ playwright"
fi
echo "########## 7/9 إثبات حقيقي ##########"
bash "$HERE/PROVE.sh"
echo "########## 8/9 حصد + نشر ##########"
bash "$HERE/HARVEST.sh"
bash "$HERE/PUSH-GH.sh" || true
echo "########## 9/9 الحالة ##########"
bash "$HERE/STATUS.sh"
echo "افتح: http://127.0.0.1:${PORT:-8787}/gate.html   |   سجل المواقع: http://127.0.0.1:${PORT:-8787}/register.html"
echo "التسجيل الإلزامي يعمل. الرمز يظهر على الشاشة ويُحفظ في logs/codes.log"
