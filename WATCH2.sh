#!/data/data/com.termux/files/usr/bin/bash
# مراقب صارم: يلتقط كود الإعلان فقط · يربط · ينشر · رمز تفويض
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs data; export GHTMP="$TMPDIR"
LOG="logs/watch2.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
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
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { echo "لا تفويض — bash FINAL.sh"; exit 1; }
SITE="https://$U.github.io"
LAST="$(cat .tmp/lastcode 2>/dev/null || true)"

DET='a-ads.com|AADS_UNIT|[0-9]{4,8}|https://a-ads.com/api/v1/banners/{v}|.'
DET="$DET"$'\n''a-ads|AADS_UNIT|[0-9]{4,8}||'
DET="$DET"$'\n''data-aa|AADS_UNIT|[0-9]{4,8}||'
DET="$DET"$'\n''exoclick|EXOCLICK_ZONE|[0-9]{5,9}||'
DET="$DET"$'\n''s.exoclick|EXOCLICK_ZONE|[0-9]{5,9}||'
DET="$DET"$'\n''zoneid|EXOCLICK_ZONE|[0-9]{5,9}||'
DET="$DET"$'\n''zone_id|EXOCLICK_ZONE|[0-9]{5,9}||'
DET="$DET"$'\n''juicyads|JUICYADS_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''jads.js|JUICYADS_ZONE|[0-9]{4,9}||'
DET="$DET"$'\n''monetag|MONETAG_MULTITAG|[0-9]{5,9}||'
DET="$DET"$'\n''multitag|MONETAG_MULTITAG|[0-9]{5,9}||'
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
DET="$DET"$'\n''trc20|USDT_TRC20|T[1-9A-HJ-NP-Za-km-z]{33}||'
DET="$DET"$'\n''usdt|USDT_TRC20|T[1-9A-HJ-NP-Za-km-z]{33}||'

bad_token(){ printf '%s' "$1" | grep -qE '^[A-Z][A-Z_]{5,}$'; }

try_detect(){
  local blob="$1" low frag key re vurl exp v B2 n=${#1}
  # 1) NAME=value
  if printf '%s' "$blob" | grep -qE '^[A-Z][A-Z0-9_]{2,}=[^= ]'; then
    key="$(printf '%s' "$blob" | grep -oE '^[A-Z][A-Z0-9_]{2,}' | head -1)"
    v="$(printf '%s' "$blob" | sed -n "s/^${key}=//p" | head -1 | tr -d ' \r\n')"
    [ -n "$v" ] && { printf '%s|%s' "$key" "$v"; return 0; }
  fi
  low="$(printf '%s' "$blob" | tr 'A-Z' 'a-z')"
  # 2) اسم نطاق معروف → إلزامي للنصوص الطويلة
  while IFS='|' read -r frag key re vurl exp; do
    [ -z "${frag:-}" ] && continue
    case "$low" in *"$frag"*) ;; *) continue ;; esac
    for v in $(printf '%s' "$blob" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^${re}$" | head -6); do
      [ ${#v} -lt 4 ] && continue
      bad_token "$v" && continue
      if [ -n "$vurl" ]; then
        B2="$(curl -fsS -m 15 "${vurl//\{v\}/$v}" 2>/dev/null || true)"
        [ -n "$exp" ] && [ -n "$B2" ] && { printf '%s' "$B2" | grep -qF "$exp" || continue; }
      fi
      printf '%s|%s' "$key" "$v"; return 0
    done
  done <<< "$DET"
  # 3) نص قصير فقط → مطابقة حرّة بمفتاح واحد
  [ "$n" -gt 60 ] && return 1
  python3 - "$blob" "$LAST" <<'PY'
import sys, os, re, json
blob, last = sys.argv[1], sys.argv[2]
if blob == last or re.match(r'^[0-9a-fA-F]{16}$', blob): sys.exit(1)
if re.match(r'^[A-Z][A-Z_]{5,}$', blob): sys.exit(1)
CAT = {"AADS_UNIT":r'\d{4,8}',"EXOCLICK_ZONE":r'\d{5,9}',"JUICYADS_ZONE":r'\d{4,9}',
 "HILLTOPADS_ZONE":r'\d{3,9}',"CLICKADU_ZONE":r'\d{3,9}',"ADMAVEN_ZONE":r'\d{4,9}',
 "GALAKSION_ZONE":r'\d{3,9}',"MYBID_ZONE":r'\d{3,9}',"EVADAV_ZONE":r'\d{3,9}',
 "LINKVERTISE_UID":r'\d{4,9}',"POPADS_SITE_ID":r'\d{4,9}',"PROPELLER_ZONE":r'\d{4,9}',
 "ADCASH_ZONE":r'\d{4,9}',"TMDB_KEY":r'[0-9a-fA-F]{32}',"OMDB_API_KEY":r'[A-Za-z0-9]{6,12}'}
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
tok = [t for t in re.split(r'[^A-Za-z0-9._~\-]+', blob) if len(t) >= 4]
hit = [k for k, rx in CAT.items() if any(re.match("^%s$" % rx, t) for t in tok)]
if len(hit) == 1:
    for t in tok:
        if re.match("^%s$" % CAT[hit[0]], t): print("%s|%s" % (hit[0], t)); sys.exit(0)
sys.exit(1)
PY
}

printf '\n%s══ مراقبة الحافظة (صارم) ══%s\n' "$C" "$N"
printf '  انسخ كود الإعلان من الموقع — سيُلتقط خلال ثانيتين.\n'
printf '  %so فتح a-ads · p الحالة · s تجاهل · x KEY مسح مفتاح · q خروج%s\n' "$D" "$N"
printf '  %s(رمز التفويض والكلمات الإنجليزية مُتجاهلة تلقائيًا)%s\n\n' "$D" "$N"

prev="$(clip)"; t0=$(date +%s)
while :; do
  sleep 2
  line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
  case "$line" in
    q|Q) break ;;
    o|O) openurl "https://a-ads.com/"; printf '  ↗ a-ads\n'; continue ;;
    s|S) prev="$(clip)"; printf '  · تُجوهل\n'; continue ;;
    p|P) printf '\n'; python3 -c "
