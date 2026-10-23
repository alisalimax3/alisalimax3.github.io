const fs=require('fs'),path=require('path');const AX=process.argv[2],M=process.argv[3];
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
const S=g('registry/summary.json'),I=g('state/integrations.json'),E=g('state/earnings.json'),
 L=g('ledger/rules.json'),W=g('state/appwallet.json'),MB=g('state/mailbox.json'),WR=g('state/wire.json'),
 MO=g('pipeline/money.json'),SE=g('pipeline/settle.json'),RC=g('pipeline/reconcile.json');
const md=['# CineHub / APEX — تقرير الإنجاز','','> '+new Date().toISOString(),'',
'## 1) مُثبت بالقياس','',
'- نطاقات في السجل: **'+(S.platforms_total||0)+'**','- استجابت فعليًا: **'+(S.platforms_reachable||0)+'**',
'- نقاط ربط موثّقة: **'+(S.connection_points_verified||0)+'**','- واجهات API حية: **'+(I.working||0)+'/'+(I.total||0)+'**',
'- منصات تدعم اليمن: **'+(L.ye_actionable_platforms||0)+'**','- صفحات حُقنت بالإعلانات: **'+((WR.by_circle&&(WR.by_circle.adult+WR.by_circle.cinema+WR.by_circle.general))||0)+'**',
'- صندوق بريد حقيقي: '+(MB.address||'—'),'','## 2) خط الأموال','',
'- أحداث معالجة: '+(MO.events||0)+' | مقبولة: '+(MO.approved||0)+' | معلّقة: '+(MO.held||0)+' | مرفوضة: '+(MO.rejected||0),
'- دفتر مزدوج سليم: '+((MO.ledger_ok)?'نعم':'لا')+' | قيود: '+(MO.entries||0),
'- **مؤكدة:** $'+((E.buckets&&E.buckets.confirmed_usd)||0)+' | **متوقعة:** $'+((E.buckets&&E.buckets.expected_usd)||0),
'- **معلّقة:** $'+((E.buckets&&E.buckets.pending_usd)||0)+' | **صافي بعد الرسوم:** $'+((E.buckets&&E.buckets.net_after_fees_usd)||0),
'- معاملة موقّعة (Settlement): '+(SE.built?SE.built.txhash:'—')+' | مُبثّة: '+(SE.broadcast?'نعم':'لا'),
'- مطابقة ثلاثية: '+((RC.match)?'مطابق':'بانتظار أول دفعة'),'','## 3) محفظة التطبيق','','- `'+(W.address||'—')+'` — '+(W.source||''),'',
'## 4) قنوات السحب من اليمن','',...((L.rails||[]).map(r=>(r.ye?'✔':'○')+' '+r.name+' | $'+r.min+' | '+r.how)),'',
'## 5) متطلبات تحتاج تدخلك','',
'- مفاتيح النشر: SURGE/NETLIFY/VERCEL/CLOUDFLARE → reports/KEYS.md',
'- CAPSOLVER_KEY + FIVESIM_TOKEN → تسجيل آلي موسّع',
'- ADSENSE_CLIENT / ADSTERRA_HOST / EXOCLICK_ZONE / JUICYADS_ZONE / MONETAG_ZONE → أول إيراد حقيقي',
'- ADSTERRA_API_KEY / EXOCLICK_API_KEY → حصاد تلقائي للأرباح','',
'## 6) سطور التشخيص الخام','','```',(function(){try{return fs.readFileSync(path.join(AX,'reports','diag-'+process.argv[4]+'.txt'),'utf8')}catch(e){return ''}})(),'```'].join('\n');
fs.writeFileSync(path.join(AX,'reports/APEX-FINAL.md'),md);
console.log('final_report=ok');
