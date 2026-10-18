#!/data/data/com.termux/files/usr/bin/bash
# تشغيل متسلسل: أنت تلصق وتضغط Enter فقط
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR"; export GHTMP="$TMPDIR"
G=$'\033[32m';Y=$'\033[33m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
LIST="${1:-aads adsterra exoclick monetag}"
printf '\n%s╔═══════════════════════════════════════════════════════╗\n' "$B"
printf '║  تفويض كامل: أنت تلصق وتضغط Enter — والباقي تلقائي  ║\n'
printf '╚═══════════════════════════════════════════════════════╝%s\n' "$N"
for t in $LIST; do
  bash COACH.sh "$t" || true
  printf '\n%sاضغط Enter للموقع التالي · q للخروج · إعادة: bash COACH.sh %s%s › ' "$D" "$t" "$N"
  read -r x </dev/tty 2>/dev/null || x=""
  [ "$x" = "q" ] && break
done
printf '\n%s✓ الربط والنشر النهائي…%s\n' "$G" "$N"
bash PUSH.sh 2>&1 | tail -3
printf '\n  الخزينة : https://alisalimax3.github.io/wallet.html\n'
printf '  الأموال : https://alisalimax3.github.io/money.html\n'
printf '  سجّل هنا ما فعلته: %s\n' "$(ls -t logs/coach.* 2>/dev/null | head -1)"
