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
