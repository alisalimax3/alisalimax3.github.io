#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const led=rd(path.join(D,"ledger.json"),{total:0,rows:[]});
const st={at:new Date().toISOString(),total:Number(led.total||0),rows:(led.rows||[]).length,live:0};
try{const ks=rd(path.join(D,"keys-status.json"),{summary:{}});st.live=(ks.summary&&ks.summary.live)||0;}catch(e){}
try{const p=rd(path.join(D,"revenue-proof.json"),{});st.rising=!!p.rising;}catch(e){}
fs.writeFileSync(path.join(D,"harvest.json"),JSON.stringify(st,null,1));
console.log("  ✔ حصد: $"+st.total.toFixed(2)+" · قيود "+st.rows+" · مصادر حيّة "+st.live);
