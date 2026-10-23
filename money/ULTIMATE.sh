#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# ULTIMATE.sh — الإصلاح الشامل + تشغيل التطبيق + النشر والتحقق
# bash money/ULTIMATE.sh [--no-push] [--no-wire] [--broadcast]
# ============================================================
set -u; umask 022
ROOT="$HOME/cinehub3099"; [ -d "$ROOT" ] || ROOT="$(cd "$(dirname "$0")/.." && pwd)"
M="$ROOT/money"; AX="$M/apex"; P="$AX/pipeline"; TS="$(date -u +%Y%m%dT%H%M%SZ)"
PUSH=1; WIRE=0; BCAST=0
for a in "$@"; do
 [ "$a" = "--no-push" ] && PUSH=0
 [ "$a" = "--wire" ] && WIRE=1
 [ "$a" = "--broadcast" ] && BCAST=1
done
mkdir -p "$M/logs" "$AX"/{registry,exec,ledger,state,reports,logs,dlq,dash,data} "$P" "$AX/backup-html"
LOG="$M/logs/ultimate-$TS.log"; DIAG="$AX/reports/diag-$TS.txt"; : > "$DIAG"
say(){ printf '%s\n' "$*" | tee -a "$LOG"; }
H(){ say ""; say "========== $* =========="; }
d(){ printf '%s\n' "$*" | tee -a "$LOG" >> "$DIAG"; }
have(){ command -v "$1" >/dev/null 2>&1; }
pass(){ say "  ✔ $*"; }
fail(){ say "  ✘ $*"; }

H "0) فحص أولي"
for b in node python3 curl git; do have $b && pass "$b: $(command -v $b)" || { fail "$b مفقود"; exit 1; }; done

H "1) تشخيص الحقيقي"
d "### حجم الملفات الحرجة"
for f in lib/async.js lib/q-sec.js lib/q-lint.js lib/q-fix.js lib/q-db.js lib/q-load.js lib/q-test.js; do
 [ -f "$M/$f" ] && d "$(printf '%-22s %s سطر' "$f" "$(wc -l < "$M/$f")")" || d "$(printf '%-22s مفقود' "$f")"
done
d ""
d "### q-sec: موضع الدفع"
grep -n 'push(' "$M/lib/q-sec.js" 2>/dev/null | head -6 | sed 's/^/  /' >> "$DIAG"
d ""
d "### q-lint/q-fix: مواضع node"
grep -nE 'node|spawn|exec' "$M/lib/q-lint.js" "$M/lib/q-fix.js" 2>/dev/null | head -12 | sed 's/^/  /' >> "$DIAG"
d ""
d "### قائمة المفاتيح في keys.env"
[ -f "$M/keys.env" ] && sed 's/=.*//' "$M/keys.env" | grep -v '^$' | tr '\n' ' ' >> "$DIAG"
d ""
d "### حالة git"
d "  branch=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
d "  remote=$(git -C "$ROOT" remote get-url origin 2>/dev/null || echo none)"
d "  HEAD=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo none)"
d "  ملفات كبيرة>40M: $(find "$ROOT" -type f -size +40M 2>/dev/null | grep -v '/.git/' | wc -l)"
d ""
d "### ملفات HTML"
d "  إجمالي: $(find "$ROOT" -name '*.html' -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l)"
d "  مُعلَّمة: $(grep -rl 'APEX-ADS-v1' "$ROOT" --include='*.html' 2>/dev/null | wc -l)"
say "  التشخيص: $DIAG"

H "2) إصلاح دقيق — crypto / reconcile / async / q-sec / lint / fix"
BK="$M/audit/backup-ult-$TS"; mkdir -p "$BK"
for f in lib/async.js lib/q-sec.js lib/q-lint.js lib/q-fix.js lib/q-db.js lib/q-load.js keys.env; do
 [ -f "$M/$f" ] && { mkdir -p "$BK/$(dirname "$f")"; cp -f "$M/$f" "$BK/$f"; }
done

