#!/usr/bin/env node
"use strict";
const {execFile}=require("child_process"),fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),CJ=path.join(H,"db","cookies");
const UA=["Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36",
 "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125 Safari/537.36",
 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36"];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const RATE={};
const jar=h=>{fs.mkdirSync(CJ,{recursive:true});return path.join(CJ,String(h).replace(/[^\w.-]/g,"_")+".txt");};
const curl=(a,t)=>new Promise(r=>execFile("curl",a,{timeout:t||30000,maxBuffer:12e6},(e,so,se)=>r({e,so:String(so||""),se:String(se||"")})));
async function req(method,url,o){o=o||{};
  let host="x";try{host=new URL(url).host;}catch(e){}
  const gap=o.gap==null?1200:o.gap,last=RATE[host]||0,wait=Math.max(0,last+gap-Date.now());
  if(wait>0)await sleep(wait);RATE[host]=Date.now();
  const a=["-sL","--max-time",String(Math.round((o.timeout||30000)/1000)),"-A",o.ua||UA[Math.floor(Math.random()*UA.length)],
    "-w","\n%{http_code} %{time_total} %{url_effective}","-b",jar(host),"-c",jar(host),"--compressed"];
  Object.entries(o.headers||{}).forEach(([k,v])=>a.push("-H",k+": "+v));
  if(method!=="GET")a.push("-X",method);
  if(o.json)a.push("-H","content-type: application/json","--data-binary",JSON.stringify(o.json));
  else if(o.form)Object.entries(o.form).forEach(([k,v])=>a.push("--data-urlencode",k+"="+(v==null?"":String(v))));
  a.push(url);
  const r=await curl(a,o.timeout||30000);
  const parts=r.so.replace(/\s+$/,"").split("\n"),meta=(parts.pop()||"").split(" ");
  return{status:Number(meta[0]||0),ms:Math.round(Number(meta[1]||0)*1000),url:meta[2]||url,body:parts.join("\n"),
    ok:Number(meta[0]||0)>0&&Number(meta[0]||0)<400,err:r.se};
}
async function retry(method,url,o,tries){tries=tries||3;let r;
  for(let i=0;i<tries;i++){r=await req(method,url,o);if(r.status>0&&r.status<500)return r;await sleep(1200*(i+1));}
  return r;}
const get=(u,o)=>req("GET",u,o);
const post=(u,o)=>req("POST",u,o);
function links(html,base){const out=new Set(),re=/href=["']([^"'#]+)["']/gi;let m;
  while((m=re.exec(html))){let h=m[1];if(/^(mailto:|javascript:|tel:|data:)/.test(h))continue;
    try{h=new URL(h,base).href;}catch(e){continue;}
    if(/signup|sign-up|register|join|create-account|publisher|partner|dashboard|pricing|login|signin/i.test(h))out.add(h);}
  return [...out].slice(0,50);}
function hiddenFields(html){const o={},re=/<input[^>]*type=["']hidden["'][^>]*>/gi;let m;
  while((m=re.exec(html))){const n=(m[0].match(/name=["']([^"']+)["']/i)||[])[1],v=(m[0].match(/value=["']([^"']*)["']/i)||[])[1];
    if(n&&!/csrf|token/i.test(n))o[n]=v||"";}
  return o;}
const tpl=(s,v)=>String(s||"").replace(/\{(\w+)\}/g,(m,k)=>v&&v[k]!=null?v[k]:m);
module.exports={req,get,post,retry,links,hiddenFields,tpl,sleep,jar,UA};
