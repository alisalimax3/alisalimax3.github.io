#!/usr/bin/env node
"use strict";
const https=require("https"),fs=require("fs"),path=require("path"),crypto=require("crypto");
const ROOT=path.resolve(__dirname,"..",".."),DATA=path.join(ROOT,"money","data");
const UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Safari/537.36";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function rq(url,o={},body){return new Promise((res,rej)=>{
  const u=new URL(url),h=Object.assign({"user-agent":UA,accept:"application/json,text/html,*/*"},o.headers||{});
  const d=body?(typeof body==="string"?body:JSON.stringify(body)):null;
  if(d){h["content-type"]="application/json";h["content-length"]=Buffer.byteLength(d);}
  const q=https.request({host:u.host,path:u.pathname+u.search,method:o.method||"GET",headers:h},r=>{
    if([301,302,303,307,308].includes(r.statusCode)&&r.headers.location&&(o._n||0)<5)
      return rq(new URL(r.headers.location,u).href,Object.assign({},o,{_n:(o._n||0)+1}),body).then(res).catch(rej);
    let b="";r.setEncoding("utf8");r.on("data",c=>b+=c);r.on("end",()=>res({status:r.statusCode,headers:r.headers,body:b}));});
  q.on("error",rej);if(d)q.write(d);q.end();});}
const j=r=>{try{return JSON.parse(r.body);}catch(e){return null;}};
const MBP=path.join(DATA,"mailbox.json");
const mk=(provider,addr,pass,tok)=>({provider,addr,pass,tok,
  async messages(){const m=await rq("https://"+provider+"/messages",{headers:{authorization:"Bearer "+tok}});
    return (j(m)||{})["hydra:member"]||(j(m)||{}).member||[];},
  async full(id){return (await rq("https://"+provider+"/messages/"+id,{headers:{authorization:"Bearer "+tok}})).body;}});
async function fresh(){
  for(const host of ["api.mail.tm","api.mail.gw"]){
    try{
      const d=await rq("https://"+host+"/domains",{headers:{accept:"application/ld+json,application/json"}});
      const list=(j(d)||{})["hydra:member"]||(j(d)||{}).member||[];
      const dom=(list.find(x=>x.isActive!==false&&x.isPrivate!==true)||list[0]||{}).domain;
      if(!dom)continue;
      const addr="cinehub"+crypto.randomBytes(3).toString("hex")+"@"+dom,pass=crypto.randomBytes(9).toString("base64url");
      if((await rq("https://"+host+"/accounts",{method:"POST"},{address:addr,password:pass})).status>=400)continue;
      const t=await rq("https://"+host+"/token",{method:"POST"},{address:addr,password:pass});
      const tok=(j(t)||{}).token; if(!tok)continue;
      save({provider:host,addr,pass,tok}); return mk(host,addr,pass,tok);
    }catch(e){}
  }
  const d=await rq("https://www.1secmail.com/api/v1/?action=getDomainList");
  const doms=j(d)||[]; if(!doms.length)throw new Error("كل مزوّدي البريد فشلوا");
  const login="cinehub"+crypto.randomBytes(3).toString("hex"),dom=doms[0],addr=login+"@"+dom;
  const q=u=>"https://www.1secmail.com/api/v1/?action="+u+"&login="+login+"&domain="+dom;
  const box={provider:"1secmail",addr,pass:"(بلا حساب)",
    async messages(){return j(await rq(q("getMessages")))||[];},
    async full(id){const r=j(await rq(q("readMessage")+"&id="+id))||{};return r.htmlBody||r.body||r.textBody||"";}};
  save({provider:"1secmail",addr,pass:box.pass,tok:""}); return box;
}
const save=s=>{fs.mkdirSync(DATA,{recursive:true});fs.writeFileSync(MBP,JSON.stringify(s,null,1));try{fs.chmodSync(MBP,0o600);}catch(e){}};
async function create(){
  if(fs.existsSync(MBP)){
    try{const s=JSON.parse(fs.readFileSync(MBP,"utf8"));
      if(s.provider==="1secmail"){console.log("  ✔ بريد محفوظ: "+s.addr);return await attach1(s);}
      const t=await rq("https://"+s.provider+"/token",{method:"POST"},{address:s.addr,password:s.pass});
      const tok=(j(t)||{}).token;
      if(tok){console.log("  ✔ بريد محفوظ: "+s.addr);return mk(s.provider,s.addr,s.pass,tok);}
    }catch(e){}
    console.log("  ⚠ البريد المحفوظ تعذّر — أُنشئ جديد");
  }
  const m=await fresh(); console.log("  ✔ بريد حقيقي: "+m.addr+"  ("+m.provider+")"); return m;
}
async function attach1(s){
  const [login,dom]=s.addr.split("@"),q=u=>"https://www.1secmail.com/api/v1/?action="+u+"&login="+login+"&domain="+dom;
  return {provider:"1secmail",addr:s.addr,pass:s.pass,
    async messages(){return j(await rq(q("getMessages")))||[];},
    async full(id){const r=j(await rq(q("readMessage")+"&id="+id))||{};return r.htmlBody||r.body||r.textBody||"";}};
}
async function waitLink(timeoutMs=180000){
  const box=await create(),t0=Date.now(),seen=new Set();
  console.log("  … أنتظر رسالة التأكيد");
  while(Date.now()-t0<timeoutMs){
    let msgs=[];try{msgs=await box.messages();}catch(e){}
    for(const m of msgs){const id=m.id||m.ID;if(seen.has(id))continue;seen.add(id);
      const body=String(await box.full(id)).replace(/&amp;/g,"&");
      const link=(body.match(/https?:\/\/[^\s"'<>]*(?:confirm|verif|activ|activat)[^\s"'<>]*/i)||[])[0];
      if(link){console.log("  ✔ وصل رابط التأكيد");return {box,link};}
      const code=(body.match(/\b(\d{5,8})\b/)||[])[1];
      if(code){console.log("  ✔ وصل رمز: "+code);return {box,link:null,code};}}
    await sleep(6000);}
  return {box,link:null};
}
module.exports={create,waitLink,rq,j,MBP};
if(require.main===module)create().then(m=>console.log("  الصندوق جاهز: "+m.addr));
