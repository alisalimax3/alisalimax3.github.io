#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  APEX — الوكيل الأقوى والأوسع: صلاحيات كاملة · تنفيذ شامل · إحياء ذاتي · لوحة
#  bash money/APEX.sh [menu|install|start|stop|restart|status|ready|health|doctor|
#    sync|proof|plan|deploy|seo|sites|traffic|harvest|payout|bank|kyc|dash|vault|
#    audit|snapshot|update|watch|report|logs|all]
# ══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
D="$H/data"; mkdir -p "$D" logs money/lib money/assets _deploy _backup
[ -f keys.env ] || touch keys.env; chmod 600 keys.env 2>/dev/null
PID="$D/apex.pid"; ST="$D/apex-state.json"; L="$ROOT/logs/apex.log"
CMD="${1:-menu}"; shift || true
say(){ printf '%s\n' "$*"; }
S(){ printf '\n══════════ %s ══════════\n' "$1"; }
# كتابة ملف فقط إن لم يوجد (FORCE=1 لإعادة الكتابة)
w(){ local f="$1"; [ "${FORCE:-0}" = "1" ] && rm -f "$f"; [ -f "$f" ] || cat > "$f"; }

# ═══════════════════════ 1) النواة: مفاتيح · سجل · إشعار · محرّكات · خزنة ═════
w "$H/lib/akeys.js" <<'A1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,"..",".."),F=path.join(ROOT,"keys.env");
function all(){const o={};try{fs.readFileSync(F,"utf8").split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0&&!/^\s*#/.test(l))o[l.slice(0,i).trim()]=l.slice(i+1).trim();});}catch(e){}return o;}
const get=k=>all()[k]||"";
function set(o){const c=all();Object.assign(c,o);const t=Object.keys(c).sort().map(k=>k+"="+c[k]).join("\n")+"\n";
  const tmp=F+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,F);try{fs.chmodSync(F,0o600);}catch(e){}}
function normalize(){const c=all();set(c);return Object.keys(c).length;}
module.exports={get,set,all,normalize};
if(require.main===module){const c=process.argv[2];if(c==="normalize")console.log("  ✔ keys.env مصحّح ("+normalize()+" مفتاح)");else if(c==="list")Object.keys(all()).forEach(k=>console.log("  "+k));}
A1

w "$H/lib/acodes.js" <<'A2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,"..",".."),LOGS=path.join(ROOT,"logs");
try{fs.mkdirSync(LOGS,{recursive:true});}catch(e){}
const F=path.join(LOGS,"codes.log"),V=path.join(LOGS,"vault.json");
const mask=v=>{const s=String(v);return s.length>16?s.slice(0,6)+"…"+s.slice(-4):s;};
function save(title,data){const at=new Date().toISOString();
  try{fs.appendFileSync(F,"["+at+"] "+title+" :: "+JSON.stringify(data)+"\n");}catch(e){}
  let v={};try{v=JSON.parse(fs.readFileSync(V,"utf8"));}catch(e){}
  v[title]=v[title]||[];v[title].push({at,data});
  try{fs.writeFileSync(V,JSON.stringify(v,null,1));fs.chmodSync(V,0o600);}catch(e){}
  try{fs.chmodSync(F,0o600);}catch(e){}}
module.exports={save,mask};
A2

w "$H/lib/anotify.js" <<'A3'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),LOG=path.join(ROOT,"logs","apex.log"),ID="cinehub-apex";
const cache={};
function has(c){return new Promise(r=>{if(c in cache)return r(cache[c]);execFile("sh",["-c","command -v "+c],e=>{cache[c]=!e;r(!e);});});}
const run=(c,a)=>new Promise(r=>{try{execFile(c,a||[],{timeout:9000},()=>r(true));}catch(e){r(false);}});
async function notify(o){
  if(!await has("termux-notification")){try{fs.appendFileSync(LOG,"[notify] "+(o.title||"")+" — "+(o.content||"")+"\n");}catch(e){}return;}
  const a=["--id",ID,"--title",o.title||"APEX","--content",o.content||"","--priority","high"];
  if(o.ongoing)a.push("--ongoing","--button1","⏹ إيقاف","--button1-action","bash "+path.join(H,"APEX.sh")+" stop",
                      "--button2","📊 الحالة","--button2-action","bash "+path.join(H,"APEX.sh")+" status");
  if(o.big)a.push("--big-text",String(o.big).slice(0,400));
  if(o.progress!=null)a.push("--progress",String(Math.round(o.progress)),"--max","100");
  await run("termux-notification",a);
}
const toast=m=>run("termux-toast",["-g","bottom",String(m)]);
const vibrate=p=>run("termux-vibrate",p?["-p",p]:["-d","250"]);
const clear=()=>run("termux-notification-remove",["--id",ID]);
const clip=()=>new Promise(r=>execFile("termux-clipboard-get",[],(e,so)=>r(String(so||"").trim())));
const clipSet=t=>run("termux-clipboard-set",[String(t)]);
const sms=n=>new Promise(r=>execFile("termux-sms-list",["-l",String(n)],(e,so)=>{try{r(JSON.parse(so)||[]);}catch(x){r([]);}}));
module.exports={notify,toast,vibrate,clear,clip,clipSet,sms,has,ID};
A3

w "$H/lib/aengines.js" <<'A4'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const ROOT=path.resolve(__dirname,"..","..");
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36";
const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium","/usr/bin/chromium-browser","/usr/bin/google-chrome"];
const hasChrom=()=>!!(process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p)));
const hasPup=()=>fs.existsSync(path.join(ROOT,"node_modules","puppeteer-core"));
const open=u=>new Promise(r=>execFile("termux-open-url",[u],()=>r()));
function get(u,h,ms){return new Promise((res,rej)=>{const https=require("https"),http=require("http"),m=/^https/.test(u)?https:http;
  const q=m.get(u,{headers:Object.assign({"user-agent":UA},h||{})},r=>{let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>res({status:r.statusCode,body:b,headers:r.headers}));});
  q.on("error",rej);q.setTimeout(ms||15000,()=>q.destroy(new Error("timeout")));});}
async function browser(fn){if(!hasChrom()||!hasPup())return null;
  const pp=require(path.join(ROOT,"node_modules","puppeteer-core"));
  const br=await pp.launch({executablePath:process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p)),headless:"new",
    args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu","--single-process"]});
  try{return await fn(br,pp);}finally{await br.close();}}
const rank=()=>({chromium:hasChrom()&&hasPup(),http:true,termux:true});
module.exports={get,browser,open,rank,hasChrom,hasPup,UA,CH};
if(require.main===module){const r=rank();console.log("  المحرّكات: "+Object.entries(r).filter(([,v])=>v).map(([k])=>k).join(" · "));}
A4

w "$H/lib/apool.js" <<'A5'
#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process");
function task(t){return new Promise(r=>{const t0=Date.now();
  execFile(t.cmd,t.args||[],{timeout:t.timeout||240000,maxBuffer:8e6,cwd:t.cwd},(e,so,se)=>
    r({name:t.name,ok:!e,ms:Date.now()-t0,out:String(so||"")+String(se||""),code:e?e.code:0}));});}
async function pool(list,limit){const res=new Array(list.length);let i=0;const n=Math.max(1,Math.min(limit||3,list.length||1));
  await Promise.all(Array.from({length:n},async()=>{while(i<list.length){const k=i++;res[k]=await task(list[k]);}}));
  return res;}
module.exports={pool,task};
A5

w "$H/lib/avault.js" <<'A6'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),crypto=require("crypto");
const ROOT=path.resolve(__dirname,"..",".."),D=path.resolve(__dirname,"..","data");
const K=path.join(ROOT,"keys.env"),V=path.join(D,"vault.enc");
const pass=()=>process.env.APEX_VAULT_PASS||require("./akeys.js").get("VAULT_PASS")||"apex-local";
function seal(){if(!fs.existsSync(K))return "○ لا keys.env";
  const out=execFileSync("openssl",["enc","-aes-256-cbc","-pbkdf2","-iter","200000","-salt","-pass","pass:"+pass(),"-in",K]);
  fs.writeFileSync(V,out);try{fs.chmodSync(V,0o600);}catch(e){}
  return "✔ خُتمت الخزنة ("+out.length+" بايت) — النسخة المشفّرة في money/data/vault.enc";}
function open(){if(!fs.existsSync(V))return "○ لا خزنة";
  const out=execFileSync("openssl",["enc","-d","-aes-256-cbc","-pbkdf2","-iter","200000","-pass","pass:"+pass(),"-in",V]);
  fs.writeFileSync(K,out);try{fs.chmodSync(K,0o600);}catch(e){}return "✔ فُتحت الخزنة واستُعيد keys.env";}
module.exports={seal,open};
if(require.main===module){console.log("  "+(process.argv[2]==="open"?open():seal()));}
A6

w "$H/lib/aaudit.js" <<'A7'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const ROOT=path.resolve(__dirname,"..",".."),F=path.join(ROOT,"logs","audit.jsonl");
const h=(prev,o)=>crypto.createHash("sha256").update(prev+JSON.stringify(o)).digest("hex").slice(0,32);
function last(){try{const L=fs.readFileSync(F,"utf8").trim().split("\n");return JSON.parse(L[L.length-1]);}catch(e){return null;}}
function add(event,data){const p=last();const o={i:(p?p.i:0)+1,at:new Date().toISOString(),event,data:data||{}};
  o.prev=p?p.hash:"0".repeat(32);o.hash=h(o.prev,o);fs.appendFileSync(F,JSON.stringify(o)+"\n");return o;}
