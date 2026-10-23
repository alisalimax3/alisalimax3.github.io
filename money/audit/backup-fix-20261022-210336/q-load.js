#!/usr/bin/env node
"use strict";
const http=require("http"),U=require("./q-util.js");
const PORT=Number(process.env.Q_TEST_PORT||8803);
const N=Number(process.env.Q_LOAD_N||200),C=Number(process.env.Q_LOAD_C||10);
function one(p){return new Promise(r=>{const t0=Date.now();
  const q=http.request({host:"127.0.0.1",port:PORT,path:p},x=>{x.resume();x.on("end",()=>r({ok:x.statusCode<400,ms:Date.now()-t0,status:x.statusCode}));});
  q.on("error",()=>r({ok:false,ms:Date.now()-t0,status:0}));q.setTimeout(20000,()=>q.destroy(new Error("timeout")));q.end();});}
(async()=>{const srv=require("./q-static.js").server;await new Promise(r=>srv.listen(PORT,"127.0.0.1",r));
  const paths=["/","/health","/api/health","/metrics"];
  const res=[];const t0=Date.now();let i=0;
  await Promise.all(Array.from({length:C},async()=>{while(i<N){const k=i++;res.push(await one(paths[k%paths.length]));}}));
  const total=Date.now()-t0;await new Promise(r=>srv.close(r));
  const ms=res.map(x=>x.ms).sort((a,b)=>a-b),p50=ms[Math.floor(ms.length*0.5)]||0,p95=ms[Math.floor(ms.length*0.95)]||0;
  const errs=res.filter(x=>!x.ok).length,rps=Math.round(res.length/(total/1000));
  const r={at:new Date().toISOString(),requests:res.length,concurrency:C,errors:errs,p50,p95,max:ms[ms.length-1]||0,rps,seconds:Math.round(total/1000)};
  U.jw(path.join(U.A,"load.json"),r);
  console.log("  ✔ حمل: "+r.requests+" طلب · "+r.rps+" طلب/ث · p50 "+p50+"ms · p95 "+p95+"ms · أخطاء "+errs);
  U.ev({phase:"load",ok:errs===0&&p95<2500,detail:r});})();
