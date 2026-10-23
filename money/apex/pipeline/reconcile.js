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
