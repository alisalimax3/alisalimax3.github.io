#!/usr/bin/env bash
# تقرير يومي حقيقي بالأرقام
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
D="$(date -u +%F)"; R="$DATA/report-$D.md"
python3 - "$DATA" "$R" "$D" <<'PY'
import json,os,sys
d,p,day=sys.argv[1],sys.argv[2],sys.argv[3]
def g(n,f="{}"):
    x=os.path.join(d,n); return json.load(open(x)) if os.path.exists(x) else json.loads(f)
ks=g("keys-status.json",'{"summary":{},"keys":[]}'); tr=g("treasury.json",'{}'); led=g("ledger.json",'{"chain":[],"total":0}')
today=[r for r in led.get("chain",[]) if r["date"]==day]
per={}
for r in today: per[r["net"]]=round(per.get(r["net"],0)+r["usd"],6)
open(p,"w").write(f"""# تقرير CineHub — {day}

| | |
|---|---|
| أرباح اليوم | ${round(sum(r['usd'] for r in today),6)} |
| الإجمالي | ${led.get('total',0)} |
| قابل للسحب | ${tr.get('available_usd',0)} |
| مسحوب | ${tr.get('paid_out_usd',0)} |
| مفاتيح حيّة | {ks['summary'].get('live',0)} |
| مصادر ربح حيّة | {len([k for k in ks['keys'] if k['status']=='LIVE' and k.get('revenue_source')])} |

## تفصيل اليوم
"""+"\n".join(f"- {k}: ${v}" for k,v in sorted(per.items(),key=lambda x:-x[1]) or [("لا شيء بعد",0)])+"\n")
print("  ✔ "+p)
PY
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ] && curl -sS --max-time 12 -X POST \
 "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TG_CHAT_ID" \
 --data-urlencode "text=$(cat "$R")" >/dev/null 2>&1 && echo "  ✔ أُرسل لتيليجرام"
