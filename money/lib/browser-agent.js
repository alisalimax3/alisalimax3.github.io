#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const K=require("./keysfile.js"),MB=require("./mailbox.js"),CAP=require("./captcha.js"),codes=require("./codes.js");
const KP=JSON.parse(fs.readFileSync(path.join(DATA,"keypages.json"),"utf8"));
const CAND=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium","/usr/bin/chromium-browser"];
const chrom=()=>process.env.CHROME_PATH||CAND.find(p=>fs.existsSync(p))||"";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const open=u=>new Promise(r=>execFile("termux-open-url",[u],()=>r()));
const I=()=>JSON.parse(fs.readFileSync(path.join(DATA,"identity.json"),"utf8"));
const UA="Mozilla/5.0 (Linux; Android 13; SM-A536B) AppleWebKit/537.36 Chrome/124 Safari/537.36";
async function fill(page,id){
  for(const[sel,v]of [['input[type=email],input[name*=email i],input[name*=mail i]',id.email.primary],
    ['input[type=password]',id.password],['input[name*=user i],input[name*=login i],input[name*=nick i]',id.handle],
    ['input[name*=name i],input[name*=first i]',id.brand]]){
    const e=await page.$(sel);if(e){try{await e.click({clickCount:3});await e.type(v,{delay:14});}catch(x){}}}
  const cb=await page.$('input[type=checkbox]');if(cb){try{await cb.click();}catch(x){}}
}
async function inject(page,url){
  const i=await page.evaluate(()=>{const e=document.querySelector("[data-sitekey]");
    return {k:e?e.getAttribute("data-sitekey"):"",
      kind:document.querySelector("iframe[src*=hcaptcha],.h-captcha")?"hcaptcha":
        (document.querySelector("iframe[src*=recaptcha],.g-recaptcha")?"recaptcha":
        (document.querySelector(".cf-turnstile")?"turnstile":""))};});
  if(!i.kind)return;
  const t=await CAP.solve(i.kind,url,i.k); if(!t)return;
  await page.evaluate(tok=>{for(const n of["h-captcha-response","g-recaptcha-response","cf-turnstile-response"]){
    let e=document.querySelector('[name="'+n+'"]');
    if(!e){e=document.createElement("textarea");e.name=n;e.style.display="none";document.body.appendChild(e);}
    e.value=tok;}},t);
}
async function submit(page){
  const b=await page.$('button[type=submit],input[type=submit],button:not([type])');
  if(b)await Promise.all([page.waitForNavigation({waitUntil:"networkidle2",timeout:45000}).catch(()=>{}),b.click()]);
  await sleep(2500);
}
async function run(k){
  const rec=KP[k];if(!rec)return;
  const id=I(),exe=chrom(),ppPath=path.join(ROOT,"node_modules","puppeteer-core");
  const pp=fs.existsSync(ppPath)&&exe?require(ppPath):null;
  console.log("\n═══ "+k+" ═══");
  let page=null,br=null;
  if(pp){
    br=await pp.launch({executablePath:exe,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
    page=await br.newPage();await page.setUserAgent(UA);
    try{
      await page.goto(rec.signup,{waitUntil:"networkidle2",timeout:60000});
      await fill(page,id);await inject(page,rec.signup);await submit(page);
      console.log("  ✔ أُرسل النموذج");
    }catch(e){console.log("  ○ "+String(e.message||e).slice(0,70));}
  }else{console.log("  ○ بلا Chromium — فتحتُ المتصفح لتُكمل الضغط");await open(rec.signup);}
  const {link}=await MB.waitLink(90000);
  if(link){const v=await MB.rq(link);console.log("  ✔ تأكيد البريد: HTTP "+v.status);}
  if(page){
    try{
      await page.goto(rec.login,{waitUntil:"networkidle2",timeout:60000});
      await fill(page,id);await inject(page,rec.login);await submit(page);
      await page.goto(rec.keysUrl,{waitUntil:"networkidle2",timeout:60000}).catch(()=>{});
      await sleep(2500);
      const html=await page.content();
      const cand=[...new Set((html.match(new RegExp(rec.regex,"g"))||[]).filter(x=>x.length>=20))].slice(0,6);
      if(cand.length){
        const o={};rec.env.forEach((e,i)=>o[e]=cand[i]||cand[0]);K.set(o);
        console.log("  ✔ كُتب في keys.env: "+Object.keys(o).join(", "));
        codes.save("مفتاح مكتشف — "+k,Object.assign({الرابط:rec.keysUrl},o));}
      else console.log("  ○ لم ألتقط المفتاح — "+rec.keysUrl);
      fs.mkdirSync(path.join(ROOT,"logs"),{recursive:true});
      await page.screenshot({path:path.join(ROOT,"logs","shot-"+k+".png")}).catch(()=>{});
    }catch(e){console.log("  ○ "+String(e.message||e).slice(0,70));}
    finally{await br.close();}
  }else console.log("  → المفاتيح: "+rec.env.join(", ")+"  من: "+rec.keysUrl);
}
(async()=>{const a=process.argv.slice(2);
 if(a[0]==="all")for(const k of Object.keys(KP)){await run(k);await sleep(1500);}
 else if(a[0])await run(a[0]);
 else console.log("الأسماء: "+Object.keys(KP).join(", "));
})();
