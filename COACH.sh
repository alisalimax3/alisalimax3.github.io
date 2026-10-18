#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  COACH.sh — مدرّب خطوة بخطوة. أنت: الصق · اضغط · Enter. وأنا الباقي.
#  bash COACH.sh            → A-ADS (ابدأ بها)
#  bash COACH.sh adsterra | exoclick | monetag
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" tools; export GHTMP="$TMPDIR"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
kv(){ python3 - "$1" <<'PY'
import sys
try:
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if s.startswith(sys.argv[1]+"="): print(s.split("=",1)[1]); break
except Exception: pass
PY
}
setkv(){ python3 - "$1" "$2" <<'PY'
import sys, os, time
k,v=sys.argv[1],sys.argv[2]; E={}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if "=" in s and not s.startswith("#"):
            a,b=s.split("=",1); E[a.strip()]=b.strip()
E[k]=v
open("keys.env","w",encoding="utf-8").write("# CineHub 3099\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
PY
}
clip(){ termux-clipboard-get 2>/dev/null | tr -d '\r\n'; }
clipset(){ printf '%s' "$1" | termux-clipboard-set 2>/dev/null || true; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || true; }
newpass(){ python3 -c "import secrets,string as s;print(''.join(secrets.choice(s.ascii_letters+s.digits) for _ in range(13)))"; }
go(){ printf '\n%s▸ %s%s\n' "$B" "$1" "$N"; }
enter(){ printf '  %s[اضغط Enter عندما تنتهي · q للخروج]%s › ' "$D" "$N"
  local x=""; read -r x </dev/tty 2>/dev/null || x=""; [ "$x" = "q" ] && exit 0; }

# ── الهدف ──
T="${1:-aads}"
case "$T" in
  aads|"")      KEY=AADS_UNIT;      DOM=a-ads;     NAME="A-ADS"
                SIGNUP="https://a-ads.com/"; PANEL="https://a-ads.com/ad_units"
                COPY='الكود كاملًا أو الرقم فقط (data-aa)'; RE='[0-9]{4,8}'
                VURL='https://a-ads.com/api/v1/banners/{v}'; EX="." ;;
  adsterra)     KEY=ADSTERRA_API_KEY; DOM=adsterra; NAME="Adsterra"
                SIGNUP="https://publishers.adsterra.com/signup"; PANEL="https://publishers.adsterra.com/settings/api"
                COPY='مفتاح API'; RE='[A-Za-z0-9_-]{20,48}'
                VURL='https://api3.adsterra.com/api/v1/publisher/balance'; EX="" ;;
  exoclick)     KEY=EXOCLICK_ZONE;  DOM=exoclick;  NAME="ExoClick"
                SIGNUP="https://www.exoclick.com/signup/"; PANEL="https://admin.exoclick.com/zones.php"
                COPY='رقم Zone ID'; RE='[0-9]{5,9}'; VURL=""; EX="" ;;
  monetag)      KEY=MONETAG_MULTITAG; DOM=monetag; NAME="Monetag"
                SIGNUP="https://monetag.com/"; PANEL="https://publisher.monetag.com/"
                COPY='معرّف Multitag'; RE='[0-9]{5,9}'; VURL=""; EX="" ;;
  *) echo "استخدم: bash COACH.sh [aads|adsterra|exoclick|monetag]"; exit 0 ;;
esac

printf '\n%s╔══════════════════════════════════════════════════╗\n' "$C"
printf '║  %s — تسجيل موجّه خطوة بخطوة              ║\n' "$NAME"
printf '╚══════════════════════════════════════════════════╝%s\n' "$N"

if [ -n "$(kv "$KEY")" ]; then
  printf '%s✓%s لديك %s = %s مسبقًا\n' "$G" "$N" "$KEY" "$(kv "$KEY")"
  printf '  تريد استبداله؟ (Enter للمتابعة · q خروج) › '; read -r a </dev/tty 2>/dev/null || a=""
  [ "$a" = "q" ] && exit 0
fi

# ── البريد ──
MU="$(kv MAIL_USER)"
if [ -z "$MU" ]; then
  go "بريدك (Gmail) — أكتبه مرة واحدة فقط"
  printf '  البريد › '; read -r MU </dev/tty 2>/dev/null || MU=""
  printf '  كلمة مرور التطبيق (16 حرفًا من myaccount.google.com → الأمان) › '
  read -r MP </dev/tty 2>/dev/null || MP=""
  [ -n "$MU" ] && setkv MAIL_USER "$MU"
  [ -n "$MP" ] && setkv MAIL_APP_PASS "$MP"
