#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
python3 - "$HERE" <<'PY'
import os,sys
H=sys.argv[1]
rd=lambda p:(open(p,encoding="utf-8").read() if os.path.exists(p) else None)
wr=lambda p,s:open(p,"w",encoding="utf-8").write(s)
def patch(fn,pairs):
    p=os.path.join(H,fn); s=rd(p)
    if s is None: print("  ✗ %s غير موجود"%fn); return
    n=0
    for old,new in pairs:
        if old in s: s=s.replace(old,new); n+=1
        else: print("  ⚠ %s ← لم أطابق: %s"%(fn,old[:58]))
    wr(p,s); print("  ✔ %s (%d تعديل)"%(fn,n))

SEVEN='["sources.json","sources-big.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"]'
FOUR='["sources.json","sources-big.json","sources-mega.json","sources-mega2.json"]'

patch("AUTH-CENTER.js",[
 ('const src=function(){var out=[];["sources.json","sources-big.json"].forEach(function(f){try{out=out.concat(JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")));}catch(e){}});return out;};',
  'const src=function(){var out=[],seen={};'+SEVEN+'.forEach(function(f){try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(function(x){if(x&&x.id&&!seen[x.id]){seen[x.id]=1;out.push(x);}});}catch(e){}});return out;};'),
 ('var stp=(STEPS[x.id]||[]).map',
  'var stp=(STEPS[x.id]||["افتح الرابط وسجّل حسابًا","أكمل النموذج وأكّد البريد","بعد القبول: Settings/Account ← API ← Create","انسخ المفتاح والصقه هنا"]).map'),
 ('fs.writeFileSync(KEYS,t);',
  'var tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);try{fs.chmodSync(KEYS,0o600);}catch(e){}'),
])
s=rd(os.path.join(H,"AUTH-CENTER.js"))
if s and '"data"' not in s:
    i=s.find("const CATS=["); j=s.find("];",i)
    if i>=0<j:
        s=s[:j]+',["dev","🧰 أدوات ومطوّرين"],["data","📊 بيانات"],["media","🎞 وسائط"],["seo","📈 نمو"]'+s[j:]
        wr(os.path.join(H,"AUTH-CENTER.js"),s); print("  ✔ CATS (+4)")

for fn in ("agent-core.js","AGENT-BOT.js"):
    patch(fn,[('const sources=()=>{let o=[];'+FOUR+'.forEach(f=>{try{o=o.concat(JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")));}catch(e){}});const s={};return o.filter(x=>s[x.id]?0:(s[x.id]=1));};',
              'const sources=()=>{let o=[],s={};'+SEVEN+'.forEach(f=>{try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(x=>{if(x&&x.id&&!s[x.id]){s[x.id]=1;o.push(x);}});}catch(e){}});return o;};')])

patch("agent-core.js",[
 ('if(!x.url||x.url==="-")return res({id:x.id,code:0,note:"لا يحتاج مفتاح"});',
  'const UU=x.probe||x.url;if(!UU||UU==="-")return res({id:x.id,code:0,note:"لا يحتاج مفتاح"});'),
 ('let u=x.url;x.env.forEach','let u=UU;x.env.forEach'),
 ('fs.writeFileSync(K,t);',
  'var tmp=K+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,K);try{fs.chmodSync(K,0o600);}catch(e){}'),
])
patch("agent-ui.html",[('const B=location.port==="8787"?"http://127.0.0.1:8790":"";','const B="";')])
PY
[ -f keys.env ] && chmod 600 keys.env && echo "  ✔ keys.env → 600"
for f in "$HERE"/*.js; do [ -e "$f" ] || continue
  node --check "$f" >/dev/null 2>&1 && echo "  ✔ صياغة $(basename "$f")" || echo "  ✗ خطأ صياغة $(basename "$f")"; done
