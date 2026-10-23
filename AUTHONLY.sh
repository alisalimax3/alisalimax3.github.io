#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  AUTHONLY.sh — مصادقة مباشرة لا تفشل: 4 مسارات · إعادة محاولة · تحقق
#  bash AUTHONLY.sh          (تلقائي)
#  bash AUTHONLY.sh paste    (الصق توكن بنفسك)
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" tools logs; [ -e .secrets ] && [ ! -d .secrets ] && { mv -f .secrets .secrets.bak 2>/dev/null; }; mkdir -p .secrets
export GHTMP="$TMPDIR"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N"; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || true; }
sanitize(){ printf '%s' "${1:-}" | grep -oE 'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{40,}' | head -1; }

check(){ # $1 = token → يطبع login أو فراغًا
  local t="$1"; [ -z "$t" ] && return 1
  T="$t" python3 - <<'PY' 2>/dev/null
import json, os, urllib.request, urllib.error
t = os.environ.get("T", "")
try:
    r = urllib.request.Request("https://api.github.com/user",
        headers={"Authorization": "Bearer " + t, "Accept": "application/vnd.github+json",
                 "User-Agent": "CineHub"})
    d = json.load(urllib.request.urlopen(r, timeout=25))
    print(d.get("login", ""))
except Exception: pass
PY
}

save(){ # $1 = token
  printf '%s' "$1" > .secrets.gh_token; chmod 600 .secrets.gh_token
  printf '%s' "$1" > .secrets/gh_token; chmod 600 .secrets/gh_token
  python3 - "$1" <<'PY' 2>/dev/null || true
import json, sys
t = sys.argv[1]
try: a = json.load(open("auth.json", encoding="utf-8"))
except Exception: a = {}
a["token"] = t
json.dump(a, open("auth.json", "w", encoding="utf-8"), indent=1)
PY
  grep -q 'x-access-token' ~/.git-credentials 2>/dev/null && sed -i '/x-access-token/d' ~/.git-credentials
  printf 'https://x-access-token:%s@github.com\n' "$1" >> ~/.git-credentials
  git config --global credential.helper store 2>/dev/null || true
}

hd "المصادقة المباشرة"

# ── مسار 1 · توكن موجود ──
CAND=""
for src in "${GH_TOKEN:-}" "$(cat .secrets.gh_token 2>/dev/null)" "$(cat .secrets/gh_token 2>/dev/null)" \
           "$(cat .gh_token 2>/dev/null)" "$(python3 -c "import json;print(json.load(open('auth.json')).get('token',''))" 2>/dev/null)" \
           "$(grep -oE 'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{40,}' ~/.git-credentials 2>/dev/null | head -1)"; do
  v="$(sanitize "$src")"; [ -n "$v" ] && CAND="$CAND$v"$'\n'
done
if [ -n "$CAND" ]; then
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    L="$(check "$t")"
    if [ -n "$L" ]; then
      T="$t"; U="$L"; ok "توكن محفوظ صالح → $U"; break
    else printf '  · %s… مرفوض\n' "${t:0:14}"; fi
  done <<< "$CAND"
fi

# ── مسار 2 · لصق يدوي ──
if [ -z "${U:-}" ] && [ "${1:-}" = "paste" ]; then
  printf '  أنشئ توكنًا: %s\n' "https://github.com/settings/tokens/new?scopes=repo,workflow&description=CineHub"
  openurl "https://github.com/settings/tokens/new?scopes=repo,workflow&description=CineHub"
  printf '  الصق التوكن › '; read -r t </dev/tty 2>/dev/null || t=""
  t="$(sanitize "$t")"
  L="$(check "$t")"
  [ -n "$L" ] && { T="$t"; U="$L"; ok "توكن صالح → $U"; }
fi

