#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
function lint(inv){const D=[];const add=(sev,rule,file,msg,fix)=>D.push({sev,rule,file,msg,fixable:!!fix});
  for(const f of inv.scripts){try{execFileSync("node",["--check",path.join(U.ROOT,f)],{stdio:"pipe"});}
    catch(e){add("high","js-syntax",f,String(e.stderr||e.message||"").split("\n").filter(Boolean).slice(0,2).join(" "),false);}}
  for(const f of inv.configs){try{JSON.parse(U.read(path.join(U.ROOT,f),2e6));}catch(e){add("high","json-parse",f,String(e.message).slice(0,80),false);}}
  for(const f of inv.pages){const p=path.join(U.ROOT,f),s=U.read(p,900000);
    if(!/<meta\s+charset/i.test(s))add("med","html-charset",f,"لا charset",true);
    if(!/name=["']viewport/i.test(s))add("med","html-viewport",f,"لا viewport",true);
    if(!/<title>\s*\S/i.test(s))add("med","html-title",f,"لا title",true);
    if(!/name=["']description/i.test(s))add("low","html-desc",f,"لا description",true);
    if(!/<html[^>]*lang=/i.test(s))add("low","html-lang",f,"لا lang",true);
    if(!/rel=["']icon/i.test(s))add("low","html-favicon",f,"لا favicon",true);
    if(/=["']http:\/\//.test(s))add("low","mixed-content",f,"روابط http://",false);
    if(/<img(?![^>]*\balt=)/i.test(s))add("low","img-alt",f,"صور بلا alt",false);
    if(/target=["']_blank["'](?![^>]*\brel=)/i.test(s))add("low","blank-rel",f,"target=_blank بلا rel",true);
    if(/<button(?![^>]*\btype=)/i.test(s))add("low","button-type",f,"زر بلا type",true);
    const o=(s.match(/<div\b/gi)||[]).length,c=(s.match(/<\/div>/gi)||[]).length;
    if(Math.abs(o-c)>2)add("med","html-balance",f,"عدم توازن div "+o+"/"+c,false);
    const ids=[...s.matchAll(/\sid=["']([^"']+)["']/g)].map(m=>m[1]);
    const dup=[...new Set(ids.filter((x,i)=>ids.indexOf(x)!==i))];
    if(dup.length)add("low","dup-id",f,"معرّفات مكررة: "+dup.slice(0,5).join(","),false);
    for(const m of s.matchAll(/(?:href|src)=["'](?!https?:|\/\/|#|mailto:|tel:|data:|javascript:)([^"']+)["']/g)){
      const t=m[1].split(/[?#]/)[0];if(!t)continue;
      const abs=t.startsWith("/")?path.join(U.ROOT,t):path.join(path.dirname(p),t);
      if(!fs.existsSync(abs)&&!/\.(php|cgi)$/.test(abs))add("med","broken-ref",f,"مرجع مفقود: "+t,true);}}
  for(const f of inv.styles){const s=U.read(path.join(U.ROOT,f),700000);
    const o=(s.match(/{/g)||[]).length,c=(s.match(/}/g)||[]).length;
    if(o!==c)add("med","css-braces",f,"أقواس غير متوازنة "+o+"/"+c,false);
    for(const m of s.matchAll(/url\(["']?(?!data:|https?:|\/\/)([^"')]+)["']?\)/g))
      if(!fs.existsSync(path.join(U.ROOT,m[1])))add("low","css-url",f,"ملف مفقود: "+m[1],false);}
  for(const [f,sev] of [["robots.txt","med"],["sitemap.xml","med"],["manifest.webmanifest","low"],["security.txt","low"],["ads.txt","low"],["404.html","med"]])
    if(!U.exists(path.join(U.ROOT,f)))add(sev,"missing-file",f,"الملف غير موجود",true);
  for(const f of inv.scripts.concat(inv.pages)){const s=U.read(path.join(U.ROOT,f),400000);
    const t=(s.match(/\bTODO\b|\bFIXME\b/g)||[]).length;if(t)add("low","todo",f,t+" علامة TODO/FIXME",false);
    const cl=(s.match(/console\.log/g)||[]).length;if(cl>12&&/\.js$/.test(f))add("low","console",f,cl+" console.log",false);}
  return D;}
if(require.main===module){const inv=INV(),D=lint(inv);
  U.jw(path.join(U.A,"findings-lint.json"),{at:new Date().toISOString(),count:D.length,items:D});
  const by={};D.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
  console.log("  ✔ تشخيص ساكن: "+D.length+" ملاحظة — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
  D.filter(x=>x.sev==="high").slice(0,8).forEach(x=>console.log("   ✗ ["+x.rule+"] "+x.file+" — "+x.msg));
  U.ev({phase:"lint",ok:!D.some(x=>x.sev==="high"),detail:{count:D.length,by}});}
module.exports={lint};
