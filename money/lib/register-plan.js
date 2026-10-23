#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const S=JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8"));
const KP=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"keypages.json"),"utf8"));}catch(e){return{};}})();
const PRI={adult:0,ads:1,pay:2,channel:3,dev:4,infra:5,crypto:6,ai:7,data:8,media:9,fx:10,movie:11,series:12,seo:13};
const plan=S.filter(x=>x.url&&x.url!=="-"&&x.env&&x.env.length)
 .map(x=>({id:x.id,name:x.name,cat:x.cat,url:x.url,env:x.env,
   tier:KP[x.id]?"A":(/signup|register|join/i.test(x.url)?"A":"B"),
   pri:PRI[x.cat]!=null?PRI[x.cat]:99}))
 .sort((a,b)=>a.pri-b.pri||a.tier.localeCompare(b.tier));
fs.writeFileSync(path.join(D,"register-plan.json"),JSON.stringify({at:new Date().toISOString(),total:plan.length,plan},null,1));
const byT={};plan.forEach(p=>byT[p.tier]=(byT[p.tier]||0)+1);
console.log("  ✔ خطة تسجيل: "+plan.length+" منصة (A="+(byT.A||0)+" فورية · B="+(byT.B||0)+" بالتحقق)");
