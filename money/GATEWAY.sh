#!/usr/bin/env bash
# مالك واحد للبوابة + PID صحيح + إصلاح ذاتي
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
mkdir -p "$DATA" "$ROOT/logs"; P="${PORT:-8787}"
alive(){ curl -sS -o /dev/null --max-time 3 "http://127.0.0.1:$P/api/status" 2>/dev/null; }
realpid(){ if command -v pgrep >/dev/null 2>&1; then pgrep -f "money/gateway.js" 2>/dev/null | head -1; fi; }
syncpid(){ local rp; rp="$(realpid)"; [ -n "$rp" ] && echo "$rp" > "$DATA/gateway.pid"; }
stop(){ pkill -f "money/gateway.js" 2>/dev/null; sleep 1; }
start(){ if alive; then syncpid; return 0; fi
  stop
  nohup node "$HERE/gateway.js" </dev/null >> "$ROOT/logs/gateway.log" 2>&1 &
  echo $! > "$DATA/gateway.pid"
  for i in $(seq 1 15); do sleep 1; alive && { syncpid; echo "  ✔ البوابة تعمل :$P (pid $(cat "$DATA/gateway.pid"))"; return 0; }; done
  echo "  ✗ فشل التشغيل — آخر سطور:"; tail -8 "$ROOT/logs/gateway.log" 2>/dev/null; return 1; }
case "${1:-start}" in start) start;; stop) stop;; restart) stop; start;; status) alive && { syncpid; echo "up $(cat "$DATA/gateway.pid" 2>/dev/null)"; } || echo down;; esac
