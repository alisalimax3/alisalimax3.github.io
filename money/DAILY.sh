#!/usr/bin/env bash
# مهام يومية حقيقية — تُشغّل مرة أو في حلقة
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
L="$ROOT/logs/daily.log"; mkdir -p "$ROOT/logs"
run(){ echo "[$(date -u +%H:%M:%S)] ▶ $1" | tee -a "$L"
  shift; for t in "$@"; do [ -f "$H/$t" ] && bash "$H/$t" >>"$L" 2>&1 || true; done; }
cycle(){
  run "فحص المصادر"     KEYLESS.sh
  run "حصد الأرباح"     HARVEST.sh PAYOUT.sh
  run "نشر تلقائي"      AUTOPOST.sh
  run "حقن الإعلانات"   INJECT-ADS.sh
  run "تقرير"           REPORT.sh
}
if [ "${1:-once}" = "loop" ]; then
  IV="${INTERVAL:-21600}"
  echo "  ▶ حلقة يومية كل ${IV}ث — Ctrl+C للإيقاف"; trap 'echo; exit 0' INT
  while :; do cycle; sleep "$IV"; done
else cycle; fi
