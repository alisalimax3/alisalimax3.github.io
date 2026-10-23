#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process"),path=require("path");
const H=path.resolve(__dirname,".."),ID="cinehub";
const run=(c,a,cb)=>execFile(c,a,{timeout:9000},()=>cb&&cb());
const has=c=>new Promise(r=>execFile("which",[c],e=>r(!e)));
function notify(o){
  const a=["--id",ID,"--title",o.title||"CineHub","--content",o.content||"","--priority","high"];
  if(o.ongoing){a.push("--ongoing");a.push("--button1","⏹ إيقاف");a.push("--button1-action","bash "+path.join(H,"OMEGA.sh")+" stop");}
  if(o.progress!=null)a.push("--progress",String(Math.round(o.progress)),"--max","100");
  if(o.big)a.push("--big-text",o.big);
  run("termux-notification",a);
}
const toast=m=>run("termux-toast",["-g","bottom","-c","#2563eb","-b","#0b0e14",String(m).slice(0,220)]);
const vibrate=(d=250,pat)=>run("termux-vibrate",pat?["-p",pat]:["-d",String(d)]);
const clear=()=>run("termux-notification-remove",["--id",ID]);
const clip=()=>new Promise(r=>execFile("termux-clipboard-get",[],{timeout:6000},(e,so)=>r(String(so||"").trim())));
const clipSet=t=>run("termux-clipboard-set",[String(t)]);
const sms=(n=12)=>new Promise(r=>execFile("termux-sms-list",["-l",String(n)],{timeout:9000},(e,so)=>{try{r(JSON.parse(so)||[]);}catch(x){r([]);}}));
module.exports={notify,toast,vibrate,clear,clip,clipSet,sms,has,ID,H};
if(require.main===module){const[,,c]=process.argv;if(c==="test"){notify({title:"OMEGA",content:"الوكيل يعمل باسمك",ongoing:1});toast("✔ الجسر يعمل");vibrate(300,"200,100,200");}else if(c==="clear")clear();}
