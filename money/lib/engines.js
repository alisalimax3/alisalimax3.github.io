#!/usr/bin/env node
"use strict";
// محرّكات التنفيذ بتراجع تلقائي: chromium → http → api → متصفح الهاتف
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const ROOT=path.resolve(__dirname,"..","..");
const CH=["/data/data/com.termux/files/usr/bin/chromium-browser","/data/data/com.termux/files/usr/bin/chromium","/usr/bin/chromium","/usr/bin/chromium-browser"];
const hasChrom=()=>!!(process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p)));
const hasPup=()=>fs.existsSync(path.join(ROOT,"node_modules","puppeteer-core"));
const hasTermux=()=>new Promise(r=>execFile("which",["termux-open-url"],e=>r(!e)));
const open=u=>new Promise(r=>execFile("termux-open-url",[u],()=>r()));
const get=(u,h)=>new Promise((res,rej)=>{const https=require("https"),http=require("http");
  const m=/^https/.test(u)?https:http;const q=m.get(u,{headers:Object.assign({"user-agent":"Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36"},h||{})},r=>{
    let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>res({status:r.statusCode,body:b,headers:r.headers}));});
  q.on("error",rej);q.setTimeout(15000,()=>q.destroy(new Error("timeout")));});
async function browser(fn){
  if(!hasChrom()||!hasPup())return null;
  const pp=require(path.join(ROOT,"node_modules","puppeteer-core"));
  const br=await pp.launch({executablePath:process.env.CHROME_PATH||CH.find(p=>fs.existsSync(p)),headless:"new",
    args:["--no-sandbox","--disable-dev-shm-usage","--disable-gpu"]});
  try{return await fn(br,pp);}finally{await br.close();}
}
const rank=()=>({chromium:hasChrom()&&hasPup(),http:true,termux:true});
module.exports={hasChrom,hasPup,hasTermux,open,get,browser,rank};
if(require.main===module){const r=rank();console.log("  المحرّكات المتاحة: "+Object.entries(r).filter(([,v])=>v).map(([k])=>k).join(" · "));}
