#!/data/data/com.termux/files/usr/bin/bash
# money/FULL.sh — الأمر الواحد الكامل والنهائي
# مصادقة (بالمتصفح) + فحص + تجميع + دمج + رفع على دفعات + وكلاء + تحقق + إصلاح
# الاستخدام: bash money/FULL.sh    |    bash money/FULL.sh --check
set -u
cd "$(dirname "$0")/.." || exit 1

BR=main; OWNER=alisalimax3; NAME=alisalimax3.github.io
REAL="https://$OWNER.github.io"; CLEAN="https://github.com/$OWNER/$NAME.git"
CHECK=0; [ "${1:-}" = "--check" ] && CHECK=1
BASE=""; USER="$OWNER"
say(){ printf '%s\n' "$*"; }
die(){ say "✗ $*"; exit 1; }

say ""
say "═════ FULL · مصادقة + تجميع + رفع + وكلاء + تحقق ═════"
[ -d .git ] || die "مش مستودع git"
command -v gh >/dev/null 2>&1 || die "gh مش متسطّب"

if [ "$CHECK" = 0 ]; then

  # ── 1 · مصادقة بالمتصفح (كود لمرة واحدة) ─────────────────
  if [ -z "$(gh auth token 2>/dev/null)" ]; then
    say ""
    say "► هيفتح المتصفح ويظهر كود. افتح الرابط، الصق الكود، وافق Authorize."
    say "  مفيش توكن ولا باسورد بتكتبه."
    gh auth login --hostname github.com --git-protocol https --web || true
    [ -n "$(gh auth token 2>/dev/null)" ] || die "المصادقة ماكملتش"
  else
    say "✓ مسجّل دخول — مفيش كود مطلوب"
  fi
  USER=$(gh api user --jq .login 2>/dev/null || echo "$OWNER")
  say "✓ الحساب: $USER"

  # ── 2 · نظّف الأقفال وبقايا الـ rebase ────────────────────
  pkill -f 'money/heal.mjs' 2>/dev/null; pkill -f 'money/panel.mjs' 2>/dev/null
  pkill -f 'money/agent.mjs' 2>/dev/null; pkill -f 'money/tick.mjs' 2>/dev/null
  pkill -f 'money/agentd.mjs' 2>/dev/null
  sleep 1
  git rebase --abort >/dev/null 2>&1
  git merge --abort  >/dev/null 2>&1
  rm -rf .git/rebase-merge .git/rebase-apply 2>/dev/null
  rm -f .git/index.lock .git/MERGE_HEAD 2>/dev/null
  say "✓ الأقفال اتنضّفت"

  # ── 3 · ربط git + إعدادات مقاومة للانقطاع ─────────────────
  git config --global --unset-all credential.helper >/dev/null 2>&1
  git config --local  --unset-all credential.helper >/dev/null 2>&1
  rm -f "$HOME/.git-credentials" 2>/dev/null
  gh auth setup-git >/dev/null 2>&1
  git remote set-url origin "$CLEAN"
  git config http.postBuffer 524288000
  git config http.version HTTP/1.1
  git config http.lowSpeedLimit 0
  git config http.lowSpeedTime 999999
  git config pack.threads 1
  git config core.compression 6
  git config core.fsyncObjectFiles false
  git config gc.auto 0
  say "✓ git مربوط بـ gh + إعدادات الشبكة"

  # ── 4 · خفّف المستودع (ملفات مش لازمة للرفع) ──────────────
  touch .gitignore
  for p in 'tools.bak.*/' 'snapshots/' 'money/.heal/backups/' 'money/logs/' '*.log'; do
    grep -qxF "$p" .gitignore 2>/dev/null || echo "$p" >> .gitignore
  done
  git rm -r --cached --ignore-unmatch -q tools.bak.* snapshots money/.heal/backups money/logs >/dev/null 2>&1
  say "✓ .gitignore اتظبط"

  # ── 5 · مزامنة ───────────────────────────────────────────
  git fetch origin "$BR" --prune >/dev/null 2>&1 || true
  if git rev-parse --verify --quiet "origin/$BR" >/dev/null; then
    BASE=$(git rev-parse "origin/$BR")
    BEHIND=$(git rev-list --count "HEAD..$BASE" 2>/dev/null || echo 0)
    AHEAD=$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)
    say "▸ محلي متقدّم: $AHEAD · الريموت متقدّم: $BEHIND"
    if [ "$BEHIND" -gt 0 ]; then
      git -c rebase.autoStash=true pull --rebase origin "$BR" >/dev/null 2>&1 \
        || { git rebase --abort >/dev/null 2>&1; git pull --no-rebase --no-edit origin "$BR" >/dev/null 2>&1; }
      BASE=$(git rev-parse "origin/$BR")
    fi
  else
    BASE=""
  fi
  say "✓ المزامنة خلصت"

  # ── 6 · إعادة بناء الكوميتات المحلية كدفعات صغيرة ─────────
  if [ -n "$BASE" ]; then
    AHEAD=$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)
    if [ "$AHEAD" -gt 0 ]; then
      say "▸ فكّ $AHEAD كوميت لإعادة الرفع على دفعات (المحتوى محفوظ)"
      git reset --soft "$BASE"; git reset -q
    fi
  fi
