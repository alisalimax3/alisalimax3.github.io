#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
let fixed=0;const issues=[],pages=[];
(function walk(d,depth){if(depth>4)return;for(const e of fs.readdirSync(d,{withFileTypes:true})){
  if(["_backup","node_modules",".git","logs","_deploy"].includes(e.name))continue;
  const p=path.join(d,e.name);if(e.isDirectory())walk(p,depth+1);else if(/\.html?$/i.test(e.name))pages.push(p);}})(ROOT,0);
let base={brand:"CineHub",desc_short_ar:"منصة أفلام ومسلسلات"};
try{base=Object.assign(base,JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8")));}catch(e){}
const url=(()=>{try{return require("./akeys.js").get("PUBLIC_URL")||"http://127.0.0.1:8787/";}catch(e){return"http://127.0.0.1:8787/";}})();
for(const p of pages){let s=fs.readFileSync(p,"utf8");const o=s;
  if(!/<meta\s+charset/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta charset="utf-8">');issues.push("charset");}
  if(!/name=["']viewport/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="viewport" content="width=device-width,initial-scale=1">');issues.push("viewport");}
  if(!/name=["']description/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta name="description" content="'+(base.desc_short_ar||"").replace(/"/g,"")+'">');issues.push("description");}
  if(!/property=["']og:title/i.test(s)){s=s.replace(/<head([^>]*)>/i,'<head$1><meta property="og:title" content="'+base.brand+'"><meta property="og:image" content="/assets/logo.png"><meta name="theme-color" content="#2563eb">');issues.push("og");}
  if(!/<html[^>]*lang=/i.test(s))s=s.replace(/<html/i,'<html lang="ar" dir="rtl"');
  if(s!==o){fs.writeFileSync(p,s);fixed++;}}
const need={"manifest.webmanifest":JSON.stringify({name:base.brand,short_name:base.brand,start_url:"/",display:"standalone",background_color:"#0b0e14",theme_color:"#2563eb"},null,1)};
for(const[f,c]of Object.entries(need)){const p=path.join(ROOT,f);if(!fs.existsSync(p)){fs.writeFileSync(p,c);fixed++;issues.push("أنشأ "+f);}}
for(const f of fs.readdirSync(path.join(HERE,"lib")).filter(x=>x.endsWith(".js"))){
  try{execFileSync("node",["--check",path.join(HERE,"lib",f)],{stdio:"pipe"});}catch(e){issues.push("صياغة "+f);}}
const rep={at:new Date().toISOString(),pages:pages.length,fixed,issues:[...new Set(issues)].slice(0,40)};
fs.writeFileSync(path.join(D,"doctor.json"),JSON.stringify(rep,null,1));
console.log("  ✔ فحص "+pages.length+" صفحة · أصلحت/أنشأت "+fixed+" عنصرًا · ملاحظات "+rep.issues.length);
