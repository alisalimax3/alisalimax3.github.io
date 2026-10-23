#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{spawn}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data"),F=path.join(D,"watch.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){return{};}};
const wr=o=>fs.writeFileSync(F,JSON.stringify(o,null,1));
const alive=p=>{try{process.kill(p,0);return true;}catch(e){return false;}};
function ensure(svc){const st=rd(),s=st[svc.name]||{restarts:0,last:0,breaks:0,down:0};
  if(s.pid&&alive(s.pid)){s.ok=true;st[svc.name]=s;wr(st);return{name:svc.name,action:"حيّ"};}
  const now=Date.now();
  if(now-(s.last||0)<12000){st[svc.name]=s;wr(st);return{name:svc.name,action:"انتظار"};}
  if(s.restarts>6&&now-(s.breaks||0)>600000){s.restarts=0;s.breaks=now;}
  s.last=now;s.restarts++;s.down++;
  try{const out=fs.openSync(svc.log||path.join(ROOT,"logs",svc.name+".log"),"a");
    const p=spawn(svc.cmd,svc.args||[],{cwd:svc.cwd||ROOT,detached:true,stdio:["ignore",out,out]});p.unref();s.pid=p.pid;
  }catch(e){}
  st[svc.name]=s;wr(st);return{name:svc.name,action:"أُحيي",pid:s.pid,restarts:s.restarts};}
module.exports={ensure,alive,rd};
if(require.main===module){const s=rd();Object.entries(s).forEach(([k,v])=>console.log("  "+(v.pid&&alive(v.pid)?"✔":"○")+" "+k+"  إحياءات:"+v.restarts));}
