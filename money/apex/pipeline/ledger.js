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
