#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),crypto=require("crypto");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),OUT=path.join(ROOT,"_deploy"),D=path.join(H,"data");
const K=require("./akeys.js"),codes=require("./acodes.js");
const sh=(c,a,o)=>execFileSync(c,a,Object.assign({cwd:OUT,stdio:"pipe",timeout:420000},o||{})).toString();
function build(){
  fs.rmSync(OUT,{recursive:true,force:true});fs.mkdirSync(OUT,{recursive:true});
  const skip=new Set(["_backup","node_modules",".git","logs","_deploy","__pycache__","storage",".cache"]);
  (function cp(src,dst){for(const e of fs.readdirSync(src,{withFileTypes:true})){
    if(skip.has(e.name)||e.name==="keys.env"||e.name.endsWith(".pid"))continue;
    const s=path.join(src,e.name),d=path.join(dst,e.name);
    if(e.isDirectory()){fs.mkdirSync(d,{recursive:true});cp(s,d);}
    else if(/\.(html?|css|js|json|png|jpe?g|webp|svg|ico|woff2?|ttf|txt|xml|webmanifest|md)$/i.test(e.name))fs.copyFileSync(s,d);}})(ROOT,OUT);
  const key=K.get("INDEXNOW_KEY")||crypto.randomBytes(16).toString("hex");K.set({INDEXNOW_KEY:key});
  fs.writeFileSync(path.join(OUT,key+".txt"),key);
  const f=[];(function wk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);e.isDirectory()?wk(p):f.push(path.relative(OUT,p));}})(OUT);
  return{key,files:f};
}
const tries=[
 {n:"surge",need:["SURGE_TOKEN"],fn:()=>{const dom=K.get("SURGE_DOMAIN")||("cinehub-"+crypto.randomBytes(3).toString("hex")+".surge.sh");
   sh("npx",["--yes","surge",".",dom,"--token",K.get("SURGE_TOKEN")]);K.set({SURGE_DOMAIN:dom});return "https://"+dom;}},
 {n:"netlify",need:["NETLIFY_TOKEN"],fn:()=>{const o=sh("npx",["--yes","netlify-cli","deploy","--prod","--dir","."],{env:Object.assign({},process.env,{NETLIFY_AUTH_TOKEN:K.get("NETLIFY_TOKEN")})});
   const m=o.match(/https:\/\/[a-z0-9\-]+\.netlify\.app/);return m?m[0]:null;}},
 {n:"vercel",need:["VERCEL_TOKEN"],fn:()=>{const o=sh("npx",["--yes","vercel","--prod","--yes","--token",K.get("VERCEL_TOKEN")]);
   const m=o.match(/https:\/\/[a-z0-9\-]+\.vercel\.app/);return m?m[0]:null;}},
 {n:"cloudflare",need:["CF_TOKEN","CF_PROJECT"],fn:()=>{const o=sh("npx",["--yes","wrangler","pages","deploy",".","--project-name",K.get("CF_PROJECT")],
   {env:Object.assign({},process.env,{CLOUDFLARE_API_TOKEN:K.get("CF_TOKEN")})});
   const m=o.match(/https:\/\/[a-z0-9\-\.]+\.pages\.dev/);return m?m[0]:null;}},
 {n:"firebase",need:["FIREBASE_TOKEN"],fn:()=>{const o=sh("npx",["--yes","firebase-tools","deploy","--only","hosting","--token",K.get("FIREBASE_TOKEN")]);
   const m=o.match(/https:\/\/[a-z0-9\-]+\.web\.app/);return m?m[0]:null;}},
 {n:"neocities",need:["NEOCITIES_USER","NEOCITIES_PASS"],fn:()=>{const u=K.get("NEOCITIES_USER");
   const args=["-s","-u",u+":"+K.get("NEOCITIES_PASS")];const files=[];
   (function wk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name);
     if(e.isDirectory()){args.push("-F",path.relative(OUT,p)+"=@"+p);}else files.push(p);}})(OUT);
   for(const f of files)args.push("-F",path.relative(OUT,f)+"=@"+f);
   args.push("https://neocities.org/api/upload");
   const o=sh("curl",args);return /"result":"success"/.test(o)?("https://"+u+".neocities.org"):null;}},
 {n:"github",need:["GITHUB_TOKEN","GH_USER"],fn:()=>{const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER"),repo="cinehub-apex";
   const g=path.join(OUT,".git");if(!fs.existsSync(g))sh("git",["init","-q"]);
   sh("git",["config","user.email",K.get("CONTACT_EMAIL")||"apex@local"]);sh("git",["config","user.name",user]);
   sh("git",["add","-A"]);sh("git",["commit","-q","-m","apex "+new Date().toISOString()]);sh("git",["branch","-M","gh-pages"]);
   try{sh("git",["remote","remove","origin"]);}catch(e){}
   sh("git",["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo+".git"]);
   try{sh("git",["push","-u","origin","gh-pages","--force"]);}catch(e){}
   return "https://"+user+".github.io/"+repo+"/";}}
];
(async()=>{const{key,files}=build();console.log("  ✔ حزمة النشر: "+files.length+" ملف");
  const done=[];
  for(const t of tries){if(!t.need.every(k=>K.get(k)))continue;
    try{const u=t.fn();if(u&&/^https/.test(u)){done.push({host:t.n,url:u});console.log("  ✔ "+t.n+" → "+u);}}catch(e){console.log("  ○ "+t.n+" فشل");}}
  if(!done.length){console.log("  ○ لا استضافة — أضف توكنًا: SURGE_TOKEN أو NETLIFY_TOKEN أو VERCEL_TOKEN أو GITHUB_TOKEN+GH_USER");}
  const rec={at:new Date().toISOString(),ok:done.length>0,hosts:done,url:done[0]?done[0].url:"",files:files.length,key};
  fs.writeFileSync(path.join(D,"deploy.json"),JSON.stringify(rec,null,1));
  if(done.length){K.set({PUBLIC_URL:done[0].url,INDEXNOW_HOST:new URL(done[0].url).host,MIRRORS:done.map(d=>d.url).join(",")});codes.save("نشر متعدد",{عدد:done.length,الرابط:done[0].url});}
  require("./aaudit.js").add("deploy",{hosts:done.length});})();
