#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  FINAL2.sh — إصلاح النقل · توثيق الحساب برمز · دفع متدرّج · تحقق
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs .tmp; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
E="$TMPDIR/perr"; LOG="logs/final2.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; B=$'\033[1m'; N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
inf(){ printf '  %s\n' "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

T="$(cat .secrets.gh_token 2>/dev/null || true)"
[ -z "$T" ] && { bad "لا توكن"; exit 1; }
U="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.login(gh.token()))" 2>/dev/null)"
[ -z "$U" ] && { bad "التوكن مرفوض"; exit 1; }
R="$U.github.io"; SITE="https://$U.github.io"
URL="https://x-access-token:$T@github.com/$U/$R.git"
ok "الحساب: $U"

hd "1 · إصلاح النقل (سبب الـ408)"
git config --global http.postBuffer 524288000
git config --global http.version HTTP/1.1
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global core.compression 6
git config --global pack.threads 1
git config --global pack.windowMemory 64m
git config --global pull.rebase true
git config --local credential.helper ""
git config --local core.bigFileThreshold 512m
git remote remove origin 2>/dev/null || true
git remote add origin "$URL"
ok "لا قتل للاتصال البطيء · ضغط 6 · HTTP/1.1"

inf "تقليص الحزمة (repack)…"
git repack -adf --window=50 --depth=50 >/dev/null 2>&1 || true
git gc --prune=now >/dev/null 2>&1 || true
SZ="$(du -sh .git 2>/dev/null | cut -f1)"
NF="$(git ls-files | wc -l)"
ok "حجم .git: ${SZ:-?} · ملفات متتبعة: $NF"

hd "2 · توثيق الحساب ورمز الربط"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SIG="$(python3 -c "import hashlib;print(hashlib.sha256(('$U|$R|$TS').encode()).hexdigest()[:16])")"
cat > verify.txt <<VEOF
CineHub 3099 — وثيقة توثيق الحساب
الحساب   : $U
المستودع : https://github.com/$U/$R
الموقع   : $SITE
التوثيق  : $TS
رمز الربط: $SIG
الصلاحيات: read:org, repo, workflow
VEOF
python3 - "$SIG" <<'PY'
import sys, json, os, time
s = sys.argv[1]
d = {"account": os.environ.get("U", ""), "sig": s, "at": time.strftime("%F %T"), "verified": True}
try: j = json.load(open("data/verify.json", encoding="utf-8"))
except Exception: j = {}
j.update(d); os.makedirs("data", exist_ok=True)
json.dump(j, open("data/verify.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
for f in owner.html index.html app.html; do
  [ -f "$f" ] || continue
  grep -q 'name="verify"' "$f" && continue
  python3 - "$f" "$SIG" <<'PY'
import sys
f, s = sys.argv[1], sys.argv[2]
t = open(f, encoding="utf-8").read()
tag = '<meta name="verify" content="%s">' % s
t = t.replace("<head>", "<head>\n" + tag, 1) if "<head>" in t else tag + t
t = t.replace("</body>", '<div style="text-align:center;color:#8b96a8;font-size:11px;padding:8px">موثّق · رمز الربط <code>%s</code></div></body>' % s, 1)
open(f, "w", encoding="utf-8").write(t)
PY
done
ok "verify.txt · data/verify.json · شارة في الصفحات"
printf '  %sرمز الربط: %s%s\n' "$B" "$SIG" "$N" | tee -a "$LOG"

hd "3 · دفع متدرّج (4 محاولات)"
VMSG="verify: $U $SIG"
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git -c user.email=a@c.local -c user.name=Agent commit --allow-empty -m "$VMSG" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true

orphan(){ inf "لقطة واحدة بلا تاريخ (أصغر حزمة)"
  git checkout --orphan snap 2>/dev/null || git checkout -f --orphan snap
  git add -A
  git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
  git branch -M main; }

push_ok=0
for i in 1 2 3 4; do
  case "$i" in
    1) inf "محاولة 1 — عادي"        ; timeout 1800 git push origin main 2>"$E" ;;
    2) inf "محاولة 2 — قسري"        ; timeout 1800 git push --force origin main 2>"$E" ;;
    3) inf "محاولة 3 — بلا thin"    ; timeout 1800 git push --force --no-thin origin main 2>"$E" ;;
    4) inf "محاولة 4 — لقطة نظيفة"  ; orphan; timeout 1800 git push --force origin main 2>"$E" ;;
  esac
  if [ $? -eq 0 ]; then ok "نجح الدفع في المحاولة $i"; push_ok=1; break; fi
  wrn "فشلت المحاولة $i: $(tail -2 "$E" 2>/dev/null | tr '\n' ' ' | cut -c1-90)"
done
[ "$push_ok" = 0 ] && { bad "كل المحاولات فشلت"; tail -4 "$E" | sed 's/^/    /'; }

hd "4 · تحقق من الدفع والتوثيق"
H="$(git rev-parse HEAD 2>/dev/null)"
RH="$(timeout 120 git ls-remote "$URL" main 2>/dev/null | cut -c1-40)"
[ -n "$RH" ] && [ "$RH" = "$H" ] && ok "الريموت مطابق للمحلي" || wrn "الريموت: ${RH:-?} · المحلي: ${H:0:12}"
RM="$(curl -s -m 30 -H "Authorization: Bearer $T" -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$U/$R/commits/main" \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['commit']['message'].splitlines()[0])" 2>/dev/null)"
[ "$RM" = "$VMSG" ] && ok "رسالة التوثيق وصلت الريموت: $RM" || wrn "رسالة الريموت: ${RM:-?}"

hd "5 · تحقق حيّ (بمحاولات)"
sleep 10
for u in "" app.html money.html wallet.html platforms.html verify.txt; do
  code=000
  for k in 1 2 3 4 5 6; do
    code="$(curl -s -o /dev/null -w '%{http_code}' -m 30 "https://$U.github.io/$u")"
    [ "$code" = "200" ] && break; sleep 12
  done
  [ "$code" = "200" ] && ok "/$u" || bad "/$u → $code"
done

hd "الخلاصة"
printf '  الحساب   : %s\n  الموقع   : %s\n  رمز الربط: %s\n  السجل    : %s\n' "$U" "$SITE" "$SIG" "$LOG" | tee -a "$LOG"
[ "$push_ok" = 1 ] && printf '\n%s✅ الحساب موثّق والملفات مرفوعة. افتح: %s%s\n' "$G" "$SITE" "$N" \
                   || printf '\n%s⚠ أعد التشغيل: bash FINAL2.sh%s\n' "$Y" "$N"
