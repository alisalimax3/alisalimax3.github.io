#!/data/data/com.termux/files/usr/bin/bash
# الاستخدام: bash tools/ask.sh <نوع> <سؤال> <قيمة حالية> <إلزامي 0/1>
# القيمة النهائية → stdout فقط · كل الرسائل → stderr
T="$1"; Q="$2"; CUR="$3"; REQ="${4:-0}"; N=0
while [ $N -lt 30 ]; do
  N=$((N+1))
  if [ -n "$CUR" ]; then printf '%s [%s] : ' "$Q" "$CUR" >&2; else printf '%s : ' "$Q" >&2; fi
  if ! read -r IN; then IN=""; fi
  [ -z "$IN" ] && IN="$CUR"
  if [ -z "$IN" ]; then
    if [ "$REQ" = "1" ]; then printf '    ↳ إلزامي\n' >&2; continue; fi
    printf '' ; exit 0
  fi
  RES=$(python3 tools/validate.py "$T" "$IN" 2>/dev/null)
  case "$RES" in
    *'"ok": true'*)
      EX=$(printf '%s' "$RES" | sed -n 's/.*"extra": *"\([^"]*\)".*/\1/p')
      [ -n "$EX" ] && printf '    \033[32m✓\033[0m %s\n' "$EX" >&2 || printf '    \033[32m✓\033[0m\n' >&2
      printf '%s' "$IN"; exit 0 ;;
  esac
  ER=$(printf '%s' "$RES" | sed -n 's/.*"err": *"\([^"]*\)".*/\1/p')
  printf '    \033[31m✗ %s\033[0m\n' "${ER:-غير مقبول}" >&2
  if [ "$REQ" = "0" ]; then
    printf '    (Enter = اقبله كما هو) : ' >&2
    if ! read -r F; then F=""; fi
    [ -z "$F" ] && { printf '%s' "$IN"; exit 0; }
    IN="$F"
  fi
done
printf '%s' "$IN"
