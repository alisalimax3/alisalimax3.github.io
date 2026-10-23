#!/data/data/com.termux/files/usr/bin/bash
# money/AGENTD.sh — مشغّل الوكلاء (للتشغيل من Termux widget / plugin)
cd "$(dirname "$0")/.." || exit 1
export PATH="$PREFIX/bin:$PATH"
mkdir -p money/logs
pkill -f 'money/agentd.mjs' 2>/dev/null; sleep 1

if [ -f money/agentd.mjs ]; then
  nohup node money/agentd.mjs supervise >> money/logs/sup.out 2>&1 &
else
  for f in heal.mjs panel.mjs agent.mjs tick.mjs; do
    [ -f "money/$f" ] && nohup node "money/$f" >> "money/logs/${f%.mjs}.log" 2>&1 &
  done
fi
sleep 2
echo "✓ الوكلاء: $(pgrep -af 'money/' | grep -v AGENTD | wc -l) عملية"
