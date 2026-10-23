#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),K=require("./keysfile.js"),codes=require("./codes.js");
const tk=K.get("GITHUB_TOKEN"),user=K.get("GH_USER");
if(!tk||!user)return console.log("  ○ لا GITHUB_TOKEN أو GH_USER — bash money/AGENT-RUN.sh set GITHUB_TOKEN=... GH_USER=...");
const repo=K.get("GITHUB_REPO")||(user+".cinehub");
const run=a=>{try{return execFileSync("git",a,{cwd:ROOT,stdio:"pipe"}).toString();}catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
const api=(m,p,b)=>new Promise(r=>{const https=require("https");
  const q=https.request({host:"api.github.com",path:p,method:m,headers:{"user-agent":"cinehub","authorization":"Bearer "+tk,accept:"application/vnd.github+json","content-type":"application/json"}},x=>{
    let d="";x.on("data",c=>d+=c);x.on("end",()=>r({status:x.statusCode,body:d}));});q.on("error",()=>r({status:0}));q.end(b?JSON.stringify(b):undefined);});
(async()=>{
  await api("POST","/user/repos",{name:repo.replace(/^.*\./,""),private:true,description:"CineHub — منصة أفلام + وكيل أرباح",auto_init:false});
  if(!fs.existsSync(path.join(ROOT,".git")))run(["init","-q"]);
  run(["config","user.email",K.get("CONTACT_EMAIL")||"cinehub@local"]);
  run(["config","user.name",user]);
  const gi=path.join(ROOT,".gitignore");
  if(!fs.existsSync(gi))fs.writeFileSync(gi,"node_modules/\n_backup/\nlogs/*.log\nkeys.env\n__pycache__/\n*.pid\n");
  const rd=path.join(ROOT,"README.md");
  if(!fs.existsSync(rd))fs.writeFileSync(rd,"# CineHub\n\nمنصة أفلام ومسلسلات + وكيل أرباح ذاتي.\n\n"+
    "## التشغيل\n```bash\nbash money/OMEGA.sh\n```\n\n## الأوامر\n`start|stop|status|ready|doctor|sync|proof|plan`\n");
  run(["add","-A"]);
  run(["commit","-q","-m","OMEGA: "+new Date().toISOString()]);
  run(["branch","-M","main"]);
  run(["remote","remove","origin"]);run(["remote","add","origin","https://"+tk+"@github.com/"+user+"/"+repo.replace(/^.*\./,"")+".git"]);
  const out=run(["push","-u","origin","main","--force"]);
  const ok=/main|up-to-date|->/.test(out);
  console.log(ok?"  ✔ رُفع إلى https://github.com/"+user+"/"+repo.replace(/^.*\./,""):"  ○ "+out.slice(0,120));
  codes.save("رفع GitHub",{repo:user+"/"+repo.replace(/^.*\./,""),الحالة:ok?"مرفوع":"فشل",الوقت:new Date().toISOString()});
})();
