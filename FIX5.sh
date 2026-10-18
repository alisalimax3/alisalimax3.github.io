#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools; export GHTMP="$TMPDIR"
G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; B=$'\033[1m'; D=$'\033[2m'; N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N"; }

hd "1 · تطهير keys.env بنمط صارم لكل مفتاح"
python3 - <<'PY'
import os, re
PAT = {
 "AADS_UNIT": r'^\d{4,8}$',
 "ADSTERRA_API_KEY": r'^[A-Za-z0-9_-]{20,}$',
 "ADSTERRA_BANNER_TOP": r'^[A-Za-z0-9_-]{6,}$',
 "EXOCLICK_ZONE": r'^\d{5,9}$',
 "JUICYADS_ZONE": r'^\d{4,9}$',
 "MONETAG_MULTITAG": r'^\d{5,9}$',
 "USDT_TRC20": r'^T[1-9A-HJ-NP-Za-km-z]{33}$',
 "GH_TOKEN": r'^(gh[pousr]_|github_pat_)[A-Za-z0-9_]{20,}$',
 "GITHUB_TOKEN": r'^(gh[pousr]_|github_pat_)[A-Za-z0-9_]{20,}$',
 "MAIL_USER": r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$',
 "MAIL_APP_PASS": r'^[A-Za-z0-9]{16}$',
 "KURAIMI_SWIFT": r'^[A-Z]{8,11}$',
 "OWNER_WHATSAPP": r'^\d{9,15}$',
 "KURAIMI_PHONE": r'^\d{7,15}$',
 "KURAIMI_ACCOUNT": r'^\d{6,20}$',
}
DOM = re.compile(r'^[a-z0-9\-]+(\.[a-z0-9\-]+)+$', re.I)
E, drop = {}, []
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.rstrip("\n")
        if "=" not in s or s.lstrip().startswith("#"): continue
        k, v = s.split("=", 1); k, v = k.strip(), v.strip()
        if not v: continue
        why = None
        if k in PAT and not re.match(PAT[k], v): why = "شكل خاطئ"
        elif k not in PAT and DOM.match(v) and "@" not in v: why = "اسم نطاق لا مفتاح"
        elif any(ch in v for ch in "…⏳·«»؟✓✗"): why = "نص توضيحي"
        if why: drop.append((k, v, why)); continue
        E[k] = v
open("keys.env", "w", encoding="utf-8").write(
    "# CineHub 3099 — مطهّر\n" + "\n".join("%s=%s" % (k, E[k]) for k in sorted(E)) + "\n")
print("  حُذفت %d قيمة · بقي %d" % (len(drop), len(E)))
for k, v, w in drop: print("    ✗ %-20s %-28s (%s)" % (k, v[:28], w))
PY

hd "2 · التحقق من بريدك حيًّا (IMAP)"
imaptest(){ U="$1" P="$2" python3 - <<'PY'
import imaplib, os
try:
    M = imaplib.IMAP4_SSL("imap.gmail.com"); M.login(os.environ["U"], os.environ["P"])
    M.select("INBOX"); M.logout(); print("OK")
except Exception as e: print("ERR " + str(e)[:70])
PY
}
kvget(){ python3 - "$1" <<'PY'
import sys
try:
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if s.startswith(sys.argv[1]+"="): print(s.split("=",1)[1]); break
except Exception: pass
PY
}
kvset(){ python3 - "$1" "$2" <<'PY'
import sys, os
k,v=sys.argv[1],sys.argv[2]; E={}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s=ln.strip()
        if "=" in s and not s.startswith("#"):
            a,b=s.split("=",1); E[a.strip()]=b.strip()
E[k]=v
open("keys.env","w",encoding="utf-8").write("# CineHub 3099 — مطهّر\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
PY
}
MU="$(kvget MAIL_USER)"; MP="$(kvget MAIL_APP_PASS)"
[ -z "$MU" ] && { printf '  بريدك › '; read -r MU </dev/tty; kvset MAIL_USER "$MU"; }
i=0
while [ $i -lt 3 ]; do
  i=$((i+1))
  if [ -n "$MP" ]; then R="$(imaptest "$MU" "$MP")"; else R="ERR فارغة"; fi
  case "$R" in
    OK) ok "البريد يعمل: $MU"; break ;;
    *) bad "فشل: $R"
       printf '\n  %sلإنشاء كلمة مرور تطبيق صحيحة:%s\n' "$D" "$N"
       printf '   1) myaccount.google.com → الأمان → فعّل «التحقق بخطوتين»\n'
       printf '   2) ثم ابحث عن «كلمات مرور التطبيقات» → أنشئ واحدة لـ Mail\n'
       printf '   3) ستحصل على 16 حرفًا في 4 مجموعات — أدخلها %sبدون مسافات%s\n\n' "$B" "$N"
       printf '  كلمة مرور التطبيق (16 حرفًا) › '; read -r MP </dev/tty
       MP="$(printf '%s' "$MP" | tr -d ' ')"
       kvset MAIL_APP_PASS "$MP"
       [ $i -ge 3 ] && wrn "استمر رغم الفشل — التأكيد سيصير يدويًا" ;;
  esac
done

hd "3 · ALL.sh — كل المواقع في أمر واحد"
cat > ALL.sh <<'AEOF'
#!/data/data/com.termux/files/usr/bin/bash
# تشغيل متسلسل: أنت تلصق وتضغط Enter فقط
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR"; export GHTMP="$TMPDIR"
G=$'\033[32m';Y=$'\033[33m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
LIST="${1:-aads adsterra exoclick monetag}"
printf '\n%s╔═══════════════════════════════════════════════════════╗\n' "$B"
printf '║  تفويض كامل: أنت تلصق وتضغط Enter — والباقي تلقائي  ║\n'
printf '╚═══════════════════════════════════════════════════════╝%s\n' "$N"
for t in $LIST; do
  bash COACH.sh "$t" || true
  printf '\n%sاضغط Enter للموقع التالي · q للخروج · إعادة: bash COACH.sh %s%s › ' "$D" "$t" "$N"
  read -r x </dev/tty 2>/dev/null || x=""
  [ "$x" = "q" ] && break
done
printf '\n%s✓ الربط والنشر النهائي…%s\n' "$G" "$N"
bash PUSH.sh 2>&1 | tail -3
printf '\n  الخزينة : https://alisalimax3.github.io/wallet.html\n'
printf '  الأموال : https://alisalimax3.github.io/money.html\n'
printf '  سجّل هنا ما فعلته: %s\n' "$(ls -t logs/coach.* 2>/dev/null | head -1)"
AEOF
chmod +x ALL.sh; bash -n ALL.sh && ok "ALL.sh جاهز"
bash -n COACH.sh && ok "COACH.sh سليم"

hd "4 · الحالة الآن"
python3 - <<'PY'
import os, json
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
need = ["AADS_UNIT", "ADSTERRA_API_KEY", "EXOCLICK_ZONE", "MONETAG_MULTITAG", "USDT_TRC20"]
for k in need:
    print(("  ✓ %-18s %s" % (k, E[k])) if E.get(k) else ("  · %-18s — ينتظر التسجيل" % k))
print("  مفاتيح كلية: %d" % len(E))
PY
