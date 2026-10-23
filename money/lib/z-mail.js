#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto"),tls=require("tls");
const H=path.resolve(__dirname,".."),DB=path.join(H,"db"),F=path.join(DB,"mail.json");
const K=require("./z-keys.js"),HTTP=require("./z-http.js"),ID=require("./z-identity.js");
const sleep=HTTP.sleep;
const rd=()=>{try{return JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){return{};}};
const wr=o=>{fs.mkdirSync(DB,{recursive:true});fs.writeFileSync(F,JSON.stringify(o,null,1));};
async function fromTmp(host){const d=await HTTP.get("https://"+host+"/domains",{headers:{accept:"application/ld+json"},timeout:20000});
  let j={};try{j=JSON.parse(d.body);}catch(e){}
  const list=j["hydra:member"]||j.member||[];const dom=(list.find(x=>x.isActive!==false)||{}).domain||(list[0]||{}).domain;
  if(!dom)throw new Error("لا نطاق على "+host);
  const addr="cine"+crypto.randomBytes(3).toString("hex")+"@"+dom,pass=crypto.randomBytes(9).toString("base64url");
  const a=await HTTP.post("https://"+host+"/accounts",{json:{address:addr,password:pass},timeout:20000});
  if(a.status>=400)throw new Error("فشل إنشاء بريد "+a.status);
  const t=await HTTP.post("https://"+host+"/token",{json:{address:addr,password:pass},timeout:20000});
  let tok="";try{tok=JSON.parse(t.body).token;}catch(e){}
  if(!tok)throw new Error("فشل توكن البريد");
  return{provider:host,addr,pass,tok,type:"tmp"};}
async function fromOneSec(){const d=await HTTP.get("https://www.1secmail.com/api/v1/?action=getDomainList",{timeout:20000});
  let doms=[];try{doms=JSON.parse(d.body);}catch(e){}
  if(!doms.length)throw new Error("1secmail لا نطاق");
  const login="cine"+crypto.randomBytes(3).toString("hex");
  return{provider:"1secmail",addr:login+"@"+doms[0],pass:"",login,dom:doms[0],type:"onesec"};}
async function create(){for(const f of [()=>fromTmp("api.mail.tm"),()=>fromTmp("api.mail.gw"),fromOneSec]){try{return await f();}catch(e){}}throw new Error("كل مزوّدي البريد فشلوا");}
async function ensure(id){const m=rd();if(m[id])return m[id];
  const owner=ID.get();
  if(K.get("IMAP_HOST")&&owner.email){const b={provider:"imap",type:"imap",addr:String(owner.email).replace("@","+"+id+"@")};m[id]=b;wr(m);return b;}
  const b=await create();m[id]=b;wr(m);return b;}
async function messages(box){if(box.type==="onesec"){const u="https://www.1secmail.com/api/v1/?action=getMessages&login="+box.login+"&domain="+box.dom;
    const r=await HTTP.get(u,{timeout:20000});try{return JSON.parse(r.body)||[];}catch(e){return[];}}
  if(box.type==="imap")return imapRaw(box.addr);
  const r=await HTTP.get("https://"+box.provider+"/messages",{headers:{authorization:"Bearer "+box.tok},timeout:20000});
  try{return JSON.parse(r.body)["hydra:member"]||[];}catch(e){return[];}}
async function full(box,msg){if(box.type==="onesec"){const u="https://www.1secmail.com/api/v1/?action=readMessage&login="+box.login+"&domain="+box.dom+"&id="+(msg.id||msg.ID);
    const r=await HTTP.get(u,{timeout:20000});return r.body;}
  if(box.type==="imap")return msg.raw||"";
  const r=await HTTP.get("https://"+box.provider+"/messages/"+(msg.id||msg.ID),{headers:{authorization:"Bearer "+box.tok},timeout:20000});return r.body;}
function imapRaw(addr){return new Promise(res=>{const host=K.get("IMAP_HOST"),user=K.get("IMAP_USER"),pass=K.get("IMAP_PASS");
  const c=tls.connect({host,port:Number(K.get("IMAP_PORT")||993)},()=>{});let buf="",st=0,out=[];
  const done=v=>{try{c.end();}catch(e){}res(v);};
  const send=s=>c.write(s+"\r\n");
  c.on("data",d=>{buf+=d.toString("utf8");
    if(st===0&&/\* OK/.test(buf)){send("a1 LOGIN "+user+" "+pass);st=1;buf="";return;}
    if(st===1&&/a1 (OK|NO)/.test(buf)){send("a2 SELECT INBOX");st=2;buf="";return;}
    if(st===2&&/a2 (OK|NO)/.test(buf)){send("a3 UID SEARCH ALL");st=3;buf="";return;}
    if(st===3){const m=buf.match(/\* SEARCH ([\d ]+)/);if(m&&/a3 OK/.test(buf)){const ids=m[1].trim().split(/\s+/).filter(Boolean).slice(-4);
      if(!ids.length)return done([]);send("a4 UID FETCH "+ids.join(",")+" (BODY.PEEK[])");st=4;buf="";}return;}
    if(st===4&&/a4 (OK|NO)/.test(buf)){out.push({id:1,raw:buf});return done(out);}});
  c.on("error",()=>done([]));setTimeout(()=>done(out),25000);});}
async function wait(id,rx,timeoutMs){const box=await ensure(id);const t0=Date.now();const seen=new Set();
  const re=new RegExp(rx||"https?://[^\\s\"'<>]*(confirm|verify|activat|valid|token|signup)[^\\s\"'<>]*","i");
  while(Date.now()-t0<(timeoutMs||180000)){
    let msgs=[];try{msgs=await messages(box);}catch(e){}
    for(const m of msgs){const k=String(m.id||m.ID);if(seen.has(k))continue;seen.add(k);
      let body="";try{body=await full(box,m);}catch(e){}
      const link=(String(body).replace(/&amp;/g,"&").match(re)||[])[0];
      if(link)return{box,link,code:(String(body).match(/\b(\d{4,8})\b/)||[])[1]||""};}
    await sleep(6000);}
  return{box,link:"",code:""};}
module.exports={create,ensure,wait,messages,full,rd};
