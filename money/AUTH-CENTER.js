#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=__dirname,ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const KEYS=path.join(ROOT,"keys.env");
const PORT=(function(){var p=parseInt(process.env.AUTH_PORT||"0",10);if(p)return p;
  try{var m=fs.readFileSync(KEYS,"utf8").match(/^AUTH_PORT=([0-9]+)/m);if(m)return parseInt(m[1],10);}catch(e){}return 8799;})();
const CATS=[["movie","🎬 أفلام"],["series","📺 مسلسلات"],["adult","🔞 البالغين — أرباح ضخمة"],["channel","📣 قنوات ونشر"],["ads","💵 إعلانات"],["pay","🏦 دفع"],["crypto","🪙 عملات"],["infra","⚙️ بنية"],["ai","🧠 ذكاء"],["fx","💱 صرف"]];
const STEPS={
 telegram:["افتح t.me/BotFather","أرسل /newbot ثم اختر أي اسم","ستصلك رسالة فيها رمز مثل 123456:ABC-xyz ← هذا TELEGRAM_BOT_TOKEN","أرسل أي رسالة للبوت الذي أنشأته","افتح api.telegram.org/bot<الرمز>/getUpdates وابحث عن chat ثم id ← هذا TG_CHAT_ID"],
 exoclick:["اضغط افتح التسجيل","اختر Publisher (مهم — ليس Advertiser)","البريد وكلمة مرور قوية ثم أكمل النموذج","بعد الدخول: My Profile ← API Token ← Create ← انسخه هنا","ثم Sites & Zones ← أضف موقعك ← أنشئ Zone ← الرقم هو EXOCLICK_ZONE"],
 adsterra:["اضغط افتح التسجيل","سجّل بحساب جوجل مباشرة","بعد الدخول: Settings ← API ← Generate token ← انسخه","PUB_ID يظهر في Dashboard"],
 crakrevenue:["اضغط افتح التسجيل","سجّل بحساب جوجل","بعد القبول: Account ← API Settings ← انسخ المفتاح"],
 trafficjunky:["افتح التسجيل واختر Publisher","أكمل النموذج بالبريد","بعد القبول: Account ← API ← انسخ"],
 lospollos:["افتح التسجيل","أكمل النموذج","بعد القبول: Settings ← API Key"],
 chaturbate:["افتح صفحة الأفلييت","سجّل بياناتك","USERNAME = اسم حسابك، CAMPAIGN = الرمز الذي يعطونه"],
 awempire:["افتح التسجيل","اختر Webmaster/Promoter","بعد القبول: Tools ← API"],
 tmdb:["سجّل بحساب جوجل أو بريد","Settings ← API ← Request an API Key ← Developer","الرمز يظهر فورًا"],
 omdb:["املأ النموذج بالبريد","تصلك رسالة تفعيل ← اضغط الرابط","الرمز في نفس الرسالة"],
 watchmode:["افتح api.watchmode.com/requestApiKey","املأ البريد ← الرمز يظهر فورًا"],
 trakt:["سجّل ← Settings ← Your API Apps ← New Application","Client ID يظهر فورًا"],
 github:["افتح github.com/settings/tokens","Generate new token (classic)","اختر صلاحية repo فقط","انسخه هنا وضعه في GITHUB_TOKEN"],
 cloudflare:["افتح dash.cloudflare.com/profile/api-tokens","Create Token ← قالب Edit zone","انسخه"]
};
const loadEnv=function(){var o={};try{fs.readFileSync(KEYS,"utf8").split(/\r?\n/).forEach(function(l){var m=l.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);if(m)o[m[1]]=m[2].trim();});}catch(e){}return o;};
const st=function(){try{return JSON.parse(fs.readFileSync(path.join(DATA,"keys-status.json"),"utf8"));}catch(e){return{keys:[]};}};
const setkv=function(k,v){var t="";try{t=fs.readFileSync(KEYS,"utf8");}catch(e){}
  var re=new RegExp("^"+k+"=[^\\n]*$","m");
  if(re.test(t))t=t.replace(re,k+"="+v);else t+=(t&&!t.endsWith("\n")?"\n":"")+k+"="+v+"\n";
  var tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);try{fs.chmodSync(KEYS,0o600);}catch(e){}};
