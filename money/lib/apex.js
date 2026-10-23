#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data"),LOG=path.join(ROOT,"logs","apex.log");
const N=require("./anotify.js"),K=require("./akeys.js"),IC=require("./aintercept.js"),AL=require("./aledger.js"),
      W=require("./awatch.js"),PR=require("./aprivi.js"),HL=require("./ahealth.js"),AU=require("./aaudit.js"),
      TG=require("./atelegram.js"),codes=require("./acodes.js"),DP=require("./adeploy.js");
const PID=path.join(D,"apex.pid"),ST=path.join(D,"apex-state.json");
const IV=Math.max(120,parseInt(process.env.APEX_INTERVAL||"600",10)),START=Date.now();
const log=m=>{try{fs.appendFileSync(LOG,"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");}catch(e){}};
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const S=rd(ST,{cycles:0,keys:0,fixes:0,pushes:0,deploys:0,harvest:0,errors:0,ready:false,live:0,lastTotal:0,started:new Date().toISOString()});
fs.writeFileSync(PID,String(process.pid));
const sh=(c,a)=>new Promise(r=>execFile(c,a,{cwd:ROOT,timeout:480000,maxBuffer:8e6},(e,so,se)=>{const t=String(so||"")+String(se||"");if(e)S.errors++;r(t);}));
const has=f=>fs.existsSync(path.join(H,f));
const shh=f=>has(f)?sh("bash",[path.join(H,f)]):Promise.resolve("");
const nod=(f,...a)=>has("lib/"+f)?sh("node",[path.join(H,"lib",f),...a]):Promise.resolve("");
const curl=p=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","4","http://127.0.0.1:"+p+"/"],e=>r(!e)));
const sv=()=>{try{fs.writeFileSync(ST,JSON.stringify(S,null,1));}catch(e){}};
function paint(extra){const l=AL.rd();const up=Math.round((Date.now()-START)/1000);
  N.notify({ongoing:1,title:S.ready?"✅ CineHub · كل شيء جاهز ويربح":"CineHub · APEX يعمل بصلاحياتك",
    content:"أرباح $"+Number(l.total||0).toFixed(2)+" · صحة "+S.score+" · مفاتيح "+S.keys+" · دورات "+S.cycles+" · "+Math.floor(up/3600)+"س"+Math.floor(up%3600/60)+"د",
    big:(extra||"")+"\nنشر "+S.deploys+" · إصلاح "+S.fixes+" · رفع "+S.pushes+" · مصادر "+S.live+"\n"+new Date().toISOString().slice(11,19)});}
async function heal(){
  for(const p of ["PORT","AUTH_PORT","AGENT_PORT","HUB_PORT"]){const v=K.get(p);if(!v)continue;
    if(!await curl(v)){log("إحياء الخدمات");await shh("TOTAL.sh");await new Promise(r=>setTimeout(r,4000));break;}}
  const dp=K.get("DASH_PORT")||"8788";
  if(!await curl(dp)){const r=W.ensure({name:"dashboard",cmd:"node",args:[path.join(H,"lib","adash.js")]});log("لوحة: "+r.action);}
  for(const[k,v]of Object.entries(W.rd())){if(v.pid&&!W.alive(v.pid))log("سقط "+k);}}
async function cycle(){
  S.cycles++;log("دورة "+S.cycles);
  PR.grant(false);
  await IC.checkSms();const c=await IC.checkClip();if(c)S.keys++;
  await heal();
  if(!K.get("PUBLIC_URL")||S.cycles%24===1){const d=await nod("adeploy.js");if(/نُشر|→/.test(d))S.deploys++;log(d.trim().split("\n").filter(x=>x.includes("✔")).join(" | ").slice(0,200));}
  if(S.cycles%6===1){const d=await nod("adoctor.js");const m=d.match(/أصلحت\/أنشأت (\d+)/);if(m)S.fixes+=Number(m[1]);log(d.trim());}
  if(S.cycles%4===1){await nod("atraffic.js");await nod("asites.js");}
  if(S.cycles%2===0){await shh("BROWSER-AGENT.sh");await nod("aapproval.js");}
  await shh("AGENT-RUN.sh");await shh("ADS.sh");await shh("INJECT-ADS.sh");
  const s=await nod("aseo.js","250");const m2=s.match(/دُفعت (\d+)/);if(m2)S.pushes+=Number(m2[1]);log(s.trim().split("\n").join(" | ").slice(0,200));
  await shh("harvest-live.js");await nod("aharvest.js");
  const hj=rd(path.join(D,"harvest.json"),{});S.live=hj.live||S.live;
  const tot=Number(rd(path.join(D,"ledger.json"),{total:0}).total||0);
  if(tot>S.lastTotal){AL.add("harvest",tot-S.lastTotal,{note:"من الحصد المباشر"});S.lastTotal=tot;}
  if(S.cycles%12===0){await nod("apayout.js");await nod("asnapshot.js");}
  if(S.cycles%20===0){const g=await nod("async.js");if(/رُفع/.test(g))S.pushes++;const u=await nod("aupdate.js");log(u.trim());}
  if(S.cycles%8===0)await nod("aoutreach.js");
  const R=HL.score();S.score=R.score;
  if(!S.ready&&R.ready){S.ready=true;
    fs.writeFileSync(path.join(ROOT,"logs","READY.txt"),"جاهز بالكامل — "+new Date().toISOString()+"\n"+JSON.stringify(R,null,2));
    N.vibrate("300,150,300,150,700");N.toast("✅ كل شيء جاهز — $"+Number(AL.rd().total||0).toFixed(2));
    N.notify({ongoing:0,title:"✅ CineHub جاهز ويربح",content:"$"+Number(AL.rd().total||0).toFixed(2)+" · صحة 100/100",
      big:Object.entries(R.gates).map(([k,v])=>(v?"✔ ":"✗ ")+k).join("\n")});
    await TG.send("✅ CineHub جاهز — $"+Number(AL.rd().total||0).toFixed(2));
    codes.save("جاهزية كاملة",R.gates);AU.add("ready",R.gates);log("★ جاهزية كاملة");}
  if(S.cycles%10===0)await TG.send("<b>APEX</b>\nأرباح: $"+Number(AL.rd().total||0).toFixed(2)+"\nصحة: "+R.score+"/100\nمفاتيح: "+S.keys+"\n"+(K.get("PUBLIC_URL")||"لا رابط"));
  AU.add("cycle",{n:S.cycles,score:R.score,total:Number(AL.rd().total||0)});
  sv();paint(R.ready?"✅ جاهز — تحسين مستمر":"بوابات "+Object.values(R.gates).filter(Boolean).length+"/10");}
(async()=>{log("APEX بدأ pid="+process.pid+" كل "+IV+"ث");sv();
  await N.notify({ongoing:1,title:"APEX · بدأ",content:"ينفّذ بصلاحياتك…"});N.toast("✔ APEX بدأ");N.vibrate("300");
  const stop=()=>{log("توقف");N.notify({title:"APEX · أوقفتَه",content:"أرباح $"+Number(AL.rd().total||0).toFixed(2),ongoing:0});N.clear();sv();process.exit(0);};
  process.on("SIGINT",stop);process.on("SIGTERM",stop);
  for(;;){try{await cycle();}catch(e){log("خطأ: "+(e.message||e));S.errors++;sv();}
    await new Promise(r=>setTimeout(r,IV*1000));}})();
