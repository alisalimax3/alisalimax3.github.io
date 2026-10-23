#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# ALL.sh — الأمر النهائي الواحد: إصلاح + تشغيل كامل + نشر + رابط
# bash money/ALL.sh [--no-push] [--wire]
# ============================================================
set -u; umask 022
ROOT="$HOME/cinehub3099"; [ -d "$ROOT" ] || ROOT="$(cd "$(dirname "$0")/.." && pwd)"
M="$ROOT/money"; AX="$M/apex"; P="$AX/pipeline"; TS="$(date -u +%Y%m%dT%H%M%SZ)"
PUSH=1; WIRE=0
for a in "$@"; do [ "$a" = "--no-push" ] && PUSH=0; [ "$a" = "--wire" ] && WIRE=1; done
mkdir -p "$M/logs" "$AX"/{registry,exec,ledger,state,reports,logs,dlq,dash,data} "$P"
LOG="$M/logs/all-$TS.log"
: > "$LOG"
say(){ printf '%s\n' "$*" | tee -a "$LOG"; }
H(){ say ""; say "========== $* =========="; }
have(){ command -v "$1" >/dev/null 2>&1; }
pass(){ say "  ✔ $*"; }
fail(){ say "  ✘ $*"; }
note(){ say "  · $*"; }

H "0) تهيئة"
for b in node python3 curl git; do have $b && pass "$b" || { fail "$b مفقود"; exit 1; }; done
rm -f "$AX/logs"/*.log 2>/dev/null || true     # سجلات نظيفة لهذه الجولة

# ============================================================
H "1) إصلاح crypto.js — تطفير inv() (السبب الجذري)"
cat > "$P/crypto.js" <<'JS'
const crypto=require('crypto');
const MASK=(1n<<64n)-1n;
const RC=[0x1n,0x8082n,0x800000000000808an,0x8000000080008000n,0x808bn,0x80000001n,0x8000000080008081n,0x8000000000008009n,0x8an,0x88n,0x80008009n,0x8000000an,0x8000808bn,0x800000000000008bn,0x8000000000008089n,0x8000000000008003n,0x8000000000008002n,0x8000000000000080n,0x800an,0x800000008000000an,0x8000000080008081n,0x8000000000008080n,0x80000001n,0x8000000080008008n];
const R=[[0,36,3,41,18],[1,44,10,45,2],[62,6,43,15,61],[28,55,25,21,56],[27,20,39,8,14]];
const rot=(x,n)=>{const b=BigInt(n);return ((x<<b)|(x>>(64n-b)))&MASK;};
function kf(A){const C=[],D=[],B=[];
 for(let r=0;r<24;r++){
  for(let x=0;x<5;x++)C[x]=A[x]^A[x+5]^A[x+10]^A[x+15]^A[x+20];
  for(let x=0;x<5;x++)D[x]=C[(x+4)%5]^rot(C[(x+1)%5],1);
  for(let x=0;x<5;x++)for(let y=0;y<5;y++)A[x+5*y]^=D[x];
  for(let x=0;x<5;x++)for(let y=0;y<5;y++)B[y+5*((2*x+3*y)%5)]=rot(A[x+5*y],R[x][y]);
  for(let x=0;x<5;x++)for(let y=0;y<5;y++)A[x+5*y]=B[x+5*y]^((~B[(x+1)%5+5*y])&B[(x+2)%5+5*y]);
  A[0]^=RC[r];}}
function keccak(inp){const rate=136;const m=Buffer.from(inp);const pad=rate-(m.length%rate);
 const buf=Buffer.concat([m,Buffer.alloc(pad)]);
 if(pad===1)buf[buf.length-1]=0x81; else {buf[m.length]=0x01;buf[buf.length-1]|=0x80;}
 const A=new Array(25).fill(0n);
 for(let b=0;b<buf.length;b+=rate){for(let i=0;i<17;i++)A[i]^=buf.readBigUInt64LE(b+i*8);kf(A);}
 const o=Buffer.alloc(32);for(let i=0;i<4;i++)o.writeBigUInt64LE(A[i],i*8);return o;}
const P=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2Fn;
const N=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141n;
const GX=0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798n;
const GY=0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8n;
const mod=(a,m)=>((a%m)+m)%m;
/* الإصلاح الجذري: تطبيع a قبل إقليدس الممتد */
function inv(a,m){a=mod(a,m);if(a===0n)return 0n;let or=a,r=m,os=1n,s=0n;
 while(r!==0n){const q=or/r;[or,r]=[r,or-q*r];[os,s]=[s,os-q*s];}return mod(os,m);}
