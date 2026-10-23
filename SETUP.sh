#!/data/data/com.termux/files/usr/bin/bash
# SETUP — الأمر الواحد: تفويض · شفاء · ربط · نشر · وكيل · مراقبة
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
pkill -f agentd.sh 2>/dev/null; sleep 1; rm -f .git/index.lock 2>/dev/null
bash FINAL.sh 2>&1 | tail -25
bash GO2.sh   2>&1 | tail -25
bash WATCH2.sh
