#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const K=require("./keysfile.js"),{rq,j}=require("./mailbox.js"),codes=require("./codes.js");
const R=JSON.parse(fs.readFileSync(path.join(DATA,"stats-recipes.json"),"utf8"));
const LED=path.join(DATA,"ledger.json");
const iso=d=>new Date(d).toISOString().slice(0,10);
const deep=(o,f)=>{try{return f.split(".").reduce((a,k)=>a&&a[k],o);}catch(e){return null;}};
(async()=>{
  const to=iso(Date.now()),from=iso(Date.now()-864e5*7);
  const led=(()=>{try{return JSON.parse(fs.readFileSync(LED,"utf8"));}catch(e){return{total:0,rows:[]};}})();
  let got=0;
  for(const[id,r]of Object.entries(R)){
    const key=K.get(r.keyEnv); if(!key){console.log("  ○ "+id+" — لا مفتاح");continue;}
    try{
      let url=r.login.replace("{FROM}",from).replace("{TO}",to).replace("{KEY}",key);
      const h=Object.fromEntries(Object.entries(r.headers||{}).map(([k,v])=>[k,v.replace("{KEY}",key)]));
      let out=0;
      if(r.kind==="exoclick"){
        const lg=await rq(r.login,{method:"POST",headers:{"content-type":"application/json"}},
          JSON.stringify({api_token:key}));
        const tk=(j(lg)||{}).token||(j(lg)||{}).token_type==="Bearer"&&(j(lg)||{}).token;
        if(!tk){console.log("  ⚠ "+id+" — فشل الدخول");continue;}
        const st=await rq(r.stats,{method:"POST",headers:{"content-type":"application/json",authorization:"Bearer "+tk}},
          JSON.stringify({group_by:["date"],date_from:from,date_to:to}));
        const rows=(j(st)||{}).result||[];
        out=rows.reduce((a,x)=>a+Number(x.revenue||0),0);
      }else{
        const res=await rq(url,{headers:h});
        const data=j(res)||{};
        if(r.sum)out=Number(deep(data,r.sum))||0;
        if(!out){const m=(res.body.match(/"revenue"\s*:\s*"?([\d.]+)/)||[])[1];if(m)out=Number(m);}
      }
      led.rows.push({id,from,to,revenue:out,at:new Date().toISOString()});
      led.total=Number(led.total||0)+out; got++;
      console.log("  ✔ "+id+" → $"+out.toFixed(2));
    }catch(e){console.log("  ✗ "+id+" — "+(e.message||e));}
  }
  fs.writeFileSync(LED,JSON.stringify(led,null,1));
  console.log("  ── إجمالي الحصد: $"+Number(led.total).toFixed(2)+" من "+got+" شبكة");
  if(got)codes.save("حصد",{شبكات:got,"الإجمالي":led.total,من:from,إلى:to});
})();
