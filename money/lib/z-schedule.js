#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync,execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),K=require("./z-keys.js");
const LINE="*/20 * * * * cd "+ROOT+" && bash money/ZERO.sh batch 12 >> logs/cron.log 2>&1";
function cron(){try{let cur="";try{cur=execFileSync("crontab",["-l"],{stdio:"pipe"}).toString();}catch(e){}
  if(!cur.includes("ZERO.sh batch")){execFileSync("crontab",["-"],{input:cur+LINE+"\n",stdio:["pipe","pipe","pipe"]});return "✔ cron مثبّت (كل 20 دقيقة)";}
  return "○ cron موجود";}catch(e){return "○ لا crontab — استخدم termux-job-scheduler";}}
function job(){return new Promise(r=>execFile("termux-job-scheduler",["--script",path.join(H,"JOB-ZERO.sh"),"--job-id","3099",
  "--period-ms","1200000","--network","any","--persisted","true"],()=>r(true)));}
async function ping(){const u=K.get("HEALTHCHECK_PING_URL");if(!u)return "○ لا healthcheck";
  return new Promise(r=>execFile("curl",["-sL","-o","/dev/null","--max-time","10",u],()=>r("✔ أُرسل نبض الصحة")));}
(async()=>{const c=cron();const j=await job();const p=await ping();
  console.log("  "+c);console.log("  ✔ جدولة أندرويد "+(j?"مثبّتة":"متعذرة"));console.log("  "+p);})();
