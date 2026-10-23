#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
A="$H/data/ads.json"
node - "$A" "$@" <<'JS'
const fs=require("fs"),path=require("path"),A=process.argv[2];
const K=require(path.join(path.dirname(A),"..","lib","keysfile.js"));
const MAP={adsterra:["ADSTERRA_API_KEY"],monetag:["MONETAG_API_KEY"],exoclick:["EXOCLICK_API_TOKEN"],
 trafficjunky:["TRAFFICJUNKY_API_KEY"],juicyads:["JUICYADS_API_KEY"],clickadilla:["CLICKADILLA_API_KEY"],
 propellerads:["PROPELLERADS_API_KEY"],evadav:["EVADAV_API_KEY"],pushhouse:["PUSHHOUSE_TOKEN"],
 lospollos:["LOSPOLLOS_API_KEY"],adsense:["ADSENSE_CLIENT"],analytics:["GOATCOUNTER_CODE"]};
const rd=()=>{try{return JSON.parse(fs.readFileSync(A,"utf8"));}catch(e){return[];}};
const wr=x=>fs.writeFileSync(A,JSON.stringify(x,null,1));
const[c,id,...rest]=process.argv.slice(3);
if(c==="list"){rd().forEach(a=>console.log("  "+(a.enabled?"●":"○")+" "+(a.snippet?"[كود]":"[فارغ]")+"  "+a.id+"  "+(a.name||"")));}
else if(c==="set"){let x=rd(),f=x.find(a=>a.id===id);if(!f)return console.log("  ✗ لا يوجد "+id);
  f.snippet=rest.join(" ");f.enabled=true;wr(x);console.log("  ✔ "+id+" ← كود بطول "+f.snippet.length+" (مفعّل)");}
else if(c==="on"||c==="off"){let x=rd(),f=x.find(a=>a.id===id);if(!f)return;f.enabled=c==="on";wr(x);console.log("  ✔ "+id+" → "+c);}
else if(c==="auto"){let x=rd(),n=0;x=x.map(a=>{const has=(MAP[a.id]||[]).some(k=>K.get(k));
  const e=has&&a.snippet?a.enabled:false;if(e)n++;return Object.assign({},a,{enabled:e});});wr(x);
  console.log("  ✔ فُعّل "+n+" شريحة جاهزة (لها مفتاح + كود)");}
else if(c==="status"){const x=rd();console.log("  جاهزة للحقن: "+x.filter(a=>a.enabled&&a.snippet).length+" / "+x.length);}
else console.log("الأوامر: list | set <id> '<كود>' | on <id> | off <id> | auto | status");
JS
