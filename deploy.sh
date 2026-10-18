#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
BR="${1:-main}"; MSG="${2:-auto $(date -u +%FT%TZ)}"
git add -A; git diff --cached --quiet || git commit -q -m "$MSG"
for i in 1 2 3 4 5 6; do
  git fetch -q origin "$BR" 2>/dev/null
  if ! git rebase -q "origin/$BR" >/dev/null 2>&1; then git rebase --abort 2>/dev/null; git reset -q --soft "origin/$BR" 2>/dev/null && git commit -q -m "$MSG"; fi
  OUT=$(git push origin "HEAD:$BR" 2>&1); RC=$?
  if [ $RC -eq 0 ]; then L=$(git rev-parse HEAD); Rm=$(git ls-remote origin "refs/heads/$BR" 2>/dev/null|cut -f1); [ "$L" = "$Rm" ] && { echo "  ✓ نُشر $L"; exit 0; }; fi
  echo "    $(echo "$OUT"|head -1)"; sleep $((i*6))
done; echo "  ✗ فشل"; exit 1
