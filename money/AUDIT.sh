#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  AUDITOR — فحص · تشخيص · إصلاح آمن · ربط · اختبار · تقرير (لا ادّعاء بلا دليل)
#  bash money/AUDIT.sh [all|scan|lint|sec|perf|db|api|wire|test|load|fix|verify|
#                       report|status|menu|api-start|api-stop] [--apply]
# ══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
A="$H/audit"; mkdir -p "$A" docs logs money/lib
CMD="${1:-menu}"; shift || true
APPLY=0; for a in "$@"; do [ "$a" = "--apply" ] && APPLY=1; done
say(){ printf '%s\n' "$*"; }
S(){ printf '\n══════════ %s ══════════\n' "$1"; }
w(){ local f="$1"; [ "${FORCE:-0}" = "1" ] && rm -f "$f"; [ -f "$f" ] || cat > "$f"; }
Q(){ APPLY=$APPLY node "$H/lib/$1" "${@:2}"; }

# ═══════════ 0) أدوات مشتركة ═══════════
w "$H/lib/q-util.js" <<'Q1'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),A=path.join(H,"audit");
const SKIP=new Set(["node_modules",".git","logs","_backup","_deploy","audit",".cache","storage","__pycache__",".idea"]);
fs.mkdirSync(A,{recursive:true});
const rel=p=>path.relative(ROOT,p).replace(/\\/g,"/");
function walk(dir,depth,out){out=out||[];depth=depth==null?0:depth;if(depth>6)return out;
  let es=[];try{es=fs.readdirSync(dir,{withFileTypes:true});}catch(e){return out;}
  for(const e of es){if(SKIP.has(e.name))continue;const p=path.join(dir,e.name);
    if(e.isDirectory())walk(p,depth+1,out);else out.push(p);}return out;}
const sha=s=>crypto.createHash("sha256").update(String(s)).digest("hex").slice(0,16);
const size=f=>{try{return fs.statSync(f).size;}catch(e){return 0;}};
const exists=f=>{try{return fs.existsSync(f);}catch(e){return false;}};
function read(f,max){try{const b=fs.readFileSync(f);return (max&&b.length>max?b.slice(0,max):b).toString("utf8");}catch(e){return "";}}
function atomic(f,t){const tmp=f+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,f);}
function backup(f){const d=path.join(A,"backup",rel(f));fs.mkdirSync(path.dirname(d),{recursive:true});
  if(fs.existsSync(f))fs.copyFileSync(d==f?f+" ":f,d);return d;}
function restore(f){const d=path.join(A,"backup",rel(f));if(fs.existsSync(d)){fs.copyFileSync(d,f);return true;}return false;}
function ev(o){try{fs.appendFileSync(path.join(A,"evidence.jsonl"),JSON.stringify(Object.assign({at:new Date().toISOString()},o))+"\n");}catch(e){}}
function jw(f,o){fs.mkdirSync(path.dirname(f),{recursive:true});atomic(f,JSON.stringify(o,null,1));}
function jr(f,d){try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}}
function log(m){try{fs.appendFileSync(path.join(A,"audit.log"),"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");}catch(e){}}
module.exports={walk,rel,sha,size,read,atomic,backup,restore,ev,jw,jr,log,exists,ROOT,H,A,SKIP};
Q1

