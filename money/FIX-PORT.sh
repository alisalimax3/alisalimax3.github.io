#!/usr/bin/env bash
# ينقل مركز التفويض إلى منفذ حر ويجعله ثابتًا في keys.env
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; cd "$ROOT"

echo "== 1/5 إيقاف المركز القديم =="
[ -s "$DATA/auth.pid" ] && kill "$(cat "$DATA/auth.pid")" 2>/dev/null && echo "  أوقفت PID قديم"
pkill -f "AUTH-CENTER.js" 2>/dev/null; sleep 1

echo "== 2/5 البحث عن منفذ حر =="
P=""
for x in $(seq 8799 8900); do
  curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$x/" 2>/dev/null || { P="$x"; break; }
done
[ -n "$P" ] || { echo "  ✗ لا منفذ حر بين 8799-8900"; exit 1; }
echo "  ✔ المنفذ المختار: $P"

echo "== 3/5 تثبيته في keys.env =="
grep -q '^AUTH_PORT=' "$ROOT/keys.env" 2>/dev/null \
  && sed -i "s|^AUTH_PORT=.*|AUTH_PORT=$P|" "$ROOT/keys.env" \
  || echo "AUTH_PORT=$P" >> "$ROOT/keys.env"

echo "== 4/5 ربط المركز و MASTER بالمنفذ الجديد =="
python3 - "$ROOT" <<'PY'
import re,sys,os
root=sys.argv[1]
ac=os.path.join(root,"money","AUTH-CENTER.js")
s=open(ac,encoding="utf-8").read()
if "AUTH_PORT=(" not in s:
    new='PORT=(()=>{let p=parseInt(process.env.AUTH_PORT||"0",10);if(p)return p;try{const m=fs.readFileSync(path.join(ROOT,"keys.env"),"utf8").match(/^AUTH_PORT=(\\d+)/m);if(m)return +m[1];}catch(e){}return 8788;})()'
    s2=re.sub(r'PORT=parseInt\(process\.env\.AUTH_PORT\|\|"8788",10\)', new, s)
    if s2==s: print("  ⚠ لم أطابق سطر المنفذ — تأكد أن AUTH-CENTER.js منسوخ كما هو")
    else: open(ac,"w",encoding="utf-8").write(s2); print("  ✔ AUTH-CENTER.js يقرأ AUTH_PORT من keys.env")
else: print("  ✔ مطبّق مسبقًا")
m=os.path.join(root,"money","MASTER.sh")
t=open(m,encoding="utf-8").read()
if "AUTH_PORT=" not in t.split("\n")[0:12].__str__():
    ins='\n[ -f "$ROOT/keys.env" ] && export AUTH_PORT="$(grep -m1 "^AUTH_PORT=" "$ROOT/keys.env" 2>/dev/null | cut -d= -f2)"\n'
    t=re.sub(r'(mkdir -p "\$DATA" "\$ROOT/logs")', r'\1'+ins, t, count=1)
    open(m,"w",encoding="utf-8").write(t); print("  ✔ MASTER.sh يقرأ AUTH_PORT تلقائيًا")
PY

echo "== 5/5 التشغيل =="
nohup node "$HERE/AUTH-CENTER.js" </dev/null >> "$ROOT/logs/auth.log" 2>&1 & echo $! > "$DATA/auth.pid"
sleep 2
if curl -s -o /dev/null --max-time 5 "http://127.0.0.1:$P/"; then
  echo
  echo "  ★★★ افتح الآن: http://127.0.0.1:$P/ ★★★"
  echo "  (المنفذ مثبّت في keys.env — لن يتغير بعد الآن)"
else
  echo "  ✗ فشل — آخر السطور:"; tail -6 "$ROOT/logs/auth.log"
fi
