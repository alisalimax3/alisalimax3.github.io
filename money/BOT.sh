#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  الوكيل الحيّ — يعمل باسمك على هاتفك، يستمر حتى توقفه
#  الاستخدام:  bash money/BOT.sh [start|stop|status|once|log|install]
# ══════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
D="$H/data"; mkdir -p "$D" logs money/assets; [ -f keys.env ] || touch keys.env; chmod 600 keys.env
PID="$D/bot.pid"; ST="$D/bot-state.json"; L="$ROOT/logs/bot.log"
CMD="${1:-start}"

# ════════ الملف 1: الجسر مع أندرويد ════════
cat > "$H/lib/notify.js" <<'JSN'
#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process");
const ID="cinehub";
const run=(c,a,cb)=>execFile(c,a,{timeout:9000},()=>cb&&cb());
const has=c=>new Promise(r=>execFile("which",[c],e=>r(!e)));
function notify(o){
  const a=["--id",ID,"--title",o.title||"CineHub","--content",o.content||"","--priority","high"];
  if(o.ongoing)a.push("--ongoing");
  if(o.progress!=null)a.push("--progress",String(Math.round(o.progress)),"--max","100");
  if(o.big)a.push("--big-text",o.big);
  run("termux-notification",a);
}
const toast=m=>run("termux-toast",["-g","bottom","-c","#2563eb","-b","#0b0e14",String(m).slice(0,220)]);
const vibrate=(d=250)=>run("termux-vibrate",["-d",String(d)]);
const clear=()=>run("termux-notification-remove",["--id",ID]);
const clip=()=>new Promise(r=>execFile("termux-clipboard-get",[],{timeout:6000},(e,so)=>r(String(so||"").trim())));
const sms=(n=12)=>new Promise(r=>execFile("termux-sms-list",["-l",String(n)],{timeout:9000},(e,so)=>{try{r(JSON.parse(so)||[]);}catch(x){r([]);}}));
const clipSet=t=>run("termux-clipboard-set",[String(t)]);
module.exports={notify,toast,vibrate,clear,clip,sms,clipSet,has,ID};
if(require.main===module){const[,,c,...a]=process.argv;
  if(c==="test"){notify({title:"CineHub",content:"الوكيل يعمل باسمك",ongoing:1});toast("✔ الجسر مع أندرويد يعمل");vibrate(300);}
  else if(c==="clear")clear();}
JSN

# ════════ الملف 2: التقاط الرموز من شريحتك + الحافظة ════════
cat > "$H/lib/intercept.js" <<'JSI'
#!/usr/bin/env node
"use strict";
// يقرأ SMS برقمك والحافظة — كأنه أنت
const fs=require("fs"),path=require("path");
const N=require("./notify.js"),K=require("./keysfile.js");
const D=path.resolve(__dirname,"..","data"),S=path.join(D,"intercept.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(S,"utf8"));}catch(e){return{otp:[],clip:""};}};
const wr=o=>fs.writeFileSync(S,JSON.stringify(o,null,1));
const TOK=/^[A-Za-z0-9_\-]{20,90}$/;
const SITE=/adsterra|monetag|exoclick|juicyads|trafficjunky|evadav|push\.house|clickadilla|propellerads|admaven|hilltopads|galaksion|cpagrip|bitlabs|ayet|offertoro|mylead|lospollos|crakrevenue|monetag/i;

async function checkSms(){
  const st=rd(),out=[];
  const msgs=await N.sms(12);
  for(const m of msgs){
    const key=String(m.number||"")+"|"+String(m.body||"").slice(0,40);
    if(st.otp.includes(key))continue;
    const code=(String(m.body||"").match(/\b(\d{4,8})\b/)||[])[1];
    if(code&&SITE.test(String(m.body||""))||code&&/code|otp|verif|رمز/i.test(String(m.body||""))){
      st.otp.push(key);out.push(code);
      K.set({LAST_OTP:code,LAST_OTP_AT:new Date().toISOString()});
      N.notify({title:"CineHub · رمز تحقق",content:code,ongoing:0});
      N.vibrate(180);
      console.log("  ✔ رمز من رسالة هاتفك: "+code);
    }
  }
  wr(st);return out;
}
async function checkClip(){
  const st=rd(),txt=await N.clip();
  if(!txt||txt===st.clip||!TOK.test(txt))return null;
  st.clip=txt;wr(st);
  // ابحث عن مفتاح متوقّع: المنصّة الحالية في الطابور
  let want="";
  try{const q=JSON.parse(fs.readFileSync(path.join(D,"queue.json"),"utf8"));
    const cur=q.current;
    if(cur){const src=JSON.parse(fs.readFileSync(path.join(__dirname,"..","sources-big.json"),"utf8")).find(x=>x.id===cur);
      if(src)want=src.env.find(e=>!K.get(e))||"";}
  }catch(e){}
  if(!want)return null;
  K.set({[want]:txt});
  console.log("  ✔ التقطتُ من حافظتك → "+want);
  N.notify({title:"CineHub · مفتاح جديد",content:want+" محفوظ",ongoing:0});N.vibrate(200);
  return {key:want,value:txt};
}
module.exports={checkSms,checkClip};
if(require.main===module){const[,,c]=process.argv;
  if(c==="sms")checkSms().then(()=>console.log("  انتهى"));
  else if(c==="clip")checkClip().then(r=>console.log(r?"  ✔ "+r.key:"  ○ لا جديد"));
  else{checkSms().then(checkClip);}}
JSI

# ════════ الملف 3: الحلقة الحيّة ════════
cat > "$H/lib/daemon.js" <<'JSD'
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
JSD

# ════════ الملف 4: وظيفة أندرويد مجدولة (تعمل بعد إغلاق Termux) ════════
cat > "$H/JOB.sh" <<'JSJ'
#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"
[ -f "$ROOT/money/data/bot.pid" ] && kill -0 "$(cat "$ROOT/money/data/bot.pid")" 2>/dev/null && exit 0
exec bash "$H/BOT.sh" start
JSJ

# ══════════════════════════════════════════════════════════════════
case "$CMD" in

install)
  echo "── تجاوز صلاحيات أندرويد (مرة واحدة) ──"
  pkg install -y termux-api root-repo >/dev/null 2>&1 || pkg install -y termux-api >/dev/null 2>&1
  command -v termux-notification >/dev/null 2>&1 && echo "  ✔ termux-api مثبّت" || echo "  ⚠ ثبّت تطبيق Termux:API من F-Droid"
  termux-setup-storage 2>/dev/null; echo "  ✔ صلاحية التخزين"
  termux-wake-lock 2>/dev/null; echo "  ✔ منع نوم المعالج"
  termux-job-scheduler --script "$H/JOB.sh" --job-id 3099 --period-ms 900000 --network any --persisted true >/dev/null 2>&1 \
    && echo "  ✔ وظيفة أندرويد مجدولة (تعمل بعد إغلاق Termux وبعد إعادة التشغيل)" || echo "  ○ الجدولة تحتاج termux-api"
  echo "  ⚠ اذهب إلى: الإعدادات ← التطبيقات ← Termux ← البطارية ← بلا قيود"
  ;;

