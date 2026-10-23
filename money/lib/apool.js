#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process");
function task(t){return new Promise(r=>{const t0=Date.now();
  execFile(t.cmd,t.args||[],{timeout:t.timeout||240000,maxBuffer:8e6,cwd:t.cwd},(e,so,se)=>
    r({name:t.name,ok:!e,ms:Date.now()-t0,out:String(so||"")+String(se||""),code:e?e.code:0}));});}
async function pool(list,limit){const res=new Array(list.length);let i=0;const n=Math.max(1,Math.min(limit||3,list.length||1));
  await Promise.all(Array.from({length:n},async()=>{while(i<list.length){const k=i++;res[k]=await task(list[k]);}}));
  return res;}
module.exports={pool,task};
