#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const DB=require("./z-db.js"),K=require("./z-keys.js");
const WHY={captcha:"تحقق بشري (كابتشا)",identity:"بيانات هوية / تصادق",kyc:"توثيق KYC",payment:"دفع أو بطاقة",
 phone:"تحقق برقم هاتف",dns:"سجل DNS",manual:"إجراء يدوي",key:"مفتاح يدوي",tos:"قبول شروط"};
const pending=()=>Object.values(DB.human()).filter(x=>!x.resolved);
function sheet(){const p=pending();const g={};p.forEach(x=>(g[x.why]=g[x.why]||[]).push(x));
  const L=["# جلسة تدخّل واحدة — ZERO","","عدد المهام: "+p.length,"","هذه كل ما يحتاجك. أنجزها بالترتيب ثم: bash money/ZERO.sh human --import money/data/human-input.json",""];
  Object.entries(g).forEach(([w,items])=>{L.push("## "+(WHY[w]||w)+" ("+items.length+")","");
    items.forEach((x,i)=>{L.push("### "+(i+1)+") "+x.id);if(x.url)L.push("- الرابط: "+x.url);
      (x.steps||[]).forEach(s=>L.push("- "+s));
      if(x.field)L.push("- الحقل المطلوب: `"+x.field+"`");
      L.push("- لإتمامه: `bash money/ZERO.sh human --resolve "+x.id+" "+x.field+"=<القيمة>`","");});});
  return L.join("\n");}
function write(){const f=path.join(ROOT,"docs","HUMAN.md");fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,sheet());
  fs.writeFileSync(path.join(D,"human-sheet.txt"),sheet());return f;}
function next(){return pending()[0]||null;}
function resolve(id,val,field){const h=DB.human();const it=h[id];if(!it)return null;
  if(field&&val)K.set({[field]:val},"human:"+id);
  DB.humanResolve(id,val||true);
  DB.stage(id,it.resume||"reachable","حُلّ يدويًا: "+it.why);
  DB.ev(id,"human-resolved",{why:it.why,field:field||"",value:val?K.mask(val):""});
  return it;}
function paste(){return new Promise(r=>execFile("termux-clipboard-get",[],(e,so)=>r(String(so||"").trim())));}
function importFile(f){const txt=fs.readFileSync(f,"utf8");let n=0;
  txt.split("\n").forEach(l=>{l=l.trim();if(!l||l.startsWith("#"))return;
    const m=l.match(/^([\w.\-]+)\s*[:=]\s*(.+)$/);if(!m)return;
    const id=m[1].replace(/^svc-/,""),val=m[2].trim();
    const h=DB.human();const key=Object.keys(h).find(k=>k===m[1]||k===id||k.endsWith(m[1]));
    if(key){const it=h[key];resolve(key,val,it.field||"");n++;}});
  return n;}
module.exports={pending,sheet,write,next,resolve,paste,importFile,WHY};
if(require.main===module){const a=process.argv[2]||"sheet";
  if(a==="count")console.log(pending().length);
  else if(a==="sheet"){const f=write();console.log(sheet());console.log("\n  ✔ كُتب: docs/HUMAN.md");}
  else if(a==="next"){const x=next();if(!x)console.log("  ✔ لا مهام معلّقة");else{console.log("  المهمة: "+x.id+" — "+(WHY[x.why]||x.why));
    if(x.url)console.log("  الرابط: "+x.url);(x.steps||[]).forEach(s=>console.log("  - "+s));if(x.field)console.log("  الحقل: "+x.field);}}
  else if(a==="import"){const n=importFile(process.argv[3]);console.log("  ✔ استُوردت "+n+" قيمة");}}
