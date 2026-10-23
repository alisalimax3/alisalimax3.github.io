#!/usr/bin/env node
"use strict";
// مصدر واحد لكل قوائم المنصات — إزالة تكرار بـ id
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,"..");
const FILES=String(process.env.SOURCES_FILES||
 "sources.json,sources-big.json,sources-west.json,sources-mega.json,sources-mega2.json,sources-mega3.json,sources-mega4.json")
 .split(",").map(s=>s.trim()).filter(Boolean);
module.exports=function load(){
  const seen=new Set(),out=[],bad=[];
  for(const f of FILES){
    let d; try{d=JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8"));}catch(e){bad.push(f);continue;}
    if(!Array.isArray(d)){bad.push(f);continue;}
    for(const x of d){ if(!x||!x.id||seen.has(x.id))continue; seen.add(x.id); out.push(x); }
  }
  return {list:out,badFiles:bad};
};
module.exports.FILES=FILES;
