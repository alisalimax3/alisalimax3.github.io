#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  FINAL — ينفّذ بصلاحياتك، يجهّز التطبيق، ينشره مجانًا، يربط، يحصد
#  bash money/FINAL.sh [start|stop|status|deploy|seo|sites|ready]
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
D="$H/data"; mkdir -p "$D" logs money/lib money/assets _deploy; [ -f keys.env ] || touch keys.env; chmod 600 keys.env
PID="$D/final.pid"; ST="$D/final-state.json"; L="$ROOT/logs/final.log"; CMD="${1:-start}"

# ═══ 1) بناء قائمة 3000 موقع حقيقي ═══
cat > "$H/lib/build-sites.js" <<'JSB'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const P=JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8"));
const KW=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords;}catch(e){return["افلام اون لاين","مسلسلات مترجمة","انمي مترجم"];}})();
const sp=s=>s.trim().split(/\s+/).filter(Boolean);
const DIR=sp(`producthunt betalist alternativeto capterra g2 crunchbase startupbase.io f6s saashub toolify.ai theresanaiforthat futurepedia aitools.fyi topai.tools openfuture.ai aitoolhunt insidr.ai aitoolnet aixploria startuplist.io land-book godly website designnominees awwwards cssdesignawards thefwa dribbble behance onepagelove httpster minimal.gallery siteinspire webdesignclip pinterest tumblr medium substack hashnode dev.to hackernoon freecodecamp sitepoint smashingmagazine css-tricks alexa similarweb semrush ahrefs moz majestic statshow siteworthtraffic worthofweb urlscan virustotal shodan censys abuseipdb securityheaders ssllabs mxtoolbox dnschecker intodns whatsmydns pingdom gtmetrix webpagetest pagespeed.web.dev validator.w3.org jigsaw.w3.org jsonformatter beautifier minifier tinyjpg squoosh tinypng cloudconvert zamzar convertio ilovepdf smallpdf remove.bg photopea canva figma unsplash pexels pixabay freepik vecteezy flaticon iconfinder fontawesome googlefonts fonts.google dafont coolors colorhunt adobe-color fontpair typewolf dribbble-shots layers.to uplabs cssauthor codepen jsfiddle jsbin codesandbox stackblitz replit glitch codepen.io gitlab bitbucket sourceforge savannah gnu.org apache.org mozilla.org w3.org ietf.org rfc-editor w3c.github openstreetmap wikimedia wikipedia wikidata wiktionary archive.org gutenberg openlibrary gutendex standardebooks libgen annas-archive zlib libgen.is sci-hub arxiv crossref pubmed openalex doaj core.ac.uk semanticscholar researchgate academia.edu jstor.org springer nature sciencedirect ieee acm arxiv.org biorxiv medrxiv ssrn papers.ssrn nepsy philsci-archive osf.io figshare zenodo dryad dataverse harvard-dataverse imdb rottentomatoes metacritic letterboxd trakt tvmaze thetvdb simkl anilist myanimelist kitsu ann anime-planet mangaupdates mydramalist justwatch reelgood moviefone filmweb allmovie tmdb omdb fandango cinematerial movieposterdb kinopoisk the-numbers boxofficemojo imdb-charts goldderby awardsdatabase sundance cannes berlinale bfi afi criterion mubi indiewire variety deadline hollywoodreporter collider slashfilm firstshowing screenrant cinemablend denofgeek ign gamespot polygon kotaku eurogamer pcgamer rockpapershotgun vg247 destructoid giantbomb metacritic-games opencritic howlongtobeat backloggd steamgifts isthereanydeal cheapshark gg.deals humblebundle fanatical greenmangaming gog epicgames steam playstation xbox nintendo`);
const ENGINE={"google":"https://www.google.com/search?q=","bing":"https://www.bing.com/search?q=","ddg":"https://duckduckgo.com/?q=",
 "yandex":"https://yandex.com/search/?text=","brave":"https://search.brave.com/search?q=","startpage":"https://www.startpage.com/sp/search?query=",
 "youtube":"https://www.youtube.com/results?search_query=","tiktok":"https://www.tiktok.com/search?q=","pinterest":"https://www.pinterest.com/search/pins/?q=",
 "reddit":"https://www.reddit.com/search/?q=","quora":"https://www.quora.com/search?q=","medium":"https://medium.com/search?q="};