fi
MP="$(kv MAIL_APP_PASS)"
PW="$(newpass)"

# ── الخطوات ──
go "الخطوة 1 من 6 — افتح الموقع واضغط Sign up"
printf '  %s\n' "$SIGNUP"
clipset "$MU"; openurl "$SIGNUP"
enter

go "الخطوة 2 من 6 — في خانة البريد: الصق"
printf '  %sبريدك في الحافظة الآن: %s%s  ← اضغط لصق (Paste)\n' "$C" "$MU" "$N"
enter

go "الخطوة 3 من 6 — في خانة كلمة المرور: الصق"
clipset "$PW"
printf '  %sكلمة المرور في الحافظة الآن: %s%s  ← اضغط لصق\n' "$C" "$PW" "$N"
printf '  %sاكتبها أو احفظها: %s%s\n' "$D" "$PW" "$N"
enter

go "الخطوة 4 من 6 — أكمل الحقول واضغط زر التسجيل"
printf '  إن طلب تأكيد البريد، لا تغلق الصفحة — سنفتح الرابط تلقائيًا.\n'
enter

go "الخطوة 5 من 6 — سأبحث عن رسالة التأكيد في بريدك وأفتحها"
printf '  %s(حتى 4 دقائق — إن لم تصل، أرسلها من الموقع ثم اضغط Enter)%s\n' "$D" "$N"
L="$(MU="$MU" MP="$MP" python3 tools/mailopen.py "$DOM" 240 2>/dev/null || true)"
if [ -n "$L" ]; then
  printf '%s✓%s رابط التأكيد: %.90s\n' "$G" "$N" "$L"
  openurl "$L"; sleep 2; enter
else
  printf '%s!%s لم أجد الرسالة — افتحها يدويًا ثم Enter\n' "$Y" "$N"; enter
fi

go "الخطوة 6 من 6 — افتح اللوحة وأنشئ وحدة/منطقة"
printf '  %s\n' "$PANEL"
printf '  أنشئ: Banner 300x250 · ثم انسخ: %s\n' "$COPY"
printf '  %s[انسخ من الصفحة — سيُلتقط تلقائيًا. اكتب s للتخطي]%s\n' "$D" "$N"
openurl "$PANEL" &
prev="$(clip)"; t0=$(date +%s)
while :; do
  sleep 2
  line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
  [ "$line" = "s" ] && { printf '\n  تُخطّي\n'; exit 0; }
  now="$(clip)"
  if [ -n "$now" ] && [ "$now" != "$prev" ]; then
    prev="$now"
    for v in $(printf '%s' "$now" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^${RE}$" | head -6); do
      [ ${#v} -lt 4 ] && continue
      [ "$v" = "$MU" ] && continue
      if [ -n "$VURL" ]; then
        B2="$(curl -fsS -m 15 "${VURL//\{v\}/$v}" 2>/dev/null)" || B2=""
        [ -n "$EX" ] && [ -n "$B2" ] && { printf '%s' "$B2" | grep -qF "$EX" || continue; }
      fi
      setkv "$KEY" "$v"
      printf '\n%s✓%s %s = %s\n' "$G" "$N" "$KEY" "$v"
      printf '  جاري الربط والنشر…\n'
      bash PUSH.sh >/dev/null 2>&1 && printf '%s✓%s رُفع — الإعلان سيظهر خلال دقائق\n' "$G" "$N" \
                                   || printf '%s!%s حُفظ لكن الدفع فشل — نفّذ: bash PUSH.sh\n' "$Y" "$N"
      printf '\n  التالي: %sbash COACH.sh %s%s\n\n' "$B" "$(case $T in aads) echo adsterra;; adsterra) echo exoclick;; exoclick) echo monetag;; *) echo aads;; esac)" "$N"
      exit 0
    done
    printf '\r%-70s\r%s✗%s مرفوض: %.38s\n' '' "$R" "$N" "$now"
  fi
  el=$(( $(date +%s) - t0 )); [ "$el" -ge 1800 ] && { echo "  انتهت المهلة"; exit 1; }
  printf '\r%-70s' "$(printf '  … %dث — انسخ %s' "$el" "$COPY")"
done
