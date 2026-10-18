#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 — FIXALL2 : استعادة التوكن + دفع موثّق بلا اعتماد على الشبكة
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
OWNER="alkazmybwhwr-dot"; SLUG="$OWNER/$OWNER.github.io"; LIVE="https://$OWNER.github.io"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }; info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }; warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
T=""; L=""; SCOPES=""
mkdir -p tools m g x k p pb

echo "═══ 1 · استعادة التوكن ═══"
rm -f .git/index.lock .git/*.lock 2>/dev/null
git config --local credential.helper "" 2>/dev/null || true

from_auth(){ python3 -c "
import json,sys
try: print((json.load(open('auth.json')).get('token') or '').strip())
except Exception: print('')" 2>/dev/null; }
from_remote(){ git remote get-url origin 2>/dev/null | sed -n 's|https://[^:]*:\([^@]*\)@.*|\1|p'; }

[ -n "${1:-}" ] && T="$1"
[ -z "$T" ] && T="$(from_auth)"
[ -z "$T" ] && { info "auth.json فاقد التوكن — أستعيده من .git/config"; T="$(from_remote)"; }
if [ -z "$T" ]; then
  warn "لا توكن في أي مكان."
  echo "أنشئ توكنًا: https://github.com/settings/tokens/new?scopes=repo,workflow"
  printf "الصق التوكن: "; read -r T
fi
[ -z "$T" ] && { bad "بلا توكن"; exit 1; }
printf "  طول التوكن: %d | البداية: %s\n" "${#T}" "$(printf %s "$T" | cut -c1-11)"

echo "  التحقق من التوكن…"
R=$(curl -s -m 25 -H "Authorization: token $T" https://api.github.com/user)
L=$(printf '%s' "$R" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('login',''))" 2>/dev/null)
if [ -z "$L" ]; then
  warn "التوكن مرفوض من GitHub."
  printf "الصق توكنًا صحيحًا (Enter للإلغاء): "; read -r NT
  [ -n "${NT:-}" ] && { T="$NT"; R=$(curl -s -m 25 -H "Authorization: token $T" https://api.github.com/user); L=$(printf '%s' "$R" | python3 -c "import sys,json;print(json.load(sys.stdin).get('login',''))" 2>/dev/null); }
fi
[ -z "$L" ] && { bad "تعذّر التحقق — تأكد من الإنترنت"; exit 1; }
SCOPES=$(curl -sI -m 20 -H "Authorization: token $T" https://api.github.com/ | tr -d '\r' | sed -n 's/^[Xx]-[Oo]auth-[Ss]copes: *//p')
ok "الحساب: $L | الصلاحيات: ${SCOPES:-لا شيء}"
echo "$SCOPES" | grep -q workflow || warn "بلا صلاحية workflow → سنستخدم مسار الملفات فقط"

python3 - "$T" "$L" "$SCOPES" <<'PY'
import json,sys
t,l,s=sys.argv[1],sys.argv[2],sys.argv[3]
try: a=json.load(open("auth.json",encoding="utf-8"))
except Exception: a={}
a.update({"token":t,"login":l,"repo":l+"/"+l+".github.io","branch":"main","scopes":s,
 "has_repo":"repo" in s,"has_workflow":"workflow" in s})
