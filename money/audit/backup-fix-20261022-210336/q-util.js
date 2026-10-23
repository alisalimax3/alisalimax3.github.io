#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),A=path.join(H,"audit");
const SKIP=new Set(["node_modules",".git","logs","_backup","_deploy","audit",".cache","storage","__pycache__",".idea"]);
fs.mkdirSync(A,{recursive:true});
const rel=p=>path.relative(ROOT,p).replace(/\\/g,"/");
function walk(dir,depth,out){out=out||[];depth=depth==null?0:depth;if(depth>6)return out;
  let es=[];try{es=fs.readdirSync(dir,{withFileTypes:true});}catch(e){return out;}
  for(const e of es){if(SKIP.has(e.name))continue;const p=path.join(dir,e.name);
    if(e.isDirectory())walk(p,depth+1,out);else out.push(p);}return out;}
const sha=s=>crypto.createHash("sha256").update(String(s)).digest("hex").slice(0,16);
const size=f=>{try{return fs.statSync(f).size;}catch(e){return 0;}};
const exists=f=>{try{return fs.existsSync(f);}catch(e){return false;}};
function read(f,max){try{const b=fs.readFileSync(f);return (max&&b.length>max?b.slice(0,max):b).toString("utf8");}catch(e){return "";}}
function atomic(f,t){const tmp=f+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,f);}
function backup(f){const d=path.join(A,"backup",rel(f));fs.mkdirSync(path.dirname(d),{recursive:true});
  if(fs.existsSync(f))fs.copyFileSync(d==f?f+" ":f,d);return d;}
function restore(f){const d=path.join(A,"backup",rel(f));if(fs.existsSync(d)){fs.copyFileSync(d,f);return true;}return false;}
function ev(o){try{fs.appendFileSync(path.join(A,"evidence.jsonl"),JSON.stringify(Object.assign({at:new Date().toISOString()},o))+"\n");}catch(e){}}
function jw(f,o){fs.mkdirSync(path.dirname(f),{recursive:true});atomic(f,JSON.stringify(o,null,1));}
function jr(f,d){try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}}
function log(m){try{fs.appendFileSync(path.join(A,"audit.log"),"["+new Date().toISOString().slice(11,19)+"] "+m+"\n");}catch(e){}}
module.exports={walk,rel,sha,size,read,atomic,backup,restore,ev,jw,jr,log,exists,ROOT,H,A,SKIP};
