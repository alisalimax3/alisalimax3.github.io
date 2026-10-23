const fs=require('fs'),path=require('path');const AX=process.argv[2];
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
const S=g('registry/summary.json'),I=g('state/integrations.json'),C=g('state/chain.json'),
 E=g('state/earnings.json'),L=g('ledger/rules.json'),MB=g('state/mailbox.json');
const L1=[],L2=[],L3=[],L4=[];
L1.push('منصات في السجل: '+(S.platforms_total||0));
L1.push('منصات استجابت فعليًا (DNS+HTTP): '+(S.platforms_reachable||0));
L1.push('نقاط ربط تم التحقق منها: '+(S.connection_points_verified||0)+' / '+(S.connection_points_probed||0));
L1.push('واجهات API حية بلا مفاتيح: '+(I.working||0)+'/'+(I.total||0));
L1.push('صندوق بريد حقيقي: '+(MB.address||'—'));
L2.push('سلاسل مفحوصة: '+((C.chains||[]).length)+' | محفظة: '+(C.wallet||'غير مضبوطة'));
L2.push('إجمالي رصيد على السلسلة (USD): '+(E.verified_earnings&&E.verified_earnings.onchain_total_usd||0));
L2.push('منصات قابلة للربح من اليمن: '+(L.ye_actionable_platforms||0));
Object.entries(L.by_method||{}).forEach(([k,v])=>L2.push('  وسيلة '+k+': '+v+' منصة'));
(L.rails||[]).forEach(r=>L3.push((r.ye?'✔':'○')+' '+r.name+' | حد أدنى $'+r.min+' | '+r.how));
L4.push('SURGE_TOKEN أو GITHUB_TOKEN+GH_USER → رابط عام حقيقي');
L4.push('CAPSOLVER_KEY/2CAPTCHA_KEY + FIVESIM_TOKEN → تسجيل آلي للفئات B/C');
L4.push('تفعيل Google AdSense + Adsterra + ExoClick على النطاق → أول إيراد إعلاني حقيقي');
L4.push('تأكيد SWIFT KRIBYEBA مع فرع الكريمي قبل أول حوالة');
L4.push('تأكيد Gmail حقيقي (لا بريد مؤقت) لحسابات AdSense');
const md=['# APEX — تقرير التنفيذ الفعلي','','> '+new Date().toISOString(),'',
 '## 1) مُثبت بالقياس','',...L1.map(x=>'- '+x),'','## 2) الأرباح والقدرة على السحب','',...L2.map(x=>'- '+x),
 '','## 3) قنوات السحب من اليمن','',...L3.map(x=>'- '+x),'','## 4) ما تبقى (يتطلب إنسانًا)','',...L4.map(x=>'- '+x),
 '','## 5) عينات','','### منصات غير مستجيبة (أول 20)','','```',
 ...((S.dead||[]).slice(0,20).map(d=>d.domain+' — '+(d.id||''))),'```'].join('\n');
fs.writeFileSync(path.join(AX,'reports/APEX-REPORT.md'),md);
fs.writeFileSync(path.join(AX,'reports/APEX-REPORT.json'),JSON.stringify({ts:new Date().toISOString(),measured:L1,earnings:L2,rails:L3,pending_human:L4},null,1));
console.log('report='+path.join(AX,'reports/APEX-REPORT.md'));
