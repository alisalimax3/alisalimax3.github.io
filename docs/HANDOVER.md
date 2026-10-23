# تسليم — أنت المالك

## ما تم
- 9763 هدفًا مسجّلًا في السجل
- 0 تكاملًا مُتحقّقًا فعليًا
- undefined

## الأسرار
- كل المفاتيح في `keys.env` (صلاحيات 600)
- نسخة مشفّرة: `money/data/vault.enc`
- سجل المصادر والأوقات: `money/data/secrets.json`

## حسابك على كل خدمة
- البريد وكلمة المرور لكل خدمة: `money/db/creds.json`
- بريد التحقق المستخدم: `money/db/mail.json`

## تحكمك الكامل

```bash
bash money/ZERO.sh owner lock <id>      # لا تلمسه بعد الآن
bash money/ZERO.sh owner revoke <id>    # احذف مفاتيحه
bash money/ZERO.sh owner rollback <id> reachable
bash money/ZERO.sh pause                # أوقف الوكيل
bash money/ZERO.sh open                 # استعد الأسرار من الخزنة
```

## سحب الأرباح
- أضف PAYOUT_ADDRESS على base