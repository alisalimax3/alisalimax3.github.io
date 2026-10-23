#!/usr/bin/env node
"use strict";
const crypto=require("crypto");
const A="ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
function b32enc(buf){let bits=0,val=0,o="";for(const b of buf){val=(val<<8)|b;bits+=8;while(bits>=5){o+=A[(val>>>(bits-5))&31];bits-=5;}}if(bits)o+=A[(val<<(5-bits))&31];return o;}
function b32dec(s){let bits=0,val=0,o=[];for(const c of String(s).replace(/[^A-Za-z2-7]/g,"").toUpperCase()){const i=A.indexOf(c);if(i<0)continue;val=(val<<5)|i;bits+=5;if(bits>=8){o.push((val>>>(bits-8))&255);bits-=8;}}return Buffer.from(o);}
const gen=(n=20)=>b32enc(crypto.randomBytes(n));
function code(secret,step=30,digits=6,at=Date.now()){
  const key=b32dec(secret),t=Math.floor(at/1000/step);
  const b=Buffer.alloc(8);b.writeUInt32BE(Math.floor(t/2**32),0);b.writeUInt32BE(t>>>0,4);
  const h=crypto.createHmac("sha1",key).update(b).digest(),o=h[19]&15;
  const n=((h[o]&127)<<24)|(h[o+1]<<16)|(h[o+2]<<8)|h[o+3];
  return String(n%(10**digits)).padStart(digits,"0");
}
const url=(s,l,i)=>`otpauth://totp/${encodeURIComponent(i)}:${encodeURIComponent(l)}?secret=${s}&issuer=${encodeURIComponent(i)}&algorithm=SHA1&digits=6&period=30`;
module.exports={gen,code,url,b32dec,b32enc};
if(require.main===module){
  const s=process.argv[2]; if(!s)return console.log(gen());
  console.log("  الرمز الآن : "+code(s)+"   (يبقى "+(30-(Math.floor(Date.now()/1000)%30))+" ثانية)");
  console.log("  تحقّق: افتح تطبيق المصادقة — يجب أن يطابق تمامًا. إن طابق فهو حقيقي لا وهمي.");
}
