#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),DB=require("./z-db.js"),K=require("./z-keys.js");
const DIR=path.join(ROOT,"docs"),SV=path.join(DIR,"services");
const W=o=>{fs.mkdirSync(DIR,{recursive:true});return o;};
function service(t){fs.mkdirSync(SV,{recursive:true});
  const T=DB.rd(DB.F.tests,{})[t.id],ev=fs.existsSync(DB.F.evidence)?
    fs.readFileSync(DB.F.evidence,"utf8").split("\n").filter(l=>l.includes('"id":"'+t.id+'"')).slice(-12):[];
  const L=["# "+t.id,"","- التصنيف: "+(t.cat||"-"),"- الحالة: **"+t.stage+"**"+(T&&T.ok?" (مُتحقّق فعليًا ✔)":""),
   "- الموقع: "+(t.home||"-"),"- رابط التسجيل: "+(t.signup||"-"),"- الوصفة: "+(t.recipe||"عامة"),
   "- عدد الأدلة: "+(t.evidence||0),"- آخر تحديث: "+(t.updated||"-"),"- المحاولات: "+(t.attempts||0),
   T?"- آخر اختبار: "+(T.ok?"نجح":"فشل")+" · "+(T.note||"")+" · "+T.at:"- آخر اختبار: —",
   "","## المفاتيح (مقنّعة)",""];
  const rec=require("./z-recipes.js").byId(t.recipe);
  ((rec&&rec.env)||[]).forEach(e=>L.push("- `"+e+"` = "+(K.get(e)?K.mask(K.get(e)):"—")));
  L.push("","## سجل الأدلة","","```");
  ev.forEach(l=>{try{const j=JSON.parse(l);L.push(j.at+"  "+j.kind+"  "+JSON.stringify(j.data).slice(0,160));}catch(e){}});
  L.push("```","");
  fs.writeFileSync(path.join(SV,t.id+".md"),L.join("\n"));return path.join(SV,t.id+".md");}
function index(){const s=DB.stats(),T=DB.rd(DB.F.tests,{});
  const rows=Object.values(DB.targets()).filter(t=>t.stage==="live").slice(0,500)
    .map(t=>"| "+t.id+" | "+(t.cat||"-")+" | "+((T[t.id]||{}).ok?"✔":"—")+" | "+((T[t.id]||{}).note||"")+" |");
  const md=["# فهرس ZERO","","- الإجمالي: "+s.total+" هدفًا","- مُتحقّق فعليًا: "+s.passed,"- أدلة: "+s.evidence,
   "- مهام تنتظرك: "+s.humanPending,"","## التوزيع","","```",JSON.stringify(s.by,null,1),"```","",
   "## الخدمات المُتحقَّق منها","","| الهدف | التصنيف | تحقق | ملاحظة |","|---|---|---|---|"].concat(rows).join("\n");
  fs.writeFileSync(W(path.join(DIR,"INDEX.md")),md);return path.join(DIR,"INDEX.md");}
function report(){const s=DB.stats(),T=DB.rd(DB.F.tests,{}),D=DB.rd(path.join(H,"data","deploy.json"),{}),l=DB.rd(path.join(H,"data","apex-ledger.json"),{total:0});
  const live=Object.values(DB.targets()).filter(t=>t.stage==="live");
  const md=["# تقرير المالك — ZERO","","> كل رقم هنا مبني على دليل مُخزَّن في db/evidence.jsonl و db/tests.json","",
   "- الأهداف الكلية: **"+s.total+"**","- حسابات/تكاملات مُتحقَّقة فعليًا: **"+s.passed+"**",
   "- قيد التنفيذ: **"+((s.by.reachable||0)+(s.by.account||0)+(s.by.email||0)+(s.by.key||0)+(s.by.linked||0))+"**",
   "- فشل (سيُعاد): **"+(s.by.failed||0)+"**","- ينتظرك: **"+s.humanPending+"**",
   "- مفاتيح محفوظة: **"+K.verify().total+"** (سليمة: "+(K.verify().bad.length===0?"نعم":"لا")+")",
   "- الرابط العام: "+(D.url||"—"),"- الأرباح المسجّلة: $"+(Number(l.total||0)).toFixed(2),"",
   "## التوزيع بالحالة","","```",JSON.stringify(s.by,null,2),"```","",
   "## عيّنة من المُتحقَّق منه (أول 40)","","| الهدف | التصنيف | دليل |","|---|---|---|"]
   .concat(live.slice(0,40).map(t=>"| "+t.id+" | "+(t.cat||"-")+" | "+(((T[t.id]||{}).note)||"")+" |")).join("\n");
  fs.writeFileSync(W(path.join(DIR,"OWNER-REPORT.md")),md);return path.join(DIR,"OWNER-REPORT.md");}
function handover(){const K2=K.all(),s=DB.stats();
  const md=["# تسليم — أنت المالك","","## ما تم","- "+s.total+" هدفًا مسجّلًا في السجل","- "+s.passed+" تكاملًا مُتحقّقًا فعليًا",
   "- "+K2.PUBLIC_URL||"—","","## الأسرار","- كل المفاتيح في `keys.env` (صلاحيات 600)","- نسخة مشفّرة: `money/data/vault.enc`",
   "- سجل المصادر والأوقات: `money/data/secrets.json`","","## حسابك على كل خدمة","- البريد وكلمة المرور لكل خدمة: `money/db/creds.json`",
   "- بريد التحقق المستخدم: `money/db/mail.json`","","## تحكمك الكامل","","```bash","bash money/ZERO.sh owner lock <id>      # لا تلمسه بعد الآن",
   "bash money/ZERO.sh owner revoke <id>    # احذف مفاتيحه","bash money/ZERO.sh owner rollback <id> reachable","bash money/ZERO.sh pause                # أوقف الوكيل",
   "bash money/ZERO.sh open                 # استعد الأسرار من الخزنة","```","","## سحب الأرباح","- "+((K2.PAYOUT_ADDRESS)||"أضف PAYOUT_ADDRESS")+" على "+((K2.PAYOUT_CHAIN)||"base")].join("\n");
  fs.writeFileSync(W(path.join(DIR,"HANDOVER.md")),md);return path.join(DIR,"HANDOVER.md");}
function evidence(){const f=DB.F.evidence;const out=fs.existsSync(f)?fs.readFileSync(f,"utf8").split("\n").filter(Boolean).map(l=>{try{return JSON.parse(l);}catch(e){return null;}}).filter(Boolean):[];
  fs.writeFileSync(W(path.join(DIR,"EVIDENCE.json")),JSON.stringify({at:new Date().toISOString(),count:out.length,items:out.slice(-3000)},null,1));
  return path.join(DIR,"EVIDENCE.json");}
module.exports={service,index,report,handover,evidence};
if(require.main===module){index();report();handover();evidence();console.log("  ✔ وثائق: docs/INDEX.md · OWNER-REPORT.md · HANDOVER.md · EVIDENCE.json");}
