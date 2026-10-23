#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),codes=require("./acodes.js");
const KP=(()=>{try{return JSON.parse(fs.readFileSync(path.join(D,"keypages.json"),"utf8"));}catch(e){return{};}})();
let I={brand:"CineHub",handle:"cinehub"};
try{I=Object.assign(I,JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8")));}catch(e){}
function plan(){const ids=Object.keys(KP);const out=ids.map(id=>({id,signup:KP[id].signup,keysUrl:KP[id].keysUrl,env:KP[id].env,
  missing:(KP[id].env||[]).filter(e=>!K.get(e))}));
  fs.writeFileSync(path.join(D,"approval-plan.json"),JSON.stringify({at:new Date().toISOString(),plan:out},null,1));
  return out;}
if(require.main===module){const p=plan();const miss=p.filter(x=>x.missing.length);
  console.log("  ✔ خطة الموافقة: "+p.length+" شبكة · ناقص مفاتيح "+miss.length);
  miss.slice(0,6).forEach(m=>console.log("   ○ "+m.id+" → "+m.signup+"  ("+m.missing.join(", ")+")"));
  codes.save("خطة الموافقة",{شبكات:p.length,ناقص:miss.length});}