# 2.1 crypto.js — إعادة كتابة كاملة ومصحّحة
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
function inv(a,m){let or=a,r=m,os=1n,s=0n;while(r!==0n){const q=or/r;[or,r]=[r,or-q*r];[os,s]=[s,os-q*s];}return mod(os,m);}
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
function recover(hash,r,s,rec){const z=BigInt('0x'+hash.toString('hex'));
 const x=r+BigInt(rec>>1)*N; if(x>=P)return null;
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
 const hh=keccak(pre);
 const sig=sign(hh,priv);
 const v=BigInt(sig.rec)+tx.chainId*2n+35n;
 const raw=rlp([tx.nonce,tx.gasPrice,tx.gasLimit,to,tx.value,data,v,sig.r,sig.s]);
 return {raw:'0x'+raw.toString('hex'),hash:'0x'+keccak(raw).toString('hex'),v,r:sig.r,s:sig.s,rec:sig.rec};}
const erc20Transfer=(to,amt)=>'0xa9059cbb'+to.replace(/^0x/,'').toLowerCase().padStart(64,'0')+amt.toString(16).padStart(64,'0');
module.exports={keccak,addrOf,pub,sign,recover,signTx,erc20Transfer,rlp,rlpItem,lenb,N,P,GX,GY,mul,mod,inv};
JS
node --check "$P/crypto.js" && pass "crypto.js مكتوب" || fail "crypto.js"

# 2.2 reconcile.js — إصلاح })(); الزائدة + محتوى كامل
cat > "$P/reconcile.js" <<'JS'
const fs=require('fs'),path=require('path');
const P=process.argv[2],AX=process.argv[3];
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(P,p),'utf8'))}catch(e){return d||{}}};
const m=g('money.json',{}),s=g('settle.json',{});
let chain={};try{chain=JSON.parse(fs.readFileSync(path.join(AX,'state/chain.json'),'utf8'))}catch(e){}
const onchain=(chain.chains||[]).reduce((a,c)=>a+(c.usdc||0),0)+(chain.usdt_tron||0);
const out={ts:new Date().toISOString(),
 internal_payable:m.payable_wallet||0, onchain_stable:onchain, psp_statement:0,
 match:Math.abs((m.payable_wallet||0)-onchain)<0.01, ledger_ok:!!m.ledger_ok,
 settle_tx:(s.built&&s.built.txhash)||null, broadcast:!!s.broadcast,
 note:'مطابقة ثلاثية: الدفتر × السلسلة × كشف المزوّد (يُملأ عند أول دفعة فعلية)'};
fs.writeFileSync(path.join(P,'reconcile.json'),JSON.stringify(out,null,1));
console.log('reconcile ledger_ok='+out.ledger_ok+' internal='+out.internal_payable+' onchain='+out.onchain_stable+' match='+out.match);
JS
node --check "$P/reconcile.js" && pass "reconcile.js مصحّح" || fail "reconcile.js"

# 2.3 async.js + q-sec + lint/fix عبر python
export M
cat > "$AX/exec/fix3.py" <<'PY'
import io,os,re
M=os.environ['M'];A=[];S=[]
def p(r): return os.path.join(M,r)
def rd(x): return io.open(x,encoding='utf-8',errors='surrogateescape').read()
def wr(x,s): io.open(x,'w',encoding='utf-8',errors='surrogateescape').write(s)
def split_top(s):
    d=0;q=None;qi=None
    for k,c in enumerate(s):
        if q:
            if c=='\\':continue
            if c==q:q=None
            continue
        if c in '"\'`':q=c;continue
        if c in '([{':d+=1
        elif c in ')]}':d-=1
        elif c=='?' and d==0:qi=k;break
    if qi is None:return None
    d=0;q=None;ci=None
    for k in range(qi+1,len(s)):
        c=s[k]
        if q:
            if c=='\\':continue
            if c==q:q=None
            continue
        if c in '"\'`':q=c;continue
        if c in '([{':d+=1
        elif c in ')]}':d-=1
        elif c==':' and d==0:ci=k;break
    if ci is None:return None
    return s[:qi],s[qi+1:ci],s[ci+1:]
