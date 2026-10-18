#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
command -v termux-wake-lock >/dev/null && termux-wake-lock
while true; do
  git pull --rebase -q 2>/dev/null
  bash tools/agent_cycle.sh >/dev/null 2>&1
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "agentd $(date -u +%FT%TZ)" 2>/dev/null
  git push -q 2>/dev/null || { git pull --rebase -q 2>/dev/null; git push -q 2>/dev/null; }
  sleep 300
done
