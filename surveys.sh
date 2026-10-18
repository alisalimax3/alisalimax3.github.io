#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
P="${1:-}"; T="${2:-}"
case "$P" in
  bitlabs|cpx|pollfish|adgate|adgem|lootably|timewall) : ;;
  *) echo "الاستخدام: bash surveys.sh <bitlabs|cpx|pollfish|adgate|adgem|lootably|timewall> TOKEN"; exit 1;;
esac
[ -z "$T" ] && { echo "✗ التوكن فارغ"; exit 1; }
[ "$T" = "TOKEN" ] && { echo "✗ لصقت كلمة TOKEN حرفيًا — الصق التوكن الحقيقي من لوحة المزوّد"; exit 1; }
python3 - "$P" "$T" <<'PY'
import json,sys,os
k,t=sys.argv[1],sys.argv[2]; p="surveys-config.json"
c=json.load(open(p,encoding="utf-8")) if os.path.exists(p) else {}
c[k]=t; json.dump(c,open(p,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
print("✓ %s مُفعّل"%k)
PY