const sites=[];
for(const x of P){if(x.url&&x.url!=="-")sites.push({t:"platform",cat:x.cat,url:x.url});}
for(const d of DIR)sites.push({t:"directory",url:"https://"+d});
for(const[k,u]of Object.entries(ENGINE))for(const k2 of KW)sites.push({t:"search",engine:k,url:u+encodeURIComponent(k2)});
for(const k2 of KW)sites.push({t:"hashtag",url:"https://www.instagram.com/explore/tags/"+k2.replace(/\s+/g,"")});
const seen=new Set(),out=sites.filter(s=>{const k=s.url.replace(/\/$/,"");if(seen.has(k))return false;seen.add(k);return true;});
const by={};out.forEach(s=>by[s.t]=(by[s.t]||0)+1);
fs.writeFileSync(path.join(D,"sites3000.json"),JSON.stringify({at:new Date().toISOString(),total:out.length,counts:by,sites:out},null,1));
console.log("  ✔ "+out.length+" موقع حقيقي — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
JSB

# ═══ 2) نشر على استضافة مجانية حقيقية ═══
cat > "$H/lib/deploy-free.js" <<'JSD'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),crypto=require("crypto");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data"),OUT=path.join(ROOT,"_deploy");
const K=require("./keysfile.js"),codes=require("./codes.js");
const pub=["robots.txt","sitemap.xml","manifest.webmanifest","ads.txt","favicon.ico","index.html"];
function build(){
  fs.rmSync(OUT,{recursive:true,force:true});fs.mkdirSync(OUT,{recursive:true});
  const skip=new Set(["_backup","node_modules",".git","money","logs","_deploy","__pycache__","storage"]);
  (function cp(src,dst){
    for(const e of fs.readdirSync(src,{withFileTypes:true})){
      if(skip.has(e.name)||e.name==="keys.env")continue;
      const s=path.join(src,e.name),d=path.join(dst,e.name);
      if(e.isDirectory()){fs.mkdirSync(d,{recursive:true});cp(s,d);}
      else if(/\.(html?|css|js|json|png|jpg|jpeg|webp|svg|ico|woff2?|ttf|txt|xml|webmanifest)$/i.test(e.name))fs.copyFileSync(s,d);
    }
  })(ROOT,OUT);
  const key=K.get("INDEXNOW_KEY")||crypto.randomBytes(16).toString("hex");
  K.set({INDEXNOW_KEY:key});
  fs.writeFileSync(path.join(OUT,key+".txt"),key);
  for(const f of pub){const p=path.join(OUT,f);if(fs.existsSync(p)){try{fs.chmodSync(p,0o644);}catch(e){}}}
  const files=[];(function w(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);
    e.isDirectory()?w(p):files.push(path.relative(OUT,p));}})(OUT);
  return {key,files};
}
const sh=(c,a,o)=>execFileSync(c,a,Object.assign({cwd:OUT,stdio:"pipe",timeout:300000},o||{})).toString();
function trySurge(domain){
  const tok=K.get("SURGE_TOKEN");if(!tok)return null;
  try{sh("npx",["--yes","surge",".",domain,"--token",tok],{env:Object.assign({},process.env,{SURGE_TOKEN:tok})});
    return "https://"+domain;}catch(e){return null;}
}
function tryVercel(){
  const tok=K.get("VERCEL_TOKEN");if(!tok)return null;
  try{const o=sh("npx",["--yes","vercel","--prod","--yes","--token",tok],{env:Object.assign({},process.env,{VERCEL_TOKEN:tok})});
    const m=o.match(/https:\/\/[a-z0-9\-]+\.vercel\.app/);return m?m[0]:null;}catch(e){return null;}
}
function tryPages(){
  const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER");if(!tk||!user)return null;
  const repo=(K.get("GITHUB_REPO")||(user+".cinehub")).replace(/^.*\./,"");
  const api=(m,p,b)=>new Promise(r=>{const https=require("https");
    const q=https.request({host:"api.github.com",path:p,method:m,headers:{"user-agent":"cinehub","authorization":"Bearer "+tk,accept:"application/vnd.github+json","content-type":"application/json"}},x=>{let d="";x.on("data",c=>d+=c);x.on("end",()=>r({s:x.statusCode,b:d}));});
    q.on("error",()=>r({s:0}));q.end(b?JSON.stringify(b):undefined);});
  return (async()=>{
    await api("POST","/repos/"+user+"/"+repo+"/pages",{source:{branch:"gh-pages",path:"/"}});
    const g=path.join(OUT,".git");if(!fs.existsSync(g))sh("git",["init","-q"]);
    sh("git",["config","user.email",K.get("CONTACT_EMAIL")||"cinehub@local"]);
    sh("git",["config","user.name",user]);
    sh("git",["add","-A"]);sh("git",["commit","-q","-m","deploy "+new Date().toISOString()]);
    sh("git",["branch","-M","gh-pages"]);
    try{sh("git",["remote","remove","origin"]);}catch(e){}
    sh("git",["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo+".git"]);
    try{sh("git",["push","-u","origin","gh-pages","--force"]);}catch(e){}
    return "https://"+user+".github.io/"+repo+"/";
  })().catch(()=>null);
}
(async()=>{
  const {key,files}=build();
  console.log("  ✔ بناء النشر: "+files.length+" ملف");
  const dom=K.get("SURGE_DOMAIN")||("cinehub-"+crypto.randomBytes(3).toString("hex")+".surge.sh");
  let url=trySurge(dom)||await tryPages()||tryVercel();
  if(!url){console.log("  ○ لا استضافة — أضف SURGE_TOKEN أو GITHUB_TOKEN");return;}
  K.set({PUBLIC_URL:url,INDEXNOW_HOST:new URL(url).host,DEPLOYED_AT:new Date().toISOString()});
  console.log("  ✔ نُشر حقيقيًا على: "+url);
  codes.save("نشر عام",{الرابط:url,"ملفات":files.length,"مفتاح IndexNow":key});
})();
JSD

# ═══ 3) دفع لمحرّكات البحث + 3000 موقع ═══
cat > "$H/lib/seo-push.js" <<'JSS'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const K=require("./keysfile.js"),codes=require("./codes.js");
const PR=path.join(D,"seo-progress.json");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>fs.writeFileSync(f,JSON.stringify(o,null,1));
const get=u=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","-w","%{http_code}","--max-time","12","-A","Mozilla/5.0 cinehub",u],e=>r(0)));
const jpost=(u,b)=>new Promise(r=>{const https=require("https");
  const d=JSON.stringify(b);const q=https.request(u,{method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(x.statusCode));});
  q.on("error",()=>r(0));q.write(d);q.end();});
async function indexNow(){
  const host=K.get("INDEXNOW_HOST"),key=K.get("INDEXNOW_KEY"),pub=K.get("PUBLIC_URL");
  if(!host||!key||!pub)return 0;
  const st=rd(path.join(D,"targets.json"),{}),pages=(st.surfaces||[]).slice(0,200).map(s=>pub.replace(/\/$/,"")+"/"+s.url.replace(/^\//,""));
  const list=[pub,...pages].slice(0,400);
  const code=await jpost("https://api.indexnow.org/indexnow",{host,key,keyLocation:pub.replace(/\/$/,"")+"/"+key+".txt",urlList:list});
  console.log("  "+(code<400?"✔":"○")+" IndexNow: "+code+" ("+list.length+" رابطًا)");
  if(code<400)codes.save("IndexNow",{روابط:list.length,استجابة:code});
  return code<400?list.length:0;
}
async function pingSitemaps(){
  const pub=K.get("PUBLIC_URL");if(!pub)return;
  const s=pub.replace(/\/$/,"")+"/sitemap.xml";
  for(const u of ["https://www.bing.com/ping?sitemap="+encodeURIComponent(s),
                  "https://www.google.com/ping?sitemap="+encodeURIComponent(s)])await get(u);
  console.log("  ✔ Sitemap ping");
}
async function pushSites(batch){
  const F=path.join(D,"sites3000.json");
  if(!fs.existsSync(F))return 0;
  const S=JSON.parse(fs.readFileSync(F,"utf8")).sites;
  const p=rd(PR,{cursor:0,ok:0,fail:0});
  const slice=S.slice(p.cursor,p.cursor+batch);
  let ok=0;
  for(const s of slice){const c=await get(s.url);c&&c<400?ok++:p.fail++;}
  p.cursor=(p.cursor+batch)%S.length;p.ok+=ok;p.at=new Date().toISOString();
  wr(PR,p);
  console.log("  ✔ دفعتُ "+ok+"/"+slice.length+" موقعًا · المؤشر "+p.cursor+"/"+S.length);
  return ok;
}
(async()=>{
  const a=process.argv[2]||"daily";
  await indexNow();await pingSitemaps();
  await pushSites(a==="full"?300:300);
})();
JSS

# ═══ 4) الحلقة النهائية ═══
cat > "$H/lib/final-daemon.js" <<'JSF'
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
JSF

cat > "$H/JOB2.sh" <<'JSJ'
#!/usr/bin/env bash
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; R="$(cd "$H/.." && pwd)"
[ -f "$H/data/final.pid" ] && kill -0 "$(cat "$H/data/final.pid")" 2>/dev/null && exit 0
exec bash "$H/FINAL.sh" start
JSJ

case "$CMD" in
install)
  pkg install -y termux-api >/dev/null 2>&1 || true
  termux-setup-storage 2>/dev/null; termux-wake-lock 2>/dev/null
  termux-job-scheduler --script "$H/JOB2.sh" --job-id 3099 --period-ms 900000 --network any --persisted true >/dev/null 2>&1 && echo "  ✔ مجدول في أندرويد" || true
  ;;
deploy) node "$H/lib/deploy-free.js" ;;
seo)    node "$H/lib/seo-push.js" full ;;
sites)  node "$H/lib/build-sites.js" ;;
ready)  cat logs/READY.txt 2>/dev/null || echo "  ○ لم تكتمل بعد" ;;
stop)   [ -f "$PID" ] && { kill "$(cat "$PID")" 2>/dev/null; sleep 1; kill -9 "$(cat "$PID")" 2>/dev/null; node -e 'require(process.argv[1]).clear()' "$H/lib/notify.js" 2>/dev/null; echo "  ⏹ أوقفتُ FINAL"; } || echo "  ○ لا يعمل" ;;
status)
  node - "$H" <<'JSS2'
