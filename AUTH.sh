#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  AUTH.sh — انسخ كود الإعلان فقط. يُلتقط · يُربط · يُنشر · رمز تفويض
#  bash AUTH.sh        (مراقبة الحافظة — q للخروج)
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs data; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/auth.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
clip(){ termux-clipboard-get 2>/dev/null | tr -d '\r\n'; }
openurl(){ termux-open-url "$1" >/dev/null 2>&1 || am start -a android.intent.action.VIEW -d "$1" >/dev/null 2>&1 || true; }
setkv(){ python3 - "$1" "$2" <<'PY'
import sys, os
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

hd "1 · التفويض"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
if [ -z "$U" ]; then
  wrn "لا تفويض — افتح والصق الرمز"
  python3 tools/auth_device.py || true
  T="$(cat "$GHTMP/gh_tok" 2>/dev/null || true)"
  [ -n "$T" ] && { printf '%s' "$T" > .secrets.gh_token; chmod 600 .secrets.gh_token
                   U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"; }
fi
[ -n "$U" ] || { bad "لا تفويض"; exit 1; }
ok "مفوَّض: $U"
R="$U.github.io"; SITE="https://$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
git config --local credential.helper ""; git config --local pull.rebase true

newcode(){ python3 -c "import hashlib,time;print(hashlib.sha256(('$U|%s'%time.time()).encode()).hexdigest()[:16])"; }

pushit(){
  rm -f .git/index.lock 2>/dev/null
  git add -A >/dev/null 2>&1
  local COD; COD="$(newcode)"
  local NK; NK="$(grep -c '=' keys.env 2>/dev/null || true)"
  local VMSG="delegate: $U $COD keys=$NK"
  git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
  git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
  for i in 1 2 3; do
    rm -f .git/index.lock 2>/dev/null
    if [ "$i" = 1 ]; then timeout 900 git push origin main >/dev/null 2>&1 && { printf '%s' "$COD"; return 0; }
    elif [ "$i" = 2 ]; then timeout 900 git push --force origin main >/dev/null 2>&1 && { printf '%s' "$COD"; return 0; }
    else timeout 900 git push --force --no-thin origin main >/dev/null 2>&1 && { printf '%s' "$COD"; return 0; }; fi
  done
  return 1
}

# جدول التعرّف: بادئة → المفتاح|regex|رابط تحقق|المتوقع
DET='a-ads.com|AADS_UNIT|[0-9]{4,8}|https://a-ads.com/api/v1/banners/{v}|.'
DET="$DET"$'\n''data-aa|AADS_UNIT|[0-9]{4,8}|https://a-ads.com/api/v1/banners/{v}|.'
DET="$DET"$'\n''exoclick|EXOCLICK_ZONE|[0-9]{5,9}||'
DET="$DET"$'\n''juicyads|JUICYADS_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''jads.js|JUICYADS_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''monetag|MONETAG_MULTITAG|[0-9]{5,9}||'
DET="$DET"$'\n''adsterra|ADSTERRA_API_KEY|[A-Za-z0-9_-]{20,48}|https://api3.adsterra.com/api/v1/publisher/balance|'
DET="$DET"$'\n''hilltopads|HILLTOPADS_ZONE|[0-9]{3,9}||'
DET="$DET"$'\n''popads|POPADS_SITE_ID|[0-9]{4,9}||'
DET="$DET"$'\n''propellerads|PROPELLER_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''clickadu|CLICKADU_ZONE|[0-9]{3,9}||'
DET="$DET"$'\n''plugrush|PLUGRUSH_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''adcash|ADCASH_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''ad-maven|ADMAVEN_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''galaksion|GALAKSION_ZONE|[0-9]{3,9}||'
DET="$DET"$'\n''evadav|EVADAV_ZONE|[0-9]{3,9}||'
DET="$DET"$'\n''mybid|MYBID_ZONE|[0-9]{3,9}||'
DET="$DET"$'\n''trafficjunky|TRAFFICJUNKY_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''stripchat|STRIPCHAT_AFF|[A-Za-z0-9_-]{4,32}||'
DET="$DET"$'\n''bongacams|BONGA_AFF|[A-Za-z0-9_-]{4,32}||'
DET="$DET"$'\n''livejasmin|JASMIN_AFF|[A-Za-z0-9_-]{4,32}||'
DET="$DET"$'\n''cpagrip|CPAGRIP_SMARTLINK|[A-Za-z0-9_./:-]{6,80}||'
DET="$DET"$'\n''ogads|OGADS_SMARTLINK|[A-Za-z0-9_./:-]{6,80}||'
DET="$DET"$'\n''linkvertise|LINKVERTISE_UID|[0-9]{4,9}||'
DET="$DET"$'\n''ca-pub-|ADSENSE_CLIENT|ca-pub-[0-9]{10,20}||'
DET="$DET"$'\n''googlesyndication|ADSENSE_CLIENT|ca-pub-[0-9]{10,20}||'
DET="$DET"$'\n''themoviedb|TMDB_KEY|[0-9a-fA-F]{32}|https://api.themoviedb.org/3/configuration?api_key={v}|images'
DET="$DET"$'\n''omdbapi|OMDB_API_KEY|[A-Za-z0-9]{6,12}|https://www.omdbapi.com/?apikey={v}&t=Inception|True'
DET="$DET"$'\n''tvmaze|TVMAZE_KEY|[A-Za-z0-9]{4,32}||'
DET="$DET"$'\n''watchmode|WATCHMODE_KEY|[A-Za-z0-9]{20,40}||'
DET="$DET"$'\n''fanart|FANART_API_KEY|[A-Za-z0-9]{16,40}||'
DET="$DET"$'\n''trakt|TRAKT_CLIENT_ID|[A-Za-z0-9]{20,64}||'
DET="$DET"$'\n''usdt|USDT_TRC20|T[1-9A-HJ-NP-Za-km-z]{33}||'

try_detect(){
  local blob="$1" low line frag key re vurl exp v B2
  low="$(printf '%s' "$blob" | tr 'A-Z' 'a-z')"
  while IFS='|' read -r frag key re vurl exp; do
    [ -z "${frag:-}" ] && continue
    case "$low" in *"$frag"*) ;; *) continue ;; esac
    for v in $(printf '%s' "$blob" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^${re}$" | head -6); do
      [ ${#v} -lt 4 ] && continue
      if [ -n "$vurl" ]; then
        B2="$(curl -fsS -m 15 "${vurl//\{v\}/$v}" 2>/dev/null || true)"
        [ -n "$exp" ] && [ -n "$B2" ] && { printf '%s' "$B2" | grep -qF "$exp" || continue; }
      fi
      printf '%s|%s' "$key" "$v"; return 0
    done
  done <<< "$DET"
  return 1
}

hd "2 · الجاهزية"
printf '  %sالطريقة: افتح أي موقع إعلان → سجّل → انسخ الكود → ارجع هنا. سيُلتقط وحده.%s\n' "$D" "$N"
printf '  %sالمواقع: a-ads.com · exoclick.com · publishers.adsterra.com · monetag.com%s\n' "$D" "$N"
printf '  %sالأوامر: p = حالة المفاتيح · o = فتح a-ads · q = خروج%s\n\n' "$D" "$N"
printf '  رمز تفويضك الحالي: %s%s%s\n' "$B" "$(newcode)" "$N"

hd "3 · مراقبة الحافظة"
prev="$(clip)"; t0=$(date +%s); n=0
while :; do
  sleep 2
  line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
  case "$line" in
    q|Q) break ;;
    o|O) openurl "https://a-ads.com/"; printf '  ↗ فُتح a-ads\n'; continue ;;
    p|P) printf '\n'; python3 -c "
import os
E={}
if os.path.exists('keys.env'):
    for ln in open('keys.env',encoding='utf-8'):
        s=ln.strip()
        if '=' in s and not s.startswith('#'):
            k,v=s.split('=',1); E[k.strip()]=v.strip()
for k in sorted(E): print('   %-22s %s' % (k, E[k][:34]))
print('   الإجمالي: %d' % len(E))"; printf '\n'; continue ;;
  esac
  now="$(clip)"
  if [ -z "$now" ] || [ "$now" = "$prev" ]; then
    el=$(( $(date +%s) - t0 ))
    printf '\r%-74s' "$(printf '  … %dث — انسخ كود إعلان وسيُلتقط' "$el")"
    continue
  fi
  prev="$now"
  R2="$(try_detect "$now" || true)"
  if [ -z "$R2" ]; then
    printf '\r%-74s\r%s·%s لم أتعرّف (%.30s)\n' '' "$Y" "$N" "$now"
    printf '\r%-74s' "$(printf '  … انسخ الكود كاملًا أو رقمه فقط')"
    continue
  fi
  KEY="${R2%%|*}"; VAL="${R2#*|}"
  setkv "$KEY" "$VAL"; n=$((n+1))
  printf '\r%-74s\r' ''
  ok "التُقط: $KEY = $VAL"
  python3 - <<'PY' >/dev/null 2>&1
import json, os
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
try: a = json.load(open("ads.json", encoding="utf-8"))
except Exception: a = {}
nets = {x.get("k"): x for x in (a.get("networks") or []) if x.get("k")}
for k, n in nets.items():
    v = E.get(k) or ""; n["id"] = v; n["enabled"] = bool(v)
a["networks"] = list(nets.values())
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
  for s in inject_hits revenue_sync vault money dashboard share; do
    [ -f "tools/$s.py" ] && python3 "tools/$s.py" >/dev/null 2>&1 || true
  done
  COD="$(pushit || true)"
  if [ -n "$COD" ]; then
    ok "رُفع · رمز التفويض الجديد: $B$COD$N"
    printf '  التطبيق: %s/app.html · الروابط: %s/links.html\n' "$SITE" "$SITE"
  else wrn "حُفظ لكن الدفع فشل — bash PUSH.sh"; fi
  printf '  %sانسخ كودًا آخر، أو q للخروج%s\n' "$D" "$N"
done

hd "الخلاصة"
python3 - <<'PY' | tee -a "$LOG"
import json, os
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
live = [x for x in (json.load(open("ads.json", encoding="utf-8")).get("networks") or []) if x.get("id")]
print("  شبكات مفعّلة: %d" % len(live))
for x in live: print("    ✓ %-18s %s" % (x.get("n"), x.get("pay")))
print("  مفاتيح كلية: %d" % len(E))
PY
printf '\n  الموقع: %s/ · الخزينة: %s/wallet.html\n  السجل: %s\n' "$SITE" "$SITE" "$LOG"
