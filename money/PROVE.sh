#!/usr/bin/env bash
# إثبات حقيقي end-to-end (يُصلح خطأ PUID readonly وتطابق نص المبلغ)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"; load "$DATA/keys.live.env"
B="http://127.0.0.1:${PORT:-8787}"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
E="prove$(date +%s)@cinehub.local"; P=0; F=0
ck(){ if [ "$2" = "$3" ]; then echo "  ✔ $1"; P=$((P+1)); else echo "  ✗ $1  (توقعنا [$3] — حصلنا [$2])"; F=$((F+1)); fi }
J(){ python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('$1',''))" 2>/dev/null; }
echo "== إثبات ضد $B =="
echo "  POSTBACK_SECRET: $([ -n "${POSTBACK_SECRET:-}" ] && echo مضبوط || echo غير مضبوط)"
ck "البوابة تستجيب" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$B/api/status")" "200"
ck "صفحة محمية تُحوّل للبوابة" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$B/movies.html")" "302"
ck "البوابة تُفتح" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$B/gate.html")" "200"
R="$(curl -s --max-time 10 -X POST -H 'content-type: application/json' -d "{\"email\":\"$E\"}" "$B/api/signup")"
CODE="$(printf '%s' "$R" | J code)"; USR="$(printf '%s' "$R" | J id)"
ck "التسجيل يعيد رمزًا من 6 خانات" "${#CODE}" "6"
ck "الرمز مسترجع من API" "$(curl -s --max-time 10 "$B/api/code?email=$E" | J code)" "$CODE"
curl -s -c "$T/j" --max-time 10 -X POST -H 'content-type: application/json' -d "{\"email\":\"$E\",\"code\":\"$CODE\"}" "$B/api/verify" >/dev/null
ck "الدخول بعد التوثيق" "$(curl -s -b "$T/j" -o /dev/null -w '%{http_code}' --max-time 5 "$B/movies.html")" "200"
ck "رخصة صادرة" "$(curl -s -b "$T/j" --max-time 5 "$B/api/me" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("user",{}).get("license",""))' 2>/dev/null | cut -c1-3)" "CH-"
BEF="$(curl -s --max-time 5 "$B/api/ledger" | J total)"; D="$(date -u +%F)"; AMT="0.15"
RAW="adsterra|$AMT|$USR|$D"
SIG="$(printf '%s' "$RAW" | openssl dgst -sha256 -hmac "${POSTBACK_SECRET:-x}" | awk '{print $NF}')"
ADDED="$(curl -s --max-time 10 "$B/api/postback?net=adsterra&amount=$AMT&uid=$USR&date=$D&sig=$SIG" | J added)"
ck "postback موقّع يُقيَّد في الدفتر" "$ADDED" "True"
AFT="$(curl -s --max-time 5 "$B/api/ledger" | J total)"
ck "الدفتر ارتفع فعليًا" "$(python3 -c "print(1 if float('$AFT')>float('$BEF') else 0)" 2>/dev/null)" "1"
ck "منع التكرار" "$(curl -s --max-time 10 "$B/api/postback?net=adsterra&amount=$AMT&uid=$USR&date=$D&sig=$SIG" | J added)" "False"
ck "توقيع خاطئ مرفوض" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$B/api/postback?net=x&amount=1&sig=bad")" "403"
echo; echo "النتيجة: نجح $P / فشل $F"
[ "$F" = 0 ] && echo "✅ مُثبَت: تسجيل + توثيق + جلسة + رخصة + أرباح + دفتر" || echo "⚠️ راجع الأعلى"
if [ "${SIMULATE:-0}" = 1 ]; then echo "محاكاة 20 حدث..."; for i in $(seq 1 20); do
  A="$(python3 -c 'import random;print(round(random.uniform(0.01,0.4),2))')"
  DD="$D-$i"; RW="adsterra|$A|$USR|$DD"; S="$(printf '%s' "$RW" | openssl dgst -sha256 -hmac "${POSTBACK_SECRET:-x}" | awk '{print $NF}')"
  curl -s --max-time 8 "$B/api/postback?net=adsterra&amount=$A&uid=$USR&date=$DD&sig=$S" >/dev/null; done
  echo "  الدفتر: $(curl -s "$B/api/ledger" | J total)"; fi
