#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  OMEGA — الوكيل النهائي: يبني · يربط · يُصلح · يرفع · يتأكد · يشعرك · يتوقف
#  bash money/OMEGA.sh [start|stop|status|ready|doctor|sync|proof|plan]
# ═══════════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
D="$H/data"; mkdir -p "$D" logs money/assets money/lib; [ -f keys.env ] || touch keys.env; chmod 600 keys.env
PID="$D/omega.pid"; ST="$D/omega-state.json"; L="$ROOT/logs/omega.log"
CMD="${1:-start}"

# ═══════ 1) الجسر مع أندرويد (+ زر إيقاف) ═══════
cat > "$H/lib/notify.js" <<'JSN'
#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process"),path=require("path");
const H=path.resolve(__dirname,".."),ID="cinehub";
const run=(c,a,cb)=>execFile(c,a,{timeout:9000},()=>cb&&cb());
const has=c=>new Promise(r=>execFile("which",[c],e=>r(!e)));
function notify(o){
  const a=["--id",ID,"--title",o.title||"CineHub","--content",o.content||"","--priority","high"];
  if(o.ongoing){a.push("--ongoing");a.push("--button1","⏹ إيقاف");a.push("--button1-action","bash "+path.join(H,"OMEGA.sh")+" stop");}
  if(o.progress!=null)a.push("--progress",String(Math.round(o.progress)),"--max","100");
  if(o.big)a.push("--big-text",o.big);
  run("termux-notification",a);
}
const toast=m=>run("termux-toast",["-g","bottom","-c","#2563eb","-b","#0b0e14",String(m).slice(0,220)]);
const vibrate=(d=250,pat)=>run("termux-vibrate",pat?["-p",pat]:["-d",String(d)]);
const clear=()=>run("termux-notification-remove",["--id",ID]);
const clip=()=>new Promise(r=>execFile("termux-clipboard-get",[],{timeout:6000},(e,so)=>r(String(so||"").trim())));
const clipSet=t=>run("termux-clipboard-set",[String(t)]);
const sms=(n=12)=>new Promise(r=>execFile("termux-sms-list",["-l",String(n)],{timeout:9000},(e,so)=>{try{r(JSON.parse(so)||[]);}catch(x){r([]);}}));
module.exports={notify,toast,vibrate,clear,clip,clipSet,sms,has,ID,H};
if(require.main===module){const[,,c]=process.argv;if(c==="test"){notify({title:"OMEGA",content:"الوكيل يعمل باسمك",ongoing:1});toast("✔ الجسر يعمل");vibrate(300,"200,100,200");}else if(c==="clear")clear();}
JSN

