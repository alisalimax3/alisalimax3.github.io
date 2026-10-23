#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync,execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const run=(c,a)=>{try{return execFileSync(c,a,{stdio:"pipe",timeout:120000}).toString().trim();}catch(e){return "";}};
const sh=c=>run("sh",["-c",c]);
const has=c=>!!sh("command -v "+c);
const isRoot=()=>{try{return process.getuid()===0;}catch(e){return false;}};
function grant(apply){
  const HOME=process.env.HOME||"/data/data/com.termux/files/home";
  const R={at:new Date().toISOString(),root:isRoot(),chroot:has("termux-chroot"),tsu:has("tsu")||has("sudo"),
    storage:false,wakelock:false,boot:false,jobs:false,cron:false,services:false,steps:[]};
  if(!fs.existsSync(path.join(HOME,"storage"))){try{execFile("termux-setup-storage",[],()=>{});R.steps.push("طلب صلاحية التخزين");}catch(e){}}
  R.storage=fs.existsSync(path.join(HOME,"storage"));
  if(has("termux-wake-lock")){sh("termux-wake-lock");R.wakelock=true;R.steps.push("منع نوم الجهاز");}
  if(apply){try{const b=path.join(HOME,".termux","boot");fs.mkdirSync(b,{recursive:true});
    const f=path.join(b,"000-apex.sh");
    fs.writeFileSync(f,"#!/data/data/com.termux/files/usr/bin/sh\ntermux-wake-lock\nsleep 25\ncd "+ROOT+" && bash money/APEX.sh start >> logs/boot.log 2>&1\n");
    fs.chmodSync(f,0o755);R.boot=true;R.steps.push("تمهيد تلقائي عند الإقلاع");}catch(e){}}
  if(apply&&has("termux-job-scheduler")){try{sh("termux-job-scheduler --script "+path.join(H,"JOB-APEX.sh")+" --job-id 3099 --period-ms 900000 --network any --persisted true");R.jobs=true;R.steps.push("مجدول أندرويد");}catch(e){}}
  if(has("crond")){R.cron=true;if(apply&&!run("pgrep",["-x","crond"])){try{execFile("crond",[],()=>{});R.steps.push("cron شغّال");}catch(e){}}}
  if(has("sv"))R.services=true;
  try{execFile("am",["start","-a","android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS"],()=>{});}catch(e){}
  fs.writeFileSync(path.join(D,"privileges.json"),JSON.stringify(R,null,1));
  return R;
}
const level=()=>isRoot()?"root":(has("termux-chroot")?"chroot(شبه-جذر)":(has("tsu")?"tsu":"user"));
module.exports={grant,level,isRoot,has,run,sh};
if(require.main===module){const r=grant(process.argv[2]!=="check");
  console.log("  ✔ مستوى الصلاحيات: "+level()+" · تخزين "+(r.storage?"✔":"○")+" · منع نوم "+(r.wakelock?"✔":"○")+" · إقلاع "+(r.boot?"✔":"○")+" · جدولة "+(r.jobs?"✔":"○")+" · cron "+(r.cron?"✔":"○"));}
