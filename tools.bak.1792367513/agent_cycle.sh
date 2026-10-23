#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."; mkdir -p .state; LOG=.state/log.txt
run(){ [ -f "$1" ] && python3 "$1" >>"$LOG" 2>&1 || true; }
run tools/apply_keys.py; run tools/autodetect.py
run tools/revenue_pull.py; run tools/revenue.py; run tools/pull_revenue.py
run tools/ledger.py; run tools/insights.py
PLATFORM_TARGET=1000 PAGES_LIMIT="${PAGES_LIMIT:-40}" run tools/pages_gen.py
run tools/treasury.py; run tools/withdraw_auto.py; run tools/status.py; run tools/report.py
python3 - <<'PY' >>"$LOG" 2>&1
import json,datetime
p="pulse.json"; d={}
try: d=json.load(open(p,encoding="utf-8"))
except Exception: pass
d["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
d["cycle"]=int(d.get("cycle",0))+1
json.dump(d,open(p,"w"),ensure_ascii=False,indent=1)
PY
echo "cycle $(date -u +%FT%TZ) ok"
