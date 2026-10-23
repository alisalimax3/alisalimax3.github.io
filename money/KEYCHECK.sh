#!/usr/bin/env bash
# فحص حقيقي لكل مفتاح. modes: api | sign | post | basic | dash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
mkdir -p "$DATA"; OUT="$DATA/keys-status.json"; LIVE="$DATA/keys.live.env"; D="$(date -u +%F)"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
  l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
  case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
  printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/.env"; load "$ROOT/keys.env"; load "$DATA/keys.live.env"
gen(){ local n="$1" v; [ -n "${!n:-}" ] && return 0
  v="$(openssl rand -hex 32 2>/dev/null || head -c32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  printf '%s=%s\n' "$n" "$v" >> "$ROOT/keys.env"; export "$n=$v"; echo "  أُنشئ سر: $n"; }
for s in LICENSE_SECRET POSTBACK_SECRET ADMIN_TOKEN; do gen "$s"; done
[ -n "${BASE_RPC:-}" ] || { echo "BASE_RPC=https://mainnet.base.org" >> "$ROOT/keys.env"; export BASE_RPC="https://mainnet.base.org"; }
[ -n "${PAYOUT_THRESHOLD:-}" ] || { echo "PAYOUT_THRESHOLD=10" >> "$ROOT/keys.env"; export PAYOUT_THRESHOLD=10; }
CB="$(python3 "$HERE/lib/captcha.py" balance 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("balance"))' 2>/dev/null)"
echo "2Captcha balance: ${CB:-غير مضبوط}"
R="$DATA/.rows"; : > "$R"; LT="$DATA/.live"; : > "$LT"
live=0; dead=0; missing=0; setc=0; CRIT=()
while IFS='|' read -r id name cat signup envf mode url hdrs rev payout note; do
  [ -n "${id:-}" ] || continue; [ "$id" = "id" ] && continue
  k1="${envf%%,*}"; k2=""; case "$envf" in *,*) k2="${envf#*,}"; k2="${k2%%,*}";; esac; k3=""; case "$envf" in *,*,*) k3="${envf##*,}";; esac
  v1="${!k1:-}"; v2=""; [ -n "$k2" ] && v2="${!k2:-}"
  if [ -z "$v1" ] || { [ -n "$k2" ] && [ -z "$v2" ]; }; then
    printf '%s|%s|MISSING|0|0|%s\n' "$id" "$envf" "$rev" >> "$R"; missing=$((missing+1))
    echo "  ✗ $id  — أضف: $envf"; continue; fi
  if [ "$mode" = "dash" ]; then printf '%s|%s|SET|0|0|%s\n' "$id" "$envf" "$rev" >> "$R"; setc=$((setc+1))
    echo "  • $id  — المفتاح موجود (لوحة فقط، لا API عام)"; printf 'export %s=%q\n' "$k1" "$v1" >> "$LT"; continue; fi
  U="${url//\{KEY\}/$v1}"; U="${U//\{KEY2\}/$v2}"; U="${U//\{D\}/$D}"; A=()
  if [ -n "$hdrs" ] && [ "$mode" != "post" ]; then while IFS= read -r h; do [ -n "$h" ] || continue
    h="${h//\{KEY\}/$v1}"; h="${h//\{KEY2\}/$v2}"; A+=(-H "$h"); done < <(printf '%s' "$hdrs" | tr ';' '\n' | grep .); fi
  case "$mode" in
    sign) TS="$(date +%s%3N)"; Q="timestamp=$TS"
          [ -n "$k3" ] && Q="recvWindow=5000&$Q"
          SIG="$(printf '%s' "$Q" | openssl dgst -sha256 -hmac "$v2" | awk '{print $NF}')"
          U="$U?$Q&signature=$SIG";;
    post) B="${hdrs//\{KEY\}/$v1}"; A=(-H 'content-type: application/x-www-form-urlencoded' --data "$B");;
    basic) A+=(-u "$v1:$v2");;
  esac
  T0="$(date +%s%3N)"
  CODE="$(curl -sS -o "$DATA/.body" -w '%{http_code}' --max-time 20 "${A[@]}" "$U" 2>/dev/null || echo 000)"
  MS=$(( $(date +%s%3N) - T0 ))
  if [[ "$CODE" =~ ^2 ]]; then
    printf '%s|%s|LIVE|%s|%s|%s\n' "$id" "$envf" "$CODE" "$MS" "$rev" >> "$R"; live=$((live+1))
    echo "  ✔ $id  LIVE (HTTP $CODE, ${MS}ms)"
    printf 'export %s=%q\n' "$k1" "$v1" >> "$LT"; [ -n "$v2" ] && printf 'export %s=%q\n' "$k2" "$v2" >> "$LT"
    [ -n "$k3" ] && printf 'export %s=%q\n' "$k3" "${!k3}" >> "$LT"
  else printf '%s|%s|DEAD|%s|%s|%s\n' "$id" "$envf" "$CODE" "$MS" "$rev" >> "$R"; dead=$((dead+1))
    echo "  ✗ $id  DEAD (HTTP $CODE)"; [ "$rev" = "1" ] && CRIT+=("$id"); fi
done < "$HERE/sites.tsv"
{ echo "# حيّ $(date -u +%FT%TZ)"; cat "$LT"; } > "$LIVE"
python3 - "$R" "$OUT" "$live" "$dead" "$missing" "$setc" <<'PY'
import json,sys,datetime,os
rows=[l.rstrip("\n").split("|") for l in open(sys.argv[1]) if l.strip()]
json.dump({"checked_at":datetime.datetime.utcnow().isoformat()+"Z",
 "summary":{"live":int(sys.argv[3]),"dead":int(sys.argv[4]),"missing":int(sys.argv[5]),"set":int(sys.argv[6])},
 "keys":[{"id":r[0],"env":r[1],"status":r[2],"http":r[3],"ms":r[4],"revenue_source":r[5]=="1"} for r in rows]},
 open(sys.argv[2],"w"),indent=2)
st=os.path.join(os.path.dirname(sys.argv[2]),"sites.json"); d=json.load(open(st)) if os.path.exists(st) else {}
for r in rows:
    s=r[2]; d.setdefault(r[0],{})["status"]="live" if s=="LIVE" else ("key_set" if s=="SET" else ("key_set" if s=="DEAD" else "pending"))
json.dump(d,open(st,"w"),indent=2)
PY
rm -f "$R" "$LT" "$DATA/.body"
echo; echo "النتيجة: live=$live  dead=$dead  dash-set=$setc  missing=$missing"
[ ${#CRIT[@]} -gt 0 ] && echo "مصادر ربح لا تعمل: ${CRIT[*]}"
echo "التفاصيل: $OUT"
