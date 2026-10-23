const fs=require('fs'),path=require('path');
const AX=process.env.AX;
const g=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
const r=(p,d)=>{try{return fs.readFileSync(path.join(AX,p),'utf8').trim()}catch(e){return d||'-'}};
const S=g('registry/summary.json'),I=g('state/integrations.json'),E=g('state/earnings.json'),
 L=g('ledger/rules.json'),W=g('state/appwallet.json'),MB=g('state/mailbox.json'),WR=g('state/wire.json'),
 MO=g('pipeline/money.json'),SE=g('pipeline/settle.json'),RC=g('pipeline/reconcile.json'),RV=g('state/revenue.json');
const OPEN=g('state/ports.json',{});
const md=['# CineHub / APEX — التقرير النهائي','','> '+new Date().toISOString(),'',
'## 1) مُثبت بالقياس','',
'- نطاقات في السجل: **'+(S.platforms_total||0)+'** | استجابت: **'+(S.platforms_reachable||0)+'**',
'- نقاط ربط موثّقة: **'+(S.connection_points_verified||0)+'**',
'- واجهات API حية: **'+(I.working||0)+'/'+(I.total||0)+'**',
'- منصات تدعم اليمن: **'+(L.ye_actionable_platforms||0)+'**',
'- صفحات محقونة بالإعلانات: **'+(WR.wired||0)+'** '+JSON.stringify(WR.by_circle||{}),
'- صندوق بريد حقيقي: '+(MB.address||'—'),'',
'## 2) خط الأموال (Ingest→Fraud→Ledger→Compliance→Settle→Wallet→Reconcile)','',
'- أحداث: '+(MO.events||0)+' | مقبولة: '+(MO.approved||0)+' | معلّقة: '+(MO.held||0)+' | مرفوضة: '+(MO.rejected||0),
'- دفتر مزدوج: '+((MO.ledger_ok)?'سليم ومتوازن':'خلل')+' | قيود: '+(MO.entries||0),
'- **مؤكدة:** $'+((E.buckets&&E.buckets.confirmed_usd)||0)+' | **متوقعة:** $'+((E.buckets&&E.buckets.expected_usd)||0)+' | **معلّقة:** $'+((E.buckets&&E.buckets.pending_usd)||0)+' | **صافي بعد الرسوم:** $'+((E.buckets&&E.buckets.net_after_fees_usd)||0),
'- معاملة موقّعة: '+(SE.built?SE.built.txhash:'—')+' | مُبثّة: '+(SE.broadcast?'نعم':'لا'),
'- مطابقة ثلاثية: '+(RC.match?'مطابق':'بانتظار أول دفعة')+' | مصادر إيراد: '+((RV.sources||[]).map(s=>s.name+':'+(s.ok?'ok':'x')).join(' ')||'—'),'',
'## 3) محفظة التطبيق (وجهة السحب)','','`'+(W.address||'—')+'` — '+(W.source||''),'',
'## 4) قنوات السحب من اليمن','',...((L.rails||[]).map(x=>(x.ye?'✔':'○')+' '+x.name+' | حد $'+x.min+' | '+x.how)),'',
'## 5) النشر','','- المستودع: '+r('reports/.repo'),'- الفرع: '+r('reports/.branch'),'- الالتزام: `'+r('reports/.commit')+'`','',
'## 6) متطلبات تحتاج تدخلك','',
'- مفاتيح النشر (SURGE/NETLIFY/VERCEL/CLOUDFLARE/GITHUB_TOKEN) → reports/KEYS.md',
'- ADSENSE_CLIENT / ADSTERRA_HOST / EXOCLICK_ZONE / JUICYADS_ZONE / MONETAG_ZONE → أول إيراد حقيقي',
'- ADSTERRA_API_KEY / EXOCLICK_API_KEY → حصاد تلقائي',
'- CAPSOLVER_KEY + FIVESIM_TOKEN → تسجيل موسّع','',
'## 7) تشخيص خام','','```',(function(){const f=fs.readdirSync(path.join(AX,'reports')).filter(x=>x.startsWith('diag-')).sort().pop();
 try{return fs.readFileSync(path.join(AX,'reports',f),'utf8')}catch(e){return ''}})(),'```'].join('\n');
fs.writeFileSync(path.join(AX,'reports/APEX-FINAL.md'),md);
console.log('ok');
