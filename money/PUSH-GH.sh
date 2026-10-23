#!/usr/bin/env bash
# نشر على GitHub — محصّن ضد فشل TLS في Termux
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"; load "$ROOT/.env"
[ -n "${GITHUB_TOKEN:-}" ] || { echo "  ℹ أضف GITHUB_TOKEN في keys.env للنشر"; return 0 2>/dev/null || exit 0; }
command -v git >/dev/null || { echo "  ℹ git غير مثبت: pkg install git"; exit 0; }
OWNER="$(python3 "$HERE/lib/gh.py" whoami "$GITHUB_TOKEN" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("login",""))' 2>/dev/null)"
[ -n "$OWNER" ] || { echo "  ✗ تعذّر التحقق من الرمز (تحقق من GITHUB_TOKEN)"; exit 0; }
echo "  الحساب: $OWNER"
touch .gitignore
for l in node_modules/ money/node_modules/ logs/ cache/ _archive/ '*.log' '*.pid' '*.tmp' .env money/data/keys.live.env money/data/browser/ money/data/watch-profile/; do
  grep -qxF "$l" .gitignore || echo "$l" >> .gitignore; done
for R in ${GITHUB_REPOS:-cinehub3099}; do :; done
for R in ${GITHUB_REPOS:-cinehub3099}; do
  C="$(python3 "$HERE/lib/gh.py" exists "$GITHUB_TOKEN" "$OWNER/$R")"
  if [ "$C" = "404" ]; then python3 "$HERE/lib/gh.py" create "$GITHUB_TOKEN" "$R" >/dev/null && echo "  ✔ أُنشئ مستودع $OWNER/$R"
  elif [ "$C" = "200" ]; then echo "  ✔ مستودع موجود $OWNER/$R"; else echo "  ✗ فحص $R -> $C"; fi
done
[ -d .git ] || git init -q
git config user.email "agent@cinehub.local" 2>/dev/null; git config user.name "CineHub Agent" 2>/dev/null
git add -A 2>/dev/null; git commit -q -m "agent sync $(date -u +%FT%TZ)" 2>/dev/null && echo "  ✔ commit" || echo "  ℹ لا تغييرات"
git branch -M main 2>/dev/null
i=0
for R in ${GITHUB_REPOS:-cinehub3099}; do i=$((i+1))
  git remote remove "r$i" 2>/dev/null || true
  git remote add "r$i" "https://x-access-token:$GITHUB_TOKEN@github.com/$OWNER/$R.git"
  if git -c http.postBuffer=524288000 push -q "r$i" main --force 2>/dev/null; then echo "  ✔ مدفوع -> https://github.com/$OWNER/$R"
  else echo "  ✗ فشل الدفع إلى $R (جرّب: pkg install git && git config --global http.version HTTP/1.1)"; fi
done
