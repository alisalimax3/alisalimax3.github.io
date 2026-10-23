#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const D=path.resolve(__dirname,"..","data"),P=path.join(D,"revenue-proof.json");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const led=rd(path.join(D,"ledger.json"),{total:0});
const prev=rd(P,{samples:[]});
const now=Number(led.total||0);
prev.samples.push({at:new Date().toISOString(),total:now});
if(prev.samples.length>20)prev.samples=prev.samples.slice(-20);
const a=prev.samples[0],b=prev.samples[prev.samples.length-1];
prev.total=now;
prev.rising=prev.samples.length>=2 && (b.total-a.total)>0;
prev.delta=prev.samples.length>=2?(b.total-a.total):0;
prev.confirmed=prev.rising && now>0;
fs.writeFileSync(P,JSON.stringify(prev,null,1));
console.log("  "+(prev.confirmed?"✔":"○")+" الأرباح: $"+now.toFixed(2)+"  (تغيّر: $"+prev.delta.toFixed(2)+" على "+prev.samples.length+" عيّنة)");
process.exit(prev.confirmed?0:1);
