#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js"),QDB=require("./q-db.js");
const APPLY=process.env.APPLY==="1";
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
const items=[];
function rec(rule,file,ok,evidence){items.push({rule,file,ok,evidence:evidence||"",at:new Date().toISOString()});
  QDB.insert("fixes",{rule,file,ok:ok?1:0,evidence:evidence||""});U.ev({phase:"fix",ok,detail:{rule,file,evidence}});}
function patch(file,fn,rule,verify){const p=path.join(U.ROOT,file);const before=U.read(p,2e6);
  const after=fn(before);if(after===before)return false;
  if(!APPLY)return true;
  U.backup(p);U.atomic(p,after);
  if(/\.js$/.test(file)){try{execFileSync(process.execPath,["--check",p],{stdio:"pipe"});}
    catch(e){U.restore(p);rec(rule,file,false,"فشل node --check — استُرجع");return false;}}
  const okv=verify?verify(U.read(p,2e6)):true;
  if(!okv){U.restore(p);rec(rule,file,false,"فشل التحقق — استُرجع");return false;}
  rec(rule,file,true,"طُبّق وتحقّق ("+U.sha(after)+")");return true;}
function create(file,content,rule){const p=path.join(U.ROOT,file);
  if(fs.existsSync(p))return false;if(!APPLY)return true;
  U.atomic(p,content);rec(rule,file,true,"أُنشئ ("+content.length+" بايت)");return true;}
