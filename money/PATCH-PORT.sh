#!/usr/bin/env bash
# ينقل مركز التفويض لمنفذ حر — بلا re.sub، استبدال نصي مباشر
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; cd "$ROOT"

echo "== 1/6 إيقاف المركز =="
[ -s "$DATA/auth.pid" ] && kill "$(cat "$DATA/auth.pid")" 2>/dev/null
pkill -f "AUTH-CENTER.js" 2>/dev/null; sleep 1; echo "  ✔"

echo "== 2/6 تنظيف تكرار AUTH_PORT =="
if [ -f keys.env ]; then
  grep -v '^AUTH_PORT=' keys.env > keys.env.tmp 2>/dev/null || true
  mv keys.env.tmp keys.env 2>/dev/null || true
fi

echo "== 3/6 اختيار منفذ حر =="
P=""
for x in $(seq 8799 8900); do
  curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$x/" 2>/dev/null || { P="$x"; break; }
done
[ -n "$P" ] || { echo "  ✗ لا منفذ حر"; exit 1; }
echo "AUTH_PORT=$P" >> keys.env
echo "  ✔ المنفذ: $P"

echo "== 4/6 تعديل AUTH-CENTER.js =="
python3 - "$ROOT" "$P" <<'PY'
import sys,os
root,port=sys.argv[1],sys.argv[2]
ac=os.path.join(root,"money","AUTH-CENTER.js")
s=open(ac,encoding="utf-8").read()
key='process.env.AUTH_PORT||"'
i=s.find(key)
if i>=0:
    j=s.find('"',i+len(key))
    s=s[:i+len(key)]+port+s[j:]
    open(ac,"w",encoding="utf-8").write(s)
    print("  ✔ افتراضي المركز = "+port)
else:
    print("  ⚠ لم أجد سطر المنفذ في AUTH-CENTER.js")
PY

echo "== 5/6 تعديل MASTER.sh =="
python3 - "$ROOT" "$P" <<'PY'
import sys,os
root,port=sys.argv[1],sys.argv[2]
m=os.path.join(root,"money","MASTER.sh")
if not os.path.exists(m): print("  ℹ MASTER.sh غير موجود"); raise SystemExit
t=open(m,encoding="utf-8").read()
line='mkdir -p "$DATA" "$ROOT/logs"'
add='\n[ -f "$ROOT/keys.env" ] && export AUTH_PORT="$(grep -m1 "^AUTH_PORT=" "$ROOT/keys.env" 2>/dev/null | cut -d= -f2)"'
if 'export AUTH_PORT' not in t and line in t:
    t=t.replace(line,line+add,1)
    open(m,"w",encoding="utf-8").write(t); print("  ✔ MASTER.sh صار يقرأ AUTH_PORT")
else:
    print("  ✔ مطبّق مسبقًا أو غير لازم")
PY

echo "== 6/6 التشغيل =="
nohup node "$HERE/AUTH-CENTER.js" </dev/null >> "$ROOT/logs/auth.log" 2>&1 & echo $! > "$DATA/auth.pid"
sleep 3
if curl -s -o /dev/null --max-time 5 "http://127.0.0.1:$P/"; then
  echo
  echo "  ★★★ مركز التفويض: http://127.0.0.1:$P/ ★★★"
  echo "  ★ التطبيق (كما هو): http://127.0.0.1:${PORT:-8787}/"
else
  echo "  ✗ فشل:"; tail -8 "$ROOT/logs/auth.log"
fi