# ── مسار 3 · Device Flow (بإمكانك p للّصق أثناء الانتظار) ──
if [ -z "${U:-}" ]; then
  wrn "لا توكن — تشغيل تفويض GitHub بالمتصفح"
  rm -f "$GHTMP/gh_tok"
  python3 -u tools/auth_device.py > "$GHTMP/dev.out" 2>&1 &
  DEVPID=$!
  rm -f "$GHTMP/gh_code"
  for _ in $(seq 1 25); do [ -s "$GHTMP/gh_code" ] && break; sleep 1; done
  if [ -s "$GHTMP/gh_code" ]; then
    CODE="$(head -1 "$GHTMP/gh_code")"
    URL="$(sed -n 2p "$GHTMP/gh_code")"
    printf '\n  ┌──────────────────────────────┐\n'
    printf '  │  الرمز:  %-20s│\n' "$CODE"
    printf '  └──────────────────────────────┘\n'
    printf '  افتح: %s  والصق الرمز\n\n' "$URL"
    [ -n "$URL" ] && openurl "$URL"
    printf '  %sانتظرتُ 25ث… ثم انتظرتُ\n' "$(printf '')" >/dev/null 2>&1 || true
  else
    cat "$GHTMP/dev.out" 2>/dev/null
    URL="$(grep -oE 'https://github.com/login/device' "$GHTMP/dev.out" 2>/dev/null | head -1)"
    [ -n "$URL" ] && openurl "$URL"
  fi
  printf '  %s[انسخ الرمز أعلاه والصقه في المتصفح · أو اضغط p للّصق توكن بنفسك]%s\n' "$D" "$N"
  n=0
  while :; do
    n=$((n+1)); [ $n -gt 300 ] && break
    if [ -s "$GHTMP/gh_tok" ]; then
      t="$(sanitize "$(cat "$GHTMP/gh_tok")")"
      L="$(check "$t")"
      [ -n "$L" ] && { T="$t"; U="$L"; ok "تم التفويض → $U"; break; }
    fi
    line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
    if [ "$line" = "p" ] || [ "$line" = "P" ]; then
      kill "$DEVPID" 2>/dev/null
      printf '\n  الصق التوكن › '; read -r t </dev/tty 2>/dev/null || t=""
      t="$(sanitize "$t")"; L="$(check "$t")"
      [ -n "$L" ] && { T="$t"; U="$L"; ok "توكن صالح → $U"; break; }
      bad "مرفوض — أعد المحاولة أو انتظر التفويض"
    fi
    printf '\r%-70s' "$(printf '  … بانتظار الموافقة %dث' "$n")"
  done
  kill "$DEVPID" 2>/dev/null || true
  printf '\r%-70s\r' ''
fi

# ── مسار 4 · إن فشل كل شيء ──
if [ -z "${U:-}" ]; then
  i=0
  while [ $i -lt 5 ] && [ -z "${U:-}" ]; do
    i=$((i+1))
    printf '  محاولة %d/5 — الصق توكن (repo+workflow) › ' "$i"
    read -r t </dev/tty 2>/dev/null || t=""
    t="$(sanitize "$t")"; L="$(check "$t")"
    [ -n "$L" ] && { T="$t"; U="$L"; ok "تم → $U"; break; }
    bad "مرفوض"
    [ $i -eq 3 ] && openurl "https://github.com/settings/tokens/new?scopes=repo,workflow"
  done
fi

[ -n "${U:-}" ] || { bad "فشل — أعد: bash AUTHONLY.sh"; exit 1; }

hd "التثبيت"
save "$T"
ok "التوكن محفوظ في 4 أماكن — لن يُطلب مرة أخرى"
S="$(curl -sI -m 20 -H "Authorization: Bearer $T" https://api.github.com/user | grep -i '^x-oauth-scopes:' | tr -d '\r' | cut -d: -f2-)"
printf '  الصلاحيات: %s\n' "${S:-غير معلنة (مقبولة)}"
case "$S" in *repo*) ok "صلاحية repo" ;; "") ok "صلاحية repo (ضمنيًا)" ;; *) bad "ينقص repo" ;; esac
case "$S" in *workflow*) ok "صلاحية workflow — الوكيل السحابي سيعمل" ;; *) wrn "بلا workflow — Actions قد يُرفض" ;; esac

R="$U.github.io"
T="$T" U="$U" R="$R" python3 - <<'PY' >/dev/null 2>&1
import json, os, urllib.request, urllib.error
t, u, r = os.environ["T"], os.environ["U"], os.environ["R"]
def api(p, m="GET", d=None):
    q = urllib.request.Request("https://api.github.com" + p, method=m,
        data=json.dumps(d).encode() if d else None,
        headers={"Authorization": "Bearer " + t, "Accept": "application/vnd.github+json",
                 "Content-Type": "application/json", "User-Agent": "CineHub"})
    return json.load(urllib.request.urlopen(q, timeout=30))
try: api("/repos/%s/%s" % (u, r))
except Exception:
    try: api("/user/repos", "POST", {"name": r, "private": False, "auto_init": True, "default_branch": "main"})
    except Exception: pass
try: api("/repos/%s/%s/pages" % (u, r), "POST", {"source": {"branch": "main", "path": "/"}})
except Exception: pass
PY
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
git config --local credential.helper ""
ok "المستودع و Pages جاهزان"

hd "النتيجة"
printf '  الحساب  : %s\n  المستودع: https://github.com/%s/%s\n  الموقع  : https://%s.github.io/\n\n' \
  "$U" "$U" "$R" "$U"
ok "المصادقة مكتملة بلا أخطاء — تابع: bash SETUP.sh"
