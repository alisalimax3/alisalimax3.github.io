#!/usr/bin/env node
"use strict";
// إنشاء حساب GitHub حقيقي: بريد حقيقي (mail.tm) + تحقق اسم + captcha + تأكيد + تسليم
const https=require("https"),fs=require("fs"),path=require("path"),crypto=require("crypto");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),KEYS=path.join(ROOT,"keys.env");
const codes=require("./codes.js");
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36";
function rq(url,opt={},body){return new Promise((res,rej)=>{
  const u=new URL(url),o={method:opt.method||"GET",headers:Object.assign({"user-agent":UA,"accept":"text/html,application/json"},opt.headers||{})};
  if(opt.cookies&&opt.cookies.length)o.headers.cookie=opt.cookies.join("; ");
  const d=body?(typeof body==="string"?body:new URLSearchParams(body).toString()):null;
  if(d){o.headers["content-type"]="application/x-www-form-urlencoded";o.headers["content-length"]=Buffer.byteLength(d);}
  const q=https.request({host:u.host,path:u.pathname+u.search,method:o.method,headers:o.headers},r=>{
    if([301,302,303,307,308].includes(r.statusCode)&&r.headers.location&&opt.redirect!==false)
      return rq(new URL(r.headers.location,u).href,opt,body).then(res).catch(rej);
    let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>res({status:r.statusCode,headers:r.headers,body:b}));});
  q.on("error",rej); if(d)q.write(d); q.end();});}
const jget=async(u,opt)=>{const r=await rq(u,opt);try{return{...r,json:JSON.parse(r.body)};}catch(e){return{...r,json:null};}};
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function setkv(k,v){let t="";try{t=fs.readFileSync(KEYS,"utf8");}catch(e){}
  const re=new RegExp("^"+k+"=.*$","m");t=re.test(t)?t.replace(re,k+"="+v):(t&&!t.endsWith("\n")?"\n":"")+k+"="+v+"\n";
  const tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);try{fs.chmodSync(KEYS,0o600);}catch(e){}}
const getkv=k=>{try{return (fs.readFileSync(KEYS,"utf8").match(new RegExp("^"+k+"=(.*)$","m"))||[])[1]||"";}catch(e){return"";}};

