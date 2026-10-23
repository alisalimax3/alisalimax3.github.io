#!/usr/bin/env bash
# حصد حقيقي من كل موقع rev=1 + أرصدة Base، وإيداع في الدفتر المسلسل
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/.env"; load "$ROOT/keys.env"; load "$DATA/keys.live.env"
D="$(date -u +%F)"; TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT; E="$TMP/e.jsonl"; : > "$E"; N=0
liveness(){ python3 - "$DATA/keys-status.json" "$1" <<'PY' 2>/dev/null || echo 0
import json,sys,os
p=sys.argv[1]
if not os.path.exists(p): print(0); raise SystemExit
d=json.load(open(p)); print(1 if any(k["id"]==sys.argv[2] and k["status"]=="LIVE" for k in d["keys"]) else 0)
PY
}
echo "== حصد $(date -u +%FT%TZ) =="
while IFS='|' read -r id name cat signup envf mode url hdrs rev payout note; do
  [ "$rev" = "1" ] || continue; [ "$(liveness "$id")" = "1" ] || { echo "  - $id (مفتاح غير حيّ)"; continue; }
  k1="${envf%%,*}"; k2=""; case "$envf" in *,*) k2="${envf#*,}"; k2="${k2%%,*}";; esac
  v1="${!k1:-}"; v2=""; [ -n "$k2" ] && v2="${!k2:-}"
  U="${url//\{KEY\}/$v1}"; U="${U//\{KEY2\}/$v2}"; U="${U//\{D\}/$D}"; A=()
  if [ -n "$hdrs" ] && [ "$mode" != "post" ]; then while IFS= read -r h; do [ -n "$h" ] || continue
    h="${h//\{KEY\}/$v1}"; h="${h//\{KEY2\}/$v2}"; A+=(-H "$h"); done < <(printf '%s' "$hdrs" | tr ';' '\n' | grep .); fi
  case "$mode" in sign) TS="$(date +%s%3N)"; Q="timestamp=$TS"
        SIG="$(printf '%s' "$Q" | openssl dgst -sha256 -hmac "$v2" | awk '{print $NF}')"; U="$U?$Q&signature=$SIG";;
      post) A=(-H 'content-type: application/x-www-form-urlencoded' --data "${hdrs//\{KEY\}/$v1}");;
      basic) A+=(-u "$v1:$v2");; esac
  CODE="$(curl -sS -o "$TMP/$id.json" -w '%{http_code}' --max-time 20 "${A[@]}" "$U" 2>/dev/null || echo 000)"
  [ "${CODE:0:1}" = "2" ] || { echo "  ✗ $id HTTP $CODE"; continue; }
  AMT="$(python3 "$HERE/lib/extract.py" "$TMP/$id.json")"
  [ "$AMT" = "0.000000" ] && { echo "  - $id: 0.00"; continue; }
  printf '{"net":"%s","date":"%s","amount":%s,"usd":%s,"currency":"USD","source":"api","key":"%s|%s"}\n' "$id" "$D" "$AMT" "$AMT" "$id" "$D" >> "$E"
  echo "  ✔ $id: +\$$AMT"; N=$((N+1))
done < "$HERE/sites.tsv"
python3 "$HERE/lib/onchain.py" > "$DATA/onchain.json" 2>/dev/null || echo '{}' > "$DATA/onchain.json"
OC="$(python3 -c "import json;print(json.load(open('$DATA/onchain.json')).get('usd_total',0))" 2>/dev/null || echo 0)"
python3 -c "import json;print(json.dumps([json.loads(l) for l in open('$E') if l.strip()]))" > "$TMP/b.json"
ADD="$(python3 "$HERE/lib/ledger.py" append < "$TMP/b.json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["added"])' 2>/dev/null || echo 0)"
python3 "$HERE/lib/ledger.py" stats 30 > "$DATA/earnings-live.json"
python3 - "$DATA" "$OC" <<'PY'
import json,os,sys,datetime
d=sys.argv[1]; oc=float(sys.argv[2])
led=json.load(open(os.path.join(d,"ledger.json"))) if os.path.exists(os.path.join(d,"ledger.json")) else {"total":0.0,"chain":[]}
p=os.path.join(d,"payouts.json"); pay=json.load(open(p)) if os.path.exists(p) else {"items":[]}
paid=round(sum(float(i.get("usd",0)) for i in pay["items"] if i.get("ok")),6)
thr=float(os.environ.get("PAYOUT_THRESHOLD","10"))
t={"updated":datetime.datetime.utcnow().isoformat()+"Z","lifetime_usd":led.get("total",0.0),"paid_out_usd":paid,
   "available_usd":round(max(led.get("total",0.0)-paid,0),6),"onchain_usd":oc,"threshold_usd":thr,
   "ready_to_payout":(led.get("total",0.0)-paid)>=thr,"entries":len(led.get("chain",[]))}
json.dump(t,open(os.path.join(d,"treasury.json"),"w"),indent=2)
print("  ledger=$%.6f available=$%.6f onchain=$%.6f"%(t["lifetime_usd"],t["available_usd"],t["onchain_usd"]))
PY
echo "$ADD" > "$DATA/.added"; echo "أُضيفت $ADD قيود | مصادر ناجحة: $N"
