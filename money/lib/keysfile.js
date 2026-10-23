#!/usr/bin/env node
"use strict";
// قارئ/كاتب keys.env حقيقي: يفصل الأسطر الملتصقة، يوحّد الشكل، يكتب ذرّيًا
const fs=require("fs"),path=require("path");
const ROOT=path.resolve(__dirname,"..",".."),KEYS=path.join(ROOT,"keys.env");
const RX=/([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)(?=\s+[A-Za-z_][A-Za-z0-9_]*\s*=|\s*$)/g;
function read(){
  let t="";try{t=fs.readFileSync(KEYS,"utf8");}catch(e){return {};}
  const o={};
  for(const line of t.split(/\r?\n/)){
    if(!line.trim()||line.trim().startsWith("#"))continue;
    RX.lastIndex=0;let m;
    while((m=RX.exec(line))){const k=m[1],v=(m[2]||"").trim();if(!(k in o))o[k]=v;}
  }
  return o;
}
function writeAll(o){
  const t=Object.keys(o).sort().map(k=>k+"="+o[k]).join("\n")+"\n";
  const tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);
  try{fs.chmodSync(KEYS,0o600);}catch(e){}
}
const set=kv=>{const o=read();for(const[k,v]of Object.entries(kv))o[k]=v;writeAll(o);};
const get=k=>read()[k]||"";
const normalize=()=>{const o=read();writeAll(o);return Object.keys(o).length;};
module.exports={read,writeAll,set,get,normalize,KEYS};
if(require.main===module){
  const[,,c,...a]=process.argv;
  if(c==="normalize")console.log("  ✔ نُظّف keys.env — "+normalize()+" مفتاح مفصول بشكل صحيح");
  else if(c==="set"){const o={};a.forEach(p=>{const i=p.indexOf("=");o[p.slice(0,i)]=p.slice(i+1);});set(o);console.log("  ✔ حُفظ "+a.length);}
  else if(c==="get")console.log(get(a[0]));
  else if(c==="list")Object.entries(read()).forEach(([k,v])=>console.log((v?"✔":"○")+" "+k));
}
