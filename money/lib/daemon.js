#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const N=require("./notify.js"),K=require("./keysfile.js"),IC=require("./intercept.js"),codes=require("./codes.js");
const PID=path.join(D,"bot.pid"),ST=path.join(D,"bot-state.json"),LOG=path.join(ROOT,"logs","bot.log");
const IV=Math.max(120,parseInt(process.env.BOT_INTERVAL||"900",10));
const START=Date.now();
const log=m=>{const l="["+new Date().toISOString().slice(11,19)+"] "+m;fs.appendFileSync(LOG,l+"\n");};
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const S=rd(ST,{cycles:0,keys:0,money:0,lastMoney:0,errors:0,started:new Date().toISOString()});
fs.writeFileSync(PID,String(process.pid));
const sh=(c,a)=>new Promise(r=>execFile(c,a,{cwd:ROOT,timeout:420000,maxBuffer:4e6},(e,so,se)=>{const t=String(so||"")+String(se||"");if(e)S.errors++;r(t);}));
const shh=f=>sh("bash",[path.join(HERE,f)]);
const curl=p=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","4","http://127.0.0.1:"+p+"/"],e=>r(!e)));

function paint(extra){
  const led=rd(path.join(D,"ledger.json"),{total:0});
  const w=rd(path.join(D,"wallet.json"),{});
  const up=Math.round((Date.now()-START)/1000);
  const hm=Math.floor(up/3600)+"س "+Math.floor(up%3600/60)+"د";
  N.notify({ongoing:1,title:"CineHub · الوكيل يعمل باسمك",
    content:`دورات ${S.cycles} · مفاتيح ${S.keys} · أرباح $${Number(led.total||0).toFixed(2)} · ${hm}`,
    big:(extra||"")+"\nآخر دورة: "+new Date().toISOString().slice(11,19)});
}
async function alive(){
  for(const p of ["PORT","AUTH_PORT","AGENT_PORT","HUB_PORT"]){
    const v=K.get(p); if(!v)continue;
    if(!await curl(v)){log("إحياء الخدمات ("+p+")");await shh("TOTAL.sh");await new Promise(r=>setTimeout(r,4000));return true;}
  }return false;
}
async function cycle(){
  S.cycles++;
  const before=Number(rd(path.join(D,"ledger.json"),{total:0}).total||0);
  log("دورة "+S.cycles);
  await IC.checkSms();
  const c=await IC.checkClip(); if(c)S.keys++;
  await alive();
  // تسجيل + موافقة للشبكات الناقصة (بمعدل شبكة كل دورة)
  try{
    const srcs=JSON.parse(fs.readFileSync(path.join(HERE,"sources-big.json"),"utf8"));
    const MONEY=["adult","ads","pay"];
    const miss=srcs.filter(x=>MONEY.includes(x.cat)&&x.env.every(e=>!K.get(e)));
    const q=rd(path.join(D,"queue.json"),{done:[],skip:[]});
    const nx=miss.find(x=>!q.skip.includes(x.id));
    if(nx){q.current=nx.id;fs.writeFileSync(path.join(D,"queue.json"),JSON.stringify(q,null,1));
      log("التالي: "+nx.name);N.toast("🎯 "+nx.name);
      await shh("BROWSER-AGENT.sh");}
  }catch(e){log("queue: "+e.message);}
  await shh("AGENT-RUN.sh verify --all").catch(()=>{});
  await shh("ADS.sh auto").catch(()=>{});
  await shh("INJECT-ADS.sh").catch(()=>{});
  const h=await sh("node",[path.join(HERE,"lib","harvest-live.js")]);
  log(h.split("\n").filter(x=>x.includes("✔")||x.includes("الإجمالي")).join(" | ").slice(0,400));
  const after=Number(rd(path.join(D,"ledger.json"),{total:0}).total||0);
  const delta=after-before;
  if(delta>0){N.toast("💰 +$"+delta.toFixed(2)+" · الإجمالي $"+after.toFixed(2));N.vibrate(400);
    N.notify({title:"CineHub · أرباح جديدة",content:"+$"+delta.toFixed(2),ongoing:0});
    codes.save("ربح",{زيادة:delta,الإجمالي:after,دورة:S.cycles});}
  // سحب تلقائي عند بلوغ الحد
  const thr=Number(K.get("PAYOUT_THRESHOLD")||"10"),wd=Number(S.lastMoney||0);
  if(after-wd>=thr&&K.get("WALLET_PRIVATE_KEY")){
    const r=await sh("node",[path.join(HERE,"lib","payout-evm.js")]);
    if(/✔ أُرسل/.test(r)){S.lastMoney=after;N.toast("🏦 سُحب $"+thr);N.vibrate(600);}
  }
  await shh("REPORT.sh").catch(()=>{});
  S.money=after;S.at=new Date().toISOString();
  fs.writeFileSync(ST,JSON.stringify(S,null,1));
  paint(delta>0?("💰 +$"+delta.toFixed(2)):"");
}
(async()=>{
  log("بدء الوكيل pid="+process.pid+" كل "+IV+"ث");
  paint("بدأت — أول دورة جارية…");
  N.toast("✔ الوكيل بدأ يعمل باسمك");
  const stop=()=>{log("توقف");N.notify({title:"CineHub · متوقف",content:"أوقفتَ الوكيل — الإجمالي $"+Number(S.money||0).toFixed(2),ongoing:0});N.clear();process.exit(0);};
  process.on("SIGINT",stop);process.on("SIGTERM",stop);
  for(;;){try{await cycle();}catch(e){log("خطأ دورة: "+(e.message||e));S.errors++;fs.writeFileSync(ST,JSON.stringify(S,null,1));}
    await new Promise(r=>setTimeout(r,IV*1000));}
})();
