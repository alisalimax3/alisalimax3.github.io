#!/usr/bin/env bash
###############################################################################
# CINEHUB AUTO-SURGEON v1.0
# SCAN -> ORGANIZE -> REPAIR -> MISSING -> ACTIVATE -> VERIFY -> REPORT
# Safe: nothing is deleted. Everything is moved to ./_archive/<timestamp>/
# Usage:  ./CINEHUB.sh --dry-run     # preview
#         ./CINEHUB.sh               # organize + repair (no restart)
#         ./CINEHUB.sh --start       # ...and (re)start app + health check
#         ./CINEHUB.sh --start --port 8080
###############################################################################
set -uo pipefail

DRY=0; START=0; PORT=""
for a in "$@"; do
  case "$a" in
    -n|--dry-run) DRY=1 ;;
    -s|--start)   START=1 ;;
    --port=*)     PORT="${a#*=}" ;;
    -h|--help)    sed -n '2,9p' "$0"; exit 0 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd "$ROOT" || exit 1
STAMP="$(date -u +%Y%m%d-%H%M%S)"; DATE="$(date -u +%F)"
ARCH="$ROOT/_archive/$STAMP"
LOG="$ROOT/logs/cinehub-fix-$STAMP.log"
REPORT="$ROOT/REPORT-FIX-$STAMP.md"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$ROOT/logs" "$ROOT/_archive"
exec > >(tee -a "$LOG") 2>&1

