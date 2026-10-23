#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
D="$(pwd)"
O="alkazmybwhwr-dot"; R="alisalimax3.github.io"; B="main"
rm -f "$D/.git/index.lock" ~/.git/index.lock 2>/dev/null
if [ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$D" ]; then
  rm -rf "$D/.git"; git init -q "$D"; git symbolic-ref HEAD refs/heads/$B
fi
[ -f .gh-token ] || { echo "✗ نفّذ: python3 auth.py"; exit 1; }
T="$(tr -d '\n\r ' < .gh-token)"
printf 'node_modules/\nbackups/\n*.log\n.gh-token\n__pycache__/\n*.tgz\n' > .gitignore
git config user.email "cinehub@local"; git config user.name "CineHub"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${O}/${R}.git"
git add -A
if git ls-files | grep -q '^cinehub3099/'; then echo "  ! المسارات مسبوقة — خطأ"; exit 1; fi
git rm --cached -q --ignore-unmatch .gh-token 2>/dev/null
if git diff --cached --quiet; then echo "  لا تغييرات"; else git commit -q -m "publish $(date -u +%FT%TZ)"; fi
n=0; until bash deploy.sh main "auto $(date -u +%FT%TZ)"; do n=$((n+1)); [ $n -ge 5 ] && { echo "✗ فشل"; exit 1; }; sleep $((n*3)); done
echo "✓ نُشر → https://${O}.github.io"
