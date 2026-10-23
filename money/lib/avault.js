#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),crypto=require("crypto");
const ROOT=path.resolve(__dirname,"..",".."),D=path.resolve(__dirname,"..","data");
const K=path.join(ROOT,"keys.env"),V=path.join(D,"vault.enc");
const pass=()=>process.env.APEX_VAULT_PASS||require("./akeys.js").get("VAULT_PASS")||"apex-local";
function seal(){if(!fs.existsSync(K))return "○ لا keys.env";
  const out=execFileSync("openssl",["enc","-aes-256-cbc","-pbkdf2","-iter","200000","-salt","-pass","pass:"+pass(),"-in",K]);
  fs.writeFileSync(V,out);try{fs.chmodSync(V,0o600);}catch(e){}
  return "✔ خُتمت الخزنة ("+out.length+" بايت) — النسخة المشفّرة في money/data/vault.enc";}
function open(){if(!fs.existsSync(V))return "○ لا خزنة";
  const out=execFileSync("openssl",["enc","-d","-aes-256-cbc","-pbkdf2","-iter","200000","-pass","pass:"+pass(),"-in",V]);
  fs.writeFileSync(K,out);try{fs.chmodSync(K,0o600);}catch(e){}return "✔ فُتحت الخزنة واستُعيد keys.env";}
module.exports={seal,open};
if(require.main===module){console.log("  "+(process.argv[2]==="open"?open():seal()));}
