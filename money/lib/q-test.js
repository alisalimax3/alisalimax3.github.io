#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path"),crypto=require("crypto"),U=require("./q-util.js"),QDB=require("./q-db.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
const PORT=Number(process.env.Q_TEST_PORT||8801);
const sha=b=>crypto.createHash("sha256").update(String(b)).digest("hex").slice(0,12);
function get(p,opt){return new Promise(r=>{const t0=Date.now();
  const q=http.request({host:"127.0.0.1",port:PORT,path:p,method:(opt&&opt.method)||"GET",headers:(opt&&opt.headers)||{}},
    x=>{let b="";x.setEncoding("utf8");x.on("data",c=>b+=c);x.on("end",()=>r({status:x.statusCode,headers:x.headers,body:b,ms:Date.now()-t0}));});
  q.on("error",e=>r({status:0,err:String(e.message),ms:Date.now()-t0}));
  q.setTimeout(20000,()=>q.destroy(new Error("timeout")));
  if(opt&&opt.body)q.write(opt.body);q.end();});}
function post(p,obj){const b=JSON.stringify(obj);return get(p,{method:"POST",body:b,headers:{"content-type":"application/json","content-length":Buffer.byteLength(b)}});}
(async()=>{
  const inv=INV(),T=[],add=(name,ok,status,ms,note)=>T.push({name,ok,status,ms:ms||0,note:note||""});
  const srv=require("./q-static.js").server;
  await new Promise(r=>srv.listen(PORT,"127.0.0.1",r));
  // صفحات
  for(const f of inv.pages.slice(0,80)){const r=await get("/"+f);
    const ok=r.status===200&&/<html|<!doctype/i.test(r.body)&&!/Cannot GET/i.test(r.body);
    add("صفحة "+f,ok,r.status,r.ms,ok?"":("حجم "+r.body.length));}
  // 404 + traversal + deny
  const nf=await get("/no-such-page-xyz");add("404 لصفحة مفقودة",nf.status===404,nf.status,nf.ms);
  const tr=await get("/./index.html");add("مسار مُطبَّع",tr.status===200||tr.status===404,tr.status,tr.ms);
  const dn=await get("/keys.env");add("منع keys.env",dn.status===403,dn.status,dn.ms,"لا يتسرّب");
  const hz=await get("/health");add("فحص الصحة",hz.status===200,hz.status,hz.ms);
  const mt=await get("/metrics");add("المقاييس",mt.status===200&&/auditor_/.test(mt.body),mt.status,mt.ms);
  const mth=await post("/health",{});add("405 لطريقة خاطئة",mth.status===405,mth.status,mth.ms);
  // API
  for(const p of ["/api/version","/api/health","/api/state","/api/findings","/api/tests","/api/keys"]){
    const r=await get(p);let j=null;try{j=JSON.parse(r.body);}catch(e){}
    add("API "+p,!!(r.status===200&&j&&j.ok),r.status,r.ms,r.headers["content-type"]||"");}
  const n404=await get("/api/nope");let jn=null;try{jn=JSON.parse(n404.body);}catch(e){}
  add("API 404 JSON",n404.status===404&&!!jn&&jn.ok===false,n404.status,n404.ms);
  const before=QDB.count("events");
  const ev=await post("/api/event",{kind:"audit-test",payload:{x:1}});
  const after=QDB.count("events");
  add("كتابة في القاعدة",ev.status===201&&after===before+1,ev.status,ev.ms,"قبل "+before+" بعد "+after);
  const big=await post("/api/event",{kind:"big",payload:{s:"x".repeat(400000)}});
  add("حمولة كبيرة",big.status===201||big.status===413,big.status,big.ms);
  const bad=await get("/api/event",{method:"POST",body:"{bad",headers:{"content-type":"application/json"}});
  add("JSON تالف",bad.status===400,bad.status,bad.ms);
  // أزرار/روابط/نماذج (تحليل بنيوي)
  let anchors=0,btns=0,forms=0,badHref=0;
  for(const f of inv.pages.slice(0,80)){const s=U.read(path.join(U.ROOT,f),900000);
    anchors+=(s.match(/<a\b/gi)||[]).length;btns+=(s.match(/<button\b/gi)||[]).length;forms+=(s.match(/<form\b/gi)||[]).length;
    for(const m of s.matchAll(/<a\b[^>]*href=["'](?!https?:|\/\/|#|mailto:|tel:|javascript:)([^"']+)["']/gi)){
      const t=m[1].split(/[?#]/)[0];if(!t)continue;
      const abs=t.startsWith("/")?path.join(U.ROOT,t):path.join(U.ROOT,path.dirname(f),t);
      if(!fs.existsSync(abs))badHref++;}}
  add("روابط داخلية سليمة",badHref===0,badHref===0?200:0,0,anchors+" رابط · "+btns+" زر · "+forms+" نموذج"+(badHref?" · مكسور "+badHref:""));
  // اختبار حقيقي للمتصفح إن توفّر
  const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium"].find(p=>fs.existsSync(p));
  if(CH&&fs.existsSync(path.join(U.ROOT,"node_modules","puppeteer-core"))){
    try{const pp=require(path.join(U.ROOT,"node_modules","puppeteer-core"));
      const br=await pp.launch({executablePath:CH,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu","--single-process"]});
      const page=await br.newPage();const errs=[];
      page.on("pageerror",e=>errs.push(String(e.message).slice(0,90)));
      page.on("console",m=>{if(m.type()==="error")errs.push("console:"+String(m.text()).slice(0,80));});
      await page.goto("http://127.0.0.1:"+PORT+"/"+(inv.pages[0]||"index.html"),{waitUntil:"domcontentloaded",timeout:30000}).catch(()=>{});
      const title=await page.title().catch(()=>"");
      await br.close();
      add("تشغيل المتصفح",errs.length===0,200,0,errs.slice(0,3).join(" | ")||("title: "+title.slice(0,40)));}
    catch(e){add("تشغيل المتصفح",false,0,0,String(e.message).slice(0,80));}}
  else add("تشغيل المتصفح",true,0,0,"لا متصفح — تخطّي مُعلن");
  await new Promise(r=>srv.close(r));
  const pass=T.filter(x=>x.ok).length;
  U.jw(path.join(U.A,"tests.json"),{at:new Date().toISOString(),total:T.length,passed:pass,items:T});
  for(const t of T)QDB.insert("tests",{name:t.name,ok:t.ok?1:0,status:t.status||0,ms:t.ms||0,note:t.note||""});
  console.log("  ✔ اختبار وظيفي: "+pass+"/"+T.length+" ناجح");
  T.filter(x=>!x.ok).slice(0,10).forEach(x=>console.log("   ✗ "+x.name+" ["+x.status+"] "+x.note));
  U.ev({phase:"test",ok:pass===T.length,detail:{passed:pass,total:T.length}});
  process.exit(pass===T.length?0:1);})();