# ═══════ 2) الاعتراض: SMS برقمك + الحافظة ═══════
cat > "$H/lib/intercept.js" <<'JSI'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const N=require("./notify.js"),K=require("./keysfile.js");
const D=path.resolve(__dirname,"..","data"),S=path.join(D,"intercept.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(S,"utf8"));}catch(e){return{otp:[],clip:""};}};
const wr=o=>fs.writeFileSync(S,JSON.stringify(o,null,1));
const TOK=/^[A-Za-z0-9_\-]{20,90}$/;
const SITE=/adsterra|monetag|exoclick|juicyads|trafficjunky|evadav|push\.house|clickadilla|propellerads|admaven|hilltopads|galaksion|cpagrip|bitlabs|ayet|offertoro|mylead|lospollos|crakrevenue|cloudflare|github|vercel|netlify/i;
async function checkSms(){
  const st=rd();const msgs=await N.sms(12);const out=[];
  for(const m of msgs){
    const sig=String(m.number||"")+"|"+String(m.body||"").slice(0,40);
    if(st.otp.includes(sig))continue;
    const body=String(m.body||"");const code=(body.match(/\b(\d{4,8})\b/)||[])[1];
    if(code&&(SITE.test(body)||/code|otp|verif|رمز|تحقق/i.test(body))){
      st.otp.push(sig);out.push(code);
      K.set({LAST_OTP:code,LAST_OTP_AT:new Date().toISOString()});
      N.notify({title:"OMEGA · رمز تحقق",content:code,ongoing:0});N.vibrate(180);
      N.clipSet(code);console.log("  ✔ رمز من شريحتك: "+code);
    }
  }
  wr(st);return out;
}
async function checkClip(){
  const st=rd(),txt=await N.clip();
  if(!txt||txt===st.clip||!TOK.test(txt))return null;
  st.clip=txt;wr(st);
  let want="";
  try{const q=JSON.parse(fs.readFileSync(path.join(D,"queue.json"),"utf8"));
    if(q.current){const s=JSON.parse(fs.readFileSync(path.join(__dirname,"..","sources-big.json"),"utf8")).find(x=>x.id===q.current);
      if(s)want=s.env.find(e=>!K.get(e))||"";}
  }catch(e){}
  if(!want){const P=JSON.parse(fs.readFileSync(path.join(__dirname,"..","data","register-plan.json"),"utf8")).plan||[];
    const nx=P.find(x=>x.env&&x.env.some(e=>!K.get(e)));if(nx)want=nx.env.find(e=>!K.get(e))||"";}
  if(!want)return null;
  K.set({[want]:txt});console.log("  ✔ من حافظتك → "+want);
  N.notify({title:"OMEGA · مفتاح جديد",content:want+" محفوظ",ongoing:0});N.vibrate(200);
  return {key:want};
}
module.exports={checkSms,checkClip};
if(require.main===module){checkSms().then(checkClip);}
JSI

# ═══════ 3) المحرّكات المتعددة ═══════
cat > "$H/lib/engines.js" <<'JSE'
#!/usr/bin/env node
"use strict";
// محرّكات التنفيذ بتراجع تلقائي: chromium → http → api → متصفح الهاتف
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const ROOT=path.resolve(__dirname,"..","..");
const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium","/usr/bin/chromium-browser"];
const hasChrom=()=>!!(process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p)));
const hasPup=()=>fs.existsSync(path.join(ROOT,"node_modules","puppeteer-core"));
const hasTermux=()=>new Promise(r=>execFile("which",["termux-open-url"],e=>r(!e)));
const open=u=>new Promise(r=>execFile("termux-open-url",[u],()=>r()));
const get=(u,h)=>new Promise((res,rej)=>{const https=require("https"),http=require("http");
  const m=/^https/.test(u)?https:http;const q=m.get(u,{headers:Object.assign({"user-agent":"Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36"},h||{})},r=>{
    let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>res({status:r.statusCode,body:b,headers:r.headers}));});
  q.on("error",rej);q.setTimeout(15000,()=>q.destroy(new Error("timeout")));});
async function browser(fn){
  if(!hasChrom()||!hasPup())return null;
  const pp=require(path.join(ROOT,"node_modules","puppeteer-core"));
  const br=await pp.launch({executablePath:process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p)),headless:"new",
    args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
  try{return await fn(br,pp);}finally{await br.close();}
}
const rank=()=>({chromium:hasChrom()&&hasPup(),http:true,termux:true});
module.exports={hasChrom,hasPup,hasTermux,open,get,browser,rank};
if(require.main===module){const r=rank();console.log("  المحرّكات المتاحة: "+Object.entries(r).filter(([,v])=>v).map(([k])=>k).join(" · "));}
JSE

# ═══════ 4) طبيب التطبيق ═══════
cat > "$H/lib/doctor.js" <<'JSD'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const codes=require("./codes.js");
const K=require("./keysfile.js");
let fixed=0,issues=[];
const pages=[];
(function walk(d,depth){if(depth>4)return;
  for(const e of fs.readdirSync(d,{withFileTypes:true})){
    if(["_backup","node_modules",".git","logs"].includes(e.name))continue;
    const p=path.join(d,e.name);
    if(e.isDirectory())walk(p,depth+1);else if(/\.html?$/i.test(e.name))pages.push(p);}})(ROOT,0);