import os
E={}
if os.path.exists('keys.env'):
    for ln in open('keys.env',encoding='utf-8'):
        s=ln.strip()
        if '=' in s and not s.startswith('#'):
            k,v=s.split('=',1); E[k.strip()]=v.strip()
for k in sorted(E): print('   %-22s %s' % (k, E[k][:36]))
print('   الإجمالي: %d' % len(E))"; printf '\n'; continue ;;
    x*) KEY="${line#x}"; KEY="$(printf '%s' "$KEY" | tr -d ' ')"; [ -z "$KEY" ] && continue
        python3 - "$KEY" <<'PY'
import sys, os
k = sys.argv[1]; E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            a, b = s.split("=", 1)
            if a.strip() != k: E[a.strip()] = b.strip()
open("keys.env","w",encoding="utf-8").write("# CineHub 3099\n"+"\n".join("%s=%s"%(x,E[x]) for x in sorted(E))+"\n")
print("   مُسح: %s" % k)
PY
        continue ;;
  esac
  now="$(clip)"
  if [ -z "$now" ] || [ "$now" = "$prev" ]; then
    printf '\r%-74s' "$(printf '  … %dث — انسخ كود إعلان' $(( $(date +%s) - t0 )))"
    continue
  fi
  prev="$now"
  R2="$(try_detect "$now" || true)"
  if [ -z "$R2" ]; then
    printf '\r%-74s\r%s·%s لم يُعرَف (%.30s) — انسخ الكود مع اسم النطاق\n' '' "$Y" "$N" "$now"
    continue
  fi
  KEY="${R2%%|*}"; VAL="${R2#*|}"
  setkv "$KEY" "$VAL"
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
  rm -f .git/index.lock 2>/dev/null
  git add -A >/dev/null 2>&1
  COD="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|%s'%time.time()).encode()).hexdigest()[:16])")"
  printf '%s' "$COD" > .tmp/lastcode; LAST="$COD"
  NK="$(grep -c '=' keys.env 2>/dev/null || true)"
  VMSG="delegate: $U $COD keys=$NK"
  printf 'CineHub 3099 — تفويض\nالحساب: %s\nالموقع: %s\nالرمز: %s\nالمفاتيح: %s\n' "$U" "$SITE" "$COD" "$NK" > verify.txt
  git add -A >/dev/null 2>&1
  git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
  git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
  P=0
  for i in 1 2 3; do
    rm -f .git/index.lock 2>/dev/null
    if [ "$i" = 1 ]; then timeout 900 git push origin main >/dev/null 2>&1 && P=1
    elif [ "$i" = 2 ]; then timeout 900 git push --force origin main >/dev/null 2>&1 && P=1
    else timeout 900 git push --force --no-thin origin main >/dev/null 2>&1 && P=1; fi
    [ "$P" = 1 ] && break
  done
  if [ "$P" = 1 ]; then
    ok "رُفع · رمز التفويض الجديد: $B$COD$N"
    printf '  التطبيق: %s/app.html · الروابط: %s/links.html · الخزينة: %s/wallet.html\n' "$SITE" "$SITE" "$SITE"
  else wrn "حُفظ — الدفع فشل"; fi
  printf '  %sانسخ كودًا آخر أو q%s\n' "$D" "$N"
done

printf '\n%s══ الخلاصة ══%s\n' "$C" "$N"
python3 -c "
import json, os
E={}
if os.path.exists('keys.env'):
    for ln in open('keys.env',encoding='utf-8'):
        s=ln.strip()
        if '=' in s and not s.startswith('#'):
            k,v=s.split('=',1); E[k.strip()]=v.strip()
live=[x for x in (json.load(open('ads.json',encoding='utf-8')).get('networks') or []) if x.get('id')]
print('  شبكات مفعّلة: %d' % len(live))
for x in live: print('    ✓ %-18s %s' % (x.get('n'), x.get('pay')))
"
printf '  الموقع: %s/ · الخزينة: %s/wallet.html\n' "$SITE" "$SITE"
