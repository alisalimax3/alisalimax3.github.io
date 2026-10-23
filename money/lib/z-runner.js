#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,"..");
const DB=require("./z-db.js"),K=require("./z-keys.js"),HTTP=require("./z-http.js"),REC=require("./z-recipes.js"),
  MAIL=require("./z-mail.js"),BR=require("./z-browser.js"),V=require("./z-verify.js"),DOC=require("./z-docs.js"),
  HU=require("./z-human.js"),IDN=require("./z-identity.js");
const sleep=HTTP.sleep;
const log=m=>{try{fs.appendFileSync(path.join(ROOT,"logs","zero.log"),"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");}catch(e){}};
function recOf(t){return REC.byId(t.recipe)||REC.generic(t);}
function needHuman(t,rec,why,steps,field){DB.humanAdd({id:t.id,why,url:t.signup||t.home,steps:steps||[],field:field||"",resume:t.stage});
  DB.stage(t.id,"human",(HU.WHY[why]||why));log("تدخّل: "+t.id+" ("+why+")");}
async function sResolve(t,rec){
  if(t.kind==="search")return DB.stage(t.id,"reachable","بحث");
  if(rec.method==="none"&&rec.signup){DB.upsert(t.id,{signup:rec.signup,login:rec.login||rec.signup,recipe:rec.id});return DB.stage(t.id,"resolved",rec.signup);}
  const home=t.home||rec.home;
  const r=await HTTP.get(home,{timeout:20000});
  if(!r.ok){DB.fail(t.id,"لا يستجيب "+r.status);return DB.stage(t.id,"failed","الموقع "+r.status);}
  DB.ev(t.id,"resolve",{home,status:r.status});
  const ls=HTTP.links(r.body,r.url||home);
  const su=ls.find(u=>/signup|register|join|create|publisher|partner/i.test(u))||ls[0];
  if(!su){needHuman(t,rec,"identity",["افتح "+home,"أنشئ الحساب ثم الصق رابط التسجيل"],"");return;}
  DB.upsert(t.id,{signup:su,login:su,recipe:rec.id,recipe_conf:rec.conf});
  DB.ev(t.id,"signup-found",{signup:su});return DB.stage(t.id,"resolved",su);}
async function sReach(t,rec){
  const r=await HTTP.get(t.signup||rec.signup,{timeout:20000});
  if(!r.ok){DB.fail(t.id,"تسجيل "+r.status);return DB.stage(t.id,"failed","تسجيل غير متاح "+r.status);}
  DB.ev(t.id,"reach",{status:r.status,ms:r.ms,url:t.signup});
  if(t.kind==="search"||t.kind==="directory"){DB.test(t.id,{ok:true,status:r.status,ms:r.ms,kind:"وصول",note:"HTTP "+r.status,at:new Date().toISOString()});
    return DB.stage(t.id,"live","وصول مُتحقّق");}
  return DB.stage(t.id,"reachable","جاهز للتسجيل "+r.status);}
async function sAccount(t,rec){
  const I=IDN.get(),CR=IDN.creds(t.id);
  let mail={addr:I.email||""};
  if((rec.needs||[]).includes("email")){try{mail=await MAIL.ensure(t.id);}catch(e){DB.ev(t.id,"mail-fail",{err:String(e.message||e)});}}
  const vars={email:mail.addr,user:CR.user,pass:CR.pass,name:I.name||I.brand,site:I.site_url||"",brand:I.brand};
  const pg=await HTTP.get(t.signup,{timeout:25000});
  const fields=Object.assign({},HTTP.hiddenFields(pg.body));
  Object.entries(rec.fields||{}).forEach(([k,v])=>fields[k]=HTTP.tpl(v,vars));
  if(rec.method==="http"&&Object.keys(rec.fields||{}).length){
    const r=await HTTP.post(HTTP.tpl(rec.action||t.signup,vars),{form:fields,headers:rec.headers,timeout:30000});
    const ok=rec.success?new RegExp(rec.success,"i").test(r.body):(r.status>0&&r.status<400&&!/error|invalid|already/i.test(r.body));
    DB.ev(t.id,"account-http",{status:r.status,ok,fields:Object.keys(fields)});
    if(ok){DB.stage(t.id,"account","حساب عبر HTTP "+r.status);return{note:"HTTP"};}}
  if(BR.has()){
    const res=await BR.withPage(async page=>{
      await page.goto(t.signup,{waitUntil:"domcontentloaded",timeout:60000});
      const n=await BR.fill(page,{email:mail.addr,user:CR.user,pass:CR.pass,name:I.name||I.brand,site:I.site_url||""});
      await BR.captchaInPage(page,t.signup);
      await BR.submit(page);await sleep(4000);
      return{url:page.url(),shot:await BR.shot(page,"signup-"+t.id),filled:n,html:await page.content()};});
    DB.ev(t.id,"account-browser",{url:res.url,shot:res.shot,filled:res.filled});
    DB.stage(t.id,"account","حساب عبر المتصفح");return{note:"متصفح "+res.url};}
  needHuman(t,rec,"identity",["افتح "+(t.signup||t.home),"سجّل بالبريد "+mail.addr,"كلمة المرور: "+CR.pass,"أكمل التحقق ثم عد"],"");
  return{note:"يحتاجك"};}
async function sEmail(t,rec){
  if(!(rec.needs||[]).includes("email"))return DB.stage(t.id,"key","بلا تحقق بريد");
  const r=await MAIL.wait(t.id,rec.mailRegex,150000);
  if(!r.link&&!r.code){DB.fail(t.id,"لا بريد تحقق");return DB.stage(t.id,"failed","لم يصل رابط التحقق");}
  if(r.link)await HTTP.get(r.link,{timeout:25000});
  DB.ev(t.id,"email-verified",{link:r.link||"",code:r.code?"موجود":""});
  return DB.stage(t.id,"key","بريد مؤكَّد");}
