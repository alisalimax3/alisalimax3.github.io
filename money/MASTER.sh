#!/usr/bin/env bash
# الأمر التنفيذي الشامل — بلا توقف، بلا أسئلة
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
S(){ printf '\n══════════ %s ══════════\n' "$1"; }
S "1/10 بيئة";     [ -f keys.env ] || touch keys.env; chmod 600 keys.env; mkdir -p logs money/data money/assets
S "2/10 هوية";     bash "$H/IDENTITY.sh"
S "3/10 محفظة";    bash "$H/WALLET.sh"
S "4/10 أوروبي";   bash "$H/EU.sh"
S "5/10 أهداف";    bash "$H/TARGETS.sh"
S "6/10 إصلاح";    bash "$H/PATCH-ALL.sh" 2>/dev/null | grep -E '✔|✗' || true
S "7/10 خدمات";    bash "$H/TOTAL.sh"
S "8/10 فحص";      bash "$H/AGENT-RUN.sh" verify --all
S "9/10 حقن";      bash "$H/INJECT-ADS.sh"
S "10/10 بوابة";   bash "$H/VERIFY.sh" | tail -14
bash "$H/REPORT.sh"
echo
echo "★ التالي: bash money/AUTO-SIGNUP.sh tier A   ثم   bash money/GITHUB-CREATE.sh"
echo "★ التقرير الكامل: logs/REPORT.txt"
