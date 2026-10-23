#!/usr/bin/env bash
# متتبع التسجيل + فتح الروابط + حل الكابتشا
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"; load "$DATA/keys.live.env"
case "${1:-list}" in
  list) python3 - "$HERE/sites.tsv" <<'PY'
import sys
for l in open(sys.argv[1]):
    f=l.rstrip("\n").split("|")
    if len(f)<10 or f[0]=="id": continue
    print(f"  {f[0]:<16} {f[2]:<10} mode={f[5]:<6} {'REV' if f[8]=='1' else '   '}  {f[3]}")
PY
    echo; echo "لتوليد صفحة التسجيل: bash money/REGISTER.sh html" ;;
  html) python3 "$HERE/lib/sites.py" ;;
  open) i=0; while IFS='|' read -r id name cat signup rest; do [ "$id" = "id" ] && continue
      i=$((i+1)); echo "  [$i] $name"; (xdg-open "$signup" >/dev/null 2>&1 || open "$signup" >/dev/null 2>&1 || true); sleep 1
    done < "$HERE/sites.tsv"; echo "فُتحت الروابط — أكمل التسجيل والكابتشا" ;;
  set) python3 - "$DATA/sites.json" "$2" "$3" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)) if __import__("os").path.exists(p) else {}
d.setdefault(sys.argv[2],{})["status"]=sys.argv[3]; json.dump(d,open(p,"w"),indent=2)
print(f"{sys.argv[2]} -> {sys.argv[3]}")
PY
    ;;
  status) python3 - "$DATA/sites.json" <<'PY'
import json,sys,collections,os
d=json.load(open(sys.argv[1])) if os.path.exists(sys.argv[1]) else {}
c=collections.Counter(v.get("status","pending") for v in d.values())
tot=len(d) or 1
for k,v in c.most_common(): print(f"  {k:<12} {v}")
print(f"  الإجمالي {sum(c.values())} — مكتمل {round(100*(sum(c.values())-c.get('pending',0)-c.get('opened',0))/tot)}%")
PY
    ;;
  solve) [ -n "${CAPTCHA_API_KEY:-}" ] || { echo "أضف CAPTCHA_API_KEY"; exit 1; }
    python3 "$HERE/lib/captcha.py" solve "$2" "$3" "${4:-recaptcha}" ;;
  balance) python3 "$HERE/lib/captcha.py" balance ;;
  check) bash "$HERE/KEYCHECK.sh" ;;
  *) echo "الاستخدام: REGISTER.sh [list|html|open|set <id> <status>|status|solve <sitekey> <url>|balance|check]" ;;
esac
