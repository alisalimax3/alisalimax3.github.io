#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),LOG=path.join(ROOT,"logs","apex.log"),ID="cinehub-apex";
const cache={};
function has(c){return new Promise(r=>{if(c in cache)return r(cache[c]);execFile("sh",["-c","command -v "+c],e=>{cache[c]=!e;r(!e);});});}
const run=(c,a)=>new Promise(r=>{try{execFile(c,a||[],{timeout:9000},()=>r(true));}catch(e){r(false);}});
async function notify(o){
  if(!await has("termux-notification")){try{fs.appendFileSync(LOG,"[notify] "+(o.title||"")+" — "+(o.content||"")+"\n");}catch(e){}return;}
  const a=["--id",ID,"--title",o.title||"APEX","--content",o.content||"","--priority","high"];
  if(o.ongoing)a.push("--ongoing","--button1","⏹ إيقاف","--button1-action","bash "+path.join(H,"APEX.sh")+" stop",
                      "--button2","📊 الحالة","--button2-action","bash "+path.join(H,"APEX.sh")+" status");
  if(o.big)a.push("--big-text",String(o.big).slice(0,400));
  if(o.progress!=null)a.push("--progress",String(Math.round(o.progress)),"--max","100");
  await run("termux-notification",a);
}
const toast=m=>run("termux-toast",["-g","bottom",String(m)]);
const vibrate=p=>run("termux-vibrate",p?["-p",p]:["-d","250"]);
const clear=()=>run("termux-notification-remove",["--id",ID]);
const clip=()=>new Promise(r=>execFile("termux-clipboard-get",[],(e,so)=>r(String(so||"").trim())));
const clipSet=t=>run("termux-clipboard-set",[String(t)]);
const sms=n=>new Promise(r=>execFile("termux-sms-list",["-l",String(n)],(e,so)=>{try{r(JSON.parse(so)||[]);}catch(x){r([]);}}));
module.exports={notify,toast,vibrate,clear,clip,clipSet,sms,has,ID};