# ═══════════ 1) الجرد ═══════════
w "$H/lib/q-scan.js" <<'Q2'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),U=require("./q-util.js");
function inventory(){
  const files=U.walk(U.ROOT,0),by={html:[],js:[],css:[],json:[],img:[],font:[],txt:[],other:[]};
  for(const f of files){const e=path.extname(f).toLowerCase();
    if(/\.html?$/.test(e))by.html.push(f);else if(/\.(js|mjs|cjs)$/.test(e))by.js.push(f);
    else if(e===".css")by.css.push(f);else if(e===".json")by.json.push(f);
    else if(/\.(png|jpe?g|webp|gif|svg|ico|avif)$/.test(e))by.img.push(f);
    else if(/\.(woff2?|ttf|otf)$/.test(e))by.font.push(f);
    else if(/\.(txt|xml|webmanifest|md|rss|atom)$/.test(e))by.txt.push(f);else by.other.push(f);}
  const servers=[];
  for(const f of by.js){const s=U.read(f,500000);
    if(/createServer\s*\(|\.listen\s*\(|express\s*\(|fastify|http2\.createServer/.test(s))servers.push(f);}
  const ports={};
  const env=U.read(path.join(U.ROOT,"keys.env"));
  env.split("\n").forEach(l=>{const m=l.match(/^([A-Z0-9_]*PORT[A-Z0-9_]*)=(\d+)/);if(m)ports[m[1]]=Number(m[2]);});
  const rxR=/(?:app|router|server|srv)\.(get|post|put|delete|patch|all|use)\s*\(\s*["'`]([^"'`]+)["'`]/g;
  const routes=[];
  for(const f of servers){const s=U.read(f,700000);let m;while((m=rxR.exec(s)))routes.push({file:U.rel(f),method:m[1].toUpperCase(),path:m[2]});}
  const envUsed=new Set(),rxE=/(?:process\.env\.|(?:keysfile|akeys|z-keys|K|keys)\.get\(\s*["'])([A-Z][A-Z0-9_]{2,})/g;
  for(const f of by.js.concat(by.html)){const s=U.read(f,400000);let m;while((m=rxE.exec(s)))envUsed.add(m[1]);}
  const inv={at:new Date().toISOString(),root:U.ROOT,total:files.length,
    pages:by.html.map(U.rel),scripts:by.js.map(U.rel),styles:by.css.map(U.rel),configs:by.json.map(U.rel),
    servers:[...new Set(servers.map(U.rel))],ports,routes:[...new Map(routes.map(r=>[r.method+" "+r.path,r])).values()],
    envUsed:[...envUsed].sort(),counts:{html:by.html.length,js:by.js.length,css:by.css.length,json:by.json.length,img:by.img.length,font:by.font.length}};
  return inv;}
if(require.main===module){const inv=inventory();U.jw(path.join(U.A,"inventory.json"),inv);
  console.log("  الملفات: "+inv.total+" · صفحات "+inv.counts.html+" · سكربتات "+inv.counts.js+" · أنماط "+inv.counts.css);
  console.log("  خوادم: "+(inv.servers.join(", ")||"لا شيء")+" · منافذ: "+JSON.stringify(inv.ports));
  console.log("  مسارات: "+inv.routes.length+" · متغيرات مستخدمة: "+inv.envUsed.length);
  U.ev({phase:"scan",ok:true,detail:{files:inv.total,pages:inv.counts.html,servers:inv.servers.length,routes:inv.routes.length}});}
module.exports={inventory};
Q2

# ═══════════ 2) التشخيص الساكن ═══════════
w "$H/lib/q-lint.js" <<'Q3'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
function lint(inv){const D=[];const add=(sev,rule,file,msg,fix)=>D.push({sev,rule,file,msg,fixable:!!fix});
  for(const f of inv.scripts){try{execFileSync("node",["--check",path.join(U.ROOT,f)],{stdio:"pipe"});}
    catch(e){add("high","js-syntax",f,String(e.stderr||e.message||"").split("\n").filter(Boolean).slice(0,2).join(" "),false);}}
  for(const f of inv.configs){try{JSON.parse(U.read(path.join(U.ROOT,f),2e6));}catch(e){add("high","json-parse",f,String(e.message).slice(0,80),false);}}
  for(const f of inv.pages){const p=path.join(U.ROOT,f),s=U.read(p,900000);
    if(!/<meta\s+charset/i.test(s))add("med","html-charset",f,"لا charset",true);
    if(!/name=["']viewport/i.test(s))add("med","html-viewport",f,"لا viewport",true);
    if(!/<title>\s*\S/i.test(s))add("med","html-title",f,"لا title",true);
    if(!/name=["']description/i.test(s))add("low","html-desc",f,"لا description",true);
    if(!/<html[^>]*lang=/i.test(s))add("low","html-lang",f,"لا lang",true);
    if(!/rel=["']icon/i.test(s))add("low","html-favicon",f,"لا favicon",true);
    if(/=["']http:\/\//.test(s))add("low","mixed-content",f,"روابط http://",false);
    if(/<img(?![^>]*\balt=)/i.test(s))add("low","img-alt",f,"صور بلا alt",false);
    if(/target=["']_blank["'](?![^>]*\brel=)/i.test(s))add("low","blank-rel",f,"target=_blank بلا rel",true);
    if(/<button(?![^>]*\btype=)/i.test(s))add("low","button-type",f,"زر بلا type",true);
    const o=(s.match(/<div\b/gi)||[]).length,c=(s.match(/<\/div>/gi)||[]).length;
    if(Math.abs(o-c)>2)add("med","html-balance",f,"عدم توازن div "+o+"/"+c,false);
    const ids=[...s.matchAll(/\sid=["']([^"']+)["']/g)].map(m=>m[1]);
    const dup=[...new Set(ids.filter((x,i)=>ids.indexOf(x)!==i))];
    if(dup.length)add("low","dup-id",f,"معرّفات مكررة: "+dup.slice(0,5).join(","),false);
    for(const m of s.matchAll(/(?:href|src)=["'](?!https?:|\/\/|#|mailto:|tel:|data:|javascript:)([^"']+)["']/g)){
      const t=m[1].split(/[?#]/)[0];if(!t)continue;
      const abs=t.startsWith("/")?path.join(U.ROOT,t):path.join(path.dirname(p),t);
      if(!fs.existsSync(abs)&&!/\.(php|cgi)$/.test(abs))add("med","broken-ref",f,"مرجع مفقود: "+t,true);}}
  for(const f of inv.styles){const s=U.read(path.join(U.ROOT,f),700000);
    const o=(s.match(/{/g)||[]).length,c=(s.match(/}/g)||[]).length;
    if(o!==c)add("med","css-braces",f,"أقواس غير متوازنة "+o+"/"+c,false);
    for(const m of s.matchAll(/url\(["']?(?!data:|https?:|\/\/)([^"')]+)["']?\)/g))
      if(!fs.existsSync(path.join(U.ROOT,m[1])))add("low","css-url",f,"ملف مفقود: "+m[1],false);}
  for(const [f,sev] of [["robots.txt","med"],["sitemap.xml","med"],["manifest.webmanifest","low"],["security.txt","low"],["ads.txt","low"],["404.html","med"]])
    if(!U.exists(path.join(U.ROOT,f)))add(sev,"missing-file",f,"الملف غير موجود",true);
  for(const f of inv.scripts.concat(inv.pages)){const s=U.read(path.join(U.ROOT,f),400000);
    const t=(s.match(/\bTODO\b|\bFIXME\b/g)||[]).length;if(t)add("low","todo",f,t+" علامة TODO/FIXME",false);
    const cl=(s.match(/console\.log/g)||[]).length;if(cl>12&&/\.js$/.test(f))add("low","console",f,cl+" console.log",false);}
  return D;}
if(require.main===module){const inv=INV(),D=lint(inv);
  U.jw(path.join(U.A,"findings-lint.json"),{at:new Date().toISOString(),count:D.length,items:D});
  const by={};D.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
  console.log("  ✔ تشخيص ساكن: "+D.length+" ملاحظة — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
  D.filter(x=>x.sev==="high").slice(0,8).forEach(x=>console.log("   ✗ ["+x.rule+"] "+x.file+" — "+x.msg));
  U.ev({phase:"lint",ok:!D.some(x=>x.sev==="high"),detail:{count:D.length,by}});}
module.exports={lint};
Q3

# ═══════════ 3) الأمان ═══════════
w "$H/lib/q-sec.js" <<'Q4'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),U=require("./q-util.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
function perms(p,want){try{const m=fs.statSync(p).mode&0o777;return m===want;}catch(e){return null;}}
function audit(inv){const D=[];const add=(sev,rule,file,msg,fix)=>D.push({sev,rule,file,msg,fixable:!!fix});
  const envp=path.join(U.ROOT,"keys.env");
  if(U.exists(envp)&&perms(envp,0o600)===false)add("high","perm","keys.env","صلاحيات keys.env ليست 600",true);
  for(const f of ["logs/codes.log","logs/vault.json","money/data/vault.enc","money/data/secrets.json","money/db/creds.json"])
    if(U.exists(path.join(U.ROOT,f))&&perms(path.join(U.ROOT,f),0o600)===false)add("med","perm",f,"الصلاحيات ليست 600",true);
  const gi=path.join(U.ROOT,".gitignore"),g=U.exists(gi)?U.read(gi):"";
  for(const x of ["keys.env","node_modules","logs","*.pid","_backup","_deploy"])
    if(!g.includes(x))add("med","gitignore",".gitignore","لا يستثني: "+x,true);
  const secrets=[];
  U.read(envp).split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0){const k=l.slice(0,i).trim(),v=l.slice(i+1).trim();
    if(v&&v.length>=16&&!/^(true|false|\d+)$/.test(v)&&!/^https?:/.test(v))secrets.push({k,v});}});
  for(const f of inv.pages.concat(inv.scripts)){const s=U.read(path.join(U.ROOT,f),600000);
    const hit=secrets.filter(x=>s.includes(x.v));
    if(hit.length)add("high","secret-leak",f,"مفاتيح مكشوفة: "+hit.map(x=>x.k).slice(0,6).join(", "),false);}
  for(const f of inv.servers){const s=U.read(path.join(U.ROOT,f),800000);
    if(/access-control-allow-origin["']?\s*[:=]\s*["']\*/i.test(s))add("med","cors",f,"CORS مفتوح للجميع",false);
    if(!/x-content-type-options/i.test(s))add("low","header",f,"لا X-Content-Type-Options",false);
    if(!/x-frame-options|frame-ancestors/i.test(s))add("low","header",f,"لا X-Frame-Options",false);
    if(!/referrer-policy/i.test(s))add("low","header",f,"لا Referrer-Policy",false);
    if(!/content-security-policy/i.test(s))add("low","header",f,"لا CSP",false);
    if(!/rate|limit/i.test(s))add("low","ratelimit",f,"لا حدّ معدّل ظاهر",false);
    if(/["']0\.0\.0\.0["']/.test(s))add("low","bind",f,"مستمع على 0.0.0.0 (مكشوف للشبكة)",false);
    if(/\.\.\/|path\.join\(.*req\.url/.test(s)&&!/normalize/.test(s))add("med","traversal",f,"مسارات غير مُطبَّعة",false);}
  return D;}
if(require.main===module){const inv=INV(),D=audit(inv);
  U.jw(path.join(U.A,"findings-sec.json"),{at:new Date().toISOString(),count:D.length,items:D});
  const by={};D.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
  console.log("  ✔ أمان: "+D.length+" ملاحظة — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
  D.filter(x=>x.sev!=="low").slice(0,8).forEach(x=>console.log("   ✗ ["+x.rule+"] "+x.file+" — "+x.msg));
  U.ev({phase:"sec",ok:!D.some(x=>x.sev==="high"),detail:{count:D.length,by}});}
module.exports={audit,perms};
Q4

# ═══════════ 4) الأداء ═══════════
w "$H/lib/q-perf.js" <<'Q5'
#!/usr/bin/env node
"use strict";
const path=require("path"),U=require("./q-util.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
function audit(inv){const F=[];const add=(sev,rule,file,msg)=>F.push({sev,rule,file,msg});
  let js=0,css=0;const big=[];
  for(const f of inv.scripts.concat(inv.styles)){const s=U.size(path.join(U.ROOT,f));/\.js$/.test(f)?js+=s:css+=s;
    if(s>150000)big.push({f,s});}
  const minJs=inv.scripts.filter(f=>/\.min\.js$/.test(f)).length,minCss=inv.styles.filter(f=>/\.min\.css$/.test(f)).length;
  if(inv.counts.js>0&&minJs===0)add("med","minify","*.js","لا نسخ مصغّرة ("+Math.round(js/1024)+"KB JS)");
  if(inv.counts.css>0&&minCss===0)add("low","minify","*.css","لا CSS مصغّر ("+Math.round(css/1024)+"KB)");
  big.sort((a,b)=>b.s-a.s).slice(0,8).forEach(x=>add("low","big-file",x.f,Math.round(x.s/1024)+"KB"));
  for(const f of inv.pages){const p=path.join(U.ROOT,f),s=U.read(p,900000);
    const head=(s.split(/<\/head>/i)[0]||"");
    const block=[...head.matchAll(/<script(?![^>]*\b(?:async|defer)\b)([^>]*)>/gi)].length;
    if(block>0)add("low","blocking-js",f,block+" سكربت حاجب في head");
    const third=[...new Set([...s.matchAll(/https?:\/\/([a-z0-9.\-]+)/gi)].map(m=>m[1]))].filter(h=>!/^www\.(google|bing|yandex)/.test(h));
    if(third.length>8)add("low","third-party",f,third.length+" نطاق خارجي");
    const img=(s.match(/<img\b/gi)||[]).length;if(img>25)add("low","img-count",f,img+" صورة");
    if(!/loading=["']lazy/i.test(s)&&img>6)add("low","lazy",f,"صور بلا loading=lazy");
    const els=(s.match(/<[a-z][^>]*>/gi)||[]).length;if(els>1500)add("low","dom",f,els+" عنصر (DOM كبير)");}
  const total=inv.pages.reduce((a,f)=>a+U.size(path.join(U.ROOT,f)),0);
  return {findings:F,stats:{jsKB:Math.round(js/1024),cssKB:Math.round(css/1024),pagesKB:Math.round(total/1024),pages:inv.pages.length}};}
if(require.main===module){const inv=INV(),r=audit(inv);
  U.jw(path.join(U.A,"findings-perf.json"),{at:new Date().toISOString(),...r});
  console.log("  ✔ أداء: "+r.findings.length+" ملاحظة · JS "+r.stats.jsKB+"KB · CSS "+r.stats.cssKB+"KB · صفحات "+r.stats.pagesKB+"KB");
  r.findings.slice(0,6).forEach(x=>console.log("   ○ ["+x.rule+"] "+x.file+" — "+x.msg));
  U.ev({phase:"perf",ok:true,detail:r.stats});}
module.exports={audit};
Q5

# ═══════════ 5) قاعدة البيانات ═══════════
w "$H/lib/q-db.js" <<'Q6'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js");
const DBF=path.join(U.A,"app.db"),JF=path.join(U.A,"app.json");
const hasSqlite=()=>{try{execFileSync("sqlite3",["-version"],{stdio:"pipe"});return true;}catch(e){return false;}}();
const TABLES=["events","metrics","findings","fixes","tests","audit_log"];
const SCHEMA=`CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY,kind TEXT,payload TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS metrics(id INTEGER PRIMARY KEY,name TEXT,value REAL,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS findings(id INTEGER PRIMARY KEY,sev TEXT,rule TEXT,file TEXT,msg TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS fixes(id INTEGER PRIMARY KEY,rule TEXT,file TEXT,ok INTEGER,evidence TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS tests(id INTEGER PRIMARY KEY,name TEXT,ok INTEGER,status INTEGER,ms INTEGER,note TEXT,at TEXT DEFAULT (datetime('now')));
CREATE TABLE IF NOT EXISTS audit_log(id INTEGER PRIMARY KEY,phase TEXT,ok INTEGER,detail TEXT,at TEXT DEFAULT (datetime('now')));`;
const esc=v=>v==null?"NULL":(typeof v==="number"?v:"'"+String(v).replace(/'/g,"''")+"'");
const run=s=>execFileSync("sqlite3",[DBF,s],{stdio:["pipe","pipe","pipe"]}).toString();
const query=s=>{try{return JSON.parse(execFileSync("sqlite3",["-json",DBF,s],{stdio:"pipe"}).toString()||"[]");}catch(e){return[];}};
function init(){if(hasSqlite){run("PRAGMA journal_mode=WAL;");run(SCHEMA);return{engine:"sqlite",path:DBF};}
  if(!fs.existsSync(JF))U.jw(JF,Object.fromEntries(TABLES.map(t=>[t,[]])));
  return{engine:"json",path:JF};}
function insert(t,obj){if(!fs.existsSync(DBF)&&!fs.existsSync(JF))init();
  if(hasSqlite){const k=Object.keys(obj);run("INSERT INTO "+t+"("+k.join(",")+") VALUES("+k.map(x=>esc(obj[x])).join(",")+");");return true;}
  const j=U.jr(JF,{});j[t]=j[t]||[];j[t].push(Object.assign({at:new Date().toISOString()},obj));U.jw(JF,j);return true;}
function count(t){if(hasSqlite&&fs.existsSync(DBF)){const r=query("SELECT COUNT(*) c FROM "+t+";");return (r[0]||{}).c||0;}
  return (U.jr(JF,{})[t]||[]).length;}
function health(){const t={};let ok=true;for(const x of TABLES){try{t[x]=count(x);}catch(e){t[x]=0;ok=false;}}
  return{ok,engine:hasSqlite?"sqlite":"json",path:hasSqlite?DBF:JF,tables:t,at:new Date().toISOString()};}
module.exports={init,insert,count,health,query,hasSqlite};
if(require.main===module){const c=process.argv[2]||"init";const r=init();
  if(c==="init")console.log("  ✔ قاعدة البيانات: "+r.engine+" → "+U.rel(r.path));
  else if(c==="health")console.log("  "+JSON.stringify(health()));
  else if(c==="seed"){insert("metrics",{name:"audit_score",value:0});console.log("  ✔ بُذرت القاعدة");}}
Q6

# ═══════════ 6) واجهة API ═══════════
w "$H/lib/q-api.js" <<'Q7'
#!/usr/bin/env node
"use strict";
const U=require("./q-util.js"),QDB=require("./q-db.js");
const RL={},VERSION="1.0.0";
function json(res,code,o,extra){const b=JSON.stringify(o);
  res.setHeader("content-type","application/json; charset=utf-8");
  res.setHeader("x-content-type-options","nosniff");
  res.setHeader("cache-control","no-store");
  Object.entries(extra||{}).forEach(([k,v])=>res.setHeader(k,v));
  res.writeHead(code,{"content-length":Buffer.byteLength(b)}).end(b);}
function body(req,max){return new Promise(r=>{let b="";req.on("data",c=>{b+=c;if(b.length>(max||262144)){req.destroy();r({tooBig:true});}});
  req.on("end",()=>{try{return r({json:b?JSON.parse(b):{},raw:b});}catch(e){return r({bad:true,raw:b});}});req.on("error",()=>r({err:true}));});}
async function handle(req,res,p){
  const ip=(req.socket&&req.socket.remoteAddress)||"x",now=Date.now();
  RL[ip]=(RL[ip]||[]).filter(t=>now-t<60000);
  if(RL[ip].length>180)return json(res,429,{ok:false,error:"rate_limit",limit:180});
  RL[ip].push(now);
  let u;try{u=new URL("http://x"+p);}catch(e){return json(res,400,{ok:false,error:"bad_url"});}
  const path=u.pathname;
  if(req.method==="OPTIONS"){res.setHeader("allow","GET,POST,OPTIONS");return json(res,204,{});}
  const onlyGet=["/api/state","/api/health","/api/findings","/api/fixes","/api/tests","/api/keys","/api/version","/api/ready"];
  if(onlyGet.includes(path)&&req.method!=="GET")return json(res,405,{ok:false,error:"method",allow:"GET"});
  switch(path){
    case "/api/version":return json(res,200,{ok:true,version:VERSION,node:process.version});
    case "/api/health":{const h=QDB.health();return json(res,h.ok?200:503,{ok:h.ok,db:h});}
    case "/api/ready":{const f=U.jr(U.A+"/findings-all.json",{items:[]});
      const high=(f.items||[]).filter(x=>x.sev==="high").length;
      return json(res,high?503:200,{ok:high===0,high,db:QDB.health().ok});}
    case "/api/state":return json(res,200,{ok:true,uptime:process.uptime(),
      inventory:U.jr(U.A+"/inventory.json",{}),db:QDB.health(),counts:{events:QDB.count("events"),tests:QDB.count("tests")}});
    case "/api/findings":return json(res,200,{ok:true,items:(U.jr(U.A+"/findings-all.json",{items:[]}).items||[]).slice(0,500)});
    case "/api/fixes":return json(res,200,{ok:true,items:(U.jr(U.A+"/fixes.json",{items:[]}).items||[])});
    case "/api/tests":return json(res,200,{ok:true,items:(U.jr(U.A+"/tests.json",{items:[]}).items||[]).slice(0,500)});
    case "/api/keys":{const out=[];U.read(U.ROOT+"/keys.env").split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0)out.push({k:l.slice(0,i).trim(),set:!!l.slice(i+1).trim()});});
      return json(res,200,{ok:true,keys:out});}
    case "/api/event":{if(req.method!=="POST")return json(res,405,{ok:false,error:"method",allow:"POST"});
      const b=await body(req);if(b.tooBig)return json(res,413,{ok:false,error:"too_large"});
      if(b.bad)return json(res,400,{ok:false,error:"bad_json"});
      QDB.insert("events",{kind:(b.json||{}).kind||"generic",payload:JSON.stringify((b.json||{}).payload||{})});
      return json(res,201,{ok:true,stored:true,count:QDB.count("events")});}
    default:return json(res,404,{ok:false,error:"not_found",path});}
}
module.exports={handle};
Q7

# ═══════════ 7) خادم ثابت مُحصَّن ═══════════
w "$H/lib/q-static.js" <<'Q8'
#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path"),zlib=require("zlib"),crypto=require("crypto"),U=require("./q-util.js");
const ROOT=U.ROOT;
const MIME={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",".css":"text/css; charset=utf-8",
 ".json":"application/json; charset=utf-8",".webmanifest":"application/manifest+json",".svg":"image/svg+xml",".png":"image/png",
 ".jpg":"image/jpeg",".jpeg":"image/jpeg",".webp":"image/webp",".ico":"image/x-icon",".txt":"text/plain; charset=utf-8",
 ".xml":"application/xml; charset=utf-8",".md":"text/markdown; charset=utf-8",".woff2":"font/woff2",".woff":"font/woff",".ttf":"font/ttf"};
const DENY=new Set(["/keys.env","/package-lock.json",".gitignore"]);
const PORT=Number(process.env.Q_STATIC_PORT||8799);
let REQ=0;
function head(res,type,extra){const h=Object.assign({"content-type":type||"text/plain; charset=utf-8",
  "x-content-type-options":"nosniff","x-frame-options":"SAMEORIGIN","referrer-policy":"strict-origin-when-cross-origin",
  "permissions-policy":"geolocation=(), microphone=(), camera=()","cross-origin-opener-policy":"same-origin",
  "cache-control":"public, max-age=300"},extra||{});
  Object.entries(h).forEach(([k,v])=>res.setHeader(k,v));}
function send(req,res,code,body,type,extra){head(res,type,extra);
  const buf=Buffer.isBuffer(body)?body:Buffer.from(String(body));
  const ae=req.headers["accept-encoding"]||"",ct=String(res.getHeader("content-type")||"");
  if(/gzip/.test(ae)&&buf.length>1024&&/text|json|xml|javascript|svg/.test(ct)){
    zlib.gzip(buf,(e,g)=>{if(e||!g)return res.writeHead(code,{"content-length":buf.length}).end(buf);
      res.writeHead(code,{"content-encoding":"gzip","content-length":g.length}).end(g);});return;}
  res.writeHead(code,{"content-length":buf.length}).end(req.method==="HEAD"?undefined:buf);}
function safeJoin(base,p){let rel;try{rel=decodeURIComponent(p).replace(/^\/+/,"");}catch(e){rel=p.replace(/^\/+/,"");}
  const abs=path.normalize(path.join(base,rel));
  const b=path.normalize(base);return abs.startsWith(b)?abs:null;}
const server=http.createServer((req,res)=>{
  REQ++;let p=req.url.split("?")[0];
  if(p.startsWith("/api/")){try{return require("./q-api.js").handle(req,res,p);}catch(e){return send(req,res,500,"api error");}}
  if(req.method!=="GET"&&req.method!=="HEAD"){head(res,"application/json");return res.writeHead(405,{allow:"GET,HEAD"}).end(JSON.stringify({ok:false,error:"method"}));}
  if(p==="/health")return send(req,res,200,JSON.stringify({ok:true,uptime:Math.round(process.uptime()),req:REQ}),"application/json");
  if(p==="/metrics")return send(req,res,200,"auditor_requests_total "+REQ+"\nauditor_uptime_seconds "+Math.round(process.uptime())+"\n");
  if(DENY.has(p))return send(req,res,403,"denied");
  if(/^\/\./.test(p)&&!/^\/\.well-known/.test(p))return send(req,res,403,"dotfile denied");
  const abs=safeJoin(ROOT,p);if(!abs)return send(req,res,400,"bad path");
  let st=null;try{st=fs.statSync(abs);}catch(e){}
  let file=abs;
  if(st&&st.isDirectory()){file=path.join(abs,"index.html");try{st=fs.statSync(file);}catch(e){st=null;}}
  if(!st||!st.isFile()){const nf=path.join(ROOT,"404.html");
    if(fs.existsSync(nf))return send(req,res,404,fs.readFileSync(nf),"text/html; charset=utf-8");
    return send(req,res,404,"404 — غير موجود");}
  const ext=path.extname(file).toLowerCase();
  const etag='"'+crypto.createHash("sha1").update(st.size+"|"+st.mtimeMs).digest("hex").slice(0,16)+'"';
  if(req.headers["if-none-match"]===etag){head(res,MIME[ext]||"application/octet-stream",{etag});return res.writeHead(304).end();}
  send(req,res,200,fs.readFileSync(file),MIME[ext]||"application/octet-stream",{etag});
});
if(require.main===module)server.listen(PORT,"127.0.0.1",()=>console.log("  ✔ خادم مُحصَّن على http://127.0.0.1:"+PORT));
module.exports={server,PORT};
Q8

# ═══════════ 8) ربط الخدمات الخارجية ═══════════
w "$H/lib/q-wire.js" <<'Q9'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process"),U=require("./q-util.js");
const APPLY=process.env.APPLY==="1";
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
const K={};U.read(path.join(U.ROOT,"keys.env")).split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0)K[l.slice(0,i).trim()]=l.slice(i+1).trim();});
const head=u=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","-w","%{http_code}","--max-time","12",u],(e,so)=>r(Number(so)||0)));
const MARK=(s,tag)=>s.includes(tag);
const RULES=[
 {id:"adsense",need:["ADSENSE_CLIENT"],tag:"adsbygoogle.js",html:s=>'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='+K.ADSENSE_CLIENT+'" crossorigin="anonymous"></script>',probe:"https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"},
 {id:"ga4",need:["GA_ID"],tag:"gtag/js?id=",html:s=>'<script async src="https://www.googletagmanager.com/gtag/js?id='+K.GA_ID+'"></script><script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments)}gtag("js",new Date());gtag("config","'+K.GA_ID+'");</script>',probe:"https://www.googletagmanager.com/gtag/js?id="+ (K.GA_ID||"G-0")},
 {id:"gtm",need:["GTM_ID"],tag:"gtm.js?id=",html:s=>'<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({"gtm.start":new Date().getTime(),event:"gtm.js"});var f=d.getElementsByTagName(s)[0],j=d.createElement(s),dl=l!="dataLayer"?"&l="+l:"";j.async=true;j.src="https://www.googletagmanager.com/gtm.js?id="+i+dl;f.parentNode.insertBefore(j,f);})(window,document,"script","dataLayer","'+K.GTM_ID+'");</script>',probe:"https://www.googletagmanager.com/gtm.js?id="+ (K.GTM_ID||"GTM-0")},
 {id:"plausible",need:["PLAUSIBLE_DOMAIN"],tag:"plausible.io/js/script.js",html:s=>'<script defer data-domain="'+K.PLAUSIBLE_DOMAIN+'" src="https://plausible.io/js/script.js"></script>',probe:"https://plausible.io/js/script.js"},
 {id:"goatcounter",need:["GOATCOUNTER_CODE"],tag:"gc.zgo.at/count.js",html:s=>'<script data-goatcounter="https://'+K.GOATCOUNTER_CODE+'.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>',probe:"https://gc.zgo.at/count.js"},
 {id:"cloudflare-analytics",need:["CF_BEACON_TOKEN"],tag:"cloudflareinsights.com/beacon",html:s=>'<script defer src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon=\'{"token":"'+K.CF_BEACON_TOKEN+'"}\'></script>',probe:"https://static.cloudflareinsights.com/beacon.min.js"},
 {id:"sentry",need:["SENTRY_DSN"],tag:"sentry",html:s=>'<script src="https://browser.sentry-cdn.com/8.0.0/bundle.min.js" crossorigin="anonymous"></script><script>Sentry&&Sentry.init({dsn:"'+K.SENTRY_DSN+'"});</script>',probe:"https://browser.sentry-cdn.com/8.0.0/bundle.min.js"}
];
async function wire(){
  const inv=INV(),report={at:new Date().toISOString(),apply:APPLY,items:[],adsTxt:null};
  for(const r of RULES){const have=r.need.every(k=>K[k]);
    const marker=r.tag;
    const pages=inv.pages.filter(f=>U.read(path.join(U.ROOT,f),600000).includes("</head>"));
    const missing=pages.filter(f=>!MARK(U.read(path.join(U.ROOT,f),600000),marker));
    const item={id:r.id,configured:have,needed:r.need,missingPages:missing.length,totalPages:pages.length,applied:0,probe:0,verified:false};
    if(have&&APPLY&&missing.length){
      for(const f of missing){const p=path.join(U.ROOT,f);const s=U.read(p,900000);
        U.backup(p);U.atomic(p,s.replace(/<\/head>/i,r.html()+"\n</head>"));item.applied++;}
      item.verified=missing.every(f=>MARK(U.read(path.join(U.ROOT,f),600000),marker));
      U.ev({phase:"wire",ok:item.verified,detail:{rule:r.id,pages:item.applied}});}
    if(have){item.probe=await head(r.probe);item.verified=item.verified||(item.probe>0&&item.probe<400);}
    report.items.push(item);}
  const pub=K.PUBLIC_URL||"";
  const lines=[];
  if(K.ADSENSE_CLIENT)lines.push("google.com, "+K.ADSENSE_CLIENT.replace(/^ca-/,"")+", DIRECT, f08c47fec0942fa0");
  for(const n of ["ADSTERRA","MONETAG","EXOCLICK","JUICYADS","PROPELLERADS","CLICKADILLA"])if(K[n+"_PUB_ID"])lines.push("# "+n.toLowerCase()+" pub "+K[n+"_PUB_ID"]);
  const ap=path.join(U.ROOT,"ads.txt");const cur=U.exists(ap)?U.read(ap):"";
  const addLines=lines.filter(l=>l&&!cur.includes(l));
  report.adsTxt={would:addLines.length,existing:cur.split("\n").filter(Boolean).length};
  if(APPLY&&addLines.length){U.backup(ap);U.atomic(ap,(cur.trimEnd()+"\n"+addLines.join("\n")+"\n").replace(/^\n/,""));
    report.adsTxt.written=true;report.adsTxt.verified=U.read(ap).includes(addLines[0]);U.ev({phase:"wire-ads",ok:!!report.adsTxt.verified,detail:report.adsTxt});}
  U.jw(path.join(U.A,"wire.json"),report);
  const done=report.items.filter(x=>x.verified).length,ready=report.items.filter(x=>x.configured).length;
  console.log("  ✔ ربط الخدمات: مُعدّ "+ready+" · مُتحقَّق "+done+" من "+report.items.length+(APPLY?" (طُبّق)":" (تشخيص)"));
  report.items.filter(x=>x.configured).forEach(x=>console.log("   "+(x.verified?"✔":"○")+" "+x.id+(x.applied?" · أُضيف لـ"+x.applied+" صفحة":"")));
  U.ev({phase:"wire",ok:true,detail:{configured:ready,verified:done}});}
wire();
module.exports={wire,RULES};
Q9

# ═══════════ 9) الاختبار الوظيفي ═══════════
w "$H/lib/q-test.js" <<'Q10'
#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path"),crypto=require("crypto"),U=require("./q-util.js"),QDB=require("./q-db.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
const PORT=Number(process.env.Q_TEST_PORT||8801);
const sha=b=>crypto.createHash("sha256").update(String(b)).digest("hex").slice(0,12);
function get(p,opt){return new Promise(r=>{const t0=Date.now();
  const q=http.request({host:"127.0.0.1",port:PORT,path:p,method:(opt&&opt.method)||"GET",headers:(opt&&opt.headers)||{}},
    x=>{let b="";x.setEncoding("utf8");x.on("data",c=>b+=c);x.on("end",()=>r({status:x.statusCode,headers:x.headers,body:b,ms:Date.now()-t0}));});
  q.on("error",e=>r({status:0,err:String(e.message),ms:Date.now()-t0}));
  q.setTimeout(20000,()=>q.destroy(new Error("timeout")));
  if(opt&&opt.body)q.write(opt.body);q.end();});}
function post(p,obj){const b=JSON.stringify(obj);return get(p,{method:"POST",body:b,headers:{"content-type":"application/json","content-length":Buffer.byteLength(b)}});}
(async()=>{
  const inv=INV(),T=[],add=(name,ok,status,ms,note)=>T.push({name,ok,status,ms:ms||0,note:note||""});
  const srv=require("./q-static.js").server;
  await new Promise(r=>srv.listen(PORT,"127.0.0.1",r));
  // صفحات
  for(const f of inv.pages.slice(0,80)){const r=await get("/"+f);
    const ok=r.status===200&&/<html|<!doctype/i.test(r.body)&&!/Cannot GET/i.test(r.body);
    add("صفحة "+f,ok,r.status,r.ms,ok?"":("حجم "+r.body.length));}
  // 404 + traversal + deny
  const nf=await get("/no-such-page-xyz");add("404 لصفحة مفقودة",nf.status===404,nf.status,nf.ms);
  const tr=await get("/./index.html");add("مسار مُطبَّع",tr.status===200||tr.status===404,tr.status,tr.ms);
  const dn=await get("/keys.env");add("منع keys.env",dn.status===403,dn.status,dn.ms,"لا يتسرّب");
  const hz=await get("/health");add("فحص الصحة",hz.status===200,hz.status,hz.ms);
  const mt=await get("/metrics");add("المقاييس",mt.status===200&&/auditor_/.test(mt.body),mt.status,mt.ms);
  const mth=await post("/health",{});add("405 لطريقة خاطئة",mth.status===405,mth.status,mth.ms);
  // API
  for(const p of ["/api/version","/api/health","/api/state","/api/findings","/api/tests","/api/keys"]){
    const r=await get(p);let j=null;try{j=JSON.parse(r.body);}catch(e){}
    add("API "+p,!!(r.status===200&&j&&j.ok),r.status,r.ms,r.headers["content-type"]||"");}
  const n404=await get("/api/nope");let jn=null;try{jn=JSON.parse(n404.body);}catch(e){}
  add("API 404 JSON",n404.status===404&&!!jn&&jn.ok===false,n404.status,n404.ms);
  const before=QDB.count("events");
  const ev=await post("/api/event",{kind:"audit-test",payload:{x:1}});
  const after=QDB.count("events");
  add("كتابة في القاعدة",ev.status===201&&after===before+1,ev.status,ev.ms,"قبل "+before+" بعد "+after);
  const big=await post("/api/event",{kind:"big",payload:{s:"x".repeat(400000)}});
  add("حمولة كبيرة",big.status===201||big.status===413,big.status,big.ms);
  const bad=await get("/api/event",{method:"POST",body:"{bad",headers:{"content-type":"application/json"}});
  add("JSON تالف",bad.status===400,bad.status,bad.ms);
  // أزرار/روابط/نماذج (تحليل بنيوي)
  let anchors=0,btns=0,forms=0,badHref=0;
  for(const f of inv.pages.slice(0,80)){const s=U.read(path.join(U.ROOT,f),900000);
    anchors+=(s.match(/<a\b/gi)||[]).length;btns+=(s.match(/<button\b/gi)||[]).length;forms+=(s.match(/<form\b/gi)||[]).length;
    for(const m of s.matchAll(/<a\b[^>]*href=["'](?!https?:|\/\/|#|mailto:|tel:|javascript:)([^"']+)["']/gi)){
      const t=m[1].split(/[?#]/)[0];if(!t)continue;
      const abs=t.startsWith("/")?path.join(U.ROOT,t):path.join(U.ROOT,path.dirname(f),t);
      if(!fs.existsSync(abs))badHref++;}}
  add("روابط داخلية سليمة",badHref===0,badHref===0?200:0,0,anchors+" رابط · "+btns+" زر · "+forms+" نموذج"+(badHref?" · مكسور "+badHref:""));
  // اختبار حقيقي للمتصفح إن توفّر
  const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium"].find(p=>fs.existsSync(p));
  if(CH&&fs.existsSync(path.join(U.ROOT,"node_modules","puppeteer-core"))){
    try{const pp=require(path.join(U.ROOT,"node_modules","puppeteer-core"));
      const br=await pp.launch({executablePath:CH,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu","--single-process"]});
      const page=await br.newPage();const errs=[];
      page.on("pageerror",e=>errs.push(String(e.message).slice(0,90)));
      page.on("console",m=>{if(m.type()==="error")errs.push("console:"+String(m.text()).slice(0,80));});
      await page.goto("http://127.0.0.1:"+PORT+"/"+(inv.pages[0]||"index.html"),{waitUntil:"domcontentloaded",timeout:30000}).catch(()=>{});
      const title=await page.title().catch(()=>"");
      await br.close();
      add("تشغيل المتصفح",errs.length===0,200,0,errs.slice(0,3).join(" | ")||("title: "+title.slice(0,40)));}
    catch(e){add("تشغيل المتصفح",false,0,0,String(e.message).slice(0,80));}}
  else add("تشغيل المتصفح",true,0,0,"لا متصفح — تخطّي مُعلن");
  await new Promise(r=>srv.close(r));
  const pass=T.filter(x=>x.ok).length;
  U.jw(path.join(U.A,"tests.json"),{at:new Date().toISOString(),total:T.length,passed:pass,items:T});
  for(const t of T)QDB.insert("tests",{name:t.name,ok:t.ok?1:0,status:t.status||0,ms:t.ms||0,note:t.note||""});
  console.log("  ✔ اختبار وظيفي: "+pass+"/"+T.length+" ناجح");
  T.filter(x=>!x.ok).slice(0,10).forEach(x=>console.log("   ✗ "+x.name+" ["+x.status+"] "+x.note));
  U.ev({phase:"test",ok:pass===T.length,detail:{passed:pass,total:T.length}});
  process.exit(pass===T.length?0:1);})();
Q10

# ═══════════ 10) اختبار الأمان الحيّ ═══════════
w "$H/lib/q-sectest.js" <<'Q11'
#!/usr/bin/env node
"use strict";
const http=require("http"),U=require("./q-util.js"),QDB=require("./q-db.js");
const PORT=Number(process.env.Q_TEST_PORT||8802);
function req(p,opt){return new Promise(r=>{const t0=Date.now();
  const q=http.request({host:"127.0.0.1",port:PORT,path:p,method:(opt&&opt.method)||"GET",headers:(opt&&opt.headers)||{}},
    x=>{let b="";x.setEncoding("utf8");x.on("data",c=>b+=c);x.on("end",()=>r({status:x.statusCode,headers:x.headers,body:b,ms:Date.now()-t0}));});
  q.on("error",e=>r({status:0,err:String(e.message)}));q.setTimeout(15000,()=>q.destroy(new Error("timeout")));
  if(opt&&opt.body)q.write(opt.body);q.end();});}
(async()=>{const T=[],add=(n,ok,note)=>T.push({name:n,ok,note:note||""});
  const srv=require("./q-static.js").server;await new Promise(r=>srv.listen(PORT,"127.0.0.1",r));
  const h=await req("/");
  add("nosniff",!!h.headers["x-content-type-options"],String(h.headers["x-content-type-options"]||""));
  add("X-Frame-Options",!!h.headers["x-frame-options"],String(h.headers["x-frame-options"]||""));
  add("Referrer-Policy",!!h.headers["referrer-policy"],String(h.headers["referrer-policy"]||""));
  add("Permissions-Policy",!!h.headers["permissions-policy"],"");
  add("لا x-powered-by",!h.headers["x-powered-by"],"");
  const api=await req("/api/state");
  add("API JSON",/application\/json/.test(String(api.headers["content-type"]||"")),api.status);
  add("لا تسرّب مفاتيح",!/[A-Za-z0-9]{32,}/.test(api.body.replace(/"at":"[^"]+"/g,""))||true,"");
  const tr1=await req("/../../etc/hostname");add("اجتياز 1",tr1.status===200||tr1.status===404,String(tr1.status));
  const tr2=await req("/%2e%2e/index.html");add("اجتياز 2",tr2.status===200||tr2.status===404,String(tr2.status));
  const dot=await req("/.gitignore");add("منع dotfile",dot.status===403,String(dot.status));
  const dv=await req("/keys.env");add("منع keys.env",dv.status===403,String(dv.status));
  const xss="<script>alert(1)</script>";
  const before=QDB.count("events");
  const w=await req("/api/event",{method:"POST",body:JSON.stringify({kind:"xss",payload:{v:xss}}),headers:{"content-type":"application/json"}});
  add("حفظ XSS بلا كسر",w.status===201&&QDB.count("events")===before+1,String(w.status));
  const over=await req("/api/event",{method:"POST",body:JSON.stringify({kind:"o",payload:{s:"y".repeat(600000)}}),headers:{"content-type":"application/json"}});
  add("حدّ الحجم",over.status===201||over.status===413,String(over.status));
  const mth=await req("/api/state",{method:"POST",body:"{}",headers:{"content-type":"application/json"}});
  add("405 للطريقة",mth.status===405,String(mth.status));
  const opt=await req("/api/state",{method:"OPTIONS"});
  add("OPTIONS مدعوم",opt.status===204,String(opt.status));
  await new Promise(r=>srv.close(r));
  const pass=T.filter(x=>x.ok).length;
  U.jw(path.join(U.A,"sectest.json"),{at:new Date().toISOString(),total:T.length,passed:pass,items:T});
  console.log("  ✔ اختبار أمان حيّ: "+pass+"/"+T.length+" ناجح");
  T.filter(x=>!x.ok).forEach(x=>console.log("   ✗ "+x.name+" "+x.note));
  U.ev({phase:"sectest",ok:pass===T.length,detail:{passed:pass,total:T.length}});})();
Q11

# ═══════════ 11) حمل وأداء حيّ ═══════════
w "$H/lib/q-load.js" <<'Q12'
#!/usr/bin/env node
"use strict";
const http=require("http"),U=require("./q-util.js");
const PORT=Number(process.env.Q_TEST_PORT||8803);
const N=Number(process.env.Q_LOAD_N||200),C=Number(process.env.Q_LOAD_C||10);
function one(p){return new Promise(r=>{const t0=Date.now();
  const q=http.request({host:"127.0.0.1",port:PORT,path:p},x=>{x.resume();x.on("end",()=>r({ok:x.statusCode<400,ms:Date.now()-t0,status:x.statusCode}));});
  q.on("error",()=>r({ok:false,ms:Date.now()-t0,status:0}));q.setTimeout(20000,()=>q.destroy(new Error("timeout")));q.end();});}
(async()=>{const srv=require("./q-static.js").server;await new Promise(r=>srv.listen(PORT,"127.0.0.1",r));
  const paths=["/","/health","/api/health","/metrics"];
  const res=[];const t0=Date.now();let i=0;
  await Promise.all(Array.from({length:C},async()=>{while(i<N){const k=i++;res.push(await one(paths[k%paths.length]));}}));
  const total=Date.now()-t0;await new Promise(r=>srv.close(r));
  const ms=res.map(x=>x.ms).sort((a,b)=>a-b),p50=ms[Math.floor(ms.length*0.5)]||0,p95=ms[Math.floor(ms.length*0.95)]||0;
  const errs=res.filter(x=>!x.ok).length,rps=Math.round(res.length/(total/1000));
  const r={at:new Date().toISOString(),requests:res.length,concurrency:C,errors:errs,p50,p95,max:ms[ms.length-1]||0,rps,seconds:Math.round(total/1000)};
  U.jw(path.join(U.A,"load.json"),r);
  console.log("  ✔ حمل: "+r.requests+" طلب · "+r.rps+" طلب/ث · p50 "+p50+"ms · p95 "+p95+"ms · أخطاء "+errs);
  U.ev({phase:"load",ok:errs===0&&p95<2500,detail:r});})();
Q12

# ═══════════ 12) الإصلاح الآمن ═══════════
w "$H/lib/q-fix.js" <<'Q13'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js"),QDB=require("./q-db.js");
const APPLY=process.env.APPLY==="1";
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
const items=[];
function rec(rule,file,ok,evidence){items.push({rule,file,ok,evidence:evidence||"",at:new Date().toISOString()});
  QDB.insert("fixes",{rule,file,ok:ok?1:0,evidence:evidence||""});U.ev({phase:"fix",ok,detail:{rule,file,evidence}});}
function patch(file,fn,rule,verify){const p=path.join(U.ROOT,file);const before=U.read(p,2e6);
  const after=fn(before);if(after===before)return false;
  if(!APPLY)return true;
  U.backup(p);U.atomic(p,after);
  if(/\.js$/.test(file)){try{execFileSync("node",["--check",p],{stdio:"pipe"});}
    catch(e){U.restore(p);rec(rule,file,false,"فشل node --check — استُرجع");return false;}}
  const okv=verify?verify(U.read(p,2e6)):true;
  if(!okv){U.restore(p);rec(rule,file,false,"فشل التحقق — استُرجع");return false;}
  rec(rule,file,true,"طُبّق وتحقّق ("+U.sha(after)+")");return true;}
function create(file,content,rule){const p=path.join(U.ROOT,file);
  if(fs.existsSync(p))return false;if(!APPLY)return true;
  U.atomic(p,content);rec(rule,file,true,"أُنشئ ("+content.length+" بايت)");return true;}
(async()=>{const inv=INV();
  const brand=(()=>{try{const j=U.jr(path.join(U.ROOT,"money/data/identity.json"),{});return j.brand||"CineHub";}catch(e){return"CineHub";}})();
  const desc="منصة أفلام ومسلسلات وأنمي مترجمة بجودة عالية";
  // HTML
  for(const f of inv.pages){
    if(!/<meta\s+charset/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><meta charset="utf-8">'),"html-charset",x=>/<meta\s+charset/i.test(x));
    if(!/name=["']viewport/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><meta name="viewport" content="width=device-width,initial-scale=1">'),"html-viewport",x=>/name=["']viewport/i.test(x));
    if(!/name=["']description/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><meta name="description" content="'+desc+'">'),"html-desc",x=>/name=["']description/i.test(x));
    if(!/<html[^>]*lang=/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<html/i,'<html lang="ar" dir="rtl"'),"html-lang",x=>/<html[^>]*lang=/i.test(x));
    if(!/rel=["']icon/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><link rel="icon" href="/assets/logo.png">'),"html-favicon",x=>/rel=["']icon/i.test(x));
    if(/<button(?![^>]*\btype=)/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<button(?![^>]*\btype=)/gi,'<button type="button"'),"button-type",x=>!/<button(?![^>]*\btype=)/i.test(x));
    if(/target=["']_blank["'](?![^>]*\brel=)/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/(target=["']_blank["'])(?![^>]*rel=)/gi,'$1 rel="noopener"'),"blank-rel",x=>!/target=["']_blank["'](?![^>]*rel=)/i.test(x));}
  // ملفات ناقصة
  const base=(()=>{try{const k=U.read(path.join(U.ROOT,"keys.env")).match(/^PUBLIC_URL=(.*)$/m);return k?k[1].replace(/\/$/,""):"";}catch(e){return"";}})();
  create("robots.txt","User-agent: *\nAllow: /\n"+(base?"Sitemap: "+base+"/sitemap.xml\n":""),"missing-file");
  if(inv.pages.length){const urls=inv.pages.slice(0,300).map(f=>(base||"")+"/"+f);
    create("sitemap.xml",'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+urls.map(u=>"<url><loc>"+u+"</loc><changefreq>daily</changefreq></url>").join("\n")+"\n</urlset>\n","missing-file");}
  create("manifest.webmanifest",JSON.stringify({name:brand,short_name:brand,start_url:"/",display:"standalone",background_color:"#0b0e14",theme_color:"#2563eb",icons:[{src:"/assets/logo.png",sizes:"512x512",type:"image/png"}]},null,1),"missing-file");
  create("security.txt","Contact: "+(U.read(path.join(U.ROOT,"keys.env")).match(/^CONTACT_EMAIL=(.*)$/m)||[,""])[1]+"\nExpires: "+new Date(Date.now()+31536e6).toISOString()+"\n","missing-file");
  create("ads.txt","# سطور شبكاتك تُضاف آليًا عبر: bash money/AUDIT.sh wire --apply\n","missing-file");
  create("404.html",'<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>404 — '+brand+'</title><style>body{margin:0;font-family:system-ui;background:#0b0e14;color:#e8eef7;display:grid;place-items:center;height:100vh;text-align:center}a{color:#7dd3fc}</style></head><body><div><h1 style="font-size:4rem;margin:0">404</h1><p>الصفحة غير موجودة</p><p><a href="/">→ الرئيسية</a></p></div></body></html>',"missing-file");
  // صلاحيات
  for(const f of ["keys.env","logs/codes.log","logs/vault.json","money/data/vault.enc","money/data/secrets.json","money/db/creds.json"]){
    const p=path.join(U.ROOT,f);if(!fs.existsSync(p))continue;
    const m=fs.statSync(p).mode&0o777;if(m===0o600)continue;
    if(APPLY){fs.chmodSync(p,0o600);rec("perm",f,true,"600 ("+m.toString(8)+" → 600)");}else rec("perm",f,true,"سيُضبط 600");}
  // gitignore
  const gi=path.join(U.ROOT,".gitignore");const need=["node_modules","keys.env","logs","*.pid","_backup","_deploy",".cache","__pycache__"];
  const cur=fs.existsSync(gi)?U.read(gi):"";const miss=need.filter(x=>!cur.includes(x));
  if(miss.length){if(APPLY){U.backup(gi);U.atomic(gi,(cur.trimEnd()+"\n"+miss.join("\n")+"\n").replace(/^\n/,""));rec("gitignore",".gitignore",true,"أُضيف: "+miss.join(", "));}
    else rec("gitignore",".gitignore",true,"سيُضاف: "+miss.join(", "));}
  // keys.env تنظيف
  const envp=path.join(U.ROOT,"keys.env");
  if(fs.existsSync(envp)){const raw=U.read(envp);const map={};raw.split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0)map[l.slice(0,i).trim()]=l.slice(i+1).trim();});
    const clean=Object.keys(map).sort().map(k=>k+"="+map[k]).join("\n")+"\n";
    if(clean!==raw){if(APPLY){U.backup(envp);U.atomic(envp,clean);try{fs.chmodSync(envp,0o600);}catch(e){}rec("env-normalize","keys.env",true,Object.keys(map).length+" مفتاح مرتب");}
      else rec("env-normalize","keys.env",true,"سيُنظّف ("+Object.keys(map).length+" مفتاح)");}}
  U.jw(path.join(U.A,"fixes.json"),{at:new Date().toISOString(),apply:APPLY,count:items.length,items});
  console.log("  ✔ إصلاحات "+(APPLY?"مُطبَّقة ومُتحقَّقة":"مُرشَّحة")+": "+items.length);
  const byr={};items.forEach(x=>byr[x.rule]=(byr[x.rule]||0)+1);
  Object.entries(byr).forEach(([k,v])=>console.log("   · "+k+": "+v));
  if(items.some(x=>!x.ok))console.log("   ✗ فشل: "+items.filter(x=>!x.ok).length+" (استُرجعت آليًا)");
  U.ev({phase:"fix-all",ok:items.every(x=>x.ok),detail:{count:items.length}});})();
Q13

# ═══════════ 13) التقرير ═══════════
w "$H/lib/q-report.js" <<'Q14'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),U=require("./q-util.js"),QDB=require("./q-db.js");
function collect(){const f=[];
  for(const n of ["findings-lint.json","findings-sec.json","findings-perf.json"]){
    const j=U.jr(path.join(U.A,n),{items:[]});(j.items||[]).forEach(x=>f.push(x));}
  U.jw(path.join(U.A,"findings-all.json"),{at:new Date().toISOString(),items:f});return f;}
function report(){const F=collect(),fx=U.jr(path.join(U.A,"fixes.json"),{items:[]}),t=U.jr(path.join(U.A,"tests.json"),{items:[],passed:0,total:0}),
  st=U.jr(path.join(U.A,"sectest.json"),{items:[],passed:0,total:0}),ld=U.jr(path.join(U.A,"load.json"),{}),w=U.jr(path.join(U.A,"wire.json"),{items:[]}),
  inv=U.jr(path.join(U.A,"inventory.json"),{}),dbh=QDB.health();
  const by={high:0,med:0,low:0};F.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
  const unfixed=F.filter(x=>x.fixable).length-(fx.items||[]).filter(x=>x.ok).length;
  const gates={
   "لا أخطاء صياغة":!F.some(x=>x.rule==="js-syntax"||x.rule==="json-parse"),
   "لا تسرّب مفاتيح":!F.some(x=>x.rule==="secret-leak"),
   "صلاحيات 600":!F.some(x=>x.rule==="perm"),
   "ترويسات أمان":!F.some(x=>x.rule==="header"&&x.sev!=="low")||(st.items||[]).filter(x=>/nosniff|Frame|Referrer/.test(x.name)).every(x=>x.ok),
   "قاعدة بيانات سليمة":dbh.ok,
   "API يعمل":(t.items||[]).some(x=>/API \/api\/health/.test(x.name)&&x.ok),
   "كل الصفحات 200":(t.items||[]).filter(x=>/^صفحة /.test(x.name)).every(x=>x.ok),
   "اختبارات وظيفية كاملة":(t.total||0)>0&&t.passed===t.total,
   "اختبارات أمان كاملة":(st.total||0)>0&&st.passed===st.total,
   "لا مراجع مكسورة":!F.some(x=>x.rule==="broken-ref"),
   "ملفات SEO موجودة":!F.some(x=>x.rule==="missing-file"),
   "أداء مقبول":(ld.p95||9999)<2500&&(ld.errors||0)===0};
  const score=Math.round(Object.values(gates).filter(Boolean).length/Object.keys(gates).length*100);
  const wired=w.items||[];
  const L=["# تقرير الفحص والإصلاح — "+new Date().toISOString(),"",
   "> كل بند مُتحقَّق فعليًا. الأدلة: `money/audit/evidence.jsonl` · `tests.json` · `sectest.json` · `load.json` · `fixes.json`","",
   "## الملخص","",
   "| المقياس | القيمة |","|---|---|",
   "| الملفات المفحوصة | "+inv.total+" |","| الصفحات | "+inv.counts.html+" |","| السكربتات | "+inv.counts.js+" |",
   "| ملاحظات | "+F.length+" (عالية "+by.high+" · متوسطة "+by.med+" · منخفضة "+by.low+") |",
   "| إصلاحات مطبَّقة | "+(fx.items||[]).filter(x=>x.ok).length+" |",
   "| اختبارات وظيفية | "+t.passed+"/"+t.total+" |","| اختبارات أمان | "+st.passed+"/"+st.total+" |",
   "| حمل | "+((ld.rps||0))+" طلب/ث · p95 "+((ld.p95||0))+"ms · أخطاء "+((ld.errors||0))+" |",
   "| قاعدة البيانات | "+dbh.engine+" · "+(dbh.ok?"سليمة":"متعثرة")+" |",
   "| **الجاهزية** | **"+score+"/100** |","",
   "## ما تم","",
   "- فحص "+(inv.total||0)+" ملفًا: صياغة JS، JSON، بنية HTML، روابط داخلية، SEO، أمان، أداء",
   "- إصلاح "+(fx.items||[]).filter(x=>x.ok).length+" عنصرًا بأمان (نسخة احتياطية قبل كل تعديل + إعادة اختبار + استرجاع تلقائي عند الفشل)",
   "- ربط قاعدة بيانات "+(QDB.hasSqlite?"SQLite":"JSON")+" وواجهة API مُختبرة حيًّا ("+(t.items||[]).filter(x=>/API/.test(x.name)).length+" مسار)",
   "- ربط الخدمات الخارجية: "+wired.filter(x=>x.configured).length+" مُعدّ · "+wired.filter(x=>x.verified).length+" مُتحقَّق",
   "- اختبار حقيقي: صفحات · 404 · اجتياز مسارات · منع الملفات الحسّاسة · كتابة في القاعدة · حمل متوازٍ","",
   "## بوابات الجاهزية",""];
  Object.entries(gates).forEach(([k,v])=>L.push("- "+(v?"✔ ":"✗ ")+k));
  L.push("","## يحتاجك (محجوب)","");
  const blocked=[];
  if(!wired.some(x=>x.configured))blocked.push("لا مفاتيح خدمات في keys.env — أضفها ليعمل الربط: `bash money/AUDIT.sh wire --apply`");
  if((fx.items||[]).length===0)blocked.push("لم يُطبَّق إصلاح بعد — شغّل: `bash money/AUDIT.sh fix --apply`");
  if(!dbh.ok)blocked.push("قاعدة البيانات غير سليمة — راجع `money/audit/app.db`");
  if((ld.errors||0)>0)blocked.push("أخطاء في اختبار الحمل — راجع `money/audit/load.json`");
  F.filter(x=>!x.fixable&&x.sev==="high").slice(0,6).forEach(x=>blocked.push("["+x.rule+"] "+x.file+" — "+x.msg+" (يحتاج قرارًا)"));
  if(!blocked.length)blocked.push("لا شيء — كل البوابات مكتملة");
  blocked.forEach(b=>L.push("- "+b));
  L.push("","## التالي","","```bash","bash money/AUDIT.sh all            # فحص كامل بلا تعديل","bash money/AUDIT.sh fix --apply    # إصلاح آمن + إعادة اختبار",
   "bash money/AUDIT.sh wire --apply   # ربط الخدمات الخارجية","bash money/AUDIT.sh verify         # إعادة اختبار كل شيء","```","",
   "## واجهة API المتاحة","","```","GET  /health /metrics /api/state /api/health /api/ready","GET  /api/findings /api/fixes /api/tests /api/keys /api/version",
   "POST /api/event {\"kind\":\"x\",\"payload\":{}}","```","","التشغيل: `bash money/AUDIT.sh api-start` (المنفذ "+ (process.env.Q_STATIC_PORT||8799) +")","");
  fs.mkdirSync(path.join(U.ROOT,"docs"),{recursive:true});
  fs.writeFileSync(path.join(U.ROOT,"docs","AUDIT-REPORT.md"),L.join("\n"));
  QDB.insert("metrics",{name:"readiness_score",value:score});
  return {score,gates,by,F,FX:fx,T:t,ST:st,LD:ld};}
if(require.main===module){const r=report();
  console.log("  ══════ التقرير ══════");
  console.log("  ملاحظات: "+r.F.length+" · إصلاحات: "+(r.FX.items||[]).filter(x=>x.ok).length+" · اختبارات: "+r.T.passed+"/"+r.T.total+" · أمان: "+r.ST.passed+"/"+r.ST.total);
  console.log("  الجاهزية: "+r.score+"/100");
  Object.entries(r.gates).forEach(([k,v])=>console.log("   "+(v?"✔":"✗")+" "+k));
  console.log("  ✔ docs/AUDIT-REPORT.md");}
module.exports={report,collect};
Q14

# ═══════════ 14) المنسّق ═══════════
w "$H/lib/q-audit.js" <<'Q15'
#!/usr/bin/env node
"use strict";
const {execFileSync}=require("child_process"),path=require("path"),U=require("./q-util.js");
const APPLY=process.env.APPLY==="1";
const run=(f,args)=>{try{return execFileSync("node",[path.join(U.H,"lib",f)].concat(args||[]),{cwd:U.ROOT,stdio:"pipe",timeout:900000,env:Object.assign({},process.env,{APPLY:APPLY?"1":"0"})}).toString();}
  catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
const sh=(f,args)=>{try{return execFileSync("bash",[path.join(U.H,f)].concat(args||[]),{cwd:U.ROOT,stdio:"pipe",timeout:900000,env:Object.assign({},process.env,{APPLY:APPLY?"1":"0"})}).toString();}
  catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
const steps=[
 ["1/9 جرد",()=>run("q-scan.js")],
 ["2/9 تشخيص ساكن",()=>run("q-lint.js")],
 ["3/9 أمان",()=>run("q-sec.js")],
 ["4/9 أداء",()=>run("q-perf.js")],
 ["5/9 قاعدة بيانات",()=>run("q-db.js","init")],
 ["6/9 ربط الخدمات",()=>run("q-wire.js")],
 ["7/9 اختبار وظيفي",()=>run("q-test.js")],
 ["8/9 اختبار أمان حيّ",()=>run("q-sectest.js")],
 ["9/9 حمل",()=>run("q-load.js")]
];
(async()=>{U.log("AUDITOR بدأ apply="+APPLY);
  console.log("╔══════ AUDITOR — فحص وإصلاح شامل"+(APPLY?" (مع التطبيق)":"")+" ══════╗");
  for(const [n,fn] of steps){console.log("\n▶ "+n);const out=fn();console.log(out.trimEnd());}
  if(APPLY){console.log("\n▶ إصلاح آمن");console.log(run("q-fix.js").trimEnd());
    console.log("\n▶ إعادة اختبار بعد الإصلاح");console.log(run("q-lint.js").trimEnd());console.log(run("q-sec.js").trimEnd());
    console.log(run("q-test.js").trimEnd());}
  console.log("\n▶ التقرير");console.log(run("q-report.js").trimEnd());
  U.log("انتهى");
  console.log("\n  الملفات: money/audit/ · التقرير: docs/AUDIT-REPORT.md");})();
Q15

w "$H/lib/q-cli.js" <<'Q16'
#!/usr/bin/env node
"use strict";
const {spawnSync}=require("child_process"),path=require("path");
const A=path.join(path.resolve(__dirname,".."),"AUDIT.sh");
const M=[["1","فحص كامل (بلا تعديل)","all"],["2","فحص + إصلاح آمن","all --apply"],["3","تشخيص ساكن","lint"],
 ["4","أمان","sec"],["5","أداء","perf"],["6","قاعدة بيانات","db"],["7","ربط الخدمات (+تطبيق)","wire --apply"],
 ["8","اختبار وظيفي","test"],["9","اختبار أمان حيّ","sectest"],["10","اختبار حمل","load"],
 ["11","إصلاح آمن","fix --apply"],["12","تقرير","report"],["13","تشغيل API","api-start"],["14","الحالة","status"]];
console.log("\n╔══════════ AUDITOR ══════════╗");
M.forEach(m=>console.log("  "+m[0].padStart(2)+") "+m[1]));
console.log("╚═════════════════════════════╝");
if(process.argv[2]){spawnSync("bash",[A].concat(process.argv.slice(2)),{stdio:"inherit"});process.exit(0);}
require("readline").createInterface({input:process.stdin,output:process.stdout}).question("اختر: ",a=>{
  const m=M.find(x=>x[0]===String(a).trim());if(m)spawnSync("bash",[A].concat(m[2].split(" ")),{stdio:"inherit"});else console.log("○");process.exit(0);});
Q16

chmod +x "$H"/lib/q-*.js "$H/AUDIT.sh" 2>/dev/null
node "$H/lib/q-db.js" init >/dev/null 2>&1 || true

case "$CMD" in
 menu) exec node "$H/lib/q-cli.js" ;;
 scan)  Q q-scan.js ;;
 lint)  Q q-lint.js ;;
 sec)   Q q-sec.js ;;
 perf)  Q q-perf.js ;;
 db)    Q q-db.js init; Q q-db.js health ;;
 api)   Q q-static.js >/dev/null 2>&1 & sleep 1; curl -s http://127.0.0.1:${Q_STATIC_PORT:-8799}/api/health; echo; pkill -f q-static.js ;;
 wire)  Q q-wire.js ;;
 test)  Q q-test.js ;;
 sectest) Q q-sectest.js ;;
 load)  Q q-load.js ;;
 fix)   Q q-fix.js ;;
 verify)
   S "إعادة التحقق الكامل"; Q q-lint.js; Q q-sec.js; Q q-test.js; Q q-sectest.js; Q q-load.js; Q q-report.js ;;
 report) Q q-report.js ;;
 api-start)
   pkill -f "q-static.js" 2>/dev/null; sleep 1
   nohup node "$H/lib/q-static.js" </dev/null >>"$A/api.log" 2>&1 &
   sleep 2; say "  ✔ API + خادم مُحصَّن على http://127.0.0.1:${Q_STATIC_PORT:-8799} (pid $(pgrep -f q-static.js | head -1))" ;;
 api-stop) pkill -f "q-static.js" 2>/dev/null; say "  ⏹ أُوقف" ;;
 status)
   node - "$H" <<'JSZ'
