const fs=require('fs'),path=require('path');const AX=process.argv[2];
const S=JSON.parse(fs.readFileSync(path.join(AX,'registry/summary.json'),'utf8'));
let chain={},integ={},mail={};
try{chain=JSON.parse(fs.readFileSync(path.join(AX,'state/chain.json'),'utf8'))}catch(e){}
try{integ=JSON.parse(fs.readFileSync(path.join(AX,'state/integrations.json'),'utf8'))}catch(e){}
try{mail=JSON.parse(fs.readFileSync(path.join(AX,'state/mailbox.json'),'utf8'))}catch(e){}
const onchain=[];
(chain.chains||[]).forEach(c=>{ if(c.native>0)onchain.push({chain:c.chain,asset:'NATIVE',amt:c.native});
 if(c.usdc>0)onchain.push({chain:c.chain,asset:'USDC',amt:c.usdc});});
if(chain.usdt_tron>0)onchain.push({chain:'tron',asset:'USDT',amt:chain.usdt_tron});
const total_usd=onchain.reduce((a,x)=>a+x.amt,0);
// قواعد سحب حقيقية: الوسائل التي تعمل من اليمن + الحد الأدنى
const RAILS=[
 {name:'Binance P2P / USDT',method:'crypto',ye:true,min:1,how:'بيع USDT عبر P2P إلى ريال/بنك يمني'},
 {name:'Payeer',method:'payeer',ye:true,min:1,how:'سحب إلى بطاقة/صراف عبر Payeer'},
 {name:'AirTM',method:'airtm',ye:true,min:1,how:'تحويل إلى محفظة/بنك محلي'},
 {name:'Payoneer',method:'payoneer',ye:true,min:50,how:'استلام لحساب Payoneer ثم سحب بنكي'},
 {name:'Western Union',method:'westernunion',ye:true,min:1,how:'استلام نقدي من فرع الصراف'},
 {name:'MoneyGram',method:'moneygram',ye:true,min:1,how:'استلام نقدي'},
 {name:'Ria',method:'ria',ye:true,min:1,how:'استلام نقدي'},
 {name:'Al-Kuraimi / بنك محلي',method:'bank',ye:true,min:10,how:'حوالة SWIFT KRIBYEBA (يتطلب تأكيد)'},
 {name:'PayPal',method:'paypal',ye:false,min:100,how:'يحتاج وسيط/حساب مرتبط'},
 {name:'Wise',method:'wise',ye:false,min:50,how:'دعم اليمن محدود'}
];
const ready=S.platforms.filter(p=>p.ye>=1&&p.min>0);
const bucket={};ready.forEach(p=>{(bucket[p.method]=bucket[p.method]||[]).push({id:p.id,domain:p.domain,min:p.min,cat:p.cat});});
const rules={ts:new Date().toISOString(),rails:RAILS,ye_actionable_platforms:ready.length,
 total_platforms:S.platforms_total, reachable:S.platforms_reachable, points:S.connection_points_verified,
 by_method:Object.fromEntries(Object.entries(bucket).map(([k,v])=>[k,v.length])),
 earning_ready:ready.slice(0,300).map(p=>({id:p.id,domain:p.domain,cat:p.cat,method:p.method,min:p.min,
   state:'reachable',earned:0,verified_earning:false}))};
fs.writeFileSync(path.join(AX,'ledger/rules.json'),JSON.stringify(rules,null,1));
const st={ts:new Date().toISOString(),
 verified_earnings:{onchain_total_usd:+total_usd.toFixed(4),onchain},
 platform_earnings:{count:0,total_usd:0,note:'تتحول إلى موجبة بعد إنشاء الحسابات وربط مفاتيح الدفع'},
 integrations_live:integ.working||0, mailbox:mail.address||null,
 withdrawable_now:onchain.filter(x=>x.amt>0).length};
fs.writeFileSync(path.join(AX,'state/earnings.json'),JSON.stringify(st,null,1));
console.log('ye_actionable='+ready.length+' rails='+RAILS.length+' onchain_usd='+st.verified_earnings.onchain_total_usd);