const src=function(){var out=[],seen={};["sources.json","sources-big.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"].forEach(function(f){try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(function(x){if(x&&x.id&&!seen[x.id]){seen[x.id]=1;out.push(x);}});}catch(e){}});return out;};
const esc=function(s){return String(s==null?"":s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/"/g,"&quot;");};

function page(){
  var env=loadEnv(),s=st(),live={};(s.keys||[]).forEach(function(k){if(k.status==="LIVE")live[k.id]=1;});
  var L=src(),gL=L.filter(function(x){return x.g;}).length;
  var lv=L.filter(function(x){return live[x.id];}).length;
  function card(x){
    var has=x.env.every(function(e){return env[e];}),isLive=live[x.id];
    var b=isLive?'<b class=ok>● حيّ</b>':has?'<b class=warn>◐ يُفحص</b>':'<b class=no>○ ناقص</b>';
    var gg=x.g?'<span class=gg>🔵 تسجيل بجوجل</span>':"";
    var inp=x.env.map(function(e){return '<div class=row><code>'+e+'</code><input data-k="'+e+'" value="'+esc(env[e])+'" placeholder="الصق القيمة"><button class=cp onclick="cp(this)">نسخ الاسم</button></div>';}).join("");
    var stp=(STEPS[x.id]||x.steps||[]).map(function(t,i){return '<li>'+esc(t)+'</li>';}).join("");
    var steps=stp?'<div class=steps hidden><ol>'+stp+'</ol></div>':"";
    var go=x.url&&x.url!=="-"?('<a class=go target=_blank href="'+x.url+'">افتح التسجيل ↗</a><button class=gh onclick="tg(this)">❓ كيف أجيب المفتاح</button>'):'<span class=free>لا يحتاج مفتاح — يعمل تلقائيًا</span>';
    return '<div class=card><div class=head><span>'+esc(x.name)+'</span>'+b+'</div><div class=meta>'+esc(x.note||"")+(x.payout&&x.payout!=="-"?' · <i>دفع: '+esc(x.payout)+'</i>':"")+' '+gg+'</div><div class=acts>'+go+'</div>'+steps+inp+'<button class=save onclick="save(this)">حفظ وتفعيل فورًا</button></div>';
  }
  var secs=CATS.map(function(c){var g=L.filter(function(x){return x.cat===c[0];});if(!g.length)return"";
    return '<h2>'+c[1]+' <small>'+g.filter(function(x){return live[x.id];}).length+'/'+g.length+' حيّ</small></h2><div class=grid>'+g.map(card).join("")+'</div>';}).join("");
  return '<!doctype html><html lang=ar dir=rtl><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1"><title>مركز التفويض</title><style>'+
  'body{margin:0;font:15px/1.6 system-ui,Tahoma;background:#0b0e14;color:#e8eef7;padding:16px}'+
  'h1{font-size:19px;margin:0 0 3px}.sub{color:#8fa2b8;font-size:12px;margin-bottom:10px}'+
  'h2{font-size:15px;margin:22px 0 8px;color:#7dd3fc;border-bottom:1px solid #1e2a3a;padding-bottom:6px}h2 small{color:#64748b;font-weight:400}'+
  '.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(310px,1fr));gap:10px}'+
  '.card{background:#141a24;border:1px solid #223;border-radius:12px;padding:11px}'+
  '.head{display:flex;justify-content:space-between;font-weight:700;margin-bottom:4px}'+
  '.meta{color:#8fa2b8;font-size:12px;margin-bottom:8px}.meta i{color:#facc15}'+
  '.gg{background:#1e3a8a;color:#bfdbfe;border-radius:5px;padding:1px 5px;font-size:10px}'+
  '.acts{display:flex;gap:6px;margin-bottom:8px;flex-wrap:wrap}'+
  '.go{background:#1e3a8a;color:#bfdbfe;text-decoration:none;padding:5px 10px;border-radius:7px;font-size:12px}'+
  '.gh,.cp{background:#24303f;color:#cbd5e1;border:0;border-radius:7px;font-size:11px;padding:5px 8px;cursor:pointer}'+
  '.free{color:#4ade80;font-size:12px}.steps{background:#0b0e14;border:1px dashed #3b82f6;border-radius:8px;padding:8px;margin-bottom:8px}'+
  '.steps ol{margin:0;padding-inline-start:18px;font-size:12px;color:#cbd5e1}.steps li{margin:3px 0}'+
  '.row{display:flex;gap:5px;align-items:center;margin:5px 0}.row code{font-size:10px;color:#94a3b8;min-width:105px;word-break:break-all}'+
  '.row input{flex:1;background:#0b0e14;border:1px solid #24303f;border-radius:7px;color:#fff;padding:6px;font-size:12px}'+
  '.save{width:100%;margin-top:8px;background:#2563eb;border:0;color:#fff;padding:8px;border-radius:7px;cursor:pointer;font-size:12px}'+
  '.ok{color:#4ade80}.no{color:#f87171}.warn{color:#facc15}'+
  '.bar{position:sticky;top:0;background:#0b0e14ee;padding:10px 0;z-index:9;border-bottom:1px solid #1e2a3a}'+
  'textarea{width:100%;height:70px;background:#0b0e14;border:1px solid #24303f;border-radius:8px;color:#fff;padding:8px;font:12px monospace;box-sizing:border-box}'+
  '.bulk{background:#166534;border:0;color:#fff;padding:7px 12px;border-radius:7px;cursor:pointer;font-size:12px;margin-top:5px}'+
  '</style><div class=bar><h1>مركز التفويض — CineHub</h1><div class=sub>حيّ: <b class=ok>'+lv+'</b> / '+L.length+' · بجوجل: <b>'+gL+'</b> موقعًا · المنفذ '+PORT+' · <a href="/api/status" style="color:#7dd3fc">الحالة</a></div>'+
  '<details><summary style="cursor:pointer;font-size:12px;color:#7dd3fc">📥 لصق جماعي (KEY=VALUE في كل سطر)</summary><textarea id=bulk placeholder="ADSTERRA_API_KEY=xxx&#10;EXOCLICK_API_TOKEN=yyy"></textarea><button class=bulk onclick="bulk()">حفظ الكل وتفعيل</button></details></div>'+
  secs+'<script>'+
  'function tg(b){var s=b.closest(".card").querySelector(".steps");if(s)s.hidden=!s.hidden;}'+
  'function cp(b){var t=b.parentNode.querySelector("code").textContent;navigator.clipboard&&navigator.clipboard.writeText(t);b.textContent="✔";}'+
  'async function save(b){b.textContent="...";var i=b.parentNode.querySelectorAll("input");for(var n=0;n<i.length;n++){if(i[n].value.trim())await fetch("/api/setkey",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({k:i[n].dataset.k,v:i[n].value.trim()})});}b.textContent="✔ حُفظ";setTimeout(function(){location.reload();},1400);}'+
  'async function bulk(){var t=document.getElementById("bulk").value;if(!t.trim())return;await fetch("/api/bulk",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({text:t})});location.reload();}'+
  '</script></html>';
}
http.createServer(function(req,res){var u=new URL(req.url,"http://x");
 if(u.pathname==="/")return res.writeHead(200,{"content-type":"text/html; charset=utf-8","cache-control":"no-store"}),res.end(page());
 if(u.pathname==="/api/status"){var s=st();return res.writeHead(200,{"content-type":"application/json"}),res.end(JSON.stringify({summary:s.summary,live:(s.keys||[]).filter(function(k){return k.status==="LIVE";}).map(function(k){return k.id;})},null,2));}
 if(u.pathname==="/api/setkey"&&req.method==="POST"){var b="";req.on("data",function(c){b+=c;});req.on("end",function(){try{var d=JSON.parse(b||"{}");if(d.k&&/^[A-Za-z_][A-Za-z0-9_]*$/.test(d.k))setkv(d.k,String(d.v||""));relink();}catch(e){}res.writeHead(200);res.end('{"ok":true}');});return;}
 if(u.pathname==="/api/bulk"&&req.method==="POST"){var b2="";req.on("data",function(c){b2+=c;});req.on("end",function(){try{var d=JSON.parse(b2||"{}");String(d.text||"").split(/\r?\n/).forEach(function(l){var m=l.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/);if(m)setkv(m[1],m[2].trim());});relink();}catch(e){}res.writeHead(200);res.end('{"ok":true}');});return;}
 res.writeHead(404);res.end("x");}).listen(PORT,function(){console.log("  ✔ مركز التفويض على "+PORT);});
function relink(){execFile("bash",[path.join(HERE,"lib","derive.sh")],function(){execFile("bash",[path.join(HERE,"KEYCHECK.sh")],function(){execFile("bash",[path.join(HERE,"WIRE.sh")],function(){});});});}
