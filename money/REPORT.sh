#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
O="$ROOT/logs/REPORT.txt"
{
echo "═══════════ تقرير التنفيذ — $(date -u +%Y-%m-%dT%H:%M:%SZ) ═══════════"
echo
echo "▌ أُنجز فعليًا (مُتحقَّق منه):"
[ -f money/data/identity.json ] && echo "  ✔ هوية تجارية: $(node -e 'console.log(require("./money/data/identity.json").brand+" / "+require("./money/data/identity.json").handle)')" || echo "  ✗ لا هوية"
[ -f money/data/profiles/_DESCRIPTIONS.md ] && echo "  ✔ $(ls money/data/profiles | wc -l | tr -d ' ') ملف نبذة منصّة-مخصّص" || echo "  ✗ لا ملفات نبذة"
grep -q '^WALLET_ADDRESS=0x' keys.env 2>/dev/null && echo "  ✔ محفظة Base: $(grep -m1 '^WALLET_ADDRESS=' keys.env | cut -d= -f2)" || echo "  ✗ لا محفظة"
grep -q '^TOTP_SECRET=' keys.env 2>/dev/null && echo "  ✔ سر 2FA مُولَّد" || echo "  ✗ لا 2FA"
[ -f money/data/targets.json ] && echo "  ✔ أهداف: $(node -e 'console.log(require("./money/data/targets.json").total.toLocaleString())') نقطة" || echo "  ✗ لا أهداف"
[ -f money/data/keys-status.json ] && echo "  ✔ فحص المصادر: $(node -e 'const s=require("./money/data/keys-status.json");console.log(JSON.stringify(s.summary))')" || echo "  ✗ لا فحص"
[ -f money/data/ads.json ] && echo "  ✔ شرائح إعلانية مفعّلة: $(node -e 'console.log(require("./money/data/ads.json").filter(a=>a.enabled&&a.snippet).length)')" || echo "  ✗ لا شرائح"
echo
echo "▌ يحتاج تدخلك (لا يمكن أتمتته):"
echo "  • 2FA: أضف السر في Google Authenticator"
echo "  • GitHub PAT: Settings → Developer settings → Tokens (classic) → repo"
echo "  • الحساب الأوروبي: جواز + سيلفي + إثبات عنوان (Wise / Revolut)"
echo "  • الموافقات البشرية: ExoClick، TrafficJunky، JuicyAds، CrakRevenue"
echo "  • إثبات ملكية الموقع في لوحة كل شبكة إعلانية (ملف/ميتا تاغ)"
echo
echo "▌ شبكات الربح — حالة الربط:"
node -e 'const e=Object.fromEntries(require("fs").readFileSync("keys.env","utf8").split(/\r?\n/).map(l=>l.split(/=(.*)/s)).filter(a=>a[0]).map(a=>[a[0],a[1]]));
["ADSTERRA_API_KEY","MONETAG_API_KEY","EXOCLICK_API_TOKEN","TRAFFICJUNKY_API_KEY","JUICYADS_API_KEY","CLICKADILLA_API_KEY","PROPELLERADS_API_KEY","EVADAV_API_KEY","PUSHHOUSE_TOKEN","LOSPOLLOS_API_KEY","ADSENSE_CLIENT"].forEach(k=>console.log("  "+(e[k]?"✔ مربوطة":"○ ناقصة")+"  "+k));' 2>/dev/null
echo
echo "▌ الملفات الحساسة:"
for f in keys.env logs/codes.log logs/vault.json logs/REPORT.txt; do [ -f "$f" ] && printf '  %s  %s\n' "$(stat -c %a "$f" 2>/dev/null)" "$f"; done
echo
echo "▌ المتبقي: راجع قائمة «يحتاج تدخلك» أعلاه — لا شيء آخر."
} | tee "$O"
chmod 600 "$O"
