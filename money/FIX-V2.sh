#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
echo "── 1) تصحيح keys.env (فصل الأسطر الملتصقة) ──"
node "$H/lib/keysfile.js" normalize
grep -q '^WALLET_ADDRESS=0x' keys.env || { echo "  ⚠ لا محفظة — شغّل bash money/WALLET.sh"; }

echo "── 2) patch بالمُحدِّدات (لا مطابقة صارمة) ──"
python3 - "$H" <<'PY'
import os,sys,re
H=sys.argv[1]
SEVEN='["sources.json","sources-big.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"]'
NEW_SRC='const src=function(){var out=[],seen={};'+SEVEN+'.forEach(function(f){try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(function(x){if(x&&x.id&&!seen[x.id]){seen[x.id]=1;out.push(x);}});}catch(e){}});return out;};'
NEW_SRC_ARROW='const sources=()=>{let o=[],s={};'+SEVEN+'.forEach(f=>{try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(x=>{if(x&&x.id&&!s[x.id]){s[x.id]=1;o.push(x);}});}catch(e){}});return o;};'
def lines_replace(path,marker,newline):
    if not os.path.exists(path): return 0
    L=open(path,encoding="utf-8").read().split("\n"); n=0
    for i,x in enumerate(L):
        if marker in x and x.strip().startswith(marker):
            if x!=newline: L[i]=newline; n+=1
    open(path,"w",encoding="utf-8").write("\n".join(L)); return n
def rx(path,pat,rep,cnt=1):
    if not os.path.exists(path): return 0
    s=open(path,encoding="utf-8").read(); s2,n=re.subn(pat,rep,s,count=cnt)
    if n: open(path,"w",encoding="utf-8").write(s2)
    return n

n=0
n+=lines_replace(os.path.join(H,"AUTH-CENTER.js"),"const src=function()",NEW_SRC)
n+=lines_replace(os.path.join(H,"agent-core.js"),"const sources=()=>",NEW_SRC_ARROW)
n+=lines_replace(os.path.join(H,"AGENT-BOT.js"),"const sources=()=>",NEW_SRC_ARROW)
print("  ✔ قوائم المصادر حُدّثت (%d)"%n)

for f,pat,rep in [
 ("agent-core.js", r'if\(!x\.url\s*\|\|\s*x\.url\s*===\s*"-"\)\s*return\s+res\([^;]*;',
   'const UU=x.probe||x.url;if(!UU||UU==="-")return res({id:x.id,code:0,note:"لا يحتاج مفتاح"});'),
 ("agent-core.js", r'let\s+u\s*=\s*x\.url\s*;', 'let u=UU;'),
 ("agent-core.js", r'fs\.writeFileSync\(\s*K\s*,\s*t\s*\)\s*;',
   'var tmp=K+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,K);try{fs.chmodSync(K,0o600);}catch(e){}'),
 ("AUTH-CENTER.js", r'fs\.writeFileSync\(\s*KEYS\s*,\s*t\s*\)\s*;',
   'var tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);try{fs.chmodSync(KEYS,0o600);}catch(e){}'),
 ("agent-ui.html", r'const\s+B\s*=\s*[^;]*;', 'const B="";'),
]:
    print("  " + ("✔" if rx(os.path.join(H,f),pat,rep) else "○") + " "+f+" ← "+pat[:34])

# 3) تصنيف VERIFY + إعادة المحاولة
v=os.path.join(H,"VERIFY.sh")
if os.path.exists(v):
    s=open(v,encoding="utf-8").read()
    s=s.replace('elif c in ("403","429","503"): blk+=1','elif c in ("401","403","429","503"): blk+=1')
    s=s.replace('"curl","-sL","-o","/dev/null"','"curl","-sL","--retry","3","--retry-delay","2","-o","/dev/null"')
    s=s.replace('for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do\n  V=$(grep','for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do\n  V=$(grep')
    open(v,"w",encoding="utf-8").write(s); print("  ✔ VERIFY.sh — تصنيف 401/403/429 + إعادة محاولة")
# 4) agent-run.js تصنيف
a=os.path.join(H,"lib","agent-run.js")
if os.path.exists(a):
    s=open(a,encoding="utf-8").read()
    s=s.replace('else if(["403","429","503"].includes(code)){blk++;}','else if(["401","403","429","503"].includes(code)){blk++;}')
    s=s.replace('execFile("curl",["-sL","-o","/dev/null"','execFile("curl",["-sL","--retry","2","-o","/dev/null"')
    open(a,"w",encoding="utf-8").write(s); print("  ✔ agent-run.js — تصنيف + إعادة محاولة")
PY

echo "── 3) فحص الصياغة ──"
for f in "$H"/*.js "$H"/lib/*.js; do [ -e "$f" ] || continue
  node --check "$f" >/dev/null 2>&1 && echo "  ✔ $(basename "$f")" || echo "  ✗ خطأ صياغة: $(basename "$f")"; done

echo "── 4) بوابة صحّة المنافذ (مع إعادة محاولة) ──"
ok=1
for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do
  V=$(grep -m1 "^$K=" keys.env 2>/dev/null | cut -d= -f2-)
  if [ -n "$V" ] && curl -sL --retry 3 --retry-delay 2 -o /dev/null --max-time 6 "http://127.0.0.1:$V/"; then
    echo "  ✔ $K=$V"; else echo "  ✗ $K=$V — أعد التشغيل: bash money/TOTAL.sh"; ok=0; fi
done
[ -f "$H/KEEPALIVE.sh" ] && { pkill -f KEEPALIVE.sh 2>/dev/null; nohup bash "$H/KEEPALIVE.sh" </dev/null >>"$ROOT/logs/keepalive.log" 2>&1 & echo "  ✔ KEEPALIVE يعمل — يمنع موت البوابة"; }
[ "$ok" = "1" ] && echo "  ★ كل الخدمات حيّة" || echo "  ⚠ بعض الخدمات ميتة"
