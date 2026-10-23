#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto"),{execFileSync}=require("child_process");
const ROOT=path.resolve(__dirname,"..",".."),ENV=path.join(ROOT,"keys.env"),D=path.resolve(__dirname,"..","data"),REG=path.join(D,"secrets.json");
fs.mkdirSync(D,{recursive:true});
const hash=s=>crypto.createHash("sha256").update(String(s)).digest("hex").slice(0,16);
const mask=s=>{s=String(s);return s.length>16?s.slice(0,5)+"…"+s.slice(-4):s;};
function all(){const o={};try{fs.readFileSync(ENV,"utf8").split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0&&!/^\s*#/.test(l))o[l.slice(0,i).trim()]=l.slice(i+1).trim();});}catch(e){}return o;}
const get=k=>all()[k]||"";
function atomic(f,t){const tmp=f+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,f);try{fs.chmodSync(f,0o600);}catch(e){}}
function reg(){try{return JSON.parse(fs.readFileSync(REG,"utf8"));}catch(e){return{};}}
function set(o,src){const c=all(),r=reg(),at=new Date().toISOString();
  Object.keys(o).forEach(k=>{if(o[k]==null||o[k]==="")return;c[k]=String(o[k]);r[k]={at,src:src||"agent",h:hash(o[k]),mask:mask(o[k])};});
  atomic(ENV,Object.keys(c).sort().map(k=>k+"="+c[k]).join("\n")+"\n");atomic(REG,JSON.stringify(r,null,1));return Object.keys(o);}
function del(k){const c=all();delete c[k];atomic(ENV,Object.keys(c).sort().map(x=>x+"="+c[x]).join("\n")+"\n");const r=reg();delete r[k];atomic(REG,JSON.stringify(r,null,1));}
function verify(){const c=all(),r=reg(),bad=[];Object.keys(r).forEach(k=>{if(c[k]&&hash(c[k])!==r[k].h)bad.push(k);});
  return{total:Object.keys(c).length,tracked:Object.keys(r).length,bad};}
const P=()=>process.env.ZERO_VAULT_PASS||get("VAULT_PASS")||"zero-local";
function seal(){const o=execFileSync("openssl",["enc","-aes-256-cbc","-pbkdf2","-iter","200000","-salt","-pass","pass:"+P(),"-in",ENV]);
  const f=path.join(D,"vault.enc");fs.writeFileSync(f,o);try{fs.chmodSync(f,0o600);}catch(e){}return "✔ خُتمت الخزنة ("+o.length+" بايت)";}
function open(){const f=path.join(D,"vault.enc");if(!fs.existsSync(f))return "○ لا خزنة";
  const o=execFileSync("openssl",["enc","-d","-aes-256-cbc","-pbkdf2","-iter","200000","-pass","pass:"+P(),"-in",f]);
  atomic(ENV,o.toString());return "✔ استُعيدت keys.env";}
module.exports={get,set,del,all,reg,mask,hash,verify,seal,open,ENV};
if(require.main===module){const c=process.argv[2]||"list";
  if(c==="list")Object.entries(all()).forEach(([k,v])=>console.log("  "+k+" = "+mask(v)));
  else if(c==="verify"){const v=verify();console.log("  مفاتيح "+v.total+" · متعقّبة "+v.tracked+(v.bad.length?" · ✗ تغيّرت: "+v.bad.join(", "):" · ✔ سلامة سليمة"));}
  else if(c==="seal")console.log("  "+seal());else if(c==="open")console.log("  "+open());
  else if(c==="set"){const o={};process.argv.slice(3).forEach(a=>{const i=a.indexOf("=");if(i>0)o[a.slice(0,i)]=a.slice(i+1);});console.log("  ✔ "+set(o,"owner").join(", "));}}
