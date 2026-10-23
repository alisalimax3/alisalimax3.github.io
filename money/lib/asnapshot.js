#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),B=path.join(ROOT,"_backup");
function make(){fs.mkdirSync(B,{recursive:true});
  const f=path.join(B,"apex-"+new Date().toISOString().replace(/[:.]/g,"-")+".tar.gz");
  execFileSync("tar",["-czf",f,"--exclude=node_modules","--exclude=_backup","--exclude=.git","-C",ROOT,"."],{stdio:"pipe",timeout:400000});
  const all=fs.readdirSync(B).filter(x=>x.endsWith(".tar.gz")).sort();
  while(all.length>7)fs.unlinkSync(path.join(B,all.shift()));
  return f;}
function restore(f){execFileSync("tar",["-xzf",f,"-C",ROOT],{stdio:"pipe"});return "✔ استُعيد من "+f;}
module.exports={make,restore};
if(require.main===module){const c=process.argv[2];
  if(c==="restore")console.log("  "+restore(process.argv[3]));
  else{const f=make();console.log("  ✔ نسخة احتياطية: "+path.relative(ROOT,f)+" ("+Math.round(fs.statSync(f).size/1024)+"KB)");}}
