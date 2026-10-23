#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process"),U=require("./q-util.js");
const APPLY=process.env.APPLY==="1";
const INV=()=>U.jr(path.join(U.A,"inventory.json"),null)||require("./q-scan.js").inventory();
const K={};U.read(path.join(U.ROOT,"keys.env")).split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0)K[l.slice(0,i).trim()]=l.slice(i+1).trim();});
const head=u=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","-w","%{http_code}","--max-time","12",u],(e,so)=>r(Number(so)||0)));
const MARK=(s,tag)=>s.includes(tag);
const RULES=[
 {id:"adsense",need:["ADSENSE_CLIENT"],tag:"adsbygoogle.js",html:s=>'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='+K.ADSENSE_CLIENT+'" crossorigin="anonymous"></script>',probe:"https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"},
 {id:"ga4",need:["GA_ID"],tag:"gtag/js?id=",html:s=>'<script async src="https://www.googletagmanager.com/gtag/js?id='+K.GA_ID+'"></script><script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments)}gtag("js",new Date());gtag("config","'+K.GA_ID+'");</script>',probe:"https://www.googletagmanager.com/gtag/js?id="+ (K.GA_ID||"G-0")},
 {id:"gtm",need:["GTM_ID"],tag:"gtm.js?id=",html:s=>'<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({"gtm.start":new Date().getTime(),event:"gtm.js"});var f=d.getElementsByTagName(s)[0],j=d.createElement(s),dl=l!="dataLayer"?"&l="+l:"";j.async=true;j.src="https://www.googletagmanager.com/gtm.js?id="+i+dl;f.parentNode.insertBefore(j,f);})(window,document,"script","dataLayer","'+K.GTM_ID+'");</script>',probe:"https://www.googletagmanager.com/gtm.js?id="+ (K.GTM_ID||"GTM-0")},
 {id:"plausible",need:["PLAUSIBLE_DOMAIN"],tag:"plausible.io/js/script.js",html:s=>'<script defer data-domain="'+K.PLAUSIBLE_DOMAIN+'" src="https://plausible.io/js/script.js"></script>',probe:"https://plausible.io/js/script.js"},
 {id:"goatcounter",need:["GOATCOUNTER_CODE"],tag:"gc.zgo.at/count.js",html:s=>'<script data-goatcounter="https://'+K.GOATCOUNTER_CODE+'.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>',probe:"https://gc.zgo.at/count.js"},
 {id:"cloudflare-analytics",need:["CF_BEACON_TOKEN"],tag:"cloudflareinsights.com/beacon",html:s=>'<script defer src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon=\'{"token":"'+K.CF_BEACON_TOKEN+'"}\'></script>',probe:"https://static.cloudflareinsights.com/beacon.min.js"},
 {id:"sentry",need:["SENTRY_DSN"],tag:"sentry",html:s=>'<script src="https://browser.sentry-cdn.com/8.0.0/bundle.min.js" crossorigin="anonymous"></script><script>Sentry&&Sentry.init({dsn:"'+K.SENTRY_DSN+'"});</script>',probe:"https://browser.sentry-cdn.com/8.0.0/bundle.min.js"}
];
async function wire(){
  const inv=INV(),report={at:new Date().toISOString(),apply:APPLY,items:[],adsTxt:null};
  for(const r of RULES){const have=r.need.every(k=>K[k]);
    const marker=r.tag;
    const pages=inv.pages.filter(f=>U.read(path.join(U.ROOT,f),600000).includes("</head>"));
    const missing=pages.filter(f=>!MARK(U.read(path.join(U.ROOT,f),600000),marker));
    const item={id:r.id,configured:have,needed:r.need,missingPages:missing.length,totalPages:pages.length,applied:0,probe:0,verified:false};
    if(have&&APPLY&&missing.length){
      for(const f of missing){const p=path.join(U.ROOT,f);const s=U.read(p,900000);
        U.backup(p);U.atomic(p,s.replace(/<\/head>/i,r.html()+"\n</head>"));item.applied++;}
      item.verified=missing.every(f=>MARK(U.read(path.join(U.ROOT,f),600000),marker));
      U.ev({phase:"wire",ok:item.verified,detail:{rule:r.id,pages:item.applied}});}
    if(have){item.probe=await head(r.probe);item.verified=item.verified||(item.probe>0&&item.probe<400);}
    report.items.push(item);}
  const pub=K.PUBLIC_URL||"";
  const lines=[];
  if(K.ADSENSE_CLIENT)lines.push("google.com, "+K.ADSENSE_CLIENT.replace(/^ca-/,"")+", DIRECT, f08c47fec0942fa0");
  for(const n of ["ADSTERRA","MONETAG","EXOCLICK","JUICYADS","PROPELLERADS","CLICKADILLA"])if(K[n+"_PUB_ID"])lines.push("# "+n.toLowerCase()+" pub "+K[n+"_PUB_ID"]);
  const ap=path.join(U.ROOT,"ads.txt");const cur=U.exists(ap)?U.read(ap):"";
  const addLines=lines.filter(l=>l&&!cur.includes(l));
  report.adsTxt={would:addLines.length,existing:cur.split("\n").filter(Boolean).length};
  if(APPLY&&addLines.length){U.backup(ap);U.atomic(ap,(cur.trimEnd()+"\n"+addLines.join("\n")+"\n").replace(/^\n/,""));
    report.adsTxt.written=true;report.adsTxt.verified=U.read(ap).includes(addLines[0]);U.ev({phase:"wire-ads",ok:!!report.adsTxt.verified,detail:report.adsTxt});}
  U.jw(path.join(U.A,"wire.json"),report);
  const done=report.items.filter(x=>x.verified).length,ready=report.items.filter(x=>x.configured).length;
  console.log("  ✔ ربط الخدمات: مُعدّ "+ready+" · مُتحقَّق "+done+" من "+report.items.length+(APPLY?" (طُبّق)":" (تشخيص)"));
  report.items.filter(x=>x.configured).forEach(x=>console.log("   "+(x.verified?"✔":"○")+" "+x.id+(x.applied?" · أُضيف لـ"+x.applied+" صفحة":"")));
  U.ev({phase:"wire",ok:true,detail:{configured:ready,verified:done}});}
wire();
module.exports={wire,RULES};
