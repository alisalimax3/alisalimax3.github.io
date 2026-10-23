#!/usr/bin/env node
"use strict";
const K=require("./keysfile.js"),{rq,j}=require("./mailbox.js");
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const TYPES={hcaptcha:"HCaptchaTaskProxyLess",recaptcha:"ReCaptchaV2TaskProxyLess",turnstile:"AntiTurnstileTaskProxyLess"};
async function solve(kind,pageUrl,siteKey){
  const key=K.get("CAPSOLVER_KEY"),alt=K.get("TWOCAPTCHA_KEY");
  if(!key&&!alt){console.log("   ℹ لا محلّل كابتشا — أضف CAPSOLVER_KEY");return "";}
  const api=key?"https://api.capsolver.com":"https://api.2captcha.com";
  const ck=key||alt, type=TYPES[kind]||TYPES.hcaptcha;
  const task={type,websiteURL:pageUrl,websiteKey:siteKey||""};
  if(!siteKey&&kind==="hcaptcha")task.websiteKey="a5f74b19-9e45-40e0-b45d-47ff91b7a6c2";
  const c=await rq(api+"/createTask",{method:"POST",headers:{"content-type":"application/json"}},
    JSON.stringify({clientKey:ck,task}));
  const tid=(j(c)||{}).taskId; if(!tid){console.log("   ⚠ "+api+" ← "+c.body.slice(0,90));return "";}
  for(let i=0;i<45;i++){await sleep(3000);
    const g=await rq(api+"/getTaskResult",{method:"POST",headers:{"content-type":"application/json"}},
      JSON.stringify({clientKey:ck,taskId:tid}));
    const x=j(g)||{};
    if(x.status==="ready"){console.log("   ✔ حُلّت "+kind);return x.solution.gRecaptchaResponse||x.solution.token||"";}
    if(x.status==="failed"){console.log("   ⚠ فشل الحل");return "";}}
  return "";
}
module.exports={solve};
