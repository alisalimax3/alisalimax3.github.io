#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
rm -f .git/index.lock 2>/dev/null
T=$(python3 -c "import json;print((json.load(open('auth.json')).get('token') or '').strip())" 2>/dev/null)
[ -z "$T" ] && { echo "FAIL بلا توكن"; exit 1; }
U="https://x-access-token:$T@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git"
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