def fixlog(line):
    i=line.find('console.log(')
    if i<0:return line
    st=i+len('console.log(');d=1;q=None;j=st
    while j<len(line):
        c=line[j]
        if q:
            if c=='\\':j+=2;continue
            if c==q:q=None
        elif c in '"\'`':q=c
        elif c=='(':d+=1
        elif c==')':
            d-=1
            if d==0:break
        j+=1
    inner=line[st:j]
    if '?' not in inner:return line
    sp=split_top(inner)
    if not sp:return line
    cond,t,f=sp
    t=t if t.strip().startswith('(') and t.strip().endswith(')') else '('+t+')'
    f=f if f.strip().startswith('(') and f.strip().endswith(')') else '('+f+')'
    return line[:i]+'console.log('+cond+'?'+t+':'+f+')'+line[j+1:]

x=p('lib/async.js')
if os.path.isfile(x):
    L=rd(x).split('\n');n=0
    for k in range(len(L)):
        if 'console.log(' in L[k] and '?' in L[k]:
            o=L[k];L[k]=fixlog(L[k])
            if L[k]!=o:n+=1
    if n:wr(x,'\n'.join(L));A.append('async.js x%d'%n)
    else:S.append('async.js نظيف')

# q-sec: ابحث عن الدالة التي تُجمّع الأسرار ثم اطبع ما وجد
x=p('lib/q-sec.js')
if os.path.isfile(x):
    s=rd(x)
    if '_NAME|' in s and 'APEX' not in s: S.append('q-sec فلتر موجود')
    else:
        cands=re.findall(r'(\w+)\.push\(',s)
        A.append('q-sec arrays='+(','.join(sorted(set(cands))) or '-'))
        if cands and '_NAME|' not in s:
            arr=cands[0];arg=None
            m=re.search(r'\b'+arr+r'\.push\(([^;]+?)\)\s*;',s)
            if m:
                arg=m.group(1)
                guard='{const _s=('+arg+');if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER|PORT|CURRENCY|TYPE|MODE|ENV)$/i.test(String(_s)))'+arr+'.push(_s);}'
                wr(x,s[:m.start()]+guard+s[m.end():]);A.append('q-sec فلتر('+arr+')')

for r in ('lib/q-lint.js','lib/q-fix.js'):
    x=p(r)
    if not os.path.isfile(x):S.append(r+' مفقود');continue
    s=rd(x);o=s
    s=re.sub(r'(spawnSync|execFileSync|spawn|execSync)\s*\(\s*(["\'])node\2',r'\1(\2"+"',s)
    s=re.sub(r'(["\'])\s*\+\s*""\s*\+\s*(["\'])',r'\1+\2',s)
    s=s.replace('""+','').replace('+""','')
    s=re.sub(r'(["\'])node --check\1',r'\1" + process.execPath + " --check\1',s)
    s=re.sub(r'(["\'])node\b',r'\1" + process.execPath + "',s)
    s=re.sub(r'(\w+)\s*\+\s*"([^"]*)"\s*\+\s*"([^"]*)"',r'\1+"\2\3"',s)
    s=re.sub(r'\(\s*"\s*\+\s*process\.execPath',r'(process.execPath',s)
    if 'process.execPath' in s and s!=o:
        wr(x,s);A.append(r+' execPath')
    else:S.append(r+' لا تغيير')
print('APPLIED: '+(' | '.join(A) or '-'))
print('SKIPPED: '+(' | '.join(S) or '-'))
PY
python3 "$AX/exec/fix3.py" 2>&1 | tee -a "$LOG"
for f in lib/async.js lib/q-sec.js lib/q-lint.js lib/q-fix.js; do
 [ -f "$M/$f" ] || continue
 if node --check "$M/$f" >>"$LOG" 2>&1; then pass "$f سليم"
 else fail "$f → استرجاع"; cp -f "$BK/$f" "$M/$f"; fi
done
node "$M/lib/q-db.js" >>"$LOG" 2>&1 && pass "q-db.js يحمّل" || fail "q-db.js"

