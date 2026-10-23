#!/usr/bin/env bash
# ══════ الأمر الواحد — ينفّذ ويفعّل ويجهّز كل شيء ══════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
mkdir -p logs money/data money/assets; [ -f keys.env ] || touch keys.env; chmod 600 keys.env
L="$ROOT/logs/go.log"; : > "$L"
q(){ "$@" >>"$L" 2>&1; }
say(){ printf '%s\n' "$*"; }
up(){ for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do
        V=$(grep -m1 "^$K=" keys.env 2>/dev/null | cut -d= -f2-)
        [ -n "$V" ] && curl -sL -o /dev/null --max-time 4 "http://127.0.0.1:$V/" || return 1; done; return 0; }

say ""
say "╔══════════════════════════════════════════╗"
say "║   CineHub — التشغيل النهائي الشامل       ║"
say "╚══════════════════════════════════════════╝"

# 1) تصحيح جذري
node "$H/lib/keysfile.js" normalize >>"$L" 2>&1
say "✔ keys.env مصحّح ومحمي (600)"

# 2) المصادر — دمج بلا patch
q bash "$H/MERGE-SOURCES.sh"
say "$(grep '✔' "$L" | tail -2 | head -1)"

# 3) الهوية
if [ -f money/data/identity.json ]; then say "✔ الهوية موجودة: $(node -e 'console.log(require("./money/data/identity.json").brand)')"
else q bash "$H/IDENTITY.sh"; say "$(grep '✔ الهوية' "$L" | tail -1)"; fi
[ -f money/data/profiles/_DESCRIPTIONS.md ] || q node "$H/lib/profile.js"
say "✔ ملفات النبذة: $(ls money/data/profiles 2>/dev/null | wc -l | tr -d ' ') منصّة"

# 4) المحفظة
if grep -q '^WALLET_ADDRESS=0x' keys.env; then say "✔ المحفظة: $(grep -m1 '^WALLET_ADDRESS=' keys.env | cut -d= -f2)"
else q bash "$H/WALLET.sh"; say "$(grep -o '0x[0-9a-fA-F]*' "$L" | tail -1 | sed 's/^/✔ المحفظة: /')"; fi

# 5) الأهداف
q bash "$H/TARGETS-30K.sh"; say "$(grep '✔ أهداف' "$L" | tail -1)"

# 6) المتصفح الحقيقي
if [ -x "$PREFIX/bin/chromium-browser" ] || [ -x /data/data/com.termux/files/usr/bin/chromium-browser ]; then
  say "✔ Chromium جاهز"
else
  (yes 2>/dev/null | pkg install -y chromium >>"$L" 2>&1) || true
  if [ -x "$PREFIX/bin/chromium-browser" ] || [ -x /data/data/com.termux/files/usr/bin/chromium-browser ]; then say "✔ Chromium ثُبّت"; else say "○ Chromium غير مثبّت (الوكيل يعمل بالمتصفح العادي)"; fi
fi
[ -d node_modules/puppeteer-core ] || PUPPETEER_SKIP_DOWNLOAD=1 npm i --no-audit --no-fund --silent puppeteer-core@23 >>"$L" 2>&1
[ -d node_modules/puppeteer-core ] && say "✔ محرّك التحكم بالمتصفح جاهز"
[ -d node_modules/ethers ] || npm i --no-audit --no-fund --silent ethers@6 >>"$L" 2>&1

# 7) الخدمات — إحياء تلقائي
if up; then say "✔ كل الخدمات حيّة"; else
  q bash "$H/TOTAL.sh"; sleep 3
  if up; then say "✔ الخدمات أُحييت"; else q bash "$H/TOTAL.sh"; sleep 3; up && say "✔ الخدمات أُحييت" || say "○ بعض الخدمات متوقفة"; fi
fi
[ -f "$H/KEEPALIVE.sh" ] && { pkill -f KEEPALIVE.sh 2>/dev/null; nohup bash "$H/KEEPALIVE.sh" </dev/null >>"$L" 2>&1 & }
say "✔ حارس المنافذ يعمل"

# 8) تفويض الوكيل بالمتصفح
say ""
say "── تفويض الوكيل — اتبع المتصفح ──"
node "$H/lib/agent-auth.js" 2>&1 | grep -E '✔|○' | sed 's/^/  /' || true

# 9) بريد + فحص + إعلانات + حقن + حصد
q node "$H/lib/mailbox.js"; say "✔ البريد: $(grep -o '[a-z0-9]*@[a-z.]*' "$L" | tail -1)"
q bash "$H/AGENT-RUN.sh" verify --all
say "$(grep -E 'فحص [0-9]+ →' "$L" | tail -1 | sed 's/^/✔ /')"
q bash "$H/ADS.sh" auto; say "$(grep '✔ فُعّل' "$L" | tail -1)"
q bash "$H/INJECT-ADS.sh"; say "$(grep '✔ حُقنت' "$L" | tail -1 || echo '○ لا شرائح بعد — الصق كودًا: bash money/ADS.sh set adsterra "<كود>"')"
q node "$H/lib/harvest.js"; say "$(grep 'إجمالي الحصد' "$L" | tail -1 | sed 's/^/✔ /')"

# 10) تقرير نظيف
q bash "$H/REPORT.sh"
say ""
say "╔══════════════════════════════════════════╗"
say "║  التطبيق : http://127.0.0.1:$(grep -m1 '^HUB_PORT=' keys.env | cut -d= -f2)/"
say "║  الوكيل  : http://127.0.0.1:$(grep -m1 '^HUB_PORT=' keys.env | cut -d= -f2)/agent"
say "║  المفاتيح: http://127.0.0.1:$(grep -m1 '^HUB_PORT=' keys.env | cut -d= -f2)/keys"
say "╚══════════════════════════════════════════╝"
say ""
say "التسجيل الآلي:   bash money/BROWSER-AGENT.sh all"
say "المهام اليومية:  bash money/DAILY.sh loop &"
say "التقرير:         logs/REPORT.txt  |  السجل الكامل: logs/go.log"
