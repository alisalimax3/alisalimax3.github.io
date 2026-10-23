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
