#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),U=require("./q-util.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
function perms(p,want){try{const m=fs.statSync(p).mode&0o777;return m===want;}catch(e){return null;}}
function audit(inv){const D=[];const add=(sev,rule,file,msg,fix)=>{const _s=({sev,rule,file,msg,fixable:!!fix});if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER|PORT|CURRENCY)$/i.test(String(_s))){const _s=(_s);if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER|PORT|CURRENCY|TYPE|MODE|ENV)$/i.test(String(_s)))D.push(_s);}}
  const envp=path.join(U.ROOT,"keys.env");
  if(U.exists(envp)&&perms(envp,0o600)===false)add("high","perm","keys.env","صلاحيات keys.env ليست 600",true);
  for(const f of ["logs/codes.log","logs/vault.json","money/data/vault.enc","money/data/secrets.json","money/db/creds.json"])
    if(U.exists(path.join(U.ROOT,f))&&perms(path.join(U.ROOT,f),0o600)===false)add("med","perm",f,"الصلاحيات ليست 600",true);
  const gi=path.join(U.ROOT,".gitignore"),g=U.exists(gi)?U.read(gi):"";
  for(const x of ["keys.env","node_modules","logs","*.pid","_backup","_deploy"])
    if(!g.includes(x))add("med","gitignore",".gitignore","لا يستثني: "+x,true);
  const secrets=[];
  U.read(envp).split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0){const k=l.slice(0,i).trim(),v=l.slice(i+1).trim();
    if(v&&v.length>=16&&!/^(true|false|\d+)$/.test(v)&&!/^https?:/.test(v))if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER)$/.test(k))secrets.push({k,v});}});
  for(const f of inv.pages.concat(inv.scripts)){const s=U.read(path.join(U.ROOT,f),600000);
    const hit=secrets.filter(x=>s.includes(x.v));
    if(hit.length)add("high","secret-leak",f,"مفاتيح مكشوفة: "+hit.map(x=>x.k).slice(0,6).join(", "),false);}
  for(const f of inv.servers){const s=U.read(path.join(U.ROOT,f),800000);
    if(/access-control-allow-origin["']?\s*[:=]\s*["']\*/i.test(s))add("med","cors",f,"CORS مفتوح للجميع",false);
    if(!/x-content-type-options/i.test(s))add("low","header",f,"لا X-Content-Type-Options",false);
    if(!/x-frame-options|frame-ancestors/i.test(s))add("low","header",f,"لا X-Frame-Options",false);
    if(!/referrer-policy/i.test(s))add("low","header",f,"لا Referrer-Policy",false);
    if(!/content-security-policy/i.test(s))add("low","header",f,"لا CSP",false);
    if(!/rate|limit/i.test(s))add("low","ratelimit",f,"لا حدّ معدّل ظاهر",false);
    if(/["']0\.0\.0\.0["']/.test(s))add("low","bind",f,"مستمع على 0.0.0.0 (مكشوف للشبكة)",false);
    if(/\.\.\/|path\.join\(.*req\.url/.test(s)&&!/normalize/.test(s))add("med","traversal",f,"مسارات غير مُطبَّعة",false);}
  return D;}
if(require.main===module){const inv=INV(),D=audit(inv);
  U.jw(path.join(U.A,"findings-sec.json"),{at:new Date().toISOString(),count:D.length,items:D});
  const by={};D.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
  console.log("  ✔ أمان: "+D.length+" ملاحظة — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
  D.filter(x=>x.sev!=="low").slice(0,8).forEach(x=>console.log("   ✗ ["+x.rule+"] "+x.file+" — "+x.msg));
  U.ev({phase:"sec",ok:!D.some(x=>x.sev==="high"),detail:{count:D.length,by}});}
module.exports={audit,perms};
