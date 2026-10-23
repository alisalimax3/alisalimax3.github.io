#!/usr/bin/env node
"use strict";
const https=require("https"),fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const KEYS=path.join(ROOT,"keys.env"),ID=path.join(DATA,"identity.json"),REC=path.join(DATA,"signup-recipes.json");
const codes=require("./codes.js");
const UA="Mozilla/5.0 (Linux; Android 13; SM-A536B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function rq(url,o={},body){return new Promise((res,rej)=>{
  const u=new URL(url),h=Object.assign({"user-agent":UA,accept:"text/html,application/json,text/plain,*/*",
    "accept-language":"ar,en;q=0.9"},o.headers||{});
  if(o.cookies&&o.cookies.length)h.cookie=o.cookies.join("; ");
  const d=body?(typeof body==="string"?body:new URLSearchParams(body).toString()):null;
  if(d){h["content-type"]="application/x-www-form-urlencoded";h["content-length"]=Buffer.byteLength(d);}
  const q=https.request({host:u.host,path:u.pathname+u.search,method:o.method||"GET",headers:h},r=>{
    if([301,302,303,307,308].includes(r.statusCode)&&r.headers.location&&o.redirect!==false&&o._n<6)
      return rq(new URL(r.headers.location,u).href,Object.assign({},o,{_n:(o._n||0)+1}),body).then(res).catch(rej);
    let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>res({status:r.statusCode,headers:r.headers,body:b,final:u.href}));});
  q.on("error",rej); if(d)q.write(d); q.end();});}
const getkv=k=>{try{return (fs.readFileSync(KEYS,"utf8").match(new RegExp("^"+k+"=(.*)$","m"))||[])[1]||"";}catch(e){return"";}};

