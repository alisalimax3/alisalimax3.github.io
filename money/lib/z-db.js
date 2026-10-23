#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"db");
const F={targets:path.join(D,"targets.json"),journal:path.join(D,"journal.jsonl"),evidence:path.join(D,"evidence.jsonl"),
  tests:path.join(D,"tests.json"),human:path.join(D,"human.json"),locks:path.join(D,"locks.json"),
  links:path.join(D,"links.json"),ads:path.join(D,"ads.json"),progress:path.join(D,"progress.json")};
const STAGES=["new","resolved","reachable","account","email","key","linked","live","human","failed","locked"];
function ensure(){fs.mkdirSync(D,{recursive:true});Object.values(F).forEach(f=>{if(!fs.existsSync(f))fs.writeFileSync(f,f.endsWith(".jsonl")?"":"{}");});}
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
function wr(f,o){const t=f+"."+process.pid+".tmp";fs.writeFileSync(t,JSON.stringify(o,null,1));fs.renameSync(t,f);}
function jrn(e,d){ensure();fs.appendFileSync(F.journal,JSON.stringify({at:new Date().toISOString(),event:e,data:d||{}})+"\n");}
const targets=()=>{ensure();return rd(F.targets,{});};
const target=id=>targets()[id]||null;
function upsert(id,o){const t=targets();t[id]=Object.assign(t[id]||{id,stage:"new",attempts:0,evidence:0,created:new Date().toISOString()},o);
  t[id].updated=new Date().toISOString();wr(F.targets,t);return t[id];}
function stage(id,s,note){const t=targets();if(!t[id])return null;const prev=t[id].stage;
  t[id].stage=s;t[id].updated=new Date().toISOString();if(note)t[id].note=note;
  t[id].history=(t[id].history||[]).concat([{from:prev,to:s,at:new Date().toISOString()}]);
  wr(F.targets,t);jrn("stage",{id,from:prev,to:s,note:note||""});return t[id];}
function ev(id,kind,data){ensure();fs.appendFileSync(F.evidence,JSON.stringify({at:new Date().toISOString(),id,kind,data:data||{}})+"\n");
  const t=targets();if(t[id]){t[id].evidence=(t[id].evidence||0)+1;t[id].lastEvidence=new Date().toISOString();wr(F.targets,t);}}
function test(id,res){const T=rd(F.tests,{});T[id]=Object.assign({at:new Date().toISOString()},res);wr(F.tests,T);jrn("test",{id,ok:res.ok});return T[id];}
const human=()=>{ensure();return rd(F.human,{});};
function humanAdd(it){const h=human();h[it.id]=Object.assign(h[it.id]||{id:it.id,at:new Date().toISOString()},it);wr(F.human,h);jrn("human",{id:it.id,why:it.why});return h[it.id];}
function humanResolve(id,val){const h=human();if(h[id]){h[id].resolved=val||true;h[id].resolvedAt=new Date().toISOString();wr(F.human,h);jrn("human-resolved",{id});}return h[id];}
function next(n,filter){const t=targets(),now=Date.now();
  return Object.values(t).filter(x=>!x.locked&&x.stage!=="locked"&&(!x.nextAt||x.nextAt<=now)&&(!filter||filter(x)))
    .sort((a,b)=>(a.attempts||0)-(b.attempts||0)||String(a.updated).localeCompare(String(b.updated))).slice(0,n||10);}
function fail(id,note){const t=targets();if(!t[id])return;t[id].attempts=(t[id].attempts||0)+1;
  t[id].nextAt=Date.now()+Math.min(6*3600e3,Math.pow(2,t[id].attempts)*45000);t[id].lastError=note;wr(F.targets,t);}
function stats(){const t=Object.values(targets()),by={};t.forEach(x=>by[x.stage]=(by[x.stage]||0)+1);
  const T=rd(F.tests,{});const pass=Object.values(T).filter(x=>x.ok).length;
  return{total:t.length,by,tests:Object.keys(T).length,passed:pass,humanPending:Object.values(human()).filter(x=>!x.resolved).length,
    evidence:fs.existsSync(F.evidence)?fs.readFileSync(F.evidence,"utf8").split("\n").filter(Boolean).length:0};}
function backup(){const f=path.join(D,"backup-"+Date.now()+".json");wr(f,{targets:targets(),tests:rd(F.tests,{}),human:human()});return f;}
function lock(id){const t=targets();if(t[id]){t[id].locked=true;t[id].stage="locked";wr(F.targets,t);}}
function unlock(id){const t=targets();if(t[id]){t[id].locked=false;if(t[id].stage==="locked")t[id].stage="reachable";wr(F.targets,t);}}
const rollback=(id,s)=>stage(id,s,"rollback يدوي");
module.exports={ensure,targets,target,upsert,stage,ev,test,human,humanAdd,humanResolve,next,fail,stats,backup,lock,unlock,rollback,jrn,rd,wr,D,F,STAGES};
if(require.main===module){const c=process.argv[2]||"stats";
  if(c==="stats")console.log(JSON.stringify(stats(),null,1));
  else if(c==="backup")console.log("  ✔ "+backup());
  else if(c==="human")Object.values(human()).filter(x=>!x.resolved).forEach(x=>console.log("  ○ "+x.id+" — "+x.why));}
