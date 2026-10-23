// قواعد حتمية + سرعة (velocity) — قرار: approve | hold | reject
const win=new Map();
function score(ev,ctx){
 let s=0,r=[];const amt=+(ev.amount_usd||0);
 if(amt>10000){s+=40;r.push('amount>10k');}
 if(amt<=0&&ev.type==='revenue'){s+=10;r.push('nonpositive');}
 const key=(ev.source||'?')+'|'+(ev.account||'?');
 const now=Date.now();const w=win.get(key)||[];w.push(now);
 while(w.length&&now-w[0]>60000)w.shift();win.set(key,w);
 if(w.length>60){s+=25;r.push('velocity>60/min');}
 if(ctx&&ctx.dup){s+=30;r.push('duplicate-id');}
 if(ev.country&&ctx&&ctx.home&&ev.country!==ctx.home){s+=10;r.push('geo-mismatch');}
 if(ctx&&ctx.sanctioned){s+=20;r.push('sanctioned');}
 const decision=s>=60?'reject':(s>=30?'hold':'approve');
 return{score:Math.min(100,s),rules:r,decision};}
module.exports={score};