start)
  if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then echo "  ✔ يعمل مسبقًا (pid $(cat "$PID")) — أوقفه بـ: bash money/BOT.sh stop"; exit 0; fi
  bash "$H/BOT.sh" install >/dev/null 2>&1
  nohup node "$H/lib/daemon.js" </dev/null >>"$L" 2>&1 &
  sleep 3
  if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then
    echo "  ✔ الوكيل يعمل الآن باسمك (pid $(cat "$PID"))"
    echo "  ✔ إشعار ثابت على شاشتك يعرض الحالة لحظة بلحظة"
    echo "  ⏹ للإيقاف: bash money/BOT.sh stop"
  else echo "  ✗ لم يبدأ — راجع logs/bot.log"; fi
  ;;

stop)
  if [ -f "$PID" ]; then kill "$(cat "$PID")" 2>/dev/null; sleep 1; kill -9 "$(cat "$PID")" 2>/dev/null
    node -e 'require(process.argv[1]).clear()' "$H/lib/notify.js" 2>/dev/null
    echo "  ⏹ أوقفتُ الوكيل"; else echo "  ○ لا يعمل"; fi
  ;;

status)
  node - "$H" <<'JSS'
const fs=require("fs"),path=require("path"),H=process.argv[2],D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const pid=fs.existsSync(path.join(D,"bot.pid"))?Number(fs.readFileSync(path.join(D,"bot.pid"),"utf8")):0;
let live=false;try{process.kill(pid,0);live=true;}catch(e){}
const s=rd(path.join(D,"bot-state.json"),{}),led=rd(path.join(D,"ledger.json"),{total:0});
const k=rd(path.join(D,"keys-status.json"),{summary:{}});
console.log("  الحالة   : "+(live?"يعمل باسمك (pid "+pid+")":"متوقف"));
console.log("  دورات    : "+(s.cycles||0)+"   |  مفاتيح ملقوطة: "+(s.keys||0)+"   |  أخطاء: "+(s.errors||0));
console.log("  أرباح    : $"+(Number(led.total||0)).toFixed(2)+"   |  مسحوب: $"+(Number(s.lastMoney||0)).toFixed(2));
console.log("  مصادر حيّة: "+(k.summary&&k.summary.live||0)+"   |  محجوبة: "+(k.summary&&k.summary.blocked||0));
JSS
  ;;

once)  node "$H/lib/intercept.js"; node "$H/lib/daemon.js" >/dev/null 2>&1 & sleep 2; node "$H/lib/intercept.js" ;;
log)   tail -40 "$L" ;;
*)     echo "الأوامر: install | start | stop | status | once | log" ;;
esac
