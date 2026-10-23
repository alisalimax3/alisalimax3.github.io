#!/usr/bin/env bash
# يطبّق الإصلاحات ويعيد تشغيل كل شيء ويثبت أنه يعمل
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; cd "$ROOT"
echo "=== 1/6 بيئة Termux ==="
command -v termux-wake-lock >/dev/null 2>&1 && { termux-wake-lock && echo "  ✔ منع نوم المعالج"; } || echo "  ℹ termux-wake-lock غير متاح"
for c in node curl python3 openssl git; do command -v $c >/dev/null && echo "  ✔ $c" || echo "  ✗ $c — ثبّته: pkg install $c"; done
mkdir -p "$DATA" "$ROOT/logs"
echo "=== 2/6 إيقاف النسخ القديمة ==="
for n in agent watchkeys autopost watchbot; do [ -s "$DATA/$n.pid" ] && kill "$(cat "$DATA/$n.pid")" 2>/dev/null && echo "  أوقفت $n"; done
echo "=== 3/6 بوابة نظيفة ==="
bash "$HERE/GATEWAY.sh" restart || exit 1
echo "=== 4/6 ربط + تشغيل الخدمات ==="
bash "$HERE/WIRE.sh"
start(){ local n="$1"; shift
  [ -s "$DATA/$n.pid" ] && kill -0 "$(cat "$DATA/$n.pid")" 2>/dev/null && { echo "  ✔ $n يعمل"; return; }
  nohup "$@" </dev/null >> "$ROOT/logs/$n.log" 2>&1 & echo $! > "$DATA/$n.pid"; sleep 1; echo "  ✔ $n بدأ"; }
start agent bash "$HERE/AGENT-MONEY.sh"
start watchkeys bash "$HERE/WATCH-KEYS.sh"
echo "=== 5/6 إثبات حقيقي ==="
bash "$HERE/PROVE.sh"
echo "=== 6/6 الحالة ==="
bash "$HERE/STATUS.sh"
echo "افتح الآن: http://127.0.0.1:${PORT:-8787}/gate.html"
echo "أو اكتب بريدك وسترى الرمز على الشاشة مباشرة (ومحفوظ في logs/codes.log)"