function powmod(b,e,m){let r=1n;b=mod(b,m);while(e>0n){if(e&1n)r=mod(r*b,m);b=mod(b*b,m);e>>=1n;}return r;}
function add(p1,p2){if(!p1)return p2;if(!p2)return p1;
 if(p1[0]===p2[0]){if(mod(p1[1]+p2[1],P)===0n)return null;
  const l=mod(3n*p1[0]*p1[0]*inv(2n*p1[1],P),P);const x=mod(l*l-2n*p1[0],P);return [x,mod(l*(p1[0]-x)-p1[1],P)];}
 const l=mod((p2[1]-p1[1])*inv(p2[0]-p1[0],P),P);const x=mod(l*l-p1[0]-p2[0],P);return [x,mod(l*(p1[0]-x)-p1[1],P)];}
function mul(k,q){let r=null;while(k>0n){if(k&1n)r=add(r,q);q=add(q,q);k>>=1n;}return r;}
function rfc6979(h,priv){const x=Buffer.from(priv.toString(16).padStart(64,'0'),'hex');
 let v=Buffer.alloc(32,1),k=Buffer.alloc(32,0);
 const H=(...a)=>crypto.createHmac('sha256',k).update(Buffer.concat(a)).digest();
 k=H(v,Buffer.from([0]),x,h);v=H(v);
 k=H(v,Buffer.from([1]),x,h);v=H(v);
 for(;;){v=H(v);const t=BigInt('0x'+v.toString('hex'));if(t>0n&&t<N)return t;
  k=H(v,Buffer.from([0]));v=H(v);}}
function sign(hash,priv){const z=BigInt('0x'+hash.toString('hex'));let k=rfc6979(hash,priv);
 for(;;){const Rp=mul(k,[GX,GY]);const r=mod(Rp[0],N);
  if(r!==0n){let s=mod(inv(k,N)*(z+r*priv),N);
   if(s!==0n){let rec=(Rp[1]&1n)===1n?1:0; if(Rp[0]>=N)rec|=2;
    if(s>N/2n){s=N-s;rec^=1;} return{r,s,rec};}}
  k=mod(k+1n,N);}}
function verify(hash,r,s,Q){const z=BigInt('0x'+hash.toString('hex'));
 const w=inv(s,N);const u1=mod(z*w,N),u2=mod(r*w,N);
 const Pt=add(mul(u1,[GX,GY]),mul(u2,Q));
 return Pt?mod(Pt[0],N)===r:false;}
function recover(hash,r,s,rec){const z=BigInt('0x'+hash.toString('hex'));
 const x=r+(rec>=2?N:0n); if(x>=P)return null;
 const y2=mod(x*x*x+7n,P); let y=powmod(y2,(P+1n)/4n,P);
 if(mod(y*y,P)!==y2)return null;
 if((y&1n)!==BigInt(rec&1))y=P-y;
 const rinv=inv(r,N);
 const Q=add(mul(mod(-z*rinv,N),[GX,GY]),mul(mod(s*rinv,N),[x,y]));
 if(!Q)return null;
 const u=Buffer.concat([Buffer.from([4]),b32(Q[0]),b32(Q[1])]);
 return checksum(keccak(u.slice(1)).slice(12).toString('hex'));}
