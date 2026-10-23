#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs data; export GHTMP="$TMPDIR"
unlock(){ local n=0; while [ -f .git/index.lock ]; do n=$((n+1)); [ $n -gt 40 ] && { rm -f .git/index.lock; break; }; sleep 3; done; }
while :; do
  python3 tools/tasks.py >> logs/agentd.log 2>&1
  python3 - <<'PY' >> logs/agentd.log 2>&1
import json, time
try: st = json.load(open("agent_state.json", encoding="utf-8"))
except Exception: st = {}
st.update({"cycles": st.get("cycles", 0) + 1, "at": time.strftime("%F %H:%M"), "status": "ok"})
json.dump(st, open("agent_state.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
  unlock; git add -A >/dev/null 2>&1
  git -c user.email=a@c.local -c user.name=agent commit -m "agent $(date +%F_%H%M)" >/dev/null 2>&1
  unlock; git push --force origin main >/dev/null 2>&1
  sleep 900
done
