#!/data/data/com.termux/files/usr/bin/bash
# دفع قطعي: بلا rebase، بلا إخفاء أخطاء
set -u
cd "$HOME/cinehub3099" || exit 1
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }; bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }; warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
rm -f .git/index.lock .git/*.lock 2>/dev/null
T=$(python3 -c "import json;print((json.load(open('auth.json')).get('token') or '').strip())" 2>/dev/null)
[ -z "$T" ] && { bad "بلا توكن"; exit 1; }
U="https://x-access-token:$T@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git"

echo "═══ 1 · إعداد git لمقاومة القطع ══"
git config --local http.version HTTP/1.1
git config --local http.postBuffer 524288000
git config --local http.lowSpeedLimit 0
git config --local http.lowSpeedTime 999999
git config --local core.compression 0
git config --local pack.threads 1
git config --local core.bigFileThreshold 512m
git config --local credential.helper ""
ok "HTTP/1.1 + buffer 500MB + ضغط 0"

echo; echo "═══ 2 · تجهيز الملفات ══"
git add -A 2>&1 | tail -3
for f in .nojekyll auth.json wallet.json ledger.json ads.json payout.json gate.json pb.json \
         earnings.json keywords.json genres.json agent_state.json ia_cache.json \
         sitemap-k.xml sitemap-g.xml sitemap-m.xml sitemap.xml feed.xml \
         genres.html keywords.html posters.js ads.js pb.html gate.js robots.txt; do
  git add -f "$f" 2>/dev/null
done
git add -f m g k p 2>/dev/null
N=$(git diff --cached --name-only 2>/dev/null | wc -l)
echo "  ملفات مجهّزة: $N"
if [ "$N" = "0" ]; then
  warn "لا تغييرات مجهّزة — أجبر الإضافة"
  git add -f . 2>/dev/null
  N=$(git diff --cached --name-only 2>/dev/null | wc -l)
  echo "  بعد الإجبار: $N"
fi
[ "$N" = "0" ] && { info "لا شيء جديد — الريموت مطابق"; }

echo; echo "═══ 3 · إنشاء commit (بإظهار الأخطاء) ══"
git -c user.email=a@c.local -c user.name=Agent commit -m "${1:-update}" 2>&1 | tail -3
H=$(git rev-parse --short HEAD 2>/dev/null)
echo "  HEAD المحلي: $H"
R=$(git ls-remote "$U" main 2>/dev/null | cut -c1-8)
echo "  HEAD الريموت: ${R:-غير معروف}"
[ "$H" = "$R" ] && info "متطابقان — لا حاجة للدفع" || ok "فرق موجود → ندفع"

echo; echo "═══ 4 · الدفع (force) ══"
if git push --force "$U" main 2>&1 | tail -6; then ok "تم"; else bad "فشل"; fi
echo; echo "═══ 5 · تحقق ══"
sleep 4
NEW=$(git ls-remote "$U" main 2>/dev/null | cut -c1-8)
[ "$NEW" = "$H" ] && ok "الريموت الآن عند $NEW — مطابق للمحلي" || bad "الريموت $NEW ≠ المحلي $H"
for f in m keywords.html keywords.json earnings.json sitemap-m.xml tools/dispatch.py; do
  c=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $T" \
      "https://api.github.com/repos/alkazmybwhwr-dot/alisalimax3.github.io/contents/$f?ref=main")
  [ "$c" = "200" ] && ok "$f" || bad "$f → $c"
done
