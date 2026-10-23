#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
R="$H/data/signup-recipes.json"
case "${1:-list}" in
  list) node "$H/lib/signup.js" list ;;
  inspect) node "$H/lib/signup.js" inspect "$2" ;;
  tier)
    T="${2:-A}"; node -e 'const r=require(process.argv[1]);r.filter(x=>x.tier===process.argv[2]).forEach(x=>console.log(x.id))' "$R" "$T" |
    while read -r id; do echo "──────── $id ────────"; node "$H/lib/signup.js" try "$id"; sleep 4; done ;;
  one) node "$H/lib/signup.js" try "$2" ;;
  *) echo "الأوامر: list | tier A|B|C | one <id> | inspect <url>" ;;
esac