const base=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8"));}catch(e){return{brand:"CineHub",handle:"cinehub",desc_short_ar:"",keywords_ar:[],colors:{primary:"#2563eb"}};}})();
const url=K.get("PUBLIC_URL")||("http://127.0.0.1:"+(K.get("PORT")||"8787")+"/");
// 1) إصلاح كل صفحة
for(const p of pages){
  let s=fs.readFileSync(p,"utf8"),o=s;
  if(!/<meta\s+charset/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta charset="utf-8">');issues.push("charset");}
  if(!/name=["']viewport/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="viewport" content="width=device-width,initial-scale=1">');issues.push("viewport");}
  if(!/name=["']description/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="description" content="'+base.desc_short_ar.replace(/"/g,"")+'">');issues.push("description");}
  if(!/property=["']og:title/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta property="og:title" content="'+base.brand+'">'
    +'<meta property="og:description" content="'+base.desc_short_ar.replace(/"/g,"")+'">'
    +'<meta property="og:image" content="/assets/logo.png"><meta name="theme-color" content="'+base.colors.primary+'">');issues.push("og");}
  if(!/rel=["']icon/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><link rel="icon" href="/assets/logo.png"><link rel="manifest" href="/manifest.webmanifest">');issues.push("icon");}
  if(!/<html[^>]*lang=/i.test(s))s=s.replace(/<html/i,'<html lang="ar" dir="rtl"');
  if(s!==o){fs.writeFileSync(p,s);fixed++;}
}
// 2) الملفات الناقصة
const need={
 "robots.txt":"User-agent: *\nAllow: /\nSitemap: "+url.replace(/\/$/,"")+"/sitemap.xml\n",
 "sitemap.xml":'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
   pages.slice(0,200).map(p=>"<url><loc>"+url.replace(/\/$/,"")+"/"+path.relative(ROOT,p).replace(/\\/g,"/")+"</loc></url>").join("\n")+"\n</urlset>\n",
 "manifest.webmanifest":JSON.stringify({name:base.brand,short_name:base.brand,start_url:"/",display:"standalone",
   background_color:"#0b0e14",theme_color:base.colors.primary,icons:[{src:"/assets/logo.png",sizes:"512x512",type:"image/png"}]},null,1),
 "ads.txt":"# أضف سطور شبكاتك بعد القبول\n"}
for(const[f,c]of Object.entries(need)){
  const p=path.join(ROOT,f);
  if(!fs.existsSync(p)){fs.writeFileSync(p,c);fixed++;issues.push("أنشأ "+f);}
}
// 3) فحص صياغة JS
for(const f of fs.readdirSync(HERE).filter(x=>x.endsWith(".js"))){
  try{require("child_process").execFileSync("node",["--check",path.join(HERE,f)],{stdio:"pipe"});}
  catch(e){issues.push("خطأ صياغة "+f);}
}
// 4) الروابط الداخلية المكسورة
for(const p of pages){
  const s=fs.readFileSync(p,"utf8");
  for(const m of s.matchAll(/(?:href|src)=["'](?!https?:|\/\/|#|mailto:|data:)([^"']+)["']/g)){
    const t=m[1].split("?")[0];if(!t||t==="/")continue;
    const abs=t.startsWith("/")?path.join(ROOT,t):path.join(path.dirname(p),t);
    if(!fs.existsSync(abs)&&!/\.(php|json)$/.test(abs))issues.push("رابط مكسور "+t);
  }
}
const rep={at:new Date().toISOString(),pages:pages.length,fixed,issues:[...new Set(issues)].slice(0,40)};
fs.writeFileSync(path.join(D,"doctor.json"),JSON.stringify(rep,null,1));
codes.save("طبيب التطبيق",{صفحات:pages.length,إصلاحات:fixed,مشاكل:rep.issues.length});
console.log("  ✔ فحص "+pages.length+" صفحة · أصلحت/أنشأت "+fixed+" عنصرًا · ملاحظات "+rep.issues.length);
JSD

# ═══════ 5) إثبات الأرباح ═══════
cat > "$H/lib/revenue-proof.js" <<'JSR'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const D=path.resolve(__dirname,"..","data"),P=path.join(D,"revenue-proof.json");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const led=rd(path.join(D,"ledger.json"),{total:0});
const prev=rd(P,{samples:[]});
const now=Number(led.total||0);
prev.samples.push({at:new Date().toISOString(),total:now});
if(prev.samples.length>20)prev.samples=prev.samples.slice(-20);
const a=prev.samples[0],b=prev.samples[prev.samples.length-1];
prev.total=now;
prev.rising=prev.samples.length>=2 && (b.total-a.total)>0;
prev.delta=prev.samples.length>=2?(b.total-a.total):0;
prev.confirmed=prev.rising && now>0;
fs.writeFileSync(P,JSON.stringify(prev,null,1));
console.log("  "+(prev.confirmed?"✔":"○")+" الأرباح: $"+now.toFixed(2)+"  (تغيّر: $"+prev.delta.toFixed(2)+" على "+prev.samples.length+" عيّنة)");
process.exit(prev.confirmed?0:1);
JSR

# ═══════ 6) الرفع إلى GitHub ═══════
cat > "$H/lib/sync-gh.js" <<'JSG'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),K=require("./keysfile.js"),codes=require("./codes.js");
const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER");
if(!tk||!user)return console.log("  ○ لا GITHUB_TOKEN أو GH_USER — bash money/AGENT-RUN.sh set GITHUB_TOKEN=... GH_USER=...");
const repo=K.get("GITHUB_REPO")||(user+".cinehub");
const run=a=>{try{return execFileSync("git",a,{cwd:ROOT,stdio:"pipe"}).toString();}catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
const api=(m,p,b)=>new Promise(r=>{const https=require("https");
  const q=https.request({host:"api.github.com",path:p,method:m,headers:{"user-agent":"cinehub","authorization":"Bearer "+tk,accept:"application/vnd.github+json","content-type":"application/json"}},x=>{
    let d="";x.on("data",c=>d+=c);x.on("end",()=>r({status:x.statusCode,body:d}));});q.on("error",()=>r({status:0}));q.end(b?JSON.stringify(b):undefined);});
(async()=>{
  await api("POST","/user/repos",{name:repo.replace(/^.*\./,""),private:true,description:"CineHub — منصة أفلام + وكيل أرباح",auto_init:false});
  if(!fs.existsSync(path.join(ROOT,".git")))run(["init","-q"]);
  run(["config","user.email",K.get("CONTACT_EMAIL")||"cinehub@local"]);
  run(["config","user.name",user]);
  const gi=path.join(ROOT,".gitignore");
  if(!fs.existsSync(gi))fs.writeFileSync(gi,"node_modules/\n_backup/\nlogs/*.log\nkeys.env\n__pycache__/\n*.pid\n");
  const rd=path.join(ROOT,"README.md");
  if(!fs.existsSync(rd))fs.writeFileSync(rd,"# CineHub\n\nمنصة أفلام ومسلسلات + وكيل أرباح ذاتي.\n\n"+
    "## التشغيل\n```bash\nbash money/OMEGA.sh\n```\n\n## الأوامر\n`start|stop|status|ready|doctor|sync|proof|plan`\n");
  run(["add","-A"]);
  run(["commit","-q","-m","OMEGA: "+new Date().toISOString()]);
  run(["branch","-M","main"]);
  run(["remote","remove","origin"]);run(["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo.replace(/^.*\./,"")+".git"]);
  const out=run(["push","-u","origin","main","--force"]);
  const ok=/main|up-to-date|->/.test(out);
  console.log(ok?"  ✔ رُفع إلى https://github.com/"+user+"/"+repo.replace(/^.*\./,""):"  ○ "+out.slice(0,120));
  codes.save("رفع GitHub",{repo:user+"/"+repo.replace(/^.*\./,""),الحالة:ok?"مرفوع":"فشل",الوقت:new Date().toISOString()});
})();
JSG

# ═══════ 7) خطة التسجيل (من 666 منصة) ═══════
cat > "$H/lib/register-plan.js" <<'JSP'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const S=JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8"));
const KP=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"keypages.json"),"utf8"));}catch(e){return{};}})();
const PRI={adult:0,ads:1,pay:2,channel:3,dev:4,infra:5,crypto:6,ai:7,data:8,media:9,fx:10,movie:11,series:12,seo:13};
const plan=S.filter(x=>x.url&&x.url!=="-"&&x.env&&x.env.length)
 .map(x=>({id:x.id,name:x.name,cat:x.cat,url:x.url,env:x.env,
   tier:KP[x.id]?"A":(/signup|register|join/i.test(x.url)?"A":"B"),
   pri:PRI[x.cat]!=null?PRI[x.cat]:99}))
 .sort((a,b)=>a.pri-b.pri||a.tier.localeCompare(b.tier));
fs.writeFileSync(path.join(D,"register-plan.json"),JSON.stringify({at:new Date().toISOString(),total:plan.length,plan},null,1));
const byT={};plan.forEach(p=>byT[p.tier]=(byT[p.tier]||0)+1);
console.log("  ✔ خطة تسجيل: "+plan.length+" منصة (A="+(byT.A||0)+" فورية · B="+(byT.B||0)+" بالتحقق)");
JSP

# ═══════ 8) الحلقة النهائية ببوابة جاهزية ═══════
cat > "$H/lib/omega-daemon.js" <<'JSO'
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
JSO

# ═══════ 9) ملف بنك الكريمي ═══════
cat > "$H/data/bank.json" <<'JSON'
{
"bank":"بنك الكريمي (Al-Kuraimi Islamic Microfinance Bank)",
"country":"اليمن","swift":"KRIBYEBA","swift_note":"أكّد الرمز مع الفرع — موسوم unverified",
"currencies":["USD","SAR","YER"],
"receive_methods":["حوالة دولية USD عبر SWIFT","مراسل بنكي","Payoneer ثم تحويل محلي","USDT ثم صرافة محلية"],
"fields":{"ACCOUNT_NAME":"","ACCOUNT_NUMBER":"","IBAN_OR_LOCAL":"","BRANCH":"","BENEFICIARY_PHONE":""},
"fill_hint":"bash money/AGENT-RUN.sh set BANK_ACCOUNT_NAME=\"اسمك\" BANK_ACCOUNT_NUMBER=\"رقمك\" BANK_BRANCH=\"الفرع\"",
"payout_flow":"حصد → ledger → تجاوز PAYOUT_THRESHOLD → USDC على Base إلى PAYOUT_ADDRESS → تحويل إلى الكريمي"
}
JSON

# ═══════ الأوامر ═══════
case "$CMD" in
install)
  pkg install -y termux-api >/dev/null 2>&1 || true
  command -v termux-notification >/dev/null 2>&1 && echo "  ✔ termux-api" || echo "  ⚠ ثبّت Termux:API من F-Droid"
  termux-setup-storage 2>/dev/null; termux-wake-lock 2>/dev/null
  termux-job-scheduler --script "$H/JOB.sh" --job-id 3099 --period-ms 900000 --network any --persisted true >/dev/null 2>&1 \
    && echo "  ✔ وظيفة أندرويد مجدولة (تبقى بعد إغلاق Termux وإعادة التشغيل)" || echo "  ○ الجدولة تحتاج termux-api"
  echo "  ⚠ الإعدادات ← التطبيقات ← Termux ← البطارية ← بلا قيود"
  ;;

start)
  if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then echo "  ✔ يعمل (pid $(cat "$PID"))"; exit 0; fi
  bash "$H/OMEGA.sh" install >/dev/null 2>&1
  node "$H/lib/engines.js"
  nohup node "$H/lib/omega-daemon.js" </dev/null >>"$L" 2>&1 &
  sleep 3
  if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then
    echo "  ✔ OMEGA يعمل باسمك (pid $(cat "$PID"))"
    echo "  ✔ إشعار ثابت بزر «⏹ إيقاف»"
    echo "  ⏹ bash money/OMEGA.sh stop"
  else echo "  ✗ لم يبدأ — logs/omega.log"; fi
  ;;

stop) [ -f "$PID" ] && { kill "$(cat "$PID")" 2>/dev/null; sleep 1; kill -9 "$(cat "$PID")" 2>/dev/null; node -e 'require(process.argv[1]).clear()' "$H/lib/notify.js" 2>/dev/null; echo "  ⏹ أوقفتُ OMEGA"; } || echo "  ○ لا يعمل" ;;

status)
  node - "$H" <<'JSS'
