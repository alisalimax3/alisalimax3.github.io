#!/usr/bin/env node
"use strict";
const http=require("http"),fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,".."),KEYS=path.join(ROOT,"keys.env"),ADSF=path.join(__dirname,"data","ads.json");
const env=()=>{const o={};try{fs.readFileSync(KEYS,"utf8").split(/\r?\n/).forEach(l=>{const m=l.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);if(m)o[m[1]]=m[2].trim();});}catch(e){}return o;};
const E=env(),N=(a,b)=>parseInt(process.env[a]||E[a]||b,10);
const APP=N("PORT",8787),AGENT=N("AGENT_PORT",8790),AUTH=N("AUTH_PORT",8799),HUB=N("HUB_PORT",8700);

const DOCK=`<style>#hubdock{position:fixed;inset-inline-end:12px;bottom:14px;z-index:2147483000;display:flex;gap:6px;font:13px/1 system-ui,Tahoma}
#hubdock a{background:rgba(17,24,39,.92);color:#e5e7eb;text-decoration:none;padding:9px 13px;border-radius:999px;border:1px solid #374151;backdrop-filter:blur(6px)}
#hubdock a:hover{background:#2563eb}</style>
<div id=hubdock><a href="/agent">🤖</a><a href="/keys">🔑</a><a href="/api/hub/status">📊</a></div>`;
const ads=()=>{try{return JSON.parse(fs.readFileSync(ADSF,"utf8")).filter(x=>x.enabled&&x.snippet)
  .map(x=>"<!-- "+x.id+" -->\n"+x.snippet).join("\n");}catch(e){return "";}};
const EXTRA=()=>DOCK+"\n"+ads();

function route(port,req,res,inject,pathOverride){
  const p=http.request({host:"127.0.0.1",port,path:pathOverride||req.url,method:req.method,
    headers:Object.assign({},req.headers,{host:"127.0.0.1:"+port})},r=>{
    const html=String(r.headers["content-type"]||"").includes("text/html");
    if(!html||!inject){res.writeHead(r.statusCode,r.headers);r.pipe(res);return;}
    let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>{
      const X=EXTRA();
      b=b.includes("</body>")?b.replace("</body>",X+"\n</body>"):b+X;
      const h=Object.assign({},r.headers);delete h["content-length"];
      res.writeHead(r.statusCode,h);res.end(b);});
  });
  p.on("error",()=>{res.writeHead(502,{"content-type":"text/html; charset=utf-8"});
    res.end("<meta charset=utf-8><body style='font:16px system-ui;background:#0b0e14;color:#e8eef7;padding:24px'><h2>المنفذ "+port+" لا يستجيب</h2><p>شغّل: <code>bash money/TOTAL.sh</code></p></body>");});
  req.pipe(p);
}
const ping=p=>new Promise(r=>{const q=http.get({host:"127.0.0.1",port:p,path:"/",timeout:1800},x=>{x.resume();r(x.statusCode);});q.on("error",()=>r(0));q.on("timeout",()=>{q.destroy();r(0);});});

http.createServer((req,res)=>{
  const p=new URL(req.url,"http://x").pathname;
  if(p==="/api/hub/status"){Promise.all([ping(APP),ping(AGENT),ping(AUTH)]).then(([a,b,c])=>{
    res.writeHead(200,{"content-type":"application/json; charset=utf-8","cache-control":"no-store"});
    res.end(JSON.stringify({app:a,agent:b,auth:c,hub:HUB,ads:ads().length>0,ok:!!(a&&b&&c)}));});return;}
  if(p==="/api/hub/ads"&&req.method==="POST"){let b="";req.on("data",c=>b+=c);req.on("end",()=>{
    try{JSON.parse(b);fs.mkdirSync(path.dirname(ADSF),{recursive:true});fs.writeFileSync(ADSF,b);
      res.writeHead(200,{"content-type":"application/json"});res.end('{"ok":true}');}catch(e){res.writeHead(400);res.end('{"ok":false}');}});return;}
  if(p.startsWith("/api/agent"))return route(AGENT,req,res,false);
  if(p==="/api/status"||p==="/api/setkey")return route(AUTH,req,res,false);
  if(p==="/agent")return route(AGENT,req,res,true,"/");
  if(p==="/keys")return route(AUTH,req,res,true,"/");
  route(APP,req,res,true);
}).listen(HUB,()=>console.log("HUB "+HUB+" → app:"+APP+" agent:"+AGENT+" auth:"+AUTH));
