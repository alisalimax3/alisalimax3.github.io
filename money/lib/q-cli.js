#!/usr/bin/env node
"use strict";
const {spawnSync}=require("child_process"),path=require("path");
const A=path.join(path.resolve(__dirname,".."),"AUDIT.sh");
const M=[["1","فحص كامل (بلا تعديل)","all"],["2","فحص + إصلاح آمن","all --apply"],["3","تشخيص ساكن","lint"],
 ["4","أمان","sec"],["5","أداء","perf"],["6","قاعدة بيانات","db"],["7","ربط الخدمات (+تطبيق)","wire --apply"],
 ["8","اختبار وظيفي","test"],["9","اختبار أمان حيّ","sectest"],["10","اختبار حمل","load"],
 ["11","إصلاح آمن","fix --apply"],["12","تقرير","report"],["13","تشغيل API","api-start"],["14","الحالة","status"]];
console.log("\n╔══════════ AUDITOR ══════════╗");
M.forEach(m=>console.log("  "+m[0].padStart(2)+") "+m[1]));
console.log("╚═════════════════════════════╝");
if(process.argv[2]){spawnSync("bash",[A].concat(process.argv.slice(2)),{stdio:"inherit"});process.exit(0);}
require("readline").createInterface({input:process.stdin,output:process.stdout}).question("اختر: ",a=>{
  const m=M.find(x=>x[0]===String(a).trim());if(m)spawnSync("bash",[A].concat(m[2].split(" ")),{stdio:"inherit"});else console.log("○");process.exit(0);});
