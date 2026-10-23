#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
cat <<'TXT'
═══ الحساب الأوروبي — خيارات حقيقية بـIBAN أوروبي ═══
الوثائق المطلوبة: جواز سفر ساري + سيلفي + إثبات عنوان (كشف بنك/فاتورة < 90 يومًا).

1) Wise — الأفضل للاستقبال الدولي        https://wise.com
   ▸ يعطي IBAN بلجيكي (BE) + حساب USD + GBP + 40 عملة
   ▸ يقبل Wire و SEPA من شبكات الإعلانات، ويحوّل لأي مكان في العالم
   ▸ مفتاح API: Settings ← API tokens → WISE_API_TOKEN

2) Revolut — أسرع افتتاح                   https://www.revolut.com
   ▸ IBAN ليتواني (LT) — يقبل SEPA
   ▸ مفتاح: Settings ← API → REVOLUT_TOKEN

3) N26 — IBAN ألماني (DE)                  https://n26.com
   ▸ يقبل SEPA وDirect Debit

4) Payoneer — الأفضل لشبكات الأفلييت        https://www.payoneer.com
   ▸ حساب استقبال EUR/GBP/USD — تقبله معظم شبكات CPA

5) Airwallex / Paysera — بدائل أوروبية
   https://www.airwallex.com · https://www.paysera.com
TXT
node "$HERE/lib/codes.js" "الحساب الأوروبي — المطلوب" "الوثائق"="جواز + سيلفي + إثبات عنوان" "الخيار الأول"="Wise IBAN BE" "الخيار الثاني"="Revolut IBAN LT" >/dev/null
echo
echo "  ✔ سُجّل في logs/codes.log"
echo "  بعد الفتح أضف في keys.env:"
echo "    WISE_API_TOKEN= · WISE_IBAN= · PAYONEER_EMAIL= · EU_BANK_NAME="
