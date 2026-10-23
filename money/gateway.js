#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path"),crypto=require("crypto"),https=require("https");
const HERE=__dirname, ROOT=path.resolve(HERE,".."), DATA=path.join(HERE,"data");
fs.mkdirSync(DATA,{recursive:true}); fs.mkdirSync(path.join(ROOT,"logs"),{recursive:true});
const loadEnv=p=>{const o={};try{for(const l of fs.readFileSync(p,"utf8").split(/\r?\n/)){const m=l.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);if(m)o[m[1]]=m[2].trim().replace(/^["']|["']$/g,"");}}catch(e){}return o;};
const ENV=Object.assign({},loadEnv(path.join(ROOT,".env")),loadEnv(path.join(ROOT,"keys.env")),loadEnv(path.join(DATA,"keys.live.env")),process.env);
const PORT=parseInt(ENV.PORT||"8787",10), HOST=ENV.HOST||"127.0.0.1";
const AUTO_VERIFY=(ENV.AUTO_VERIFY||"1")!=="0";
const GATE=(ENV.GATE_MODE||"strict")!=="off";
const F={keys:path.join(DATA,"keys-status.json"),users:path.join(DATA,"users.json"),ledger:path.join(DATA,"ledger.json"),earn:path.join(DATA,"earnings-live.json")};
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>{const t=f+".tmp";fs.writeFileSync(t,JSON.stringify(o,null,2));fs.renameSync(t,f);};
const SECRET=ENV.LICENSE_SECRET||"change-me";
const sign=s=>crypto.createHmac("sha256",SECRET).update(s).digest("hex").slice(0,40);
const canon=r=>[r.ts,r.net,r.date,r.amount.toFixed(6),r.currency,r.usd.toFixed(6),r.source,r.uid||"-"].join("|");
const H=(p,c)=>crypto.createHash("sha256").update(p+"|"+c).digest("hex");
function ledgerAdd(e){const d=rd(F.ledger,{chain:[],keys:[],total:0});const ks=new Set(d.keys);const k=e.key||`${e.net}|${e.date}`;
 if(ks.has(k))return false;const prev=d.chain.length?d.chain[d.chain.length-1].hash:"0".repeat(64);
 const r={ts:Math.floor(Date.now()/1000),net:e.net,date:e.date,amount:+(+e.amount).toFixed(6),currency:e.currency||"USD",usd:+(+(e.usd??e.amount)).toFixed(6),source:e.source||"postback",uid:e.uid||"-",prev};
 r.hash=H(prev,canon(r));d.chain.push(r);d.keys.push(k);d.total=+(d.total+r.usd).toFixed(6);wr(F.ledger,d);return true;}
const users=()=>rd(F.users,{users:{}});
const lic=em=>"CH-"+crypto.createHmac("sha256",SECRET).update("lic:"+em).digest("hex").slice(0,16).toUpperCase().replace(/(.{4})(?=.)/g,"$1-");
const cookies=r=>Object.fromEntries((r.headers.cookie||"").split(";").map(s=>s.trim().split("=")).filter(a=>a[0]).map(a=>[a[0],decodeURIComponent(a[1]||"")]));
function sess(req){const c=cookies(req).ch;if(!c)return null;const p=c.split(".");if(p.length<3)return null;const[uid,exp,sig]=p;
 if(sig!==sign(uid+"."+exp))return null;if(+exp<Date.now())return null;return uid;}
const mkCookie=uid=>{const exp=Date.now()+30*864e5,b=uid+"."+exp;return `ch=${b}.${sign(b)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000`;};
const send=(res,code,obj,extra={})=>{res.writeHead(code,Object.assign({"content-type":"application/json; charset=utf-8","access-control-allow-origin":"*","cache-control":"no-store"},extra));res.end(JSON.stringify(obj,null,2));};
const keysStatus=()=>rd(F.keys,{checked_at:null,summary:{live:0,dead:0,missing:0},keys:[]});
const keyLive=n=>{const k=keysStatus().keys.find(x=>x.id===n);return !!k&&k.status==="LIVE";};
const FEAT={adsense:["ADSENSE_CLIENT"],adsterra:["ADSTERRA_API_KEY"],telegram:["TELEGRAM_BOT_TOKEN","TG_CHAT_ID"],stripe:["STRIPE_SECRET_KEY"],payout:["WALLET_PRIVATE_KEY"]};
const featOn=n=>keyLive(n)&&(FEAT[n]||[]).every(v=>ENV[v]);
function tg(text){if(!ENV.TELEGRAM_BOT_TOKEN||!ENV.TG_CHAT_ID)return Promise.resolve(false);
 return new Promise(r=>{const q=https.request({host:"api.telegram.org",path:`/bot${ENV.TELEGRAM_BOT_TOKEN}/sendMessage`,method:"POST",headers:{"content-type":"application/json"}},x=>{x.resume();r(true);});q.on("error",()=>r(false));q.write(JSON.stringify({chat_id:ENV.TG_CHAT_ID,text}));q.end();});}
const MIME={".html":"text/html; charset=utf-8",".js":"text/javascript; charset=utf-8",".css":"text/css",".json":"application/json",".svg":"image/svg+xml",".png":"image/png",".jpg":"image/jpeg",".webp":"image/webp",".ico":"image/x-icon",".xml":"application/xml",".txt":"text/plain",".woff2":"font/woff2"};
const OPEN=new Set(["/gate.html","/login.html","/signup.html","/install.html","/404.html"]);
const body=req=>new Promise(r=>{let b="";req.on("data",c=>b+=c);req.on("end",()=>{try{r(JSON.parse(b||"{}"));}catch(e){r({});}});});
const logCode=(em,code)=>{const l=`${new Date().toISOString()}  ${em}  ${code}\n`;
 try{fs.appendFileSync(path.join(ROOT,"logs","codes.log"),l);}catch(e){} try{fs.writeFileSync(path.join(DATA,"last-code.txt"),em+" "+code+"\n");}catch(e){}
 console.log("  رمز الدخول: "+code+"  ->  "+em);};

const GATEPAGE=`<!doctype html><html lang=ar dir=rtl><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>دخول CineHub</title><style>
body{margin:0;font:16px/1.7 system-ui,Segoe UI,Tahoma;background:#0b0e14;color:#e8eef7;display:grid;place-items:center;min-height:100vh}
.c{width:min(440px,93vw);background:#141a24;border:1px solid #223;border-radius:16px;padding:26px}
h1{margin:0 0 4px;font-size:22px}p{color:#8fa2b8;font-size:13px;margin:6px 0}
input{width:100%;padding:12px;margin:7px 0;background:#0b0e14;border:1px solid #24303f;border-radius:9px;color:#fff;box-sizing:border-box;font-size:15px}
button{width:100%;padding:12px;margin-top:7px;background:#3b82f6;border:0;border-radius:9px;color:#fff;font-weight:600;cursor:pointer;font-size:15px}
.g{background:#1f2937}.code{font:700 34px/1.2 ui-monospace,monospace;letter-spacing:9px;text-align:center;background:#0b0e14;border:2px dashed #3b82f6;border-radius:12px;padding:14px;margin:12px 0;color:#7dd3fc;cursor:pointer}
.ok{color:#4ade80;font-size:13px;min-height:18px}.err{color:#f87171;font-size:13px;min-height:18px}
.tag{font-size:11px;color:#64748b}</style>
<div class="c"><h1>🎬 CineHub</h1><p>التسجيل إلزامي. رمز التوثيق يظهر هنا مباشرة.</p>
<div id="s"><input id="e" type="email" placeholder="بريدك الإلكتروني" autocomplete="email"><button onclick="signup()">دخول / إنشاء حساب</button><div class="err" id="e0"></div></div>
<div id="v" style="display:none"><p>رمزك (اضغط للنسخ):</p><div class="code" id="code" onclick="copy()">------</div>
<input id="c" inputmode=numeric placeholder="أدخل الرمز" style="text-align:center;letter-spacing:6px;font-size:20px">
<button onclick="verify()">توثيق ودخول</button><button class="g" onclick="login()">لدي حساب موثّق — دخول مباشر</button>
<div class="ok" id="m2"></div><div class="err" id="e2"></div></div>
<p class="tag">رمزك محفوظ في logs/codes.log أيضًا</p></div><script>
const q=new URLSearchParams(location.search),next=q.get("next")||"/";let em="",t=null;
const $=i=>document.getElementById(i);
function copy(){navigator.clipboard&&navigator.clipboard.writeText($("code").textContent);$("m2").textContent="نُسخ";}
async function signup(){em=$("e").value.trim();$("e0").textContent="";if(!em)return;
 const d=await(await fetch("/api/signup",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({email:em,device:navigator.userAgent.slice(0,120)})})).json();
 if(!d.ok)return $("e0").textContent=d.error||"خطأ";
 if(d.verified){$("m2").textContent="تم الدخول";return location.href=next;}
 $("s").style.display="none";$("v").style.display="block";$("code").textContent=d.code;$("c").value=d.code;
 $("m2").textContent=d.sent?"أُرسل أيضًا إلى تيليجرام":"";
 clearInterval(t);t=setInterval(()=>verify(true),4000);}
async function verify(auto){const code=$("c").value.trim();if(code.length!==6)return;
 const d=await(await fetch("/api/verify",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({email:em,code})})).json();
 if(d.ok){clearInterval(t);$("m2").textContent="تم التوثيق ✔ رخصتك: "+d.license;setTimeout(()=>location.href=next,700);}else if(!auto)$("e2").textContent=d.error||"رمز خاطئ";}
async function login(){em=$("e").value.trim()||em;if(!em)return $("e0").textContent="أدخل بريدك";
 const d=await(await fetch("/api/login",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({email:em})})).json();
 if(d.ok)return location.href=next; if(d.code){$("s").style.display="none";$("v").style.display="block";$("code").textContent=d.code;$("c").value=d.code;}
 else $("e0").textContent=d.error||"غير موثّق";}
</script></html>`;

http.createServer(async(req,res)=>{const u=new URL(req.url,"http://x"),p=decodeURIComponent(u.pathname);
 try{
  if(p==="/api/status"){const s=keysStatus();return send(res,200,{ok:true,uptime:Math.round(process.uptime()),gate:GATE,auto_verify:AUTO_VERIFY,
    keys:s.summary,features:Object.fromEntries(Object.keys(FEAT).map(k=>[k,featOn(k)])),users:Object.keys(users().users||{}).length,
    ledger:rd(F.ledger,{chain:[],total:0}).total,last_code:fs.existsSync(path.join(DATA,"last-code.txt"))?fs.readFileSync(path.join(DATA,"last-code.txt"),"utf8").trim():null});}
  if(p==="/api/code"){const em=(u.searchParams.get("email")||"").toLowerCase();const D=users();
    const id=Object.keys(D.users||{}).find(k=>D.users[k].email===em);
    if(!id)return send(res,404,{ok:false,error:"لا يوجد حساب"});
    return send(res,200,{ok:true,code:D.users[id].code||null,verified:!!D.users[id].verified,license:D.users[id].license});}
  if(p==="/api/signup"&&req.method==="POST"){const b=await body(req);const em=(b.email||"").toLowerCase().trim();
    if(!/^[^@\s]+@[^@\s]+\.[a-z]{2,}$/i.test(em))return send(res,400,{ok:false,error:"بريد غير صالح"});
    const D=users();D.users=D.users||{};const id=crypto.createHash("sha1").update(em).digest("hex").slice(0,12);
    const code=String(Math.floor(100000+Math.random()*900000));
    D.users[id]=Object.assign(D.users[id]||{},{id,email:em,license:D.users[id]?.license||lic(em),code,code_exp:Date.now()+900000,device:b.device||"",created:D.users[id]?.created||new Date().toISOString()});
    const canSend=featOn("telegram");let verified=!!D.users[id].verified;
    if(!canSend&&AUTO_VERIFY){D.users[id].verified=true;verified=true;D.users[id].verified_at=new Date().toISOString();}
    wr(F.users,D); logCode(em,code);
    if(canSend)await tg(`CineHub — رمز الدخول: ${code}`);
    const extra=verified?{"Set-Cookie":mkCookie(id)}:{};
    return send(res,200,{ok:true,id,sent:canSend,verified,code,license:D.users[id].license},extra);}
  if(p==="/api/verify"&&req.method==="POST"){const b=await body(req);const em=(b.email||"").toLowerCase().trim();const D=users();
    const id=Object.keys(D.users||{}).find(k=>D.users[k].email===em);if(!id)return send(res,404,{ok:false,error:"لا يوجد حساب"});
    const U=D.users[id];if(String(b.code||"").trim()!==String(U.code))return send(res,400,{ok:false,error:"رمز خاطئ"});
    if(U.code_exp&&Date.now()>U.code_exp)return send(res,400,{ok:false,error:"انتهت صلاحية الرمز"});
    U.verified=true;U.verified_at=new Date().toISOString();delete U.code;wr(F.users,D);
    return send(res,200,{ok:true,id,license:U.license},{"Set-Cookie":mkCookie(id)});}
  if(p==="/api/login"&&req.method==="POST"){const b=await body(req);const em=(b.email||"").toLowerCase().trim();const D=users();
    const id=Object.keys(D.users||{}).find(k=>D.users[k].email===em);if(!id)return send(res,404,{ok:false,error:"لا يوجد حساب"});
    const U=D.users[id];if(U.verified)return send(res,200,{ok:true,license:U.license},{"Set-Cookie":mkCookie(id)});
    return send(res,200,{ok:false,need_code:true,code:U.code,error:"غير موثّق"});}
  if(p==="/api/me"){const uid=sess(req);if(!uid)return send(res,401,{ok:false,error:"unauth"});
    const U=users().users[uid];if(!U)return send(res,401,{ok:false,error:"unknown"});
    if(!U.verified)return send(res,403,{ok:false,error:"unverified"});U.last_seen=new Date().toISOString();wr(F.users,users());
    return send(res,200,{ok:true,user:{id:U.id,email:U.email,license:U.license,earnings:U.earnings||0}});}
  if(p==="/api/earnings")return send(res,200,rd(F.earn,{total:0,per_network:{}}));
  if(p==="/api/ledger"){const l=rd(F.ledger,{chain:[],total:0});return send(res,200,{total:l.total,entries:l.chain.length,head:l.chain.length?l.chain[l.chain.length-1].hash:null});}
  if(p==="/api/postback"){const q=u.searchParams,net=q.get("net")||"unknown",amount=parseFloat(q.get("amount")||"0"),
    uid=q.get("uid")||"-",date=q.get("date")||new Date().toISOString().slice(0,10);
    if(!(amount>0))return send(res,400,{ok:false,error:"amount"});
    if(ENV.POSTBACK_SECRET){const sig=q.get("sig")||"",raw=`${net}|${amount}|${uid}|${date}`;
      const want=crypto.createHmac("sha256",ENV.POSTBACK_SECRET).update(raw).digest("hex");
      if(sig!==want&&sig!==sign(raw))return send(res,403,{ok:false,error:"bad_sig",want});}
    const added=ledgerAdd({net,date,amount,usd:amount,currency:q.get("cur")||"USD",source:"postback",uid,key:`${net}|${date}|${amount}|${uid}`});
    if(added&&uid!=="-"){const D=users();if(D.users&&D.users[uid]){D.users[uid].earnings=+((D.users[uid].earnings||0)+amount).toFixed(6);wr(F.users,D);}}
    return send(res,200,{ok:true,added,ledger:rd(F.ledger,{total:0}).total});}
  if(p==="/api/config.js"||p==="/config.js"){const uid=sess(req),U=uid?users().users[uid]:null;
    return send(res,200,{keys:{adsense:ENV.ADSENSE_CLIENT||"",adsterra:ENV.ADSTERRA_PUB_ID||""},
      features:Object.fromEntries(Object.keys(FEAT).map(k=>[k,featOn(k)])),gate:GATE,
      user:U?{id:U.id,verified:U.verified,license:U.license}:null},{"content-type":"text/javascript; charset=utf-8"});}
  if(p==="/gate.html"||p==="/login.html"||p==="/signup.html")return res.writeHead(200,{"content-type":"text/html; charset=utf-8","cache-control":"no-store"}),res.end(GATEPAGE);
  if(GATE&&!OPEN.has(p)&&(p==="/"||p.endsWith(".html"))&&!sess(req))return res.writeHead(302,{Location:"/gate.html?next="+encodeURIComponent(p)}),res.end();
  let f=path.join(ROOT,p);if(p.endsWith("/"))f=path.join(f,"index.html");
  if(!f.startsWith(ROOT))f=path.join(ROOT,"index.html");
  if(fs.existsSync(f)&&fs.statSync(f).isDirectory())f=path.join(f,"index.html");
  if(!fs.existsSync(f))f=path.join(ROOT,"404.html");
  if(!fs.existsSync(f))return res.writeHead(404),res.end("404");
  const ext=path.extname(f).toLowerCase();
  res.writeHead(200,{"content-type":MIME[ext]||"application/octet-stream","cache-control":ext===".html"?"no-store":"public, max-age=3600"});
  fs.createReadStream(f).pipe(res);
 }catch(e){send(res,500,{ok:false,error:String(e.message||e)});}
}).listen(PORT,HOST,()=>{const s=keysStatus();
 console.log(`gateway up http://${HOST}:${PORT} | gate=${GATE?"ON":"OFF"} auto_verify=${AUTO_VERIFY?"ON":"OFF"}`);
 console.log(`keys live=${s.summary.live} set=${s.summary.set||0} missing=${s.summary.missing}`);
 console.log(`البوابة: http://${HOST}:${PORT}/gate.html`);});
