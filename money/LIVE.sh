#!/data/data/com.termux/files/usr/bin/bash
set -u
REPO="/data/data/com.termux/files/home/cinehub3099"; cd "$REPO" || exit 1
BR=main; PLOG="$REPO/.git/_push.log"; say(){ printf '%s\n' "$*"; }
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

say ""; say "═════ LIVE v2 · وكيل واسع + سحابة ═════"
[ -n "$(gh auth token 2>/dev/null)" ] || { say "► كود بالمتصفح — الصقه ووافق"; gh auth login --hostname github.com --git-protocol https --web; }
for p in heal panel agent tick agentd realagent liveagent wideagent; do pkill -f "money/$p.mjs" 2>/dev/null; done; sleep 1
git rebase --abort >/dev/null 2>&1; git merge --abort >/dev/null 2>&1
rm -rf .git/rebase-merge .git/rebase-apply 2>/dev/null; rm -f .git/index.lock .git/MERGE_HEAD 2>/dev/null
gh auth setup-git >/dev/null 2>&1
git config http.version HTTP/1.1; git config http.postBuffer 524288000
git remote set-url origin "https://github.com/alisalimax3/alisalimax3.github.io.git" 2>/dev/null
git fetch origin "$BR" >/dev/null 2>&1 || true
git merge-base --is-ancestor "origin/$BR" HEAD 2>/dev/null || {
  git -c rebase.autoStash=true pull --rebase origin "$BR" >/dev/null 2>&1 \
   || { git rebase --abort >/dev/null 2>&1; git pull --no-rebase --no-edit origin "$BR" >/dev/null 2>&1 || git merge --abort >/dev/null 2>&1; }; }
say "✓ جاهز"

node money/wideagent.mjs --live

say "▸ رفع…"
git add -A
git -c user.name=alisalimax3 -c user.email=alisalimax3@users.noreply.github.com \
    commit -q -m "agent: wide live run + keys + links + harvest" 2>/dev/null || true
git fetch origin "$BR" >/dev/null 2>&1 || true
git merge-base --is-ancestor "origin/$BR" HEAD 2>/dev/null || git -c rebase.autoStash=true pull --rebase origin "$BR" >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
P=0
GIT_TERMINAL_PROMPT=0 git push --no-thin origin "HEAD:$BR" >"$PLOG" 2>&1 && P=1
[ "$P" = 0 ] && { grep -qE 'rejected|non-fast|fetch first|stale' "$PLOG" && GIT_TERMINAL_PROMPT=0 git push --no-thin --force-with-lease origin "HEAD:$BR" >"$PLOG" 2>&1 && P=1; }
[ "$P" = 1 ] && say "✓ اترفع" || say "⚠ الرفع: $(tail -1 "$PLOG" | cut -c1-80)"

mkdir -p money/logs
for f in heal.mjs panel.mjs agent.mjs tick.mjs; do [ -f "money/$f" ] || continue
  if [ "$f" = heal.mjs ]; then nohup node "money/$f" --watch >> "money/logs/${f%.mjs}.log" 2>&1 &
  else nohup node "money/$f" >> "money/logs/${f%.mjs}.log" 2>&1 & fi; done
nohup node money/wideagent.mjs >> money/logs/wideagent.log 2>&1 &
sleep 2; say "✓ الوكلاء: $(pgrep -f 'money/' | grep -v LIVE.sh | wc -l) عملية"

chk(){ local t="$1" s=""; local k; for k in 1 2 3 4 5; do
  s=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "https://alisalimax3.github.io$t")
  [ "$s" = 200 ] && { echo 200; return; }; sleep 12; done; echo "${s:-000}"; }
say ""; say "══ تحقق (بإعادة محاولة — Pages بياخد وقت) ══"
for t in / /movies.html /links.json /keys.json /wallet.json /vn-panel.html /vn-wallet.html; do
  s=$(chk "$t"); [ "$s" = 200 ] && printf ' %-16s %s\n' "$t" "200 ✓" || printf ' %-16s %s\n' "$t" "$s"
done
say ""; say "► https://alisalimax3.github.io/movies.html · /keys.json · /links.json · /vn-wallet.html"
command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
