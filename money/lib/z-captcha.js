#!/usr/bin/env node
"use strict";
const K=require("./z-keys.js"),HTTP=require("./z-http.js");
const sleep=HTTP.sleep;
function kindOf(k){return /hcap/i.test(k)?"hcaptcha":/turnstile/i.test(k)?"turnstile":/recap/i.test(k)?"recaptcha":"unknown";}
async function two(kind,url,key,extra){const tok=K.get("TWOCAPTCHA_KEY");if(!tok)return "";
  const m={recaptcha:"userrecaptcha",hcaptcha:"hcaptcha",turnstile:"turnstile"}[kind]||"userrecaptcha";
  const p=new URLSearchParams({key:tok,method:m,sitekey:key,pageurl:url,json:1});
  if(kind==="recaptcha"&&extra&&extra.v3){p.set("version","v3");p.set("action",extra.action||"login");p.set("min_score","0.3");}
  const c=await HTTP.get("https://2captcha.com/in.php?"+p.toString(),{timeout:20000});
  const j=JSON.parse(c.body||"{}");if(j.status!==1)return "";
  for(let i=0;i<40;i++){await sleep(5000);
    const r=await HTTP.get("https://2captcha.com/res.php?key="+tok+"&action=get&id="+j.request+"&json=1",{timeout:20000});
    const g=JSON.parse(r.body||"{}");if(g.status===1)return g.request;}
  return "";}
async function capsolver(kind,url,key){const tok=K.get("CAPSOLVER_KEY");if(!tok)return "";
  const type={recaptcha:"ReCaptchaV2TaskProxyLess",hcaptcha:"HCaptchaTaskProxyLess",turnstile:"AntiTurnstileTaskProxyLess"}[kind];
  const c=await HTTP.post("https://api.capsolver.com/createTask",{json:{clientKey:tok,task:{type,websiteURL:url,websiteKey:key}},timeout:20000});
  const j=JSON.parse(c.body||"{}");if(j.errorId)return "";
  for(let i=0;i<40;i++){await sleep(4000);
    const r=await HTTP.post("https://api.capsolver.com/getTaskResult",{json:{clientKey:tok,taskId:j.taskId},timeout:20000});
    const g=JSON.parse(r.body||"{}");if(g.status==="ready")return (g.solution||{}).gRecaptchaResponse||(g.solution||{}).token||"";}
  return "";}
async function solve(kindRaw,url,key,extra){const kind=kindOf(kindRaw);if(!key)return "";
  try{return await capsolver(kind,url,key)||await two(kind,url,key,extra)||"";}catch(e){return "";}}
module.exports={solve,kindOf};
