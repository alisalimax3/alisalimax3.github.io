#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,"..",".."),D=path.join(ROOT,"logs");
fs.mkdirSync(D,{recursive:true});
const FILE=path.join(D,"codes.log"),VAULT=path.join(D,"vault.json");
function save(title,obj){
  const t=new Date().toISOString();
  const body=Object.entries(obj).filter(([k,v])=>v!=null&&v!=="").map(([k,v])=>`    ${k}: ${v}`).join("\n");
  const block=`\n[${t}] ${title}\n${body}\n`;
  fs.appendFileSync(FILE,block); try{fs.chmodSync(FILE,0o600);}catch(e){}
  let V={}; try{V=JSON.parse(fs.readFileSync(VAULT,"utf8"));}catch(e){}
  V[title]=Object.assign(V[title]||{},{...obj,_updated:t});
  const tmp=VAULT+"."+process.pid+".tmp"; fs.writeFileSync(tmp,JSON.stringify(V,null,2)); fs.renameSync(tmp,VAULT);
  try{fs.chmodSync(VAULT,0o600);}catch(e){}
  return block;
}
module.exports={save,FILE,VAULT};
if(require.main===module){const[, ,t,...kv]=process.argv,o={};kv.forEach(p=>{const i=p.indexOf("=");o[p.slice(0,i)]=p.slice(i+1);});console.log(save(t||"ملاحظة",o));}
