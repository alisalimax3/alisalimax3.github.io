#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools; export GHTMP="$TMPDIR"
export PYTHONUNBUFFERED=1
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*"; }

printf '\n%s══ إصلاح المصادقة ══%s\n' "$C" "$N"

# 0 · أوقف أي محاولة عالقة
pkill -f auth_device.py 2>/dev/null && ok "أُوقفت المحاولة العالقة" || true

# 1 · حل تعارض .secrets (ملف ← مجلد)
if [ -e .secrets ] && [ ! -d .secrets ]; then
  VAL="$(cat .secrets 2>/dev/null | tr -d ' \r\n')"
  mv -f .secrets .secrets.bak 2>/dev/null
  mkdir -p .secrets
  ok ".secrets كان ملفًا → نُقل إلى .secrets.bak"
  if printf '%s' "$VAL" | grep -qE 'gh[pousr]_|github_pat_'; then
    printf '%s' "$VAL" > .secrets.gh_token; chmod 600 .secrets.gh_token
    ok "استُخرج توكن من الملف القديم"
  fi
else
  mkdir -p .secrets
  ok ".secrets مجلد سليم"
fi
[ -d .secrets ] || { mkdir -p .secrets; }

# 2 · ترقيع AUTHONLY: مخرجات غير مخزّنة + طباعة الكود من ملف
python3 - <<'PY'
p = "AUTHONLY.sh"
try: s = open(p, encoding="utf-8").read()
except FileNotFoundError: print("  ✗ لا AUTHONLY.sh"); raise SystemExit
o = s

s = s.replace('python3 tools/auth_device.py > "$GHTMP/dev.out" 2>&1 &',
              'python3 -u tools/auth_device.py > "$GHTMP/dev.out" 2>&1 &')

old = '''  sleep 3
  cat "$GHTMP/dev.out" 2>/dev/null
  URL="$(grep -oE 'https://github.com/login/device' "$GHTMP/dev.out" 2>/dev/null | head -1)"
  [ -n "$URL" ] && openurl "$URL"'''
new = '''  rm -f "$GHTMP/gh_code"
  for _ in $(seq 1 25); do [ -s "$GHTMP/gh_code" ] && break; sleep 1; done
  if [ -s "$GHTMP/gh_code" ]; then
    CODE="$(head -1 "$GHTMP/gh_code")"
    URL="$(sed -n 2p "$GHTMP/gh_code")"
    printf '\\n  ┌──────────────────────────────┐\\n'
    printf '  │  الرمز:  %-20s│\\n' "$CODE"
    printf '  └──────────────────────────────┘\\n'
    printf '  افتح: %s  والصق الرمز\\n\\n' "$URL"
    [ -n "$URL" ] && openurl "$URL"
    printf '  %sانتظرتُ 25ث… ثم انتظرتُ\\n' "$(printf '')" >/dev/null 2>&1 || true
  else
    cat "$GHTMP/dev.out" 2>/dev/null
    URL="$(grep -oE 'https://github.com/login/device' "$GHTMP/dev.out" 2>/dev/null | head -1)"
    [ -n "$URL" ] && openurl "$URL"
  fi'''
if old in s: s = s.replace(old, new); print("  ✓ صُحّح مسار Device Flow")
else: print("  · مسار Device Flow مُصحّح مسبقًا")

s = s.replace('mkdir -p "$TMPDIR" .secrets tools logs',
              'mkdir -p "$TMPDIR" tools logs; [ -e .secrets ] && [ ! -d .secrets ] && { mv -f .secrets .secrets.bak 2>/dev/null; }; mkdir -p .secrets')

if s != o: open(p, "w", encoding="utf-8").write(s); print("  ✓ AUTHONLY.sh مُرقّع")
else: print("  · AUTHONLY.sh مُرقّع مسبقًا")
PY
bash -n AUTHONLY.sh && ok "الصيغة سليمة"

# 3 · تحقق من auth_device.py
if [ -s tools/auth_device.py ]; then ok "auth_device.py موجود"
else
cat > tools/auth_device.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, time, urllib.request, urllib.parse
T = os.environ.get("GHTMP") or os.path.expanduser("~/.cinehub-tmp"); os.makedirs(T, exist_ok=True)
CID = os.environ.get("GH_CLIENT_ID", "178c6fc778ccc68e1d6a")
def post(u, d):
    r = urllib.request.Request(u, data=urllib.parse.urlencode(d).encode(),
        headers={"Accept": "application/json", "User-Agent": "CineHub"})
    return json.load(urllib.request.urlopen(r, timeout=30))
d = post("https://github.com/login/device/code", {"client_id": CID, "scope": "repo workflow read:org"})
code, url = d["user_code"], d["verification_uri"]
try: open(T + "/gh_code", "w").write(code + "\n" + url + "\n")
except Exception: pass
print("\n  ┌──────────────────────────────┐")
print("  │  الرمز:  %-20s│" % code)
print("  └──────────────────────────────┘")
print("  افتح: %s  والصق الرمز ثم Approve\n" % url, flush=True)
iv = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
while time.time() < end:
    time.sleep(iv)
    t = post("https://github.com/login/oauth/access_token",
             {"client_id": CID, "device_code": d["device_code"],
              "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
    if t.get("access_token"):
        open(T + "/gh_tok", "w").write(t["access_token"]); sys.exit(0)
    e = t.get("error", "")
    if e == "slow_down": iv += 5
    elif e == "authorization_pending": print("  … بانتظار الموافقة", flush=True)
    elif e in ("expired_token", "access_denied"): sys.exit(2)
sys.exit(4)
PYEOF
ok "auth_device.py أُعيد بناؤه"; fi

printf '\n%s══ تشغيل المصادقة ══%s\n\n' "$C" "$N"
export PYTHONUNBUFFERED=1
bash AUTHONLY.sh
