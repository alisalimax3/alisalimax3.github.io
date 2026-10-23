#!/usr/bin/env node
"use strict";
const https=require("https"),fs=require("fs"),path=require("path"),crypto=require("crypto"),{execFile}=require("child_process");
const HERE=__dirname,ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const KEYS=path.join(ROOT,"keys.env"),ONB=path.join(DATA,"onboard.json"),STF=path.join(DATA,"bot-state.json");
fs.mkdirSync(DATA,{recursive:true});
function loadEnv(){const o={};try{fs.readFileSync(KEYS,"utf8").split(/\r?\n/).forEach(l=>{const m=l.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);if(m)o[m[1]]=m[2].trim();});}catch(e){}return o;}
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>fs.writeFileSync(f,JSON.stringify(o,null,1));
const sources=()=>{let o=[],s={};["sources.json","sources-big.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"].forEach(f=>{try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(x=>{if(x&&x.id&&!s[x.id]){s[x.id]=1;o.push(x);}});}catch(e){}});return o;};
const st=()=>{try{return JSON.parse(fs.readFileSync(path.join(DATA,"keys-status.json"),"utf8"));}catch(e){return{keys:[],summary:{}};}};
const liveIds=()=>new Set((st().keys||[]).filter(k=>k.status==="LIVE").map(k=>k.id));
const env=loadEnv();
function tg(m,p){return new Promise(r=>{if(!env.TELEGRAM_BOT_TOKEN)return r({});const d=JSON.stringify(p);
 const q=https.request({host:"api.telegram.org",path:"/bot"+env.TELEGRAM_BOT_TOKEN+"/"+m,method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{let b="";x.on("data",c=>b+=c);x.on("end",()=>{try{r(JSON.parse(b));}catch(e){r({});}});});
 q.on("error",()=>r({}));q.write(d);q.end();});}
const say=t=>tg("sendMessage",{chat_id:env.TG_CHAT_ID,text:t});
const run=(c,a)=>new Promise(r=>execFile(c,a,{cwd:ROOT},(e,so,se)=>r(String(so||"")+String(se||""))));
const onb=()=>rd(ONB,{done:[],skip:[],current:null});
const nextSite=()=>{const o=onb(),L=sources(),lv=liveIds();return L.find(x=>!o.done.includes(x.id)&&!o.skip.includes(x.id)&&!lv.has(x.id))||null;};
async function statusText(){const L=sources(),lv=liveIds();const led=rd(path.join(DATA,"ledger.json"),{total:0});const tr=rd(path.join(DATA,"treasury.json"),{available_usd:0});
 return "📊 الحالة\nحيّ: "+lv.size+" / "+L.length+"\nناقص: "+(L.length-lv.size)+"\nدفتر: $"+(led.total||0)+"\nقابل للسحب: $"+(tr.available_usd||0);}
async function sendNext(){const x=nextSite();if(!x)return say("✅ أكملت كل المصادر المتاحة!");
 const o=onb();o.current=x.id;wr(ONB,o);
 const stp=(x.steps||[]).map((t,i)=>(i+1)+". "+t).join("\n");
 return say("🎯 التالي: "+x.name+"\n"+(x.note||"")+"\n💰 دفع: "+(x.payout||"-")+"\n\n🔗 "+(x.url==="-"?"لا يحتاج مفتاح":x.url)+"\n\n"+(stp?"الخطوات:\n"+stp+"\n\n":"")+"المفاتيح المطلوبة:\n"+x.env.map(e=>"• "+e).join("\n")+"\n\nأرسل /done بعد الإضافة · /skip للتخطي");}
async function handle(msg){const t=(msg.text||"").trim(),c=msg.chat.id;
 if(env.TG_CHAT_ID&&String(c)!==String(env.TG_CHAT_ID))return;
 if(t==="/start"||t==="/help")return say("🤖 وكيل CineHub\n/next التالي\n/skip تخطي\n/done تم\n/status الحالة\n/check فحص وتفعيل\n/harvest حصد الآن\n/top أعلى دفعًا\n/report تقرير\n/progress تقدمي");
 if(t==="/next")return sendNext();
 if(t==="/skip"){const o=onb();if(o.current&&!o.skip.includes(o.current))o.skip.push(o.current);o.current=null;wr(ONB,o);return sendNext();}
 if(t==="/done"){const o=onb();if(o.current&&!o.done.includes(o.current))o.done.push(o.current);o.current=null;wr(ONB,o);return say("✔ أُنجز")&&sendNext();}
 if(t==="/status")return say(await statusText());
 if(t==="/progress"){const o=onb();return say("منجز: "+o.done.length+" · متخطّى: "+o.skip.length+"\n"+await statusText());}
 if(t==="/check"){await say("⏳ أفحص وأربط...");
  for(const s of ["lib/derive.sh","KEYCHECK.sh","WIRE.sh","HARVEST.sh"])await run("bash",[path.join(HERE,s)]);
  return say("✔ انتهى\n"+await statusText());}
 if(t==="/harvest"){const o=await run("bash",[path.join(HERE,"HARVEST.sh")]);return say("🌾 "+o.slice(-600));}
 if(t==="/report"){await run("bash",[path.join(HERE,"DAILY-REPORT.sh")]);const f=path.join(DATA,"report-"+new Date().toISOString().slice(0,10)+".md");
  return say(fs.existsSync(f)?fs.readFileSync(f,"utf8").slice(0,3500):"لا تقرير بعد");}
 if(t==="/top"){const L=sources().filter(x=>x.payout&&x.payout!=="-");return say("🏆 أعلى دفعًا:\n"+L.slice(0,10).map(x=>"• "+x.name+" — "+x.payout).join("\n"));}
 return say("أمر غير معروف · /help");}
let off=(rd(STF,{}).offset)||0;
async function poll(){if(!env.TELEGRAM_BOT_TOKEN||!env.TG_CHAT_ID)return new Promise(r=>setTimeout(r,5000));
 try{const r=await tg("getUpdates",{offset:off,timeout:20});if(r.result)for(const u of r.result){off=u.update_id+1;wr(STF,{offset:off});if(u.message)await handle(u.message);}}catch(e){}}
const hash=()=>{try{return crypto.createHash("md5").update(fs.readFileSync(KEYS)).digest("hex");}catch(e){return"";}};
let h="",lastLive=0;
async function watch(){const nh=hash();
 if(nh!==h){const first=!h;h=nh;
  if(!first){await say("🔑 تغيّر keys.env — أفحص وأربط وأحصد...");
   for(const s of ["lib/derive.sh","KEYCHECK.sh","WIRE.sh","HARVEST.sh"])await run("bash",[path.join(HERE,s)]);
   const n=liveIds().size;
   await say((n>lastLive?"✅ مصادر حيّة جديدة: +"+(n-lastLive):"⚠ لا تغيير — تحقق من صحة المفتاح")+"\n"+await statusText());
   lastLive=n;await run("bash",[path.join(HERE,"PUSH-GH.sh")]);}}
 await new Promise(r=>setTimeout(r,4000));}
(async()=>{h=hash();lastLive=liveIds().size;
 console.log("agent-bot يعمل");
 if(env.TELEGRAM_BOT_TOKEN&&env.TG_CHAT_ID)await say("🤖 وكيل CineHub جاهز. أرسل /next");
 while(true){await poll();await watch();}})();
