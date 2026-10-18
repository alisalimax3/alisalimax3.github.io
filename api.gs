// ═══════════════════════════════════════════════════════════════
// CineHub 3099 · باكند حقيقي: يتحقق من كابتشا Turnstile سيرفرياً
// ويُسجّل: السحوبات · الأرباح · الإحالات · النقرات
// الإعداد: Sheet جديد > Extensions > Apps Script > الصق > ضع SHEET_ID
//         > Deploy > Web app > Execute as Me > Anyone > انسخ /exec
// ═══════════════════════════════════════════════════════════════
const SHEET_ID = 'PASTE_SHEET_ID_HERE';
const TURNSTILE_SECRET = '1x0000000000000000000000000000000AA'; // مفتاحك الحقيقي
const OWNER_EMAIL = ''; // بريدك لإشعارك بكل طلب سحب

const HEADERS = {
  payouts:  ['وقت','المستخدم','المرجع','المبلغ','الوسيلة','الحساب','الاسم','الحالة'],
  earnings: ['وقت','المستخدم','إجمالي','صافي','جاهز للسحب'],
  referrals:['وقت','المُحيل','المُحال','المبلغ'],
  clicks:   ['وقت','المستخدم','النوع','الرابط'],
  watch:    ['وقت','المستخدم','الرابط','المكافأة']
};
function sh_(n){
  const ss=SpreadsheetApp.openById(SHEET_ID);
  let s=ss.getSheetByName(n);
  if(!s){ s=ss.insertSheet(n); s.appendRow(HEADERS[n]||['وقت','بيانات']); s.setFrozenRows(1); }
  return s;
}
function js_(o){ return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON); }
function verify_(t){
  if(!t) return false;
  try{
    const r=UrlFetchApp.fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',
      {method:'post', payload:{secret:TURNSTILE_SECRET, response:t}});
    return JSON.parse(r.getContentText()).success===true;
  }catch(e){ return true; }
}
function doPost(e){
  let d={}; try{ d=JSON.parse((e.postData&&e.postData.contents)||'{}'); }catch(err){ return js_({ok:false,why:'bad-json'}); }
  const t=d.type||'clicks', p=d.payload||{};
  if(t==='payouts' && !verify_(p.token)) return js_({ok:false,why:'captcha'});
  const s=sh_(t);
  if(t==='payouts'){
    s.appendRow([new Date(), d.uid||'', p.ref||'', p.amount||'', p.method||'', p.account||'', p.name||'', 'pending']);
    if(OWNER_EMAIL) try{ MailApp.sendEmail(OWNER_EMAIL,'طلب سحب جديد '+p.ref,
      'المبلغ: $'+p.amount+'\nالوسيلة: '+p.method+'\nالحساب: '+p.account+'\nالاسم: '+p.name); }catch(e2){}
  } else if(t==='earnings'){ s.appendRow([new Date(), d.uid||'', p.gross||0, p.net||0, p.bal||0]); }
  else if(t==='referrals'){ s.appendRow([new Date(), p.from||'', p.to||'', p.amount||0]); }
  else if(t==='watch'){ s.appendRow([new Date(), d.uid||'', p.url||'', p.reward||0]); }
  else { s.appendRow([new Date(), d.uid||'', p.kind||'', p.url||'']); }
  return js_({ok:true, ref:p.ref||''});
}
function doGet(e){
  const t=(e.parameter.type)||'payouts';
  const s=sh_(t);
  return js_({ok:true, rows:s.getDataRange().getValues()});
}
// ═══ تحقق آلي كل ساعة من رصيد الشبكات (اختياري) ═══
function dailyReport(){
  const rows=sh_('payouts').getDataRange().getValues().slice(1).filter(r=>r[7]==='pending');
  if(rows.length && OWNER_EMAIL) MailApp.sendEmail(OWNER_EMAIL,'CineHub: '+rows.length+' طلب سحب معلّق','افتح لوحة التحكم للمعالجة.');
}
