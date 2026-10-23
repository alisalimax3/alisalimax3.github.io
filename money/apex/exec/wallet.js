const fs=require('fs'),path=require('path'),crypto=require('crypto'),https=require('https');
const AX=process.argv[2],M=process.argv[3],KEYS=path.join(M,'keys.env');
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
function add(p1,p2){if(!p1)return p2;if(!p2)return p1;
 if(p1[0]===p2[0]){if(mod(p1[1]+p2[1],P)===0n)return null;
  const l=mod(3n*p1[0]*p1[0]*inv(2n*p1[1],P),P);const x=mod(l*l-2n*p1[0],P);return [x,mod(l*(p1[0]-x)-p1[1],P)];}
 const l=mod((p2[1]-p1[1])*inv(p2[0]-p1[0],P),P);const x=mod(l*l-p1[0]-p2[0],P);return [x,mod(l*(p1[0]-x)-p1[1],P)];}
function mul(k,q){let r=null;while(k>0n){if(k&1n)r=add(r,q);q=add(q,q);k>>=1n;}return r;}
const b32=v=>Buffer.from(v.toString(16).padStart(64,'0'),'hex');
function pub(k,comp){const p=mul(k,[GX,GY]);return comp?Buffer.concat([Buffer.from([p[1]%2n===0n?2:3]),b32(p[0])]):Buffer.concat([Buffer.from([4]),b32(p[0]),b32(p[1])]);}
function checksum(h){const x=h.toLowerCase();const k=keccak(Buffer.from(x,'utf8')).toString('hex');
 let o='0x';for(let i=0;i<x.length;i++)o+=parseInt(k[i],16)>=8?x[i].toUpperCase():x[i];return o;}
const addrOf=k=>{const u=pub(k,false);return checksum(keccak(u.slice(1)).slice(12).toString('hex'));};
const mn2seed=(mn,pw='')=>crypto.pbkdf2Sync(Buffer.from(mn.normalize('NFKD'),'utf8'),Buffer.from(('mnemonic'+pw).normalize('NFKD'),'utf8'),2048,64,'sha512');
const master=s=>{const I=crypto.createHmac('sha512','Bitcoin seed').update(s).digest();return{k:BigInt('0x'+I.slice(0,32).toString('hex')),c:I.slice(32)};};
function ckd(n,i){const d=Buffer.alloc(37);
 if(i>=0x80000000){d[0]=0;b32(n.k).copy(d,1);}else pub(n.k,true).copy(d,0);
 d.writeUInt32BE(i>>>0,33);
 const I=crypto.createHmac('sha512',n.c).update(d).digest();
 return{k:mod(n.k+BigInt('0x'+I.slice(0,32).toString('hex')),N),c:I.slice(32)};}
const HD=i=>i+0x80000000;
let env=fs.existsSync(KEYS)?fs.readFileSync(KEYS,'utf8'):'';
// ابحث عن العبارة الاستذكارية في أي ملف
function findMn(){
 for(const f of [KEYS,path.join(M,'secrets.json'),path.join(M,'wallet.txt'),path.join(M,'data/wallet.json')]){
  try{const t=fs.readFileSync(f,'utf8');
   let m=t.match(/WALLET_MNEMONIC\s*[=:]\s*"?([a-z ]{20,})"?/i);
   if(m)return m[1].trim();
   m=t.match(/"mnemonic"\s*:\s*"([a-z ]{20,})"/i); if(m)return m[1].trim();
   m=t.match(/\b([a-z]+(?: [a-z]+){11,23})\b/); if(m&&m[1].split(' ').length%3===0)return m[1].trim();
  }catch(e){}}
 return null;}
const set=(k,v)=>{if(new RegExp('^'+k+'\\s*=','m').test(env))env=env.replace(new RegExp('^'+k+'\\s*=.*$','m'),k+'='+v);else env=env.replace(/\n*$/,'\n')+k+'='+v+'\n';};
(async()=>{
 let src='none',priv=null;
 const pk=(env.match(/^WALLET_PRIVATE_KEY\s*=\s*(0x[0-9a-fA-F]{64})/m)||[])[1];
 const mn=findMn();
 if(pk) priv=BigInt(pk), src='keys.env:PRIVATE_KEY';
 else if(mn){
  try{
   const lf=path.join(AX,'data/bip39.txt');
   if(!fs.existsSync(lf)){
    const t=await new Promise(r=>{https.get('https://raw.githubusercontent.com/bitcoin/bips/master/bip-0039/english.txt',s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>r(d))}).on('error',()=>r(''))});
    if(t.split('\n').length>2000)fs.writeFileSync(lf,t);}
   let n=master(mn2seed(mn));
   for(const i of [HD(44),HD(60),HD(0),0,0]) n=ckd(n,i);
   priv=n.k; src='BIP39/BIP44 m/44\'/60\'/0\'/0/0 (mn='+mn.split(' ').length+'w)';
  }catch(e){src='bip39-err';}
 }
 if(!priv){ priv=BigInt('0x'+crypto.randomBytes(32).toString('hex'))%N; src='مولّد جديد'; }
 const a=addrOf(priv);
 set('WALLET_ADDRESS',a); set('WALLET_PRIVATE_KEY','0x'+priv.toString(16).padStart(64,'0'));
 if(mn) set('WALLET_MNEMONIC',mn);
 fs.writeFileSync(KEYS,env); fs.chmodSync(KEYS,0o600);
 fs.writeFileSync(path.join(AX,'state/appwallet.json'),JSON.stringify({ts:new Date().toISOString(),address:a,source:src,qr:'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data='+a},null,1));
 console.log('wallet='+a+' src='+src);})();
