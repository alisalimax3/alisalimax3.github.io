#!/usr/bin/env bash
# CineHub TOTAL v2 — نسخة احتياطية + إصلاح + تفعيل + ربط + تحقّق
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
cd "$ROOT"; mkdir -p "$DATA" "$ROOT/logs"; umask 077; chmod +x "$HERE"/*.sh 2>/dev/null

freeport(){ local x; for x in $(seq "$1" "$2"); do (exec 3<>/dev/tcp/127.0.0.1/$x) 2>/dev/null || { echo "$x"; return 0; }; done; return 1; }
setkv(){ local k="$1" v="$2" f="$ROOT/keys.env"; touch "$f"; grep -v "^$k=" "$f" > "$f.t" 2>/dev/null || true; mv "$f.t" "$f" 2>/dev/null || true; printf '%s=%s\n' "$k" "$v" >> "$f"; }
getkv(){ grep -m1 "^$1=" "$ROOT/keys.env" 2>/dev/null | cut -d= -f2-; }

echo "════ 0/9 نسخة احتياطية ════"
B="$ROOT/_backup/$(date +%Y%m%d-%H%M%S)"; mkdir -p "$B"
tar --exclude=./node_modules --exclude=./_backup --exclude=./.git -czf "$B/cinehub.tgz" . 2>/dev/null \
  && echo "  ✔ $B/cinehub.tgz" && echo "  ↩ للرجوع: tar -xzf \"$B/cinehub.tgz\" -C \"$ROOT\""

echo "════ 1/9 جرد ════"
MISS=0
for f in lib/sites.py KEYCHECK.sh WIRE.sh PROVE.sh AUTH-CENTER.js agent-core.js AGENT-BOT.js agent-ui.html HUB.js VERIFY.sh PATCH-ALL.sh lib/sources.js; do
  [ -e "$HERE/$f" ] && printf '  ✔ %s\n' "$f" || { printf '  ✗ %s\n' "$f"; MISS=$((MISS+1)); }
done
echo "  ناقص: $MISS (لا يوقف التشغيل)"

echo "════ 2/9 إصلاحات ════"
if [ -f keys.env ]; then
  awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{if(seen[$1]++)next} {print}' keys.env > keys.env.t && mv keys.env.t keys.env
  chmod 600 keys.env; echo "  ✔ keys.env نُظّف + 600"
fi
[ -f "$HERE/PROVE.sh" ] && { grep -q 'PUID' "$HERE/PROVE.sh" || { sed -i 's/\bUID\b/PUID/g' "$HERE/PROVE.sh"; echo "  ✔ PROVE.sh: UID→PUID"; }; }
python3 - "$HERE" <<'PY'
import os,sys,glob
h=sys.argv[1];n=0
for f in glob.glob(os.path.join(h,"**","*.py"),recursive=True):
    try: s=open(f,encoding="utf-8").read()
    except Exception: continue
    if ".utcnow()" not in s: continue
    s=s.replace(".utcnow()",".now(datetime.timezone.utc)")
    if "import datetime" not in s:
        L=s.split("\n"); i=1 if L and L[0].startswith("#!") else 0
        L.insert(i,"import datetime"); s="\n".join(L)
    open(f,"w",encoding="utf-8").write(s); n+=1
print("  ✔ utcnow أُصلح في %d ملف"%n)
PY

echo "════ 3/9 المصادر بلا مفتاح ════"
[ -f "$HERE/KEYLESS.sh" ] && bash "$HERE/KEYLESS.sh" | tail -4 || echo "  ℹ KEYLESS.sh غير موجود"

echo "════ 4/9 إصلاح الكود ════"
bash "$HERE/PATCH-ALL.sh" 2>/dev/null | grep -E '✔|✗|⚠' || true

echo "════ 5/9 ربط المفاتيح ════"
[ -f "$HERE/WIRE.sh" ] && bash "$HERE/WIRE.sh" 2>&1 | grep -E '✔|✗' || true

echo "════ 6/9 المنافذ ════"
pkill -f "money/gateway.js" 2>/dev/null; pkill -f "money/AUTH-CENTER.js" 2>/dev/null
pkill -f "money/agent-core.js" 2>/dev/null; pkill -f "money/HUB.js" 2>/dev/null; sleep 1
for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do
  V="$(getkv $K)"
  if [ -z "$V" ]; then
    case $K in PORT) R="8787 8850";; AUTH_PORT) R="8799 8860";; AGENT_PORT) R="8870 8930";; HUB_PORT) R="8700 8786";; esac
    V="$(freeport $R)"; [ -n "$V" ] || { echo "  ✗ لا منفذ حر لـ $K"; exit 1; }; setkv "$K" "$V"
  fi
  printf '  ✔ %s=%s\n' "$K" "$V"
done
export PORT="$(getkv PORT)" AUTH_PORT="$(getkv AUTH_PORT)" AGENT_PORT="$(getkv AGENT_PORT)" HUB_PORT="$(getkv HUB_PORT)"

echo "════ 7/9 تشغيل الخدمات ════"
start(){ local n="$1" f="$2"; [ -f "$HERE/$f" ] || { echo "  ⚠ $f غير موجود"; return; }
  nohup bash -c "cd '$ROOT' && exec node '$HERE/$f'" </dev/null >> "$ROOT/logs/$n.log" 2>&1 & echo $! > "$DATA/$n.pid"; }
start gateway gateway.js; start auth AUTH-CENTER.js; start agentcore agent-core.js
start hub HUB.js; start agentbot AGENT-BOT.js
sleep 3
for n in gateway auth agentcore hub agentbot; do
  P="$(cat "$DATA/$n.pid" 2>/dev/null)"
  [ -n "$P" ] && kill -0 "$P" 2>/dev/null && echo "  ✔ $n يعمل (pid $P)" || echo "  ✗ $n فشل → tail logs/$n.log"
done

echo "════ 8/9 تحقّق من المنافذ ════"
for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do
  V="$(getkv $K)"; curl -s -o /dev/null -w "  $K=$V → %{http_code}\n" --max-time 5 "http://127.0.0.1:$V/"
done

echo "════ 9/9 البوابة النهائية ════"
bash "$HERE/VERIFY.sh" || true
echo
echo "  ★★★ التطبيق الموحّد : http://127.0.0.1:$(getkv HUB_PORT)/"
echo "  ★★★ الوكيل           : http://127.0.0.1:$(getkv HUB_PORT)/agent"
echo "  ★★★ المفاتيح         : http://127.0.0.1:$(getkv HUB_PORT)/keys"
echo "  المنافذ مثبّتة في keys.env — لن تتغير"
