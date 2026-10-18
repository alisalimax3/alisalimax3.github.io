#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR"; export GHTMP="$TMPDIR"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
K="${1:-}"
kv(){ python3 - "$1" <<'PY'
import sys
try:
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if s.startswith(sys.argv[1]+"="): print(s.split("=",1)[1]); break
except Exception: pass
PY
}
setkv(){ python3 - "$1" "$2" <<'PY'
import sys, os, time
k,v=sys.argv[1],sys.argv[2]; E={}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if "=" in s and not s.startswith("#"):
            a,b=s.split("=",1); E[a.strip()]=b.strip()
E[k]=v
open("keys.env","w",encoding="utf-8").write("# CineHub 3099\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
PY
}
clip(){ termux-clipboard-get 2>/dev/null | tr -d '\r\n'; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || true; }

# المفتاح: الاسم | الرابط | ماذا تنسخ | التحقق الحيّ | regex
case "$K" in
  AADS_UNIT|"") K=AADS_UNIT; SITE="https://a-ads.com"; COPY='data-aa="..." (الأرقام)'; VURL='https://a-ads.com/api/v1/banners/{v}'; EX="."; RE='[0-9]{4,8}' ;;
  ADSTERRA_API_KEY) SITE="https://publishers.adsterra.com/signup"; COPY="Profile → API Key"; VURL='https://api3.adsterra.com/api/v1/publisher/balance'; EX=""; RE='[A-Za-z0-9_-]{20,48}' ;;
  EXOCLICK_ZONE) SITE="https://www.exoclick.com/signup/"; COPY="Zones → Zone ID"; VURL=""; EX=""; RE='[0-9]{5,9}' ;;
  MONETAG_MULTITAG) SITE="https://monetag.com"; COPY="Sites → Multitag ID"; VURL=""; EX=""; RE='[0-9]{5,9}' ;;
  *) echo "استخدم: bash KEY.sh [AADS_UNIT|ADSTERRA_API_KEY|EXOCLICK_ZONE|MONETAG_MULTITAG]"; exit 0 ;;
esac

printf '\n%s┌─ %s ─┐%s\n' "$B" "$K" "$N"
printf '  سجّل: %s\n  انسخ: %s\n' "$SITE" "$COPY"
printf '  %s[انسخ من الموقع — سيُلتقط تلقائيًا · s تخطي]%s\n' "$D" "$N"
openurl "$SITE" &
prev="$(clip)"; t0=$(date +%s)
while :; do
  sleep 2
  line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
  [ "$line" = "s" ] && { echo "  تُخطّي"; exit 0; }
  now="$(clip)"
  if [ -n "$now" ] && [ "$now" != "$prev" ]; then
    prev="$now"
    for v in $(printf '%s' "$now" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^${RE}$" | head -5); do
      [ ${#v} -lt 4 ] && continue
      if [ -n "$VURL" ]; then
        B2="$(curl -fsS -m 15 "${VURL//\{v\}/$v}" 2>/dev/null)" || continue
        [ -n "$EX" ] && { printf '%s' "$B2" | grep -qF "$EX" || continue; }
      fi
      setkv "$K" "$v"; printf '%s✓%s %s = %s\n' "$G" "$N" "$K" "$v"
      bash PUSH.sh >/dev/null 2>&1 && printf '%s✓%s رُفع — سيظهر الإعلان خلال دقائق\n' "$G" "$N"
      exit 0
    done
    printf '%s✗%s مرفوض: %s\n' "$R" "$N" "${now:0:40}"
  fi
  el=$(( $(date +%s) - t0 )); [ "$el" -ge 900 ] && { echo "  انتهت المهلة"; exit 1; }
  printf '\r%-70s' "$(printf '  … %dث — انسخ %s' "$el" "$COPY")"
done
