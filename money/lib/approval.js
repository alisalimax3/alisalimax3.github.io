#!/usr/bin/env node
"use strict";
// يملأ نموذج الطلب كاملًا (المفتاح للموافقة الفورية) + يقرأ بريد الموافقة ويفتح رابطه
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const K=require("./keysfile.js"),MB=require("./mailbox.js"),codes=require("./codes.js");
const KP=JSON.parse(fs.readFileSync(path.join(DATA,"keypages.json"),"utf8"));
const I=()=>JSON.parse(fs.readFileSync(path.join(DATA,"identity.json"),"utf8"));
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
// قيم ترفع احتمال الموافقة الفورية إلى أقصاها
function profile(){
  const id=I();
  return {
    site: K.get("PUBLIC_URL")||"https://"+id.handle+".blogspot.com",
    impressions:"500000", uniques:"150000", pageviews:"1200000",
    sources:"Search Engines, Social Media, Direct, Referral",
    categories:"Movies, Entertainment, Video Streaming, Anime",
    countries:"Worldwide, US, GB, DE, EG, SA, AE",
    adformats:"Popunder, Push, In-Page Push, Native, Banner",
    phone:K.get("PHONE_NUMBER")||"",
    payment:"USDT (TRC20 / Base)", tax:"Individual", company:"Individual",
    role:"Webmaster / Publisher", experience:"3+ years",
    referrer:"Google", interest:"Publisher account", monthly:"500000"
  };
}
function val(f,P){
  const s=((f.name||"")+" "+(f.id||"")+" "+(f.placeholder||"")+" "+(f.getAttribute&&f.getAttribute("aria-label")||"")).toLowerCase();
  const t=(f.type||"").toLowerCase();
  const hit=(...ks)=>ks.some(k=>s.includes(k));
  if(t==="email"||hit("email","mail"))return K.get("CONTACT_EMAIL");
  if(t==="password"||hit("pass"))return K.get("MASTER_PASSWORD");
  if(t==="tel"||hit("phone","mobile","tel"))return P.phone;
  if(hit("confirm"))return K.get("MASTER_PASSWORD");
  if(hit("user","login","nick","handle"))return K.get("BRAND_HANDLE");
  if(hit("first","fname"))return I().brand;
  if(hit("last","lname","surname"))return "Media";
  if(hit("name","company","fullname"))return I().brand;
  if(hit("site","website","url","domain","link"))return P.site;
  if(hit("impress","traffic","volume","visits","views"))return P.impressions;
  if(hit("unique"))return P.uniques;
  if(hit("source","channel"))return P.sources;
  if(hit("categor","niche","vertical","topic"))return P.categories;
  if(hit("country","geo","region"))return P.countries;
  if(hit("format","ad type","placement"))return P.adformats;
  if(hit("payment","payout","wallet","method"))return P.payment;
  if(hit("tax","vat","entity","business type"))return P.tax;
  if(hit("experience","years"))return P.experience;
  if(hit("skype","telegram","messenger"))return I().handle;
  if(hit("city"))return "Cairo";
  if(hit("address"))return "Cairo, Egypt";
  if(hit("postal","zip"))return "11511";
  if(hit("about","comment","message","note","describe","how"))return I().desc_long_en.slice(0,300);
  if(hit("refer"))return P.referrer;
  return "";
}
async function fillAll(page){
  const P=profile();
  const els=await page.$$("input,select,textarea");
  let n=0;
  for(const el of els){
    try{
      const meta=await el.evaluate(e=>({tag:e.tagName,type:e.type,name:e.name,id:e.id,placeholder:e.placeholder,
        aria:e.getAttribute("aria-label")||"",value:e.value}));
      if(["hidden","submit","button","file"].includes(meta.type))continue;
      const box=await el.boundingBox(); if(!box)continue;
      if(meta.tag==="SELECT"){
        const opts=await el.$$eval("option",os=>os.map(o=>({v:o.value,t:o.textContent.trim()})));
        const want=val(meta,P).toLowerCase();
        let pick=opts.find(o=>want&&(o.t.toLowerCase().includes(want)||want.includes(o.t.toLowerCase())));
        if(!pick)pick=opts.find(o=>o.v&&o.v!=="0"&&!/select|choose|--/i.test(o.t));
        if(pick&&pick.v){await page.select(meta.name?`select[name="${meta.name}"]`:`#${meta.id}`,pick.v).catch(()=>{});n++;}
        continue;
      }
      if(meta.type==="checkbox"||meta.type==="radio"){if(!meta.value||meta.value==="on"){await el.click().catch(()=>{});n++;}continue;}
      const v=val(meta,P);
      if(v){await el.click({clickCount:3}).catch(()=>{});await el.type(String(v),{delay:10}).catch(()=>{});n++;}
    }catch(e){}
  }
  return n;
}
async function access(page){const h=await page.content();return /logout|dashboard|sign out|my account|panel/i.test(h);}
async function run(k){
  const rec=KP[k]; if(!rec)return;
  const ppP=path.join(ROOT,"node_modules","puppeteer-core");
  const exe=process.env.CHROME_PATH||["/data/data/com.termux/files/usr/bin/chromium-browser","/usr/bin/chromium"].find(p=>fs.existsSync(p));
  if(!fs.existsSync(ppP)||!exe)return console.log("  ○ "+k+" — بلا متصفح");
  const pp=require(ppP),id=I();
  const br=await pp.launch({executablePath:exe,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
  const page=await br.newPage(); await page.setUserAgent(UA);
  try{
    console.log("\n═══ موافقة "+k+" ═══");
    await page.goto(rec.signup,{waitUntil:"networkidle2",timeout:60000});
    const n=await fillAll(page);
    console.log("  ✔ مُلئ "+n+" حقلًا كاملًا (المفتاح للموافقة الفورية)");
    const b=await page.$('button[type=submit],input[type=submit],button:not([type])');
    if(b)await Promise.all([page.waitForNavigation({waitUntil:"networkidle2",timeout:45000}).catch(()=>{}),b.click()]);
    await sleep(3000);
    const ok=await access(page);
    console.log(ok?"  ✔ دخلت اللوحة فورًا — مقبول":"  ○ قيد المراجعة");
    const {link}=await MB.waitLink(60000);
    if(link){const v=await MB.rq(link);console.log("  ✔ تأكيد/موافقة بالبريد: HTTP "+v.status);}
    // التقاط المفتاح
    await page.goto(rec.keysUrl,{waitUntil:"networkidle2",timeout:60000}).catch(()=>{});
    await sleep(2000);
    const html=await page.content();
    const cand=[...new Set((html.match(new RegExp(rec.regex,"g"))||[]).filter(x=>x.length>=20))].slice(0,6);
    if(cand.length){const o={};rec.env.forEach((e,i)=>o[e]=cand[i]||cand[0]);K.set(o);
      console.log("  ✔ مفتاح: "+Object.keys(o).join(", "));}
    codes.save("موافقة "+k,{الحالة:ok?"مقبول":"قيد المراجعة",الرابط:rec.signup});
    await page.screenshot({path:path.join(ROOT,"logs","approval-"+k+".png")}).catch(()=>{});
  }catch(e){console.log("  ○ "+String(e.message||e).slice(0,80));}
  finally{await br.close();}
}
(async()=>{const a=process.argv.slice(2);
  if(a[0]==="all")for(const k of Object.keys(KP)){await run(k);await sleep(1500);}else if(a[0])await run(a[0]);
})();
