#!/usr/bin/env node
/* بوت المشاهدة: يسجّل في التطبيق، ثم يتنقّل بين صفحات الأفلام/البالغين لتوليد ظهورات إعلانية حقيقية */
"use strict";
const fs=require("fs"),path=require("path");
const M=__dirname, ROOT=path.resolve(M,".."), DATA=path.join(M,"data");
let chromium; try{ ({chromium}=require("playwright")); }catch(e){ console.log("playwright غير مثبت: cd money && npm i -D playwright && npx playwright install chromium"); process.exit(0); }
const PORT=process.env.PORT||"8787", BASE=process.env.PUBLIC_URL||`http://127.0.0.1:${PORT}`;
const EMAIL=process.env.BOT_EMAIL||(process.env.REG_EMAIL? process.env.REG_EMAIL.replace("@","+bot@"):"bot@cinehub.local");
const WANT=["watch","play","movie","film","series","adult","cams","go"];
async function login(){
  const r=await fetch(BASE+"/api/signup",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({email:EMAIL,device:"watchbot"})});
  const d=await r.json(); if(!d.ok) throw new Error(d.error||"signup");
  const uf=path.join(DATA,"users.json"); const u=JSON.parse(fs.readFileSync(uf,"utf8")).users;
  const id=Object.keys(u).find(k=>u[k].email===EMAIL); const code=u[id].code;
  const v=await fetch(BASE+"/api/verify",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({email:EMAIL,code})});
  const sc=v.headers.get("set-cookie"); if(!sc) throw new Error("no cookie");
  return sc.split(";")[0];
}
(async()=>{
  const pages=fs.readdirSync(ROOT).filter(f=>f.endsWith(".html")&&WANT.some(w=>f.toLowerCase().includes(w)));
  const targets=pages.length?pages:["index.html"];
  const cookie=await login();
  const ctx=await chromium.launchPersistentContext(path.join(DATA,"watch-profile"),{headless:process.env.HEADLESS!=="0",viewport:{width:1366,height:900}});
  await ctx.addCookies([{name:cookie.split("=")[0],value:cookie.split("=")[1],domain:"127.0.0.1",path:"/"}]);
  const page=ctx.pages()[0]||await ctx.newPage();
  console.log(`watchbot: ${targets.length} صفحة | ${BASE}`);
  let i=0;
  for(;;){
    const t=targets[i%targets.length]; i++;
    try{
      await page.goto(BASE+"/"+t,{waitUntil:"domcontentloaded",timeout:40000});
      await page.waitForTimeout(2000);
      const v=page.locator("video").first();
      if(await v.count()){ await v.click({timeout:3000}).catch(()=>{}); }
      else { await page.mouse.wheel(0,600).catch(()=>{}); }
      await page.waitForTimeout(Number(process.env.WATCH_SECONDS||45)*1000);
      console.log(`  ${t} ✔`);
    }catch(e){ console.log(`  ${t} ✗ ${String(e.message).slice(0,50)}`); }
  }
})();
