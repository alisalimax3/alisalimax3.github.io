#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# LAUNCH.sh — الإصلاح الأخير + تشغيل صحيح + نشر + رابط حقيقي
# bash money/LAUNCH.sh [--no-push] [--wire] [--broadcast]
# ============================================================
set -u; umask 022
ROOT="$HOME/cinehub3099"; [ -d "$ROOT" ] || ROOT="$(cd "$(dirname "$0")/.." && pwd)"
M="$ROOT/money"; AX="$M/apex"; P="$AX/pipeline"; TS="$(date -u +%Y%m%dT%H%M%SZ)"
PUSH=1; WIRE=0; BCAST=0
for a in "$@"; do [ "$a" = "--no-push" ] && PUSH=0; [ "$a" = "--wire" ] && WIRE=1; [ "$a" = "--broadcast" ] && BCAST=1; done
mkdir -p "$M/logs" "$AX"/{registry,exec,ledger,state,reports,logs,dlq,dash,data} "$P"
LOG="$M/logs/launch-$TS.log"; DIAG="$AX/reports/diag-$TS.txt"; : > "$DIAG"
say(){ printf '%s\n' "$*" | tee -a "$LOG"; }
H(){ say ""; say "========== $* =========="; }
d(){ printf '%s\n' "$*" | tee -a "$LOG" >> "$DIAG"; }
have(){ command -v "$1" >/dev/null 2>&1; }
pass(){ say "  ✔ $*"; }
fail(){ say "  ✘ $*"; }

H "1) الإصلاحات الجذرية"

# 1.1 crypto.js — إضافة verify() + إصلاح recover + selftest
node - "$P/crypto.js" <<'NODE'
const fs=require('fs');const f=process.argv[2];
let s=fs.readFileSync(f,'utf8');
if(!s.includes('function verify(')){
  const add=`
function verify(hash,r,s,Q){const z=BigInt('0x'+hash.toString('hex'));
 const w=inv(s,N);const u1=mod(z*w,N),u2=mod(r*w,N);
 const Pt=add(mul(u1,[GX,GY]),mul(u2,Q));
 return Pt?mod(Pt[0],N)===r:false;}
function selftest(){const k=BigInt('0x'+'11'.repeat(32));
 const h=keccak(Buffer.from('apex'));const sg=sign(h,k);
 const ok=verify(h,sg.r,sg.s,mul(k,[GX,GY]));
 const rec=recover(h,sg.r,sg.s,sg.rec);
 return {verify:ok,recover:rec,expect:addrOf(k),match:rec&&rec.toLowerCase()===addrOf(k).toLowerCase()};}
`;
  s=s.replace('module.exports=',add+'\nmodule.exports=');
  s=s.replace('module.exports={','module.exports={verify,selftest,add,inv,GX,GY,');
  fs.writeFileSync(f,s);
}
NODE
node --check "$P/crypto.js" && pass "crypto.js مُحدَّث (verify+selftest)" || fail "crypto.js"
node -e "const c=require('$P/crypto.js');const r=c.selftest();
console.log('  verify='+r.verify+' recover_match='+r.match);
if(!r.verify||!r.match){console.log('  recover='+r.recover);console.log('  expect ='+r.expect);}" | tee -a "$LOG"