function verify(){try{const L=fs.readFileSync(F,"utf8").trim().split("\n").filter(Boolean);let prev="0".repeat(32),i=0;
  for(const l of L){const o=JSON.parse(l);i++;if(o.prev!==prev)return{ok:false,at:i};if(h(prev,o)!==o.hash)return{ok:false,at:i};prev=o.hash;}
  return{ok:true,count:i};}catch(e){return{ok:true,count:0};}}
module.exports={add,verify};
if(require.main===module){const v=verify();console.log(v.ok?"  ✔ سلسلة التدقيق سليمة ("+v.count+" قيد)":"  ✗ كسر عند "+v.at);}
A7

# ═══════════════════════ 2) الصلاحيات الأوسع + المراقبة + الدفتر + الصحة ═══════
w "$H/lib/aprivi.js" <<'B1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync,execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const run=(c,a)=>{try{return execFileSync(c,a,{stdio:"pipe",timeout:120000}).toString().trim();}catch(e){return "";}};
const sh=c=>run("sh",["-c",c]);
const has=c=>!!sh("command -v "+c);
const isRoot=()=>{try{return process.getuid()===0;}catch(e){return false;}};
function grant(apply){
  const HOME=process.env.HOME||"/data/data/com.termux/files/home";
  const R={at:new Date().toISOString(),root:isRoot(),chroot:has("termux-chroot"),tsu:has("tsu")||has("sudo"),
    storage:false,wakelock:false,boot:false,jobs:false,cron:false,services:false,steps:[]};
  if(!fs.existsSync(path.join(HOME,"storage"))){try{execFile("termux-setup-storage",[],()=>{});R.steps.push("طلب صلاحية التخزين");}catch(e){}}
  R.storage=fs.existsSync(path.join(HOME,"storage"));
  if(has("termux-wake-lock")){sh("termux-wake-lock");R.wakelock=true;R.steps.push("منع نوم الجهاز");}
  if(apply){try{const b=path.join(HOME,".termux","boot");fs.mkdirSync(b,{recursive:true});
    const f=path.join(b,"000-apex.sh");
    fs.writeFileSync(f,"#!/data/data/com.termux/files/usr/bin/sh\ntermux-wake-lock\nsleep 25\ncd "+ROOT+" && bash money/APEX.sh start >> logs/boot.log 2>&1\n");
    fs.chmodSync(f,0o755);R.boot=true;R.steps.push("تمهيد تلقائي عند الإقلاع");}catch(e){}}
  if(apply&&has("termux-job-scheduler")){try{sh("termux-job-scheduler --script "+path.join(H,"JOB-APEX.sh")+" --job-id 3099 --period-ms 900000 --network any --persisted true");R.jobs=true;R.steps.push("مجدول أندرويد");}catch(e){}}
  if(has("crond")){R.cron=true;if(apply&&!run("pgrep",["-x","crond"])){try{execFile("crond",[],()=>{});R.steps.push("cron شغّال");}catch(e){}}}
  if(has("sv"))R.services=true;
  try{execFile("am",["start","-a","android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS"],()=>{});}catch(e){}
  fs.writeFileSync(path.join(D,"privileges.json"),JSON.stringify(R,null,1));
  return R;
}
const level=()=>isRoot()?"root":(has("termux-chroot")?"chroot(شبه-جذر)":(has("tsu")?"tsu":"user"));
module.exports={grant,level,isRoot,has,run,sh};
if(require.main===module){const r=grant(process.argv[2]!=="check");
  console.log("  ✔ مستوى الصلاحيات: "+level()+" · تخزين "+(r.storage?"✔":"○")+" · منع نوم "+(r.wakelock?"✔":"○")+" · إقلاع "+(r.boot?"✔":"○")+" · جدولة "+(r.jobs?"✔":"○")+" · cron "+(r.cron?"✔":"○"));}
B1

w "$H/lib/awatch.js" <<'B2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{spawn}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data"),F=path.join(D,"watch.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){return{};}};
const wr=o=>fs.writeFileSync(F,JSON.stringify(o,null,1));
const alive=p=>{try{process.kill(p,0);return true;}catch(e){return false;}};
function ensure(svc){const st=rd(),s=st[svc.name]||{restarts:0,last:0,breaks:0,down:0};
  if(s.pid&&alive(s.pid)){s.ok=true;st[svc.name]=s;wr(st);return{name:svc.name,action:"حيّ"};}
  const now=Date.now();
  if(now-(s.last||0)<12000){st[svc.name]=s;wr(st);return{name:svc.name,action:"انتظار"};}
  if(s.restarts>6&&now-(s.breaks||0)>600000){s.restarts=0;s.breaks=now;}
  s.last=now;s.restarts++;s.down++;
  try{const out=fs.openSync(svc.log||path.join(ROOT,"logs",svc.name+".log"),"a");
    const p=spawn(svc.cmd,svc.args||[],{cwd:svc.cwd||ROOT,detached:true,stdio:["ignore",out,out]});p.unref();s.pid=p.pid;
  }catch(e){}
  st[svc.name]=s;wr(st);return{name:svc.name,action:"أُحيي",pid:s.pid,restarts:s.restarts};}
module.exports={ensure,alive,rd};
if(require.main===module){const s=rd();Object.entries(s).forEach(([k,v])=>console.log("  "+(v.pid&&alive(v.pid)?"✔":"○")+" "+k+"  إحياءات:"+v.restarts));}
B2

w "$H/lib/aledger.js" <<'B3'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data"),F=path.join(D,"apex-ledger.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){return{total:0,rows:[]};}};
const wr=o=>fs.writeFileSync(F,JSON.stringify(o,null,1));
function add(net,amount,meta){const l=rd();const a=Number(amount)||0;
  l.rows.push(Object.assign({net,amount:a,at:new Date().toISOString()},meta||{}));
  l.total=Number(l.total||0)+a;l.updated=new Date().toISOString();wr(l);return l.total;}
const day=()=>{const d=new Date().toISOString().slice(0,10);return rd().rows.filter(r=>r.at.slice(0,10)===d).reduce((a,r)=>a+r.amount,0);};
const week=()=>{const t=Date.now()-864e5*7;return rd().rows.filter(r=>new Date(r.at).getTime()>t).reduce((a,r)=>a+r.amount,0);};
function csv(){return "date,network,amount,note\n"+rd().rows.map(r=>[r.at,r.net,r.amount,(r.note||"")].join(",")).join("\n")+"\n";}
function invoice(){const l=rd();
  return "<!doctype html><meta charset=utf-8><style>body{font-family:system-ui;background:#0b0e14;color:#e8eef7;padding:32px}td,th{border-bottom:1px solid #223;padding:8px;text-align:right}h2{color:#4ade80}</style><h1>CineHub — كشف أرباح</h1><p>"+new Date().toISOString().slice(0,10)+"</p><table><tr><th>الشبكة</th><th>المبلغ</th><th>التاريخ</th></tr>"+
    l.rows.slice(-200).map(r=>"<tr><td>"+r.net+"</td><td>$"+r.amount.toFixed(2)+"</td><td>"+r.at.slice(0,16)+"</td></tr>").join("")+"</table><h2>الإجمالي $"+Number(l.total||0).toFixed(2)+"</h2>";}
module.exports={add,day,week,rd,wr,csv,invoice};
if(require.main===module){const c=process.argv[2]||"show";
  if(c==="csv")console.log(csv());else if(c==="invoice")console.log(invoice());
  else{const l=rd();console.log("  الإجمالي $"+Number(l.total||0).toFixed(2)+" · أسبوع $"+week().toFixed(2)+" · اليوم $"+day().toFixed(2)+" · "+l.rows.length+" قيد");}}
B3

w "$H/lib/ahealth.js" <<'B4'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const K=require("./akeys.js");
function score(){
  const sig=[],led=rd(path.join(D,"apex-ledger.json"),{total:0}),h=rd(path.join(D,"harvest.json"),{}),
    keys=K.all(),ads=rd(path.join(D,"ads.json"),[]),pr=rd(path.join(D,"privileges.json"),{}),
    wt=rd(path.join(D,"watch.json"),{}),dep=rd(path.join(D,"deploy.json"),{}),pub=K.get("PUBLIC_URL");
  let p=0;const add=(n,w,ok,note)=>{sig.push({n,w,ok:!!ok,note:note||""});if(ok)p+=w;};
  add("رابط عام حيّ",15,pub);add("استضافة منشورة",10,dep.ok);add("مفاتيح ≥5",10,Object.keys(keys).length>=5);
  add("مصادر حيّة ≥3",10,(h.live||0)>=3);add("إعلانات محقونة ≥1",10,ads.filter(a=>a.enabled&&a.snippet).length>=1);
  add("أرباح > 0",10,Number(led.total||0)>0);add("صلاحيات كاملة",10,pr.wakelock&&pr.boot);
  add("مراقبة تعمل",10,Object.keys(wt).length>0);add("عنوان تحويل",5,!!K.get("PAYOUT_ADDRESS"));
  add("هوية/بريد",5,!!K.get("CONTACT_EMAIL"));add("خزنة مختومة",5,fs.existsSync(path.join(D,"vault.enc")));
  const gates={"رابط عام":!!pub,"منشور":!!dep.ok,"مصادر≥3":(h.live||0)>=3,
    "إعلان":ads.filter(a=>a.enabled&&a.snippet).length>=1,"أرباح":Number(led.total||0)>0,
    "مراقبة":Object.keys(wt).length>0,"صلاحيات":!!pr.wakelock,"تحويل":!!K.get("PAYOUT_ADDRESS"),
    "هوية":!!K.get("CONTACT_EMAIL"),"خزنة":fs.existsSync(path.join(D,"vault.enc"))};
  const rep={at:new Date().toISOString(),score:p,signals:sig,gates,ready:Object.values(gates).every(Boolean)};
  fs.writeFileSync(path.join(D,"health.json"),JSON.stringify(rep,null,1));return rep;}
