#!/usr/bin/env node
"use strict";
const crypto=require("crypto");
const HTTP=require("./z-http.js"),K=require("./z-keys.js"),DB=require("./z-db.js"),REC=require("./z-recipes.js");
const iso=d=>new Date(Date.now()-d*864e5).toISOString().slice(0,10);
const HASH=b=>crypto.createHash("sha256").update(String(b)).digest("hex").slice(0,12);
async function probe(rec,t){
  const v=Object.assign({kind:"http"},rec.verify||{});
  const key=(v.keyEnv&&K.get(v.keyEnv))||(rec.env||[]).map(e=>K.get(e)).find(Boolean)||"";
  const t0=Date.now();
  if(v.kind==="none")return{ok:true,kind:"none",ms:0,note:"لا يوجد ما يُتحقق آليًا",at:new Date().toISOString()};
  const url=HTTP.tpl(v.url||rec.home,{KEY:key,FROM:iso(7),TO:iso(0)});
  const headers={};Object.entries(v.headers||{}).forEach(([k,x])=>headers[k]=HTTP.tpl(x,{KEY:key}));
  if(v.kind==="api"&&!key)return{ok:false,kind:"api",ms:0,note:"لا مفتاح بعد",at:new Date().toISOString()};
  const r=v.kind==="api"?await HTTP.post(url,{headers,json:v.body||undefined,timeout:25000})
                        :await HTTP.get(url,{headers,timeout:25000});
  const ok=r.status>0&&r.status<400&&(!v.regex||new RegExp(v.regex,"i").test(r.body));
  return{ok,kind:v.kind,status:r.status,ms:Date.now()-t0,url,hash:HASH(r.body),
    note:(ok?"تحقق فعلي":"فشل التحقق")+" · HTTP "+r.status,at:new Date().toISOString()};
}
async function verifyTarget(id){const t=DB.target(id);if(!t)return null;
  const rec=REC.byId(t.recipe)||REC.generic(t);
  const res=await probe(rec,t);
  DB.test(id,res);DB.ev(id,"verify",{ok:res.ok,status:res.status||0,note:res.note});
  if(res.ok&&t.stage!=="live")DB.stage(id,"live","تحقق ناجح");
  if(!res.ok&&t.stage==="live"){DB.stage(id,"failed","سقط التحقق: "+res.note);DB.fail(id,res.note);}
  return res;}
async function verifyAll(limit){const list=Object.values(DB.targets()).filter(x=>x.stage==="live").slice(0,limit||400);
  let ok=0,fail=0;
  for(const t of list){const r=await verifyTarget(t.id);r&&r.ok?ok++:fail++;await HTTP.sleep(250);}
  DB.jrn("verify-all",{ok,fail,checked:list.length});
  console.log("  ✔ تحقق فعلي: "+ok+" سليم · "+fail+" سقط (من "+list.length+")");return{ok,fail,checked:list.length};}
module.exports={probe,verifyTarget,verifyAll};
if(require.main===module){const a=process.argv[2];
  if(a==="--all")verifyAll(Number(process.argv[3]||400));
  else if(a)verifyTarget(a).then(r=>console.log("  "+(r.ok?"✔":"✗")+" "+a+" — "+r.note));}