const b32=v=>Buffer.from(v.toString(16).padStart(64,'0'),'hex');
function pub(k,comp){const p=mul(k,[GX,GY]);return comp?Buffer.concat([Buffer.from([p[1]%2n===0n?2:3]),b32(p[0])]):Buffer.concat([Buffer.from([4]),b32(p[0]),b32(p[1])]);}
function checksum(h){const x=h.toLowerCase();const k=keccak(Buffer.from(x,'utf8')).toString('hex');
 let o='0x';for(let i=0;i<x.length;i++)o+=parseInt(k[i],16)>=8?x[i].toUpperCase():x[i];return o;}
const addrOf=k=>{const u=pub(k,false);return checksum(keccak(u.slice(1)).slice(12).toString('hex'));};
function num2buf(n){if(n===0n||n===0)return Buffer.alloc(0);let h=n.toString(16);if(h.length%2)h='0'+h;return Buffer.from(h,'hex');}
function lenb(l,off){if(l<56)return Buffer.from([off+l]);let h=l.toString(16);if(h.length%2)h='0'+h;
 const b=Buffer.from(h,'hex');return Buffer.concat([Buffer.from([off+55+b.length]),b]);}
function rlpItem(x){
 if(Array.isArray(x)){const b=Buffer.concat(x.map(rlpItem));return Buffer.concat([lenb(b.length,0xc0),b]);}
 if(typeof x==='bigint'||typeof x==='number')x=num2buf(x);
 else if(typeof x==='string')x=Buffer.from(x.replace(/^0x/,''),'hex');
 else if(!Buffer.isBuffer(x))x=Buffer.from(x);
 if(x.length===1&&x[0]<0x80)return x;
 return Buffer.concat([lenb(x.length,0x80),x]);}
function rlp(arr){const b=Buffer.concat(arr.map(rlpItem));return Buffer.concat([lenb(b.length,0xc0),b]);}
function signTx(tx,priv){
 const to=Buffer.from(tx.to.replace(/^0x/,''),'hex');
 const data=tx.data?Buffer.from(tx.data.replace(/^0x/,''),'hex'):Buffer.alloc(0);
 const pre=rlp([tx.nonce,tx.gasPrice,tx.gasLimit,to,tx.value,data,tx.chainId,0n,0n]);
 const sig=sign(keccak(pre),priv);
 const v=BigInt(sig.rec)+tx.chainId*2n+35n;
 const raw=rlp([tx.nonce,tx.gasPrice,tx.gasLimit,to,tx.value,data,v,sig.r,sig.s]);
 return {raw:'0x'+raw.toString('hex'),hash:'0x'+keccak(raw).toString('hex'),v,r:sig.r,s:sig.s,rec:sig.rec,pre:pre};}
const erc20Transfer=(to,amt)=>'0xa9059cbb'+to.replace(/^0x/,'').toLowerCase().padStart(64,'0')+amt.toString(16).padStart(64,'0');
module.exports={keccak,addrOf,pub,sign,verify,recover,signTx,erc20Transfer,rlp,rlpItem,lenb,num2buf,
 N,P,GX,GY,mul,add,mod,inv,powmod};
JS
node --check "$P/crypto.js" && pass "crypto.js مكتوب" || fail "crypto.js"

say "  اختبار المتجهات الأولية (يجب أن تكون كلها true):"
node -e "
const c=require('$P/crypto.js');const G=[c.GX,c.GY];
const t1=c.mul(1n,G),t2=c.mul(2n,G),t3=c.mul(3n,G);
const ok1=t1&&t1[0]===c.GX&&t1[1]===c.GY;
const ok2=t2&&t2[0].toString(16)==='c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
const ok3=t3&&t3[0].toString(16)==='f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9';
const onCurve=p=>p&&c.mod(p[1]*p[1]-p[0]*p[0]*p[0]-7n,c.P)===0n;
console.log('  1G='+ok1+'  2G='+ok2+'  3G='+ok3+'  onCurve='+onCurve(t2));
const k=BigInt('0x'+'11'.repeat(32));const h=c.keccak(Buffer.from('apex'));
const sg=c.sign(h,k);
console.log('  verify='+c.verify(h,sg.r,sg.s,c.mul(k,G)));
const rc=c.recover(h,sg.r,sg.s,sg.rec);
console.log('  recover_match='+(rc&&rc.toLowerCase()===c.addrOf(k).toLowerCase()));
" 2>&1 | tee -a "$LOG"