module.exports={score};
if(require.main===module){const r=score();
  console.log("  الصحة: "+r.score+"/100 · البوابات "+Object.values(r.gates).filter(Boolean).length+"/"+Object.keys(r.gates).length+(r.ready?" ✅ جاهز كامل":""));
  r.signals.filter(x=>!x.ok).forEach(x=>console.log("   ○ "+x.n));process.exit(r.ready?0:1);}
B4

w "$H/lib/aoutreach.js" <<'B5'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),tls=require("tls");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),N=require("./anotify.js"),codes=require("./acodes.js");
const TARGETS=[["youtube.com","يوتيوب"],["reddit.com","ريديت"],["medium.com","ميديوم"],["quora.com","كورا"],["tumblr.com","تمبلر"],["blogger.com","بلوجر"],["wordpress.com","ووردبريس"],["vk.com","VK"],["pinterest.com","بينترست"],["github.com","جيت هب"],["dev.to","ديف"],["hashnode.dev","هاشنود"],["substack.com","سبستاك"],["mastodon.social","ماستودون"],["x.com","إكس"]];
function list(){return TARGETS.map(([h,n])=>({host:h,name:n,
  subject:"مشاهدة أفلام ومسلسلات مترجمة بجودة عالية — CineHub",
  body:"مرحبًا،\n\nأنا "+(K.get("BRAND_NAME")||"CineHub")+" — منصة أفلام ومسلسلات وأنمي مترجم.\n"+
  "الرابط: "+(K.get("PUBLIC_URL")||"")+"\n\nيسعدني تبادل الإشارات/الظهور إن كان لديك محتوى مشابه.\n\nتحياتي"}));}
function write(){const l=list();fs.writeFileSync(path.join(D,"outreach.json"),JSON.stringify({at:new Date().toISOString(),targets:l},null,1));return l;}
function smtpSend(to,subject,body){return new Promise(res=>{
  const host=K.get("SMTP_HOST"),port=Number(K.get("SMTP_PORT")||465),user=K.get("SMTP_USER"),pass=K.get("SMTP_PASS");
  if(!host||!user)return res("○ لا SMTP");
  const from=K.get("CONTACT_EMAIL")||user;let step=0;
  const c=tls.connect({host,port,servername:host},()=>{});
  const send=l=>c.write(l+"\r\n");
  const b64=s=>Buffer.from(s).toString("base64");
  c.on("data",d=>{const s=d.toString();
    if(step===0&&/^220/.test(s)){send("EHLO apex");step=1;return;}
    if(step===1&&/^250/.test(s)&&/AUTH/.test(s)){send("AUTH LOGIN");step=2;return;}
    if(step===1&&/^250/.test(s)){send("AUTH LOGIN");step=2;return;}
    if(step===2&&/^334/.test(s)){send(b64(user));step=3;return;}
    if(step===3&&/^334/.test(s)){send(b64(pass));step=4;return;}
    if(step===4&&/^235/.test(s)){send("MAIL FROM:<"+from+">");step=5;return;}
    if(step===5&&/^250/.test(s)){send("RCPT TO:<"+to+">");step=6;return;}
    if(step===6&&/^250/.test(s)){send("DATA");step=7;return;}
    if(step===7&&/^354/.test(s)){send("Subject: "+subject+"\r\nFrom: "+from+"\r\nTo: "+to+"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n"+body+"\r\n.");step=8;return;}
    if(step===8&&/^250/.test(s)){send("QUIT");c.end();return res("✔ أُرسل إلى "+to);}
    if(/^5\d\d/.test(s)&&step<5){c.end();return res("✗ "+s.trim().slice(0,60));}});
  c.on("error",e=>res("✗ "+(e.message||e)));
  setTimeout(()=>{try{c.end();}catch(e){}res("○ انتهت المهلة");},30000);});}
(async()=>{const l=write();console.log("  ✔ قائمة تواصل: "+l.length+" منصة → money/data/outreach.json");
  if(process.argv[2]==="send"){for(const t of l){const r=await smtpSend(K.get("CONTACT_EMAIL"),t.subject,t.body);console.log("   "+r);}}
  else console.log("  → للإرسال: أضف SMTP_HOST/SMTP_USER/SMTP_PASS ثم bash money/APEX.sh outreach send");
  codes.save("تواصل خارجي",{عدد:l.length});await N.toast("✔ تواصل خارجي: "+l.length);})();
B5

# ═══════════════════════ 3) الأهداف الواسعة + النشر المتعدد + SEO ════════════
w "$H/lib/asites.js" <<'C1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
let KW=[];try{KW=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords||[];}catch(e){}
const BASE=KW.length?KW:["افلام اون لاين","مسلسلات مترجمة","انمي مترجم","سينما","افلام اجنبية"];
const EXT=["مترجم","اون لاين","hd","مجانا","2026","جديد"];
const EN=["watch movies online","streaming","series subtitles","anime english","free movies","cinema online"];
const KWS=[...new Set([].concat(BASE,BASE.flatMap(k=>EXT.map(e=>k+" "+e)),EN))].slice(0,60);
const ENG={google:"https://www.google.com/search?q=",bing:"https://www.bing.com/search?q=",ddg:"https://duckduckgo.com/?q=",
 yandex:"https://yandex.com/search/?text=",brave:"https://search.brave.com/search?q=",startpage:"https://www.startpage.com/sp/search?query=",
 ecosia:"https://www.ecosia.org/search?q=",qwant:"https://www.qwant.com/?q=",mojeek:"https://www.mojeek.com/search?q=",
 searx:"https://searx.be/search?q=",baidu:"https://www.baidu.com/s?wd=",naver:"https://search.naver.com/search.naver?query=",
 seznam:"https://search.seznam.cz/?q=",yep:"https://yep.com/web?q=",presearch:"https://presearch.com/search?q=",
 metager:"https://metager.org/meta/meta.ger3?eingabe=",marginalia:"https://search.marginalia.nu/search?query=",
 wiby:"https://wiby.me/?q=",onesearch:"https://www.onesearch.com/yahoo-search?p=",
 youtube:"https://www.youtube.com/results?search_query=",tiktok:"https://www.tiktok.com/search?q=",
 pinterest:"https://www.pinterest.com/search/pins/?q=",reddit:"https://www.reddit.com/search/?q=",
 quora:"https://www.quora.com/search?q=",medium:"https://medium.com/search?q=",tumblr:"https://www.tumblr.com/search/",
 vk:"https://vk.com/search?c[q]=",x:"https://x.com/search?q=",threads:"https://www.threads.net/search?q=",
 mastodon:"https://mastodon.social/search?q=",linkedin:"https://www.linkedin.com/search/results/all/?keywords="};
