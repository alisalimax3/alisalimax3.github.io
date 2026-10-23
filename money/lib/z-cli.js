#!/usr/bin/env node
"use strict";
const {spawnSync}=require("child_process"),path=require("path");
const A=path.join(path.resolve(__dirname,".."),"ZERO.sh");
const M=[["1","تشغيل الوكيل","start"],["2","إيقاف","stop"],["3","إيقاف مؤقت","pause"],["4","متابعة","resume"],
 ["5","الحالة","status"],["6","دفعة الآن (12 هدفًا)","batch 12"],["7","بناء/تحديث السجل","registry"],
 ["8","تحقق فعلي شامل","verify --all"],["9","مهامك (جلسة واحدة)","human --sheet"],["10","تقرير المالك","report"],
 ["11","فهرس ووثائق","docs"],["12","مفاتيح (مقنّعة)","keys"],["13","ختم الخزنة","seal"],["14","جدولة","schedule"],["15","سجل","logs"]];
console.log("\n╔══════════ ZERO — وكيل بصلاحياتك ══════════╗");
M.forEach(m=>console.log("  "+m[0].padStart(2)+") "+m[1]));
console.log("╚═══════════════════════════════════════════╝");
if(process.argv[2]){spawnSync("bash",[A].concat(process.argv.slice(2)),{stdio:"inherit"});process.exit(0);}
require("readline").createInterface({input:process.stdin,output:process.stdout}).question("اختر: ",a=>{
  const m=M.find(x=>x[0]===String(a).trim());if(m)spawnSync("bash",[A].concat(m[2].split(" ")),{stdio:"inherit"});
  else console.log("○ غير معروف");process.exit(0);});