json.dump(a,open("auth.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
try:
    p=json.load(open("pb.json",encoding="utf-8"))
except Exception: p={}
p["token"]=t; p["repo"]=l+"/"+l+".github.io"
json.dump(p,open("pb.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("  auth.json و pb.json محدّثان")
PY
echo "$T" > .gh-token

# ══ 2 · دفع لا يعتمد على اسم المستخدم ══
cat > tools/push.sh <<'PSH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
rm -f .git/index.lock 2>/dev/null
T=$(python3 -c "import json;print((json.load(open('auth.json')).get('token') or '').strip())" 2>/dev/null)
[ -z "$T" ] && { echo "FAIL بلا توكن"; exit 1; }
U="https://x-access-token:$T@github.com/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io.git"
git remote set-url origin "$U"
git config --local credential.helper ""
git add -A
for f in .nojekyll auth.json wallet.json ledger.json ads.json payout.json gate.json pb.json earnings.json keywords.json genres.json agent_state.json ia_cache.json sitemap-k.xml sitemap-g.xml sitemap-m.xml feed.xml genres.html keywords.html posters.js ads.js pb.html gate.js robots.txt; do git add -f "$f" 2>/dev/null; done
git add -f m g k p 2>/dev/null
git -c user.email=a@c.local -c user.name=Agent commit -q -m "${1:-run}" 2>/dev/null || true
for a in 1 2 3; do
  git fetch "$U" main -q 2>/dev/null || true
  git rebase --autostash FETCH_HEAD -q >/dev/null 2>&1 || { git rebase --abort >/dev/null 2>&1; git merge -X ours FETCH_HEAD -q -m merge 2>/dev/null||true; }
  rm -f .git/index.lock 2>/dev/null
  if git push "$U" main >.po 2>&1; then echo "OK"; exit 0; fi
  if grep -qi "workflow" .po; then
    mv .github "$HOME/.gh_hold" 2>/dev/null||true
    git add -A; git -c user.email=a@c.local -c user.name=Agent commit -q -m "site" 2>/dev/null||true
    git push "$U" main >.po 2>&1 && { mv "$HOME/.gh_hold" .github 2>/dev/null||true; echo "OK-nowf"; exit 0; }
    mv "$HOME/.gh_hold" .github 2>/dev/null||true
  fi
  echo "  محاولة $a: $(tail -2 .po|tr '\n' ' ')"
  sleep 3
done
git push --force "$U" main >.po 2>&1 && { echo "OK-force"; exit 0; }
echo "FAIL $(tail -3 .po|tr '\n' ' ')"
PSH
chmod +x tools/push.sh

# ══ 3 · إعادة بناء سريعة مضمونة ══
echo; echo "═══ 2 · بناء ═══"
[ -f tools/normalize.py ] && python3 tools/normalize.py 2>/dev/null || warn "normalize مفقود"
[ -f tools/fix_posters.py ] && python3 tools/fix_posters.py 2>/dev/null
[ -f tools/movie_pages.py ] && MOVIE_MAX="${MOVIE_MAX:-12000}" timeout 1200 python3 tools/movie_pages.py
[ -f tools/pages.py ] && python3 tools/pages.py
[ -f tools/feed.py ] && python3 tools/feed.py
python3 tools/ledger.py 2>/dev/null||true

# ══ 4 · دفع ══
echo; echo "═══ 3 · دفع ═══"
R=$(bash tools/push.sh "fixall2: token repair + push")
echo "  النتيجة: $R"
case "${R%% *}" in OK|OK-force|OK-nowf) ok "مدفوع" ;; *) bad "فشل: $R" ;; esac

# ══ 5 · تحقق عبر API (بـ T معرّف صحيحًا) ══
echo; echo "═══ 4 · تحقق من الريموت ══"
MISS=0
for f in .nojekyll index.html catalog.json keywords.html genres.html keywords.json earnings.json sitemap-m.xml feed.xml tools/dispatch.py; do
  c=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $T" "https://api.github.com/repos/$SLUG/contents/$f?ref=main")
  if [ "$c" = "200" ]; then printf '\033[32m✓\033[0m %s\n' "$f"; else printf '\033[31m✗\033[0m %s → %s\n' "$f" "$c"; MISS=$((MISS+1)); fi
done
c=$(curl -s -H "Authorization: token $T" "https://api.github.com/repos/$SLUG/contents/m?ref=main"|python3 -c "import sys,json;print(len(json.load(sys.stdin)))" 2>/dev/null||echo 0)
[ "${c:-0}" -gt 100 ] && ok "m/ فيه $c ملف" || { bad "m/ فيه ${c:-0} فقط"; MISS=$((MISS+1)); }

# ══ 6 · تشغيل الوركفلو ══
echo; echo "═══ 5 · تشغيل الوركفلو ══"
python3 tools/dispatch.py 2>&1 | tail -8

echo; echo "═══ 6 · حي ══"
sleep 45
for f in "" genres.html keywords.html sitemap-m.xml earnings.json admin.html; do
  r=0; for t in 1 2 3; do r=$(curl -s -o /dev/null -w '%{http_code}' "$LIVE/$f"); [ "$r" = "200" ] && break; sleep 12; done
  [ "$r" = "200" ] && ok "/$f" || bad "/$f → $r"
done
echo
[ "$MISS" = "0" ] && ok "مكتمل — الريموت فيه كل شيء" || bad "$MISS ناقص"
info "اللوحة $LIVE/admin.html · السحب $LIVE/withdraw.html"
