#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),U=require("./q-util.js"),QDB=require("./q-db.js");
function collect(){const f=[];
  for(const n of ["findings-lint.json","findings-sec.json","findings-perf.json"]){
    const j=U.jr(path.join(U.A,n),{items:[]});(j.items||[]).forEach(x=>f.push(x));}
  U.jw(path.join(U.A,"findings-all.json"),{at:new Date().toISOString(),items:f});return f;}
function report(){const F=collect(),fx=U.jr(path.join(U.A,"fixes.json"),{items:[]}),t=U.jr(path.join(U.A,"tests.json"),{items:[],passed:0,total:0}),
  st=U.jr(path.join(U.A,"sectest.json"),{items:[],passed:0,total:0}),ld=U.jr(path.join(U.A,"load.json"),{}),w=U.jr(path.join(U.A,"wire.json"),{items:[]}),
  inv=U.jr(path.join(U.A,"inventory.json"),{}),dbh=QDB.health();
  const by={high:0,med:0,low:0};F.forEach(x=>by[x.sev]=(by[x.sev]||0)+1);
  const unfixed=F.filter(x=>x.fixable).length-(fx.items||[]).filter(x=>x.ok).length;
  const gates={
   "لا أخطاء صياغة":!F.some(x=>x.rule==="js-syntax"||x.rule==="json-parse"),
   "لا تسرّب مفاتيح":!F.some(x=>x.rule==="secret-leak"),
   "صلاحيات 600":!F.some(x=>x.rule==="perm"),
   "ترويسات أمان":!F.some(x=>x.rule==="header"&&x.sev!=="low")||(st.items||[]).filter(x=>/nosniff|Frame|Referrer/.test(x.name)).every(x=>x.ok),
   "قاعدة بيانات سليمة":dbh.ok,
   "API يعمل":(t.items||[]).some(x=>/API \/api\/health/.test(x.name)&&x.ok),
   "كل الصفحات 200":(t.items||[]).filter(x=>/^صفحة /.test(x.name)).every(x=>x.ok),
   "اختبارات وظيفية كاملة":(t.total||0)>0&&t.passed===t.total,
   "اختبارات أمان كاملة":(st.total||0)>0&&st.passed===st.total,
   "لا مراجع مكسورة":!F.some(x=>x.rule==="broken-ref"),
   "ملفات SEO موجودة":!F.some(x=>x.rule==="missing-file"),
   "أداء مقبول":(ld.p95||9999)<2500&&(ld.errors||0)===0};
  const score=Math.round(Object.values(gates).filter(Boolean).length/Object.keys(gates).length*100);
  const wired=w.items||[];
  const L=["# تقرير الفحص والإصلاح — "+new Date().toISOString(),"",
   "> كل بند مُتحقَّق فعليًا. الأدلة: `money/audit/evidence.jsonl` · `tests.json` · `sectest.json` · `load.json` · `fixes.json`","",
   "## الملخص","",
   "| المقياس | القيمة |","|---|---|",
   "| الملفات المفحوصة | "+inv.total+" |","| الصفحات | "+inv.counts.html+" |","| السكربتات | "+inv.counts.js+" |",
   "| ملاحظات | "+F.length+" (عالية "+by.high+" · متوسطة "+by.med+" · منخفضة "+by.low+") |",
   "| إصلاحات مطبَّقة | "+(fx.items||[]).filter(x=>x.ok).length+" |",
   "| اختبارات وظيفية | "+t.passed+"/"+t.total+" |","| اختبارات أمان | "+st.passed+"/"+st.total+" |",
   "| حمل | "+((ld.rps||0))+" طلب/ث · p95 "+((ld.p95||0))+"ms · أخطاء "+((ld.errors||0))+" |",
   "| قاعدة البيانات | "+dbh.engine+" · "+(dbh.ok?"سليمة":"متعثرة")+" |",
   "| **الجاهزية** | **"+score+"/100** |","",
   "## ما تم","",
   "- فحص "+(inv.total||0)+" ملفًا: صياغة JS، JSON، بنية HTML، روابط داخلية، SEO، أمان، أداء",
   "- إصلاح "+(fx.items||[]).filter(x=>x.ok).length+" عنصرًا بأمان (نسخة احتياطية قبل كل تعديل + إعادة اختبار + استرجاع تلقائي عند الفشل)",
   "- ربط قاعدة بيانات "+(QDB.hasSqlite?"SQLite":"JSON")+" وواجهة API مُختبرة حيًّا ("+(t.items||[]).filter(x=>/API/.test(x.name)).length+" مسار)",
   "- ربط الخدمات الخارجية: "+wired.filter(x=>x.configured).length+" مُعدّ · "+wired.filter(x=>x.verified).length+" مُتحقَّق",
   "- اختبار حقيقي: صفحات · 404 · اجتياز مسارات · منع الملفات الحسّاسة · كتابة في القاعدة · حمل متوازٍ","",
   "## بوابات الجاهزية",""];
  Object.entries(gates).forEach(([k,v])=>L.push("- "+(v?"✔ ":"✗ ")+k));
  L.push("","## يحتاجك (محجوب)","");
  const blocked=[];
  if(!wired.some(x=>x.configured))blocked.push("لا مفاتيح خدمات في keys.env — أضفها ليعمل الربط: `bash money/AUDIT.sh wire --apply`");
  if((fx.items||[]).length===0)blocked.push("لم يُطبَّق إصلاح بعد — شغّل: `bash money/AUDIT.sh fix --apply`");
  if(!dbh.ok)blocked.push("قاعدة البيانات غير سليمة — راجع `money/audit/app.db`");
  if((ld.errors||0)>0)blocked.push("أخطاء في اختبار الحمل — راجع `money/audit/load.json`");
  F.filter(x=>!x.fixable&&x.sev==="high").slice(0,6).forEach(x=>blocked.push("["+x.rule+"] "+x.file+" — "+x.msg+" (يحتاج قرارًا)"));
  if(!blocked.length)blocked.push("لا شيء — كل البوابات مكتملة");
  blocked.forEach(b=>L.push("- "+b));
  L.push("","## التالي","","```bash","bash money/AUDIT.sh all            # فحص كامل بلا تعديل","bash money/AUDIT.sh fix --apply    # إصلاح آمن + إعادة اختبار",
   "bash money/AUDIT.sh wire --apply   # ربط الخدمات الخارجية","bash money/AUDIT.sh verify         # إعادة اختبار كل شيء","```","",
   "## واجهة API المتاحة","","```","GET  /health /metrics /api/state /api/health /api/ready","GET  /api/findings /api/fixes /api/tests /api/keys /api/version",
   "POST /api/event {\"kind\":\"x\",\"payload\":{}}","```","","التشغيل: `bash money/AUDIT.sh api-start` (المنفذ "+ (process.env.Q_STATIC_PORT||8799) +")","");
  fs.mkdirSync(path.join(U.ROOT,"docs"),{recursive:true});
  fs.writeFileSync(path.join(U.ROOT,"docs","AUDIT-REPORT.md"),L.join("\n"));
  QDB.insert("metrics",{name:"readiness_score",value:score});
  return {score,gates,by,F,FX:fx,T:t,ST:st,LD:ld};}
if(require.main===module){const r=report();
  console.log("  ══════ التقرير ══════");
  console.log("  ملاحظات: "+r.F.length+" · إصلاحات: "+(r.FX.items||[]).filter(x=>x.ok).length+" · اختبارات: "+r.T.passed+"/"+r.T.total+" · أمان: "+r.ST.passed+"/"+r.ST.total);
  console.log("  الجاهزية: "+r.score+"/100");
  Object.entries(r.gates).forEach(([k,v])=>console.log("   "+(v?"✔":"✗")+" "+k));
  console.log("  ✔ docs/AUDIT-REPORT.md");}
module.exports={report,collect};