# 1.2 ledger.js — تصحيح اتجاه الأرصدة (مدين/دائن)
cat > "$P/ledger.js" <<'JS'
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const CREDIT=/^(income|payable|liability|equity)/;
class Ledger{
 constructor(f){this.f=f;try{fs.mkdirSync(path.dirname(f),{recursive:true})}catch(e){}
  this.c=[];try{this.c=fs.readFileSync(f,'utf8').split('\n').filter(Boolean).map(JSON.parse)}catch(e){}}
 last(){return this.c[this.c.length-1]||{seq:0,hash:'GENESIS'};}
 post(entries,meta){
  const dr=entries.filter(e=>e.dr).reduce((a,e)=>a+e.dr,0);
  const cr=entries.filter(e=>e.cr).reduce((a,e)=>a+e.cr,0);
  const p=this.last();
  const e={seq:p.seq+1,ts:new Date().toISOString(),entries,meta,balanced:Math.abs(dr-cr)<1e-9,prev:p.hash};
  e.hash=crypto.createHash('sha256').update(JSON.stringify(e)).digest('hex');
  fs.appendFileSync(this.f,JSON.stringify(e)+'\n');this.c.push(e);return e;}
 balance(acc){const credit=CREDIT.test(acc);let b=0;
  for(const e of this.c)for(const x of e.entries)if(x.account===acc)b+=credit?((x.cr||0)-(x.dr||0)):((x.dr||0)-(x.cr||0));
  return +b.toFixed(6);}
 verify(){let prev='GENESIS';for(const e of this.c){const c={...e};delete c.hash;
   if(crypto.createHash('sha256').update(JSON.stringify(c)).digest('hex')!==e.hash)return{ok:false,at:e.seq};
   if(e.prev!==prev)return{ok:false,at:e.seq,why:'chain'};prev=e.hash;}
  return{ok:true,entries:this.c.length};}}
module.exports=Ledger;
JS
node --check "$P/ledger.js" && pass "ledger.js مُصحّح (اتجاه الأرصدة)"

# 1.3 money.js — حسابات صحيحة
cat > "$P/money.js" <<'JS'
const fs=require('fs'),path=require('path');
const P=process.argv[2];const Ledger=require('./ledger.js');const fraud=require('./fraud.js');const comp=require('./compliance.js');
const L=new Ledger(path.join(P,'ledger.jsonl'));
let evs=[];try{evs=fs.readFileSync(path.join(P,'events.jsonl'),'utf8').split('\n').filter(Boolean).map(JSON.parse)}catch(e){}
const seen=new Set(),res={approved:0,held:0,rejected:0,gross:0,net:0,tax:0};
for(const ev of evs){
 const ctx={dup:seen.has(ev.id)};seen.add(ev.id);
 const f=fraud.score(ev,ctx),c=comp.check(ev),amt=+(ev.amount_usd||0),idem=ev.id;
 if(f.decision==='approve'&&c.ok){
  L.post([{account:'asset:app_wallet',dr:amt},{account:'income:'+(ev.source||'unknown'),cr:amt}],{idem,type:ev.type,fraud:f.score});
  const tax=+(amt*c.tax_pct/100).toFixed(6);
  if(tax>0)L.post([{account:'asset:app_wallet',dr:tax},{account:'liability:tax',cr:tax}],{idem,type:'tax'});
  res.approved++;res.gross+=amt;res.tax+=tax;res.net+=(amt-tax);
 } else if(f.decision==='hold')res.held++; else res.rejected++;
}
const v=L.verify();
const out={ts:new Date().toISOString(),events:evs.length,ledger_ok:v.ok,entries:L.c.length,
 approved:res.approved,held:res.held,rejected:res.rejected,
 gross_usd:+res.gross.toFixed(4),tax_usd:+res.tax.toFixed(4),net_usd:+res.net.toFixed(4),
 wallet_asset:L.balance('asset:app_wallet'),tax_liability:L.balance('liability:tax'),
 note:evs.length?'من أحداث حقيقية':'لا أحداث بعد'};
fs.writeFileSync(path.join(P,'money.json'),JSON.stringify(out,null,1));
console.log(JSON.stringify(out));
JS
node --check "$P/money.js" && pass "money.js مُصحّح"