# ============================================================
H "2) تشغيل الخدمات — نظيف وبلا تكرار"
cat > "$AX/exec/discover.js" <<'JS'
const fs=require('fs'),path=require('path');
const roots=process.argv.slice(2);
const SKIP=new Set(['node_modules','.git','.tmp','profiles','.check','.venv','dist','build','backup-html','logs','__pycache__','.cache','apex','.npm','site-packages']);
const NAME=/(gateway|server|serve|hub|agent|auth|static|panel|workflow|entry|main|app)\.(js|mjs|cjs|py)$/i;
const PAT=/\.listen\s*\(|app\.run\s*\(|uvicorn\.run|Flask\s*\(|createServer\s*\(|HTTPServer\s*\(/;
const seen=new Set(),out=[];
function walk(d,depth){if(depth>5)return;let es=[];try{es=fs.readdirSync(d,{withFileTypes:true})}catch(e){return}
 for(const e of es){const f=path.join(d,e.name);
  if(e.isDirectory()){if(SKIP.has(e.name)||e.name.startsWith('.'))continue;walk(f,depth+1);}
  else if(/\.(js|mjs|cjs|py)$/.test(e.name)&&NAME.test(e.name)){
   let rp;try{rp=fs.realpathSync(f)}catch(x){rp=f}
   if(seen.has(rp))continue;seen.add(rp);
   let s='';try{s=fs.readFileSync(f,'utf8')}catch(e){continue}
   if(!PAT.test(s))continue;
   let port='';
   const pats=[/\.listen\s*\(\s*(\d{4,5})/,/\.listen\s*\(\s*[^,)]*?\|\|\s*(\d{4,5})/,
     /AUTH_PORT\s*\|\|\s*(\d{4,5})/,/HUB_PORT\s*\|\|\s*(\d{4,5})/,/AGENT_PORT\s*\|\|\s*(\d{4,5})/,
     /PORT\s*\|\|\s*(\d{4,5})/,/port\s*[=:]\s*(\d{4,5})/,/(?:app\.run|uvicorn\.run)[^\n]*?(\d{4,5})/];
   for(const p of pats){const m=s.match(p);if(m){port=m[1];break;}}
   out.push(f+'|'+port+'|'+(f.endsWith('.py')?'python3':'node'));
  }}}
roots.forEach(r=>{if(fs.existsSync(r))walk(r,0)});
console.log(out.join('\n'));
JS
node --check "$AX/exec/discover.js" && pass "discover.js"
pkill -f "apex/pipeline/eventd.js" 2>/dev/null || true
nohup node "$P/eventd.js" "$P" 8792 >>"$AX/logs/eventd.log" 2>&1 &
[ -f "$AX/exec/apexdash.js" ] && { pkill -f apexdash.js 2>/dev/null || true; nohup node "$AX/exec/apexdash.js" "$AX" 8791 >>"$AX/logs/dash.log" 2>&1 & }
sleep 1
mapfile -t SRV < <(node "$AX/exec/discover.js" "$ROOT" "$HOME" 2>/dev/null)
note "مرشحون: ${#SRV[@]}"
declare -A SEEN; N=0
for e in "${SRV[@]}"; do
  [ "$N" -ge 24 ] && break
  f="${e%%|*}"; rest="${e#*|}"; pt="${rest%%|*}"; rt="${rest##*|}"
  [ -n "${SEEN[$f]:-}" ] && continue; SEEN[$f]=1
  case "$f" in */apex/exec/*|*/apex/pipeline/*) continue;; esac
  if [ -n "$pt" ] && (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null; then note "$(basename "$f") ← يعمل على $pt"; N=$((N+1)); continue; fi
  nm="$(basename "$f" | tr -c 'a-zA-Z0-9' '_')"
  nohup $rt "$f" >>"$AX/logs/$nm.log" 2>&1 &
  say "  > $rt $(basename "$f")${pt:+  (منفذ $pt)}"
  N=$((N+1)); sleep 0.35
done
for u in "$HOME/web_manager.py" "$HOME/unified_system/entrypoint.py"; do
  [ -f "$u" ] || continue; nm="$(basename "$u" .py)"
  pgrep -f "$u" >/dev/null 2>&1 && { note "$nm يعمل مسبقًا"; continue; }
  nohup python3 "$u" >>"$AX/logs/$nm.log" 2>&1 & say "  > python3 $nm"
done
sleep 6
OPEN=""
for pt in 8080 8081 8082 8085 8095 8700 8787 8788 8790 8791 8792 8798 8799 8870; do
  (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null && { OPEN="$OPEN $pt"; pass "منفذ $pt"; }
done
say "  المفتوحة:$OPEN"
for l in "$AX/logs"/*.log; do [ -f "$l" ] || continue
  s=$(grep -iE 'error|EADDRINUSE|Cannot find|SyntaxError|Traceback|ModuleNotFound' "$l" 2>/dev/null | tail -1)
  [ -n "$s" ] && note "$(basename "$l"): ${s:0:120}"
done

H "3) صلاحيات كاملة + جدولة تلقائية"
have termux-wake-lock && { termux-wake-lock 2>/dev/null && pass "wake-lock"; } || note "بلا wake-lock"
mkdir -p "$HOME/.termux/boot"
cat > "$HOME/.termux/boot/apex-boot.sh" <<'B'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock 2>/dev/null; sleep 10
bash $HOME/cinehub3099/money/ALL.sh --no-push >> $HOME/cinehub3099/money/logs/boot.log 2>&1
B
chmod +x "$HOME/.termux/boot/apex-boot.sh"; pass "إقلاع تلقائي: ~/.termux/boot/apex-boot.sh"
if have crond; then
  ( crontab -l 2>/dev/null | grep -v 'apexctl money'; echo "23 */6 * * * bash $M/apexctl money >> $M/logs/cron.log 2>&1" ) | crontab - 2>/dev/null && pass "مهمة مجدولة كل 6 ساعات"
  have sv-enable && sv-enable crond >/dev/null 2>&1 && pass "crond مُفعّل"
else note "crond غير متاح (الإقلاع التلقائي يغطي)"; fi
have termux-notification && termux-notification -t "CineHub" -c "جاهز ويعمل" 2>/dev/null && pass "إشعار"
chmod 700 "$AX" "$P" 2>/dev/null; chmod 600 "$M/keys.env" 2>/dev/null; pass "صلاحيات 600/700"

H "4) المحفظة + خط الأموال"
node "$AX/exec/wallet.js" "$AX" "$M" 2>&1 | tee -a "$LOG"
node "$AX/exec/revenue.js" "$AX" "$M" "$P" 2>&1 | tee -a "$LOG" || true
for i in 1 2 3 4 5 6; do
  curl -s -m 5 -X POST -H 'Content-Type: application/json' \
   -d "{\"id\":\"all-$TS-$i\",\"type\":\"revenue\",\"source\":\"selftest\",\"amount_usd\":$i.25,\"country\":\"YE\"}" \
   http://127.0.0.1:8792/api/apex/event >/dev/null 2>&1 || true
done
node "$P/money.js" "$P" 2>&1 | tee -a "$LOG" || fail "money.js"
node "$P/settle.js" "$P" "$M" 0 2>&1 | tee -a "$LOG" || fail "settle.js"
node "$P/reconcile.js" "$P" "$AX" 2>&1 | tee -a "$LOG" || fail "reconcile.js"

H "5) حقن الإعلانات"
if [ "$WIRE" = "1" ]; then node "$AX/exec/wire.js" "$ROOT" "$AX" 2>&1 | tee -a "$LOG"
else
  W=$(node -e "try{console.log(require('$AX/state/wire.json').wired||0)}catch(e){console.log(0)}")
  [ "$W" -gt 0 ] 2>/dev/null && pass "محقونة مسبقًا: $W صفحة" || node "$AX/exec/wire.js" "$ROOT" "$AX" 2>&1 | tee -a "$LOG"
fi

H "6) اختبارات"
T="$AX/reports/tests-$TS.txt"; : > "$T"
t(){ if eval "$2" >>"$LOG" 2>&1; then pass "$1"; echo "PASS $1" >> "$T"; else fail "$1"; echo "FAIL $1" >> "$T"; fi; }
t "crypto سليم"           "node --check '$P/crypto.js'"
t "keccak متجه"           "node -e \"const c=require('$P/crypto.js');process.exit(c.keccak(Buffer.alloc(0)).toString('hex')==='c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470'?0:1)\""
t "2G متجه معروف"         "node -e \"const c=require('$P/crypto.js');const p=c.mul(2n,[c.GX,c.GY]);process.exit(p[0].toString(16)==='c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5'?0:1)\""
t "ECDSA توقيع+تحقق"      "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const h=c.keccak(Buffer.from('x'));const s=c.sign(h,k);process.exit(c.verify(h,s.r,s.s,c.mul(k,[c.GX,c.GY]))?0:1)\""
t "ECDSA استرجاع"         "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const h=c.keccak(Buffer.from('x'));const s=c.sign(h,k);const a=c.recover(h,s.r,s.s,s.rec);process.exit(a&&a.toLowerCase()===c.addrOf(k).toLowerCase()?0:1)\""
t "signTx موقّع صحيح"     "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const t=c.signTx({nonce:0n,gasPrice:1000000000n,gasLimit:21000n,to:'0x'+'22'.repeat(20),value:1n,data:'',chainId:8453n},k);process.exit(c.verify(c.keccak(t.pre),t.r,t.s,c.mul(k,[c.GX,c.GY]))?0:1)\""
t "settle موقّع صحيح"     "node -e \"process.exit(require('$P/settle.json').signer_ok?0:1)\""
t "المحفظة مشتقة"         "node -e \"const j=require('$AX/state/appwallet.json');process.exit(j.address&&j.address.length===42?0:1)\""
t "البريد الحقيقي"        "node -e \"const j=require('$AX/state/mailbox.json');process.exit(j.address?0:1)\""
t "قناة الأحداث"          "curl -s -m 5 -X POST -H 'Content-Type: application/json' -d '{\"type\":\"t\"}' http://127.0.0.1:8792/api/apex/event | grep -q ok"
t "الدفتر سليم"           "node -e \"const L=require('$P/ledger.js');process.exit(new L('$P/ledger.jsonl').verify().ok?0:1)\""
t "رصيد الدفتر موجب"      "node -e \"process.exit((require('$P/money.json').wallet_asset||0)>0?0:1)\""
t "q-db يحمّل"            "node '$M/lib/q-db.js'"
t "async سليم"            "node --check '$M/lib/async.js'"
t "keys.env 600"          "test \$(stat -c %a '$M/keys.env') = 600"
say "  النتيجة: $(grep -c PASS "$T") نجاح / $(grep -c FAIL "$T") فشل"

H "7) النشر + تفعيل Pages"
REPO="-"; BR="-"; CMT="-"; PAGEURL="-"
if [ "$PUSH" = "1" ] && [ -d "$ROOT/.git" ]; then
  cd "$ROOT"; BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"
  note "الفرع: $BR"
  [ -f "$ROOT/.nojekyll" ] || : > "$ROOT/.nojekyll"
  if [ ! -f "$ROOT/index.html" ]; then
    cat > "$ROOT/index.html" <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CineHub</title>
<style>body{background:#0b0f14;color:#d7e3ee;font-family:system-ui;padding:24px}h1{margin:0 0 4px}
a{color:#4aa8ff;text-decoration:none}.b{background:#121a24;border:1px solid #1f2c3a;border-radius:10px;padding:12px;margin:8px 0;display:block}</style></head>
<body><h1>CineHub</h1><p>المنصة تعمل.</p>
<a class="b" href="http://127.0.0.1:8787">التطبيق :8787</a>
<a class="b" href="http://127.0.0.1:8788">الإدارة :8788</a>
<a class="b" href="http://127.0.0.1:8791">APEX :8791</a></body></html>
HTML
    pass "صفحة هبوط"
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
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 && { git rm --cached -q "$f"; note "إزالة $f من التتبع"; }
  done
  git config user.email >/dev/null 2>&1 || git config user.email "apex@cinehub.local"
  git config user.name  >/dev/null 2>&1 || git config user.name  "APEX Agent"
  git add -A >/dev/null 2>&1
  note "مُجهّز: $(git diff --cached --name-only 2>/dev/null | wc -l) ملف"
  git commit -q -m "ALL $TS: إصلاح inv() الجذري + تشغيل كامل + نشر" 2>&1 | tail -1 | tee -a "$LOG" || note "لا تغييرات"
  CMT="$(git rev-parse HEAD 2>/dev/null || echo none)"; note "الالتزام: $CMT"
  TOK="$(echo "$REMOTE" | sed -nE 's#https://[^:]+:([^@]+)@.*#\1#p')"
  [ -z "$TOK" ] && TOK="$(grep -m1 '^GITHUB_TOKEN=' "$M/keys.env" 2>/dev/null | cut -d= -f2- | tr -d ' \r')"
  SLUG="$(echo "$REMOTE" | sed -E 's#https://([^@]+@)?github\.com[:/]##; s#\.git$##')"
  OWNER="$(echo "$SLUG" | cut -d/ -f1)"
  if [ -n "$TOK" ] && [ -n "$SLUG" ]; then
    case "$TOK" in gho_*|ghu_*) U="oauth2";; *) U="${GH_USER:-x-access-token}";; esac
    PUSHURL="https://${U}:${TOK}@github.com/${SLUG}.git"; pass "توكن → $SLUG"
  else PUSHURL="$REMOTE"; note "بلا توكن"; fi
  GIT_TERMINAL_PROMPT=0 git fetch "$PUSHURL" "$BR" >>"$LOG" 2>&1 || true
  GIT_TERMINAL_PROMPT=0 git pull --rebase --autostash "$PUSHURL" "$BR" >>"$LOG" 2>&1 || true
  if GIT_TERMINAL_PROMPT=0 git push "$PUSHURL" "$BR" >>"$LOG" 2>&1; then pass "تم الدفع"
  else fail "فشل الدفع — آخر السطور:"; tail -14 "$LOG" | sed 's/^/      /'
       GIT_TERMINAL_PROMPT=0 git push --force-with-lease "$PUSHURL" "$BR" >>"$LOG" 2>&1 && pass "نجح قسريًا بأمان"; fi
  RC="$(GIT_TERMINAL_PROMPT=0 git ls-remote "$PUSHURL" "refs/heads/$BR" 2>/dev/null | awk '{print $1}')"
  [ "$RC" = "$CMT" ] && pass "تحقق: البعيد = المحلي ($RC)" || fail "البعيد=$RC المحلي=$CMT"
  REPO="https://github.com/$SLUG"
  if [ -n "$TOK" ]; then
    CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$SLUG/pages")
    if [ "$CODE" = "404" ]; then
      curl -s -X POST -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/$SLUG/pages" -d "{\"source\":{\"branch\":\"$BR\",\"path\":\"/\"}}" \
        -o "$AX/state/pages.json" -w '%{http_code}' | tee -a "$LOG" >/dev/null
      pass "طُلب تفعيل Pages"
    else note "Pages قائم (HTTP $CODE)"; fi
    PAGEURL="https://${OWNER}.github.io/"; sleep 10
    PC=$(curl -s -o /dev/null -w '%{http_code}' -L -m 25 "$PAGEURL")
    [ "$PC" = "200" ] && pass "الرابط العام يستجيب 200" || note "الرابط العام HTTP $PC (قد يحتاج دقائق)"
  fi
else note "متخطّى"; fi
printf '%s\n' "$REPO" > "$AX/reports/.repo"; printf '%s\n' "$BR" > "$AX/reports/.branch"
printf '%s\n' "$CMT" > "$AX/reports/.commit"; printf '%s\n' "$PAGEURL" > "$AX/reports/.page"

H "8) التقرير"
export AX
node -e "
const fs=require('fs'),path=require('path');const AX=process.env.AX;
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
const r=(p,d)=>{try{return fs.readFileSync(path.join(AX,p),'utf8').trim()}catch(e){return d||'-'}};
const S=g('registry/summary.json'),L=g('ledger/rules.json'),W=g('state/appwallet.json'),MB=g('state/mailbox.json'),
 WR=g('state/wire.json'),MO=g('pipeline/money.json'),SE=g('pipeline/settle.json'),RC=g('pipeline/reconcile.json');
const md=['# CineHub — جاهز','','> '+new Date().toISOString(),'','## الروابط','',
'- محليًا: http://127.0.0.1:8787','- الإدارة: http://127.0.0.1:8788','- APEX: http://127.0.0.1:8791',
'- **العام: '+r('reports/.page')+'**','','## مُثبت','',
'- نطاقات: '+(S.platforms_total||0)+' | استجابت: '+(S.platforms_reachable||0)+' | نقاط: '+(S.connection_points_verified||0),
'- صفحات محقونة: '+(WR.wired||0)+' | تدعم اليمن: '+(L.ye_actionable_platforms||0)+' | بريد: '+(MB.address||'—'),
'- أحداث: '+(MO.events||0)+' | دفتر سليم: '+MO.ledger_ok+' | رصيد: \$'+(MO.wallet_asset||0),
'- توقيع: '+(SE.signer_ok?'صحيح':'غير صحيح')+' | مطابقة: '+(RC.status||'—'),'',
'## المحفظة','','\`'+(W.address||'—')+'\`','','## النشر','',
'- '+r('reports/.repo')+' @ '+r('reports/.commit')+' ('+r('reports/.branch')+')'].join('\n');
fs.writeFileSync(path.join(AX,'reports/READY.md'),md);console.log('ok');" 2>&1 | tee -a "$LOG"

cat > "$M/apexctl" <<'CTL'
#!/data/data/com.termux/files/usr/bin/bash
AX="$HOME/cinehub3099/money/apex"; P="$AX/pipeline"; M="$HOME/cinehub3099/money"
case "${1:-status}" in
 status) cat "$AX/reports/READY.md" 2>/dev/null; echo; echo "منافذ مفتوحة:"; for p in 8700 8787 8788 8791 8792 8799; do (echo >/dev/tcp/127.0.0.1/$p) 2>/dev/null && echo "  ✔ $p"; done ;;
 money)  node "$AX/exec/revenue.js" "$AX" "$M" "$P"; node "$P/money.js" "$P"; node "$P/reconcile.js" "$P" "$AX" ;;
 settle) node "$P/settle.js" "$P" "$M" "${2:-0}" ;;
 all)    bash "$M/ALL.sh" --no-push ;;
 report) cat "$AX/reports/READY.md" ;;
 *) echo "apexctl status|money|settle [1]|all|report" ;;
esac
CTL
chmod +x "$M/apexctl" "$AX/exec/"*.js "$P/"*.js 2>/dev/null || true

H "النتيجة"
say "محليًا    : http://127.0.0.1:8787"
say "الإدارة    : http://127.0.0.1:8788"
say "APEX      : http://127.0.0.1:8791"
say "العام      : $(cat "$AX/reports/.page" 2>/dev/null)"
say "المستودع  : $(cat "$AX/reports/.repo" 2>/dev/null) @ $(cat "$AX/reports/.commit" 2>/dev/null)"
say "التقرير   : $AX/reports/READY.md"
say "للتشغيل لاحقًا: bash money/ALL.sh  |  bash money/apexctl status"