fi

# ── دفع دفعة واحدة ─────────────────────────────────────────
push_try(){
  if GIT_TERMINAL_PROMPT=0 git push --no-thin origin "HEAD:refs/heads/$BR" >/tmp/_p.log 2>&1; then return 0; fi
  if grep -qE 'non-fast-forward|fetch first|rejected' /tmp/_p.log 2>/dev/null; then
    GIT_TERMINAL_PROMPT=0 git push --no-thin --force-with-lease origin "HEAD:refs/heads/$BR" >/tmp/_p.log 2>&1 && return 0
  fi
  return 1
}

# ── رفع على دفعات متدرّجة ──────────────────────────────────
batch_push(){
  local chunk=${1:-1200}
  git add -A -- . >/dev/null 2>&1
  local -a FILES
  mapfile -d '' FILES < <(git diff --cached --name-only -z)
  git reset -q
  local total=${#FILES[@]}
  if [ "$total" -eq 0 ]; then say "✓ مفيش ملفات معلّقة للرفع"; return 0; fi
  say "▸ ملفات للرفع: $total · حجم الدفعة: $chunk"
  local i=0 fails=0 n=0 j
  while [ "$i" -lt "$total" ]; do
    j=$(( i + chunk )); [ "$j" -gt "$total" ] && j=$total
    git add -A -- "${FILES[@]:$i:$((j-i))}" >/dev/null 2>&1
    git -c user.name="$USER" -c user.email="$USER@users.noreply.github.com" \
        commit -q -m "build: batch $((n+1)) [$j/$total]" >/dev/null 2>&1
    if push_try; then
      say "  ✓ $j/$total اترفع"; i=$j; n=$((n+1)); fails=0
    else
      fails=$((fails+1))
      say "  ✗ فشلت الدفعة $j/$total — $(tail -1 /tmp/_p.log 2>/dev/null | cut -c1-90)"
      git reset -q --soft HEAD~1 2>/dev/null || git reset -q --soft "$BASE" 2>/dev/null
      git reset -q
      if [ "$chunk" -gt 150 ]; then chunk=$(( chunk / 2 )); say "  ⚠ قلّلت الدفعة إلى $chunk ملف"; fi
      [ "$fails" -ge 8 ] && { say "  ✗ توقفت عند $i/$total"; return 1; }
      sleep 5
    fi
  done
  return 0
}

if [ "$CHECK" = 0 ]; then
  # ── 7 · رفع الحالة الحالية على دفعات ──────────────────────
  say ""
  say "▸ رفع الحالة الحالية (دفعات)…"
  batch_push 1200 || true

  # ── 8 · التجميع الكامل + الواجهة + الدمج (one.mjs) ────────
  if [ -f money/one.mjs ]; then
    say ""
    say "▸ تشغيل خط الإنتاج money/one.mjs …"
    node money/one.mjs || say "⚠ one.mjs خلص بكود خطأ — بكمّل"
  fi

  # ── 9 · رفع البواقي ──────────────────────────────────────
  say ""
  say "▸ رفع البواقي…"
  batch_push 800 || true

  git remote set-url origin "$CLEAN"
fi

# ── 10 · الوكلاء ───────────────────────────────────────────
mkdir -p money/logs
if ! pgrep -f 'money/agentd.mjs' >/dev/null 2>&1; then
  say "▸ تشغيل الوكلاء…"
  for f in heal.mjs panel.mjs agent.mjs tick.mjs; do
    [ -f "money/$f" ] || continue
    if [ "$f" = heal.mjs ]; then
      nohup node "money/$f" --watch >> "money/logs/${f%.mjs}.log" 2>&1 &
    else
      nohup node "money/$f" >> "money/logs/${f%.mjs}.log" 2>&1 &
    fi
  done
  sleep 2
fi
say "✓ الوكلاء: $(pgrep -f 'money/' | grep -v FULL.sh | wc -l) عملية"

# ── 11 · تحقق حي ───────────────────────────────────────────
say ""
say "══ تحقق حي (لحد 6 دقايق) ══"
T=(/ /index.html /grid.js /wallet.js /grid.css /tmdb-img-shim.js /vn-panel.html /vn-wallet.html /withdraw.html)
good=0; r=0
while [ "$r" -lt 24 ]; do
  r=$((r+1)); good=0; line=""
  for t in "${T[@]}"; do
    s=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "$REAL$t")
    [ "$s" = "200" ] && good=$((good+1))
    line="$line $t=$s"
  done
  say " جولة $r [$good/${#T[@]}]$line"
  [ "$good" -eq "${#T[@]}" ] && break
  sleep 15
done
say ""
if [ "$good" -eq "${#T[@]}" ]; then say "✓✓ الموقع حيّ بالكامل — كل الملفات 200"
else say "⚠ ناقص $(( ${#T[@]} - good )) — كرر: bash money/FULL.sh --check"; fi
say "► $REAL"
say "► اللوحة $REAL/vn-panel.html · المحفظة $REAL/vn-wallet.html · السحب $REAL/withdraw.html"
