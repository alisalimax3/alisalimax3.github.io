#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..","..");
const run=a=>{try{return execFileSync("git",a,{cwd:ROOT,stdio:"pipe",timeout:120000}).toString();}catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
function go(){const v=path.join(ROOT,"VERSION");let cur="1.0.0";try{cur=fs.readFileSync(v,"utf8").trim();}catch(e){}
  const [a,b]=cur.split(".").map(Number);const nv=a+"."+(b+1)+".0";
  const out=fs.existsSync(path.join(ROOT,".git"))?run(["pull","--rebase","--autostash"]):"";
  fs.writeFileSync(v,nv+"\n");fs.writeFileSync(path.join(ROOT,"logs","update.log"),new Date().toISOString()+" → "+nv+"\n"+out,"a");
  return {from:cur,to:nv,pulled:/up to date|Fast-forward|files changed/.test(out)};}
module.exports={go};
if(require.main===module){const r=go();console.log("  ✔ تحديث ذاتي "+r.from+" → "+r.to+(r.pulled?" (سحب من git)":""));}
