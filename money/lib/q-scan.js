#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),U=require("./q-util.js");
function inventory(){
  const files=U.walk(U.ROOT,0),by={html:[],js:[],css:[],json:[],img:[],font:[],txt:[],other:[]};
  for(const f of files){const e=path.extname(f).toLowerCase();
    if(/\.html?$/.test(e))by.html.push(f);else if(/\.(js|mjs|cjs)$/.test(e))by.js.push(f);
    else if(e===".css")by.css.push(f);else if(e===".json")by.json.push(f);
    else if(/\.(png|jpe?g|webp|gif|svg|ico|avif)$/.test(e))by.img.push(f);
    else if(/\.(woff2?|ttf|otf)$/.test(e))by.font.push(f);
    else if(/\.(txt|xml|webmanifest|md|rss|atom)$/.test(e))by.txt.push(f);else by.other.push(f);}
  const servers=[];
  for(const f of by.js){const s=U.read(f,500000);
    if(/createServer\s*\(|\.listen\s*\(|express\s*\(|fastify|http2\.createServer/.test(s))servers.push(f);}
  const ports={};
  const env=U.read(path.join(U.ROOT,"keys.env"));
  env.split("\n").forEach(l=>{const m=l.match(/^([A-Z0-9_]*PORT[A-Z0-9_]*)=(\d+)/);if(m)ports[m[1]]=Number(m[2]);});
  const rxR=/(?:app|router|server|srv)\.(get|post|put|delete|patch|all|use)\s*\(\s*["'`]([^"'`]+)["'`]/g;
  const routes=[];
  for(const f of servers){const s=U.read(f,700000);let m;while((m=rxR.exec(s)))routes.push({file:U.rel(f),method:m[1].toUpperCase(),path:m[2]});}
  const envUsed=new Set(),rxE=/(?:process\.env\.|(?:keysfile|akeys|z-keys|K|keys)\.get\(\s*["'])([A-Z][A-Z0-9_]{2,})/g;
  for(const f of by.js.concat(by.html)){const s=U.read(f,400000);let m;while((m=rxE.exec(s)))envUsed.add(m[1]);}
  const inv={at:new Date().toISOString(),root:U.ROOT,total:files.length,
    pages:by.html.map(U.rel),scripts:by.js.map(U.rel),styles:by.css.map(U.rel),configs:by.json.map(U.rel),
    servers:[...new Set(servers.map(U.rel))],ports,routes:[...new Map(routes.map(r=>[r.method+" "+r.path,r])).values()],
    envUsed:[...envUsed].sort(),counts:{html:by.html.length,js:by.js.length,css:by.css.length,json:by.json.length,img:by.img.length,font:by.font.length}};
  return inv;}
if(require.main===module){const inv=inventory();U.jw(path.join(U.A,"inventory.json"),inv);
  console.log("  الملفات: "+inv.total+" · صفحات "+inv.counts.html+" · سكربتات "+inv.counts.js+" · أنماط "+inv.counts.css);
  console.log("  خوادم: "+(inv.servers.join(", ")||"لا شيء")+" · منافذ: "+JSON.stringify(inv.ports));
  console.log("  مسارات: "+inv.routes.length+" · متغيرات مستخدمة: "+inv.envUsed.length);
  U.ev({phase:"scan",ok:true,detail:{files:inv.total,pages:inv.counts.html,servers:inv.servers.length,routes:inv.routes.length}});}
module.exports={inventory};