(async()=>{const inv=INV();
  const brand=(()=>{try{const j=U.jr(path.join(U.ROOT,"money/data/identity.json"),{});return j.brand||"CineHub";}catch(e){return"CineHub";}})();
  const desc="منصة أفلام ومسلسلات وأنمي مترجمة بجودة عالية";
  // HTML
  for(const f of inv.pages){
    if(!/<meta\s+charset/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><meta charset="utf-8">'),"html-charset",x=>/<meta\s+charset/i.test(x));
    if(!/name=["']viewport/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><meta name="viewport" content="width=device-width,initial-scale=1">'),"html-viewport",x=>/name=["']viewport/i.test(x));
    if(!/name=["']description/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><meta name="description" content="'+desc+'">'),"html-desc",x=>/name=["']description/i.test(x));
    if(!/<html[^>]*lang=/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<html/i,'<html lang="ar" dir="rtl"'),"html-lang",x=>/<html[^>]*lang=/i.test(x));
    if(!/rel=["']icon/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<head([^>]*)>/i,'<head$1><link rel="icon" href="/assets/logo.png">'),"html-favicon",x=>/rel=["']icon/i.test(x));
    if(/<button(?![^>]*\btype=)/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/<button(?![^>]*\btype=)/gi,'<button type="button"'),"button-type",x=>!/<button(?![^>]*\btype=)/i.test(x));
    if(/target=["']_blank["'](?![^>]*\brel=)/i.test(U.read(path.join(U.ROOT,f),600000)))patch(f,s=>s.replace(/(target=["']_blank["'])(?![^>]*rel=)/gi,'$1 rel="noopener"'),"blank-rel",x=>!/target=["']_blank["'](?![^>]*rel=)/i.test(x));}
  // ملفات ناقصة
  const base=(()=>{try{const k=U.read(path.join(U.ROOT,"keys.env")).match(/^PUBLIC_URL=(.*)$/m);return k?k[1].replace(/\/$/,""):"";}catch(e){return"";}})();
  create("robots.txt","User-agent: *\nAllow: /\n"+(base?"Sitemap: "+base+"/sitemap.xml\n":""),"missing-file");
  if(inv.pages.length){const urls=inv.pages.slice(0,300).map(f=>(base||"")+"/"+f);
    create("sitemap.xml",'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+urls.map(u=>"<url><loc>"+u+"</loc><changefreq>daily</changefreq></url>").join("\n")+"\n</urlset>\n","missing-file");}
  create("manifest.webmanifest",JSON.stringify({name:brand,short_name:brand,start_url:"/",display:"standalone",background_color:"#0b0e14",theme_color:"#2563eb",icons:[{src:"/assets/logo.png",sizes:"512x512",type:"image/png"}]},null,1),"missing-file");
  create("security.txt","Contact: "+(U.read(path.join(U.ROOT,"keys.env")).match(/^CONTACT_EMAIL=(.*)$/m)||[,""])[1]+"\nExpires: "+new Date(Date.now()+31536e6).toISOString()+"\n","missing-file");
  create("ads.txt","# سطور شبكاتك تُضاف آليًا عبر: bash money/AUDIT.sh wire --apply\n","missing-file");
  create("404.html",'<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>404 — '+brand+'</title><style>body{margin:0;font-family:system-ui;background:#0b0e14;color:#e8eef7;display:grid;place-items:center;height:100vh;text-align:center}a{color:#7dd3fc}</style></head><body><div><h1 style="font-size:4rem;margin:0">404</h1><p>الصفحة غير موجودة</p><p><a href="/">→ الرئيسية</a></p></div></body></html>',"missing-file");
  // صلاحيات
  for(const f of ["keys.env","logs/codes.log","logs/vault.json","money/data/vault.enc","money/data/secrets.json","money/db/creds.json"]){
    const p=path.join(U.ROOT,f);if(!fs.existsSync(p))continue;
    const m=fs.statSync(p).mode&0o777;if(m===0o600)continue;
    if(APPLY){fs.chmodSync(p,0o600);rec("perm",f,true,"600 ("+m.toString(8)+" → 600)");}else rec("perm",f,true,"سيُضبط 600");}
  // gitignore
  const gi=path.join(U.ROOT,".gitignore");const need=["node_modules","keys.env","logs","*.pid","_backup","_deploy",".cache","__pycache__"];
  const cur=fs.existsSync(gi)?U.read(gi):"";const miss=need.filter(x=>!cur.includes(x));
  if(miss.length){if(APPLY){U.backup(gi);U.atomic(gi,(cur.trimEnd()+"\n"+miss.join("\n")+"\n").replace(/^\n/,""));rec("gitignore",".gitignore",true,"أُضيف: "+miss.join(", "));}
    else rec("gitignore",".gitignore",true,"سيُضاف: "+miss.join(", "));}
  // keys.env تنظيف
  const envp=path.join(U.ROOT,"keys.env");
  if(fs.existsSync(envp)){const raw=U.read(envp);const map={};raw.split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0)map[l.slice(0,i).trim()]=l.slice(i+1).trim();});
    const clean=Object.keys(map).sort().map(k=>k+"="+map[k]).join("\n")+"\n";
    if(clean!==raw){if(APPLY){U.backup(envp);U.atomic(envp,clean);try{fs.chmodSync(envp,0o600);}catch(e){}rec("env-normalize","keys.env",true,Object.keys(map).length+" مفتاح مرتب");}
      else rec("env-normalize","keys.env",true,"سيُنظّف ("+Object.keys(map).length+" مفتاح)");}}
  U.jw(path.join(U.A,"fixes.json"),{at:new Date().toISOString(),apply:APPLY,count:items.length,items});
  console.log("  ✔ إصلاحات "+(APPLY?"مُطبَّقة ومُتحقَّقة":"مُرشَّحة")+": "+items.length);
  const byr={};items.forEach(x=>byr[x.rule]=(byr[x.rule]||0)+1);
  Object.entries(byr).forEach(([k,v])=>console.log("   · "+k+": "+v));
  if(items.some(x=>!x.ok))console.log("   ✗ فشل: "+items.filter(x=>!x.ok).length+" (استُرجعت آليًا)");
  U.ev({phase:"fix-all",ok:items.every(x=>x.ok),detail:{count:items.length}});})();