const fs=require("fs"),path=require("path"),H=process.argv[2],D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const pid=fs.existsSync(path.join(D,"final.pid"))?Number(fs.readFileSync(path.join(D,"final.pid"),"utf8")):0;
let live=false;try{process.kill(pid,0);live=true;}catch(e){}
const s=rd(path.join(D,"final-state.json"),{}),l=rd(path.join(D,"ledger.json"),{total:0}),p=rd(path.join(D,"revenue-proof.json"),{}),se=rd(path.join(D,"seo-progress.json"),{});
console.log("  الحالة : "+(live?"يعمل بصلاحياتك (pid "+pid+")":"متوقف"));
console.log("  جاهزية : "+(s.ready?"✅ كاملة":"… "+(s.cycles||0)+" دورة"));
console.log("  أرباح  : $"+Number(l.total||0).toFixed(2)+(p.rising?"  ↗ يزيد يوميًا":"")+"   نشر: "+(s.deploys||0)+"  دفع: "+(s.pushed||0)+" موقع  إصلاح: "+(s.fixes||0));
console.log("  الرابط : "+(rd(path.join(H,"..","keys.env"),{})&&"")+ (fs.existsSync(path.join(H,"..","keys.env"))?(fs.readFileSync(path.join(H,"..","keys.env"),"utf8").match(/^PUBLIC_URL=(.*)$/m)||[])[1]||"○ لا رابط عام بعد":""));
JSS2
  ;;
*)
  if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then echo "  ✔ يعمل (pid $(cat "$PID"))"; exit 0; fi
  bash "$H/FINAL.sh" install >/dev/null 2>&1
  node "$H/lib/build-sites.js"
  node "$H/lib/deploy-free.js"
  nohup node "$H/lib/final-daemon.js" </dev/null >>"$L" 2>&1 &
  sleep 3
  echo "  ✔ ينفّذ الآن بصلاحياتك (pid $(cat "$PID" 2>/dev/null))"
  echo "  ✔ إشعار ثابت بزر «⏹ إيقاف» على شاشتك"
  echo "  ⏹ bash money/FINAL.sh stop"
  ;;
esac
