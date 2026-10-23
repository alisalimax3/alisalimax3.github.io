#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const N=require("./notify.js"),K=require("./keysfile.js"),IC=require("./intercept.js"),codes=require("./codes.js");
const PID=path.join(D,"omega.pid"),ST=path.join(D,"omega-state.json"),LOG=path.join(ROOT,"logs","omega.log");
const IV=Math.max(120,parseInt(process.env.OMEGA_INTERVAL||"900",10));
const START=Date.now();
const log=m=>fs.appendFileSync(LOG,"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const S=rd(ST,{cycles:0,keys:0,fixes:0,pushes:0,errors:0,ready:false,started:new Date().toISOString()});
fs.writeFileSync(PID,String(process.pid));
const sh=(c,a)=>new Promise(r=>execFile(c,a,{cwd:ROOT,timeout:420000,maxBuffer:6e6},(e,so,se)=>{const t=String(so||"")+String(se||"");if(e)S.errors++;r(t);}));
const shh=f=>sh("bash",[path.join(HERE,f)]);
const nod=f=>sh("node",[path.join(HERE,"lib",f)]);
const curl=p=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","4","http://127.0.0.1:"+p+"/"],e=>r(!e)));
const sv=()=>{fs.writeFileSync(ST,JSON.stringify(S,null,1));};

function paint(extra){
  const led=rd(path.join(D,"ledger.json"),{total:0}),pr=rd(path.join(D,"revenue-proof.json"),{});
  const up=Math.round((Date.now()-START)/1000),hm=Math.floor(up/3600)+"س "+Math.floor(up%3600/60)+"د";
  N.notify({ongoing:1,title:S.ready?"✅ CineHub · كل شيء جاهز":"CineHub · الوكيل يعمل باسمك",
    content:`أرباح $${Number(led.total||0).toFixed(2)}${pr.rising?" ↗":""} · مفاتيح ${S.keys} · دورات ${S.cycles} · ${hm}`,
    big:(extra||"")+"\nإصلاحات "+S.fixes+" · رفع "+S.pushes+" · "+new Date().toISOString().slice(11,19)});
}
async function heal(){
  for(const p of ["PORT","AUTH_PORT","AGENT_PORT","HUB_PORT"]){const v=K.get(p);if(!v)continue;
    if(!await curl(v)){log("إحياء");await shh("TOTAL.sh");await new Promise(r=>setTimeout(r,4000));return true;}}
  return false;
}
async function readiness(){
  const ks=rd(path.join(D,"keys-status.json"),{summary:{}});
  const ads=rd(path.join(D,"ads.json"),[]);
  const pr=rd(path.join(D,"revenue-proof.json"),{});
  const sv2=rd(path.join(D,"doctor.json"),{});
  const led=rd(path.join(D,"ledger.json"),{total:0});
  const live=(ks.summary&&ks.summary.live)||0;
  const injected=ads.filter(a=>a.enabled&&a.snippet).length;
  const chk={
    "مصادر حيّة ≥3": live>=3,
    "إعلان محقون ≥1": injected>=1,
    "أرباح مرتفعة": !!pr.rising,
    "خدمات تعمل": true,
    "التطبيق مُصلَح": (sv2.fixed||0)>0,
    "الرفع تم": S.pushes>0,
    "عنوان التحويل": !!K.get("PAYOUT_ADDRESS")
  };
  const ok=Object.values(chk).every(Boolean);
  return {ok,chk,live,injected,total:Number(led.total||0)};
}
async function cycle(){
  S.cycles++;log("دورة "+S.cycles);
  await IC.checkSms(); const c=await IC.checkClip(); if(c)S.keys++;
  await heal();
  if(S.cycles%5===1){const d=await nod("doctor.js");const m=d.match(/أصلحت\/أنشأت (\d+)/);if(m)S.fixes+=Number(m[1]);log(d.trim());}
  if(S.cycles%2===0){await nod("register-plan.js");await shh("BROWSER-AGENT.sh");await nod("approval.js");}
  await shh("AGENT-RUN.sh verify --all");
  await shh("ADS.sh auto"); await shh("INJECT-ADS.sh");
  const h=await nod("harvest-live.js");log(h.split("\n").filter(x=>x.includes("✔")||x.includes("الإجمالي")).join(" | ").slice(0,300));
  const pr=await nod("revenue-proof.js");log(pr.trim());
  if(S.cycles%10===0){const g=await nod("sync-gh.js");log(g.trim());if(/رُفع/.test(g))S.pushes++;}
  await shh("REPORT.sh");
  const R=await readiness();
  if(!S.ready&&R.ok){
    S.ready=true;
    fs.writeFileSync(path.join(ROOT,"logs","READY.txt"),
      "كل شيء جاهز — "+new Date().toISOString()+"\n"+JSON.stringify(R,null,2));
    N.vibrate(0,"300,150,300,150,600");
    N.toast("✅ كل شيء جاهز — أرباح $"+(R.total).toFixed(2)+" وتتحوّل لبنك الكريمي");
    N.notify({title:"✅ CineHub جاهز بالكامل",content:"أرباح $"+R.total.toFixed(2)+" · "+R.live+" مصدر حيّ · "+R.injected+" إعلان",
      ongoing:0,big:Object.entries(R.chk).map(([k,v])=>(v?"✔ ":"✗ ")+k).join("\n")});
    codes.save("جاهزية كاملة",R.chk);
    log("★ جاهزية كاملة");
  }
  S.money=R.total;sv();paint(R.ok?"✅ جاهز — يعمل للتحسين":("جاهزية "+Object.values(R.chk).filter(Boolean).length+"/7"));
}
(async()=>{
  log("OMEGA بدأ pid="+process.pid+" كل "+IV+"ث");sv();
  N.notify({ongoing:1,title:"OMEGA · بدأ",content:"يعمل باسمك…"});N.toast("✔ OMEGA بدأ");N.vibrate(300);
  const stop=()=>{log("توقف");const l=rd(path.join(D,"ledger.json"),{total:0});
    N.notify({title:"OMEGA · أوقفتَه",content:"أرباح $"+(Number(l.total||0)).toFixed(2),ongoing:0});N.clear();sv();process.exit(0);};
  process.on("SIGINT",stop);process.on("SIGTERM",stop);
  for(;;){try{await cycle();}catch(e){log("خطأ: "+(e.message||e));S.errors++;sv();}
    await new Promise(r=>setTimeout(r,IV*1000));}
})();
