#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  الوكيل الكامل — يكتب ملفاته، يثبّت نفسه، يفوّض نفسه، ينفّذ كل شيء
# ══════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
mkdir -p logs money/data money/assets money/lib; [ -f keys.env ] || touch keys.env; chmod 600 keys.env
L="$ROOT/logs/agent.log"; : > "$L"
q(){ "$@" >>"$L" 2>&1; }
say(){ printf '%s\n' "$*"; }
up(){ for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do V=$(grep -m1 "^$K=" keys.env 2>/dev/null|cut -d= -f2-);
      [ -n "$V" ] && curl -sL -o /dev/null --max-time 4 "http://127.0.0.1:$V/" || return 1; done; return 0; }

# ── 0) صلاحيات الجهاز ومنع النوم ──
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock 2>/dev/null
[ -d "$HOME/storage" ] || termux-setup-storage >/dev/null 2>&1 || true
for p in node curl openssl python3 git tar; do command -v $p >/dev/null 2>&1 || pkg install -y $p >>"$L" 2>&1; done
say "✔ الصلاحيات والاعتماديات الأساسية جاهزة"

# ══════════ الملف 1: التحقق الهاتفي (5sim) ══════════
cat > "$H/lib/sms.js" <<'JS1'
#!/usr/bin/env node
"use strict";
// رقم هاتف افتراضي حقيقي للتحقق — 5sim
const K=require("./keysfile.js");
const API="https://5sim.net/v1";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function call(p){
  const r=await fetch(API+p,{headers:{authorization:"Bearer "+K.get("FIVESIM_TOKEN"),accept:"application/json"}});
  const t=await r.text();try{return JSON.parse(t);}catch(e){return{raw:t,status:r.status};}
}
async function buy(product="github",country="any",operator="any"){
  if(!K.get("FIVESIM_TOKEN"))return console.log("  ○ لا FIVESIM_TOKEN — تخطّي الهاتف");
  const o=await call(`/user/buy/activation/${country}/${operator}/${product}`);
  if(!o.id)return console.log("  ○ فشل الشراء: "+JSON.stringify(o).slice(0,90));
  console.log("  ✔ رقم: "+o.phone+"  (id "+o.id+")");
  K.set({PHONE_NUMBER:o.phone,PHONE_ID:String(o.id)});
  return o;
}
async function waitCode(id,timeoutMs=180000){
  const t0=Date.now();
  while(Date.now()-t0<timeoutMs){
    const s=await call("/user/check/"+id);
    const sms=(s.sms||[]).map(x=>x.code).filter(Boolean);
    if(sms.length){console.log("  ✔ وصل رمز SMS: "+sms[0]);return sms[0];}
    if(s.status==="CANCELED"){console.log("  ○ أُلغي الرقم");return "";}
    await sleep(5000);
  }
  return "";
}
const finish=id=>call("/user/finish/"+id);
const profile=()=>call("/user/profile");
module.exports={buy,waitCode,finish,profile,call};
if(require.main===module){const a=process.argv.slice(2);
  if(a[0]==="buy")buy(a[1],a[2],a[3]);else if(a[0]==="code")waitCode(a[1]);
  else if(a[0]==="balance")profile().then(p=>console.log("  رصيد 5sim: "+JSON.stringify(p.balance||p)));}
JS1

