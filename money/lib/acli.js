#!/usr/bin/env node
"use strict";
const {spawnSync}=require("child_process"),path=require("path");
const H=path.resolve(__dirname,".."),A=path.join(H,"APEX.sh");
const M=[["1","تشغيل كامل (install + start)","all"],["2","تشغيل الوكيل","start"],["3","إيقاف","stop"],
 ["4","الحالة والصحة","status"],["5","نشر عام على الاستضافات","deploy"],["6","دفع للمحرّكات والأهداف","seo"],
 ["7","توليد صفحات SEO","traffic"],["8","بناء قائمة الأهداف","sites"],["9","حصد الأرباح","harvest"],
 ["10","حوالة أرباح","payout"],["11","ملف البنك + KYC","kyc"],["12","اللوحة","dash"],["13","ختم الخزنة","vault"],
 ["14","سجل التدقيق","audit"],["15","نسخة احتياطية","snapshot"],["16","تحديث ذاتي","update"],["17","تقرير","report"]];
console.log("\n╔══════════════ APEX — القائمة ══════════════╗");
M.forEach(m=>console.log("  "+m[0].padStart(2)+") "+m[1]));
console.log("╚════════════════════════════════════════════╝");
if(process.argv[2]){spawnSync("bash",[A,process.argv[2]],{stdio:"inherit"});process.exit(0);}
const r=require("readline").createInterface({input:process.stdin,output:process.stdout});
r.question("اختر رقمًا: ",a=>{const m=M.find(x=>x[0]===String(a).trim());r.close();
  if(m)spawnSync("bash",[A,m[2]],{stdio:"inherit"});else console.log("○ اختيار غير معروف");});
