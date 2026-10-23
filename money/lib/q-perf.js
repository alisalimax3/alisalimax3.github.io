#!/usr/bin/env node
"use strict";
const path=require("path"),U=require("./q-util.js");
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
function audit(inv){const F=[];const add=(sev,rule,file,msg)=>F.push({sev,rule,file,msg});
  let js=0,css=0;const big=[];
  for(const f of inv.scripts.concat(inv.styles)){const s=U.size(path.join(U.ROOT,f));/\.js$/.test(f)?js+=s:css+=s;
    if(s>150000)big.push({f,s});}
  const minJs=inv.scripts.filter(f=>/\.min\.js$/.test(f)).length,minCss=inv.styles.filter(f=>/\.min\.css$/.test(f)).length;
  if(inv.counts.js>0&&minJs===0)add("med","minify","*.js","لا نسخ مصغّرة ("+Math.round(js/1024)+"KB JS)");
  if(inv.counts.css>0&&minCss===0)add("low","minify","*.css","لا CSS مصغّر ("+Math.round(css/1024)+"KB)");
  big.sort((a,b)=>b.s-a.s).slice(0,8).forEach(x=>add("low","big-file",x.f,Math.round(x.s/1024)+"KB"));
  for(const f of inv.pages){const p=path.join(U.ROOT,f),s=U.read(p,900000);
    const head=(s.split(/<\/head>/i)[0]||"");
    const block=[...head.matchAll(/<script(?![^>]*\b(?:async|defer)\b)([^>]*)>/gi)].length;
    if(block>0)add("low","blocking-js",f,block+" سكربت حاجب في head");
    const third=[...new Set([...s.matchAll(/https?:\/\/([a-z0-9.\-]+)/gi)].map(m=>m[1]))].filter(h=>!/^www\.(google|bing|yandex)/.test(h));
    if(third.length>8)add("low","third-party",f,third.length+" نطاق خارجي");
    const img=(s.match(/<img\b/gi)||[]).length;if(img>25)add("low","img-count",f,img+" صورة");
    if(!/loading=["']lazy/i.test(s)&&img>6)add("low","lazy",f,"صور بلا loading=lazy");
    const els=(s.match(/<[a-z][^>]*>/gi)||[]).length;if(els>1500)add("low","dom",f,els+" عنصر (DOM كبير)");}
  const total=inv.pages.reduce((a,f)=>a+U.size(path.join(U.ROOT,f)),0);
  return {findings:F,stats:{jsKB:Math.round(js/1024),cssKB:Math.round(css/1024),pagesKB:Math.round(total/1024),pages:inv.pages.length}};}
if(require.main===module){const inv=INV(),r=audit(inv);
  U.jw(path.join(U.A,"findings-perf.json"),{at:new Date().toISOString(),...r});
  console.log("  ✔ أداء: "+r.findings.length+" ملاحظة · JS "+r.stats.jsKB+"KB · CSS "+r.stats.cssKB+"KB · صفحات "+r.stats.pagesKB+"KB");
  r.findings.slice(0,6).forEach(x=>console.log("   ○ ["+x.rule+"] "+x.file+" — "+x.msg));
  U.ev({phase:"perf",ok:true,detail:r.stats});}
module.exports={audit};
