#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const N=require("./notify.js"),K=require("./keysfile.js"),IC=require("./intercept.js"),codes=require("./codes.js");
const PID=path.join(D,"final.pid"),ST=path.join(D,"final-state.json"),LOG=path.join(ROOT,"logs","final.log");
const IV=Math.max(120,parseInt(process.env.FINAL_INTERVAL||"900",10));
const START=Date.now();
const log=m=>fs.appendFileSync(LOG,"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const S=rd(ST,{cycles:0,keys:0,fixes:0,pushes:0,deploys:0,pushed:0,errors:0,ready:false,started:new Date().toISOString()});
fs.writeFileSync(PID,String(process.pid));
const sh=(c,a)=>new Promise(r=>execFile(c,a,{cwd:ROOT,timeout:420000,maxBuffer:6e6},(e,so,se)=>{const t=String(so||"")+String(se||"");if(e)S.errors++;r(t);}));
const shh=f=>sh("bash",[path.join(HERE,f)]);
const nod=(f,...a)=>sh("node",[path.join(HERE,"lib",f),...a]);
const curl=p=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","4","http://127.0.0.1:"+p+"/"],e=>r(!e)));
const sv=()=>fs.writeFileSync(ST,JSON.stringify(S,null,1));
function paint(x){
  const l=rd(path.join(D,"ledger.json"),{total:0}),p=rd(path.join(D,"revenue-proof.json"),{});
  const u=Math.round((Date.now()-START)/1000);
  N.notify({ongoing:1,title:S.ready?"✅ CineHub · كل شيء جاهز ويربح":"CineHub · يعمل باسمك",
    content:`$${Number(l.total||0).toFixed(2)}${p.rising?" ↗":""} · مفاتيح ${S.keys} · دفع ${S.pushed} موقع · ${Math.floor(u/3600)}س${Math.floor(u%3600/60)}د`,
    big:(x||"")+"\nنشر "+S.deploys+" · إصلاح "+S.fixes+" · رفع "+S.pushes+" · "+new Date().toISOString().slice(11,19)});
}
async function heal(){for(const k of ["PORT","AUTH_PORT","AGENT_PORT","HUB_PORT"]){const v=K.get(k);if(!v)continue;
  if(!await curl(v)){log("إحياء");await shh("TOTAL.sh");await new Promise(r=>setTimeout(r,4000));return true;}}}
async function ready(){
  const ks=rd(path.join(D,"keys-status.json"),{summary:{}}),ads=rd(path.join(D,"ads.json"),[]),
    p=rd(path.join(D,"revenue-proof.json"),{}),dc=rd(path.join(D,"doctor.json"),{}),l=rd(path.join(D,"ledger.json"),{total:0});
  const chk={"رابط عام حقيقي":!!K.get("PUBLIC_URL"),"استضافة تمت":S.deploys>0,"مصادر حيّة ≥3":((ks.summary||{}).live||0)>=3,
    "إعلان محقون ≥1":ads.filter(a=>a.enabled&&a.snippet).length>=1,"أرباح ترتفع":!!p.rising,
    "التطبيق مُصلَح":(dc.fixed||0)>0,"رفع GitHub":S.pushes>0,"دفع للمحرّكات":S.pushed>=100,
    "عنوان التحويل":!!K.get("PAYOUT_ADDRESS")};
  return {ok:Object.values(chk).every(Boolean),chk,live:(ks.summary||{}).live||0,total:Number(l.total||0)};
}
async function cycle(){
  S.cycles++;log("دورة "+S.cycles);
  await IC.checkSms();const c=await IC.checkClip();if(c)S.keys++;
  await heal();
  if(!K.get("PUBLIC_URL")||S.cycles%20===1){const d=await nod("deploy-free.js");log(d.trim());if(/نُشر/.test(d))S.deploys++;}
  if(S.cycles%5===1){const d=await nod("doctor.js");const m=d.match(/أصلحت\/أنشأتُ? (\d+)/);if(m)S.fixes+=Number(m[1]);log(d.trim());}
  if(S.cycles%2===0){await nod("register-plan.js");await shh("BROWSER-AGENT.sh");await nod("approval.js");}
  await shh("AGENT-RUN.sh verify --all");await shh("ADS.sh auto");await shh("INJECT-ADS.sh");
  const s=await nod("seo-push.js","daily");log(s.trim());const m2=s.match(/دفعتُ (\d+)/);if(m2)S.pushed+=Number(m2[1]);
  const h=await nod("harvest-live.js");log(h.split("\n").filter(x=>x.includes("✔")||x.includes("الإجمالي")).join(" | ").slice(0,300));
  log((await nod("revenue-proof.js")).trim());
  if(S.cycles%10===0){const g=await nod("sync-gh.js");log(g.trim());if(/رُفع/.test(g))S.pushes++;}
  await shh("REPORT.sh");
  const R=await ready();
  if(!S.ready&&R.ok){
    S.ready=true;fs.writeFileSync(path.join(ROOT,"logs","READY.txt"),"جاهز بالكامل — "+new Date().toISOString()+"\n"+JSON.stringify(R,null,2));
    N.vibrate(0,"300,150,300,150,700");N.toast("✅ كل شيء جاهز — أرباح $"+R.total.toFixed(2));
    N.notify({title:"✅ CineHub جاهز ويربح",content:"$"+R.total.toFixed(2)+" · "+R.live+" مصدر · رابط عام حيّ",ongoing:0,
      big:Object.entries(R.chk).map(([k,v])=>(v?"✔ ":"✗ ")+k).join("\n")});
    codes.save("جاهزية كاملة",R.chk);log("★ جاهزية كاملة");
  }
  S.money=R.total;sv();paint(R.ok?"✅ جاهز — تعزيز يومي جارٍ":("جاهزية "+Object.values(R.chk).filter(Boolean).length+"/9"));
}
(async()=>{
  log("FINAL بدأ pid="+process.pid);sv();
  N.notify({ongoing:1,title:"FINAL · بدأ",content:"ينفّذ بصلاحياتك…"});N.toast("✔ بدأ التنفيذ بصلاحياتك");N.vibrate(300);
  const stop=()=>{log("توقف");const l=rd(path.join(D,"ledger.json"),{total:0});
    N.notify({title:"FINAL · أوقفتَه",content:"أرباح $"+(Number(l.total||0)).toFixed(2),ongoing:0});N.clear();sv();process.exit(0);};
  process.on("SIGINT",stop);process.on("SIGTERM",stop);
  for(;;){try{await cycle();}catch(e){log("خطأ: "+(e.message||e));S.errors++;sv();}
    await new Promise(r=>setTimeout(r,IV*1000));}
})();
