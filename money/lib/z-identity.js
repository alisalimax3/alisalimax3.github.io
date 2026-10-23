#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const H=path.resolve(__dirname,".."),D=path.join(H,"data"),ID=path.join(D,"identity.json"),CS=path.join(D,"consent.json"),CR=path.join(H,"db","creds.json");
fs.mkdirSync(D,{recursive:true});
const K=require("./z-keys.js");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>fs.writeFileSync(f,JSON.stringify(o,null,1));
function get(){return Object.assign({brand:"CineHub",handle:"cinehub",name:"",email:"",phone:"",country:"",
  site_url:K.get("PUBLIC_URL")||"",wallet:K.get("PAYOUT_ADDRESS")||"",payout_chain:"base"},rd(ID,{}));}
function ensure(){if(!fs.existsSync(ID))wr(ID,get());if(!fs.existsSync(CS))wr(CS,{at:new Date().toISOString(),
  grants:{"استخدام بريدي المؤقت للتحقق":"مصرّح","إنشاء كلمات مرور وحفظها في keys.env":"مصرّح",
  "فتح المتصفح وملء النماذج نيابة عني":"مصرّح","طلب تدخّلي عند KYC/دفع/تحقق بشري":"مصرّح"}});
  return get();}
function creds(id){const c=rd(CR,{});if(c[id])return c[id];
  const I=get();const u=(I.handle||"cine")+"_"+crypto.randomBytes(2).toString("hex");
  const p=crypto.randomBytes(9).toString("base64url")+"!9";
  c[id]={user:u,pass:p,at:new Date().toISOString()};wr(CR,c);return c[id];}
module.exports={get,ensure,creds,rd,wr};
if(require.main===module){const c=process.argv[2]||"show";
  if(c==="init")console.log("  ✔ الهوية والتفويض جاهزان (money/data/identity.json + consent.json)");
  else if(c==="creds")Object.entries(rd(CR,{})).forEach(([k,v])=>console.log("  "+k+" → "+v.user+" / "+v.pass));
  else console.log(JSON.stringify(get(),null,1));}
