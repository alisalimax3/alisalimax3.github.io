#!/data/data/com.termux/files/usr/bin/bash
set -u
cd ~/cinehub3099 || exit 1
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR"

echo "── 1) إنهاء سبب الفشل: /tmp ──"
[ -d /tmp ] || { mkdir -p "$PREFIX/tmp" 2>/dev/null; ln -sfn "$PREFIX/tmp" /tmp 2>/dev/null; }
sed -i "s#/tmp/gp\.err#$D/.gp.err#g" restart.sh
grep -q 'export TMPDIR' restart.sh || \
  sed -i "s#^set -u\$#set -u\nexport TMPDIR=\"$D/.tmp\"; mkdir -p \"\$TMPDIR\"#" restart.sh
printf 'node_modules/\nbackups/\n*.log\n.gh-token\n.license-secret\n.gp.err\n.tmp/\n__pycache__/\n*.tgz\n' > .gitignore
grep -n 'gp.err\|TMPDIR' restart.sh
: > "$D/.gp.err" && echo "  ✓ الكتابة في .gp.err تعمل"

echo "── 2) دفع مرئي حقيقي ──"
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
T="$(tr -d '\n\r ' < .gh-token)"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io.git"
git add -A; git rm --cached -q --ignore-unmatch .gh-token 2>/dev/null
git diff --cached --quiet || git commit -q -m "fix: TMPDIR + robust push $(date -u +%FT%TZ)"
if bash deploy.sh main "auto $(date -u +%FT%TZ)"; then echo "  ✓✓ الدفع نجح فعلياً"; else echo "  ✗ فشل:"; cat "$D/.gp.err"; fi

echo "── 3) تشغيل دورة كاملة ──"
bash restart.sh
