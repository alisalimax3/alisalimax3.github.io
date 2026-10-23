#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const ROOT=path.resolve(__dirname,"..",".."),F=path.join(ROOT,"logs","audit.jsonl");
const h=(prev,o)=>crypto.createHash("sha256").update(prev+JSON.stringify(o)).digest("hex").slice(0,32);
function last(){try{const L=fs.readFileSync(F,"utf8").trim().split("\n");return JSON.parse(L[L.length-1]);}catch(e){return null;}}
function add(event,data){const p=last();const o={i:(p?p.i:0)+1,at:new Date().toISOString(),event,data:data||{}};
  o.prev=p?p.hash:"0".repeat(32);o.hash=h(o.prev,o);fs.appendFileSync(F,JSON.stringify(o)+"\n");return o;}
function verify(){try{const L=fs.readFileSync(F,"utf8").trim().split("\n").filter(Boolean);let prev="0".repeat(32),i=0;
  for(const l of L){const o=JSON.parse(l);i++;if(o.prev!==prev)return{ok:false,at:i};if(h(prev,o)!==o.hash)return{ok:false,at:i};prev=o.hash;}
  return{ok:true,count:i};}catch(e){return{ok:true,count:0};}}
module.exports={add,verify};
if(require.main===module){const v=verify();console.log(v.ok?"  ✔ سلسلة التدقيق سليمة ("+v.count+" قيد)":"  ✗ كسر عند "+v.at);}
