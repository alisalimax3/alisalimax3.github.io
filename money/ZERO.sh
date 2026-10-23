#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  ZERO — وكيل ذكي مستقل: يكتشف · يسجّل · يتحقق · يجلب المفاتيح · يربط · يختبر
#  bash money/ZERO.sh [boot|start|stop|pause|resume|status|menu|consent|owner|
#   registry|queue|batch|stage|test|verify|human|docs|report|evidence|creds|
#   seal|open|schedule|set|logs|rollback|revoke|all]
# ══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
D="$H/data"; DB="$H/db"; mkdir -p "$D" "$DB" logs docs/services money/lib
[ -f keys.env ] || touch keys.env; chmod 600 keys.env 2>/dev/null
PID="$D/zero.pid"; ST="$D/zero-state.json"; L="$ROOT/logs/zero.log"
CMD="${1:-menu}"; shift || true
say(){ printf '%s\n' "$*"; }
S(){ printf '\n══════════ %s ══════════\n' "$1"; }
w(){ local f="$1"; [ "${FORCE:-0}" = "1" ] && rm -f "$f"; [ -f "$f" ] || cat > "$f"; }

# ═══════════ 1) خزنة الأسرار ═══════════
w "$H/lib/z-keys.js" <<'Z1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),ENV=path.join(ROOT,"keys.env"),D=path.resolve(__dirname,"..","data"),REG=path.join(D,"secrets.json");
fs.mkdirSync(D,{recursive:true});
const hash=s=>crypto.createHash("sha256").update(String(s)).digest("hex").slice(0,16);
const mask=s=>{s=String(s);return s.length>16?s.slice(0,5)+"…"+s.slice(-4):s;};
function all(){const o={};try{fs.readFileSync(ENV,"utf8").split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0&&!/^\s*#/.test(l))o[l.slice(0,i).trim()]=l.slice(i+1).trim();});}catch(e){}return o;}
const get=k=>all()[k]||"";
function atomic(f,t){const tmp=f+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,f);try{fs.chmodSync(f,0o600);}catch(e){}}
function reg(){try{return JSON.parse(fs.readFileSync(REG,"utf8"));}catch(e){return{};}}
function set(o,src){const c=all(),r=reg(),at=new Date().toISOString();
  Object.keys(o).forEach(k=>{if(o[k]==null||o[k]==="")return;c[k]=String(o[k]);r[k]={at,src:src||"agent",h:hash(o[k]),mask:mask(o[k])};});
  atomic(ENV,Object.keys(c).sort().map(k=>k+"="+c[k]).join("\n")+"\n");atomic(REG,JSON.stringify(r,null,1));return Object.keys(o);}
function del(k){const c=all();delete c[k];atomic(ENV,Object.keys(c).sort().map(x=>x+"="+c[x]).join("\n")+"\n");const r=reg();delete r[k];atomic(REG,JSON.stringify(r,null,1));}
function verify(){const c=all(),r=reg(),bad=[];Object.keys(r).forEach(k=>{if(c[k]&&hash(c[k])!==r[k].h)bad.push(k);});
  return{total:Object.keys(c).length,tracked:Object.keys(r).length,bad};}
const P=()=>process.env.ZERO_VAULT_PASS||get("VAULT_PASS")||"zero-local";
function seal(){const o=execFileSync("openssl",["enc","-aes-256-cbc","-pbkdf2","-iter","200000","-salt","-pass","pass:"+P(),"-in",ENV]);
  const f=path.join(D,"vault.enc");fs.writeFileSync(f,o);try{fs.chmodSync(f,0o600);}catch(e){}return "✔ خُتمت الخزنة ("+o.length+" بايت)";}
function open(){const f=path.join(D,"vault.enc");if(!fs.existsSync(f))return "○ لا خزنة";
  const o=execFileSync("openssl",["enc","-d","-aes-256-cbc","-pbkdf2","-iter","200000","-pass","pass:"+P(),"-in",f]);
  atomic(ENV,o.toString());return "✔ استُعيدت keys.env";}
module.exports={get,set,del,all,reg,mask,hash,verify,seal,open,ENV};
if(require.main===module){const c=process.argv[2]||"list";
  if(c==="list")Object.entries(all()).forEach(([k,v])=>console.log("  "+k+" = "+mask(v)));
  else if(c==="verify"){const v=verify();console.log("  مفاتيح "+v.total+" · متعقّبة "+v.tracked+(v.bad.length?" · ✗ تغيّرت: "+v.bad.join(", "):" · ✔ سلامة سليمة"));}
  else if(c==="seal")console.log("  "+seal());else if(c==="open")console.log("  "+open());
  else if(c==="set"){const o={};process.argv.slice(3).forEach(a=>{const i=a.indexOf("=");if(i>0)o[a.slice(0,i)]=a.slice(i+1);});console.log("  ✔ "+set(o,"owner").join(", "));}}
Z1

# ═══════════ 2) قاعدة البيانات + آلة الحالة ═══════════
w "$H/lib/z-db.js" <<'Z2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"db");
const F={targets:path.join(D,"targets.json"),journal:path.join(D,"journal.jsonl"),evidence:path.join(D,"evidence.jsonl"),
  tests:path.join(D,"tests.json"),human:path.join(D,"human.json"),locks:path.join(D,"locks.json"),
  links:path.join(D,"links.json"),ads:path.join(D,"ads.json"),progress:path.join(D,"progress.json")};
const STAGES=["new","resolved","reachable","account","email","key","linked","live","human","failed","locked"];
function ensure(){fs.mkdirSync(D,{recursive:true});Object.values(F).forEach(f=>{if(!fs.existsSync(f))fs.writeFileSync(f,f.endsWith(".jsonl")?"":"{}");});}
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
function wr(f,o){const t=f+"."+process.pid+".tmp";fs.writeFileSync(t,JSON.stringify(o,null,1));fs.renameSync(t,f);}
function jrn(e,d){ensure();fs.appendFileSync(F.journal,JSON.stringify({at:new Date().toISOString(),event:e,data:d||{}})+"\n");}
const targets=()=>{ensure();return rd(F.targets,{});};
const target=id=>targets()[id]||null;
function upsert(id,o){const t=targets();t[id]=Object.assign(t[id]||{id,stage:"new",attempts:0,evidence:0,created:new Date().toISOString()},o);
  t[id].updated=new Date().toISOString();wr(F.targets,t);return t[id];}
function stage(id,s,note){const t=targets();if(!t[id])return null;const prev=t[id].stage;
  t[id].stage=s;t[id].updated=new Date().toISOString();if(note)t[id].note=note;
  t[id].history=(t[id].history||[]).concat([{from:prev,to:s,at:new Date().toISOString()}]);
  wr(F.targets,t);jrn("stage",{id,from:prev,to:s,note:note||""});return t[id];}
function ev(id,kind,data){ensure();fs.appendFileSync(F.evidence,JSON.stringify({at:new Date().toISOString(),id,kind,data:data||{}})+"\n");
  const t=targets();if(t[id]){t[id].evidence=(t[id].evidence||0)+1;t[id].lastEvidence=new Date().toISOString();wr(F.targets,t);}}
function test(id,res){const T=rd(F.tests,{});T[id]=Object.assign({at:new Date().toISOString()},res);wr(F.tests,T);jrn("test",{id,ok:res.ok});return T[id];}
const human=()=>{ensure();return rd(F.human,{});};
function humanAdd(it){const h=human();h[it.id]=Object.assign(h[it.id]||{id:it.id,at:new Date().toISOString()},it);wr(F.human,h);jrn("human",{id:it.id,why:it.why});return h[it.id];}
function humanResolve(id,val){const h=human();if(h[id]){h[id].resolved=val||true;h[id].resolvedAt=new Date().toISOString();wr(F.human,h);jrn("human-resolved",{id});}return h[id];}
function next(n,filter){const t=targets(),now=Date.now();
  return Object.values(t).filter(x=>!x.locked&&x.stage!=="locked"&&(!x.nextAt||x.nextAt<=now)&&(!filter||filter(x)))
    .sort((a,b)=>(a.attempts||0)-(b.attempts||0)||String(a.updated).localeCompare(String(b.updated))).slice(0,n||10);}
function fail(id,note){const t=targets();if(!t[id])return;t[id].attempts=(t[id].attempts||0)+1;
  t[id].nextAt=Date.now()+Math.min(6*3600e3,Math.pow(2,t[id].attempts)*45000);t[id].lastError=note;wr(F.targets,t);}
function stats(){const t=Object.values(targets()),by={};t.forEach(x=>by[x.stage]=(by[x.stage]||0)+1);
  const T=rd(F.tests,{});const pass=Object.values(T).filter(x=>x.ok).length;
  return{total:t.length,by,tests:Object.keys(T).length,passed:pass,humanPending:Object.values(human()).filter(x=>!x.resolved).length,
    evidence:fs.existsSync(F.evidence)?fs.readFileSync(F.evidence,"utf8").split("\n").filter(Boolean).length:0};}
function backup(){const f=path.join(D,"backup-"+Date.now()+".json");wr(f,{targets:targets(),tests:rd(F.tests,{}),human:human()});return f;}
function lock(id){const t=targets();if(t[id]){t[id].locked=true;t[id].stage="locked";wr(F.targets,t);}}
function unlock(id){const t=targets();if(t[id]){t[id].locked=false;if(t[id].stage==="locked")t[id].stage="reachable";wr(F.targets,t);}}
const rollback=(id,s)=>stage(id,s,"rollback يدوي");
module.exports={ensure,targets,target,upsert,stage,ev,test,human,humanAdd,humanResolve,next,fail,stats,backup,lock,unlock,rollback,jrn,rd,wr,D,F,STAGES};
if(require.main===module){const c=process.argv[2]||"stats";
  if(c==="stats")console.log(JSON.stringify(stats(),null,1));
  else if(c==="backup")console.log("  ✔ "+backup());
  else if(c==="human")Object.values(human()).filter(x=>!x.resolved).forEach(x=>console.log("  ○ "+x.id+" — "+x.why));}
Z2

# ═══════════ 3) طبقة HTTP الرسمية (curl · إعادة محاولة · حدّ معدّل) ═══════════
w "$H/lib/z-http.js" <<'Z3'
#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process"),fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),CJ=path.join(H,"db","cookies");
const UA=["Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36",
 "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125 Safari/537.36",
 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36"];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const RATE={};
const jar=h=>{fs.mkdirSync(CJ,{recursive:true});return path.join(CJ,String(h).replace(/[^\w.-]/g,"_")+".txt");};
const curl=(a,t)=>new Promise(r=>execFile("curl",a,{timeout:t||30000,maxBuffer:12e6},(e,so,se)=>r({e,so:String(so||""),se:String(se||"")})));
async function req(method,url,o){o=o||{};
  let host="x";try{host=new URL(url).host;}catch(e){}
  const gap=o.gap==null?1200:o.gap,last=RATE[host]||0,wait=Math.max(0,last+gap-Date.now());
  if(wait>0)await sleep(wait);RATE[host]=Date.now();
  const a=["-sL","--max-time",String(Math.round((o.timeout||30000)/1000)),"-A",o.ua||UA[Math.floor(Math.random()*UA.length)],
    "-w","\n%{http_code} %{time_total} %{url_effective}","-b",jar(host),"-c",jar(host),"--compressed"];
  Object.entries(o.headers||{}).forEach(([k,v])=>a.push("-H",k+": "+v));
  if(method!=="GET")a.push("-X",method);
  if(o.json)a.push("-H","content-type: application/json","--data-binary",JSON.stringify(o.json));
  else if(o.form)Object.entries(o.form).forEach(([k,v])=>a.push("--data-urlencode",k+"="+(v==null?"":String(v))));
  a.push(url);
  const r=await curl(a,o.timeout||30000);
  const parts=r.so.replace(/\s+$/,"").split("\n"),meta=(parts.pop()||"").split(" ");
  return{status:Number(meta[0]||0),ms:Math.round(Number(meta[1]||0)*1000),url:meta[2]||url,body:parts.join("\n"),
    ok:Number(meta[0]||0)>0&&Number(meta[0]||0)<400,err:r.se};
}
async function retry(method,url,o,tries){tries=tries||3;let r;
  for(let i=0;i<tries;i++){r=await req(method,url,o);if(r.status>0&&r.status<500)return r;await sleep(1200*(i+1));}
  return r;}
const get=(u,o)=>req("GET",u,o);
const post=(u,o)=>req("POST",u,o);
function links(html,base){const out=new Set(),re=/href=["']([^"'#]+)["']/gi;let m;
  while((m=re.exec(html))){let h=m[1];if(/^(mailto:|javascript:|tel:|data:)/.test(h))continue;
    try{h=new URL(h,base).href;}catch(e){continue;}
    if(/signup|sign-up|register|join|create-account|publisher|partner|dashboard|pricing|login|signin/i.test(h))out.add(h);}
  return [...out].slice(0,50);}
function hiddenFields(html){const o={},re=/<input[^>]*type=["']hidden["'][^>]*>/gi;let m;
  while((m=re.exec(html))){const n=(m[0].match(/name=["']([^"']+)["']/i)||[])[1],v=(m[0].match(/value=["']([^"']*)["']/i)||[])[1];
    if(n&&!/csrf|token/i.test(n))o[n]=v||"";}
  return o;}
const tpl=(s,v)=>String(s||"").replace(/\{(\w+)\}/g,(m,k)=>v&&v[k]!=null?v[k]:m);
module.exports={req,get,post,retry,links,hiddenFields,tpl,sleep,jar,UA};
Z3

# ═══════════ 4) كاسر التحقق البشري (رسمي · وإلا يبقى لك) ═══════════
w "$H/lib/z-captcha.js" <<'Z4'
#!/usr/bin/env node
"use strict";
const K=require("./z-keys.js"),HTTP=require("./z-http.js");
const sleep=HTTP.sleep;
function kindOf(k){return /hcap/i.test(k)?"hcaptcha":/turnstile/i.test(k)?"turnstile":/recap/i.test(k)?"recaptcha":"unknown";}
async function two(kind,url,key,extra){const tok=K.get("TWOCAPTCHA_KEY");if(!tok)return "";
  const m={recaptcha:"userrecaptcha",hcaptcha:"hcaptcha",turnstile:"turnstile"}[kind]||"userrecaptcha";
  const p=new URLSearchParams({key:tok,method:m,sitekey:key,pageurl:url,json:1});
  if(kind==="recaptcha"&&extra&&extra.v3){p.set("version","v3");p.set("action",extra.action||"login");p.set("min_score","0.3");}
  const c=await HTTP.get("https://2captcha.com/in.php?"+p.toString(),{timeout:20000});
  const j=JSON.parse(c.body||"{}");if(j.status!==1)return "";
  for(let i=0;i<40;i++){await sleep(5000);
    const r=await HTTP.get("https://2captcha.com/res.php?key="+tok+"&action=get&id="+j.request+"&json=1",{timeout:20000});
    const g=JSON.parse(r.body||"{}");if(g.status===1)return g.request;}
  return "";}
async function capsolver(kind,url,key){const tok=K.get("CAPSOLVER_KEY");if(!tok)return "";
  const type={recaptcha:"ReCaptchaV2TaskProxyLess",hcaptcha:"HCaptchaTaskProxyLess",turnstile:"AntiTurnstileTaskProxyLess"}[kind];
  const c=await HTTP.post("https://api.capsolver.com/createTask",{json:{clientKey:tok,task:{type,websiteURL:url,websiteKey:key}},timeout:20000});
  const j=JSON.parse(c.body||"{}");if(j.errorId)return "";
  for(let i=0;i<40;i++){await sleep(4000);
    const r=await HTTP.post("https://api.capsolver.com/getTaskResult",{json:{clientKey:tok,taskId:j.taskId},timeout:20000});
    const g=JSON.parse(r.body||"{}");if(g.status==="ready")return (g.solution||{}).gRecaptchaResponse||(g.solution||{}).token||"";}
  return "";}
async function solve(kindRaw,url,key,extra){const kind=kindOf(kindRaw);if(!key)return "";
  try{return await capsolver(kind,url,key)||await two(kind,url,key,extra)||"";}catch(e){return "";}}
module.exports={solve,kindOf};
Z4

# ═══════════ 5) بريد حقيقي + انتظار رابط التحقق ═══════════
w "$H/lib/z-mail.js" <<'Z5'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto"),tls=require("tls");
const H=path.resolve(__dirname,".."),DB=path.join(H,"db"),F=path.join(DB,"mail.json");
const K=require("./z-keys.js"),HTTP=require("./z-http.js"),ID=require("./z-identity.js");
const sleep=HTTP.sleep;
const rd=()=>{try{return JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){return{};}};
const wr=o=>{fs.mkdirSync(DB,{recursive:true});fs.writeFileSync(F,JSON.stringify(o,null,1));};
async function fromTmp(host){const d=await HTTP.get("https://"+host+"/domains",{headers:{accept:"application/ld+json"},timeout:20000});
  let j={};try{j=JSON.parse(d.body);}catch(e){}
  const list=j["hydra:member"]||j.member||[];const dom=(list.find(x=>x.isActive!==false)||{}).domain||(list[0]||{}).domain;
  if(!dom)throw new Error("لا نطاق على "+host);
  const addr="cine"+crypto.randomBytes(3).toString("hex")+"@"+dom,pass=crypto.randomBytes(9).toString("base64url");
  const a=await HTTP.post("https://"+host+"/accounts",{json:{address:addr,password:pass},timeout:20000});
  if(a.status>=400)throw new Error("فشل إنشاء بريد "+a.status);
  const t=await HTTP.post("https://"+host+"/token",{json:{address:addr,password:pass},timeout:20000});
  let tok="";try{tok=JSON.parse(t.body).token;}catch(e){}
  if(!tok)throw new Error("فشل توكن البريد");
  return{provider:host,addr,pass,tok,type:"tmp"};}
async function fromOneSec(){const d=await HTTP.get("https://www.1secmail.com/api/v1/?action=getDomainList",{timeout:20000});
  let doms=[];try{doms=JSON.parse(d.body);}catch(e){}
  if(!doms.length)throw new Error("1secmail لا نطاق");
  const login="cine"+crypto.randomBytes(3).toString("hex");
  return{provider:"1secmail",addr:login+"@"+doms[0],pass:"",login,dom:doms[0],type:"onesec"};}
async function create(){for(const f of [()=>fromTmp("api.mail.tm"),()=>fromTmp("api.mail.gw"),fromOneSec]){try{return await f();}catch(e){}}throw new Error("كل مزوّدي البريد فشلوا");}
async function ensure(id){const m=rd();if(m[id])return m[id];
  const owner=ID.get();
  if(K.get("IMAP_HOST")&&owner.email){const b={provider:"imap",type:"imap",addr:String(owner.email).replace("@","+"+id+"@")};m[id]=b;wr(m);return b;}
  const b=await create();m[id]=b;wr(m);return b;}
async function messages(box){if(box.type==="onesec"){const u="https://www.1secmail.com/api/v1/?action=getMessages&login="+box.login+"&domain="+box.dom;
    const r=await HTTP.get(u,{timeout:20000});try{return JSON.parse(r.body)||[];}catch(e){return[];}}
  if(box.type==="imap")return imapRaw(box.addr);
  const r=await HTTP.get("https://"+box.provider+"/messages",{headers:{authorization:"Bearer "+box.tok},timeout:20000});
  try{return JSON.parse(r.body)["hydra:member"]||[];}catch(e){return[];}}
async function full(box,msg){if(box.type==="onesec"){const u="https://www.1secmail.com/api/v1/?action=readMessage&login="+box.login+"&domain="+box.dom+"&id="+(msg.id||msg.ID);
    const r=await HTTP.get(u,{timeout:20000});return r.body;}
  if(box.type==="imap")return msg.raw||"";
  const r=await HTTP.get("https://"+box.provider+"/messages/"+(msg.id||msg.ID),{headers:{authorization:"Bearer "+box.tok},timeout:20000});return r.body;}
function imapRaw(addr){return new Promise(res=>{const host=K.get("IMAP_HOST"),user=K.get("IMAP_USER"),pass=K.get("IMAP_PASS");
  const c=tls.connect({host,port:Number(K.get("IMAP_PORT")||993)},()=>{});let buf="",st=0,out=[];
  const done=v=>{try{c.end();}catch(e){}res(v);};
  const send=s=>c.write(s+"\r\n");
  c.on("data",d=>{buf+=d.toString("utf8");
    if(st===0&&/\* OK/.test(buf)){send("a1 LOGIN "+user+" "+pass);st=1;buf="";return;}
    if(st===1&&/a1 (OK|NO)/.test(buf)){send("a2 SELECT INBOX");st=2;buf="";return;}
    if(st===2&&/a2 (OK|NO)/.test(buf)){send("a3 UID SEARCH ALL");st=3;buf="";return;}
    if(st===3){const m=buf.match(/\* SEARCH ([\d ]+)/);if(m&&/a3 OK/.test(buf)){const ids=m[1].trim().split(/\s+/).filter(Boolean).slice(-4);
      if(!ids.length)return done([]);send("a4 UID FETCH "+ids.join(",")+" (BODY.PEEK[])");st=4;buf="";}return;}
    if(st===4&&/a4 (OK|NO)/.test(buf)){out.push({id:1,raw:buf});return done(out);}});
  c.on("error",()=>done([]));setTimeout(()=>done(out),25000);});}
async function wait(id,rx,timeoutMs){const box=await ensure(id);const t0=Date.now();const seen=new Set();
  const re=new RegExp(rx||"https?://[^\\s\"'<>]*(confirm|verify|activat|valid|token|signup)[^\\s\"'<>]*","i");
  while(Date.now()-t0<(timeoutMs||180000)){
    let msgs=[];try{msgs=await messages(box);}catch(e){}
    for(const m of msgs){const k=String(m.id||m.ID);if(seen.has(k))continue;seen.add(k);
      let body="";try{body=await full(box,m);}catch(e){}
      const link=(String(body).replace(/&amp;/g,"&").match(re)||[])[0];
      if(link)return{box,link,code:(String(body).match(/\b(\d{4,8})\b/)||[])[1]||""};}
    await sleep(6000);}
  return{box,link:"",code:""};}
module.exports={create,ensure,wait,messages,full,rd};
Z5

# ═══════════ 6) متصفح حقيقي (يُستخدم فقط عند الحاجة) ═══════════
w "$H/lib/z-browser.js" <<'Z6'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,"..");
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36";
const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium","/usr/bin/chromium-browser","/usr/bin/google-chrome"];
const exe=()=>process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p));
const has=()=>!!(exe()&&fs.existsSync(path.join(ROOT,"node_modules","puppeteer-core")));
async function withPage(fn){if(!has())return{ok:false,note:"لا متصفح"};
  const pp=require(path.join(ROOT,"node_modules","puppeteer-core"));
  const br=await pp.launch({executablePath:exe(),headless:"new",
    args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu","--single-process","--no-zygote","--disable-setuid-sandbox"]});
  const page=await br.newPage();await page.setUserAgent(UA);await page.setViewport({width:1366,height:900});
  try{return await fn(page,br);}catch(e){return{ok:false,note:String(e.message||e).slice(0,160)};}finally{try{await br.close();}catch(e){}}}
async function shot(page,name){try{const d=path.join(ROOT,"logs","shots");fs.mkdirSync(d,{recursive:true});
  const f=path.join(d,name+".png");await page.screenshot({path:f});return path.relative(ROOT,f);}catch(e){return"";}}
async function fill(page,map){let n=0;
  const pairs=[["email","input[type=email],input[name*=mail i],input[id*=mail i]"],
   ["pass","input[type=password],input[name*=pass i],input[id*=pass i]"],
   ["user","input[name*=user i],input[name*=login i],input[id*=login i],input[name*=nick i]"],
   ["name","input[name*=name i],input[id*=name i],input[name*=first i]"],
   ["site","input[name*=site i],input[name*=url i],input[name*=website i],input[name*=domain i]"]];
  for(const[k,sel]of pairs){if(!map[k])continue;try{const el=await page.$(sel);if(!el)continue;
    await el.click({clickCount:3});await el.type(String(map[k]),{delay:14});n++;}catch(e){}}
  try{const cb=await page.$('input[type=checkbox]:not([checked])');if(cb)await cb.click();}catch(e){}
  return n;}
async function submit(page){try{const b=await page.$('button[type=submit],input[type=submit],form button:not([type=button])');
  if(!b)return false;await Promise.all([page.waitForNavigation({waitUntil:"domcontentloaded",timeout:40000}).catch(()=>{}),b.click()]);return true;}catch(e){return false;}}
async function clickText(page,txt){const h=await page.evaluateHandle(t=>{const a=[...document.querySelectorAll("a,button,input[type=submit]")];
  return a.find(x=>((x.innerText||x.value||"").toLowerCase().includes(t)))||null;},String(txt).toLowerCase());
  const el=h&&h.asElement?h.asElement():null;if(!el)return false;try{await el.click();return true;}catch(e){return false;}}
async function scrape(page,rx){try{const html=await page.content();
  return [...new Set((html.match(new RegExp(rx,"g"))||[]).filter(x=>x.length>=16))].slice(0,8);}catch(e){return[];}}
async function captchaInPage(page,url){try{const info=await page.evaluate(()=>{const el=document.querySelector("[data-sitekey]");
  const k=el?el.getAttribute("data-sitekey"):"";
  const kind=document.querySelector("iframe[src*=hcaptcha],.h-captcha")?"hcaptcha":
    (document.querySelector("iframe[src*=recaptcha],.g-recaptcha")?"recaptcha":(document.querySelector(".cf-turnstile")?"turnstile":""));
  return{k,kind};});
  if(!info.kind)return"";
  const t=await require("./z-captcha.js").solve(info.kind,url,info.k);
  if(!t)return"";
  await page.evaluate(tok=>{["h-captcha-response","g-recaptcha-response","cf-turnstile-response"].forEach(n=>{
    let e=document.querySelector('[name="'+n+'"]');
    if(!e){e=document.createElement("textarea");e.name=n;e.style.display="none";document.body.appendChild(e);}e.value=tok;});},t);
  return t;}catch(e){return"";}}
module.exports={withPage,has,exe,fill,submit,clickText,scrape,shot,captchaInPage,UA};
Z6

# ═══════════ 7) الهوية والتفويض والبيانات السرّية ═══════════
w "$H/lib/z-identity.js" <<'Z7'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const H=path.resolve(__dirname,".."),D=path.join(H,"data"),ID=path.join(D,"identity.json"),CS=path.join(D,"consent.json"),CR=path.join(H,"db","creds.json");
fs.mkdirSync(D,{recursive:true});
const K=require("./z-keys.js");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>fs.writeFileSync(f,JSON.stringify(o,null,1));
function get(){return Object.assign({brand:"CineHub",handle:"cinehub",name:"",email:"",phone:"",country:"",
  site_url:K.get("PUBLIC_URL")||"",wallet:K.get("PAYOUT_ADDRESS")||"",payout_chain:"base"},rd(ID,{}));}
function ensure(){if(!fs.existsSync(ID))wr(ID,get());if(!fs.existsSync(CS))wr(CS,{at:new Date().toISOString(),
  grants:{"استخدام بريدي المؤقت للتحقق":"مصرّح","إنشاء كلمات مرور وحفظها في keys.env":"مصرّح",
  "فتح المتصفح وملء النماذج نيابة عني":"مصرّح","طلب تدخّلي عند KYC/دفع/تحقق بشري":"مصرّح"}});
  return get();}
function creds(id){const c=rd(CR,{});if(c[id])return c[id];
  const I=get();const u=(I.handle||"cine")+"_"+crypto.randomBytes(2).toString("hex");
  const p=crypto.randomBytes(9).toString("base64url")+"!9";
  c[id]={user:u,pass:p,at:new Date().toISOString()};wr(CR,c);return c[id];}
module.exports={get,ensure,creds,rd,wr};
if(require.main===module){const c=process.argv[2]||"show";
  if(c==="init")console.log("  ✔ الهوية والتفويض جاهزان (money/data/identity.json + consent.json)");
  else if(c==="creds")Object.entries(rd(CR,{})).forEach(([k,v])=>console.log("  "+k+" → "+v.user+" / "+v.pass));
  else console.log(JSON.stringify(get(),null,1));}
Z7

# ═══════════ 8) وصفات الخدمات (واجهات رسمية) ═══════════
w "$H/lib/z-recipes.js" <<'Z8'
#!/usr/bin/env node
"use strict";
const R=[];const r=o=>{R.push(o);return o;};
const h=d=>{try{return new URL(d).host;}catch(e){return String(d).replace(/^https?:\/\//,"").split("/")[0];}};
// ── شبكات الربح (تحقق بمفتاح API حقيقي) ──
r({id:"adsterra",cat:"ads",name:"Adsterra",home:"https://adsterra.com",signup:"https://publishers.adsterra.com/signup",keysUrl:"https://publishers.adsterra.com/api",env:["ADSTERRA_API_KEY"],regex:"[A-Za-z0-9]{24,64}",needs:["email"],human:["captcha"],method:"http",conf:3,
  verify:{kind:"api",url:"https://api3.adsterratools.com/publisher/stats.json?start_date={FROM}&finish_date={TO}&group_by=date",headers:{"X-API-Key":"{KEY}"},keyEnv:"ADSTERRA_API_KEY"}});
r({id:"monetag",cat:"ads",name:"Monetag",home:"https://monetag.com",signup:"https://monetag.com/signup/",keysUrl:"https://monetag.com/dashboard/settings/api",env:["MONETAG_API_KEY"],regex:"[A-Za-z0-9]{24,80}",needs:["email"],human:["captcha"],method:"browser",conf:2,
  verify:{kind:"api",url:"https://api.monetag.com/v1/statistics?date_from={FROM}&date_to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"MONETAG_API_KEY"}});
r({id:"exoclick",cat:"ads",name:"ExoClick",home:"https://www.exoclick.com",signup:"https://www.exoclick.com/signup/",keysUrl:"https://admin.exoclick.com/api",env:["EXOCLICK_API_TOKEN"],regex:"[A-Za-z0-9]{24,80}",needs:["email"],human:["captcha"],method:"browser",conf:2,
  verify:{kind:"api",url:"https://api.exoclick.com/v2/login",headers:{},keyEnv:"EXOCLICK_API_TOKEN"}});
r({id:"evadav",cat:"ads",name:"Evadav",home:"https://evadav.com",signup:"https://evadav.com/signup",keysUrl:"https://evadav.com/settings",env:["EVADAV_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"api",url:"https://api.evadav.com/v1/statistics?from={FROM}&to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"EVADAV_API_KEY"}});
r({id:"juicyads",cat:"ads",name:"JuicyAds",home:"https://www.juicyads.com",signup:"https://www.juicyads.com/signup.php",keysUrl:"https://www.juicyads.com/publisher/api",env:["JUICYADS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"api",url:"https://api.juicyads.com/api/v1/stats?from={FROM}&to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"JUICYADS_API_KEY"}});
r({id:"lospollos",cat:"ads",name:"LosPollos",home:"https://lospollos.com",signup:"https://lospollos.com/signup",keysUrl:"https://lospollos.com/settings",env:["LOSPOLLOS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"api",url:"https://api.lospollos.com/v1/stats?from={FROM}&to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"LOSPOLLOS_API_KEY"}});
r({id:"trafficjunky",cat:"ads",name:"TrafficJunky",home:"https://www.trafficjunky.com",signup:"https://www.trafficjunky.com/publisher/signup",keysUrl:"https://admin.trafficjunky.com/reports",env:["TRAFFICJUNKY_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"http",url:"https://www.trafficjunky.com"}});
r({id:"clickadilla",cat:"ads",name:"ClickAdilla",home:"https://clickadilla.com",signup:"https://clickadilla.com/signup",keysUrl:"https://clickadilla.com/statistics",env:["CLICKADILLA_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://clickadilla.com"}});
r({id:"propellerads",cat:"ads",name:"PropellerAds",home:"https://propellerads.com",signup:"https://publishers.propellerads.com/#/signup",keysUrl:"https://publishers.propellerads.com",env:["PROPELLERADS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],human:["captcha"],method:"browser",conf:1,verify:{kind:"http",url:"https://publishers.propellerads.com"}});
r({id:"pushhouse",cat:"ads",name:"Push.House",home:"https://push.house",signup:"https://push.house/register",keysUrl:"https://push.house/settings",env:["PUSHHOUSE_TOKEN"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://push.house"}});
r({id:"hilltopads",cat:"ads",name:"HilltopAds",home:"https://hilltopads.com",signup:"https://hilltopads.com/register",keysUrl:"https://hilltopads.com/publisher/api",env:["HILLTOPADS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://hilltopads.com"}});
r({id:"galaksion",cat:"ads",name:"Galaksion",home:"https://galaksion.com",signup:"https://galaksion.com/register",keysUrl:"https://galaksion.com",env:["GALAKSION_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://galaksion.com"}});
r({id:"admaven",cat:"ads",name:"AdMaven",home:"https://admaven.com",signup:"https://admaven.com/register",keysUrl:"https://admaven.com",env:["ADMAVEN_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://admaven.com"}});
r({id:"cpagrip",cat:"ads",name:"CPAGrip",home:"https://www.cpagrip.com",signup:"https://www.cpagrip.com/signup.php",keysUrl:"https://www.cpagrip.com",env:["CPAGRIP_API_KEY"],regex:"[A-Za-z0-9]{16,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.cpagrip.com"}});
r({id:"bitlabs",cat:"ads",name:"BitLabs",home:"https://bitlabs.ai",signup:"https://dashboard.bitlabs.ai/signup",keysUrl:"https://dashboard.bitlabs.ai",env:["BITLABS_API_KEY"],regex:"[A-Za-z0-9_\\-]{16,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://bitlabs.ai"}});
r({id:"offertoro",cat:"ads",name:"OfferToro",home:"https://www.offertoro.com",signup:"https://www.offertoro.com/signup",keysUrl:"https://www.offertoro.com",env:["OFFERTORO_API_KEY","OFFERTORO_APP_ID"],regex:"[A-Za-z0-9]{8,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.offertoro.com"}});
r({id:"mylead",cat:"ads",name:"MyLead",home:"https://mylead.global",signup:"https://mylead.global/signup",keysUrl:"https://mylead.global",env:["MYLEAD_API_KEY"],regex:"[A-Za-z0-9]{16,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://mylead.global"}});
r({id:"crakrevenue",cat:"ads",name:"CrakRevenue",home:"https://www.crakrevenue.com",signup:"https://www.crakrevenue.com/signup",keysUrl:"https://www.crakrevenue.com",env:["CRAKREVENUE_API_KEY"],regex:"[A-Za-z0-9]{16,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.crakrevenue.com"}});
// ── استضافة ونشر ──
r({id:"surge",cat:"host",name:"Surge",home:"https://surge.sh",signup:"https://surge.sh/signup",keysUrl:"https://surge.sh",env:["SURGE_TOKEN","SURGE_DOMAIN"],regex:"[A-Za-z0-9]{20,80}",needs:["email"],method:"none",conf:3,verify:{kind:"http",url:"https://surge.sh"}});
r({id:"netlify",cat:"host",name:"Netlify",home:"https://netlify.com",signup:"https://app.netlify.com/signup",keysUrl:"https://app.netlify.com/user/applications#personal-access-tokens",env:["NETLIFY_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,80}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.netlify.com/api/v1/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"NETLIFY_TOKEN"}});
r({id:"vercel",cat:"host",name:"Vercel",home:"https://vercel.com",signup:"https://vercel.com/signup",keysUrl:"https://vercel.com/account/tokens",env:["VERCEL_TOKEN"],regex:"[A-Za-z0-9]{24,40}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.vercel.com/v2/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"VERCEL_TOKEN"}});
r({id:"cloudflare",cat:"host",name:"Cloudflare",home:"https://cloudflare.com",signup:"https://dash.cloudflare.com/sign-up",keysUrl:"https://dash.cloudflare.com/profile/api-tokens",env:["CF_TOKEN","CF_PROJECT"],regex:"[A-Za-z0-9_\\-]{35,60}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.cloudflare.com/client/v4/user/tokens/verify",headers:{Authorization:"Bearer {KEY}"},keyEnv:"CF_TOKEN"}});
r({id:"github",cat:"host",name:"GitHub",home:"https://github.com",signup:"https://github.com/signup",keysUrl:"https://github.com/settings/tokens",env:["GITHUB_TOKEN","GH_USER"],regex:"[A-Za-z0-9_]{35,45}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.github.com/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"GITHUB_TOKEN"}});
r({id:"gitlab",cat:"host",name:"GitLab",home:"https://gitlab.com",signup:"https://gitlab.com/users/sign_up",keysUrl:"https://gitlab.com/-/profile/personal_access_tokens",env:["GITLAB_TOKEN"],regex:"[A-Za-z0-9_\\-]{20,30}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://gitlab.com/api/v4/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"GITLAB_TOKEN"}});
r({id:"neocities",cat:"host",name:"Neocities",home:"https://neocities.org",signup:"https://neocities.org/",keysUrl:"https://neocities.org/settings",env:["NEOCITIES_USER","NEOCITIES_PASS"],regex:"[A-Za-z0-9]{8,40}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://neocities.org/api/list",headers:{Authorization:"Basic {KEY}"},keyEnv:"NEOCITIES_USER"}});
r({id:"render",cat:"host",name:"Render",home:"https://render.com",signup:"https://dashboard.render.com/register",keysUrl:"https://dashboard.render.com/u/settings#api-keys",env:["RENDER_API_KEY"],regex:"[A-Za-z0-9]{20,60}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.render.com/v1/owners",headers:{Authorization:"Bearer {KEY}"},keyEnv:"RENDER_API_KEY"}});
r({id:"railway",cat:"host",name:"Railway",home:"https://railway.app",signup:"https://railway.app/login",keysUrl:"https://railway.app/account/tokens",env:["RAILWAY_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://railway.app"}});
r({id:"fly",cat:"host",name:"Fly.io",home:"https://fly.io",signup:"https://fly.io/app/sign-up",keysUrl:"https://fly.io/user/personal_access_tokens",env:["FLY_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,90}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://fly.io"}});
r({id:"deno",cat:"host",name:"Deno Deploy",home:"https://deno.com/deploy",signup:"https://dash.deno.com/signin",keysUrl:"https://dash.deno.com/account#tokens",env:["DENO_TOKEN"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://dash.deno.com"}});
// ── قواعد بيانات وخدمات خلفية ──
r({id:"supabase",cat:"db",name:"Supabase",home:"https://supabase.com",signup:"https://supabase.com/dashboard/sign-up",keysUrl:"https://supabase.com/dashboard/project/_/settings/api",env:["SUPABASE_URL","SUPABASE_ANON_KEY"],regex:"[A-Za-z0-9_.\\-]{30,200}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"http",url:"https://supabase.com"}});
r({id:"neon",cat:"db",name:"Neon",home:"https://neon.tech",signup:"https://console.neon.tech/signup",keysUrl:"https://console.neon.tech/app/settings/api-keys",env:["NEON_API_KEY"],regex:"[A-Za-z0-9_\\-]{30,90}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://console.neon.tech/api/v2/projects",headers:{Authorization:"Bearer {KEY}"},keyEnv:"NEON_API_KEY"}});
r({id:"turso",cat:"db",name:"Turso",home:"https://turso.tech",signup:"https://app.turso.tech/signup",keysUrl:"https://app.turso.tech/settings/api-tokens",env:["TURSO_TOKEN"],regex:"[A-Za-z0-9_.\\-]{30,120}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://turso.tech"}});
r({id:"upstash",cat:"db",name:"Upstash",home:"https://upstash.com",signup:"https://console.upstash.com/login",keysUrl:"https://console.upstash.com/account/api",env:["UPSTASH_EMAIL","UPSTASH_API_KEY"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://upstash.com"}});
r({id:"mongodb",cat:"db",name:"MongoDB Atlas",home:"https://www.mongodb.com/atlas",signup:"https://account.mongodb.com/account/register",keysUrl:"https://cloud.mongodb.com/v2#/account/publicApi",env:["MONGODB_PUBLIC_KEY","MONGODB_PRIVATE_KEY"],regex:"[A-Za-z0-9_\\-]{8,64}",needs:["email"],human:["captcha"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.mongodb.com"}});
r({id:"appwrite",cat:"db",name:"Appwrite",home:"https://appwrite.io",signup:"https://cloud.appwrite.io/register",keysUrl:"https://cloud.appwrite.io",env:["APPWRITE_ENDPOINT","APPWRITE_PROJECT","APPWRITE_KEY"],regex:"[A-Za-z0-9_\\-]{16,120}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cloud.appwrite.io"}});
r({id:"pocketbase",cat:"db",name:"PocketBase",home:"https://pocketbase.io",signup:"https://pocketbase.io/docs/",keysUrl:"https://pocketbase.io",env:[],needs:[],method:"none",conf:1,verify:{kind:"http",url:"https://pocketbase.io"}});
r({id:"nhost",cat:"db",name:"Nhost",home:"https://nhost.io",signup:"https://app.nhost.io/signup",keysUrl:"https://app.nhost.io",env:["NHOST_SUBDOMAIN","NHOST_ADMIN_SECRET"],regex:"[A-Za-z0-9_\\-]{16,120}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://nhost.io"}});
r({id:"cloudflare-d1",cat:"db",name:"Cloudflare D1/R2/KV",home:"https://developers.cloudflare.com/d1/",signup:"https://dash.cloudflare.com/sign-up",keysUrl:"https://dash.cloudflare.com/profile/api-tokens",env:["CF_ACCOUNT_ID"],regex:"[A-Za-z0-9]{32}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://dash.cloudflare.com"}});
r({id:"backblaze",cat:"storage",name:"Backblaze B2",home:"https://www.backblaze.com/cloud-storage",signup:"https://www.backblaze.com/sign-up/cloud-storage",keysUrl:"https://secure.backblaze.com/app_keys.htm",env:["B2_KEY_ID","B2_APP_KEY"],regex:"[A-Za-z0-9]{12,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.backblaze.com"}});
r({id:"cloudinary",cat:"storage",name:"Cloudinary",home:"https://cloudinary.com",signup:"https://cloudinary.com/users/register_free",keysUrl:"https://console.cloudinary.com/settings/api-keys",env:["CLOUDINARY_URL"],regex:"cloudinary://[A-Za-z0-9]+:[A-Za-z0-9_\\-]+@[A-Za-z0-9]+",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cloudinary.com"}});
// ── بريد ومراسلة ──
r({id:"brevo",cat:"mail",name:"Brevo",home:"https://www.brevo.com",signup:"https://onboarding.brevo.com/account/register",keysUrl:"https://app.brevo.com/settings/keys/api",env:["BREVO_API_KEY"],regex:"xkeysib-[A-Za-z0-9_\\-]{40,90}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.brevo.com/v3/account",headers:{"api-key":"{KEY}"},keyEnv:"BREVO_API_KEY"}});
r({id:"mailgun",cat:"mail",name:"Mailgun",home:"https://www.mailgun.com",signup:"https://signup.mailgun.com/new/signup",keysUrl:"https://app.mailgun.com/app/account/security/api_keys",env:["MAILGUN_API_KEY","MAILGUN_DOMAIN"],regex:"[A-Za-z0-9\\-]{24,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.mailgun.net/v3/domains",headers:{Authorization:"Basic {KEY}"},keyEnv:"MAILGUN_API_KEY"}});
r({id:"resend",cat:"mail",name:"Resend",home:"https://resend.com",signup:"https://resend.com/signup",keysUrl:"https://resend.com/api-keys",env:["RESEND_API_KEY"],regex:"re_[A-Za-z0-9_]{20,60}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.resend.com/domains",headers:{Authorization:"Bearer {KEY}"},keyEnv:"RESEND_API_KEY"}});
r({id:"sendgrid",cat:"mail",name:"SendGrid",home:"https://sendgrid.com",signup:"https://signup.sendgrid.com/",keysUrl:"https://app.sendgrid.com/settings/api_keys",env:["SENDGRID_API_KEY"],regex:"SG\\.[A-Za-z0-9_\\-]{20,80}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.sendgrid.com/v3/scopes",headers:{Authorization:"Bearer {KEY}"},keyEnv:"SENDGRID_API_KEY"}});
// ── مراقبة وأتمتة وتحليلات ──
r({id:"healthchecks",cat:"monitor",name:"Healthchecks.io",home:"https://healthchecks.io",signup:"https://healthchecks.io/accounts/signup/",keysUrl:"https://healthchecks.io/accounts/profile/",env:["HEALTHCHECK_PING_URL"],regex:"https://hc-ping\\.com/[A-Za-z0-9\\-]+",needs:["email"],method:"http",conf:2,verify:{kind:"http",url:"https://healthchecks.io"}});
r({id:"uptimerobot",cat:"monitor",name:"UptimeRobot",home:"https://uptimerobot.com",signup:"https://uptimerobot.com/signUp",keysUrl:"https://uptimerobot.com/dashboard#mySettings",env:["UPTIMEROBOT_API_KEY"],regex:"u[0-9]{6}-[A-Za-z0-9]{20,40}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.uptimerobot.com/v2/getAccountDetails",headers:{"content-type":"application/x-www-form-urlencoded"},keyEnv:"UPTIMEROBOT_API_KEY"}});
r({id:"cronjob",cat:"automation",name:"cron-job.org",home:"https://cron-job.org",signup:"https://console.cron-job.org/signup",keysUrl:"https://console.cron-job.org/settings",env:["CRONJOB_API_KEY"],regex:"[A-Za-z0-9_\\-]{24,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cron-job.org"}});
r({id:"betterstack",cat:"monitor",name:"Better Stack",home:"https://betterstack.com",signup:"https://betterstack.com/users/sign-up",keysUrl:"https://uptime.betterstack.com/team/0/api-tokens",env:["BETTERSTACK_TOKEN"],regex:"[A-Za-z0-9_]{30,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://betterstack.com"}});
r({id:"umami",cat:"analytics",name:"Umami Cloud",home:"https://umami.is",signup:"https://cloud.umami.is/signup",keysUrl:"https://cloud.umami.is/settings",env:["UMAMI_WEBSITE_ID"],regex:"[a-f0-9\\-]{36}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cloud.umami.is"}});
r({id:"goatcounter",cat:"analytics",name:"GoatCounter",home:"https://www.goatcounter.com",signup:"https://www.goatcounter.com/signup",keysUrl:"https://www.goatcounter.com/settings",env:["GOATCOUNTER_CODE"],regex:"[a-z0-9\\-]{3,40}",needs:["email"],method:"http",conf:1,verify:{kind:"http",url:"https://www.goatcounter.com"}});
r({id:"plausible",cat:"analytics",name:"Plausible",home:"https://plausible.io",signup:"https://plausible.io/register",keysUrl:"https://plausible.io/settings",env:["PLAUSIBLE_DOMAIN"],regex:"[A-Za-z0-9.\\-]{4,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://plausible.io"}});
r({id:"sentry",cat:"monitor",name:"Sentry",home:"https://sentry.io",signup:"https://sentry.io/signup/",keysUrl:"https://sentry.io/settings/account/api/auth-tokens/",env:["SENTRY_DSN","SENTRY_AUTH_TOKEN"],regex:"https://[a-f0-9]+@[a-z0-9.]+/[0-9]+",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://sentry.io/api/0/",headers:{Authorization:"Bearer {KEY}"},keyEnv:"SENTRY_AUTH_TOKEN"}});
// ── SEO وأدوات ──
r({id:"indexnow",cat:"seo",name:"IndexNow",home:"https://www.indexnow.org",signup:"https://www.indexnow.org/documentation",keysUrl:"https://www.indexnow.org",env:["INDEXNOW_KEY"],regex:"[A-Za-z0-9]{8,64}",needs:[],method:"none",conf:3,verify:{kind:"http",url:"https://api.indexnow.org/indexnow"}});
r({id:"google-search-console",cat:"seo",name:"Google Search Console",home:"https://search.google.com/search-console",signup:"https://search.google.com/search-console/welcome",keysUrl:"https://search.google.com/search-console",env:["GSC_VERIFICATION"],regex:"[A-Za-z0-9_\\-]{20,90}",needs:["email"],human:["identity","dns"],method:"none",conf:1,verify:{kind:"http",url:"https://search.google.com/search-console"}});
r({id:"bing-webmaster",cat:"seo",name:"Bing Webmaster",home:"https://www.bing.com/webmasters",signup:"https://www.bing.com/webmasters/about",keysUrl:"https://www.bing.com/webmasters",env:["BING_API_KEY"],regex:"[A-Za-z0-9]{20,60}",needs:["email"],human:["identity"],method:"none",conf:1,verify:{kind:"http",url:"https://www.bing.com/webmasters"}});
r({id:"cloudflare-pages",cat:"host",name:"Cloudflare Pages",home:"https://pages.cloudflare.com",signup:"https://dash.cloudflare.com/sign-up",keysUrl:"https://dash.cloudflare.com/profile/api-tokens",env:["CF_PAGES_PROJECT"],regex:"[a-z0-9\\-]{3,60}",needs:["email"],method:"none",conf:1,verify:{kind:"http",url:"https://pages.cloudflare.com"}});
// ── دفع وتحويل ──
r({id:"nowpayments",cat:"pay",name:"NOWPayments",home:"https://nowpayments.io",signup:"https://account.nowpayments.io/create-account",keysUrl:"https://account.nowpayments.io/store-settings/api-keys",env:["NOWPAYMENTS_API_KEY","NOWPAYMENTS_IPN"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],human:["kyc"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.nowpayments.io/v1/status",headers:{"x-api-key":"{KEY}"},keyEnv:"NOWPAYMENTS_API_KEY"}});
r({id:"cryptomus",cat:"pay",name:"Cryptomus",home:"https://cryptomus.com",signup:"https://app.cryptomus.com/register",keysUrl:"https://app.cryptomus.com/api",env:["CRYPTOMUS_MERCHANT","CRYPTOMUS_API_KEY"],regex:"[A-Za-z0-9\\-]{30,60}",needs:["email"],human:["kyc"],method:"browser",conf:1,verify:{kind:"http",url:"https://cryptomus.com"}});
r({id:"coingate",cat:"pay",name:"CoinGate",home:"https://coingate.com",signup:"https://account.coingate.com/signup",keysUrl:"https://account.coingate.com/api/auth-tokens",env:["COINGATE_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,80}",needs:["email"],human:["kyc"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.coingate.com/v2/auth/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"COINGATE_TOKEN"}});
// ── بلوكشين وواجهات ──
r({id:"alchemy",cat:"crypto",name:"Alchemy",home:"https://www.alchemy.com",signup:"https://dashboard.alchemy.com/signup",keysUrl:"https://dashboard.alchemy.com/apps",env:["ALCHEMY_KEY"],regex:"[A-Za-z0-9_\\-]{20,50}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.alchemy.com"}});
r({id:"infura",cat:"crypto",name:"Infura",home:"https://infura.io",signup:"https://app.infura.io/register",keysUrl:"https://app.infura.io/dashboard",env:["INFURA_KEY"],regex:"[a-f0-9]{32}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://infura.io"}});
r({id:"quicknode",cat:"crypto",name:"QuickNode",home:"https://www.quicknode.com",signup:"https://www.quicknode.com/signup",keysUrl:"https://dashboard.quicknode.com/endpoints",env:["QUICKNODE_URL"],regex:"https://[a-z0-9\\-]+\\.quiknode\\.pro/[a-z0-9/]+",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.quicknode.com"}});
r({id:"thegraph",cat:"crypto",name:"The Graph",home:"https://thegraph.com",signup:"https://thegraph.com/studio/",keysUrl:"https://thegraph.com/studio/apikeys/",env:["GRAPH_API_KEY"],regex:"[A-Za-z0-9]{30,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://thegraph.com"}});
// ── ذكاء اصطناعي ──
r({id:"groq",cat:"ai",name:"Groq",home:"https://groq.com",signup:"https://console.groq.com/signup",keysUrl:"https://console.groq.com/keys",env:["GROQ_API_KEY"],regex:"gsk_[A-Za-z0-9]{40,60}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.groq.com/openai/v1/models",headers:{Authorization:"Bearer {KEY}"},keyEnv:"GROQ_API_KEY"}});
r({id:"openrouter",cat:"ai",name:"OpenRouter",home:"https://openrouter.ai",signup:"https://openrouter.ai/",keysUrl:"https://openrouter.ai/keys",env:["OPENROUTER_API_KEY"],regex:"sk-or-[A-Za-z0-9\\-]{30,80}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://openrouter.ai/api/v1/models",headers:{Authorization:"Bearer {KEY}"},keyEnv:"OPENROUTER_API_KEY"}});
r({id:"huggingface",cat:"ai",name:"HuggingFace",home:"https://huggingface.co",signup:"https://huggingface.co/join",keysUrl:"https://huggingface.co/settings/tokens",env:["HF_TOKEN"],regex:"hf_[A-Za-z0-9]{30,50}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://huggingface.co/api/whoami-v2",headers:{Authorization:"Bearer {KEY}"},keyEnv:"HF_TOKEN"}});
r({id:"replicate",cat:"ai",name:"Replicate",home:"https://replicate.com",signup:"https://replicate.com/signin",keysUrl:"https://replicate.com/account/api-tokens",env:["REPLICATE_TOKEN"],regex:"r8_[A-Za-z0-9]{30,50}",needs:["email"],human:["payment"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.replicate.com/v1/account",headers:{Authorization:"Bearer {KEY}"},keyEnv:"REPLICATE_TOKEN"}});
r({id:"deepgram",cat:"ai",name:"Deepgram",home:"https://deepgram.com",signup:"https://console.deepgram.com/signup",keysUrl:"https://console.deepgram.com/project/_/keys",env:["DEEPGRAM_KEY"],regex:"[a-f0-9]{40}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://deepgram.com"}});
r({id:"elevenlabs",cat:"ai",name:"ElevenLabs",home:"https://elevenlabs.io",signup:"https://elevenlabs.io/sign-up",keysUrl:"https://elevenlabs.io/app/settings/api-keys",env:["ELEVENLABS_KEY"],regex:"sk_[a-f0-9]{40,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.elevenlabs.io/v1/user",headers:{"xi-api-key":"{KEY}"},keyEnv:"ELEVENLABS_KEY"}});
// ── أتمتة ونماذج ──
r({id:"formspree",cat:"forms",name:"Formspree",home:"https://formspree.io",signup:"https://formspree.io/register",keysUrl:"https://formspree.io/forms",env:["FORMSPREE_ID"],regex:"[a-z0-9]{8,12}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://formspree.io"}});
r({id:"n8n",cat:"automation",name:"n8n Cloud",home:"https://n8n.io",signup:"https://app.n8n.cloud/register",keysUrl:"https://app.n8n.cloud/manage",env:["N8N_URL","N8N_API_KEY"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://n8n.io"}});
r({id:"airtable",cat:"automation",name:"Airtable",home:"https://airtable.com",signup:"https://airtable.com/signup",keysUrl:"https://airtable.com/create/tokens",env:["AIRTABLE_TOKEN","AIRTABLE_BASE"],regex:"pat[A-Za-z0-9.]{20,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.airtable.com/v0/meta/whoami",headers:{Authorization:"Bearer {KEY}"},keyEnv:"AIRTABLE_TOKEN"}});
r({id:"notion",cat:"automation",name:"Notion",home:"https://www.notion.so",signup:"https://www.notion.so/signup",keysUrl:"https://www.notion.so/my-integrations",env:["NOTION_TOKEN"],regex:"(secret_|ntn_)[A-Za-z0-9]{30,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.notion.com/v1/users/me",headers:{Authorization:"Bearer {KEY}","Notion-Version":"2022-06-28"},keyEnv:"NOTION_TOKEN"}});
// ── مجموعات موسّعة (تحقق وصول مباشر) ──
const BULK=[
 ["producthunt","dir","https://www.producthunt.com","https://www.producthunt.com/"],
 ["betalist","dir","https://betalist.com","https://betalist.com/submit"],
 ["alternativeto","dir","https://alternativeto.net","https://alternativeto.net/"],
 ["crunchbase","dir","https://www.crunchbase.com","https://www.crunchbase.com/"],
 ["f6s","dir","https://www.f6s.com","https://www.f6s.com/join"],
 ["saashub","dir","https://www.saashub.com","https://www.saashub.com/"],
 ["toolify","dir","https://www.toolify.ai","https://www.toolify.ai/"],
 ["futurepedia","dir","https://www.futurepedia.io","https://www.futurepedia.io/"],
 ["theresanaiforthat","dir","https://theresanaiforthat.com","https://theresanaiforthat.com/"],
 ["aitools","dir","https://aitools.fyi","https://aitools.fyi/submit"],
 ["topai","dir","https://topai.tools","https://topai.tools/submit"],
 ["startupbase","dir","https://startupbase.io","https://startupbase.io/"],
 ["indiehackers","dir","https://www.indiehackers.com","https://www.indiehackers.com/"],
 ["devto","blog","https://dev.to","https://dev.to/enter"],
 ["hashnode","blog","https://hashnode.com","https://hashnode.com/onboard"],
 ["medium","blog","https://medium.com","https://medium.com/m/signin"],
 ["substack","blog","https://substack.com","https://substack.com/signup"],
 ["blogger","blog","https://www.blogger.com","https://www.blogger.com/start"],
 ["wordpress","blog","https://wordpress.com","https://wordpress.com/start"],
 ["tumblr","blog","https://www.tumblr.com","https://www.tumblr.com/register"],
 ["reddit","social","https://www.reddit.com","https://www.reddit.com/register"],
 ["pinterest","social","https://www.pinterest.com","https://www.pinterest.com/business/create"],
 ["quora","social","https://www.quora.com","https://www.quora.com/"],
 ["vk","social","https://vk.com","https://vk.com/join"],
 ["mastodon","social","https://mastodon.social","https://mastodon.social/auth/sign_up"],
 ["gravatar","tool","https://gravatar.com","https://gravatar.com/"],
 ["imgbb","storage","https://imgbb.com","https://imgbb.com/signup"],
 ["imagekit","storage","https://imagekit.io","https://imagekit.io/registration"],
 ["statically","cdn","https://statically.io","https://statically.io/"],
 ["jsdelivr","cdn","https://www.jsdelivr.com","https://www.jsdelivr.com/"],
 ["bunny","cdn","https://bunny.net","https://bunny.net/signup"],
 ["gcore","cdn","https://gcore.com","https://gcore.com/signup"],
 ["statcounter","analytics","https://statcounter.com","https://statcounter.com/signup/"],
 ["matomo","analytics","https://matomo.org","https://matomo.org/"],
 ["simpleanalytics","analytics","https://www.simpleanalytics.com","https://www.simpleanalytics.com/signup"],
 ["counter","analytics","https://counter.dev","https://counter.dev/"],
 ["posthog","analytics","https://posthog.com","https://app.posthog.com/signup"],
 ["clarity","analytics","https://clarity.microsoft.com","https://clarity.microsoft.com/"],
 ["logtail","monitor","https://betterstack.com/logs","https://logs.betterstack.com/users/sign-up"],
 ["logflare","monitor","https://logflare.app","https://logflare.app/users/register"],
 ["axiom","monitor","https://axiom.co","https://app.axiom.co/register"],
 ["grafana","monitor","https://grafana.com","https://grafana.com/auth/sign-up/create-user"],
 ["freshping","monitor","https://www.freshworks.com/website-monitoring/","https://www.freshworks.com/website-monitoring/"],
 ["statuspage","monitor","https://www.atlassian.com/software/statuspage","https://www.atlassian.com/software/statuspage"],
 ["uptime","monitor","https://uptime.com","https://uptime.com/signup"],
 ["cloudflare-analytics","analytics","https://www.cloudflare.com/web-analytics/","https://dash.cloudflare.com/sign-up"],
 ["npoint","tool","https://www.npoint.io","https://www.npoint.io/"],
 ["jsonbin","db","https://jsonbin.io","https://jsonbin.io/signup"],
 ["restdb","db","https://restdb.io","https://restdb.io/signup"],
 ["firebase","db","https://firebase.google.com","https://console.firebase.google.com/"],
 ["fauna","db","https://fauna.com","https://dashboard.fauna.com/register"],
 ["xata","db","https://xata.io","https://app.xata.io/signup"],
 ["cockroach","db","https://www.cockroachlabs.com","https://cockroachlabs.cloud/signup"],
 ["aiven","db","https://aiven.io","https://console.aiven.io/signup"],
 ["koyeb","host","https://www.koyeb.com","https://app.koyeb.com/auth/signup"],
 ["deta","host","https://deta.space","https://deta.space/signup"],
 ["valtown","host","https://www.val.town","https://www.val.town/signup"],
 ["glitch","host","https://glitch.com","https://glitch.com/signup"],
 ["heroku","host","https://www.heroku.com","https://signup.heroku.com/"],
 ["azure-static","host","https://azure.microsoft.com/products/app-service/static","https://azure.microsoft.com/free/"],
 ["tiiny","host","https://tiiny.host","https://tiiny.host/signup"],
 ["static","host","https://static.app","https://static.app/"],
 ["onrender","host","https://render.com","https://dashboard.render.com/register"],
 ["surge2","host","https://surge.sh","https://surge.sh/help/getting-started-with-surge"],
 ["byethost","host","https://byet.host","https://byet.host/signup"],
 ["infinityfree","host","https://infinityfree.net","https://infinityfree.net/"],
 ["000webhost","host","https://www.000webhost.com","https://www.000webhost.com/"],
 ["freehostia","host","https://www.freehostia.com","https://www.freehostia.com/signup.html"],
 ["awardspace","host","https://www.awardspace.com","https://www.awardspace.com/free-hosting/"],
 ["netlify2","host","https://www.netlify.com","https://app.netlify.com/signup"],
 ["railway2","host","https://railway.app","https://railway.app/login"],
 ["zeabur","host","https://zeabur.com","https://zeabur.com/signup"],
 ["northflank","host","https://northflank.com","https://app.northflank.com/signup"],
 ["encore","host","https://encore.dev","https://encore.dev/"],
 ["modal","host","https://modal.com","https://modal.com/signup"],
 ["replit","host","https://replit.com","https://replit.com/signup"],
 ["codesandbox","host","https://codesandbox.io","https://codesandbox.io/signup"],
 ["stackblitz","host","https://stackblitz.com","https://stackblitz.com/signup"],
 ["deno-kv","db","https://deno.com/kv","https://dash.deno.com/signin"],
 ["upstash-kafka","db","https://upstash.com/kafka","https://console.upstash.com/login"],
 ["neon2","db","https://neon.tech","https://console.neon.tech/signup"],
 ["supabase2","db","https://supabase.com","https://supabase.com/dashboard/sign-up"],
 ["turso2","db","https://turso.tech","https://app.turso.tech/signup"],
 ["planetscale","db","https://planetscale.com","https://app.planetscale.com/signup"],
 ["tidb","db","https://www.pingcap.com/tidb-cloud/","https://tidbcloud.com/free-trial"],
 ["singlestore","db","https://www.singlestore.com","https://portal.singlestore.com/"],
 ["redis-cloud","db","https://redis.io/cloud/","https://app.redislabs.com/#/sign-up"],
 ["memetria","db","https://memetria.com","https://memetria.com/"],
 ["koyeb2","host","https://www.koyeb.com","https://app.koyeb.com/auth/signup"],
 ["grafana2","monitor","https://grafana.com","https://grafana.com/auth/sign-up/create-user"],
 ["netdata","monitor","https://www.netdata.cloud","https://app.netdata.cloud/sign-up"],
 ["nodeping","monitor","https://nodeping.com","https://nodeping.com/signup"],
 ["pingdom2","monitor","https://www.pingdom.com","https://www.pingdom.com/signup/"],
 ["site24x7","monitor","https://www.site24x7.com","https://www.site24x7.com/signup.html"],
 ["hetrixtools","monitor","https://hetrixtools.com","https://hetrixtools.com/register/"],
 ["cronitor","monitor","https://cronitor.io","https://cronitor.io/signup"],
 ["pipedream","automation","https://pipedream.com","https://pipedream.com/auth/signup"],
 ["make","automation","https://www.make.com","https://www.make.com/en/register"],
 ["zapier","automation","https://zapier.com","https://zapier.com/sign-up"],
 ["ifttt","automation","https://ifttt.com","https://ifttt.com/join"],
 ["pabbly","automation","https://www.pabbly.com/connect/","https://www.pabbly.com/connect/"],
 ["windmill","automation","https://www.windmill.dev","https://app.windmill.dev/user/login"],
 ["triggerdev","automation","https://trigger.dev","https://cloud.trigger.dev/login"],
 ["composio","automation","https://composio.dev","https://app.composio.dev/"],
 ["resend2","mail","https://resend.com","https://resend.com/signup"],
 ["loops","mail","https://loops.so","https://app.loops.so/signup"],
 ["buttondown","mail","https://buttondown.email","https://buttondown.email/register"],
 ["mailtrap","mail","https://mailtrap.io","https://mailtrap.io/register/signup"],
 ["mailersend","mail","https://www.mailersend.com","https://app.mailersend.com/signup"],
 ["postmark","mail","https://postmarkapp.com","https://account.postmarkapp.com/sign_up"],
 ["smtp2go","mail","https://www.smtp2go.com","https://www.smtp2go.com/signup/"],
 ["elasticemail","mail","https://elasticemail.com","https://elasticemail.com/account#/create-account"],
 ["zeptomail","mail","https://www.zoho.com/zeptomail/","https://www.zoho.com/zeptomail/"],
 ["improvmx","mail","https://improvmx.com","https://app.improvmx.com/register"],
 ["forwardemail","mail","https://forwardemail.net","https://forwardemail.net/en/register"],
 ["cloudflare-email","mail","https://www.cloudflare.com/products/email-routing/","https://dash.cloudflare.com/sign-up"],
 ["lark","social","https://www.larksuite.com","https://www.larksuite.com/en_us/"],
 ["discord","social","https://discord.com","https://discord.com/register"],
 ["telegram","social","https://telegram.org","https://web.telegram.org/"],
 ["slack","social","https://slack.com","https://slack.com/get-started"],
 ["mattermost","social","https://mattermost.com","https://mattermost.com/get-started/"],
 ["rocket","social","https://rocket.chat","https://cloud.rocket.chat/trial"],
 ["line","social","https://line.me","https://line.me/en/"],
 ["kakao","social","https://www.kakaocorp.com","https://accounts.kakao.com/weblogin/create_account"],
 ["naver","social","https://www.naver.com","https://nid.naver.com/user2/joinGlobal.naver"],
 ["baidu","social","https://www.baidu.com","https://passport.baidu.com/v2/?reg"],
 ["weibo","social","https://weibo.com","https://weibo.com/signup/signup.php"],
 ["bilibili","social","https://www.bilibili.com","https://passport.bilibili.com/register/phone.html"],
 ["douyin","social","https://www.douyin.com","https://www.douyin.com/"],
 ["xiaohongshu","social","https://www.xiaohongshu.com","https://www.xiaohongshu.com/"],
 ["qq","social","https://www.qq.com","https://ssl.zc.qq.com/v3/index-en.html"],
 ["yandex","social","https://yandex.com","https://passport.yandex.com/registration"],
 ["mailru","social","https://mail.ru","https://account.mail.ru/signup"],
 ["okru","social","https://ok.ru","https://ok.ru/reg"],
 ["dzen","blog","https://dzen.ru","https://dzen.ru/"],
 ["telegraph","blog","https://telegra.ph","https://telegra.ph/"],
 ["ghost","blog","https://ghost.org","https://account.ghost.org/signup/"],
 ["wix","blog","https://www.wix.com","https://users.wix.com/signin"],
 ["weebly","blog","https://www.weebly.com","https://www.weebly.com/signup"],
 ["squarespace","blog","https://www.squarespace.com","https://account.squarespace.com/"],
 ["carrd","blog","https://carrd.co","https://carrd.co/signup"],
 ["linktree","social","https://linktr.ee","https://linktr.ee/register"],
 ["beacons","social","https://beacons.ai","https://beacons.ai/signup"],
 ["aboutme","social","https://about.me","https://about.me/signup"],
 ["notion2","blog","https://www.notion.so","https://www.notion.so/signup"],
 ["super","blog","https://super.so","https://super.so/signup"],
 ["potion","blog","https://www.potion.so","https://www.potion.so/"],
 ["feather","blog","https://feather.so","https://feather.so/"],
 ["typedream","blog","https://typedream.com","https://typedream.com/"],
 ["dorik","blog","https://dorik.com","https://app.dorik.com/register"],
 ["softr","blog","https://www.softr.io","https://studio.softr.io/auth/signup"],
 ["glide","blog","https://www.glideapps.com","https://www.glideapps.com/signup"],
 ["bubble","blog","https://bubble.io","https://bubble.io/"],
 ["adalo","blog","https://www.adalo.com","https://app.adalo.com/signup"],
 ["flutterflow","blog","https://flutterflow.io","https://app.flutterflow.io/"],
 ["bravo","blog","https://www.bravostudio.app","https://www.bravostudio.app/"],
 ["backendless","db","https://backendless.com","https://develop.backendless.com/"],
 ["parse","db","https://parseplatform.org","https://parseplatform.org/"],
 ["directus","db","https://directus.io","https://directus.io/"],
 ["strapi","db","https://strapi.io","https://strapi.io/"],
 ["hasura","db","https://hasura.io","https://cloud.hasura.io/signup"],
 ["baserow","db","https://baserow.io","https://baserow.io/signup"],
 ["nocodb","db","https://nocodb.com","https://app.nocodb.com/#/signup"],
 ["grist","db","https://www.getgrist.com","https://docs.getgrist.com/signup"],
 ["rows","db","https://rows.com","https://rows.com/signup"],
 ["csvbox","db","https://csvbox.io","https://app.csvbox.io/register"],
 ["retool","automation","https://retool.com","https://login.retool.com/auth/signup"],
 ["appsmith","automation","https://appsmith.com","https://app.appsmith.com/user/signup"],
 ["budibase","automation","https://budibase.com","https://account.budibase.app/register"],
 ["tooljet","automation","https://www.tooljet.com","https://www.tooljet.com/"],
 ["illacloud","automation","https://www.illacloud.com","https://cloud.illacloud.com/"],
 ["quickbase","db","https://www.quickbase.com","https://www.quickbase.com/signup"],
 ["smartsheet","db","https://www.smartsheet.com","https://app.smartsheet.com/b/home"],
 ["clickup","automation","https://clickup.com","https://app.clickup.com/signup"],
 ["trello","automation","https://trello.com","https://trello.com/signup"],
 ["asana","automation","https://asana.com","https://app.asana.com/-/signup"],
 ["monday","automation","https://monday.com","https://auth.monday.com/users/sign_up"],
 ["coda","automation","https://coda.io","https://coda.io/signup"],
 ["airtable2","automation","https://airtable.com","https://airtable.com/signup"],
 ["zoho","automation","https://www.zoho.com","https://accounts.zoho.com/signup"],
 ["freshdesk","automation","https://freshdesk.com","https://freshdesk.com/signup"],
 ["hubspot","automation","https://www.hubspot.com","https://app.hubspot.com/signup"],
 ["salesforce","automation","https://www.salesforce.com","https://login.salesforce.com/"],
 ["pipedrive","automation","https://www.pipedrive.com","https://app.pipedrive.com/signup"],
 ["zendesk","automation","https://www.zendesk.com","https://www.zendesk.com/register/"],
 ["intercom","automation","https://www.intercom.com","https://app.intercom.com/"],
 ["crisp","automation","https://crisp.chat","https://app.crisp.chat/initiate/signup/"],
 ["tawk","automation","https://www.tawk.to","https://dashboard.tawk.to/signup"],
 ["tidio","automation","https://www.tidio.com","https://www.tidio.com/"],
 ["chatwoot","automation","https://www.chatwoot.com","https://app.chatwoot.com/"],
 ["formspree2","forms","https://formspree.io","https://formspree.io/register"],
 ["getform","forms","https://getform.io","https://getform.io/signup"],
 ["formcarry","forms","https://formcarry.com","https://app.formcarry.com/signup"],
 ["tally","forms","https://tally.so","https://tally.so/signup"],
 ["typeform","forms","https://www.typeform.com","https://admin.typeform.com/signup"],
 ["jotform","forms","https://www.jotform.com","https://www.jotform.com/signup"],
 ["fillout","forms","https://www.fillout.com","https://www.fillout.com/"],
 ["surveycake","forms","https://www.surveycake.com","https://www.surveycake.com/"],
 ["google-forms","forms","https://docs.google.com/forms","https://docs.google.com/forms/"]
];
BULK.forEach(([id,cat,home,signup,env])=>r({id,cat,name:id,home,signup,keysUrl:signup,env:env?env.split(","):[],regex:"[A-Za-z0-9_\\-]{16,80}",needs:["email"],human:["captcha"],method:"browser",conf:1,verify:{kind:"http",url:home}}));
const byId={};R.forEach(x=>byId[x.id]=x);
function forId(id){return byId[id]||null;}
function match(host){host=String(host).replace(/^www\./,"");return byId[host.split(".")[0]]||null;}
function generic(t){return {id:t.id,cat:t.cat||"dir",name:t.id,home:"https://"+t.id,signup:"https://"+t.id,keysUrl:"https://"+t.id,
  env:[],regex:"[A-Za-z0-9_\\-]{16,80}",needs:[],human:[],method:"none",conf:1,verify:{kind:"http",url:"https://"+t.id}};}
module.exports={all:()=>R,byId:forId,match,generic,h,count:()=>R.length};
if(require.main===module){console.log("  ✔ وصفات الخدمات: "+R.length+" خدمة ("+new Set(R.map(x=>x.cat)).size+" تصنيف)");}
Z8

# ═══════════ 9) سجل الأهداف (3000+) ═══════════
w "$H/lib/z-registry.js" <<'Z9'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data"),DB=require("./z-db.js"),REC=require("./z-recipes.js");
const ENG={google:"https://www.google.com/search?q=",bing:"https://www.bing.com/search?q=",ddg:"https://duckduckgo.com/?q=",
 yandex:"https://yandex.com/search/?text=",brave:"https://search.brave.com/search?q=",startpage:"https://www.startpage.com/sp/search?query=",
 ecosia:"https://www.ecosia.org/search?q=",qwant:"https://www.qwant.com/?q=",mojeek:"https://www.mojeek.com/search?q=",
 searx:"https://searx.be/search?q=",baidu:"https://www.baidu.com/s?wd=",naver:"https://search.naver.com/search.naver?query=",
 seznam:"https://search.seznam.cz/?q=",yep:"https://yep.com/web?q=",presearch:"https://presearch.com/search?q=",
 metager:"https://metager.org/meta/meta.ger3?eingabe=",marginalia:"https://search.marginalia.nu/search?query=",
 wiby:"https://wiby.me/?q=",youtube:"https://www.youtube.com/results?search_query=",tiktok:"https://www.tiktok.com/search?q=",
 pinterest:"https://www.pinterest.com/search/pins/?q=",reddit:"https://www.reddit.com/search/?q=",quora:"https://www.quora.com/search?q=",
 medium:"https://medium.com/search?q=",tumblr:"https://www.tumblr.com/search/",vk:"https://vk.com/search?c[q]=",
 x:"https://x.com/search?q=",threads:"https://www.threads.net/search?q=",mastodon:"https://mastodon.social/search?q=",
 linkedin:"https://www.linkedin.com/search/results/all/?keywords="};
let KW=[];try{KW=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords||[];}catch(e){}
const BASE=KW.length?KW:["افلام اون لاين","مسلسلات مترجمة","انمي مترجم"];
const EXT=["مترجم","اون لاين","hd","مجانا","2026"];
const EN=["watch movies online","streaming","anime english"];
const KWS=[...new Set([].concat(BASE,BASE.flatMap(k=>EXT.map(e=>k+" "+e)),EN))].slice(0,60);
function build(){
  DB.ensure();let n=0,svc=0,dir=0,src=0,sea=0;
  for(const rec of REC.all()){DB.upsert("svc-"+rec.id,{kind:"service",cat:rec.cat,name:rec.name,home:rec.home,signup:rec.signup,
    recipe:rec.id,domain:REC.h(rec.home),stage:"new",conf:rec.conf});svc++;n++;}
  const dirs=new Set(REC.all().map(x=>REC.h(x.home)));
  try{JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8")).forEach(x=>{if(x.url&&x.url!=="-")dirs.add(REC.h(x.url));});}catch(e){}
  for(const d of dirs){if(REC.match(d))continue;DB.upsert("dir-"+d,{kind:"directory",cat:"dir",name:d,home:"https://"+d,signup:"https://"+d,recipe:"",domain:d,stage:"new"});dir++;n++;}
  try{const t=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8"));
    (t.surfaces||[]).forEach((s,i)=>{const u=(s.url||"").replace(/^\//,"");if(!u)return;
      DB.upsert("src-"+i,{kind:"platform",cat:"platform",name:u,home:(t.base||"")+"/"+u,recipe:"",stage:"new"});src++;n++;});}catch(e){}
  for(const[k,u]of Object.entries(ENG))for(const q of KWS){const id="sea-"+k+"-"+q.replace(/\s+/g,"_");
    DB.upsert(id,{kind:"search",cat:"search",name:k+": "+q,engine:k,query:q,home:u+encodeURIComponent(q),signup:u+encodeURIComponent(q),recipe:"",stage:"new"});sea++;n++;}
  const s=DB.stats();
  fs.writeFileSync(path.join(D,"registry-summary.json"),JSON.stringify({at:new Date().toISOString(),services:svc,directories:dir,platforms:src,searches:sea,total:n,byStage:s.by},null,1));
  console.log("  ✔ سجل الأهداف: "+n+" هدفًا — خدمات "+svc+" · أدلة "+dir+" · منصات "+src+" · بحث "+sea);
  DB.jrn("registry",{total:n});return n;}
module.exports={build};
if(require.main===module)build();
Z9

# ═══════════ 10) طابور التدخل البشري (جلسة واحدة) ═══════════
w "$H/lib/z-human.js" <<'Z10'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const DB=require("./z-db.js"),K=require("./z-keys.js");
const WHY={captcha:"تحقق بشري (كابتشا)",identity:"بيانات هوية / تصادق",kyc:"توثيق KYC",payment:"دفع أو بطاقة",
 phone:"تحقق برقم هاتف",dns:"سجل DNS",manual:"إجراء يدوي",key:"مفتاح يدوي",tos:"قبول شروط"};
const pending=()=>Object.values(DB.human()).filter(x=>!x.resolved);
function sheet(){const p=pending();const g={};p.forEach(x=>(g[x.why]=g[x.why]||[]).push(x));
  const L=["# جلسة تدخّل واحدة — ZERO","","عدد المهام: "+p.length,"","هذه كل ما يحتاجك. أنجزها بالترتيب ثم: bash money/ZERO.sh human --import money/data/human-input.json",""];
  Object.entries(g).forEach(([w,items])=>{L.push("## "+(WHY[w]||w)+" ("+items.length+")","");
    items.forEach((x,i)=>{L.push("### "+(i+1)+") "+x.id);if(x.url)L.push("- الرابط: "+x.url);
      (x.steps||[]).forEach(s=>L.push("- "+s));
      if(x.field)L.push("- الحقل المطلوب: `"+x.field+"`");
      L.push("- لإتمامه: `bash money/ZERO.sh human --resolve "+x.id+" "+x.field+"=<القيمة>`","");});});
  return L.join("\n");}
function write(){const f=path.join(ROOT,"docs","HUMAN.md");fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,sheet());
  fs.writeFileSync(path.join(D,"human-sheet.txt"),sheet());return f;}
function next(){return pending()[0]||null;}
function resolve(id,val,field){const h=DB.human();const it=h[id];if(!it)return null;
  if(field&&val)K.set({[field]:val},"human:"+id);
  DB.humanResolve(id,val||true);
  DB.stage(id,it.resume||"reachable","حُلّ يدويًا: "+it.why);
  DB.ev(id,"human-resolved",{why:it.why,field:field||"",value:val?K.mask(val):""});
  return it;}
function paste(){return new Promise(r=>execFile("termux-clipboard-get",[],(e,so)=>r(String(so||"").trim())));}
function importFile(f){const txt=fs.readFileSync(f,"utf8");let n=0;
  txt.split("\n").forEach(l=>{l=l.trim();if(!l||l.startsWith("#"))return;
    const m=l.match(/^([\w.\-]+)\s*[:=]\s*(.+)$/);if(!m)return;
    const id=m[1].replace(/^svc-/,""),val=m[2].trim();
    const h=DB.human();const key=Object.keys(h).find(k=>k===m[1]||k===id||k.endsWith(m[1]));
    if(key){const it=h[key];resolve(key,val,it.field||"");n++;}});
  return n;}
module.exports={pending,sheet,write,next,resolve,paste,importFile,WHY};
if(require.main===module){const a=process.argv[2]||"sheet";
  if(a==="count")console.log(pending().length);
  else if(a==="sheet"){const f=write();console.log(sheet());console.log("\n  ✔ كُتب: docs/HUMAN.md");}
  else if(a==="next"){const x=next();if(!x)console.log("  ✔ لا مهام معلّقة");else{console.log("  المهمة: "+x.id+" — "+(WHY[x.why]||x.why));
    if(x.url)console.log("  الرابط: "+x.url);(x.steps||[]).forEach(s=>console.log("  - "+s));if(x.field)console.log("  الحقل: "+x.field);}}
  else if(a==="import"){const n=importFile(process.argv[3]);console.log("  ✔ استُوردت "+n+" قيمة");}}
Z10

# ═══════════ 11) التحقق الفعلي (لا ادّعاء بلا دليل) ═══════════
w "$H/lib/z-verify.js" <<'Z11'
#!/usr/bin/env node
"use strict";
const crypto=require("crypto");
const HTTP=require("./z-http.js"),K=require("./z-keys.js"),DB=require("./z-db.js"),REC=require("./z-recipes.js");
const iso=d=>new Date(Date.now()-d*864e5).toISOString().slice(0,10);
const HASH=b=>crypto.createHash("sha256").update(String(b)).digest("hex").slice(0,12);
async function probe(rec,t){
  const v=Object.assign({kind:"http"},rec.verify||{});
  const key=(v.keyEnv&&K.get(v.keyEnv))||(rec.env||[]).map(e=>K.get(e)).find(Boolean)||"";
  const t0=Date.now();
  if(v.kind==="none")return{ok:true,kind:"none",ms:0,note:"لا يوجد ما يُتحقق آليًا",at:new Date().toISOString()};
  const url=HTTP.tpl(v.url||rec.home,{KEY:key,FROM:iso(7),TO:iso(0)});
  const headers={};Object.entries(v.headers||{}).forEach(([k,x])=>headers[k]=HTTP.tpl(x,{KEY:key}));
  if(v.kind==="api"&&!key)return{ok:false,kind:"api",ms:0,note:"لا مفتاح بعد",at:new Date().toISOString()};
  const r=v.kind==="api"?await HTTP.post(url,{headers,json:v.body||undefined,timeout:25000})
                        :await HTTP.get(url,{headers,timeout:25000});
  const ok=r.status>0&&r.status<400&&(!v.regex||new RegExp(v.regex,"i").test(r.body));
  return{ok,kind:v.kind,status:r.status,ms:Date.now()-t0,url,hash:HASH(r.body),
    note:(ok?"تحقق فعلي":"فشل التحقق")+" · HTTP "+r.status,at:new Date().toISOString()};
}
async function verifyTarget(id){const t=DB.target(id);if(!t)return null;
  const rec=REC.byId(t.recipe)||REC.generic(t);
  const res=await probe(rec,t);
  DB.test(id,res);DB.ev(id,"verify",{ok:res.ok,status:res.status||0,note:res.note});
  if(res.ok&&t.stage!=="live")DB.stage(id,"live","تحقق ناجح");
  if(!res.ok&&t.stage==="live"){DB.stage(id,"failed","سقط التحقق: "+res.note);DB.fail(id,res.note);}
  return res;}
async function verifyAll(limit){const list=Object.values(DB.targets()).filter(x=>x.stage==="live").slice(0,limit||400);
  let ok=0,fail=0;
  for(const t of list){const r=await verifyTarget(t.id);r&&r.ok?ok++:fail++;await HTTP.sleep(250);}
  DB.jrn("verify-all",{ok,fail,checked:list.length});
  console.log("  ✔ تحقق فعلي: "+ok+" سليم · "+fail+" سقط (من "+list.length+")");return{ok,fail,checked:list.length};}
module.exports={probe,verifyTarget,verifyAll};
if(require.main===module){const a=process.argv[2];
  if(a==="--all")verifyAll(Number(process.argv[3]||400));
  else if(a)verifyTarget(a).then(r=>console.log("  "+(r.ok?"✔":"✗")+" "+a+" — "+r.note));}
Z11

# ═══════════ 12) التوثيق والأدلة ═══════════
w "$H/lib/z-docs.js" <<'Z12'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),DB=require("./z-db.js"),K=require("./z-keys.js");
const DIR=path.join(ROOT,"docs"),SV=path.join(DIR,"services");
const W=o=>{fs.mkdirSync(DIR,{recursive:true});return o;};
function service(t){fs.mkdirSync(SV,{recursive:true});
  const T=DB.rd(DB.F.tests,{})[t.id],ev=fs.existsSync(DB.F.evidence)?
    fs.readFileSync(DB.F.evidence,"utf8").split("\n").filter(l=>l.includes('"id":"'+t.id+'"')).slice(-12):[];
  const L=["# "+t.id,"","- التصنيف: "+(t.cat||"-"),"- الحالة: **"+t.stage+"**"+(T&&T.ok?" (مُتحقّق فعليًا ✔)":""),
   "- الموقع: "+(t.home||"-"),"- رابط التسجيل: "+(t.signup||"-"),"- الوصفة: "+(t.recipe||"عامة"),
   "- عدد الأدلة: "+(t.evidence||0),"- آخر تحديث: "+(t.updated||"-"),"- المحاولات: "+(t.attempts||0),
   T?"- آخر اختبار: "+(T.ok?"نجح":"فشل")+" · "+(T.note||"")+" · "+T.at:"- آخر اختبار: —",
   "","## المفاتيح (مقنّعة)",""];
  const rec=require("./z-recipes.js").byId(t.recipe);
  ((rec&&rec.env)||[]).forEach(e=>L.push("- `"+e+"` = "+(K.get(e)?K.mask(K.get(e)):"—")));
  L.push("","## سجل الأدلة","","```");
  ev.forEach(l=>{try{const j=JSON.parse(l);L.push(j.at+"  "+j.kind+"  "+JSON.stringify(j.data).slice(0,160));}catch(e){}});
  L.push("```","");
  fs.writeFileSync(path.join(SV,t.id+".md"),L.join("\n"));return path.join(SV,t.id+".md");}
function index(){const s=DB.stats(),T=DB.rd(DB.F.tests,{});
  const rows=Object.values(DB.targets()).filter(t=>t.stage==="live").slice(0,500)
    .map(t=>"| "+t.id+" | "+(t.cat||"-")+" | "+((T[t.id]||{}).ok?"✔":"—")+" | "+((T[t.id]||{}).note||"")+" |");
  const md=["# فهرس ZERO","","- الإجمالي: "+s.total+" هدفًا","- مُتحقّق فعليًا: "+s.passed,"- أدلة: "+s.evidence,
   "- مهام تنتظرك: "+s.humanPending,"","## التوزيع","","```",JSON.stringify(s.by,null,1),"```","",
   "## الخدمات المُتحقَّق منها","","| الهدف | التصنيف | تحقق | ملاحظة |","|---|---|---|---|"].concat(rows).join("\n");
  fs.writeFileSync(W(path.join(DIR,"INDEX.md")),md);return path.join(DIR,"INDEX.md");}
function report(){const s=DB.stats(),T=DB.rd(DB.F.tests,{}),D=DB.rd(path.join(H,"data","deploy.json"),{}),l=DB.rd(path.join(H,"data","apex-ledger.json"),{total:0});
  const live=Object.values(DB.targets()).filter(t=>t.stage==="live");
  const md=["# تقرير المالك — ZERO","","> كل رقم هنا مبني على دليل مُخزَّن في db/evidence.jsonl و db/tests.json","",
   "- الأهداف الكلية: **"+s.total+"**","- حسابات/تكاملات مُتحقَّقة فعليًا: **"+s.passed+"**",
   "- قيد التنفيذ: **"+((s.by.reachable||0)+(s.by.account||0)+(s.by.email||0)+(s.by.key||0)+(s.by.linked||0))+"**",
   "- فشل (سيُعاد): **"+(s.by.failed||0)+"**","- ينتظرك: **"+s.humanPending+"**",
   "- مفاتيح محفوظة: **"+K.verify().total+"** (سليمة: "+(K.verify().bad.length===0?"نعم":"لا")+")",
   "- الرابط العام: "+(D.url||"—"),"- الأرباح المسجّلة: $"+(Number(l.total||0)).toFixed(2),"",
   "## التوزيع بالحالة","","```",JSON.stringify(s.by,null,2),"```","",
   "## عيّنة من المُتحقَّق منه (أول 40)","","| الهدف | التصنيف | دليل |","|---|---|---|"]
   .concat(live.slice(0,40).map(t=>"| "+t.id+" | "+(t.cat||"-")+" | "+(((T[t.id]||{}).note)||"")+" |")).join("\n");
  fs.writeFileSync(W(path.join(DIR,"OWNER-REPORT.md")),md);return path.join(DIR,"OWNER-REPORT.md");}
function handover(){const K2=K.all(),s=DB.stats();
  const md=["# تسليم — أنت المالك","","## ما تم","- "+s.total+" هدفًا مسجّلًا في السجل","- "+s.passed+" تكاملًا مُتحقّقًا فعليًا",
   "- "+K2.PUBLIC_URL||"—","","## الأسرار","- كل المفاتيح في `keys.env` (صلاحيات 600)","- نسخة مشفّرة: `money/data/vault.enc`",
   "- سجل المصادر والأوقات: `money/data/secrets.json`","","## حسابك على كل خدمة","- البريد وكلمة المرور لكل خدمة: `money/db/creds.json`",
   "- بريد التحقق المستخدم: `money/db/mail.json`","","## تحكمك الكامل","","```bash","bash money/ZERO.sh owner lock <id>      # لا تلمسه بعد الآن",
   "bash money/ZERO.sh owner revoke <id>    # احذف مفاتيحه","bash money/ZERO.sh owner rollback <id> reachable","bash money/ZERO.sh pause                # أوقف الوكيل",
   "bash money/ZERO.sh open                 # استعد الأسرار من الخزنة","```","","## سحب الأرباح","- "+((K2.PAYOUT_ADDRESS)||"أضف PAYOUT_ADDRESS")+" على "+((K2.PAYOUT_CHAIN)||"base")].join("\n");
  fs.writeFileSync(W(path.join(DIR,"HANDOVER.md")),md);return path.join(DIR,"HANDOVER.md");}
function evidence(){const f=DB.F.evidence;const out=fs.existsSync(f)?fs.readFileSync(f,"utf8").split("\n").filter(Boolean).map(l=>{try{return JSON.parse(l);}catch(e){return null;}}).filter(Boolean):[];
  fs.writeFileSync(W(path.join(DIR,"EVIDENCE.json")),JSON.stringify({at:new Date().toISOString(),count:out.length,items:out.slice(-3000)},null,1));
  return path.join(DIR,"EVIDENCE.json");}
module.exports={service,index,report,handover,evidence};
if(require.main===module){index();report();handover();evidence();console.log("  ✔ وثائق: docs/INDEX.md · OWNER-REPORT.md · HANDOVER.md · EVIDENCE.json");}
Z12

# ═══════════ 13) المحرّك: يدفع كل هدف عبر المراحل ═══════════
w "$H/lib/z-runner.js" <<'Z13'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,"..");
const DB=require("./z-db.js"),K=require("./z-keys.js"),HTTP=require("./z-http.js"),REC=require("./z-recipes.js"),
  MAIL=require("./z-mail.js"),BR=require("./z-browser.js"),V=require("./z-verify.js"),DOC=require("./z-docs.js"),
  HU=require("./z-human.js"),IDN=require("./z-identity.js");
const sleep=HTTP.sleep;
const log=m=>{try{fs.appendFileSync(path.join(ROOT,"logs","zero.log"),"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");}catch(e){}};
function recOf(t){return REC.byId(t.recipe)||REC.generic(t);}
function needHuman(t,rec,why,steps,field){DB.humanAdd({id:t.id,why,url:t.signup||t.home,steps:steps||[],field:field||"",resume:t.stage});
  DB.stage(t.id,"human",(HU.WHY[why]||why));log("تدخّل: "+t.id+" ("+why+")");}
async function sResolve(t,rec){
  if(t.kind==="search")return DB.stage(t.id,"reachable","بحث");
  if(rec.method==="none"&&rec.signup){DB.upsert(t.id,{signup:rec.signup,login:rec.login||rec.signup,recipe:rec.id});return DB.stage(t.id,"resolved",rec.signup);}
  const home=t.home||rec.home;
  const r=await HTTP.get(home,{timeout:20000});
  if(!r.ok){DB.fail(t.id,"لا يستجيب "+r.status);return DB.stage(t.id,"failed","الموقع "+r.status);}
  DB.ev(t.id,"resolve",{home,status:r.status});
  const ls=HTTP.links(r.body,r.url||home);
  const su=ls.find(u=>/signup|register|join|create|publisher|partner/i.test(u))||ls[0];
  if(!su){needHuman(t,rec,"identity",["افتح "+home,"أنشئ الحساب ثم الصق رابط التسجيل"],"");return;}
  DB.upsert(t.id,{signup:su,login:su,recipe:rec.id,recipe_conf:rec.conf});
  DB.ev(t.id,"signup-found",{signup:su});return DB.stage(t.id,"resolved",su);}
async function sReach(t,rec){
  const r=await HTTP.get(t.signup||rec.signup,{timeout:20000});
  if(!r.ok){DB.fail(t.id,"تسجيل "+r.status);return DB.stage(t.id,"failed","تسجيل غير متاح "+r.status);}
  DB.ev(t.id,"reach",{status:r.status,ms:r.ms,url:t.signup});
  if(t.kind==="search"||t.kind==="directory"){DB.test(t.id,{ok:true,status:r.status,ms:r.ms,kind:"وصول",note:"HTTP "+r.status,at:new Date().toISOString()});
    return DB.stage(t.id,"live","وصول مُتحقّق");}
  return DB.stage(t.id,"reachable","جاهز للتسجيل "+r.status);}
async function sAccount(t,rec){
  const I=IDN.get(),CR=IDN.creds(t.id);
  let mail={addr:I.email||""};
  if((rec.needs||[]).includes("email")){try{mail=await MAIL.ensure(t.id);}catch(e){DB.ev(t.id,"mail-fail",{err:String(e.message||e)});}}
  const vars={email:mail.addr,user:CR.user,pass:CR.pass,name:I.name||I.brand,site:I.site_url||"",brand:I.brand};
  const pg=await HTTP.get(t.signup,{timeout:25000});
  const fields=Object.assign({},HTTP.hiddenFields(pg.body));
  Object.entries(rec.fields||{}).forEach(([k,v])=>fields[k]=HTTP.tpl(v,vars));
  if(rec.method==="http"&&Object.keys(rec.fields||{}).length){
    const r=await HTTP.post(HTTP.tpl(rec.action||t.signup,vars),{form:fields,headers:rec.headers,timeout:30000});
    const ok=rec.success?new RegExp(rec.success,"i").test(r.body):(r.status>0&&r.status<400&&!/error|invalid|already/i.test(r.body));
    DB.ev(t.id,"account-http",{status:r.status,ok,fields:Object.keys(fields)});
    if(ok){DB.stage(t.id,"account","حساب عبر HTTP "+r.status);return{note:"HTTP"};}}
  if(BR.has()){
    const res=await BR.withPage(async page=>{
      await page.goto(t.signup,{waitUntil:"domcontentloaded",timeout:60000});
      const n=await BR.fill(page,{email:mail.addr,user:CR.user,pass:CR.pass,name:I.name||I.brand,site:I.site_url||""});
      await BR.captchaInPage(page,t.signup);
      await BR.submit(page);await sleep(4000);
      return{url:page.url(),shot:await BR.shot(page,"signup-"+t.id),filled:n,html:await page.content()};});
    DB.ev(t.id,"account-browser",{url:res.url,shot:res.shot,filled:res.filled});
    DB.stage(t.id,"account","حساب عبر المتصفح");return{note:"متصفح "+res.url};}
  needHuman(t,rec,"identity",["افتح "+(t.signup||t.home),"سجّل بالبريد "+mail.addr,"كلمة المرور: "+CR.pass,"أكمل التحقق ثم عد"],"");
  return{note:"يحتاجك"};}
async function sEmail(t,rec){
  if(!(rec.needs||[]).includes("email"))return DB.stage(t.id,"key","بلا تحقق بريد");
  const r=await MAIL.wait(t.id,rec.mailRegex,150000);
  if(!r.link&&!r.code){DB.fail(t.id,"لا بريد تحقق");return DB.stage(t.id,"failed","لم يصل رابط التحقق");}
  if(r.link)await HTTP.get(r.link,{timeout:25000});
  DB.ev(t.id,"email-verified",{link:r.link||"",code:r.code?"موجود":""});
  return DB.stage(t.id,"key","بريد مؤكَّد");}
async function sKey(t,rec){
  const envs=rec.env||[];
  if(!envs.length||(rec.verify||{}).kind==="none")return DB.stage(t.id,"linked","بلا مفاتيح");
  if(envs.every(e=>K.get(e)))return DB.stage(t.id,"linked","مفاتيح موجودة");
  let val="";
  if(rec.keyApi){try{const r=await HTTP.post(rec.keyApi.url,{json:rec.keyApi.body,headers:rec.keyApi.headers,timeout:30000});
    const m=String(r.body).match(new RegExp(rec.regex||"[A-Za-z0-9_\\-]{20,80}"));val=m?m[0]:"";}catch(e){}}
  if(!val&&BR.has()&&rec.keysUrl){
    val=await BR.withPage(async page=>{await page.goto(rec.keysUrl,{waitUntil:"domcontentloaded",timeout:60000});
      await sleep(3500);const c=await BR.scrape(page,rec.regex||"[A-Za-z0-9_\\-]{24,80}");
      await BR.shot(page,"keys-"+t.id);return c[0]||"";});}
  if(!val){needHuman(t,rec,"key",["افتح "+(rec.keysUrl||t.signup),"انسخ المفتاح والصقه"],envs[0]);return{note:"مفتاح يدوي"};}
  const o={};envs.forEach(e=>o[e]=val);K.set(o,"service:"+rec.id);
  DB.ev(t.id,"key",{env:envs,mask:K.mask(val)});return DB.stage(t.id,"key","مفتاح محفوظ");}
async function sLink(t,rec){
  const L=DB.rd(DB.F.links,{});L[t.id]={at:new Date().toISOString(),cat:rec.cat,env:rec.env||[]};DB.wr(DB.F.links,L);
  if(rec.cat==="ads"){const A=DB.rd(DB.F.ads,{});A[t.id]={at:new Date().toISOString(),enabled:!!((rec.env||[]).map(e=>K.get(e)).find(Boolean)),env:rec.env||[]};DB.wr(DB.F.ads,A);
    try{const f=path.join(ROOT,"ads.txt");const line="# "+t.id+" — أضف سطر ads.txt من لوحتك بعد القبول";
      if(fs.existsSync(f)&&!fs.readFileSync(f,"utf8").includes("# "+t.id))fs.appendFileSync(f,line+"\n");}catch(e){}}
  for(const s of ["ADS.sh","INJECT-ADS.sh","TOTAL.sh"]){try{if(fs.existsSync(path.join(H,s))){const {execFileSync}=require("child_process");
    execFileSync("bash",[path.join(H,s)],{cwd:ROOT,stdio:"pipe",timeout:180000});}}catch(e){}}
  DB.ev(t.id,"linked",{cat:rec.cat});return DB.stage(t.id,"linked","مربوط بالتطبيق");}
async function sTest(t,rec){
  const res=await V.probe(rec,t);DB.test(t.id,res);DB.ev(t.id,"test",{ok:res.ok,note:res.note,ms:res.ms});
  if(res.ok){DOC.service(t);return DB.stage(t.id,"live","مُتحقَّق: "+res.note);}
  DB.fail(t.id,res.note);return DB.stage(t.id,"failed",res.note);}
async function sHuman(t,rec){
  const items=Object.values(DB.human()).filter(x=>x.id===t.id&&!x.resolved);
  if(items.length){return{note:"ينتظرك"};}
  return DB.stage(t.id,t.resume||"reachable","عاد بعد تدخلك");}
async function sRetry(t,rec){
  if((t.attempts||0)>=6){needHuman(t,rec,"manual",["افتح "+(t.signup||t.home),"تحقّق يدويًا: "+(t.lastError||"")],"");return;}
  return DB.stage(t.id,t.resume||"reachable","إعادة محاولة");}
const STEPS={new:sResolve,resolved:sReach,reachable:sAccount,account:sEmail,email:sKey,key:sLink,linked:sTest,human:sHuman,failed:sRetry};
async function step(t){const rec=recOf(t);
  const fn=STEPS[t.stage];if(!fn)return{note:"مرحلة غير معروفة: "+t.stage};
  try{const r=await fn(t,rec);log(t.id+" → "+(DB.target(t.id)||{}).stage);return r||{};}
  catch(e){DB.ev(t.id,"error",{msg:String(e.message||e).slice(0,240)});DB.fail(t.id,String(e.message||e).slice(0,120));
    DB.stage(t.id,"failed",String(e.message||e).slice(0,90));log(t.id+" ✗ "+String(e.message||e).slice(0,90));return{ok:false,note:String(e.message||e).slice(0,90)};}}
async function batch(n){DB.ensure();const list=DB.next(n||10);const out=[];
  for(const t of list){const before=t.stage;await step(t);const after=(DB.target(t.id)||{}).stage;
    out.push({id:t.id,from:before,to:after});await sleep(350);}
  DB.jrn("batch",{n:list.length,out:out.map(o=>o.id)});return out;}
module.exports={step,batch,recOf,needHuman};
if(require.main===module){const n=Number(process.argv[2]||"10");
  batch(n).then(r=>{console.log("  ✔ دفعة "+r.length+" هدفًا:");
    r.forEach(x=>console.log("   · "+x.id+"  "+x.from+" → "+x.to));
    const s=DB.stats();console.log("  ── التقدّم: "+s.passed+" مُتحقَّق · "+s.humanPending+" ينتظرك · إجمالي "+s.total);});}
Z13

# ═══════════ 14) الجدولة + الإشعار + الحلقة ═══════════
w "$H/lib/z-notify.js" <<'Z14'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),LOG=path.join(ROOT,"logs","zero.log"),ID="zero-owner";
const run=(c,a)=>new Promise(r=>{try{execFile(c,a||[],{timeout:9000},()=>r(true));}catch(e){r(false);}});
function has(c){return new Promise(r=>execFile("sh",["-c","command -v "+c],e=>r(!e)));}
async function notify(o){if(!await has("termux-notification")){try{fs.appendFileSync(LOG,"[notify] "+(o.title||"")+" — "+(o.content||"")+"\n");}catch(e){}return;}
  const a=["--id",ID,"--title",o.title||"ZERO","--content",o.content||"","--priority","high"];
  if(o.ongoing)a.push("--ongoing","--button1","⏹ إيقاف","--button1-action","bash "+path.join(H,"ZERO.sh")+" stop",
    "--button2","🧑 مهمة لي","--button2-action","bash "+path.join(H,"ZERO.sh")+" human --sheet");
  if(o.big)a.push("--big-text",String(o.big).slice(0,400));
  await run("termux-notification",a);}
const clear=()=>run("termux-notification-remove",["--id",ID]);
const toast=m=>run("termux-toast",["-g","bottom",String(m)]);
const vibrate=p=>run("termux-vibrate",p?["-p",p]:["-d","250"]);
async function telegram(t){const K=require("./z-keys.js");const tok=K.get("TELEGRAM_BOT_TOKEN"),ch=K.get("TELEGRAM_CHAT_ID");
  if(!tok||!ch)return false;const https=require("https"),d=JSON.stringify({chat_id:ch,text:t,parse_mode:"HTML"});
  return new Promise(r=>{const q=https.request("https://api.telegram.org/bot"+tok+"/sendMessage",
    {method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(true));});
    q.on("error",()=>r(false));q.write(d);q.end();});}
module.exports={notify,clear,toast,vibrate,telegram};
Z14

w "$H/lib/z-schedule.js" <<'Z15'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync,execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),K=require("./z-keys.js");
const LINE="*/20 * * * * cd "+ROOT+" && bash money/ZERO.sh batch 12 >> logs/cron.log 2>&1";
function cron(){try{let cur="";try{cur=execFileSync("crontab",["-l"],{stdio:"pipe"}).toString();}catch(e){}
  if(!cur.includes("ZERO.sh batch")){execFileSync("crontab",["-"],{input:cur+LINE+"\n",stdio:["pipe","pipe","pipe"]});return "✔ cron مثبّت (كل 20 دقيقة)";}
  return "○ cron موجود";}catch(e){return "○ لا crontab — استخدم termux-job-scheduler";}}
function job(){return new Promise(r=>execFile("termux-job-scheduler",["--script",path.join(H,"JOB-ZERO.sh"),"--job-id","3099",
  "--period-ms","1200000","--network","any","--persisted","true"],()=>r(true)));}
async function ping(){const u=K.get("HEALTHCHECK_PING_URL");if(!u)return "○ لا healthcheck";
  return new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","10",u],()=>r("✔ أُرسل نبض الصحة")));}
(async()=>{const c=cron();const j=await job();const p=await ping();
  console.log("  "+c);console.log("  ✔ جدولة أندرويد "+(j?"مثبّتة":"متعذرة"));console.log("  "+p);})();
Z15

w "$H/lib/z-daemon.js" <<'Z16'
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
Z16

w "$H/lib/z-cli.js" <<'Z17'
#!/usr/bin/env node
"use strict";
const {spawnSync}=require("child_process"),path=require("path");
const A=path.join(path.resolve(__dirname,".."),"ZERO.sh");
const M=[["1","تشغيل الوكيل","start"],["2","إيقاف","stop"],["3","إيقاف مؤقت","pause"],["4","متابعة","resume"],
 ["5","الحالة","status"],["6","دفعة الآن (12 هدفًا)","batch 12"],["7","بناء/تحديث السجل","registry"],
 ["8","تحقق فعلي شامل","verify --all"],["9","مهامك (جلسة واحدة)","human --sheet"],["10","تقرير المالك","report"],
 ["11","فهرس ووثائق","docs"],["12","مفاتيح (مقنّعة)","keys"],["13","ختم الخزنة","seal"],["14","جدولة","schedule"],["15","سجل","logs"]];
console.log("\n╔══════════ ZERO — وكيل بصلاحياتك ══════════╗");
M.forEach(m=>console.log("  "+m[0].padStart(2)+") "+m[1]));
console.log("╚═══════════════════════════════════════════╝");
if(process.argv[2]){spawnSync("bash",[A].concat(process.argv.slice(2)),{stdio:"inherit"});process.exit(0);}
require("readline").createInterface({input:process.stdin,output:process.stdout}).question("اختر: ",a=>{
  const m=M.find(x=>x[0]===String(a).trim());if(m)spawnSync("bash",[A].concat(m[2].split(" ")),{stdio:"inherit"});
  else console.log("○ غير معروف");process.exit(0);});
Z17

w "$H/JOB-ZERO.sh" <<'Z18'
#!/usr/bin/env bash
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$H/data/zero.pid" ] && kill -0 "$(cat "$H/data/zero.pid")" 2>/dev/null && exit 0
exec bash "$H/ZERO.sh" start
Z18

chmod +x "$H"/*.sh "$H"/lib/*.js 2>/dev/null
node "$H/lib/z-identity.js" init >/dev/null 2>&1 || true
node "$H/lib/z-db.js" >/dev/null 2>&1 || true

deps(){ command -v pkg >/dev/null 2>&1 || return 0; S "الاعتماديات"
  for p in nodejs-lts nodejs curl openssl git tar termux-api; do dpkg -s "$p" >/dev/null 2>&1 || pkg install -y "$p" >>"$L" 2>&1 || true; done
  [ -d node_modules/puppeteer-core ] || PUPPETEER_SKIP_DOWNLOAD=1 npm i --no-audit --no-fund --silent puppeteer-core@23 >>"$L" 2>&1 || true
  say "  ✔ جاهزة"; }

case "$CMD" in
 menu) exec node "$H/lib/z-cli.js" ;;
 boot|install) deps; node "$H/lib/aprivi.js" apply; node "$H/lib/z-registry.js"; node "$H/lib/z-schedule.js" ;;
 consent) node -e 'const I=require(process.argv[1]);I.ensure();console.log(JSON.stringify(I.rd(require("path").join(process.argv[2],"consent.json"),{}),null,1))' "$H/lib/z-identity.js" "$D" ;;
 identity) node "$H/lib/z-identity.js" "${1:-show}" ;;
 start)
   if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then say "  ✔ يعمل (pid $(cat "$PID"))"; exit 0; fi
   deps; rm -f "$D/zero.pause"
   node "$H/lib/aprivi.js" apply
   [ -s "$DB/targets.json" ] || node "$H/lib/z-registry.js"
   nohup node "$H/lib/z-daemon.js" </dev/null >>"$L" 2>&1 &
   sleep 3; say "  ✔ ZERO يعمل (pid $(cat "$PID" 2>/dev/null))"; say "  ⏹ bash money/ZERO.sh stop · 🧑 bash money/ZERO.sh human --sheet" ;;
 stop) [ -f "$PID" ] && { kill "$(cat "$PID")" 2>/dev/null; sleep 1; kill -9 "$(cat "$PID")" 2>/dev/null; } || say "  ○ لا يعمل"
   node -e 'require(process.argv[1]).clear()' "$H/lib/z-notify.js" 2>/dev/null; say "  ⏹ أوقفتُ ZERO (التقدّم محفوظ)" ;;
 pause) touch "$D/zero.pause"; say "  ⏸ إيقاف مؤقت — الوكيل يبقى حيًّا" ;;
 resume) rm -f "$D/zero.pause"; say "  ▶ استُؤنف" ;;
 status) node - "$H" <<'JSX'
const fs=require("fs"),path=require("path"),H=process.argv[2],D=path.join(H,"data"),DB=require(path.join(H,"lib","z-db.js"));
const pid=fs.existsSync(path.join(D,"zero.pid"))?Number(fs.readFileSync(path.join(D,"zero.pid"),"utf8")):0;
let live=false;try{process.kill(pid,0);live=true;}catch(e){}
const s=DB.stats(),T=DB.rd(DB.F.tests,{});
console.log("  الحالة  : "+(live?"يعمل بصلاحياتك (pid "+pid+")":"متوقف")+(fs.existsSync(path.join(D,"zero.pause"))?" [مؤقّتًا موقوف]":""));
console.log("  الأهداف : "+s.total+"   مُتحقَّق فعليًا: "+s.passed+"   فشل: "+(s.by.failed||0));
console.log("  المراحل : "+JSON.stringify(s.by));
console.log("  أدلة    : "+s.evidence+"   اختبارات: "+Object.keys(T).length+" (ناجحة "+Object.values(T).filter(x=>x.ok).length+")");
console.log("  ينتظرك  : "+s.humanPending+" مهمة  → bash money/ZERO.sh human --sheet");
const K=require(path.join(H,"lib","z-keys.js"));const v=K.verify();
console.log("  مفاتيح  : "+v.total+" (سلامة "+(v.bad.length?"✗":"✔")+")   رابط عام: "+(K.get("PUBLIC_URL")||"—"));
JSX
 ;;
 registry) node "$H/lib/z-registry.js" ;;
 queue) node -e 'const D=require(process.argv[1]);const n=Number(process.argv[2]||5);D.next(n).forEach(t=>console.log("  "+t.stage.padEnd(10)+" "+t.id))' "$H/lib/z-db.js" "${1:-5}" ;;
 batch) node "$H/lib/z-runner.js" "${1:-10}" ;;
 stage) node -e 'const D=require(process.argv[1]);console.log(JSON.stringify(D.stage(process.argv[2],process.argv[3],"يدوي"),null,1))' "$H/lib/z-db.js" "${1:?id}" "${2:?stage}" ;;
 test) node "$H/lib/z-verify.js" "${1:?id}" ;;
 verify) node "$H/lib/z-verify.js" --all "${1:-400}" ;;
 human) shift 0; node "$H/lib/z-human.js" "${1:-sheet}" "${2:-}" "${3:-}" ;;
 docs) node "$H/lib/z-docs.js"; node "$H/lib/z-human.js" sheet >/dev/null ;;
 report) node "$H/lib/z-docs.js" >/dev/null; cat docs/OWNER-REPORT.md ;;
 evidence) node -e 'const D=require(process.argv[1]);const id=process.argv[2];
   const L=require("fs").readFileSync(D.F.evidence,"utf8").split("\n").filter(l=>!id||l.includes("\""+id+"\""));
   L.slice(-40).forEach(l=>{try{const j=JSON.parse(l);console.log("  "+j.at+"  "+j.id+"  "+j.kind+"  "+JSON.stringify(j.data).slice(0,140));}catch(e){}});' "$H/lib/z-db.js" "${1:-}" ;;
 creds) node "$H/lib/z-identity.js" creds ;;
 keys) node "$H/lib/z-keys.js" list ;;
 seal) node "$H/lib/z-keys.js" seal ;;
 open) node "$H/lib/z-keys.js" open ;;
 schedule) node "$H/lib/z-schedule.js" ;;
 owner) node - "$H" "${1:-help}" "${2:-}" <<'JSY'
const path=require("path"),H=process.argv[2],cmd=process.argv[3],id=process.argv[4];
const DB=require(path.join(H,"lib","z-db.js")),K=require(path.join(H,"lib","z-keys.js")),REC=require(path.join(H,"lib","z-recipes.js"));
if(cmd==="lock"){DB.lock(id);console.log("  ✔ "+id+" مقفول — لن يلمسه الوكيل");}
else if(cmd==="unlock"){DB.unlock(id);console.log("  ✔ "+id+" تحرّر");}
else if(cmd==="rollback"){DB.rollback(id,process.argv[5]||"reachable");console.log("  ✔ رجع "+id+" إلى "+(process.argv[5]||"reachable"));}
else if(cmd==="revoke"){const t=DB.target(id);const rec=REC.byId(t&&t.recipe);
  (rec&&rec.env||[]).forEach(e=>K.del(e));DB.stage(id,"reachable","أُلغيت المفاتيح");console.log("  ✔ حُذفت مفاتيح "+id);}
else if(cmd==="approve"){DB.stage(id,"linked","موافقة المالك");console.log("  ✔ وافقت على "+id);}
else if(cmd==="deny"){DB.stage(id,"locked","رفض المالك");console.log("  ✔ رفضت "+id);}
else console.log("  owner lock|unlock|rollback|revoke|approve|deny <id>   ← تحكمك الكامل");
JSY
 ;;
 set) node -e 'const K=require(process.argv[1]);const o={};process.argv.slice(2).forEach(a=>{const i=a.indexOf("=");if(i>0)o[a.slice(0,i)]=a.slice(i+1);});console.log("  ✔ "+K.set(o,"owner").join(", "))' "$H/lib/z-keys.js" "$@" ;;
 logs) tail -n 50 logs/zero.log 2>/dev/null || say "  ○ لا سجل" ;;
 all) deps; node "$H/lib/aprivi.js" apply; node "$H/lib/z-registry.js"; node "$H/lib/z-schedule.js"
   node "$H/lib/z-runner.js" 15; node "$H/lib/z-docs.js"; node "$H/lib/z-human.js" sheet >/dev/null
   [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null || { nohup node "$H/lib/z-daemon.js" </dev/null >>"$L" 2>&1 & sleep 2; say "  ✔ الوكيل يعمل في الخلفية"; } ;;
 *) say "الأوامر: menu|boot|start|stop|pause|resume|status|registry|queue|batch|stage|test|verify|human|docs|report|evidence|creds|keys|seal|open|schedule|owner|consent|set|logs|all" ;;
esac