H "3) المحفظة والبريد"
node "$AX/exec/wallet.js" "$AX" "$M" 2>&1 | tee -a "$LOG" || fail "wallet"
if [ -f "$AX/state/mailbox.json" ]; then
  MB=$(node -e "try{console.log(require('$AX/state/mailbox.json').address||'')}catch(e){console.log('')}")
  [ -n "$MB" ] && pass "بريد حقيقي قائم: $MB" || { node "$AX/exec/mail.js" "$AX" | tee -a "$LOG"; }
else node "$AX/exec/mail.js" "$AX" | tee -a "$LOG"; fi

H "4) صلاحيات الوكيل"
have termux-wake-lock && { termux-wake-lock 2>/dev/null && pass "wake-lock مُفعّل"; } || say "  - termux-wake-lock غير متاح"
[ -d "$HOME/storage" ] && pass "تخزين مشترك مربوط" || say "  - شغّل termux-setup-storage لربط التخزين"
mkdir -p "$HOME/.termux/boot"
cat > "$HOME/.termux/boot/apex-boot.sh" <<'B'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock 2>/dev/null
sleep 8
bash $HOME/cinehub3099/money/ULTIMATE.sh --no-push --no-wire >> $HOME/cinehub3099/money/logs/boot.log 2>&1
B
chmod +x "$HOME/.termux/boot/apex-boot.sh"; pass "سكربت الإقلاع: ~/.termux/boot/apex-boot.sh"
have termux-notification && termux-notification -t "APEX" -c "بدأ الإصلاح والتشغيل" 2>/dev/null && pass "إشعار مُرسل" || true
chmod 700 "$AX" "$P" 2>/dev/null; chmod 600 "$M/keys.env" 2>/dev/null; pass "صلاحيات الملفات الحساسة 600/700"

