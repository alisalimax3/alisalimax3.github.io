#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,"..");
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36";
const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium","/usr/bin/chromium-browser","/usr/bin/google-chrome"];
const exe=()=>process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p));
const has=()=>!!(exe()&&fs.existsSync(path.join(ROOT,"node_modules","puppeteer-core")));
async function withPage(fn){if(!has())return{ok:false,note:"لا متصفح"};
  const pp=require(path.join(ROOT,"node_modules","puppeteer-core"));
  const br=await pp.launch({executablePath:exe(),headless:"new",
    args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu","--single-process","--no-zygote","--disable-setuid-sandbox"]});
  const page=await br.newPage();await page.setUserAgent(UA);await page.setViewport({width:1366,height:900});
  try{return await fn(page,br);}catch(e){return{ok:false,note:String(e.message||e).slice(0,160)};}finally{try{await br.close();}catch(e){}}}
async function shot(page,name){try{const d=path.join(ROOT,"logs","shots");fs.mkdirSync(d,{recursive:true});
  const f=path.join(d,name+".png");await page.screenshot({path:f});return path.relative(ROOT,f);}catch(e){return"";}}
async function fill(page,map){let n=0;
  const pairs=[["email","input[type=email],input[name*=mail i],input[id*=mail i]"],
   ["pass","input[type=password],input[name*=pass i],input[id*=pass i]"],
   ["user","input[name*=user i],input[name*=login i],input[id*=login i],input[name*=nick i]"],
   ["name","input[name*=name i],input[id*=name i],input[name*=first i]"],
   ["site","input[name*=site i],input[name*=url i],input[name*=website i],input[name*=domain i]"]];
  for(const[k,sel]of pairs){if(!map[k])continue;try{const el=await page.$(sel);if(!el)continue;
    await el.click({clickCount:3});await el.type(String(map[k]),{delay:14});n++;}catch(e){}}
  try{const cb=await page.$('input[type=checkbox]:not([checked])');if(cb)await cb.click();}catch(e){}
  return n;}
async function submit(page){try{const b=await page.$('button[type=submit],input[type=submit],form button:not([type=button])');
  if(!b)return false;await Promise.all([page.waitForNavigation({waitUntil:"domcontentloaded",timeout:40000}).catch(()=>{}),b.click()]);return true;}catch(e){return false;}}
async function clickText(page,txt){const h=await page.evaluateHandle(t=>{const a=[...document.querySelectorAll("a,button,input[type=submit]")];
  return a.find(x=>((x.innerText||x.value||"").toLowerCase().includes(t)))||null;},String(txt).toLowerCase());
  const el=h&&h.asElement?h.asElement():null;if(!el)return false;try{await el.click();return true;}catch(e){return false;}}
async function scrape(page,rx){try{const html=await page.content();
  return [...new Set((html.match(new RegExp(rx,"g"))||[]).filter(x=>x.length>=16))].slice(0,8);}catch(e){return[];}}
async function captchaInPage(page,url){try{const info=await page.evaluate(()=>{const el=document.querySelector("[data-sitekey]");
  const k=el?el.getAttribute("data-sitekey"):"";
  const kind=document.querySelector("iframe[src*=hcaptcha],.h-captcha")?"hcaptcha":
    (document.querySelector("iframe[src*=recaptcha],.g-recaptcha")?"recaptcha":(document.querySelector(".cf-turnstile")?"turnstile":""));
  return{k,kind};});
  if(!info.kind)return"";
  const t=await require("./z-captcha.js").solve(info.kind,url,info.k);
  if(!t)return"";
  await page.evaluate(tok=>{["h-captcha-response","g-recaptcha-response","cf-turnstile-response"].forEach(n=>{
    let e=document.querySelector('[name="'+n+'"]');
    if(!e){e=document.createElement("textarea");e.name=n;e.style.display="none";document.body.appendChild(e);}e.value=tok;});},t);
  return t;}catch(e){return"";}}
module.exports={withPage,has,exe,fill,submit,clickText,scrape,shot,captchaInPage,UA};