async function solveCaptcha(kind,siteUrl,siteKey){
  const key=getkv("CAPSOLVER_KEY"); if(!key)return "";
  const type=kind==="recaptcha"?"ReCaptchaV2TaskProxyLess":"HCaptchaTaskProxyLess";
  const c=await rq("https://api.capsolver.com/createTask",{method:"POST",headers:{"content-type":"application/json"}},
    JSON.stringify({clientKey:key,task:{type,websiteURL:siteUrl,websiteKey:siteKey}}));
  const tid=JSON.parse(c.body).taskId; if(!tid){console.log("   ⚠ CapSolver: "+c.body.slice(0,90));return "";}
  for(let i=0;i<40;i++){await sleep(3000);
    const g=await rq("https://api.capsolver.com/getTaskResult",{method:"POST",headers:{"content-type":"application/json"}},
      JSON.stringify({clientKey:key,taskId:tid}));
    const j=JSON.parse(g.body);
    if(j.status==="ready")return j.solution.gRecaptchaResponse||j.solution.token||"";
    if(j.status==="failed")return "";}
  return "";
}
function fields(html){
  const out=[];const re=/<input\b[^>]*>/gi;let m;
  while((m=re.exec(html))){
    const t=m[0],g=a=>((t.match(new RegExp(a+'=["\']([^"\']*)',"i"))||[])[1]||"");
    out.push({name:g("name"),type:g("type")||"text",value:g("value"),ph:g("placeholder")});
  }
  return out.filter(x=>x.name);
}
function mapFields(fs_,id){
  const v={},meta={};
  for(const f of fs_){
    const n=f.name.toLowerCase();
    if(f.type==="hidden"||f.type==="submit"||f.type==="button"){if(f.value)v[f.name]=f.value;continue;}
    if(/confirm.*pass|pass.*confirm|password2|retype/.test(n)){v[f.name]=id.password;meta[f.name]="pass×2";continue;}
    if(/pass/.test(n)){v[f.name]=id.password;meta[f.name]="pass";continue;}
    if(/email|mail/.test(n)){v[f.name]=id.email.primary;meta[f.name]="email";continue;}
    if(/user|login|nick|handle|account|name/.test(n)){v[f.name]=id.handle;meta[f.name]="user";continue;}
    if(/website|url|site|domain/.test(n)){v[f.name]=getkv("PUBLIC_URL")||"";meta[f.name]="url";continue;}
    if(/country|geo/.test(n)){v[f.name]="EG";meta[f.name]="country";continue;}
    if(/phone|tel|mobile/.test(n)){v[f.name]=getkv("PHONE_NUMBER")||"";meta[f.name]="phone";continue;}
    if(/agree|terms|tos|newsletter|opt.?in|marketing/.test(n)){if(f.type==="checkbox")v[f.name]="on";continue;}
  }
  return {v,meta};
}
async function inspect(url){
  const r=await rq(url);
  console.log("  HTTP "+r.status+"  →  "+r.final);
  const F=fields(r.body);
  if(!F.length){console.log("  ⚠ لا حقول — قد يكون SPA/JS");return;}
  const id=JSON.parse(fs.readFileSync(ID,"utf8"));
  const {meta}=mapFields(F,id);
  console.log("  الحقول المكتشفة ("+F.length+"):");
  for(const f of F)console.log("    "+(meta[f.name]?"✔ "+meta[f.name].padEnd(9):"  hidden  ")+f.name+(f.ph?"  («"+f.ph+"»)":""));
  const cap=/hcaptcha|h-captcha/i.test(r.body)?"hcaptcha":(/recaptcha|g-recaptcha/i.test(r.body)?"recaptcha":"لا");
  console.log("  الكابتشا: "+cap+"   |   CapSolver: "+(getkv("CAPSOLVER_KEY")?"مضبوط":"غير مضبوط"));
  const action=(r.body.match(/<form[^>]*action=["']([^"']*)/i)||[])[1];
  console.log("  action: "+(action||"نفس الصفحة"));
}
async function attempt(idKey){
  const R=JSON.parse(fs.readFileSync(REC,"utf8")),rec=R.find(x=>x.id===idKey);
  if(!rec)return console.log("  ✗ لا وصفة لـ "+idKey+" — استخدم inspect");
  const id=JSON.parse(fs.readFileSync(ID,"utf8"));
  console.log("  ▶ "+rec.net+"  ["+rec.tier+"]");
  const r=await rq(rec.url);
  const cookies=(r.headers["set-cookie"]||[]).map(c=>c.split(";")[0]);
  const F=fields(r.body);
  if(!F.length){console.log("  ⚠ SPA — افتح الرابط وأكمل يدويًا: "+rec.url);return;}
  const {v,meta}=mapFields(F,id);
  let token="";
  if(/hcaptcha|h-captcha/i.test(r.body))token=await solveCaptcha("hcaptcha",rec.url,"");
  else if(/recaptcha/i.test(r.body))token=await solveCaptcha("recaptcha",rec.url,"");
  if(token){v["h-captcha-response"]=token;v["g-recaptcha-response"]=token;}
  const action=(r.body.match(/<form[^>]*action=["']([^"']*)/i)||[])[1];
  const target=action?new URL(action,rec.url).href:rec.url;
  const post=await rq(target,{method:"POST",cookies},v);
  const ok=/dashboard|admin|panel|welcome|success/i.test(post.final)||post.status<400;
  console.log("  ← HTTP "+post.status+"  →  "+post.final);
  console.log(ok?"  ✔ يُحتمل النجاح — راجع اللوحة":"  ⚠ راجع يدويًا");
  codes.save("محاولة تسجيل — "+rec.net,{الرابط:rec.url,الحقول_المُرسلة:Object.keys(v).join(","),"النتيجة":"HTTP "+post.status,
    "الحقول_المكتشفة":Object.entries(meta).map(([k,x])=>k+"="+x).join(" "),الحالة:ok?"يُحتمل النجاح":"راجع يدويًا"});
}
(async()=>{const[c,...a]=process.argv.slice(2);
 if(c==="inspect")await inspect(a[0]);
 else if(c==="try")await attempt(a[0]);
 else if(c==="list"){const R=JSON.parse(fs.readFileSync(REC,"utf8"));
   console.log("  وصفات جاهزة ("+R.length+"):");R.forEach(x=>console.log("    "+x.tier.padEnd(4)+" "+x.id.padEnd(18)+x.net));}
 else console.log("الأوامر: inspect <url> | try <id> | list");
})();
