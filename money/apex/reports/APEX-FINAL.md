# CineHub / APEX — التقرير النهائي

> 2026-10-22T19:07:00.043Z

## 1) مُثبت بالقياس

- نطاقات في السجل: **665** | استجابت: **427**
- نقاط ربط موثّقة: **4523**
- واجهات API حية: **19/36**
- منصات تدعم اليمن: **46**
- صفحات محقونة بالإعلانات: **47384** {"adult":1598,"cinema":3212,"general":42574}
- صندوق بريد حقيقي: cinehubignhsi@lnovic.com

## 2) خط الأموال (Ingest→Fraud→Ledger→Compliance→Settle→Wallet→Reconcile)

- أحداث: 4 | مقبولة: 4 | معلّقة: 0 | مرفوضة: 0
- دفتر مزدوج: سليم ومتوازن | قيود: 4
- **مؤكدة:** $0 | **متوقعة:** $0 | **معلّقة:** $0 | **صافي بعد الرسوم:** $0
- معاملة موقّعة: 0x120c7996f5a43b5968324f3c61dddcb01c05d1aae52f4e69ea64701c63ce48d9 | مُبثّة: لا
- مطابقة ثلاثية: بانتظار أول دفعة | مصادر إيراد: adsterra:x exoclick:x

## 3) محفظة التطبيق (وجهة السحب)

`0xd89862994f82bAE9a69dfAC251C09881729963Ce` — keys.env:PRIVATE_KEY

## 4) قنوات السحب من اليمن

✔ Binance P2P / USDT | حد $1 | بيع USDT عبر P2P إلى ريال/بنك يمني
✔ Payeer | حد $1 | سحب إلى بطاقة/صراف عبر Payeer
✔ AirTM | حد $1 | تحويل إلى محفظة/بنك محلي
✔ Payoneer | حد $50 | استلام لحساب Payoneer ثم سحب بنكي
✔ Western Union | حد $1 | استلام نقدي من فرع الصراف
✔ MoneyGram | حد $1 | استلام نقدي
✔ Ria | حد $1 | استلام نقدي
✔ Al-Kuraimi / بنك محلي | حد $10 | حوالة SWIFT KRIBYEBA (يتطلب تأكيد)
○ PayPal | حد $100 | يحتاج وسيط/حساب مرتبط
○ Wise | حد $50 | دعم اليمن محدود

## 5) النشر

- المستودع: https://x-access-token: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@github.com/alisalimax3/alisalimax3.github.io
- الفرع: main
- الالتزام: `5634be8568ecd6eded0244653487f494dc9e741c`

## 6) متطلبات تحتاج تدخلك

- مفاتيح النشر (SURGE/NETLIFY/VERCEL/CLOUDFLARE/GITHUB_TOKEN) → reports/KEYS.md
- ADSENSE_CLIENT / ADSTERRA_HOST / EXOCLICK_ZONE / JUICYADS_ZONE / MONETAG_ZONE → أول إيراد حقيقي
- ADSTERRA_API_KEY / EXOCLICK_API_KEY → حصاد تلقائي
- CAPSOLVER_KEY + FIVESIM_TOKEN → تسجيل موسّع

## 7) تشخيص خام

```
### حجم الملفات الحرجة
lib/async.js           19 سطر
lib/q-sec.js           36 سطر
lib/q-lint.js          46 سطر
lib/q-fix.js           63 سطر
lib/q-db.js            30 سطر
lib/q-load.js          19 سطر
lib/q-test.js          73 سطر

### q-sec: موضع الدفع
  6:function audit(inv){const D=[];const add=(sev,rule,file,msg,fix)=>{const _s=({sev,rule,file,msg,fixable:!!fix});if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER|PORT|CURRENCY)$/i.test(String(_s)))D.push(_s);}
  16:    if(v&&v.length>=16&&!/^(true|false|\d+)$/.test(v)&&!/^https?:/.test(v))if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER)$/.test(k))secrets.push({k,v});}});

### q-lint/q-fix: مواضع node
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-lint.js:1:#!/usr/bin/env node
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-lint.js:3:const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js");
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-lint.js:6:  for(const f of inv.scripts){try{execFileSync(process.execPath,["--check",path.join(U.ROOT,f)],{stdio:"pipe"});}
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-fix.js:1:#!/usr/bin/env node
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-fix.js:3:const fs=require("fs"),path=require("path"),{execFileSync}=require("child_process"),U=require("./q-util.js"),QDB=require("./q-db.js");
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-fix.js:13:  if(/\.js$/.test(file)){try{execFileSync(process.execPath,["--check",p],{stdio:"pipe"});}
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-fix.js:14:    catch(e){U.restore(p);rec(rule,file,false,"فشل node --check — استُرجع");return false;}}
  /data/data/com.termux/files/home/cinehub3099/money/lib/q-fix.js:48:  const gi=path.join(U.ROOT,".gitignore");const need=["node_modules","keys.env","logs","*.pid","_backup","_deploy",".cache","__pycache__"];

### قائمة المفاتيح في keys.env
WALLET_MNEMONIC WALLET_ADDRESS WALLET_PRIVATE_KEY 
### حالة git
  branch=main
  remote=https://x-access-token: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@github.com/alisalimax3/alisalimax3.github.io.git
  HEAD=65f5f10e3
  ملفات كبيرة>40M: 8

### ملفات HTML
  إجمالي: 65468
  مُعلَّمة: 65449

```