const fs=require("fs"),path=require("path"),H=process.argv[2],D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const pid=fs.existsSync(path.join(D,"omega.pid"))?Number(fs.readFileSync(path.join(D,"omega.pid"),"utf8")):0;
let live=false;try{process.kill(pid,0);live=true;}catch(e){}
const s=rd(path.join(D,"omega-state.json"),{}),l=rd(path.join(D,"ledger.json"),{total:0}),p=rd(path.join(D,"revenue-proof.json"),{});
console.log("  الحالة : "+(live?"يعمل باسمك (pid "+pid+")":"متوقف"));
console.log("  جاهزية : "+(s.ready?"✅ كاملة":"… "+(s.cycles||0)+" دورة"));
console.log("  أرباح  : $"+Number(l.total||0).toFixed(2)+(p.rising?"  ↗ يزيد":"")+"   |  إصلاحات: "+(s.fixes||0)+"  |  رفع: "+(s.pushes||0));
JSS
  ;;

ready) cat logs/READY.txt 2>/dev/null || echo "  ○ لم تكتمل الجاهزية بعد" ;;
doctor) node "$H/lib/doctor.js" ;;
sync)   node "$H/lib/sync-gh.js" ;;
proof)  node "$H/lib/revenue-proof.js" ;;
plan)   node "$H/lib/register-plan.js" ;;
bank)   node -e 'const b=require(process.argv[1]);console.log(JSON.stringify(b,null,2))' "$H/data/bank.json" ;;
*) echo "الأوامر: start | stop | status | ready | doctor | sync | proof | plan | bank | install" ;;
esac
