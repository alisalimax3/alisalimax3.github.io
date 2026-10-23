#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const K=require("./keysfile.js"),MB=require("./mailbox.js"),codes=require("./codes.js");
const T=JSON.parse(fs.readFileSync(path.join(DATA,"harvest-targets.json"),"utf8"));
const KP=JSON.parse(fs.readFileSync(path.join(DATA,"keypages.json"),"utf8"));
const LED=path.join(DATA,"ledger.json");
const iso=d=>new Date(d).toISOString().slice(0,10);
const deep=(o,p)=>{try{return p.split(".").reduce((a,k)=>a&&a[k],o);}catch(e){return null;}};
async function viaApi(id,r,from,to){
  const key=K.get(r.keyEnv); if(!key||!r.api)return null;
  const url=r.api.replace("{FROM}",from).replace("{TO}",to).replace("{KEY}",key);
  const h=Object.fromEntries(Object.entries(r.headers||{}).map(([k,v])=>[k,v.replace("{KEY}",key)]));
  if(r.login){
    const lg=await MB.rq(r.login,{method:"POST",headers:{"content-type":"application/json"}},JSON.stringify({api_token:key}));
    let j={};try{j=JSON.parse(lg.body);}catch(e){}
    const tk=j.token||(j.result&&j.result.token); if(!tk)return null;
    const st=await MB.rq(r.stats,{method:"POST",headers:{"content-type":"application/json",authorization:"Bearer "+tk}},
      JSON.stringify({group_by:["date"],date_from:from,date_to:to}));
    let s={};try{s=JSON.parse(st.body);}catch(e){}
    const rows=s.result||[]; if(!rows.length)return null;
    return rows.reduce((a,x)=>a+Number(x.revenue||0),0);
  }
  const res=await MB.rq(url,{headers:h});
  let j={};try{j=JSON.parse(res.body);}catch(e){}
  let v=r.sum?Number(deep(j,r.sum)):0;
  if(!v){const m=res.body.match(/"revenue"\s*:\s*"?([\d.]+)/);if(m)v=Number(m[1]);}
  if(!v&&Array.isArray(j))v=j.reduce((a,x)=>a+Number(x.revenue||x.amount||0),0);
  return v||null;
}
async function viaDash(id,r){
  const ppP=path.join(ROOT,"node_modules","puppeteer-core");
  const exe=process.env.CHROME_PATH||["/data/data/com.termux/files/usr/bin/chromium-browser","/usr/bin/chromium"].find(p=>fs.existsSync(p));
  if(!fs.existsSync(ppP)||!exe||!r.statsUrl)return null;
  const rec=KP[id]||{},K2=K;
  if(!rec.login)return null;
  const pp=require(ppP);
  const br=await pp.launch({executablePath:exe,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
  const page=await br.newPage();
  await page.setUserAgent("Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36");
  try{
    await page.goto(rec.login,{waitUntil:"networkidle2",timeout:60000});
    const I=JSON.parse(fs.readFileSync(path.join(DATA,"identity.json"),"utf8"));
    const e=await page.$('input[type=email],input[name*=email i]'); if(e)await e.type(I.email.primary,{delay:12});
    const p=await page.$('input[type=password]'); if(p)await p.type(I.password,{delay:12});
    const b=await page.$('button[type=submit],input[type=submit]');
    if(b)await Promise.all([page.waitForNavigation({waitUntil:"networkidle2",timeout:45000}).catch(()=>{}),b.click()]);
    await page.goto(r.statsUrl,{waitUntil:"networkidle2",timeout:60000}).catch(()=>{});
    await new Promise(r2=>setTimeout(r2,3500));
    const txt=await page.evaluate(()=>document.body.innerText);
    const m=txt.match(new RegExp(r.balRegex||"\\$\\s?([0-9]+\\.[0-9]{2})"));
    if(m)return Number(m[1]);
  }catch(e){}
  finally{await br.close();}
  return null;
}
(async()=>{
  const to=iso(Date.now()),from=iso(Date.now()-864e5*7);
  const led=(()=>{try{return JSON.parse(fs.readFileSync(LED,"utf8"));}catch(e){return{total:0,rows:[]};}})();
  let okA=0,okD=0,man=0;
  for(const[id,r]of Object.entries(T)){
    if(!K.get(r.keyEnv)){console.log("  ○ "+id+" — لا مفتاح");man++;continue;}
    let v=null,how="";
    try{v=await viaApi(id,r,from,to);if(v!=null)how="API";}catch(e){}
    if(v==null){try{v=await viaDash(id,r);if(v!=null)how="كشط اللوحة";}catch(e){}}
    if(v==null){console.log("  ○ "+id+" — يحتاج لصقًا: bash money/AGENT.sh set "+r.keyEnv+"=...");man++;continue;}
    led.rows.push({id,from,to,revenue:v,how,at:new Date().toISOString()});
    led.total=Number(led.total||0)+v;
    how==="API"?okA++:okD++;
    console.log("  ✔ "+id+" → $"+Number(v).toFixed(2)+"   ["+how+"]");
  }
  led.harvest={from,to,at:new Date().toISOString(),viaApi:okA,viaDash:okD,manual:man};
  fs.writeFileSync(LED,JSON.stringify(led,null,1));
  console.log("  ── الإجمالي: $"+Number(led.total).toFixed(2)+"  | API:"+okA+"  كشط:"+okD+"  يحتاجك:"+man);
  codes.save("حصد",{من:from,إلى:to,إجمالي:led.total,api:okA,كشط:okD,يدوي:man});
})();