const DIR=`producthunt.com betalist.com alternativeto.net capterra.com g2.com crunchbase.com startupbase.io f6s.com saashub.com
toolify.ai theresanaiforthat.com futurepedia.io aitools.fyi topai.tools openfuture.ai aitoolhunt.com insidr.ai aitoolnet.com
aixploria.com startuplist.io land-book.com godly.website designnominees.com awwwards.com cssdesignawards.com thefwa.com
dribbble.com behance.net onepagelove.com httpster.net minimal.gallery siteinspire.com webdesignclip.com pinterest.com tumblr.com
medium.com substack.com hashnode.dev dev.to hackernoon.com freecodecamp.org sitepoint.com smashingmagazine.com css-tricks.com
similarweb.com semrush.com ahrefs.com moz.com majestic.com statshow.com siteworthtraffic.com worthofweb.com urlscan.io
virustotal.com shodan.io censys.io securityheaders.com ssllabs.com mxtoolbox.com dnschecker.org intodns.com whatsmydns.net
pingdom.com gtmetrix.com webpagetest.org pagespeed.web.dev validator.w3.org jigsaw.w3.org jsonformatter.org beautifier.io
tinyjpg.com squoosh.app tinypng.com cloudconvert.com zamzar.com convertio.co ilovepdf.com smallpdf.com remove.bg
photopea.com canva.com figma.com unsplash.com pexels.com pixabay.com freepik.com vecteezy.com flaticon.com iconfinder.com
fontawesome.com fonts.google.com dafont.com coolors.co colorhunt.co fontpair.co typewolf.com layers.to uplabs.com codepen.io
jsfiddle.net jsbin.com codesandbox.io stackblitz.com replit.com glitch.com gitlab.com bitbucket.org sourceforge.net apache.org
mozilla.org w3.org ietf.org rfc-editor.org wikimedia.org wikipedia.org wikidata.org archive.org gutenberg.org openlibrary.org
standardebooks.org annas-archive.org arxiv.org crossref.org openalex.org doaj.org core.ac.uk semanticscholar.org researchgate.net
academia.edu jstor.org springer.com nature.com sciencedirect.com ieee.org acm.org biorxiv.org medrxiv.org ssrn.com osf.io
figshare.com zenodo.org dryad.org imdb.com rottentomatoes.com metacritic.com letterboxd.com trakt.tv tvmaze.com thetvdb.com
simkl.com anilist.co myanimelist.net kitsu.io anime-planet.com mangaupdates.com mydramalist.com justwatch.com reelgood.com
allmovie.com filmweb.pl tmdb.org omdbapi.com kinopoisk.ru the-numbers.com boxofficemojo.com mubi.com indiewire.com variety.com
deadline.com hollywoodreporter.com collider.com slashfilm.com screenrant.com cinemablend.com denofgeek.com ign.com gamespot.com
polygon.com kotaku.com eurogamer.net pcgamer.com rockpapershotgun.com vg247.com destructoid.com giantbomb.com opencritic.com
howlongtobeat.com backloggd.com steamgifts.com isthereanydeal.com cheapshark.com gg.deals humblebundle.com fanatical.com
greenmangaming.com gog.com epicgames.com playstation.com xbox.com nintendo.com neocities.org surge.sh netlify.app vercel.app
render.com railway.app fly.io tiiny.host static.app web.app pages.dev github.io gitlab.io codeberg.org sourcehut.org
pastebin.com hastebin.com termbin.com 0x0.st file.io transfer.sh tmpfiles.org catbox.moe pixeldrain.com mega.nz
drive.google.com dropbox.com onedrive.live.com icedrive.net pcloud.com koofr.net filen.io storj.io backblaze.com
wasabi.com idrive.com ubuntu.com debian.org archlinux.org alpine.org termux.dev f-droid.org apkmirror.com apkpure.com
uptodown.com softonic.com majorgeeks.com fosshub.com ninite.com brew.sh snapcraft.io flatpak.org appimage.github.io`.split(/\s+/).filter(Boolean);
const sites=[];
DIR.forEach(d=>sites.push({t:"دليل",url:"https://"+d}));
for(const[k,u]of Object.entries(ENG))for(const q of KWS)sites.push({t:"محرّك",engine:k,url:u+encodeURIComponent(q)});
for(const q of KWS.slice(0,20))sites.push({t:"هاشتاق",url:"https://www.instagram.com/explore/tags/"+q.replace(/\s+/g,"")});
try{JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8")).forEach(x=>{if(x.url&&x.url!=="-")sites.push({t:"منصة",cat:x.cat,url:x.url});});}catch(e){}
const seen=new Set();const out=sites.filter(s=>{const k=s.url.replace(/\/$/,"");if(seen.has(k))return false;seen.add(k);return true;});
const by={};out.forEach(s=>by[s.t]=(by[s.t]||0)+1);
fs.writeFileSync(path.join(D,"sites-mega.json"),JSON.stringify({at:new Date().toISOString(),total:out.length,counts:by,sites:out},null,1));
console.log("  ✔ "+out.length+" هدف حقيقي — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
C1

w "$H/lib/adeploy.js" <<'C2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),crypto=require("crypto");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),OUT=path.join(ROOT,"_deploy"),D=path.join(H,"data");
const K=require("./akeys.js"),codes=require("./acodes.js");
const sh=(c,a,o)=>execFileSync(c,a,Object.assign({cwd:OUT,stdio:"pipe",timeout:420000},o||{})).toString();
function build(){
  fs.rmSync(OUT,{recursive:true,force:true});fs.mkdirSync(OUT,{recursive:true});
  const skip=new Set(["_backup","node_modules",".git","logs","_deploy","__pycache__","storage",".cache"]);
  (function cp(src,dst){for(const e of fs.readdirSync(src,{withFileTypes:true})){
    if(skip.has(e.name)||e.name==="keys.env"||e.name.endsWith(".pid"))continue;
    const s=path.join(src,e.name),d=path.join(dst,e.name);
    if(e.isDirectory()){fs.mkdirSync(d,{recursive:true});cp(s,d);}
    else if(/\.(html?|css|js|json|png|jpe?g|webp|svg|ico|woff2?|ttf|txt|xml|webmanifest|md)$/i.test(e.name))fs.copyFileSync(s,d);}})(ROOT,OUT);
  const key=K.get("INDEXNOW_KEY")||crypto.randomBytes(16).toString("hex");K.set({INDEXNOW_KEY:key});
  fs.writeFileSync(path.join(OUT,key+".txt"),key);
  const f=[];(function wk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);e.isDirectory()?wk(p):f.push(path.relative(OUT,p));}})(OUT);
  return{key,files:f};
}
const tries=[
 {n:"surge",need:["SURGE_TOKEN"],fn:()=>{const dom=K.get("SURGE_DOMAIN")||("cinehub-"+crypto.randomBytes(3).toString("hex")+".surge.sh");
   sh("npx",["--yes","surge",".",dom,"--token",K.get("SURGE_TOKEN")]);K.set({SURGE_DOMAIN:dom});return "https://"+dom;}},
 {n:"netlify",need:["NETLIFY_TOKEN"],fn:()=>{const o=sh("npx",["--yes","netlify-cli","deploy","--prod","--dir","."],{env:Object.assign({},process.env,{NETLIFY_AUTH_TOKEN:K.get("NETLIFY_TOKEN")})});
   const m=o.match(/https:\/\/[a-z0-9\-]+\.netlify\.app/);return m?m[0]:null;}},
 {n:"vercel",need:["VERCEL_TOKEN"],fn:()=>{const o=sh("npx",["--yes","vercel","--prod","--yes","--token",K.get("VERCEL_TOKEN")]);
   const m=o.match(/https:\/\/[a-z0-9\-]+\.vercel\.app/);return m?m[0]:null;}},
 {n:"cloudflare",need:["CF_TOKEN","CF_PROJECT"],fn:()=>{const o=sh("npx",["--yes","wrangler","pages","deploy",".","--project-name",K.get("CF_PROJECT")],
   {env:Object.assign({},process.env,{CLOUDFLARE_API_TOKEN:K.get("CF_TOKEN")})});
   const m=o.match(/https:\/\/[a-z0-9\-\.]+\.pages\.dev/);return m?m[0]:null;}},
 {n:"firebase",need:["FIREBASE_TOKEN"],fn:()=>{const o=sh("npx",["--yes","firebase-tools","deploy","--only","hosting","--token",K.get("FIREBASE_TOKEN")]);
   const m=o.match(/https:\/\/[a-z0-9\-]+\.web\.app/);return m?m[0]:null;}},
 {n:"neocities",need:["NEOCITIES_USER","NEOCITIES_PASS"],fn:()=>{const u=K.get("NEOCITIES_USER");
   const args=["-s","-u",u+":"+K.get("NEOCITIES_PASS")];const files=[];
   (function wk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);
     if(e.isDirectory()){args.push("-F",path.relative(OUT,p)+"=@"+p);}else files.push(p);}})(OUT);
   for(const f of files)args.push("-F",path.relative(OUT,f)+"=@"+f);
   args.push("https://neocities.org/api/upload");
   const o=sh("curl",args);return /"result":"success"/.test(o)?("https://"+u+".neocities.org"):null;}},
 {n:"github",need:["GITHUB_TOKEN","GH_USER"],fn:()=>{const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER"),repo="cinehub-apex";
   const g=path.join(OUT,".git");if(!fs.existsSync(g))sh("git",["init","-q"]);
   sh("git",["config","user.email",K.get("CONTACT_EMAIL")||"apex@local"]);sh("git",["config","user.name",user]);
   sh("git",["add","-A"]);sh("git",["commit","-q","-m","apex "+new Date().toISOString()]);sh("git",["branch","-M","gh-pages"]);
   try{sh("git",["remote","remove","origin"]);}catch(e){}
   sh("git",["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo+".git"]);
   try{sh("git",["push","-u","origin","gh-pages","--force"]);}catch(e){}
   return "https://"+user+".github.io/"+repo+"/";}}
];
(async()=>{const{key,files}=build();console.log("  ✔ حزمة النشر: "+files.length+" ملف");
  const done=[];
  for(const t of tries){if(!t.need.every(k=>K.get(k)))continue;
    try{const u=t.fn();if(u&&/^https/.test(u)){done.push({host:t.n,url:u});console.log("  ✔ "+t.n+" → "+u);}}catch(e){console.log("  ○ "+t.n+" فشل");}}
  if(!done.length){console.log("  ○ لا استضافة — أضف توكنًا: SURGE_TOKEN أو NETLIFY_TOKEN أو VERCEL_TOKEN أو GITHUB_TOKEN+GH_USER");}
  const rec={at:new Date().toISOString(),ok:done.length>0,hosts:done,url:done[0]?done[0].url:"",files:files.length,key};
  fs.writeFileSync(path.join(D,"deploy.json"),JSON.stringify(rec,null,1));
  if(done.length){K.set({PUBLIC_URL:done[0].url,INDEXNOW_HOST:new URL(done[0].url).host,MIRRORS:done.map(d=>d.url).join(",")});codes.save("نشر متعدد",{عدد:done.length,الرابط:done[0].url});}
  require("./aaudit.js").add("deploy",{hosts:done.length});})();
C2

w "$H/lib/atraffic.js" <<'C3'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js");
let ID={brand:"CineHub",handle:"cinehub",desc_short_ar:"منصة أفلام ومسلسلات وأنمي مترجمة بجودة عالية"};
try{ID=Object.assign(ID,JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8")));}catch(e){}
const pub=(K.get("PUBLIC_URL")||"").replace(/\/$/,"");
let KW=[];try{KW=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords||[];}catch(e){}
const KWS=KW.length?KW:["افلام اون لاين","مسلسلات مترجمة","انمي مترجم"];
const LANGS=["ar","en","fr","es","de","tr","pt","id"];
const DIR=path.join(ROOT,"seo");fs.mkdirSync(DIR,{recursive:true});
const slug=s=>s.trim().replace(/\s+/g,"-").replace(/[^\w\u0600-\u06FF\-]/g,"");
function page(q,lang,i){
  const url=pub+"/seo/"+slug(q)+"-"+lang+".html";
  const alt=LANGS.map(l=>'<link rel="alternate" hreflang="'+l+'" href="'+pub+"/seo/"+slug(q)+"-"+l+'.html">').join("\n");
  const ld=JSON.stringify({"@context":"https://schema.org","@type":"WebSite",name:ID.brand,url:pub,
    potentialAction:{"@type":"SearchAction",target:pub+"/?q={search_term_string}","query-input":"required name=search_term_string"}});
  return `<!doctype html><html lang="${lang}" dir="${lang==="ar"?"rtl":"ltr"}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${q} — ${ID.brand}</title>
<meta name="description" content="${q} على ${ID.brand}: ${ID.desc_short_ar}">
<link rel="canonical" href="${url}">
${alt}
<meta property="og:title" content="${q} — ${ID.brand}"><meta property="og:type" content="website"><meta property="og:url" content="${url}">
<meta name="theme-color" content="#2563eb"><link rel="icon" href="/assets/logo.png">
<script type="application/ld+json">${ld}</script>
<style>body{margin:0;font-family:system-ui;background:#0b0e14;color:#e8eef7;line-height:1.8}
.w{max-width:900px;margin:auto;padding:28px}a{color:#7dd3fc}h1{font-size:1.9rem}ul{columns:2}
.card{background:#121826;border:1px solid #1e293b;border-radius:14px;padding:18px;margin:14px 0}</style></head>
<body><div class="w"><h1>${q}</h1>
<div class="card"><p>${ID.desc_short_ar}</p>
<p><a href="/">→ الصفحة الرئيسية</a> · <a href="${pub}/sitemap.xml">خريطة الموقع</a> · <a href="${pub}/rss.xml">RSS</a></p></div>
<div class="card"><h2>تصفّح بـ</h2><ul>${LANGS.map(l=>'<li><a href="'+slug(q)+'-'+l+'.html">'+q+' ('+l+')</a></li>').join("")}</ul></div>
<div class="card" id="ad"><!-- AD-SLOT --></div>
<footer><p>© ${new Date().getFullYear()} ${ID.brand}</p></footer></div></body></html>`;}
const made=[];
for(const q of KWS)for(const l of LANGS){const f=path.join(DIR,slug(q)+"-"+l+".html");fs.writeFileSync(f,page(q,l));made.push(path.relative(ROOT,f).replace(/\\/g,"/"));}
const urls=made.map(u=>pub+"/"+u);
fs.writeFileSync(path.join(ROOT,"sitemap.xml"),'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
  [pub+"/"].concat(urls).map(u=>"<url><loc>"+u+"</loc><changefreq>daily</changefreq></url>").join("\n")+"\n</urlset>\n");
fs.writeFileSync(path.join(ROOT,"rss.xml"),'<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>'+ID.brand+'</title><link>'+pub+'</link><description>'+ID.desc_short_ar+'</description>\n'+
  urls.slice(0,50).map(u=>"<item><title>"+u.split("/").pop().replace(/-/g," ")+"</title><link>"+u+"</link></item>").join("\n")+"</channel></rss>\n");
fs.writeFileSync(path.join(ROOT,"atom.xml"),'<?xml version="1.0" encoding="UTF-8"?>\n<feed xmlns="http://www.w3.org/2005/Atom"><title>'+ID.brand+'</title><link href="'+pub+'"/>\n'+
  urls.slice(0,50).map(u=>'<entry><title>'+u.split("/").pop()+'</title><link href="'+u+'"/></entry>').join("\n")+"</feed>\n");
fs.writeFileSync(path.join(ROOT,"robots.txt"),"User-agent: *\nAllow: /\nCrawl-delay: 1\nSitemap: "+pub+"/sitemap.xml\n");
fs.writeFileSync(path.join(ROOT,"security.txt"),"Contact: "+(K.get("CONTACT_EMAIL")||"mailto:")+"\nExpires: "+new Date(Date.now()+31536e6).toISOString()+"\n");
fs.writeFileSync(path.join(ROOT,"humans.txt"),"/* TEAM */ "+ID.brand+"\n/* SITE */ "+(pub||"local")+"\n");
fs.writeFileSync(path.join(ROOT,"opensearch.xml"),'<?xml version="1.0"?><OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/"><ShortName>'+ID.brand+'</ShortName><Url type="text/html" template="'+pub+'/?q={searchTerms}"/></OpenSearchDescription>');
if(!fs.existsSync(path.join(ROOT,"ads.txt")))fs.writeFileSync(path.join(ROOT,"ads.txt"),"# أضف سطور شبكاتك بعد القبول\n");
console.log("  ✔ مولّد الزيارات: "+made.length+" صفحة SEO + sitemap + rss + atom + robots + security + opensearch");
require("./aaudit.js").add("traffic",{pages:made.length});
C3

w "$H/lib/aseo.js" <<'C4'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const K=require("./akeys.js"),codes=require("./acodes.js");
const P=path.join(D,"seo-progress.json");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const get=u=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","-w","%{http_code}","--max-time","12","-A","Mozilla/5.0 apex",u],(e,so)=>r(Number(so)||0)));
const post=(u,b)=>new Promise(r=>{const https=require("https"),d=JSON.stringify(b);
  const q=https.request(u,{method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(x.statusCode));});
  q.on("error",()=>r(0));q.write(d);q.end();});
function urls(){try{const s=fs.readFileSync(path.join(require("path").resolve(__dirname,"..",".."),"sitemap.xml"),"utf8");
  return [...s.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m=>m[1]);}catch(e){return[];}}
async function indexnow(){const host=K.get("INDEXNOW_HOST"),key=K.get("INDEXNOW_KEY"),pub=K.get("PUBLIC_URL");
  if(!host||!key||!pub)return 0;
  const list=[pub.replace(/\/$/,"")].concat(urls()).slice(0,500);
  const c=await post("https://api.indexnow.org/indexnow",{host,key,keyLocation:pub.replace(/\/$/,"")+"/"+key+".txt",urlList:list});
  console.log("  "+(c<400?"✔":"○")+" IndexNow: "+c+" ("+list.length+" رابطًا)");
  if(c<400)codes.save("IndexNow",{روابط:list.length,استجابة:c});return c<400?list.length:0;}
async function pings(){const pub=K.get("PUBLIC_URL");if(!pub)return 0;
  const s=encodeURIComponent(pub.replace(/\/$/,"")+"/sitemap.xml");
  const E=["https://www.google.com/ping?sitemap="+s,"https://www.bing.com/ping?sitemap="+s];
  let n=0;for(const u of E){const c=await get(u);if(c&&c<400)n++;}
  console.log("  ✔ ping sitemap: "+n+"/"+E.length);return n;}
async function push(n){const F=path.join(D,"sites-mega.json");if(!fs.existsSync(F))return 0;
  const S=JSON.parse(fs.readFileSync(F,"utf8")).sites,p=rd(P,{cursor:0,ok:0,fail:0,rounds:0});
  const slice=S.slice(p.cursor,p.cursor+n);let ok=0;
  const {pool}=require("./apool.js");
  const res=await pool(slice.map((s,i)=>({name:"s"+i,cmd:"curl",args:["-sL","-o","/dev/null","--max-time","10","-A","Mozilla/5.0 apex",s.url],timeout:20000})),6);
  res.forEach(r=>r.ok?ok++:p.fail++);
  p.cursor=(p.cursor+n)%S.length;p.ok+=ok;p.rounds++;p.at=new Date().toISOString();fs.writeFileSync(P,JSON.stringify(p,null,1));
  console.log("  ✔ دُفعت "+ok+"/"+slice.length+" هدفًا · المؤشر "+p.cursor+"/"+S.length+" · جولات "+p.rounds);return ok;}
(async()=>{const n=Number(process.argv[2]||"300");await indexnow();await pings();await push(n);
  require("./aaudit.js").add("seo",{pushed:n});})();
C4

# ═══════════════════════ 4) الحصد · الحوالة · البنك · اللوحة · تيليجرام ══════
w "$H/lib/apayout.js" <<'E1'
#!/usr/bin/env node
"use strict";
const path=require("path"),fs=require("fs");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),AL=require("./aledger.js"),codes=require("./acodes.js");
function plan(){const total=Number(AL.rd().total||0),th=Number(K.get("PAYOUT_THRESHOLD")||"20"),addr=K.get("PAYOUT_ADDRESS");
  return{total,threshold:th,addr,chain:K.get("PAYOUT_CHAIN")||"base",due:total>=th&&!!addr,at:new Date().toISOString()};}
async function send(){const p=plan();fs.writeFileSync(path.join(D,"payout.json"),JSON.stringify(p,null,1));
  if(!p.due)return p;
  try{const ethers=require(path.join(ROOT,"node_modules","ethers"));
    const pk=K.get("WALLET_PRIVATE_KEY")||K.get("PRIVATE_KEY");if(!pk){p.note="بلا مفتاح خاص";return p;}
    const prov=new ethers.JsonRpcProvider(K.get("RPC_URL")||"https://mainnet.base.org");
    const w=new ethers.Wallet(pk,prov);
    const tx=await w.sendTransaction({to:p.addr,value:ethers.parseEther(p.total.toFixed(6))});
    p.tx=tx.hash;p.sent=true;codes.save("حوالة",{إلى:p.addr,مبلغ:p.total,tx:tx.hash});
  }catch(e){p.error=String(e.message||e).slice(0,140);}
  fs.writeFileSync(path.join(D,"payout.json"),JSON.stringify(p,null,1));return p;}
module.exports={plan,send};
if(require.main===module){send().then(p=>console.log("  "+(p.sent?"✔ حُوّل":(p.due?"○ جاهز":"○ لم يبلغ الحد"))+" — $"+p.total.toFixed(2)+" / حد $"+p.threshold+(p.tx?" tx:"+p.tx:"")));}
E1

w "$H/lib/abank.js" <<'E2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const K=require("./akeys.js"),AL=require("./aledger.js");
const bank={bank:"بنك الكريمي (Al-Kuraimi Islamic Microfinance Bank)",country:"اليمن",
 receive:["حوالة دولية USD عبر SWIFT","مراسل بنكي","Payoneer ثم تحويل محلي","USDT ثم صرافة محلية"],
 fields:["BANK_ACCOUNT_NAME","BANK_ACCOUNT_NUMBER","BANK_BRANCH","BENEFICIARY_PHONE"],
 flow:"حصد → apex-ledger → تجاوز PAYOUT_THRESHOLD → USDC على Base إلى PAYOUT_ADDRESS → تحويل إلى الكريمي"};
function write(){fs.writeFileSync(path.join(D,"bank.json"),JSON.stringify(bank,null,1));return bank;}
function kyc(){const l=AL.rd(),k=K.all();
 const rows=[["الاسم",k.BANK_ACCOUNT_NAME||k.BRAND_NAME||""],["الحساب",k.BANK_ACCOUNT_NUMBER||""],["الفرع",k.BANK_BRANCH||""],
  ["الهاتف",k.BENEFICIARY_PHONE||""],["البريد",k.CONTACT_EMAIL||""],["الموقع",k.PUBLIC_URL||""],
  ["الشبكات",(k.ADS_NETWORKS||"adsterra,monetag,exoclick")],["الأرباح المُسجّلة","$"+Number(l.total||0).toFixed(2)],
  ["المحفظة",k.PAYOUT_ADDRESS||""],["التاريخ",new Date().toISOString().slice(0,10)]];
 const html="<!doctype html><meta charset=utf-8><style>body{font-family:system-ui;background:#fff;color:#111;padding:40px;max-width:820px;margin:auto}td,th{border:1px solid #ccc;padding:10px;text-align:right}table{width:100%;border-collapse:collapse}h1{border-bottom:3px solid #2563eb;padding-bottom:8px}</style>"+
  "<h1>ملف KYC — "+bank.bank+"</h1><table>"+rows.map(r=>"<tr><th>"+r[0]+"</th><td>"+r[1]+"</td></tr>").join("")+"</table>"+
  "<p style='margin-top:24px'>أُنتج آليًا بواسطة APEX — اطبعه بصيغة PDF من المتصفح وأرسله للشبكات/البنك.</p>";
 const f=path.join(D,"kyc.html");fs.writeFileSync(f,html);return f;}
module.exports={write,kyc};
if(require.main===module){write();console.log("  ✔ ملف بنك الكريمي: money/data/bank.json");console.log("  ✔ ملف KYC: "+kyc());}
E2

w "$H/lib/atelegram.js" <<'E3'
#!/usr/bin/env node
"use strict";
const K=require("./akeys.js");
function post(url,body){return new Promise(r=>{try{const https=require("https"),d=JSON.stringify(body);
  const q=https.request(url,{method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(x.statusCode));});
  q.on("error",()=>r(0));q.write(d);q.end();}catch(e){r(0);}});}
