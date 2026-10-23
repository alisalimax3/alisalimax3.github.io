#!/data/data/com.termux/files/usr/bin/bash
# money/push-hard.sh — رفع مقاوم لـ HTTP 408 بدفع تدريجي
set -u
cd "$(dirname "$0")/.." || exit 1
BR=main

# ── 1) إعدادات الشبكة المقاومة للانقطاع ──
git config http.postBuffer 524288000
git config http.version HTTP/1.1
git config http.lowSpeedLimit 0
git config http.lowSpeedTime 999999
git config pack.threads 1
git config pack.windowMemory 16m
git config core.compression 6
git config core.fsyncObjectFiles false
echo "✓ إعدادات الشبكة اتظبطت"

# ── 2) ريموت نضيف + مزامنة ──
git remote set-url origin https://github.com/alisalimax3/alisalimax3.github.io.git
git fetch origin "$BR" --prune 2>/dev/null || true
if git rev-parse --verify --quiet "origin/$BR" >/dev/null; then
  BEHIND=$(git rev-list --count "HEAD..origin/$BR")
  if [ "$BEHIND" -gt 0 ]; then
    echo "▸ الريموت متقدّم بـ $BEHIND — بمزامنة…"
    git -c rebase.autoStash=true pull --rebase origin "$BR" \
      || { git rebase --abort 2>/dev/null; git pull --no-rebase --no-edit origin "$BR" || git merge --abort; }
  fi
fi

# ── 3) كوميت أي تغييرات معلّقة ──
git add -A
if [ -n "$(git status --porcelain)" ]; then
  git -c user.name=alisalimax3 -c user.email=alisalimax3@users.noreply.github.com \
      commit -m "build: go-live" >/dev/null && echo "✓ اتعمل commit"
fi

# ── 4) قائمة الكوميتات المعلّقة (الأقدم أولاً) ──
if git rev-parse --verify --quiet "origin/$BR" >/dev/null; then
  mapfile -t PENDING < <(git rev-list --reverse "origin/$BR..HEAD")
else
  mapfile -t PENDING < <(git rev-list --reverse HEAD)
fi
TOTAL=${#PENDING[@]}
echo "▸ كوميتات معلّقة: $TOTAL"
[ "$TOTAL" -eq 0 ] && { echo "✓ مفيش حاجة للرفع"; exit 0; }

# ── 5) دفع تدريجي — الدفعة بتصغر لو فشلت ──
step=10; i=0; fails=0
while [ "$i" -lt "$TOTAL" ]; do
  j=$(( i + step )); [ "$j" -gt "$TOTAL" ] && j=$TOTAL
  sha=${PENDING[$(( j - 1 ))]}
  printf '▸ دفع حتى %s/%s … ' "$j" "$TOTAL"
  if GIT_TERMINAL_PROMPT=0 git push --no-thin origin "$sha:refs/heads/$BR" >/tmp/_push.log 2>&1; then
    echo "✓"; i=$j; fails=0
  else
    echo "✗"; tail -2 /tmp/_push.log | sed 's/^/    /'
    fails=$(( fails + 1 ))
    if [ "$step" -gt 1 ] && [ "$fails" -ge 2 ]; then
      step=$(( step / 2 )); [ "$step" -lt 1 ] && step=1
      echo "    ⚠ قلّلت الدفعة إلى $step كوميت"; fails=0
    elif [ "$step" -eq 1 ] && [ "$fails" -ge 4 ]; then
      echo "    ⚠ وقفت — الكوميت $j لوحده تقيل"; break
    fi
    sleep 4
  fi
done

# ── 6) محاولة أخيرة + الحالة ──
echo "▸ محاولة أخيرة للـ HEAD …"
GIT_TERMINAL_PROMPT=0 git push --no-thin origin "HEAD:refs/heads/$BR" >/dev/null 2>&1 || true

LEFT=$(git rev-list --count "origin/$BR..HEAD" 2>/dev/null || echo "?")
echo "▸ كوميتات لسه معلّقة: $LEFT"
if [ "$LEFT" = "0" ]; then
  echo "✓✓ اترفع كله"
  [ -x money/AGENTD.sh ] && bash money/AGENTD.sh
else
  echo "⚠ فاضل $LEFT — كرر: bash money/push-hard.sh"
fi
