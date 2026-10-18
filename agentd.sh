#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
while :; do
  for s in revenue_sync hits_report money dashboard vault; do
    [ -f "tools/$s.py" ] && python3 "tools/$s.py" >> logs/agentd.log 2>&1
  done
  git add -A >/dev/null 2>&1; git -c user.email=a@c.local -c user.name=agent commit -m "daemon" >/dev/null 2>&1
  git push --force origin main >/dev/null 2>&1
  sleep 1800
done
