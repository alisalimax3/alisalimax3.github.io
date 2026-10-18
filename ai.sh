#!/usr/bin/env bash
# CineHub AI — إقلاع/إيقاف/حالة/سجل
D="$HOME/cinehub3099"; P="${PORT:-8080}"; LOG="$D/ai.log"; PID="$D/ai.pid"
ip(){ python3 - <<'P'
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
try: s.connect(("8.8.8.8",80)); print(s.getsockname()[0])
except Exception: print("127.0.0.1")
P
}
case "${1:-start}" in
 start)
  if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then echo "يعمل مسبقًا (PID $(cat "$PID"))"; else
   command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
   cd "$D"; PORT="$P" nohup python3 ai_server.py > "$LOG" 2>&1 & echo $! > "$PID"
   sleep 1.5; echo "✓ شُغّل"; fi
  echo "  هذا الهاتف  : http://127.0.0.1:$P"
  echo "  جهاز آخر    : http://$(ip):$P"
  ;;
 stop) [ -f "$PID" ] && kill "$(cat "$PID")" 2>/dev/null; rm -f "$PID"
       command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock; echo "✓ أُوقف" ;;
 status) [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null && echo "يعمل (PID $(cat "$PID"))" || echo "متوقف" ;;
 log) tail -40 "$LOG" ;;
 *) echo "الاستخدام: bash ai.sh [start|stop|status|log]" ;;
esac
