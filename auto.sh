#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 · auto.sh — يعمل وحده كل 3 ساعات
#   nohup bash auto.sh >auto.log 2>&1 &
cd ~/cinehub3099 || exit 1
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR"
command -v termux-wake-lock >/dev/null && termux-wake-lock
while true; do
  printf '\n=== %s ===\n' "$(date -u +%FT%TZ)"
  python3 content/build.py 2>&1 | tail -12
  python3 content/render.py 2>&1 | tail -4
  python3 content/expand.py 2>&1 | tail -3
  python3 content/rss.py 2>&1 | tail -1
  python3 - <<'PY'
import os,re
F=[]
for r,d,f in os.walk('.'):
    d[:]=[x for x in d if x not in ('.git','node_modules','backups','.tmp','content')]
    F+=[os.path.join(r,x) for x in f if x.endswith('.html')]
SC=['/nav.js']
for p in F:
    s=open(p,encoding='utf-8').read()
    if 'nav.js' in s: continue
    s=s.replace('</body>','<script src="/nav.js" defer></script>\n</body>',1) if '</body>' in s else s+'<script src="/nav.js" defer></script>'
    open(p,'w',encoding='utf-8').write(s)
PY
  python3 spread.py 2>&1 | tail -6
  T="$(tr -d '\n\r ' < .gh-token)"
  git remote set-url origin "https://x-access-token:${T}@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git" 2>/dev/null || \
  git remote add origin "https://x-access-token:${T}@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git"
  git add -A; git rm --cached -q --ignore-unmatch .gh-token .license-secret 2>/dev/null
  git diff --cached --quiet || git commit -q -m "auto: content refresh $(date -u +%FT%TZ)"
  bash deploy.sh main "auto $(date -u +%FT%TZ)"&& echo "  ✓ نُشر" || { echo "  ✗"; cat "$D/.gp.err"; }
  sleep 10800
done
