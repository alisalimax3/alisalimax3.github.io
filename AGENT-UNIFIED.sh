#!/data/data/com.termux/files/usr/bin/bash
# نسخة موحّدة — تفوّض كل شيء إلى الوكيل الجديد
cd "$HOME/cinehub3099"
case "${1:-help}" in
  install|setup|fix|repair) python3 tools/doctor.py ;;
  audit) python3 tools/audit.py ;;
  status) python3 tools/agent.py status ;;
  auto|pilot) python3 tools/agent.py auto ;;
  vpn|connect) bash vpn.sh ;;
  run|start) shift; python3 tools/agent.py reg "$@" ;;
  *) echo "install|audit|status|auto|run <id>|vpn" ;;
esac
