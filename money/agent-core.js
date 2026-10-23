#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path"),crypto=require("crypto"),{execFile}=require("child_process");
const HERE=__dirname,ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const PORT=parseInt(process.env.AGENT_PORT||"8790",10),LOGF=path.join(ROOT,"logs","agent-core.log");
fs.mkdirSync(DATA,{recursive:true});
const S={running:true,paused:false,interval:180,started:Date.now(),done:0,errors:0,last:null};
const LOG=[];
function log(m){const l={t:new Date().toISOString().slice(11,19),m:String(m).slice(0,400)};LOG.push(l);if(LOG.length>400)LOG.shift();try{fs.appendFileSync(LOGF,l.t+" "+l.m+"\n");}catch(e){}}
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>fs.writeFileSync(f,JSON.stringify(o,null,2));
const loadEnv=()=>{const o={};try{fs.readFileSync(path.join(ROOT,"keys.env"),"utf8").split(/\r?\n/).forEach(l=>{const m=l.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);if(m)o[m[1]]=m[2].trim();});}catch(e){}return o;};
const sources=()=>{let o=[],s={};["sources.json","sources-big.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"].forEach(f=>{try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(x=>{if(x&&x.id&&!s[x.id]){s[x.id]=1;o.push(x);}});}catch(e){}});return o;};
const st=()=>{try{return JSON.parse(fs.readFileSync(path.join(DATA,"keys-status.json"),"utf8"));}catch(e){return{keys:[]};}};
const liveIds=()=>new Set((st().keys||[]).filter(k=>k.status==="LIVE").map(k=>k.id));

const TASKS={
 link:["lib/derive.sh","KEYCHECK.sh","WIRE.sh"],
 probe:["KEYCHECK.sh"],
 harvest:["HARVEST.sh"],
 payout:["PAYOUT.sh"],
 publish:["AUTOPOST.sh"],
 sync:["PUSH-GH.sh"],
 report:["DAILY-REPORT.sh"],
 full:["lib/derive.sh","KEYCHECK.sh","WIRE.sh","HARVEST.sh","PAYOUT.sh"]
};
let busy=false;
function runTask(type){return new Promise(res=>{
 const list=TASKS[type]||[];if(!list.length){log("⚠ مهمة مجهولة: "+type);return res(false);}
 busy=true;let i=0;
 const step=()=>{if(i>=list.length){busy=false;S.done++;S.last=type;log("✔ انتهت المهمة: "+type);return res(true);}
  const s=list[i++],f=path.join(HERE,s);
  if(!fs.existsSync(f)){log("⚠ ناقص: "+s);return step();}
  log("▶ "+type+" ← "+s);
  execFile("bash",[f],{cwd:ROOT,timeout:240000,maxBuffer:4e6},(e,so,se)=>{
   const out=(String(so||"")+String(se||"")).trim().split("\n").filter(Boolean).slice(-3).join(" | ");
   if(out)log("   "+out.slice(0,320));
   if(e)S.errors++;
   step();});};
 step();});}

function probeSource(x){return new Promise(res=>{
 const env=loadEnv();
 const UU=x.probe||x.url;if(!UU||UU==="-")return res({id:x.id,code:0,note:"لا يحتاج مفتاح"});
 const missing=x.env.filter(e=>!env[e]);
 let u=UU;x.env.forEach((e,i)=>{u=u.replace("{"+(i===0?"KEY":"KEY"+(i+1))+"}",env[e]||"");});
 log("🔍 فحص مباشر: "+x.name);
 execFile("curl",["-s","-o","/dev/null","-w","%{http_code}","--max-time","15",u],{timeout:25000},(e,so)=>{
  const code=String(so||"0").trim();
  const ok=code==="200";
  if(!ok)S.errors++;
  log((ok?"✔ ":"✗ ")+x.name+" → "+code+(missing.length?" (ناقص: "+missing.join(",")+")":""));
  res({id:x.id,code:code,ok:ok,missing:missing});});});}

let timer=null;
function schedule(){if(timer)clearInterval(timer);
 timer=setInterval(async()=>{if(!S.running||S.paused||busy)return;
  log("⏱ دورة تلقائية: فحص + حصد");
  await runTask("probe");await runTask("harvest");
 },S.interval*1000);}

