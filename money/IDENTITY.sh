#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$H/lib/identity.js"
node "$H/lib/profile.js"
echo
echo "  ★ تحقّق من 2FA:  node money/lib/totp.js \"\$(grep -m1 '^TOTP_SECRET=' keys.env | cut -d= -f2)\""
echo "  ★ ملف الهوية  :  money/data/identity.json"
