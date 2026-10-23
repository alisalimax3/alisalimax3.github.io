#!/usr/bin/env node
"use strict";
const K=require("./akeys.js");
function post(url,body){return new Promise(r=>{try{const https=require("https"),d=JSON.stringify(body);
  const q=https.request(url,{method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(x.statusCode));});
  q.on("error",()=>r(0));q.write(d);q.end();}catch(e){r(0);}});}
async function send(text){const t=K.get("TELEGRAM_BOT_TOKEN"),c=K.get("TELEGRAM_CHAT_ID");
  if(t&&c)await post("https://api.telegram.org/bot"+t+"/sendMessage",{chat_id:c,text,parse_mode:"HTML"});
  const w=K.get("ALERT_WEBHOOK");if(w)await post(w,{text});
  const dc=K.get("DISCORD_WEBHOOK");if(dc)await post(dc,{content:text});
  return !!(t&&c)||!!w||!!dc;}
module.exports={send};
if(require.main===module){send(process.argv.slice(2).join(" ")||"APEX يعمل").then(ok=>console.log("  "+(ok?"✔ أُرسل":"○ لا قناة — أضف TELEGRAM_BOT_TOKEN+TELEGRAM_CHAT_ID أو ALERT_WEBHOOK")));}