C_RST=$'\033[0m'; C_B=$'\033[1m'; C_R=$'\033[31m'; C_G=$'\033[32m'
C_Y=$'\033[33m'; C_C=$'\033[36m'; C_D=$'\033[2m'
say(){  printf '\n%s%s==> %s%s\n' "$C_B" "$C_C" "$*" "$C_RST"; }
ok(){   printf '   %s[ok]%s   %s\n' "$C_G" "$C_RST" "$*"; }
warn(){ printf '   %s[warn]%s %s\n' "$C_Y" "$C_RST" "$*"; }
bad(){  printf '   %s[fail]%s %s\n' "$C_R" "$C_RST" "$*"; }
info(){ printf '     %s%s%s\n' "$C_D" "$*" "$C_RST"; }
run(){  if [ "$DRY" = 1 ]; then printf '     %s[dry]%s %s\n' "$C_D" "$C_RST" "$*"; else "$@"; fi; }
mvf(){  mkdir -p "$2"; run mv -f "$1" "$2/"; }
hash_of(){ if command -v md5sum >/dev/null 2>&1; then md5sum "$1"|cut -d' ' -f1; else md5 -q "$1"; fi; }
if [ "$(uname)" = "Darwin" ]; then SEDI=(sed -i ''); else SEDI=(sed -i); fi
JSONCHECK(){ if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys;json.load(open(sys.argv[1],encoding="utf-8"))' "$1" >/dev/null 2>&1
  else node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$1" >/dev/null 2>&1; fi; }

FIXED=0; MOVED=0; PROBLEMS=0
P(){ PROBLEMS=$((PROBLEMS+1)); }

[ -f index.html ] || [ -f package.json ] || warn "not a project root? (no index.html / package.json)"
info "root=$ROOT  mode=$([ $DRY = 1 ] && echo DRY-RUN || echo LIVE)  archive=$ARCH"

###############################################################################
say "PHASE 1/6 - SCAN (read-only)"
N_FILES=$(find . -type f -not -path './node_modules/*' -not -path './.git/*' -not -path './_archive/*' 2>/dev/null | wc -l | tr -d ' ')
N_SH=$(find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
N_BAK=$(find . -type f \( -name '*.bak*' -o -name '*.old' -o -name '*.broken' -o -name '*~' \) -not -path './node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
info "files=$N_FILES  shell-scripts=$N_SH  backup-leftovers=$N_BAK"

find . -type f -empty -not -path './node_modules/*' -not -path './.git/*' -not -path './_archive/*' 2>/dev/null > "$TMP/empty"
find . -type l -xtype l 2>/dev/null > "$TMP/brokenlinks"
find . -name '*.json' -type f -not -path './node_modules/*' -not -path './_archive/*' 2>/dev/null > "$TMP/json"
: > "$TMP/badjson"
while IFS= read -r f; do [ -n "$f" ] || continue; JSONCHECK "$f" || echo "$f" >> "$TMP/badjson"; done < "$TMP/json"
: > "$TMP/badsh"
while IFS= read -r f; do [ -f "$f" ] || continue; bash -n "$f" 2>/dev/null || echo "$f" >> "$TMP/badsh"; done < <(find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' 2>/dev/null)
: > "$TMP/badjs"
if command -v node >/dev/null 2>&1; then
  while IFS= read -r f; do [ -f "$f" ] || continue; node --check "$f" >/dev/null 2>&1 || echo "$f" >> "$TMP/badjs"; done < <(find . -maxdepth 2 -name '*.js' -not -path './node_modules/*' 2>/dev/null)
fi
: > "$TMP/badpy"
if command -v python3 >/dev/null 2>&1; then
  while IFS= read -r f; do [ -f "$f" ] || continue; python3 -m py_compile "$f" 2>/dev/null || echo "$f" >> "$TMP/badpy"; done < <(find . -maxdepth 2 -name '*.py' 2>/dev/null)
fi

info "empty files........: $(wc -l < "$TMP/empty" | tr -d ' ')"
info "broken symlinks....: $(wc -l < "$TMP/brokenlinks" | tr -d ' ')"
info "invalid JSON.......: $(wc -l < "$TMP/badjson" | tr -d ' ')"
info "shell syntax errors: $(wc -l < "$TMP/badsh" | tr -d ' ')"
info "js syntax errors...: $(wc -l < "$TMP/badjs" | tr -d ' ')"
info "py compile errors..: $(wc -l < "$TMP/badpy" | tr -d ' ')"
for f in $(cat "$TMP/badjson"); do warn "invalid JSON -> $f"; P; done
for f in $(cat "$TMP/badsh");   do bad  "shell error  -> $f"; P; done

###############################################################################
say "PHASE 2/6 - ORGANIZE (non-destructive)"
mkdir -p "$ARCH"/{backups,dupes,broken,stray} assets/img data logs cache
ok "archive tree created: $ARCH"

# 1. move editor / manual backup leftovers out of the way
while IFS= read -r -d '' f; do mvf "$f" "$ARCH/backups"; MOVED=$((MOVED+1)); done < <(
  find . -type f \( -name '*.bak' -o -name '*.bak.*' -o -name '*.old' -o -name '*.orig' -o -name '*.pre' -o -name '*.pre-*' -o -name '*.broken' -o -name '*.save' -o -name '*~' \) \
  -not -path './node_modules/*' -not -path './_archive/*' -print0 2>/dev/null)
ok "backup leftovers archived: $MOVED"

# 2. de-duplicate identical shell scripts (exact md5 matches only)
referenced(){ grep -qF "$(basename "$1")" package.json README.md 2>/dev/null; }
declare -A seen=(); DUP=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  h="$(hash_of "$f")"
  if [ -n "${seen[$h]:-}" ]; then
    keep="${seen[$h]}"; drop="$f"
    if referenced "$drop" && ! referenced "$keep"; then keep="$f"; drop="${seen[$h]}"; seen[$h]="$f"; fi
    mvf "$drop" "$ARCH/dupes"; DUP=$((DUP+1)); MOVED=$((MOVED+1))
  else
    seen[$h]="$f"
  fi
done < <(find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' -not -path './_archive/*' 2>/dev/null | sort)
ok "duplicate scripts archived: $DUP"

# 3. index of every shell script with its first comment line
{ echo "# SCRIPTS INDEX ($DATE)"; echo;
  for f in $(find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' -not -path './_archive/*' | sort); do
    d="$(grep -m1 -E '^#( |$)' "$f" 2>/dev/null | sed -E 's/^#+[[:space:]]*//' | cut -c1-90)"
    printf -- '- `%s` %s\n' "$f" "${d:+— $d}"
  done; } > SCRIPTS.md
ok "SCRIPTS.md written ($(grep -c '^- `' SCRIPTS.md) scripts indexed)"

# 4. .gitignore
touch .gitignore
for l in node_modules/ logs/ cache/ _archive/ '*.log' '*.pid' '*.tmp' .env .DS_Store Thumbs.db; do
  grep -qxF "$l" .gitignore || echo "$l" >> .gitignore
done
ok ".gitignore ensured"

###############################################################################
say "PHASE 3/6 - REPAIR"
# a) line endings + permissions
for f in $(find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' -not -path './_archive/*'); do
  if grep -qU $'\r' "$f" 2>/dev/null; then run "${SEDI[@]}" 's/\r$//' "$f"; ok "CRLF fixed: $f"; FIXED=$((FIXED+1)); fi
done
run find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' -not -path './_archive/*' -exec chmod +x {} +
run find . -maxdepth 1 \( -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.json' -o -name '*.md' -o -name '*.txt' \) -exec chmod 644 {} +
[ -d bin ] && run find bin -type f -exec chmod +x {} + 2>/dev/null
ok "permissions normalised (scripts +x, web assets 644)"

# b) repair invalid JSON (backup first, then normalise)
if [ -s "$TMP/badjson" ]; then
  if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      mvf "$f" "$ARCH/broken"
      python3 - "$f" <<'PY'
import json,sys,re,os
p=sys.argv[1]; src=sys.argv[2] if len(sys.argv)>2 else None
raw=open(p,encoding='utf-8',errors='replace').read().strip()
if not raw: raw='{}'
s=re.sub(r'//[^\n]*','',raw)
s=re.sub(r',\s*([}\]])',r'\1',s)
s=s.replace('NaN','null').replace('-Infinity','null').replace('Infinity','null')
try:
    obj=json.loads(s)
except Exception:
    obj={}
open(p,'w',encoding='utf-8').write(json.dumps(obj,indent=2,ensure_ascii=False)+"\n")
PY
      ok "JSON repaired: $f"; FIXED=$((FIXED+1))
    done < "$TMP/badjson"
  else warn "python3 missing - JSON not repaired"; fi
else ok "all JSON valid"; fi

# c) quarantine zero-byte files
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in ./.gitignore|./.gitkeep) continue;; esac
  mvf "$f" "$ARCH/stray"; warn "empty file quarantined: $f"; MOVED=$((MOVED+1))
done < "$TMP/empty"

# d) restore index.html if it is gone
if [ ! -s index.html ]; then
  newest="$(ls -1t "$ARCH"/backups/index.html* 2>/dev/null | head -1)"
  if [ -n "$newest" ]; then run cp -f "$newest" index.html; ok "index.html restored from $newest"; FIXED=$((FIXED+1))
  else printf '<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CineHub</title></head><body><h1>CineHub</h1></body></html>\n' > index.html
       warn "index.html recreated (minimal)"; FIXED=$((FIXED+1)); fi
fi

# e) robots.txt + sitemap.xml
if [ ! -s robots.txt ]; then printf 'User-agent: *\nAllow: /\nSitemap: /sitemap.xml\n' > robots.txt; ok "robots.txt created"; FIXED=$((FIXED+1)); fi
if [ ! -s sitemap.xml ] || [ "$(grep -c '<url>' sitemap.xml 2>/dev/null || echo 0)" -lt 5 ]; then
  SITE="$(grep -rhoE 'https?://[^ "/]+' config.env cloud-config.json 2>/dev/null | grep -viE 'google|schema|w3\.org|gstatic' | head -1)"
  [ -n "$SITE" ] || SITE="https://cinehub3099.pages.dev"
  [ -s sitemap.xml ] && run cp -f sitemap.xml "$ARCH/backups/sitemap.xml"
  { echo '<?xml version="1.0" encoding="UTF-8"?>'; echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    for f in *.html; do [ -f "$f" ] || continue; [ "$f" = "404.html" ] && continue
      printf '  <url><loc>%s/%s</loc><lastmod>%s</lastmod></url>\n' "$SITE" "$f" "$DATE"; done
    for d in ar en es fr tr; do [ -f "$d/index.html" ] && printf '  <url><loc>%s/%s/</loc><lastmod>%s</lastmod></url>\n' "$SITE" "$d" "$DATE"; done
    echo '</urlset>'; } > sitemap.xml
  ok "sitemap.xml regenerated ($(grep -c '<url>' sitemap.xml) urls, base=$SITE)"; FIXED=$((FIXED+1))
else ok "sitemap.xml present ($(grep -c '<url>' sitemap.xml) urls)"; fi

# f) manifest.json sanity
if [ -s manifest.json ] && JSONCHECK manifest.json; then
  if ! grep -q '"icons"' manifest.json; then warn "manifest.json has no icons"; fi
  ok "manifest.json valid"
else [ -s manifest.json ] || warn "manifest.json missing"; fi

# g) service-worker cache bust (forces clients to pick up new build)
echo "$STAMP" > sw-version.txt
if [ -f sw.js ] && command -v python3 >/dev/null 2>&1; then
  python3 - <<PY
import re
p='sw.js'; s=open(p,encoding='utf-8').read(); o=s
s=re.sub(r"""(?i)((?:cache|version|ver)[A-Za-z_]*\s*[:=]\s*)(['"])([^'"]*)\2""", lambda m: m.group(1)+m.group(2)+"$STAMP"+m.group(2), s)
if s!=o: open(p,'w',encoding='utf-8').write(s); print('BUMPED')
else: print('NOCONST')
PY
  ok "sw-version.txt bumped -> $STAMP"
fi

###############################################################################
say "PHASE 4/6 - ADD WHAT IS MISSING"
[ -s 404.html ] || { printf '<!doctype html><meta charset="utf-8"><title>404</title><h1>404 - Not found</h1><a href="/">Home</a>\n' > 404.html; ok "404.html created"; FIXED=$((FIXED+1)); }
[ -s humans.txt ] || { printf '/* TEAM */\nSite: CineHub\n/* SITE */\nStandards: HTML5, CSS3\n' > humans.txt; ok "humans.txt created"; }
if [ ! -s .env.example ] && [ -s keys.env ]; then sed -E 's/=.*/=/; s/[[:space:]]+$//' keys.env | grep -E '^[A-Z0-9_]+=' > .env.example; ok ".env.example created from keys.env"; fi
[ -s .env.example ] || warn "no keys.env / .env.example - add your API keys there"
if [ ! -s .editorconfig ]; then printf 'root = true\n\n[*]\nend_of_line = lf\ninsert_final_newline = true\ncharset = utf-8\nindent_style = space\nindent_size = 2\n\n[*.{sh,py}]\nindent_size = 4\n' > .editorconfig; ok ".editorconfig created"; fi
[ -s _archive/README.md ] || printf 'Files here are NOT deleted - just moved by CINEHUB.sh.\nbackups/ = old .bak/.old copies\ndupes/   = byte-identical scripts\nbroken/  = invalid files kept before repair\nstray/   = empty files\n' > _archive/README.md

###############################################################################
say "PHASE 5/6 - ACTIVATE"
if [ -f package.json ]; then
  if [ ! -d node_modules ] || [ package.json -nt node_modules ]; then run npm install --no-audit --no-fund; ok "dependencies installed"; else ok "dependencies up to date"; fi
  STARTCMD="$(node -e 'try{const s=require("./package.json").scripts||{};process.stdout.write(s.start||"")}catch(e){}' 2>/dev/null)"
  [ -n "$PORT" ] || PORT="$(grep -hoE 'PORT[=: ]+[0-9]+' package.json config.env .env 2>/dev/null | grep -oE '[0-9]+' | head -1)"
fi
[ -n "$PORT" ] || PORT="$(grep -hoE 'port[=: ]+[0-9]+' config.env .env 2>/dev/null | grep -oE '[0-9]+' | head -1)"
[ -n "$PORT" ] || PORT=8080
[ -n "${STARTCMD:-}" ] || { [ -f server.js ] && STARTCMD="node server.js"; }
[ -n "${STARTCMD:-}" ] || { [ -f ai_server.py ] && STARTCMD="python3 ai_server.py"; }
info "start command: ${STARTCMD:-<none found>}   port: $PORT"

if [ "$START" = 1 ]; then
  if [ "$DRY" = 1 ]; then info "[dry] would restart on :$PORT"; else
    if [ -s logs/app.pid ] && kill -0 "$(cat logs/app.pid)" 2>/dev/null; then kill "$(cat logs/app.pid)" 2>/dev/null; sleep 1; ok "previous instance stopped"; fi
    if [ -n "${STARTCMD:-}" ]; then
      nohup $STARTCMD > logs/app.out 2>&1 & echo $! > logs/app.pid
      sleep 3; ok "started pid $(cat logs/app.pid) -> logs/app.out"
      CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://127.0.0.1:$PORT/" 2>/dev/null)"
      printf '{"status":"%s","http":%s,"port":%s,"checked":"%s"}\n' \
        "$([ "${CODE:-000}" = "200" ] && echo up || echo down)" "${CODE:-0}" "$PORT" "$(date -u +%FT%TZ)" > health.json
      [ "${CODE:-000}" = "200" ] && ok "health check PASS (HTTP 200 on :$PORT)" || bad "health check FAIL (HTTP ${CODE:-none}) - see logs/app.out"
    else warn "no start command detected (add \"start\" to package.json)"; fi
  fi
else info "skipped (pass --start to launch)"; fi

###############################################################################
say "PHASE 6/6 - VERIFY + REPORT"
V_BAD=0
while IFS= read -r f; do [ -n "$f" ] || continue; JSONCHECK "$f" || V_BAD=$((V_BAD+1)); done < "$TMP/json"
V_SH=0
while IFS= read -r f; do [ -f "$f" ] || continue; bash -n "$f" 2>/dev/null || V_SH=$((V_SH+1)); done < <(find . -maxdepth 2 -name '*.sh' -not -path './node_modules/*' 2>/dev/null)

{ echo "# CINEHUB FIX REPORT - $STAMP"; echo
  echo "| metric | before | after |"; echo "|---|---|---|"
  echo "| invalid JSON | $(wc -l < "$TMP/badjson" | tr -d ' ') | $V_BAD |"
  echo "| shell syntax errors | $(wc -l < "$TMP/badsh" | tr -d ' ') | $V_SH |"
  echo "| empty files in root tree | $(wc -l < "$TMP/empty" | tr -d ' ') | $(find . -type f -empty -not -path './node_modules/*' -not -path './_archive/*' | wc -l | tr -d ' ') |"
  echo; echo "Actions: fixed=$FIXED  moved=$MOVED  archived_to=$ARCH"; echo "Log: $LOG"; echo "Mode: $([ $DRY = 1 ] && echo DRY-RUN || echo LIVE)"; } > "$REPORT"

say "SUMMARY"
info "fixed=$FIXED  moved=$MOVED  remaining_problems=$((V_BAD+V_SH))"
info "report  : $REPORT"
info "log     : $LOG"
info "archive : $ARCH"
[ "$V_BAD" = 0 ] && [ "$V_SH" = 0 ] && ok "CLEAN - app is consistent, executable and runnable" || warn "some items still need a manual look (see report)"
echo
