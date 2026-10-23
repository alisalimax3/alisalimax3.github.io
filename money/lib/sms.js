#!/usr/bin/env node
"use strict";
// رقم هاتف افتراضي حقيقي للتحقق — 5sim
const K=require("./keysfile.js");
const API="https://5sim.net/v1";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function call(p){
  const r=await fetch(API+p,{headers:{authorization:"Bearer "+K.get("FIVESIM_TOKEN"),accept:"application/json"}});
  const t=await r.text();try{return JSON.parse(t);}catch(e){return{raw:t,status:r.status};}
}
async function buy(product="github",country="any",operator="any"){
  if(!K.get("FIVESIM_TOKEN"))return console.log("  ○ لا FIVESIM_TOKEN — تخطّي الهاتف");
  const o=await call(`/user/buy/activation/${country}/${operator}/${product}`);
  if(!o.id)return console.log("  ○ فشل الشراء: "+JSON.stringify(o).slice(0,90));
  console.log("  ✔ رقم: "+o.phone+"  (id "+o.id+")");
  K.set({PHONE_NUMBER:o.phone,PHONE_ID:String(o.id)});
  return o;
}
async function waitCode(id,timeoutMs=180000){
  const t0=Date.now();
  while(Date.now()-t0<timeoutMs){
    const s=await call("/user/check/"+id);
    const sms=(s.sms||[]).map(x=>x.code).filter(Boolean);
    if(sms.length){console.log("  ✔ وصل رمز SMS: "+sms[0]);return sms[0];}
    if(s.status==="CANCELED"){console.log("  ○ أُلغي الرقم");return "";}
    await sleep(5000);
  }
  return "";
}
const finish=id=>call("/user/finish/"+id);
const profile=()=>call("/user/profile");
module.exports={buy,waitCode,finish,profile,call};
if(require.main===module){const a=process.argv.slice(2);
  if(a[0]==="buy")buy(a[1],a[2],a[3]);else if(a[0]==="code")waitCode(a[1]);
  else if(a[0]==="balance")profile().then(p=>console.log("  رصيد 5sim: "+JSON.stringify(p.balance||p)));}
