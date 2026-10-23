#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const K=require("./akeys.js");
function score(){
  const sig=[],led=rd(path.join(D,"apex-ledger.json"),{total:0}),h=rd(path.join(D,"harvest.json"),{}),
    keys=K.all(),ads=rd(path.join(D,"ads.json"),[]),pr=rd(path.join(D,"privileges.json"),{}),
    wt=rd(path.join(D,"watch.json"),{}),dep=rd(path.join(D,"deploy.json"),{}),pub=K.get("PUBLIC_URL");
  let p=0;const add=(n,w,ok,note)=>{sig.push({n,w,ok:!!ok,note:note||""});if(ok)p+=w;};
  add("رابط عام حيّ",15,pub);add("استضافة منشورة",10,dep.ok);add("مفاتيح ≥5",10,Object.keys(keys).length>=5);
  add("مصادر حيّة ≥3",10,(h.live||0)>=3);add("إعلانات محقونة ≥1",10,ads.filter(a=>a.enabled&&a.snippet).length>=1);
  add("أرباح > 0",10,Number(led.total||0)>0);add("صلاحيات كاملة",10,pr.wakelock&&pr.boot);
  add("مراقبة تعمل",10,Object.keys(wt).length>0);add("عنوان تحويل",5,!!K.get("PAYOUT_ADDRESS"));
  add("هوية/بريد",5,!!K.get("CONTACT_EMAIL"));add("خزنة مختومة",5,fs.existsSync(path.join(D,"vault.enc")));
  const gates={"رابط عام":!!pub,"منشور":!!dep.ok,"مصادر≥3":(h.live||0)>=3,
    "إعلان":ads.filter(a=>a.enabled&&a.snippet).length>=1,"أرباح":Number(led.total||0)>0,
    "مراقبة":Object.keys(wt).length>0,"صلاحيات":!!pr.wakelock,"تحويل":!!K.get("PAYOUT_ADDRESS"),
    "هوية":!!K.get("CONTACT_EMAIL"),"خزنة":fs.existsSync(path.join(D,"vault.enc"))};
  const rep={at:new Date().toISOString(),score:p,signals:sig,gates,ready:Object.values(gates).every(Boolean)};
  fs.writeFileSync(path.join(D,"health.json"),JSON.stringify(rep,null,1));return rep;}
module.exports={score};
if(require.main===module){const r=score();
  console.log("  الصحة: "+r.score+"/100 · البوابات "+Object.values(r.gates).filter(Boolean).length+"/"+Object.keys(r.gates).length+(r.ready?" ✅ جاهز كامل":""));
  r.signals.filter(x=>!x.ok).forEach(x=>console.log("   ○ "+x.n));process.exit(r.ready?0:1);}