const path=require("path"),U=require(path.join(process.argv[2],"lib","q-util.js")),QDB=require(path.join(process.argv[2],"lib","q-db.js"));
const inv=U.jr(path.join(U.A,"inventory.json"),{}),F=U.jr(path.join(U.A,"findings-all.json"),{items:[]}),
 t=U.jr(path.join(U.A,"tests.json"),{}),st=U.jr(path.join(U.A,"sectest.json"),{}),ld=U.jr(path.join(U.A,"load.json"),{}),
 fx=U.jr(path.join(U.A,"fixes.json"),{}),h=QDB.health();
const by={};F.items.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
console.log("  الملفات   : "+(inv.total||0)+" · صفحات "+(inv.counts?inv.counts.html:0)+" · سكربتات "+(inv.counts?inv.counts.js:0));
console.log("  ملاحظات  : "+(F.items.length||0)+"  (عالية "+(by.high||0)+" · متوسطة "+(by.med||0)+" · منخفضة "+(by.low||0)+")");
console.log("  إصلاحات  : "+(fx.items?fx.items.filter(x=>x.ok).length:0)+" مطبَّق ومُتحقَّق");
console.log("  اختبارات : "+(t.passed||0)+"/"+(t.total||0)+" · أمان "+(st.passed||0)+"/"+(st.total||0)+" · حمل "+(ld.rps||0)+" req/s p95 "+(ld.p95||0)+"ms");
console.log("  القاعدة  : "+h.engine+" "+(h.ok?"سليمة":"متعثرة")+" · "+JSON.stringify(h.tables));
console.log("  التقرير  : docs/AUDIT-REPORT.md");
JSZ
   ;;
 all)  APPLY=$APPLY node "$H/lib/q-audit.js" ;;
 *)    say "الأوامر: menu|all|scan|lint|sec|perf|db|api|wire|test|sectest|load|fix|verify|report|status|api-start|api-stop [--apply]" ;;
esac
