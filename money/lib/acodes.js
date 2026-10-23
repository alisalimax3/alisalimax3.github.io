#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,"..",".."),LOGS=path.join(ROOT,"logs");
try{fs.mkdirSync(LOGS,{recursive:true});}catch(e){}
const F=path.join(LOGS,"codes.log"),V=path.join(LOGS,"vault.json");
const mask=v=>{const s=String(v);return s.length>16?s.slice(0,6)+"…"+s.slice(-4):s;};
function save(title,data){const at=new Date().toISOString();
  try{fs.appendFileSync(F,"["+at+"] "+title+" :: "+JSON.stringify(data)+"\n");}catch(e){}
  let v={};try{v=JSON.parse(fs.readFileSync(V,"utf8"));}catch(e){}
  v[title]=v[title]||[];v[title].push({at,data});
  try{fs.writeFileSync(V,JSON.stringify(v,null,1));fs.chmodSync(V,0o600);}catch(e){}
  try{fs.chmodSync(F,0o600);}catch(e){}}
module.exports={save,mask};
