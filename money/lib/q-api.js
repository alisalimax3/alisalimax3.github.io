#!/usr/bin/env node
"use strict";
const U=require("./q-util.js"),QDB=require("./q-db.js");
const RL={},VERSION="1.0.0";
function json(res,code,o,extra){const b=JSON.stringify(o);
  res.setHeader("content-type","application/json; charset=utf-8");
  res.setHeader("x-content-type-options","nosniff");
  res.setHeader("cache-control","no-store");
  Object.entries(extra||{}).forEach(([k,v])=>res.setHeader(k,v));
  res.writeHead(code,{"content-length":Buffer.byteLength(b)}).end(b);}
function body(req,max){return new Promise(r=>{let b="";req.on("data",c=>{b+=c;if(b.length>(max||262144)){req.destroy();r({tooBig:true});}});
  req.on("end",()=>{try{return r({json:b?JSON.parse(b):{},raw:b});}catch(e){return r({bad:true,raw:b});}});req.on("error",()=>r({err:true}));});}
async function handle(req,res,p){
  const ip=(req.socket&&req.socket.remoteAddress)||"x",now=Date.now();
  RL[ip]=(RL[ip]||[]).filter(t=>now-t<60000);
  if(RL[ip].length>180)return json(res,429,{ok:false,error:"rate_limit",limit:180});
  RL[ip].push(now);
  let u;try{u=new URL("http://x"+p);}catch(e){return json(res,400,{ok:false,error:"bad_url"});}
  const path=u.pathname;
  if(req.method==="OPTIONS"){res.setHeader("allow","GET,POST,OPTIONS");return json(res,204,{});}
  const onlyGet=["/api/state","/api/health","/api/findings","/api/fixes","/api/tests","/api/keys","/api/version","/api/ready"];
  if(onlyGet.includes(path)&&req.method!=="GET")return json(res,405,{ok:false,error:"method",allow:"GET"});
  switch(path){
    case "/api/version":return json(res,200,{ok:true,version:VERSION,node:process.version});
    case "/api/health":{const h=QDB.health();return json(res,h.ok?200:503,{ok:h.ok,db:h});}
    case "/api/ready":{const f=U.jr(U.A+"/findings-all.json",{items:[]});
      const high=(f.items||[]).filter(x=>x.sev==="high").length;
      return json(res,high?503:200,{ok:high===0,high,db:QDB.health().ok});}
    case "/api/state":return json(res,200,{ok:true,uptime:process.uptime(),
      inventory:U.jr(U.A+"/inventory.json",{}),db:QDB.health(),counts:{events:QDB.count("events"),tests:QDB.count("tests")}});
    case "/api/findings":return json(res,200,{ok:true,items:(U.jr(U.A+"/findings-all.json",{items:[]}).items||[]).slice(0,500)});
    case "/api/fixes":return json(res,200,{ok:true,items:(U.jr(U.A+"/fixes.json",{items:[]}).items||[])});
    case "/api/tests":return json(res,200,{ok:true,items:(U.jr(U.A+"/tests.json",{items:[]}).items||[]).slice(0,500)});
    case "/api/keys":{const out=[];U.read(U.ROOT+"/keys.env").split("\n").forEach(l=>{const i=l.indexOf("=");if(i>0)out.push({k:l.slice(0,i).trim(),set:!!l.slice(i+1).trim()});});
      return json(res,200,{ok:true,keys:out});}
    case "/api/event":{if(req.method!=="POST")return json(res,405,{ok:false,error:"method",allow:"POST"});
      const b=await body(req);if(b.tooBig)return json(res,413,{ok:false,error:"too_large"});
      if(b.bad)return json(res,400,{ok:false,error:"bad_json"});
      QDB.insert("events",{kind:(b.json||{}).kind||"generic",payload:JSON.stringify((b.json||{}).payload||{})});
      return json(res,201,{ok:true,stored:true,count:QDB.count("events")});}
    default:return json(res,404,{ok:false,error:"not_found",path});}
}
module.exports={handle};
