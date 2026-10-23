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
