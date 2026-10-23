#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),LOG=path.join(ROOT,"logs","zero.log"),ID="zero-owner";
const run=(c,a)=>new Promise(r=>{try{execFile(c,a||[],{timeout:9000},()=>r(true));}catch(e){r(false);}});
function has(c){return new Promise(r=>execFile("sh",["-c","command -v "+c],e=>r(!e)));}
async function notify(o){if(!await has("termux-notification")){try{fs.appendFileSync(LOG,"[notify] "+(o.title||"")+" — "+(o.content||"")+"\n");}catch(e){}return;}
  const a=["--id",ID,"--title",o.title||"ZERO","--content",o.content||"","--priority","high"];
  if(o.ongoing)a.push("--ongoing","--button1","⏹ إيقاف","--button1-action","bash "+path.join(H,"ZERO.sh")+" stop",
    "--button2","🧑 مهمة لي","--button2-action","bash "+path.join(H,"ZERO.sh")+" human --sheet");
  if(o.big)a.push("--big-text",String(o.big).slice(0,400));
  await run("termux-notification",a);}
const clear=()=>run("termux-notification-remove",["--id",ID]);
const toast=m=>run("termux-toast",["-g","bottom",String(m)]);
const vibrate=p=>run("termux-vibrate",p?["-p",p]:["-d","250"]);
async function telegram(t){const K=require("./z-keys.js");const tok=K.get("TELEGRAM_BOT_TOKEN"),ch=K.get("TELEGRAM_CHAT_ID");
  if(!tok||!ch)return false;const https=require("https"),d=JSON.stringify({chat_id:ch,text:t,parse_mode:"HTML"});
  return new Promise(r=>{const q=https.request("https://api.telegram.org/bot"+tok+"/sendMessage",
    {method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(true));});
    q.on("error",()=>r(false));q.write(d);q.end();});}
module.exports={notify,clear,toast,vibrate,telegram};
