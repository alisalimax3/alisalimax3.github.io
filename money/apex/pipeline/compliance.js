const SANCTIONED=['IR','KP','SY','CU','SD'];
const HIGH_RISK=['AF','YE','LY','IQ','VE','MM'];
function check(ev){
 const c=(ev.country||'').toUpperCase();const out={flags:[],tax_pct:0,ok:true};
 if(SANCTIONED.includes(c)){out.flags.push('sanctioned');out.ok=false;}
 if(HIGH_RISK.includes(c))out.flags.push('enhanced-due-diligence');
 if((ev.amount_usd||0)>=200)out.tax_pct=5;
 if((ev.amount_usd||0)>=1000)out.tax_pct=10;
 out.kyt=(ev.txhash?('onchain:'+ev.txhash.slice(0,12)):'internal');
 return out;}
module.exports={check,SANCTIONED,HIGH_RISK};