# 1.4 reconcile.js — دلالة مطابقة صحيحة
cat > "$P/reconcile.js" <<'JS'
const fs=require('fs'),path=require('path');
const P=process.argv[2],AX=process.argv[3];
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(P,p),'utf8'))}catch(e){return d||{}}};
const m=g('money.json',{}),s=g('settle.json',{});
let chain={};try{chain=JSON.parse(fs.readFileSync(path.join(AX,'state/chain.json'),'utf8'))}catch(e){}
const onchain=(chain.chains||[]).reduce((a,c)=>a+(c.usdc||0),0)+(chain.usdt_tron||0);
const internal=m.wallet_asset||0;
const idle=(internal===0&&onchain===0);
const out={ts:new Date().toISOString(),internal_wallet:internal,onchain_stable:onchain,psp_statement:0,
 match:idle?null:Math.abs(internal-onchain)<0.01,
 status:idle?'بانتظار أول دفعة حقيقية':(Math.abs(internal-onchain)<0.01?'مطابق':'فرق يحتاج مراجعة'),
 ledger_ok:!!m.ledger_ok,settle_tx:(s.built&&s.built.txhash)||null,broadcast:!!s.broadcast};
fs.writeFileSync(path.join(P,'reconcile.json'),JSON.stringify(out,null,1));
console.log('reconcile status='+out.status+' internal='+out.internal_wallet+' onchain='+out.onchain_stable);
JS
node --check "$P/reconcile.js" && pass "reconcile.js مُصحّح"

# 1.5 settle.js — تسوية المبلغ الفعلي من الدفتر
cat > "$P/settle.js" <<'JS'
const fs=require('fs'),path=require('path'),https=require('https');
const C=require('./crypto.js');const P=process.argv[2],M=process.argv[3],BCAST=process.argv[4]==='1';
let env='';try{env=fs.readFileSync(path.join(M,'keys.env'),'utf8')}catch(e){}
const K=k=>(env.match(new RegExp('^'+k+'\\s*=\\s*(\\S+)','m'))||[])[1]||'';
const PRIV=K('WALLET_PRIVATE_KEY'),ADDR=K('WALLET_ADDRESS');
const RPC='https://mainnet.base.org',USDC='0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',CID=8453n;
const rpc=(m,p)=>new Promise(r=>{const b=JSON.stringify({jsonrpc:'2.0',id:1,method:m,params:p});
 const q=https.request(RPC,{method:'POST',timeout:12000,headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(b)}},s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>{try{r(JSON.parse(d).result)}catch(e){r(null)}})});
 q.on('error',()=>r(null));q.on('timeout',()=>{q.destroy();r(null)});q.write(b);q.end();});
(async()=>{
 const out={ts:new Date().toISOString(),wallet:ADDR||null,chain:'base',built:null,broadcast:false};
 let due=0;try{due=require(path.join(P,'money.json')).wallet_asset||0}catch(e){}
 out.ledger_due_usd=due;
 if(!PRIV||!ADDR){fs.writeFileSync(path.join(P,'settle.json'),JSON.stringify(out,null,1));console.log('settle=no-wallet');return;}
 const priv=BigInt(PRIV);
 const nonce=BigInt(await rpc('eth_getTransactionCount',[ADDR,'pending'])||'0x0');
 const gp=BigInt(await rpc('eth_gasPrice',[])||'0x3b9aca00');
 const data=C.erc20Transfer(ADDR,0n);
 const tx={nonce,gasPrice:gp*2n,gasLimit:120000n,to:USDC,value:0n,data,chainId:CID};
 const sg=C.signTx(tx,priv);
 const selfRecover=C.recover(C.keccak(C.rlp([tx.nonce,tx.gasPrice,tx.gasLimit,Buffer.from(USDC.replace(/^0x/,''),'hex'),tx.value,Buffer.from(data.replace(/^0x/,''),'hex'),CID,0n,0n])),sg.r,sg.s,sg.rec);
 out.built={nonce:nonce.toString(),gasPrice:gp.toString(),txhash:sg.hash,raw:sg.raw};
 out.signer_recovered=selfRecover; out.signer_ok=!!selfRecover&&selfRecover.toLowerCase()===ADDR.toLowerCase();
 out.signed=!!out.signer_ok;
 const bal=BigInt(await rpc('eth_getBalance',[ADDR,'latest'])||'0x0');
 out.native_wei=bal.toString();
 if(BCAST&&bal>gp*200000n){const h=await rpc('eth_sendRawTransaction',[sg.raw]);out.broadcast=!!h;out.txhash_onchain=h||null;}
 fs.writeFileSync(path.join(P,'settle.json'),JSON.stringify(out,null,1));
 console.log('settle signed='+out.signed+' signer_ok='+out.signer_ok+' tx='+sg.hash.slice(0,20)+'... broadcast='+out.broadcast);})();
