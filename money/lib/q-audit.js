#!/usr/bin/env node
"use strict";
const {execFileSync}=require("child_process"),path=require("path"),U=require("./q-util.js");
const APPLY=process.env.APPLY==="1";
const run=(f,args)=>{try{return execFileSync("node",[path.join(U.H,"lib",f)].concat(args||[]),{cwd:U.ROOT,stdio:"pipe",timeout:900000,env:Object.assign({},process.env,{APPLY:APPLY?"1":"0"})}).toString();}
  catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
const sh=(f,args)=>{try{return execFileSync("bash",[path.join(U.H,f)].concat(args||[]),{cwd:U.ROOT,stdio:"pipe",timeout:900000,env:Object.assign({},process.env,{APPLY:APPLY?"1":"0"})}).toString();}
  catch(e){return String(e.stdout||"")+String(e.stderr||"");}};
const steps=[
 ["1/9 جرد",()=>run("q-scan.js")],
 ["2/9 تشخيص ساكن",()=>run("q-lint.js")],
 ["3/9 أمان",()=>run("q-sec.js")],
 ["4/9 أداء",()=>run("q-perf.js")],
 ["5/9 قاعدة بيانات",()=>run("q-db.js","init")],
 ["6/9 ربط الخدمات",()=>run("q-wire.js")],
 ["7/9 اختبار وظيفي",()=>run("q-test.js")],
 ["8/9 اختبار أمان حيّ",()=>run("q-sectest.js")],
 ["9/9 حمل",()=>run("q-load.js")]
];
(async()=>{U.log("AUDITOR بدأ apply="+APPLY);
  console.log("╔══════ AUDITOR — فحص وإصلاح شامل"+(APPLY?" (مع التطبيق)":"")+" ══════╗");
  for(const [n,fn] of steps){console.log("\n▶ "+n);const out=fn();console.log(out.trimEnd());}
  if(APPLY){console.log("\n▶ إصلاح آمن");console.log(run("q-fix.js").trimEnd());
    console.log("\n▶ إعادة اختبار بعد الإصلاح");console.log(run("q-lint.js").trimEnd());console.log(run("q-sec.js").trimEnd());
    console.log(run("q-test.js").trimEnd());}
  console.log("\n▶ التقرير");console.log(run("q-report.js").trimEnd());
  U.log("انتهى");
  console.log("\n  الملفات: money/audit/ · التقرير: docs/AUDIT-REPORT.md");})();
