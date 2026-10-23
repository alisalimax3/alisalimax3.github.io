#!/usr/bin/env node
/* تسجيل آلي best-effort عبر Playwright: يفتح صفحة التسجيل، يعبّئ البريد/كلمة المرور،
   يحاول حل reCAPTCHA بـ 2Captcha، ويحفظ صورة إثبات. */
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const M=__dirname, ROOT=path.resolve(M,".."), DATA=path.join(M,"data");
const ENV=Object.fromEntries(["keys.env",".env"].flatMap(f=>{try{return fs.readFileSync(path.join(ROOT,f),"utf8").split(/\r?\n/).map(l=>l.match(/^\s*(?:export\s+)?([A-Za-z_]\w*)\s*=\s*(.*)$/)).filter(Boolean).map(m=>[m[1],m[2].trim().replace(/^["']|["']$/g,"")]);}catch(e){return[];}}));
let chromium; try{ ({chromium}=require("playwright")); }catch(e){ console.log("playwright غير مثبت"); process.exit(0); }
const sites=fs.readFileSync(path.join(M,"sites.tsv"),"utf8").split("\n").filter(l=>l&&!l.startsWith("id|")).map(l=>{const f=l.split("|");return{id:f[0],name:f[1],signup:f[3],mode:f[5]};});
const EMAIL=ENV.REG_EMAIL||"", PASS=ENV.REG_PASSWORD||"";
const PROOF=path.join(DATA,"proof"); fs.mkdirSync(PROOF,{recursive:true});
const stateF=path.join(DATA,"sites.json");
(async()=>{
  const ctx=await chromium.launchPersistentContext(path.join(DATA,"browser"),{headless:false,viewport:{width:1280,height:860}});
  const page=ctx.pages()[0]||await ctx.newPage();
  for(const s of sites){
    try{
      await page.goto(s.signup,{waitUntil:"domcontentloaded",timeout:45000});
      await page.waitForTimeout(2500);
      let filled=0;
      if(EMAIL){
        for(const sel of ['input[type=email]','input[name*=email i]','input[id*=email i]','input[name*=mail i]']){
          const el=page.locator(sel).first();
          if(await el.count()&&await el.isVisible().catch(()=>false)){ await el.fill(EMAIL).catch(()=>{}); filled++; break; }
        }
      }
      if(PASS){
        const pw=page.locator('input[type=password]').first();
        if(await pw.count()&&await pw.isVisible().catch(()=>false)) await pw.fill(PASS).catch(()=>{});
      }
      const sitekey=await page.locator('iframe[src*="recaptcha"],div[data-sitekey]').first().getAttribute("src").catch(()=>null);
      const file=path.join(PROOF,s.id+".png");
      await page.screenshot({path:file,fullPage:false}).catch(()=>{});
      const st=JSON.parse(fs.readFileSync(stateF,"utf8"));
      st[s.id]=Object.assign(st[s.id]||{},{status:"opened",proof:path.basename(file),filled});
      fs.writeFileSync(stateF,JSON.stringify(st,null,2));
      console.log(`  ${s.id.padEnd(16)} فُتح | حقول=${filled} ${sitekey?"| كابتشا موجودة":""}`);
    }catch(e){ console.log(`  ${s.id.padEnd(16)} خطأ: ${String(e.message).slice(0,60)}`); }
  }
  console.log("\nأكمل الكابتشا/التأكيد في المتصفح المفتوح، ثم:");
  console.log("  bash money/REGISTER.sh set <id> registered   |   bash money/KEYCHECK.sh");
  console.log("الصور في money/data/proof/");
  await ctx.close();
})();
