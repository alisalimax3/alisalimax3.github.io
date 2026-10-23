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
