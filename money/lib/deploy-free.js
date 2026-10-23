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