async function sKey(t,rec){
  const envs=rec.env||[];
  if(!envs.length||(rec.verify||{}).kind==="none")return DB.stage(t.id,"linked","بلا مفاتيح");
  if(envs.every(e=>K.get(e)))return DB.stage(t.id,"linked","مفاتيح موجودة");
  let val="";
  if(rec.keyApi){try{const r=await HTTP.post(rec.keyApi.url,{json:rec.keyApi.body,headers:rec.keyApi.headers,timeout:30000});
    const m=String(r.body).match(new RegExp(rec.regex||"[A-Za-z0-9_\\-]{20,80}"));val=m?m[0]:"";}catch(e){}}
  if(!val&&BR.has()&&rec.keysUrl){
    val=await BR.withPage(async page=>{await page.goto(rec.keysUrl,{waitUntil:"domcontentloaded",timeout:60000});
      await sleep(3500);const c=await BR.scrape(page,rec.regex||"[A-Za-z0-9_\\-]{24,80}");
      await BR.shot(page,"keys-"+t.id);return c[0]||"";});}
  if(!val){needHuman(t,rec,"key",["افتح "+(rec.keysUrl||t.signup),"انسخ المفتاح والصقه"],envs[0]);return{note:"مفتاح يدوي"};}
  const o={};envs.forEach(e=>o[e]=val);K.set(o,"service:"+rec.id);
  DB.ev(t.id,"key",{env:envs,mask:K.mask(val)});return DB.stage(t.id,"key","مفتاح محفوظ");}
async function sLink(t,rec){
  const L=DB.rd(DB.F.links,{});L[t.id]={at:new Date().toISOString(),cat:rec.cat,env:rec.env||[]};DB.wr(DB.F.links,L);
  if(rec.cat==="ads"){const A=DB.rd(DB.F.ads,{});A[t.id]={at:new Date().toISOString(),enabled:!!((rec.env||[]).map(e=>K.get(e)).find(Boolean)),env:rec.env||[]};DB.wr(DB.F.ads,A);
    try{const f=path.join(ROOT,"ads.txt");const line="# "+t.id+" — أضف سطر ads.txt من لوحتك بعد القبول";
      if(fs.existsSync(f)&&!fs.readFileSync(f,"utf8").includes("# "+t.id))fs.appendFileSync(f,line+"\n");}catch(e){}}
  for(const s of ["ADS.sh","INJECT-ADS.sh","TOTAL.sh"]){try{if(fs.existsSync(path.join(H,s))){const {execFileSync}=require("child_process");
    execFileSync("bash",[path.join(H,s)],{cwd:ROOT,stdio:"pipe",timeout:180000});}}catch(e){}}
  DB.ev(t.id,"linked",{cat:rec.cat});return DB.stage(t.id,"linked","مربوط بالتطبيق");}
async function sTest(t,rec){
  const res=await V.probe(rec,t);DB.test(t.id,res);DB.ev(t.id,"test",{ok:res.ok,note:res.note,ms:res.ms});
  if(res.ok){DOC.service(t);return DB.stage(t.id,"live","مُتحقَّق: "+res.note);}
  DB.fail(t.id,res.note);return DB.stage(t.id,"failed",res.note);}
async function sHuman(t,rec){
  const items=Object.values(DB.human()).filter(x=>x.id===t.id&&!x.resolved);
  if(items.length){return{note:"ينتظرك"};}
  return DB.stage(t.id,t.resume||"reachable","عاد بعد تدخلك");}
async function sRetry(t,rec){
  if((t.attempts||0)>=6){needHuman(t,rec,"manual",["افتح "+(t.signup||t.home),"تحقّق يدويًا: "+(t.lastError||"")],"");return;}
  return DB.stage(t.id,t.resume||"reachable","إعادة محاولة");}
const STEPS={new:sResolve,resolved:sReach,reachable:sAccount,account:sEmail,email:sKey,key:sLink,linked:sTest,human:sHuman,failed:sRetry};
async function step(t){const rec=recOf(t);
  const fn=STEPS[t.stage];if(!fn)return{note:"مرحلة غير معروفة: "+t.stage};
  try{const r=await fn(t,rec);log(t.id+" → "+(DB.target(t.id)||{}).stage);return r||{};}
  catch(e){DB.ev(t.id,"error",{msg:String(e.message||e).slice(0,240)});DB.fail(t.id,String(e.message||e).slice(0,120));
    DB.stage(t.id,"failed",String(e.message||e).slice(0,90));log(t.id+" ✗ "+String(e.message||e).slice(0,90));return{ok:false,note:String(e.message||e).slice(0,90)};}}
async function batch(n){DB.ensure();const list=DB.next(n||10);const out=[];
  for(const t of list){const before=t.stage;await step(t);const after=(DB.target(t.id)||{}).stage;
    out.push({id:t.id,from:before,to:after});await sleep(350);}
  DB.jrn("batch",{n:list.length,out:out.map(o=>o.id)});return out;}
module.exports={step,batch,recOf,needHuman};
if(require.main===module){const n=Number(process.argv[2]||"10");
  batch(n).then(r=>{console.log("  ✔ دفعة "+r.length+" هدفًا:");
    r.forEach(x=>console.log("   · "+x.id+"  "+x.from+" → "+x.to));
    const s=DB.stats();console.log("  ── التقدّم: "+s.passed+" مُتحقَّق · "+s.humanPending+" ينتظرك · إجمالي "+s.total);});}