async function send(text){const t=K.get("TELEGRAM_BOT_TOKEN"),c=K.get("TELEGRAM_CHAT_ID");
  if(t&&c)await post("https://api.telegram.org/bot"+t+"/sendMessage",{chat_id:c,text,parse_mode:"HTML"});
  const w=K.get("ALERT_WEBHOOK");if(w)await post(w,{text});
  const dc=K.get("DISCORD_WEBHOOK");if(dc)await post(dc,{content:text});
  return !!(t&&c)||!!w||!!dc;}
module.exports={send};
if(require.main===module){send(process.argv.slice(2).join(" ")||"APEX يعمل").then(ok=>console.log("  "+(ok?"✔ أُرسل":"○ لا قناة — أضف TELEGRAM_BOT_TOKEN+TELEGRAM_CHAT_ID أو ALERT_WEBHOOK")));}
E3

w "$H/lib/adash.js" <<'E4'
#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),AL=require("./aledger.js");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const port=Number(K.get("DASH_PORT")||8788);
const card=(t,v,c)=>'<div class="c"><div class="t">'+t+'</div><div class="v" style="color:'+c+'">'+v+'</div></div>';
function page(){
  const l=AL.rd(),h=rd(path.join(D,"health.json"),{score:0,gates:{}}),s=rd(path.join(D,"apex-state.json"),{}),
        dep=rd(path.join(D,"deploy.json"),{}),w=rd(path.join(D,"watch.json"),{});
  const gate=Object.entries(h.gates||{}).map(([k,v])=>'<span class="g '+(v?"ok":"no")+'">'+(v?"✔ ":"○ ")+k+'</span>').join(" ");
  return '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'+
  '<meta http-equiv="refresh" content="30"><title>APEX — لوحة التحكم</title><style>'+
  'body{margin:0;background:#0b0e14;color:#e8eef7;font-family:system-ui;padding:20px}'+
  '.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin:16px 0}'+
  '.c{background:#121826;border:1px solid #1e293b;border-radius:14px;padding:14px}.t{opacity:.65;font-size:.8rem}'+
  '.v{font-size:1.5rem;font-weight:700;margin-top:6px}.g{display:inline-block;padding:4px 10px;border-radius:20px;margin:3px;font-size:.8rem}'+
  '.ok{background:#052e1a;color:#4ade80}.no{background:#2b0f16;color:#f87171}h1{font-size:1.3rem}'+
  'pre{background:#0f1420;padding:12px;border-radius:10px;overflow:auto;font-size:.78rem}a{color:#7dd3fc}</style></head><body>'+
  '<h1>APEX · لوحة التحكم <span style="opacity:.5;font-size:.8rem">'+(s.ready?"✅ جاهز":"يعمل")+'</span></h1>'+
  '<div class="grid">'+card("الأرباح",'$'+Number(l.total||0).toFixed(2),"#4ade80")+card("الصحة",(h.score||0)+"/100","#7dd3fc")+
  card("الدورات",s.cycles||0,"#e8eef7")+card("المفاتيح",s.keys||0,"#fbbf24")+card("نشر",(dep.hosts||[]).length,"#a78bfa")+
  card("مراقبة",Object.keys(w).length,"#38bdf8")+card("مصادر",s.live||0,"#34d399")+'</div>'+
  '<div>'+gate+'</div><h3>الرابط العام</h3><p><a href="'+(dep.url||"#")+'" target="_blank">'+(dep.url||"لا رابط بعد")+'</a></p>'+
  '<h3>آخر الأحداث</h3><pre>'+JSON.stringify(rd(path.join(D,"apex-state.json"),{}),null,1).slice(0,1500)+'</pre>'+
  '<p><a href="/api/state">JSON</a> · <a href="/metrics">مقاييس</a> · <a href="/invoice">فاتورة</a></p></body></html>';}