let h="";
setInterval(()=>{let n="";try{n=crypto.createHash("md5").update(fs.readFileSync(path.join(ROOT,"keys.env"))).digest("hex");}catch(e){}
 if(n&&n!==h){const first=!h;h=n;if(!first){log("🔑 تغيّر keys.env → ربط تلقائي");runTask("link");}}},4000);

const MIME={".html":"text/html; charset=utf-8",".json":"application/json"};
const UI=()=>{try{return fs.readFileSync(path.join(HERE,"agent-ui.html"),"utf8");}catch(e){return"<h1>agent-ui.html ناقص</h1>";}};
http.createServer(async(req,res)=>{
 const u=new URL(req.url,"http://x"),p=u.pathname;
 const J=(o,c)=>{res.writeHead(c||200,{"content-type":"application/json; charset=utf-8","access-control-allow-origin":"*","cache-control":"no-store"});res.end(JSON.stringify(o));};
 if(p==="/"||p==="/agent.html")return res.writeHead(200,{"content-type":MIME[".html"],"cache-control":"no-store"}),res.end(UI());
 if(p==="/api/agent/status"){const L=sources(),lv=liveIds(),led=rd(path.join(DATA,"ledger.json"),{total:0}),tr=rd(path.join(DATA,"treasury.json"),{available_usd:0});
  return J({running:S.running,paused:S.paused,interval:S.interval,uptime:Math.round((Date.now()-S.started)/1000),done:S.done,errors:S.errors,last:S.last,busy:busy,
   live:lv.size,total:L.length,ledger:led.total||0,available:tr.available_usd||0,bot:fs.existsSync(path.join(DATA,"agentbot.pid"))});}
 if(p==="/api/agent/log")return J(LOG.slice(-120));
 if(p==="/api/agent/sources"){const lv=liveIds(),env=loadEnv();
  return J(sources().map(x=>({id:x.id,name:x.name,cat:x.cat,url:x.url,payout:x.payout,note:x.note,env:x.env,steps:x.steps||[],
   live:lv.has(x.id),has:x.env.every(e=>env[e])})));}
 if(p==="/api/agent/probe"){const x=sources().find(s=>s.id===u.searchParams.get("id"));if(!x)return J({ok:false},404);return J(await probeSource(x));}
 if(p==="/api/agent/task"&&req.method==="POST"){let b="";req.on("data",c=>b+=c);req.on("end",async()=>{try{const d=JSON.parse(b||"{}");
   if(d.type==="probeAll"){const L=sources();log("🔍 فحص الكل ("+L.length+")");let ok=0;for(const x of L){const r=await probeSource(x);if(r.ok)ok++;}
    log("انتهى الفحص — ناجح: "+ok);return J({ok:true,ok});}
   runTask(d.type);J({ok:true,type:d.type});}catch(e){J({ok:false},400);}});return;}
 if(p==="/api/agent/control"&&req.method==="POST"){let b="";req.on("data",c=>b+=c);req.on("end",()=>{try{const d=JSON.parse(b||"{}");
   if(d.action==="start")S.running=true;if(d.action==="pause")S.paused=true;if(d.action==="resume")S.paused=false;
   if(d.action==="stop")S.running=false;if(d.interval)S.interval=Math.max(30,parseInt(d.interval,10));
   log("⚙ تحكم: "+(d.action||"interval")+(d.interval?" "+d.interval+"s":""));schedule();J({ok:true});}catch(e){J({ok:false},400);}});return;}
 if(p==="/api/agent/setkey"&&req.method==="POST"){let b="";req.on("data",c=>b+=c);req.on("end",()=>{try{const d=JSON.parse(b||"{}");
   if(!d.k||!/^[A-Za-z_][A-Za-z0-9_]*$/.test(d.k))return J({ok:false},400);
   const K=path.join(ROOT,"keys.env");let t="";try{t=fs.readFileSync(K,"utf8");}catch(e){}
   const re=new RegExp("^"+d.k+"=.*$","m");t=re.test(t)?t.replace(re,d.k+"="+String(d.v||"")):(t&&!t.endsWith("\n")?t+"\n":"")+d.k+"="+String(d.v||"")+"\n";
   var tmp=K+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,K);try{fs.chmodSync(K,0o600);}catch(e){}log("🔑 حُفظ "+d.k);J({ok:true});}catch(e){J({ok:false},400);}});return;}
 J({ok:false},404);
}).listen(PORT,()=>{log("🤖 الوكيل يعمل على "+PORT);schedule();});
