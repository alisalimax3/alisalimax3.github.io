#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),K=require("./akeys.js"),codes=require("./acodes.js");
const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER");
const run=a=>{try{return execFileSync("git",a,{cwd:ROOT,stdio:"pipe",timeout:180000}).toString();}catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
if(!tk||!user)console.log("  ○ لا GITHUB_TOKEN/GH_USER — أضف: bash money/APEX.sh set GITHUB_TOKEN=... GH_USER=...");
else{(async()=>{const repo="cinehub-apex";
  if(!fs.existsSync(path.join(ROOT,".git")))run(["init","-q"]);
  const gi=path.join(ROOT,".gitignore");
  if(!fs.existsSync(gi))fs.writeFileSync(gi,"node_modules/\n_backup/\nlogs/*.log\nkeys.env\n__pycache__/\n*.pid\n_deploy/\n");
  run(["config","user.email",K.get("CONTACT_EMAIL")||"apex@local"]);run(["config","user.name",user]);
  run(["add","-A"]);run(["commit","-q","-m","apex "+new Date().toISOString()]);run(["branch","-M","main"]);
  try{run(["remote","remove","origin"]);}catch(e){}
  run(["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo+".git"]);
  const out=run(["push","-u","origin","main","--force"]);
  const ok=/main|up-to-date|->/.test(out);
  console.log(ok?("  ✔ رُفع إلى https://github.com/"+user+"/"+repo):("  ○ "+out.slice(0,100)));
  if(ok)codes.save("رفع GitHub",{repo:user+"/"+repo});})();}
