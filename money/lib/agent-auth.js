#!/usr/bin/env node
"use strict";
// يفتح صفحة في المتصفح → ضغطة واحدة → توكن تفويض للوكيل
const http=require("http"),crypto=require("crypto"),{execFile}=require("child_process");
const K=require("./keysfile.js"),codes=require("./codes.js");
const PORT=parseInt(process.env.AUTHZ_PORT||"8791",10);
let token=K.get("AGENT_TOKEN");
if(!token){token=crypto.randomBytes(24).toString("base64url");K.set({AGENT_TOKEN:token});}
let authorized=!!K.get("AGENT_AUTHORIZED_AT");
const id=(()=>{try{return JSON.parse(require("fs").readFileSync(require("path").join(__dirname,"..","data","identity.json"),"utf8"));}catch(e){return{brand:"CineHub",handle:"cinehub"};}})();
const page=ok=>`<!doctype html><html lang=ar dir=rtl><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>تفويض الوكيل</title><style>body{margin:0;font:16px/1.75 system-ui,Tahoma;background:#0b0e14;color:#e8eef7;display:grid;place-items:center;min-height:100vh;padding:16px}
.c{background:#141a24;border:1px solid #223;border-radius:18px;padding:28px;max-width:600px;width:100%;text-align:center}
h1{font-size:21px;margin:0 0 10px}.m{color:#9fb0c6;font-size:14px;margin-bottom:20px;text-align:right}
ul{text-align:right;color:#cbd5e1;font-size:14px;padding-inline-start:20px;margin:0 0 18px}
button{background:#2563eb;color:#fff;border:0;padding:14px 30px;border-radius:11px;font-size:17px;cursor:pointer;font-weight:700}
button:disabled{opacity:.6}code{background:#0b0e14;padding:4px 8px;border-radius:6px;font-size:11px;color:#7dd3fc;word-break:break-all;display:block;margin-top:16px}
.ok{color:#4ade80}.b{color:#7dd3fc}</style>
<div class=c><h1>${ok?"✔ الوكيل مُفوَّض":"🤖 تفويض الوكيل المحلي"}</h1>
<div class=m>${ok?"أُصدر التوكن وحُفظ في <code>keys.env</code>. أغلق الصفحة.":
`<b class=b>${id.brand}</b> — سيُفوَّض الوكيل على هويتك <code>${id.handle}</code> للقيام بـ:
<ul><li>فتح صفحات التسجيل وملؤها وتجاوز الكابتشا</li><li>تأكيد البريد آليًا والدخول</li>
<li>التقاط مفاتيح API وربطها بالتطبيق</li><li>تفعيل الإعلانات وحقنها في صفحات التطبيق</li>
<li>حصد الأرباح على المحفظة والسحب</li></ul>اضغط مرة واحدة للتفويض.`}</div>
${ok?"":'<button id=b onclick="go()">تفويض الآن</button>'}
<code>AGENT_TOKEN=${token.slice(0,16)}…</code></div>
<script>async function go(){const b=document.getElementById("b");b.disabled=1;b.textContent="…";await fetch("/ok");location.reload();}</script></html>`;
let hits=0;
const srv=http.createServer((req,res)=>{
  if(req.url.startsWith("/ok")){hits++;
    if(!authorized){authorized=true;K.set({AGENT_AUTHORIZED_AT:new Date().toISOString()});
      codes.save("تفويض الوكيل",{الحالة:"مُفوَّض",التوكن:token,الوقت:new Date().toISOString()});}
    res.writeHead(200,{"content-type":"text/plain"});return res.end("ok");}
  res.writeHead(200,{"content-type":"text/html; charset=utf-8"});res.end(page(authorized));
});
srv.listen(PORT,()=>{
  const u="http://127.0.0.1:"+PORT+"/";
  execFile("termux-open-url",[u],()=>{});
  console.log("  ✔ صفحة التفويض فُتحت في متصفحك");
  if(authorized){console.log("  ✔ الوكيل مُفوَّض مسبقًا");}
  const t0=Date.now();
  const iv=setInterval(()=>{
    if(hits>0||Date.now()-t0>120000){clearInterval(iv);srv.close();
      console.log(hits>0?"  ✔ تم التفويض — الوكيل يعمل باسمك":"  ○ لم يُضغط الزر (التوكن صالح على أي حال)");
      process.exit(0);}
  },1000);
});
