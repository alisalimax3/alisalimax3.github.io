#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),N=require("./anotify.js"),K=require("./akeys.js");
const D=path.resolve(__dirname,"..","data"),S=path.join(D,"intercept.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(S,"utf8"));}catch(e){return{otp:[],clip:""};}};
const wr=o=>fs.writeFileSync(S,JSON.stringify(o,null,1));
const TOK=/^[A-Za-z0-9_\-]{20,90}$/;
const SITE=/adsterra|monetag|exoclick|juicyads|trafficjunky|evadav|push\.house|clickadilla|propellerads|admaven|hilltopads|galaksion|cpagrip|bitlabs|ayet|offertoro|mylead|lospollos|crakrevenue|cloudflare|github|vercel|netlify|surge|firebase|neocities/i;
async function checkSms(){const st=rd(),msgs=await N.sms(12),out=[];
  for(const m of msgs){const sig=String(m.number||"")+"|"+String(m.body||"").slice(0,40);
    if(st.otp.includes(sig))continue;
    const body=String(m.body||""),code=(body.match(/\b(\d{4,8})\b/)||[])[1];
    if(code&&(SITE.test(body)||/code|otp|verif|رمز|تحقق/i.test(body))){st.otp.push(sig);out.push(code);
      K.set({LAST_OTP:code,LAST_OTP_AT:new Date().toISOString()});
      await N.notify({title:"APEX · رمز تحقق",content:code});N.vibrate("180");N.clipSet(code);}}
  wr(st);return out;}
async function checkClip(){const st=rd(),txt=await N.clip();
  if(!txt||txt===st.clip||!TOK.test(txt))return null;st.clip=txt;wr(st);
  let want="";
  try{const q=JSON.parse(fs.readFileSync(path.join(D,"queue.json"),"utf8"));
    if(q.current){const s=JSON.parse(fs.readFileSync(path.join(__dirname,"..","sources-big.json"),"utf8")).find(x=>x.id===q.current);
      if(s)want=(s.env||[]).find(e=>!K.get(e))||"";}}catch(e){}
  if(!want){try{const p=JSON.parse(fs.readFileSync(path.join(D,"register-plan.json"),"utf8")).plan||[];
    const nx=p.find(x=>x.env&&x.env.some(e=>!K.get(e)));if(nx)want=nx.env.find(e=>!K.get(e))||"";}catch(e){}}
  if(!want)return null;
  K.set({[want]:txt});N.clipSet("");
  await N.notify({title:"APEX · مفتاح جديد",content:want+" محفوظ"});N.vibrate("200");return{key:want};}
module.exports={checkSms,checkClip};
if(require.main===module){checkSms().then(checkClip).then(r=>{if(r)console.log("  ✔ "+r.key);});}