async function mailbox(){
  const d=await jget("https://api.mail.tm/domains");
  const dom=(d.json?.["hydra:member"]||[]).find(x=>x.isActive)?.domain;
  if(!dom)throw new Error("mail.tm: لا نطاق متاح");
  const addr="cinehub"+crypto.randomBytes(3).toString("hex")+"@"+dom, pass=crypto.randomBytes(9).toString("base64url");
  await rq("https://api.mail.tm/accounts",{method:"POST",headers:{"content-type":"application/json"}},JSON.stringify({address:addr,password:pass}));
  const t=await rq("https://api.mail.tm/token",{method:"POST",headers:{"content-type":"application/json"}},JSON.stringify({address:addr,password:pass}));
  const tok=JSON.parse(t.body).token;
  if(!tok)throw new Error("mail.tm: فشل التوكن");
  console.log("  ✔ بريد حقيقي: "+addr);
  return {addr,pass,tok};
}
async function username(base){
  for(let i=0;i<40;i++){
    const cand=i?base+i:base;
    const r=await jget("https://github.com/signup_check/username?value="+encodeURIComponent(cand));
    let ok=r.json?.valid; if(ok===undefined) ok = r.status===200 && !/taken/i.test(r.body);
    if(ok){console.log("  ✔ الاسم متاح: "+cand);return cand;}
  }
  throw new Error("لا اسم متاح");
}
async function solveCaptcha(){
  const key=getkv("CAPSOLVER_KEY")||process.env.CAPSOLVER_KEY;
  if(!key){console.log("  ℹ بلا CAPSOLVER_KEY → سيتوقف عند الكابتشا (الحساب يُنشأ يدويًا في 20 ثانية)");return "";}
  const site="a5f74b19-9e45-40e0-b45d-47ff91b7a6c2";
  const c=await rq("https://api.capsolver.com/createTask",{method:"POST",headers:{"content-type":"application/json"}},
    JSON.stringify({clientKey:key,task:{type:"HCaptchaTaskProxyLess",websiteURL:"https://github.com/signup",websiteKey:site}}));
  const id=JSON.parse(c.body).taskId; if(!id)throw new Error("CapSolver: "+c.body.slice(0,120));
  for(let i=0;i<40;i++){await sleep(3000);
    const g=await rq("https://api.capsolver.com/getTaskResult",{method:"POST",headers:{"content-type":"application/json"}},
      JSON.stringify({clientKey:key,taskId:id}));
    const j=JSON.parse(g.body);
    if(j.status==="ready"){console.log("  ✔ حُلّت الكابتشا");return j.solution.gRecaptchaResponse||j.solution.token||"";}
    if(j.status==="failed")throw new Error("CapSolver فشل");}
  return "";
}
async function main(){
  console.log("═══ إنشاء حساب GitHub حقيقي ═══");
  const user=(getkv("GH_USER")||("cinehub"+crypto.randomBytes(3).toString("hex"))).toLowerCase();
  const pass=getkv("GH_PASS")||(crypto.randomBytes(6).toString("base64url")+"!Aa9");
  const box=await mailbox();
  const login=await username(user);
  const token=await solveCaptcha();

  const page=await rq("https://github.com/signup");
  const cookies=(page.headers["set-cookie"]||[]).map(c=>c.split(";")[0]);
  const at=(page.body.match(/name="authenticity_token"[^>]*value="([^"]+)"/)||[])[1]||"";
  console.log("  ℹ authenticity_token: "+(at?"موجود":"مفقود"));

  const r=await rq("https://github.com/signup",{method:"POST",cookies},{
    authenticity_token:at,"signup[login]":login,"signup[email]":box.addr,
    "signup[password]":pass,"signup[password_confirmation]":pass,
    "signup[marketing_emails_opt_in]":"false","h-captcha-response":token});
  console.log("  ← رد GitHub: HTTP "+r.status);
  codes.save("GitHub — محاولة إنشاء",{اسم_المستخدم:login,البريد:box.addr,كلمة_المرور:pass,رد:"HTTP "+r.status});
  setkv("GH_USER",login);setkv("GH_PASS",pass);setkv("GH_EMAIL",box.addr);

  console.log("  … انتظار رسالة التأكيد (حتى 3 دقائق)");
  let link="";
  for(let i=0;i<36&&!link;i++){await sleep(5000);
    const m=await jget("https://api.mail.tm/messages",{headers:{authorization:"Bearer "+box.tok}});
    const list=m.json?.["hydra:member"]||[];
    for(const msg of list){
      const f=await jget("https://api.mail.tm/messages/"+msg.id,{headers:{authorization:"Bearer "+box.tok}});
      const L=(f.body.match(/https:\/\/github\.com\/account_verifications[^"'\s<]+/)||[])[0];
      if(L){link=L.replace(/&amp;/g,"&");break;}}
  }
  if(link){const v=await rq(link);console.log("  ✔ تأكيد البريد: HTTP "+v.status);}
  else console.log("  ⚠ لم تصل الرسالة — أكّد يدويًا من صندوق mail.tm");

  const chk=await rq("https://github.com/"+login);
  const ok=chk.status===200;
  console.log(ok?"  ✅ الحساب موجود فعلًا: https://github.com/"+login:"  ⚠ الحساب لم يُنشأ — راجع الرد");
  codes.save("GitHub — الحساب",{الرابط:"https://github.com/"+login,اسم_المستخدم:login,البريد:box.addr,
    كلمة_المرور:pass,"بريد mail.tm":"https://mail.tm (سجّل بـ"+box.addr+" / "+box.pass+")",حالة:ok?"مُنشأ":"غير مؤكد"});
  console.log("\n  الصق بعده:  bash money/HANDOVER.sh");
}
main().catch(e=>{console.error("  ✗ "+e.message);process.exit(1);});
