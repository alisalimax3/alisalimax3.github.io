#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
case "${1:-help}" in
  install)
    echo "── تجهيز المتصفح الحقيقي (مرة واحدة) ──"
    pkg install -y chromium >/dev/null 2>&1 || echo "  ⚠ ثبّت chromium يدويًا: pkg install chromium"
    PUPPETEER_SKIP_DOWNLOAD=1 npm i --no-audit --no-fund --silent puppeteer-core@23 >/dev/null 2>&1
    node -e 'console.log("  ✔ chromium: "+(process.env.CHROME_PATH||"auto-detect"))'
    echo "  ✔ puppeteer-core مثبّت — الوكيل سيملأ ويُرسل وحده" ;;
  *) exec node "$H/lib/browser-agent.js" "$@" ;;
esac