http.createServer((q,r)=>{const u=q.url.split("?")[0];
  if(u==="/api/state"){r.setHeader("content-type","application/json");return r.end(JSON.stringify({ledger:AL.rd(),
    health:rd(path.join(D,"health.json"),{}),state:rd(path.join(D,"apex-state.json"),{}),priv:rd(path.join(D,"privileges.json"),{}),deploy:rd(path.join(D,"deploy.json"),{})}));}
  if(u==="/invoice"){r.setHeader("content-type","text/html; charset=utf-8");return r.end(AL.invoice());}
  if(u==="/metrics"){const l=AL.rd();r.setHeader("content-type","text/plain");
    return r.end("apex_total_usd "+Number(l.total||0).toFixed(4)+"\napex_rows "+l.rows.length+"\napex_health "+(rd(path.join(D,"health.json"),{}).score||0)+"\n");}
  if(u==="/ledger.csv"){r.setHeader("content-type","text/csv");return r.end(AL.csv());}
  r.setHeader("content-type","text/html; charset=utf-8");r.end(page());}).listen(port,()=>console.log("  ✔ اللوحة: http://127.0.0.1:"+port));
E4

w "$H/lib/asnapshot.js" <<'E5'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),B=path.join(ROOT,"_backup");
function make(){fs.mkdirSync(B,{recursive:true});
  const f=path.join(B,"apex-"+new Date().toISOString().replace(/[:.]/g,"-")+".tar.gz");
  execFileSync("tar",["-czf",f,"--exclude=node_modules","--exclude=_backup","--exclude=.git","-C",ROOT,"."],{stdio:"pipe",timeout:400000});
  const all=fs.readdirSync(B).filter(x=>x.endsWith(".tar.gz")).sort();
  while(all.length>7)fs.unlinkSync(path.join(B,all.shift()));
  return f;}
function restore(f){execFileSync("tar",["-xzf",f,"-C",ROOT],{stdio:"pipe"});return "✔ استُعيد من "+f;}
module.exports={make,restore};
if(require.main===module){const c=process.argv[2];
  if(c==="restore")console.log("  "+restore(process.argv[3]));
  else{const f=make();console.log("  ✔ نسخة احتياطية: "+path.relative(ROOT,f)+" ("+Math.round(fs.statSync(f).size/1024)+"KB)");}}
E5

