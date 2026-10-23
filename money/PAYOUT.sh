#!/usr/bin/env bash
# سحب الأرباح فعليًا (USDC على Base) عند بلوغ الحد
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
  l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
  case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
  printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/.env"; load "$ROOT/keys.env"; load "$DATA/keys.live.env"
[ -f "$DATA/treasury.json" ] || { echo "لا يوجد treasury — شغّل HARVEST.sh أولاً"; exit 0; }
READY="$(python3 -c "import json;print('1' if json.load(open('$DATA/treasury.json')).get('ready_to_payout') else '0')")"
[ "$READY" = 1 ] || { echo "لم يبلغ الحد بعد"; exit 0; }
AMT="$(python3 -c "import json;print(round(json.load(open('$DATA/treasury.json'))['available_usd'],6))")"
echo "== سحب \$$AMT =="
RES="$(cd "$HERE" && node payout_evm.js "$AMT" 2>&1 | tail -1)"
echo "$RES"
python3 - "$DATA" "$RES" "$AMT" <<'PY'
import json,os,sys,datetime
d,res,amt=sys.argv[1],sys.argv[2],float(sys.argv[3])
try: r=json.loads(res)
except Exception: r={"ok":False,"reason":res[:200]}
p=os.path.join(d,"payouts.json")
t=json.load(open(p)) if os.path.exists(p) else {"items":[]}
r.update({"usd":amt,"at":datetime.datetime.utcnow().isoformat()+"Z","token":os.environ.get("PAYOUT_TOKEN_ADDRESS","USDC/Base")})
t["items"].append(r); json.dump(t,open(p,"w"),indent=2)
print("OK" if r.get("ok") else "PENDING: "+str(r.get("reason")))
PY
