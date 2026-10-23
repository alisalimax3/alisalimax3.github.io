#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,"..",".."),F=path.join(ROOT,"keys.env");
function all(){const o={};try{fs.readFileSync(F,"utf8").split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0&&!/^\s*#/.test(l))o[l.slice(0,i).trim()]=l.slice(i+1).trim();});}catch(e){}return o;}
const get=k=>all()[k]||"";
function set(o){const c=all();Object.assign(c,o);const t=Object.keys(c).sort().map(k=>k+"="+c[k]).join("\n")+"\n";
  const tmp=F+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,F);try{fs.chmodSync(F,0o600);}catch(e){}}
function normalize(){const c=all();set(c);return Object.keys(c).length;}
module.exports={get,set,all,normalize};
if(require.main===module){const c=process.argv[2];if(c==="normalize")console.log("  ✔ keys.env مصحّح ("+normalize()+" مفتاح)");else if(c==="list")Object.keys(all()).forEach(k=>console.log("  "+k));}