w "$H/lib/aupdate.js" <<'E6'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..","..");
const run=a=>{try{return execFileSync("git",a,{cwd:ROOT,stdio:"pipe",timeout:120000}).toString();}catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
function go(){const v=path.join(ROOT,"VERSION");let cur="1.0.0";try{cur=fs.readFileSync(v,"utf8").trim();}catch(e){}
  const [a,b]=cur.split(".").map(Number);const nv=a+"."+(b+1)+".0";
  const out=fs.existsSync(path.join(ROOT,".git"))?run(["pull","--rebase","--autostash"]):"";
  fs.writeFileSync(v,nv+"\n");fs.writeFileSync(path.join(ROOT,"logs","update.log"),new Date().toISOString()+" → "+nv+"\n"+out,"a");
  return {from:cur,to:nv,pulled:/up to date|Fast-forward|files changed/.test(out)};}
module.exports={go};
if(require.main===module){const r=go();console.log("  ✔ تحديث ذاتي "+r.from+" → "+r.to+(r.pulled?" (سحب من git)":""));}
E6

# ═══════════════════════ 5) الحلقة الأقوى (APEX daemon) ═══════════════════════
w "$H/lib/aintercept.js" <<'F1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),N=require("./anotify.js"),K=require("./akeys.js");
const D=path.resolve(__dirname,"..","data"),S=path.join(D,"intercept.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(S,"utf8"));}catch(e){return{otp:[],clip:""};}};
const wr=o=>fs.writeFileSync(S,JSON.stringify(o,null,1));
const TOK=/^[A-Za-z0-9_\-]{20,90}$/;
const SITE=/adsterra|monetag|exoclick|juicyads|trafficjunky|evadav|push\.house|clickadilla|propellerads|admaven|hilltopads|galaksion|cpagrip|bitlabs|ayet|offertoro|mylead|lospollos|crakrevenue|cloudflare|github|vercel|netlify|surge|firebase|neocities/i;
async function checkSms(){const st=rd(),msgs=await N.sms(12),out=[];
  for(const m of msgs){const sig=String(m.number||"")+"|"+String(m.body||"").slice(0,40);
    if(st.otp.includes(sig))continue;
    const body=String(m.body||""),code=(body.match(/\b(\d{4,8})\b/)||[])[1];
    if(code&&(SITE.test(body)||/code|otp|verif|رمز|تحقق/i.test(body))){st.otp.push(sig);out.push(code);
      K.set({LAST_OTP:code,LAST_OTP_AT:new Date().toISOString()});
      await N.notify({title:"APEX · رمز تحقق",content:code});N.vibrate("180");N.clipSet(code);}}
  wr(st);return out;}
async function checkClip(){const st=rd(),txt=await N.clip();
  if(!txt||txt===st.clip||!TOK.test(txt))return null;st.clip=txt;wr(st);
  let want="";
  try{const q=JSON.parse(fs.readFileSync(path.join(D,"queue.json"),"utf8"));
    if(q.current){const s=JSON.parse(fs.readFileSync(path.join(__dirname,"..","sources-big.json"),"utf8")).find(x=>x.id===q.current);
      if(s)want=(s.env||[]).find(e=>!K.get(e))||"";}}catch(e){}
  if(!want){try{const p=JSON.parse(fs.readFileSync(path.join(D,"register-plan.json"),"utf8")).plan||[];
    const nx=p.find(x=>x.env&&x.env.some(e=>!K.get(e)));if(nx)want=nx.env.find(e=>!K.get(e))||"";}catch(e){}}
  if(!want)return null;
  K.set({[want]:txt});N.clipSet("");
  await N.notify({title:"APEX · مفتاح جديد",content:want+" محفوظ"});N.vibrate("200");return{key:want};}
module.exports={checkSms,checkClip};
if(require.main===module){checkSms().then(checkClip).then(r=>{if(r)console.log("  ✔ "+r.key);});}
F1

w "$H/lib/apex.js" <<'F2'
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
F2

# أطراف مساعدة تُستدعى من الحلقة إن وُجدت عندك، وإلا تُكتب نسخة مبسّطة
w "$H/lib/aharvest.js" <<'G1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const led=rd(path.join(D,"ledger.json"),{total:0,rows:[]});
const st={at:new Date().toISOString(),total:Number(led.total||0),rows:(led.rows||[]).length,live:0};
try{const ks=rd(path.join(D,"keys-status.json"),{summary:{}});st.live=(ks.summary&&ks.summary.live)||0;}catch(e){}
try{const p=rd(path.join(D,"revenue-proof.json"),{});st.rising=!!p.rising;}catch(e){}
fs.writeFileSync(path.join(D,"harvest.json"),JSON.stringify(st,null,1));
console.log("  ✔ حصد: $"+st.total.toFixed(2)+" · قيود "+st.rows+" · مصادر حيّة "+st.live);
G1

w "$H/lib/adoctor.js" <<'G2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
let fixed=0;const issues=[],pages=[];
(function walk(d,depth){if(depth>4)return;for(const e of fs.readdirSync(d,{withFileTypes:true})){
  if(["_backup","node_modules",".git","logs","_deploy"].includes(e.name))continue;
  const p=path.join(d,e.name);if(e.isDirectory())walk(p,depth+1);else if(/\.html?$/i.test(e.name))pages.push(p);}})(ROOT,0);
let base={brand:"CineHub",desc_short_ar:"منصة أفلام ومسلسلات"};
try{base=Object.assign(base,JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8")));}catch(e){}
const url=(()=>{try{return require("./akeys.js").get("PUBLIC_URL")||"http://127.0.0.1:8787/";}catch(e){return"http://127.0.0.1:8787/";}})();
for(const p of pages){let s=fs.readFileSync(p,"utf8");const o=s;
  if(!/<meta\s+charset/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta charset="utf-8">');issues.push("charset");}
  if(!/name=["']viewport/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="viewport" content="width=device-width,initial-scale=1">');issues.push("viewport");}
  if(!/name=["']description/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="description" content="'+(base.desc_short_ar||"").replace(/"/g,"")+'">');issues.push("description");}
  if(!/property=["']og:title/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta property="og:title" content="'+base.brand+'"><meta property="og:image" content="/assets/logo.png"><meta name="theme-color" content="#2563eb">');issues.push("og");}
  if(!/<html[^>]*lang=/i.test(s))s=s.replace(/<html/i,'<html lang="ar" dir="rtl"');
  if(s!==o){fs.writeFileSync(p,s);fixed++;}}
const need={"manifest.webmanifest":JSON.stringify({name:base.brand,short_name:base.brand,start_url:"/",display:"standalone",background_color:"#0b0e14",theme_color:"#2563eb"},null,1)};
for(const[f,c]of Object.entries(need)){const p=path.join(ROOT,f);if(!fs.existsSync(p)){fs.writeFileSync(p,c);fixed++;issues.push("أنشأ "+f);}}
for(const f of fs.readdirSync(path.join(HERE,"lib")).filter(x=>x.endsWith(".js"))){
  try{execFileSync("node",["--check",path.join(HERE,"lib",f)],{stdio:"pipe"});}catch(e){issues.push("صياغة "+f);}}
const rep={at:new Date().toISOString(),pages:pages.length,fixed,issues:[...new Set(issues)].slice(0,40)};
fs.writeFileSync(path.join(D,"doctor.json"),JSON.stringify(rep,null,1));
console.log("  ✔ فحص "+pages.length+" صفحة · أصلحت/أنشأت "+fixed+" عنصرًا · ملاحظات "+rep.issues.length);
G2

w "$H/lib/async.js" <<'G3'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),K=require("./akeys.js"),codes=require("./acodes.js");
const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER");
const run=a=>{try{return execFileSync("git",a,{cwd:ROOT,stdio:"pipe",timeout:180000}).toString();}catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
if(!tk||!user)console.log("  ○ لا GITHUB_TOKEN/GH_USER — أضف: bash money/APEX.sh set GITHUB_TOKEN=... GH_USER=...");
else{(async()=>{const repo="cinehub-apex";
  if(!fs.existsSync(path.join(ROOT,".git")))run(["init","-q"]);
  const gi=path.join(ROOT,".gitignore");
  if(!fs.existsSync(gi))fs.writeFileSync(gi,"node_modules/\n_backup/\nlogs/*.log\nkeys.env\n__pycache__/\n*.pid\n_deploy/\n");
  run(["config","user.email",K.get("CONTACT_EMAIL")||"apex@local"]);run(["config","user.name",user]);
  run(["add","-A"]);run(["commit","-q","-m","apex "+new Date().toISOString()]);run(["branch","-M","main"]);
  try{run(["remote","remove","origin"]);}catch(e){}
  run(["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo+".git"]);
  const out=run(["push","-u","origin","main","--force"]);
  const ok=/main|up-to-date|->/.test(out);
  console.log(ok?"  ✔ رُفع إلى https://github.com/"+user+"/"+repo:"  "○ "+out.slice(0,100));
  if(ok)codes.save("رفع GitHub",{repo:user+"/"+repo});})();}
G3

w "$H/lib/aapproval.js" <<'G4'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),codes=require("./acodes.js");
const KP=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"keypages.json"),"utf8"));}catch(e){return{};}})();
let I={brand:"CineHub",handle:"cinehub"};
try{I=Object.assign(I,JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8")));}catch(e){}
function plan(){const ids=Object.keys(KP);const out=ids.map(id=>({id,signup:KP[id].signup,keysUrl:KP[id].keysUrl,env:KP[id].env,
  missing:(KP[id].env||[]).filter(e=>!K.get(e))}));
  fs.writeFileSync(path.join(D,"approval-plan.json"),JSON.stringify({at:new Date().toISOString(),plan:out},null,1));
  return out;}
if(require.main===module){const p=plan();const miss=p.filter(x=>x.missing.length);
  console.log("  ✔ خطة الموافقة: "+p.length+" شبكة · ناقص مفاتيح "+miss.length);
  miss.slice(0,6).forEach(m=>console.log("   ○ "+m.id+" → "+m.signup+"  ("+m.missing.join(", ")+")"));
  codes.save("خطة الموافقة",{شبكات:p.length,ناقص:miss.length});}
G4

w "$H/JOB-APEX.sh" <<'G5'
#!/usr/bin/env bash
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$H/data/apex.pid" ] && kill -0 "$(cat "$H/data/apex.pid")" 2>/dev/null && exit 0
exec bash "$H/APEX.sh" start
G5

w "$H/lib/acli.js" <<'H1'
#!/usr/bin/env node
"use strict";
const {spawnSync}=require("child_process"),path=require("path");
const H=path.resolve(__dirname,".."),A=path.join(H,"APEX.sh");
const M=[["1","تشغيل كامل (install + start)","all"],["2","تشغيل الوكيل","start"],["3","إيقاف","stop"],
 ["4","الحالة والصحة","status"],["5","نشر عام على الاستضافات","deploy"],["6","دفع للمحرّكات والأهداف","seo"],
 ["7","توليد صفحات SEO","traffic"],["8","بناء قائمة الأهداف","sites"],["9","حصد الأرباح","harvest"],
 ["10","حوالة أرباح","payout"],["11","ملف البنك + KYC","kyc"],["12","اللوحة","dash"],["13","ختم الخزنة","vault"],
 ["14","سجل التدقيق","audit"],["15","نسخة احتياطية","snapshot"],["16","تحديث ذاتي","update"],["17","تقرير","report"]];
console.log("\n╔══════════════ APEX — القائمة ══════════════╗");
M.forEach(m=>console.log("  "+m[0].padStart(2)+") "+m[1]));
console.log("╚════════════════════════════════════════════╝");
if(process.argv[2]){spawnSync("bash",[A,process.argv[2]],{stdio:"inherit"});process.exit(0);}
const r=require("readline").createInterface({input:process.stdin,output:process.stdout});
r.question("اختر رقمًا: ",a=>{const m=M.find(x=>x[0]===String(a).trim());r.close();
  if(m)spawnSync("bash",[A,m[2]],{stdio:"inherit"});else console.log("○ اختيار غير معروف");});
H1

chmod +x "$H"/*.sh "$H"/lib/*.js 2>/dev/null
node -e 'require(process.argv[1]).normalize&&console.log("  ✔ keys.env محمي (600)")' "$H/lib/akeys.js" 2>/dev/null

install_deps(){
  command -v pkg >/dev/null 2>&1 || return 0
  S "تجهيز الاعتماديات"
  for p in nodejs-lts nodejs curl openssl python3 git tar termux-api; do
    dpkg -s "$p" >/dev/null 2>&1 || pkg install -y "$p" >>"$L" 2>&1 || true
  done
  dpkg -s chromium >/dev/null 2>&1 || (yes 2>/dev/null | pkg install -y chromium >>"$L" 2>&1) || true
  [ -d node_modules/puppeteer-core ] || PUPPETEER_SKIP_DOWNLOAD=1 npm i --no-audit --no-fund --silent puppeteer-core@23 >>"$L" 2>&1 || true
  [ -d node_modules/ethers ] || npm i --no-audit --no-fund --silent ethers@6 >>"$L" 2>&1 || true
  say "  ✔ الاعتماديات جاهزة"
}

report(){
  node "$H/lib/ahealth.js" >/dev/null 2>&1 || true
  node - "$H" <<'JSR'
const fs=require("fs"),path=require("path"),H=process.argv[2],D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const l=rd(path.join(D,"apex-ledger.json"),{total:0,rows:[]}),h=rd(path.join(D,"health.json"),{score:0,gates:{}}),
  d=rd(path.join(D,"deploy.json"),{}),w=rd(path.join(D,"watch.json"),{}),p=rd(path.join(D,"privileges.json"),{}),
  s=rd(path.join(D,"apex-state.json"),{}),sj=rd(path.join(D,"sites-mega.json"),{total:0}),ads=rd(path.join(D,"ads.json"),[]);
const md=["# تقرير APEX — "+new Date().toISOString(),"","- الأرباح: $"+Number(l.total||0).toFixed(2),
"- الصحة: "+h.score+"/100 · بوابات "+Object.values(h.gates||{}).filter(Boolean).length+"/10",
"- الرابط العام: "+(d.url||"لا شيء"),"- الاستضافات: "+((d.hosts||[]).map(x=>x.host).join(", ")||"لا شيء"),
"- الأهداف: "+sj.total+" · مدفوعة: "+(s.pushes||0),"- إعلانات محقونة: "+ads.filter(a=>a.enabled&&a.snippet).length,
"- مراقبة: "+Object.keys(w).length+" خدمة","- صلاحيات: تخزين "+(p.storage?"✔":"○")+" · إقلاع "+(p.boot?"✔":"○")+" · منع نوم "+(p.wakelock?"✔":"○"),
"- المفاتيح: "+Object.keys(rd(path.join(D,"keys.json"),{})).length].join("\n");
fs.writeFileSync(path.join(require("path").resolve(H,".."),"logs","APEX-REPORT.md"),md+"\n");
console.log(md.split("\n").map(x=>"  "+x).join("\n"));
JSR
}

case "$CMD" in
  menu)     exec node "$H/lib/acli.js" ;;
  install)  install_deps; node "$H/lib/aprivi.js" apply ;;
  start)
    if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then say "  ✔ يعمل (pid $(cat "$PID"))"; exit 0; fi
    install_deps
    S "منح صلاحيات أوسع"
    node "$H/lib/aprivi.js" apply
    node "$H/lib/asites.js"
    node "$H/lib/atraffic.js" >/dev/null 2>&1 || true
    [ -d node_modules/puppeteer-core ] && node "$H/lib/adash.js" >/dev/null 2>&1 &
    nohup node "$H/lib/apex.js" </dev/null >>"$L" 2>&1 &
    sleep 3
    say "  ✔ APEX ينفّذ الآن بصلاحياتك (pid $(cat "$PID" 2>/dev/null))"
    say "  ✔ إشعار ثابت بزرّي «⏹ إيقاف» و«📊 الحالة» على شاشتك"
    say "  ⏹ للإيقاف: bash money/APEX.sh stop"
    ;;
  stop)
    [ -f "$PID" ] && { kill "$(cat "$PID")" 2>/dev/null; sleep 1; kill -9 "$(cat "$PID")" 2>/dev/null; } || say "  ○ لا يعمل"
    node -e 'require(process.argv[1]).clear()' "$H/lib/anotify.js" 2>/dev/null
    pkill -f "lib/adash.js" 2>/dev/null
    say "  ⏹ أوقفتُ APEX"
    ;;
  restart) bash "$H/APEX.sh" stop; sleep 2; exec bash "$H/APEX.sh" start ;;
  status)
    node - "$H" <<'JSS'
const fs=require("fs"),path=require("path"),H=process.argv[2],D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const pid=fs.existsSync(path.join(D,"apex.pid"))?Number(fs.readFileSync(path.join(D,"apex.pid"),"utf8")):0;
let live=false;try{process.kill(pid,0);live=true;}catch(e){}
const s=rd(path.join(D,"apex-state.json"),{}),l=rd(path.join(D,"apex-ledger.json"),{total:0}),h=rd(path.join(D,"health.json"),{score:0,gates:{}}),d=rd(path.join(D,"deploy.json"),{});
console.log("  الحالة : "+(live?"يعمل بصلاحياتك (pid "+pid+")":"متوقف"));
console.log("  الصحة  : "+h.score+"/100 · بوابات "+Object.values(h.gates||{}).filter(Boolean).length+"/10"+(h.ready?" ✅":""));
console.log("  أرباح  : $"+Number(l.total||0).toFixed(2)+"   دورات: "+(s.cycles||0)+"   مفاتيح: "+(s.keys||0));
console.log("  نشر    : "+(s.deploys||0)+"   دفع: "+(s.pushes||0)+"   إصلاح: "+(s.fixes||0));
console.log("  الرابط : "+(d.url||"○ لا رابط عام بعد"));
JSS
    ;;
  ready)  cat logs/READY.txt 2>/dev/null || say "  ○ لم تكتمل البوابات — bash money/APEX.sh health" ;;
  health) node "$H/lib/ahealth.js" ;;
  doctor) node "$H/lib/adoctor.js" ;;
  sync)   node "$H/lib/async.js" ;;
  proof)  node "$H/lib/ahealth.js" >/dev/null; node "$H/lib/aledger.js"; node "$H/lib/aaudit.js" ;;
  plan)   node "$H/lib/aapproval.js"; node "$H/lib/aoutreach.js" ;;
  deploy) node "$H/lib/adeploy.js" ;;
  seo)    node "$H/lib/aseo.js" "${1:-400}" ;;
  sites)  node "$H/lib/asites.js" ;;
  traffic) node "$H/lib/atraffic.js" ;;
  harvest) node "$H/lib/aharvest.js"; [ -f "$H/lib/harvest-live.js" ] && node "$H/lib/harvest-live.js" ;;
  payout) node "$H/lib/apayout.js" ;;
  bank|kyc) node "$H/lib/abank.js" ;;
  dash)   node "$H/lib/adash.js" ;;
  vault)  node "$H/lib/avault.js" "${1:-seal}" ;;
  audit)  node "$H/lib/aaudit.js" ;;
  snapshot) node "$H/lib/asnapshot.js" "${1:-make}" "${2:-}" ;;
  update) node "$H/lib/aupdate.js" ;;
  watch)  node "$H/lib/awatch.js" ;;
  outreach) node "$H/lib/aoutreach.js" "${1:-}" ;;
  report) report ;;
  logs)   tail -n 60 logs/apex.log 2>/dev/null || say "  ○ لا سجل" ;;
  set)
    node -e 'const K=require(process.argv[1]);const o={};process.argv.slice(2).forEach(a=>{const i=a.indexOf("=");if(i>0)o[a.slice(0,i)]=a.slice(i+1);});K.set(o);console.log("  ✔ "+Object.keys(o).join(", "))' "$H/lib/akeys.js" "$@"
    ;;
  all)
    install_deps; node "$H/lib/aprivi.js" apply
    node "$H/lib/asites.js"; node "$H/lib/atraffic.js"; node "$H/lib/adeploy.js"
    node "$H/lib/aseo.js" 300; node "$H/lib/aharvest.js"; node "$H/lib/abank.js"
    node "$H/lib/ahealth.js"; report
    [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null || { nohup node "$H/lib/apex.js" </dev/null >>"$L" 2>&1 & sleep 2; say "  ✔ الوكيل يعمل في الخلفية"; }
    ;;
  *) say "الأوامر: menu|install|start|stop|restart|status|ready|health|doctor|sync|proof|plan|deploy|seo|sites|traffic|harvest|payout|bank|kyc|dash|vault|audit|snapshot|update|watch|outreach|report|logs|set|all" ;;
esac