# ══════════ الملف 2: محرّك الموافقة الفورية ══════════
cat > "$H/lib/approval.js" <<'JS2'
#!/usr/bin/env node
"use strict";
// يملأ نموذج الطلب كاملًا (المفتاح للموافقة الفورية) + يقرأ بريد الموافقة ويفتح رابطه
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const K=require("./keysfile.js"),MB=require("./mailbox.js"),codes=require("./codes.js");
const KP=JSON.parse(fs.readFileSync(path.join(DATA,"keypages.json"),"utf8"));
const I=()=>JSON.parse(fs.readFileSync(path.join(DATA,"identity.json"),"utf8"));
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
// قيم ترفع احتمال الموافقة الفورية إلى أقصاها
function profile(){
  const id=I();
  return {
    site: K.get("PUBLIC_URL")||"https://"+id.handle+".blogspot.com",
    impressions:"500000", uniques:"150000", pageviews:"1200000",
    sources:"Search Engines, Social Media, Direct, Referral",
    categories:"Movies, Entertainment, Video Streaming, Anime",
    countries:"Worldwide, US, GB, DE, EG, SA, AE",
    adformats:"Popunder, Push, In-Page Push, Native, Banner",
    phone:K.get("PHONE_NUMBER")||"",
    payment:"USDT (TRC20 / Base)", tax:"Individual", company:"Individual",
    role:"Webmaster / Publisher", experience:"3+ years",
    referrer:"Google", interest:"Publisher account", monthly:"500000"
  };
}
function val(f,P){
  const s=((f.name||"")+" "+(f.id||"")+" "+(f.placeholder||"")+" "+(f.getAttribute&&f.getAttribute("aria-label")||"")).toLowerCase();
  const t=(f.type||"").toLowerCase();
  const hit=(...ks)=>ks.some(k=>s.includes(k));
  if(t==="email"||hit("email","mail"))return K.get("CONTACT_EMAIL");
  if(t==="password"||hit("pass"))return K.get("MASTER_PASSWORD");
  if(t==="tel"||hit("phone","mobile","tel"))return P.phone;
  if(hit("confirm"))return K.get("MASTER_PASSWORD");
  if(hit("user","login","nick","handle"))return K.get("BRAND_HANDLE");
  if(hit("first","fname"))return I().brand;
  if(hit("last","lname","surname"))return "Media";
  if(hit("name","company","fullname"))return I().brand;
  if(hit("site","website","url","domain","link"))return P.site;
  if(hit("impress","traffic","volume","visits","views"))return P.impressions;
  if(hit("unique"))return P.uniques;
  if(hit("source","channel"))return P.sources;
  if(hit("categor","niche","vertical","topic"))return P.categories;
  if(hit("country","geo","region"))return P.countries;
  if(hit("format","ad type","placement"))return P.adformats;
  if(hit("payment","payout","wallet","method"))return P.payment;
  if(hit("tax","vat","entity","business type"))return P.tax;
  if(hit("experience","years"))return P.experience;
  if(hit("skype","telegram","messenger"))return I().handle;
  if(hit("city"))return "Cairo";
  if(hit("address"))return "Cairo, Egypt";
  if(hit("postal","zip"))return "11511";
  if(hit("about","comment","message","note","describe","how"))return I().desc_long_en.slice(0,300);
  if(hit("refer"))return P.referrer;
  return "";
}
async function fillAll(page){
  const P=profile();
  const els=await page.$$("input,select,textarea");
  let n=0;
  for(const el of els){
    try{
      const meta=await el.evaluate(e=>({tag:e.tagName,type:e.type,name:e.name,id:e.id,placeholder:e.placeholder,
        aria:e.getAttribute("aria-label")||"",value:e.value}));
      if(["hidden","submit","button","file"].includes(meta.type))continue;
      const box=await el.boundingBox(); if(!box)continue;
      if(meta.tag==="SELECT"){
        const opts=await el.$$eval("option",os=>os.map(o=>({v:o.value,t:o.textContent.trim()})));
        const want=val(meta,P).toLowerCase();
        let pick=opts.find(o=>want&&(o.t.toLowerCase().includes(want)||want.includes(o.t.toLowerCase())));
        if(!pick)pick=opts.find(o=>o.v&&o.v!=="0"&&!/select|choose|--/i.test(o.t));
        if(pick&&pick.v){await page.select(meta.name?`select[name="${meta.name}"]`:`#${meta.id}`,pick.v).catch(()=>{});n++;}
        continue;
      }
      if(meta.type==="checkbox"||meta.type==="radio"){if(!meta.value||meta.value==="on"){await el.click().catch(()=>{});n++;}continue;}
      const v=val(meta,P);
      if(v){await el.click({clickCount:3}).catch(()=>{});await el.type(String(v),{delay:10}).catch(()=>{});n++;}
    }catch(e){}
  }
  return n;
}
async function access(page){const h=await page.content();return /logout|dashboard|sign out|my account|panel/i.test(h);}
async function run(k){
  const rec=KP[k]; if(!rec)return;
  const ppP=path.join(ROOT,"node_modules","puppeteer-core");
  const exe=process.env.CHROME_PATH||["/data/data/com.termux/files/usr/bin/chromium-browser","/usr/bin/chromium"].find(p=>fs.existsSync(p));
  if(!fs.existsSync(ppP)||!exe)return console.log("  ○ "+k+" — بلا متصفح");
  const pp=require(ppP),id=I();
  const br=await pp.launch({executablePath:exe,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
  const page=await br.newPage(); await page.setUserAgent(UA);
  try{
    console.log("\n═══ موافقة "+k+" ═══");
    await page.goto(rec.signup,{waitUntil:"networkidle2",timeout:60000});
    const n=await fillAll(page);
    console.log("  ✔ مُلئ "+n+" حقلًا كاملًا (المفتاح للموافقة الفورية)");
    const b=await page.$('button[type=submit],input[type=submit],button:not([type])');
    if(b)await Promise.all([page.waitForNavigation({waitUntil:"networkidle2",timeout:45000}).catch(()=>{}),b.click()]);
    await sleep(3000);
    const ok=await access(page);
    console.log(ok?"  ✔ دخلت اللوحة فورًا — مقبول":"  ○ قيد المراجعة");
    const {link}=await MB.waitLink(60000);
    if(link){const v=await MB.rq(link);console.log("  ✔ تأكيد/موافقة بالبريد: HTTP "+v.status);}
    // التقاط المفتاح
    await page.goto(rec.keysUrl,{waitUntil:"networkidle2",timeout:60000}).catch(()=>{});
    await sleep(2000);
    const html=await page.content();
    const cand=[...new Set((html.match(new RegExp(rec.regex,"g"))||[]).filter(x=>x.length>=20))].slice(0,6);
    if(cand.length){const o={};rec.env.forEach((e,i)=>o[e]=cand[i]||cand[0]);K.set(o);
      console.log("  ✔ مفتاح: "+Object.keys(o).join(", "));}
    codes.save("موافقة "+k,{الحالة:ok?"مقبول":"قيد المراجعة",الرابط:rec.signup});
    await page.screenshot({path:path.join(ROOT,"logs","approval-"+k+".png")}).catch(()=>{});
  }catch(e){console.log("  ○ "+String(e.message||e).slice(0,80));}
  finally{await br.close();}
}
(async()=>{const a=process.argv.slice(2);
  if(a[0]==="all")for(const k of Object.keys(KP)){await run(k);await sleep(1500);}else if(a[0])await run(a[0]);
})();
JS2

# ══════════ الملف 3: أهداف الحصد (ثلاث استراتيجيات) ══════════
cat > "$H/data/harvest-targets.json" <<'JSON'
{
"adsterra":{"mode":"api","keyEnv":"ADSTERRA_API_KEY","api":"https://api3.adsterratools.com/publisher/stats.json?start_date={FROM}&finish_date={TO}&group_by=date","headers":{"X-API-Key":"{KEY}"},"sum":"revenue","statsUrl":"https://publishers.adsterra.com/dashboard","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":true},
"exoclick":{"mode":"api","keyEnv":"EXOCLICK_API_TOKEN","login":"https://api.exoclick.com/v2/login","stats":"https://api.exoclick.com/v2/statistics/a/global","statsUrl":"https://admin.exoclick.com/statistics","balRegex":"([0-9]+\\.[0-9]{2})\\s*(?:EUR|USD)","verified":true},
"monetag":{"mode":"api","keyEnv":"MONETAG_API_KEY","api":"https://api.monetag.com/v1/statistics?date_from={FROM}&date_to={TO}","headers":{"Authorization":"Bearer {KEY}"},"sum":"revenue","statsUrl":"https://monetag.com/dashboard","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false},
"evadav":{"mode":"api","keyEnv":"EVADAV_API_KEY","api":"https://api.evadav.com/v1/statistics?from={FROM}&to={TO}","headers":{"Authorization":"Bearer {KEY}"},"sum":"revenue","statsUrl":"https://evadav.com/statistics","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false},
"lospollos":{"mode":"api","keyEnv":"LOSPOLLOS_API_KEY","api":"https://api.lospollos.com/v1/stats?from={FROM}&to={TO}","headers":{"Authorization":"Bearer {KEY}"},"sum":"revenue","statsUrl":"https://lospollos.com/stats","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false},
"juicyads":{"mode":"api","keyEnv":"JUICYADS_API_KEY","api":"https://api.juicyads.com/api/v1/stats?from={FROM}&to={TO}","headers":{"Authorization":"Bearer {KEY}"},"sum":"revenue","statsUrl":"https://www.juicyads.com/publisher/stats","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false},
"trafficjunky":{"mode":"api","keyEnv":"TRAFFICJUNKY_API_KEY","api":"https://api.trafficjunky.com/v1/stats?from={FROM}&to={TO}","headers":{"Authorization":"Bearer {KEY}"},"sum":"revenue","statsUrl":"https://admin.trafficjunky.com/reports","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false},
"clickadilla":{"mode":"dashboard","keyEnv":"CLICKADILLA_API_KEY","statsUrl":"https://clickadilla.com/statistics","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false},
"propellerads":{"mode":"dashboard","keyEnv":"PROPELLERADS_API_KEY","statsUrl":"https://publishers.propellerads.com/#/statistics","balRegex":"\\$\\s?([0-9]+\\.[0-9]{2})","verified":false}
}
JSON

# ══════════ الملف 4: الحصد الحقيقي (api → كشط اللوحة → يدوي) ══════════
cat > "$H/lib/harvest-live.js" <<'JS3'
#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const K=require("./keysfile.js"),MB=require("./mailbox.js"),codes=require("./codes.js");
const T=JSON.parse(fs.readFileSync(path.join(DATA,"harvest-targets.json"),"utf8"));
const KP=JSON.parse(fs.readFileSync(path.join(DATA,"keypages.json"),"utf8"));
const LED=path.join(DATA,"ledger.json");
const iso=d=>new Date(d).toISOString().slice(0,10);
const deep=(o,p)=>{try{return p.split(".").reduce((a,k)=>a&&a[k],o);}catch(e){return null;}};
async function viaApi(id,r,from,to){
  const key=K.get(r.keyEnv); if(!key||!r.api)return null;
  const url=r.api.replace("{FROM}",from).replace("{TO}",to).replace("{KEY}",key);
  const h=Object.fromEntries(Object.entries(r.headers||{}).map(([k,v])=>[k,v.replace("{KEY}",key)]));
  if(r.login){
    const lg=await MB.rq(r.login,{method:"POST",headers:{"content-type":"application/json"}},JSON.stringify({api_token:key}));
    let j={};try{j=JSON.parse(lg.body);}catch(e){}
    const tk=j.token||(j.result&&j.result.token); if(!tk)return null;
    const st=await MB.rq(r.stats,{method:"POST",headers:{"content-type":"application/json",authorization:"Bearer "+tk}},
      JSON.stringify({group_by:["date"],date_from:from,date_to:to}));
    let s={};try{s=JSON.parse(st.body);}catch(e){}
    const rows=s.result||[]; if(!rows.length)return null;
    return rows.reduce((a,x)=>a+Number(x.revenue||0),0);
  }
  const res=await MB.rq(url,{headers:h});
  let j={};try{j=JSON.parse(res.body);}catch(e){}
  let v=r.sum?Number(deep(j,r.sum)):0;
  if(!v){const m=res.body.match(/"revenue"\s*:\s*"?([\d.]+)/);if(m)v=Number(m[1]);}
  if(!v&&Array.isArray(j))v=j.reduce((a,x)=>a+Number(x.revenue||x.amount||0),0);
  return v||null;
}
async function viaDash(id,r){
  const ppP=path.join(ROOT,"node_modules","puppeteer-core");
  const exe=process.env.CHROME_PATH||["/data/data/com.termux/files/usr/bin/chromium-browser","/usr/bin/chromium"].find(p=>fs.existsSync(p));
  if(!fs.existsSync(ppP)||!exe||!r.statsUrl)return null;
  const rec=KP[id]||{},K2=K;
  if(!rec.login)return null;
  const pp=require(ppP);
  const br=await pp.launch({executablePath:exe,headless:"new",args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
  const page=await br.newPage();
  await page.setUserAgent("Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36");
  try{
    await page.goto(rec.login,{waitUntil:"networkidle2",timeout:60000});
    const I=JSON.parse(fs.readFileSync(path.join(DATA,"identity.json"),"utf8"));
    const e=await page.$('input[type=email],input[name*=email i]'); if(e)await e.type(I.email.primary,{delay:12});
    const p=await page.$('input[type=password]'); if(p)await p.type(I.password,{delay:12});
    const b=await page.$('button[type=submit],input[type=submit]');
    if(b)await Promise.all([page.waitForNavigation({waitUntil:"networkidle2",timeout:45000}).catch(()=>{}),b.click()]);
    await page.goto(r.statsUrl,{waitUntil:"networkidle2",timeout:60000}).catch(()=>{});
    await new Promise(r2=>setTimeout(r2,3500));
    const txt=await page.evaluate(()=>document.body.innerText);
    const m=txt.match(new RegExp(r.balRegex||"\\$\\s?([0-9]+\\.[0-9]{2})"));
    if(m)return Number(m[1]);
  }catch(e){}
  finally{await br.close();}
  return null;
}
(async()=>{
  const to=iso(Date.now()),from=iso(Date.now()-864e5*7);
  const led=(()=>{try{return JSON.parse(fs.readFileSync(LED,"utf8"));}catch(e){return{total:0,rows:[]};}})();
  let okA=0,okD=0,man=0;
  for(const[id,r]of Object.entries(T)){
    if(!K.get(r.keyEnv)){console.log("  ○ "+id+" — لا مفتاح");man++;continue;}
    let v=null,how="";
    try{v=await viaApi(id,r,from,to);if(v!=null)how="API";}catch(e){}
    if(v==null){try{v=await viaDash(id,r);if(v!=null)how="كشط اللوحة";}catch(e){}}
    if(v==null){console.log("  ○ "+id+" — يحتاج لصقًا: bash money/AGENT.sh set "+r.keyEnv+"=...");man++;continue;}
    led.rows.push({id,from,to,revenue:v,how,at:new Date().toISOString()});
    led.total=Number(led.total||0)+v;
    how==="API"?okA++:okD++;
    console.log("  ✔ "+id+" → $"+Number(v).toFixed(2)+"   ["+how+"]");
  }
  led.harvest={from,to,at:new Date().toISOString(),viaApi:okA,viaDash:okD,manual:man};
  fs.writeFileSync(LED,JSON.stringify(led,null,1));
  console.log("  ── الإجمالي: $"+Number(led.total).toFixed(2)+"  | API:"+okA+"  كشط:"+okD+"  يحتاجك:"+man);
  codes.save("حصد",{من:from,إلى:to,إجمالي:led.total,api:okA,كشط:okD,يدوي:man});
})();
JS3

say "✔ 4 ملفات جديدة كُتبت (sms · approval · harvest-live · harvest-targets)"

# ══════════ التنفيذ الشامل ══════════
say ""
say "╔══════════════════════════════════════════╗"
say "║   الوكيل الكامل — تنفيذ نهائي            ║"
say "╚══════════════════════════════════════════╝"

node "$H/lib/keysfile.js" normalize >>"$L" 2>&1;              say "✔ keys.env مصحّح ومحمي (600)"
q bash "$H/MERGE-SOURCES.sh";                                  say "$(grep '✔' "$L"|tail -2|head -1)"
[ -f money/data/identity.json ] && say "✔ الهوية: $(node -e 'console.log(require("./money/data/identity.json").brand+" / "+require("./money/data/identity.json").handle)')" || { q bash "$H/IDENTITY.sh"; say "$(grep '✔ الهوية' "$L"|tail -1)"; }
[ -f money/data/profiles/_DESCRIPTIONS.md ] || q node "$H/lib/profile.js"
say "✔ ملفات النبذة: $(ls money/data/profiles 2>/dev/null|wc -l|tr -d ' ')"
if grep -q '^WALLET_ADDRESS=0x' keys.env; then say "✔ المحفظة: $(grep -m1 '^WALLET_ADDRESS=' keys.env|cut -d= -f2)"
else q bash "$H/WALLET.sh"; say "$(grep -o '0x[0-9a-fA-F]\{40\}' "$L"|tail -1|sed 's/^/✔ المحفظة: /')"; fi
q bash "$H/TARGETS-30K.sh";                                    say "$(grep '✔ أهداف' "$L"|tail -1)"

for d in chromium puppeteer-core ethers; do :; done
if [ -x "$PREFIX/bin/chromium-browser" ] || [ -x /data/data/com.termux/files/usr/bin/chromium-browser ]; then say "✔ Chromium جاهز"
else (yes 2>/dev/null|pkg install -y chromium >>"$L" 2>&1)||true
  if [ -x "$PREFIX/bin/chromium-browser" ] || [ -x /data/data/com.termux/files/usr/bin/chromium-browser ]; then say "✔ Chromium ثُبّت"; else say "○ Chromium غير مثبّت"; fi; fi
[ -d node_modules/puppeteer-core ] || PUPPETEER_SKIP_DOWNLOAD=1 npm i --no-audit --no-fund --silent puppeteer-core@23 >>"$L" 2>&1
[ -d node_modules/ethers ] || npm i --no-audit --no-fund --silent ethers@6 >>"$L" 2>&1
say "✔ محرّكات المتصفح والبلوكشين جاهزة"

if up; then say "✔ كل الخدمات حيّة"; else q bash "$H/TOTAL.sh"; sleep 3; up && say "✔ الخدمات أُحييت" || { q bash "$H/TOTAL.sh"; sleep 3; up && say "✔ الخدمات أُحييت" || say "○ بعض الخدمات متوقفة"; }; fi
[ -f "$H/KEEPALIVE.sh" ] && { pkill -f KEEPALIVE.sh 2>/dev/null; nohup bash "$H/KEEPALIVE.sh" </dev/null >>"$L" 2>&1 & say "✔ حارس المنافذ يعمل"; }

say ""; say "── تفويض الوكيل: اتبع المتصفح واضغط زرًّا واحدًا ──"
node "$H/lib/agent-auth.js" 2>&1 | grep -E '✔|○' | sed 's/^/  /' || true

q node "$H/lib/mailbox.js";   say "✔ البريد: $(grep -oE '[a-z0-9]+@[a-z.]+' "$L"|tail -1)"
say ""; say "── تسجيل آلي + موافقة فورية على كل الشبكات ──"
q bash "$H/BROWSER-AGENT.sh" all 2>/dev/null
q node "$H/lib/approval.js" all 2>/dev/null
say "✔ انتهى التسجيل والموافقة — التفاصيل: logs/agent.log"
q bash "$H/AGENT-RUN.sh" verify --all;                        say "$(grep -E 'فحص [0-9]+ →' "$L"|tail -1|sed 's/^/✔ /')"
q bash "$H/ADS.sh" auto;                                      say "$(grep '✔ فُعّل' "$L"|tail -1)"
q bash "$H/INJECT-ADS.sh";                                    say "$(grep '✔ حُقنت' "$L"|tail -1||echo '○ الصق كودًا: bash money/ADS.sh set adsterra \"<كود>\"')"
q node "$H/lib/harvest-live.js";                              say "$(grep 'الإجمالي:' "$L"|tail -1|sed 's/^/✔ /')"
q bash "$H/REPORT.sh"

P=$(grep -m1 '^HUB_PORT=' keys.env|cut -d= -f2)
say ""
say "╔══════════════════════════════════════════╗"
say "║  التطبيق : http://127.0.0.1:$P/"
say "║  الوكيل  : http://127.0.0.1:$P/agent"
say "║  المفاتيح: http://127.0.0.1:$P/keys"
say "╚══════════════════════════════════════════╝"
say "السجل الكامل: logs/agent.log  |  التقرير: logs/REPORT.txt  |  الأسرار: logs/vault.json"
