#!/usr/bin/env bash
# تشغيل حقيقي كامل: إصلاح → متصفح → تسجيل → التقاط مفاتيح → ربط → تفعيل → حصد
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
S(){ printf '\n══════════ %s ══════════\n' "$1"; }
S "1/8 تصحيح جذري";   bash "$H/FIX-V2.sh"
S "2/8 توسيع الأهداف"; bash "$H/TARGETS-30K.sh"
S "3/8 بريد حقيقي";    node "$H/lib/mailbox.js"
S "4/8 متصفح";         bash "$H/BROWSER-AGENT.sh" install
S "5/8 فحص المصادر";   bash "$H/AGENT-RUN.sh" verify --all
S "6/8 تفعيل الإعلانات"; bash "$H/ADS.sh" auto && bash "$H/INJECT-ADS.sh"
S "7/8 حصد حقيقي";     node "$H/lib/harvest.js"
S "8/8 تقرير";         bash "$H/REPORT.sh" 2>/dev/null | tail -22
echo
echo "★ وكيل المتصفح:  bash money/BROWSER-AGENT.sh adsterra"
echo "★ الكل بالترتيب: bash money/BROWSER-AGENT.sh all"
echo "★ مهام يومية:    bash money/DAILY.sh loop &"