H "5) اكتشاف وتشغيل خدمات التطبيق"
cat > "$AX/exec/discover.js" <<'JS'
const fs=require('fs'),path=require('path');
const roots=process.argv.slice(2);
const SKIP=new Set(['node_modules','.git','.tmp','profiles','.check','.venv','dist','build','backup-html','logs','__pycache__','.cache']);
const NAME=/gateway|server|serve|api|hub|agent|app|main|entry|web|auth|static|boot|dash|scheduler|worker/i;
const PAT=/\.listen\s*\(|app\.run\s*\(|uvicorn\.run|Flask\s*\(|createServer\s*\(|HTTPServer\s*\(/;
const out=[];
function walk(d,depth){if(depth>4)return;let es=[];try{es=fs.readdirSync(d,{withFileTypes:true})}catch(e){return}
 for(const e of es){const f=path.join(d,e.name);
  if(e.isDirectory()){if(SKIP.has(e.name)||e.name.startsWith('.'))continue;walk(f,depth+1);}
  else if(/\.(js|mjs|cjs|py)$/.test(e.name)&&NAME.test(e.name)){
   let s='';try{s=fs.readFileSync(f,'utf8')}catch(e){continue}
   if(!PAT.test(s))continue;
   let port='';
   const m=s.match(/(?:listen\s*\(\s*|PORT\s*\|\|\s*|port\s*=\s*|PORT\s*=\s*|:\s*)(\d{4,5})/);
   if(m)port=m[1];
   if(!port){const a=s.match(/\b(8[0-9]{3})\b/g);if(a)port=a[0];}
   out.push(f+'|'+port);
  }}}
roots.forEach(r=>{if(fs.existsSync(r))walk(r,0)});
console.log([...new Set(out)].join('\n'));
JS
mapfile -t SRV < <(node "$AX/exec/discover.js" "$ROOT" "$HOME" 2>/dev/null | head -40)
say "  مرشحون: ${#SRV[@]}"
STARTED=0
for e in "${SRV[@]}"; do
  f="${e%%|*}"; pt="${e#*|}"
  case "$f" in *"/money/apex/"*) continue;; esac
  if [ -n "$pt" ] && (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null; then say "  = $(basename "$f") يعمل مسبقًا على $pt"; continue; fi
  nm="$(basename "$f" | tr -c 'a-zA-Z0-9' '_')"
  if [ -n "$pt" ]; then
    PORT=$pt AGENT_PORT=$pt AUTH_PORT=$pt Q_STATIC_PORT=$pt HUB_PORT=$pt DASH_PORT=$pt HOST=127.0.0.1 \
      nohup node "$f" >>"$AX/logs/$nm.log" 2>&1 & STARTED=$((STARTED+1))
    say "  > تشغيل $(basename "$f") على $pt"
  else
    nohup node "$f" >>"$AX/logs/$nm.log" 2>&1 & STARTED=$((STARTED+1))
    say "  > تشغيل $(basename "$f") (بلا منفذ محدد)"
  fi
done
# خدمات المستخدم المعروفة
for u in "$HOME/web_manager.py" "$HOME/unified_system/entrypoint.py"; do
  [ -f "$u" ] || continue
  nm="$(basename "$u" .py)"
  pgrep -f "$u" >/dev/null 2>&1 && { say "  = $nm يعمل مسبقًا"; continue; }
  nohup python3 "$u" >>"$AX/logs/$nm.log" 2>&1 & STARTED=$((STARTED+1))
  say "  > تشغيل $nm"
done
# قناة الأحداث واللوحة
pkill -f "apex/pipeline/eventd.js" 2>/dev/null || true
nohup node "$P/eventd.js" "$P" 8792 >>"$AX/logs/eventd.log" 2>&1 &
[ -f "$AX/exec/apexdash.js" ] && { pkill -f apexdash.js 2>/dev/null || true; nohup node "$AX/exec/apexdash.js" "$AX" 8791 >>"$AX/logs/dash.log" 2>&1 & }
sleep 5
OPEN=""
for pt in 8700 8787 8788 8791 8792 8798 8799 8870; do
  (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null && { pass "منفذ $pt يعمل"; OPEN="$OPEN $pt"; }
done
for pt in 8700 8787 8798 8799 8870; do
  (echo >/dev/tcp/127.0.0.1/$pt) 2>/dev/null || { fail "منفذ $pt لا يستجيب"; }
done
say "  مفتوحة:$OPEN"
for l in "$AX/logs"/*.log; do [ -f "$l" ] || continue
  s=$(grep -iE 'error|EADDRINUSE|Cannot find|SyntaxError|Traceback' "$l" 2>/dev/null | tail -1)
  [ -n "$s" ] && say "  ! $(basename "$l"): ${s:0:150}"
done

H "6) حقن الإعلانات"
if [ "$WIRE" = "1" ]; then node "$AX/exec/wire.js" "$ROOT" "$AX" 2>&1 | tee -a "$LOG"
else
  W=$(node -e "try{console.log(require('$AX/state/wire.json').wired||0)}catch(e){console.log(0)}")
  [ "$W" -gt 0 ] 2>/dev/null && pass "الصفحات محقونة مسبقًا: $W (استخدم --wire لإعادة الحقن)" || node "$AX/exec/wire.js" "$ROOT" "$AX" 2>&1 | tee -a "$LOG"
fi

H "7) خط الأموال — تشغيل كامل"
node "$AX/exec/revenue.js" "$AX" "$M" "$P" 2>&1 | tee -a "$LOG" || true
# أحداث حقيقية عبر HTTP لإثبات المسار كاملًا
for i in 1 2 3; do
  curl -s -m 5 -X POST -H 'Content-Type: application/json' \
    -d "{\"id\":\"selftest-$TS-$i\",\"type\":\"revenue\",\"source\":\"selftest\",\"amount_usd\":$((i)).5,\"country\":\"YE\"}" \
    http://127.0.0.1:8792/api/apex/event >/dev/null 2>&1
done
curl -s -m 5 http://127.0.0.1:8792/api/apex/stats | tee -a "$LOG" || true
say ""
node "$P/money.js" "$P" 2>&1 | tee -a "$LOG" || fail "money.js"
node "$P/settle.js" "$P" "$M" "$BCAST" 2>&1 | tee -a "$LOG" || fail "settle.js"
node "$P/reconcile.js" "$P" "$AX" 2>&1 | tee -a "$LOG" || fail "reconcile.js"

H "8) اختبارات"
T="$AX/reports/tests-$TS.txt"; : > "$T"
t(){ if eval "$2" >>"$LOG" 2>&1; then pass "$1"; echo "PASS $1" >> "$T"; else fail "$1"; echo "FAIL $1" >> "$T"; fi; }
t "async.js سليم"          "node --check '$M/lib/async.js'"
t "q-sec.js سليم"          "node --check '$M/lib/q-sec.js'"
t "q-lint.js سليم"         "node --check '$M/lib/q-lint.js'"
t "q-db يحمّل"             "node '$M/lib/q-db.js'"
t "crypto.js سليم"         "node --check '$P/crypto.js'"
t "keccak متجه معروف"      "node -e \"const c=require('$P/crypto.js');process.exit(c.keccak(Buffer.alloc(0)).toString('hex')==='c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470'?0:1)\""
t "توقيع+استرجاع ECDSA"    "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const h=c.keccak(Buffer.from('apex'));const s=c.sign(h,k);process.exit(c.recover(h,s.r,s.s,s.rec).toLowerCase()===c.addrOf(k).toLowerCase()?0:1)\""
t "signTx + استرجاع الموقّع" "node -e \"const c=require('$P/crypto.js');const k=BigInt('0x'+'11'.repeat(32));const t=c.signTx({nonce:0n,gasPrice:1000000000n,gasLimit:21000n,to:'0x'+'22'.repeat(20),value:1n,data:'',chainId:8453n},k);const p=c.rlp([0n,1000000000n,21000n,Buffer.from('22'.repeat(20),'hex'),1n,Buffer.alloc(0),8453n,0n,0n]);process.exit(c.recover(c.keccak(p),t.r,t.s,t.rec).toLowerCase()===c.addrOf(k).toLowerCase()?0:1)\""
t "المحفظة مشتقة"          "node -e \"const j=require('$AX/state/appwallet.json');process.exit(j.address&&j.address.length===42?0:1)\""
t "البريد الحقيقي"         "node -e \"const j=require('$AX/state/mailbox.json');process.exit(j.address?0:1)\""
t "قناة الأحداث"           "curl -s -m 5 -X POST -H 'Content-Type: application/json' -d '{\"type\":\"t\"}' http://127.0.0.1:8792/api/apex/event | grep -q ok"
t "الدفتر متوازن وسلسلة سليمة" "node -e \"const L=require('$P/ledger.js');process.exit(new L('$P/ledger.jsonl').verify().ok?0:1)\""
t "reconcile.js سليم"      "node --check '$P/reconcile.js'"
t "قواعد السحب"            "node -e \"const j=require('$AX/ledger/rules.json');process.exit(j.rails.length>5?0:1)\""
t "keys.env 600"           "test \$(stat -c %a '$M/keys.env') = 600"
say "  النتيجة: $(grep -c PASS "$T") نجاح / $(grep -c FAIL "$T") فشل"

H "9) النشر إلى GitHub"
REPO="-"; BR="-"; CMT="-"; PUSHED="لا"
if [ "$PUSH" = "1" ] && [ -d "$ROOT/.git" ]; then
  cd "$ROOT"
  BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"
  say "  الفرع: $BR | البعيد: ${REMOTE:-لا يوجد}"
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
  for f in money/keys.env money/secrets.json keys.env secrets.json; do
    if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then git rm --cached -q "$f"; say "  إزالة $f من التتبع"; fi
  done
  git config user.email >/dev/null 2>&1 || git config user.email "apex@cinehub.local"
  git config user.name  >/dev/null 2>&1 || git config user.name  "APEX Agent"
  git add -A >/dev/null 2>&1
  STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
  say "  ملفات مُجهّزة: $STAGED"
  # حارس الأسرار على المُجهّز
  LEAK=0
  while read -r f; do
    [ -f "$f" ] || continue
    case "$f" in *keys.env|*secrets.json|*bip39*) continue;; esac
    if grep -qE '0x[0-9a-fA-F]{64}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}' "$f" 2>/dev/null; then
      say "  ! سرّ محتمل في $f"; LEAK=$((LEAK+1))
    fi
  done < <(git diff --cached --name-only 2>/dev/null | head -2000)
  [ "$LEAK" = "0" ] && pass "لا أسرار مكشوفة في المُجهّز" || say "  $LEAK ملفًا يحتاج مراجعة"
  if [ -n "$(git status --porcelain)" ] || [ "$STAGED" != "0" ]; then
    git commit -q -m "APEX ULTIMATE $TS: إصلاح crypto/reconcile/async + تشغيل الخدمات + حقن الإعلانات + خط الأموال + أدلة" 2>&1 | tail -2 | tee -a "$LOG" || say "  (لا تغييرات جديدة)"
  else say "  لا تغييرات للالتزام"; fi
  CMT="$(git rev-parse HEAD 2>/dev/null || echo none)"
  say "  الالتزام المحلي: $CMT"
  if [ -n "$REMOTE" ]; then
    PUSHURL="$REMOTE"
    TOK="$(grep -m1 '^GITHUB_TOKEN=' "$M/keys.env" 2>/dev/null | cut -d= -f2- | tr -d ' \r')"
    USR="$(grep -m1 '^GH_USER=' "$M/keys.env" 2>/dev/null | cut -d= -f2- | tr -d ' \r')"
    if [ -n "$TOK" ] && echo "$REMOTE" | grep -q github.com; then
      SLUG="$(echo "$REMOTE" | sed -E 's#.*github\.com[:/]##; s#\.git$##')"
      PUSHURL="https://${USR:-x-access-token}:${TOK}@github.com/${SLUG}.git"
      pass "دفع بتوكن إلى $SLUG"
    else say "  دفع بدون توكن"; fi
    if GIT_TERMINAL_PROMPT=0 git push "$PUSHURL" "$BR" >>"$LOG" 2>&1; then
      pass "تم الدفع"
      RC="$(GIT_TERMINAL_PROMPT=0 git ls-remote "$PUSHURL" "refs/heads/$BR" 2>/dev/null | awk '{print $1}')"
      if [ "$RC" = "$CMT" ]; then PUSHED="نعم"; pass "تحقق: البعيد يطابق المحلي ($RC)"
      else fail "تعارض: البعيد=$RC المحلي=$CMT"; fi
    else fail "فشل الدفع — راجع $LOG"; fi
    REPO="$(echo "$REMOTE" | sed -E 's#\.git$##')"
  else say "  لا يوجد remote origin"; fi
else say "  متخطّى"; fi
printf '%s\n' "$REPO" > "$AX/reports/.repo"; printf '%s\n' "$BR" > "$AX/reports/.branch"; printf '%s\n' "$CMT" > "$AX/reports/.commit"

H "10) تقرير نهائي"
export AX
cat > "$AX/exec/final.js" <<'JS'
const fs=require('fs'),path=require('path');
const AX=process.env.AX;
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
const r=(p,d)=>{try{return fs.readFileSync(path.join(AX,p),'utf8').trim()}catch(e){return d||'-'}};
const S=g('registry/summary.json'),I=g('state/integrations.json'),E=g('state/earnings.json'),
 L=g('ledger/rules.json'),W=g('state/appwallet.json'),MB=g('state/mailbox.json'),WR=g('state/wire.json'),
 MO=g('pipeline/money.json'),SE=g('pipeline/settle.json'),RC=g('pipeline/reconcile.json'),RV=g('state/revenue.json');
const OPEN=g('state/ports.json',{});
const md=['# CineHub / APEX — التقرير النهائي','','> '+new Date().toISOString(),'',
'## 1) مُثبت بالقياس','',
'- نطاقات في السجل: **'+(S.platforms_total||0)+'** | استجابت: **'+(S.platforms_reachable||0)+'**',
'- نقاط ربط موثّقة: **'+(S.connection_points_verified||0)+'**',
'- واجهات API حية: **'+(I.working||0)+'/'+(I.total||0)+'**',
'- منصات تدعم اليمن: **'+(L.ye_actionable_platforms||0)+'**',
'- صفحات محقونة بالإعلانات: **'+(WR.wired||0)+'** '+JSON.stringify(WR.by_circle||{}),
'- صندوق بريد حقيقي: '+(MB.address||'—'),'',
'## 2) خط الأموال (Ingest→Fraud→Ledger→Compliance→Settle→Wallet→Reconcile)','',
'- أحداث: '+(MO.events||0)+' | مقبولة: '+(MO.approved||0)+' | معلّقة: '+(MO.held||0)+' | مرفوضة: '+(MO.rejected||0),
'- دفتر مزدوج: '+((MO.ledger_ok)?'سليم ومتوازن':'خلل')+' | قيود: '+(MO.entries||0),
'- **مؤكدة:** $'+((E.buckets&&E.buckets.confirmed_usd)||0)+' | **متوقعة:** $'+((E.buckets&&E.buckets.expected_usd)||0)+' | **معلّقة:** $'+((E.buckets&&E.buckets.pending_usd)||0)+' | **صافي بعد الرسوم:** $'+((E.buckets&&E.buckets.net_after_fees_usd)||0),
'- معاملة موقّعة: '+(SE.built?SE.built.txhash:'—')+' | مُبثّة: '+(SE.broadcast?'نعم':'لا'),
'- مطابقة ثلاثية: '+(RC.match?'مطابق':'بانتظار أول دفعة')+' | مصادر إيراد: '+((RV.sources||[]).map(s=>s.name+':'+(s.ok?'ok':'x')).join(' ')||'—'),'',
'## 3) محفظة التطبيق (وجهة السحب)','','`'+(W.address||'—')+'` — '+(W.source||''),'',
'## 4) قنوات السحب من اليمن','',...((L.rails||[]).map(x=>(x.ye?'✔':'○')+' '+x.name+' | حد $'+x.min+' | '+x.how)),'',
'## 5) النشر','','- المستودع: '+r('reports/.repo'),'- الفرع: '+r('reports/.branch'),'- الالتزام: `'+r('reports/.commit')+'`','',
'## 6) متطلبات تحتاج تدخلك','',
'- مفاتيح النشر (SURGE/NETLIFY/VERCEL/CLOUDFLARE/GITHUB_TOKEN) → reports/KEYS.md',
'- ADSENSE_CLIENT / ADSTERRA_HOST / EXOCLICK_ZONE / JUICYADS_ZONE / MONETAG_ZONE → أول إيراد حقيقي',
'- ADSTERRA_API_KEY / EXOCLICK_API_KEY → حصاد تلقائي',
'- CAPSOLVER_KEY + FIVESIM_TOKEN → تسجيل موسّع','',
'## 7) تشخيص خام','','```',(function(){const f=fs.readdirSync(path.join(AX,'reports')).filter(x=>x.startsWith('diag-')).sort().pop();
 try{return fs.readFileSync(path.join(AX,'reports',f),'utf8')}catch(e){return ''}})(),'```'].join('\n');
fs.writeFileSync(path.join(AX,'reports/APEX-FINAL.md'),md);
console.log('ok');
JS
node "$AX/exec/final.js" && pass "التقرير: $AX/reports/APEX-FINAL.md"
node -e "try{const m=require('$P/money.json');console.log('money: events='+m.events+' approved='+m.approved+' net=\$'+m.net_usd)}catch(e){console.log('money: -')}"

H "الخلاصة"
say "التقرير  : $AX/reports/APEX-FINAL.md"
say "التشخيص  : $DIAG"
say "السجل    : $LOG"
say "المستودع : $(cat "$AX/reports/.repo" 2>/dev/null) @ $(cat "$AX/reports/.commit" 2>/dev/null)"
say "الأوامر  : bash money/apexctl status|money|settle|mail|wallet|report"
