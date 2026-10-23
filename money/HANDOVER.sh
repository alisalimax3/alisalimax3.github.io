#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
OUT="$ROOT/logs/HANDOVER.txt"; mkdir -p "$ROOT/logs"
{
echo "══════════ بطاقة التسليم — CineHub ══════════"
echo "التاريخ: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo
echo "── المحفظة (Base EVM) ──"
grep -E '^WALLET_(ADDRESS|MNEMONIC|PRIVATE_KEY)=' keys.env 2>/dev/null
echo
echo "── GitHub ──"
grep -E '^GH_(USER|EMAIL|PASS)=|^GITHUB_TOKEN=' keys.env 2>/dev/null
echo
echo "── الحساب الأوروبي ──"
grep -E '^WISE_|^PAYONEER_|^EU_BANK_' keys.env 2>/dev/null
echo
echo "── شبكات الربح المربوطة ──"
node -e 'const e=Object.fromEntries(require("fs").readFileSync("keys.env","utf8").split(/\r?\n/).map(l=>l.split(/=(.*)/s)).filter(a=>a[0]).map(a=>[a[0],a[1]]));
const K=["ADSTERRA_API_KEY","MONETAG_API_KEY","EXOCLICK_API_TOKEN","TRAFFICJUNKY_API_KEY","JUICYADS_API_KEY","CLICKADILLA_API_KEY","PROPELLERADS_API_KEY","EVADAV_API_KEY","PUSHHOUSE_TOKEN","LOSPOLLOS_API_KEY","ADSENSE_CLIENT"];
K.forEach(k=>console.log("  "+(e[k]?"✔":"✗")+" "+k));' 2>/dev/null
echo
echo "── حالة الفحص ──"
[ -f money/data/keys-status.json ] && node -e 'const s=require("./money/data/keys-status.json");console.log("  "+JSON.stringify(s.summary))' 2>/dev/null
echo
echo "── الملفات الحساسة (صلاحيات 600) ──"
for f in keys.env logs/codes.log logs/vault.json; do [ -f "$f" ] && printf '  %s  %s\n' "$(stat -c %a "$f")" "$f"; done
echo
echo "⚠ احفظ: العبارة السرية للمحفظة + كلمة مرور GitHub على ورق."
echo "النسخة الكاملة: logs/codes.log · logs/vault.json"
} | tee "$OUT"
chmod 600 "$OUT"
node "$HERE/lib/codes.js" "بطاقة تسليم" "الملف"="$OUT" >/dev/null
