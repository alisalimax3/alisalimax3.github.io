#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 · ناشر تيليجرام — bash tg.sh [عدد]  أو  bash tg.sh --watch
cd ~/cinehub3099 || exit 1
[ -f config.env ] && { set -a; . ./config.env; set +a; }
if [ "${1:-}" = "--watch" ]; then
  while true; do python3 tgbot.py 2; sleep 7200; done
else
  python3 tgbot.py "${1:-1}"
fi
