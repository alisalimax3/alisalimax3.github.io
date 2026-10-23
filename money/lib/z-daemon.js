#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const DB=require("./z-db.js"),RUN=require("./z-runner.js"),V=require("./z-verify.js"),DOC=require("./z-docs.js"),
  N=require("./z-notify.js"),HU=require("./z-human.js"),K=require("./z-keys.js"),PR=require("./aprivi.js");
const PID=path.join(D,"zero.pid"),ST=path.join(D,"zero-state.json"),PAUSE=path.join(D,"zero.pause"),LOG=path.join(ROOT,"logs","zero.log");
const IV=Math.max(60,parseInt(process.env.ZERO_INTERVAL||"300",10)),START=Date.now();
const log=m=>{try{fs.appendFileSync(LOG,"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");}catch(e){}};
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const S=rd(ST,{cycles:0,started:new Date().toISOString()});
fs.writeFileSync(PID,String(process.pid));
const sh=(c,a)=>new Promise(r=>execFile(c,a,{cwd:ROOT,timeout:600000,maxBuffer:8e6},(e,so,se)=>r(String(so||"")+String(se||""))));
async function heal(){for(const p of ["PORT","AUTH_PORT","AGENT_PORT","HUB_PORT"]){const v=K.get(p);if(!v)continue;
  const ok=await new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","4","http://127.0.0.1:"+v+"/"],e=>r(!e)));
  if(!ok){log("إحياء الخدمات");await sh("bash",[path.join(H,"TOTAL.sh")]);await new Promise(r=>setTimeout(r,4000));break;}}}
async function cycle(){S.cycles++;log("دورة "+S.cycles);
  if(fs.existsSync(PAUSE)){log("موقوف مؤقتًا");return;}
  PR.grant(false);
  const out=await RUN.batch(Number(process.env.ZERO_BATCH||"10"));
  log("دفعة: "+out.length+" · "+out.filter(o=>o.to==="live").length+" مُتحقَّق");
  if(S.cycles%3===0)await V.verifyAll(120);
  await heal();
  const s=DB.stats(),h=HU.pending().length;
  if(S.cycles%2===0){DOC.index();DOC.report();DOC.handover();DOC.evidence();}
  if(h>0&&(Date.now()-(S.lastHuman||0)>6*3600e3)){S.lastHuman=Date.now();
    const sh2=HU.write();
    await N.notify({ongoing:0,title:"🧑 تحتاجك "+h+" مهمة",content:"جلسة واحدة فقط — اضغط الزر",
      big:(HU.pending().slice(0,6).map(x=>"· "+x.id+" — "+(HU.WHY[x.why]||x.why)).join("\n"))});
    await N.vibrate("250,120,250");
    await N.telegram("<b>ZERO</b> — تحتاجك "+h+" مهمة\n"+HU.pending().slice(0,8).map(x=>"· "+x.id+" ("+(HU.WHY[x.why]||x.why)+")").join("\n"));
    log("طُلب تدخل: "+h+" مهمة → "+sh2);}
  N.notify({ongoing:1,title:"ZERO · يعمل بصلاحياتك",
    content:"مُتحقَّق "+s.passed+"/"+s.total+" · أدلة "+s.evidence+" · ينتظرك "+h,
    big:"دورات "+S.cycles+" · "+(K.get("PUBLIC_URL")||"لا رابط")+" · "+new Date().toISOString().slice(11,19)});
  if(S.cycles%10===0)await N.telegram("<b>ZERO</b>\nمُتحقَّق: "+s.passed+"\nإجمالي: "+s.total+"\nينتظرك: "+h);
  S.passed=s.passed;S.total=s.total;S.human=h;fs.writeFileSync(ST,JSON.stringify(S,null,1));}
(async()=>{log("ZERO بدأ pid="+process.pid);DB.ensure();
  await N.notify({ongoing:1,title:"ZERO · بدأ التنفيذ",content:"يسجّل ويتحقق بنفسه · يطلبك عند الحاجة فقط"});
  await N.toast("✔ ZERO بدأ — كل ما يلزمك سيأتي في جلسة واحدة");
  const stop=()=>{log("توقف");N.clear();N.notify({title:"ZERO · أوقفتَه",content:"التقدّم محفوظ — يتابع من حيث توقّف"});process.exit(0);};
  process.on("SIGINT",stop);process.on("SIGTERM",stop);
  for(;;){try{await cycle();}catch(e){log("خطأ: "+(e.message||e));}
    await new Promise(r=>setTimeout(r,IV*1000));}})();