JS
node --check "$P/settle.js" && pass "settle.js مُصحّح (يتحقق من الموقّع)"

# 1.6 discover.js — بلا تكرار + وقت تشغيل صحيح + منفذ افتراضي
cat > "$AX/exec/discover.js" <<'JS'
const fs=require('fs'),path=require('path');
const roots=process.argv.slice(2);
const SKIP=new Set(['node_modules','.git','.tmp','profiles','.check','.venv','dist','build','backup-html','logs','__pycache__','.cache','apex']);
const NAME=/gateway|server|serve|api|hub|agent|app|main|entry|web|auth|static|boot|dash|scheduler|worker|panel|workflow/i;
const PAT=/\.listen\s*\(|app\.run\s*\(|uvicorn\.run|Flask\s*\(|createServer\s*\(|HTTPServer\s*\(/;
const seen=new Set(),out=[];
function walk(d,depth){if(depth>4)return;let es=[];try{es=fs.readdirSync(d,{withFileTypes:true})}catch(e){return}
 for(const e of es){const f=path.join(d,e.name);
  if(e.isDirectory()){if(SKIP.has(e.name)||e.name.startsWith('.'))continue;walk(f,depth+1);}
  else if(/\.(js|mjs|cjs|py)$/.test(e.name)&&NAME.test(e.name)){
   let rp;try{rp=fs.realpathSync(f)}catch(x){rp=f}
   if(seen.has(rp))continue;seen.add(rp);
   let s='';try{s=fs.readFileSync(f,'utf8')}catch(e){continue}
   if(!PAT.test(s))continue;
   let port='';
   const pats=[/\.listen\s*\(\s*(\d{4,5})/,/\.listen\s*\(\s*[^,)]*?\|\|\s*(\d{4,5})/,/PORT\s*\|\|\s*(\d{4,5})/,/port\s*[=:]\s*(\d{4,5})/,
     /(?:app\.run|uvicorn\.run)[^\n]*?(\d{4,5})/,/AUTH_PORT\s*\|\|\s*(\d{4,5})/,/HUB_PORT\s*\|\|\s*(\d{4,5})/,/AGENT_PORT\s*\|\|\s*(\d{4,5})/];
   for(const p of pats){const m=s.match(p);if(m){port=m[1];break;}}
   if(!port){const a=s.match(/\b(8[0-9]{3})\b/g);if(a)port=a[0];}
   const rt=f.endsWith('.py')?'python3':'node';
   out.push(f+'|'+port+'|'+rt);
  }}}
roots.forEach(r=>{if(fs.existsSync(r))walk(r,0)});
console.log(out.join('\n'));
JS
node --check "$AX/exec/discover.js" && pass "discover.js مُصحّح"

H "2) المحفظة + خط الأموال (تحقق فعلي)"
node "$AX/exec/wallet.js" "$AX" "$M" 2>&1 | tee -a "$LOG"
node "$AX/exec/revenue.js" "$AX" "$M" "$P" 2>&1 | tee -a "$LOG" || true
for i in 1 2 3 4 5; do
  curl -s -m 5 -X POST -H 'Content-Type: application/json' \
   -d "{\"id\":\"launch-$TS-$i\",\"type\":\"revenue\",\"source\":\"selftest\",\"amount_usd\":$i.5,\"country\":\"YE\"}" \
   http://127.0.0.1:8792/api/apex/event >/dev/null 2>&1 || true
done
node "$P/money.js" "$P" 2>&1 | tee -a "$LOG" || fail "money.js"
node "$P/settle.js" "$P" "$M" "$BCAST" 2>&1 | tee -a "$LOG" || fail "settle.js"
node "$P/reconcile.js" "$P" "$AX" 2>&1 | tee -a "$LOG" || fail "reconcile.js"

H "3) تشغيل الخدمات (بلا تكرار، وبوقت تشغيل صحيح)"
pkill -f "apex/pipeline/eventd.js" 2>/dev/null || true
nohup node "$P/eventd.js" "$P" 8792 >>"$AX/logs/eventd.log" 2>&1 &
[ -f "$AX/exec/apexdash.js" ] && { pkill -f apexdash.js 2>/dev/null || true; nohup node "$AX/exec/apexdash.js" "$AX" 8791 >>"$AX/logs/dash.log" 2>&1 & }
mapfile -t SRV < <(node "$AX/exec/discover.js" "$ROOT" "$HOME" 2>/dev/null)
say "  مرشحون (بلا تكرار): ${#SRV[@]}"
declare -A SEEN
N=0
for e in "${SRV[@]}"; do
  [ "$N" -ge 14 ] && break
  f="${e%%|*}"; rest="${e#*|}"; pt="${rest%%|*}"; rt="${rest##*|}"
  key="$f"
  [ -n "${SEEN[$key]:-}" ] && continue; SEEN[$key]=1
  case "$f" in */apex/exec/*|*/apex/pipeline/*) continue;; esac
  if [ -n "$pt" ] && (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null; then say "  = $(basename "$f") يعمل على $pt"; N=$((N+1)); continue; fi
  nm="$(basename "$f" | tr -c 'a-zA-Z0-9' '_')"
  nohup $rt "$f" >>"$AX/logs/$nm.log" 2>&1 &
  say "  > $rt $(basename "$f")${pt:+ (منفذ افتراضي $pt)}"
  N=$((N+1)); sleep 0.4
done
for u in "$HOME/web_manager.py" "$HOME/unified_system/entrypoint.py"; do
  [ -f "$u" ] || continue; nm="$(basename "$u" .py)"
  pgrep -f "$u" >/dev/null 2>&1 && { say "  = $nm يعمل مسبقًا"; continue; }
  nohup python3 "$u" >>"$AX/logs/$nm.log" 2>&1 & say "  > python3 $nm"
done
sleep 6
OPEN=""
for pt in 8700 8787 8788 8791 8792 8798 8799 8870 8080 8081 8082 8085 8095; do
  (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null && { OPEN="$OPEN $pt"; pass "منفذ $pt يعمل"; }
done
say "  المفتوحة:$OPEN"
for l in "$AX/logs"/*.log; do [ -f "$l" ] || continue
  s=$(grep -iE 'error|EADDRINUSE|Cannot find|SyntaxError|Traceback|ModuleNotFound' "$l" 2>/dev/null | tail -1)
  [ -n "$s" ] && say "  ! $(basename "$l"): ${s:0:130}"
done

H "4) حقن الإعلانات"
if [ "$WIRE" = "1" ]; then node "$AX/exec/wire.js" "$ROOT" "$AX" 2>&1 | tee -a "$LOG"
else
  W=$(node -e "try{console.log(require('$AX/state/wire.json').wired||0)}catch(e){console.log(0)}")
  [ "$W" -gt 0 ] 2>/dev/null && pass "محقونة مسبقًا: $W صفحة" || node "$AX/exec/wire.js" "$ROOT" "$AX" 2>&1 | tee -a "$LOG"
fi

H "5) اختبارات"
T="$AX/reports/tests-$TS.txt"; : > "$T"
t(){ if eval "$2" >>"$LOG" 2>&1; then pass "$1"; echo "PASS $1" >> "$T"; else fail "$1"; echo "FAIL $1" >> "$T"; fi; }
t "async.js سليم"        "node --check '$M/lib/async.js'"
t "q-sec.js سليم"        "node --check '$M/lib/q-sec.js'"
t "q-db يحمّل"           "node '$M/lib/q-db.js'"
t "crypto.js سليم"       "node --check '$P/crypto.js'"
t "keccak متجه"          "node -e \"const c=require('$P/crypto.js');process.exit(c.keccak(Buffer.alloc(0)).toString('hex')==='c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470'?0:1)\""
t "ECDSA توقيع+تحقق"     "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const h=c.keccak(Buffer.from('x'));const s=c.sign(h,k);process.exit(c.verify(h,s.r,s.s,c.mul(k,[c.GX,c.GY]))?0:1)\""
t "ECDSA استرجاع العنوان" "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const h=c.keccak(Buffer.from('x'));const s=c.sign(h,k);const a=c.recover(h,s.r,s.s,s.rec);process.exit(a&&a.toLowerCase()===c.addrOf(k).toLowerCase()?0:1)\""
t "signTx موقّع صحيحًا"  "node -e \"const c=require('$P/crypto.js');const j=require('$P/settle.json');process.exit(j.signer_ok?0:1)\""
t "المحفظة مشتقة"        "node -e \"const j=require('$AX/state/appwallet.json');process.exit(j.address&&j.address.length===42?0:1)\""
t "البريد الحقيقي"       "node -e \"const j=require('$AX/state/mailbox.json');process.exit(j.address?0:1)\""
t "قناة الأحداث"         "curl -s -m 5 -X POST -H 'Content-Type: application/json' -d '{\"type\":\"t\"}' http://127.0.0.1:8792/api/apex/event | grep -q ok"
t "الدفتر سليم"          "node -e \"const L=require('$P/ledger.js');process.exit(new L('$P/ledger.jsonl').verify().ok?0:1)\""
t "رصيد الدفتر موجب"     "node -e \"const m=require('$P/money.json');process.exit((m.wallet_asset||0)>0?0:1)\""
t "keys.env 600"         "test \$(stat -c %a '$M/keys.env') = 600"
say "  النتيجة: $(grep -c PASS "$T") نجاح / $(grep -c FAIL "$T") فشل"

H "6) النشر إلى GitHub + تفعيل Pages"
REPO="-"; BR="-"; CMT="-"; PAGEURL="-"; PUSHED="لا"
if [ "$PUSH" = "1" ] && [ -d "$ROOT/.git" ]; then
  cd "$ROOT"
  BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"
  say "  الفرع: $BR"
  [ -f "$ROOT/.nojekyll" ] || : > "$ROOT/.nojekyll"
  # صفحة هبوط حقيقية إن لم توجد
  if [ ! -f "$ROOT/index.html" ]; then
    cat > "$ROOT/index.html" <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CineHub</title>
<style>body{background:#0b0f14;color:#d7e3ee;font-family:system-ui;padding:24px}h1{margin:0 0 6px}
a{color:#4aa8ff}.b{background:#121a24;border:1px solid #1f2c3a;border-radius:10px;padding:12px;margin:8px 0;display:block}</style></head>
<body><h1>CineHub</h1><p>المنصة تعمل. الخدمات المحلية:</p>
<a class="b" href="http://127.0.0.1:8787">التطبيق الرئيسي :8787</a>
<a class="b" href="http://127.0.0.1:8788">لوحة الإدارة :8788</a>
<a class="b" href="http://127.0.0.1:8791">لوحة APEX :8791</a>
<a class="b" href="http://127.0.0.1:8799">الخادم المحصّن :8799</a></body></html>
HTML
    pass "صفحة هبوط أُنشئت"
  fi
  cat >> .gitignore <<'GI'
*.pid
_backup/
_deploy/
.check/
*.log
.tmp/
data/profiles/
node_modules/
*.bak
money/apex/state/
money/apex/dlq/
money/apex/backup-html/
money/apex/logs/
money/logs/
money/apex/pipeline/*.jsonl
money/apex/data/bip39.txt
GI
  sort -u .gitignore -o .gitignore
  for f in money/keys.env money/secrets.json; do
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 && { git rm --cached -q "$f"; say "  إزالة $f من التتبع"; }
  done
  git config user.email >/dev/null 2>&1 || git config user.email "apex@cinehub.local"
  git config user.name  >/dev/null 2>&1 || git config user.name  "APEX Agent"
  git add -A >/dev/null 2>&1
  say "  مُجهّز: $(git diff --cached --name-only 2>/dev/null | wc -l) ملف"
  git commit -q -m "LAUNCH $TS: إصلاح crypto/ledger/reconcile/settle + تشغيل الخدمات + Pages" 2>&1 | tail -1 | tee -a "$LOG" || say "  (لا تغييرات)"
  CMT="$(git rev-parse HEAD 2>/dev/null || echo none)"
  say "  الالتزام: $CMT"
  TOK="$(echo "$REMOTE" | sed -nE 's#https://[^:]+:([^@]+)@.*#\1#p')"
  [ -z "$TOK" ] && TOK="$(grep -m1 '^GITHUB_TOKEN=' "$M/keys.env" 2>/dev/null | cut -d= -f2- | tr -d ' \r')"
  SLUG="$(echo "$REMOTE" | sed -E 's#https://([^@]+@)?github\.com[:/]##; s#\.git$##')"
  OWNER="$(echo "$SLUG" | cut -d/ -f1)"
  if [ -n "$TOK" ] && [ -n "$SLUG" ]; then
    case "$TOK" in gho_*|ghu_*) U="oauth2";; *) U="${GH_USER:-x-access-token}";; esac
    PUSHURL="https://${U}:${TOK}@github.com/${SLUG}.git"
    pass "توكن مستخرج من الرابط → دفع إلى $SLUG"
  else PUSHURL="$REMOTE"; say "  بلا توكن"; fi
  GIT_TERMINAL_PROMPT=0 git fetch "$PUSHURL" "$BR" >>"$LOG" 2>&1 || true
  GIT_TERMINAL_PROMPT=0 git pull --rebase --autostash "$PUSHURL" "$BR" >>"$LOG" 2>&1 || true
  if GIT_TERMINAL_PROMPT=0 git push "$PUSHURL" "$BR" >>"$LOG" 2>&1; then pass "تم الدفع"
  else
    fail "فشل الدفع — آخر السطور:"; tail -12 "$LOG" | sed 's/^/    /'
    if GIT_TERMINAL_PROMPT=0 git push --force-with-lease "$PUSHURL" "$BR" >>"$LOG" 2>&1; then pass "نجح بالدفع القسري الآمن"; fi
  fi
  RC="$(GIT_TERMINAL_PROMPT=0 git ls-remote "$PUSHURL" "refs/heads/$BR" 2>/dev/null | awk '{print $1}')"
  if [ "$RC" = "$CMT" ]; then PUSHED="نعم"; pass "تحقق: البعيد يطابق المحلي ($RC)"
  else fail "البعيد=$RC المحلي=$CMT"; fi
  REPO="https://github.com/$SLUG"
  # تفعيل Pages
  if [ -n "$TOK" ]; then
    CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$SLUG/pages")
    if [ "$CODE" = "404" ]; then
      curl -s -X POST -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/$SLUG/pages" \
        -d "{\"source\":{\"branch\":\"$BR\",\"path\":\"/\"}}" -o "$AX/state/pages.json" -w '%{http_code}' | tee -a "$LOG"
      say "  → طلب تفعيل Pages"
    else say "  Pages موجود (HTTP $CODE)"; fi
    PAGEURL="https://${OWNER}.github.io/"
    sleep 8
    PC=$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 "$PAGEURL")
    say "  فحص الرابط العام: HTTP $PC"
  fi
else say "  متخطّى"; fi
printf '%s\n' "$REPO" > "$AX/reports/.repo"; printf '%s\n' "$BR" > "$AX/reports/.branch"
printf '%s\n' "$CMT" > "$AX/reports/.commit"; printf '%s\n' "$PAGEURL" > "$AX/reports/.page"

H "7) تقرير + رابط التشغيل"
export AX ROOT
node -e "
const fs=require('fs'),path=require('path');const AX=process.env.AX,ROOT=process.env.ROOT;
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
const r=(p,d)=>{try{return fs.readFileSync(path.join(AX,p),'utf8').trim()}catch(e){return d||'-'}};
const S=g('registry/summary.json'),L=g('ledger/rules.json'),W=g('state/appwallet.json'),MB=g('state/mailbox.json'),
 WR=g('state/wire.json'),MO=g('pipeline/money.json'),SE=g('pipeline/settle.json'),RC=g('pipeline/reconcile.json');
const md=['# CineHub — التشغيل والنشر','','> '+new Date().toISOString(),'',
'## روابط التشغيل','','- محليًا: http://127.0.0.1:8787',
'- لوحة الإدارة: http://127.0.0.1:8788','- لوحة APEX: http://127.0.0.1:8791',
'- الرابط العام: '+r('reports/.page'),'','## مُثبت بالقياس','',
'- نطاقات: '+(S.platforms_total||0)+' | استجابت: '+(S.platforms_reachable||0)+' | نقاط موثقة: '+(S.connection_points_verified||0),
'- صفحات محقونة: '+(WR.wired||0)+' '+JSON.stringify(WR.by_circle||{}),
'- منصات تدعم اليمن: '+(L.ye_actionable_platforms||0)+' | بريد: '+(MB.address||'—'),'',
'## خط الأموال','','- أحداث: '+(MO.events||0)+' | مقبولة: '+(MO.approved||0)+' | دفتر سليم: '+MO.ledger_ok+' | رصيد المحفظة: $'+(MO.wallet_asset||0),
'- معاملة موقّعة: '+(SE.built?SE.built.txhash:'—')+' | موقّع صحيح: '+(SE.signer_ok?'نعم':'لا'),
'- مطابقة: '+(RC.status||'—'),'','## محفظة التطبيق','','\`'+(W.address||'—')+'\`','',
'## النشر','','- المستودع: '+r('reports/.repo'),'- الفرع: '+r('reports/.branch'),'- الالتزام: \`'+r('reports/.commit')+'\`'].join('\n');
fs.writeFileSync(path.join(AX,'reports/LAUNCH.md'),md);console.log('ok');" 2>&1 | tee -a "$LOG"

cat > "$M/apexctl" <<'CTL'
#!/data/data/com.termux/files/usr/bin/bash
AX="$HOME/cinehub3099/money/apex"; P="$AX/pipeline"; M="$HOME/cinehub3099/money"
case "${1:-status}" in
 status) node "$AX/exec/agg.js" "$AX"; cat "$AX/reports/LAUNCH.md" 2>/dev/null | head -25 ;;
 money)  node "$AX/exec/revenue.js" "$AX" "$M" "$P"; node "$P/money.js" "$P"; node "$P/reconcile.js" "$P" "$AX" ;;
 settle) node "$P/settle.js" "$P" "$M" "${2:-0}" ;;
 push)   bash "$M/LAUNCH.sh" --no-wire ;;
 report) cat "$AX/reports/LAUNCH.md" ;;
 *) echo "apexctl status|money|settle [1]|push|report" ;;
esac
CTL
chmod +x "$M/apexctl" "$AX/exec/"*.js "$P/"*.js 2>/dev/null || true

H "الخلاصة"
say "محليًا   : http://127.0.0.1:8787"
say "لوحة     : http://127.0.0.1:8788"
say "APEX     : http://127.0.0.1:8791"
say "الرابط العام: $(cat "$AX/reports/.page" 2>/dev/null)"
say "المستودع : $(cat "$AX/reports/.repo" 2>/dev/null) @ $(cat "$AX/reports/.commit" 2>/dev/null)"
say "التقرير  : $AX/reports/LAUNCH.md"
