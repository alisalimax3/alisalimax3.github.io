#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const codes=require("./codes.js");
const K=require("./keysfile.js");
let fixed=0,issues=[];
const pages=[];
(function walk(d,depth){if(depth>4)return;
  for(const e of fs.readdirSync(d,{withFileTypes:true})){
    if(["_backup","node_modules",".git","logs"].includes(e.name))continue;
    const p=path.join(d,e.name);
    if(e.isDirectory())walk(p,depth+1);else if(/\.html?$/i.test(e.name))pages.push(p);}})(ROOT,0);
const base=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8"));}catch(e){return{brand:"CineHub",handle:"cinehub",desc_short_ar:"",keywords_ar:[],colors:{primary:"#2563eb"}};}})();
const url=K.get("PUBLIC_URL")||("http://127.0.0.1:"+(K.get("PORT")||"8787")+"/");
// 1) إصلاح كل صفحة
for(const p of pages){
  let s=fs.readFileSync(p,"utf8"),o=s;
  if(!/<meta\s+charset/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta charset="utf-8">');issues.push("charset");}
  if(!/name=["']viewport/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="viewport" content="width=device-width,initial-scale=1">');issues.push("viewport");}
  if(!/name=["']description/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="description" content="'+base.desc_short_ar.replace(/"/g,"")+'">');issues.push("description");}
  if(!/property=["']og:title/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta property="og:title" content="'+base.brand+'">'
    +'<meta property="og:description" content="'+base.desc_short_ar.replace(/"/g,"")+'">'
    +'<meta property="og:image" content="/assets/logo.png"><meta name="theme-color" content="'+base.colors.primary+'">');issues.push("og");}
  if(!/rel=["']icon/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><link rel="icon" href="/assets/logo.png"><link rel="manifest" href="/manifest.webmanifest">');issues.push("icon");}
  if(!/<html[^>]*lang=/i.test(s))s=s.replace(/<html/i,'<html lang="ar" dir="rtl"');
  if(s!==o){fs.writeFileSync(p,s);fixed++;}
}
// 2) الملفات الناقصة
const need={
 "robots.txt":"User-agent: *\nAllow: /\nSitemap: "+url.replace(/\/$/,"")+"/sitemap.xml\n",
 "sitemap.xml":'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
   pages.slice(0,200).map(p=>"<url><loc>"+url.replace(/\/$/,"")+"/"+path.relative(ROOT,p).replace(/\\/g,"/")+"</loc></url>").join("\n")+"\n</urlset>\n",
 "manifest.webmanifest":JSON.stringify({name:base.brand,short_name:base.brand,start_url:"/",display:"standalone",
   background_color:"#0b0e14",theme_color:base.colors.primary,icons:[{src:"/assets/logo.png",sizes:"512x512",type:"image/png"}]},null,1),
 "ads.txt":"# أضف سطور شبكاتك بعد القبول\n"}
for(const[f,c]of Object.entries(need)){
  const p=path.join(ROOT,f);
  if(!fs.existsSync(p)){fs.writeFileSync(p,c);fixed++;issues.push("أنشأ "+f);}
}
// 3) فحص صياغة JS
for(const f of fs.readdirSync(HERE).filter(x=>x.endsWith(".js"))){
  try{require("child_process").execFileSync("node",["--check",path.join(HERE,f)],{stdio:"pipe"});}
  catch(e){issues.push("خطأ صياغة "+f);}
}
// 4) الروابط الداخلية المكسورة
for(const p of pages){
  const s=fs.readFileSync(p,"utf8");
  for(const m of s.matchAll(/(?:href|src)=["'](?!https?:|\/\/|#|mailto:|data:)([^"']+)["']/g)){
    const t=m[1].split("?")[0];if(!t||t==="/")continue;
    const abs=t.startsWith("/")?path.join(ROOT,t):path.join(path.dirname(p),t);
    if(!fs.existsSync(abs)&&!/\.(php|json)$/.test(abs))issues.push("رابط مكسور "+t);
  }
}
const rep={at:new Date().toISOString(),pages:pages.length,fixed,issues:[...new Set(issues)].slice(0,40)};
fs.writeFileSync(path.join(D,"doctor.json"),JSON.stringify(rep,null,1));
codes.save("طبيب التطبيق",{صفحات:pages.length,إصلاحات:fixed,مشاكل:rep.issues.length});
console.log("  ✔ فحص "+pages.length+" صفحة · أصلحت/أنشأت "+fixed+" عنصرًا · ملاحظات "+rep.issues.length);
