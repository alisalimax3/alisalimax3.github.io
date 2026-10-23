#!/data/data/com.termux/files/usr/bin/bash
# money/LIVE.sh — تسجيل حقيقي حيّ + مفاتيح + ربط + رفع + وكلاء
set -u
REPO="/data/data/com.termux/files/home/cinehub3099"; cd "$REPO" || exit 1
BR=main; PLOG="$REPO/.git/_push.log"
say(){ printf '%s\n' "$*"; }
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

say ""; say "═════ LIVE · وكيل حقيقي مباشر ═════"
[ -n "$(gh auth token 2>/dev/null)" ] || { say "► هيفتح المتصفح ويظهر كود — الصقه ووافق"; gh auth login --hostname github.com --git-protocol https --web; }

for p in heal panel agent tick agentd realagent liveagent; do pkill -f "money/$p.mjs" 2>/dev/null; done; sleep 1
git rebase --abort >/dev/null 2>&1; git merge --abort >/dev/null 2>&1
rm -rf .git/rebase-merge .git/rebase-apply 2>/dev/null; rm -f .git/index.lock .git/MERGE_HEAD 2>/dev/null
gh auth setup-git >/dev/null 2>&1
git config http.version HTTP/1.1; git config http.postBuffer 524288000
git config http.lowSpeedLimit 0; git config http.lowSpeedTime 999999
git remote set-url origin "https://github.com/alisalimax3/alisalimax3.github.io.git" 2>/dev/null
say "✓ المصادقة والقفل نضاف"

# ── التنفيذ الحيّ ──
node money/liveagent.mjs

# ── رفع النتائج ──
say "▸ رفع النتائج…"
git add -A
git -c user.name=alisalimax3 -c user.email=alisalimax3@users.noreply.github.com \
    commit -q -m "agent: live registration + keys + links + wallet" 2>/dev/null || true
git fetch origin "$BR" >/dev/null 2>&1 || true
git merge-base --is-ancestor "origin/$BR" HEAD 2>/dev/null || {
  git -c rebase.autoStash=true pull --rebase origin "$BR" >/dev/null 2>&1 \
    || { git rebase --abort >/dev/null 2>&1; git pull --no-rebase --no-edit origin "$BR" >/dev/null 2>&1 || git merge --abort >/dev/null 2>&1; }; }
PUSHED=0
if GIT_TERMINAL_PROMPT=0 git push --no-thin origin "HEAD:$BR" >"$PLOG" 2>&1; then PUSHED=1
elif grep -qE 'rejected|non-fast|fetch first|stale' "$PLOG"; then
  GIT_TERMINAL_PROMPT=0 git push --no-thin --force-with-lease origin "HEAD:$BR" >"$PLOG" 2>&1 && PUSHED=1; fi
[ "$PUSHED" = 1 ] && say "✓ اترفع" || say "⚠ الرفع فشل: $(tail -1 "$PLOG" 2>/dev/null | cut -c1-90)"

# ── الوكلاء ──
mkdir -p money/logs
for f in heal.mjs panel.mjs agent.mjs tick.mjs; do
  [ -f "money/$f" ] || continue
  if [ "$f" = heal.mjs ]; then nohup node "money/$f" --watch >> "money/logs/${f%.mjs}.log" 2>&1 &
  else nohup node "money/$f" >> "money/logs/${f%.mjs}.log" 2>&1 & fi
done
[ -f money/realagent.mjs ] && nohup node money/realagent.mjs >> money/logs/realagent.log 2>&1 &
sleep 2
say "✓ الوكلاء: $(pgrep -f 'money/' | grep -v LIVE.sh | wc -l) عملية"

# ── تحقق ──
say ""; say "══ تحقق حي ══"
for t in / /movies.html /links.json /keys.json /wallet.json /vn-panel.html; do
  s=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "https://alisalimax3.github.io$t")
  [ "$s" = "200" ] && printf ' %-16s %s\n' "$t" "200 ✓" || printf ' %-16s %s\n' "$t" "$s"
done
say ""
say "► التطبيق: https://alisalimax3.github.io/movies.html"
say "► المفاتيح: https://alisalimax3.github.io/keys.json"
say "► الروابط : https://alisalimax3.github.io/links.json"
say "► المحفظة: https://alisalimax3.github.io/vn-wallet.html"
command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
