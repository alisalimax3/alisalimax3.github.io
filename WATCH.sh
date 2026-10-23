#!/data/data/com.termux/files/usr/bin/bash
# مراقب الحافظة: يلتقط كود الإعلان ويربطه وينشره ويطبع رمز تفويض
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs data; export GHTMP="$TMPDIR"
LOG="logs/watch.$(date +%F_%H%M).log"; : > "$LOG"
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

python3 - <<'PY' >/dev/null 2>&1
import json
CAT = {"AADS_UNIT":r'\d{4,8}',"EXOCLICK_ZONE":r'\d{5,9}',"JUICYADS_ZONE":r'\d{4,9}',
 "TRAFFICJUNKY_ZONE":r'\d{4,9}',"PLUGRUSH_ZONE":r'\d{4,9}',"CLICKADU_ZONE":r'\d{3,9}',
 "HILLTOPADS_ZONE":r'\d{3,9}',"ADMAVEN_ZONE":r'\d{4,9}',"GALAKSION_ZONE":r'\d{3,9}',
 "MYBID_ZONE":r'\d{3,9}',"EVADAV_ZONE":r'\d{3,9}',"POPADS_SITE_ID":r'\d{4,9}',
 "PROPELLER_ZONE":r'\d{4,9}',"ADCASH_ZONE":r'\d{4,9}',"LINKVERTISE_UID":r'\d{4,9}',
 "STRIPCHAT_AFF":r'[A-Za-z0-9_-]{4,32}',"BONGA_AFF":r'[A-Za-z0-9_-]{4,32}',
 "JASMIN_AFF":r'[A-Za-z0-9_-]{4,32}',"ADSTERRA_API_KEY":r'[A-Za-z0-9_-]{20,48}',
 "ADSENSE_CLIENT":r'ca-pub-\d{10,20}',"USDT_TRC20":r'T[1-9A-HJ-NP-Za-km-z]{33}',
 "TMDB_KEY":r'[0-9a-fA-F]{32}',"OMDB_API_KEY":r'[A-Za-z0-9]{6,12}',
 "CPAGRIP_SMARTLINK":r'[A-Za-z0-9_./:-]{6,80}',"OGADS_SMARTLINK":r'[A-Za-z0-9_./:-]{6,80}'}
json.dump(CAT, open("data/cat.json","w"), indent=1)
PY

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
DET="$DET"$'\n''usdt|USDT_TRC20|T[1-9A-HJ-NP-Za-km-z]{33}||'
DET="$DET"$'\n''trc20|USDT_TRC20|T[1-9A-HJ-NP-Za-km-z]{33}||'

toks(){ printf '%s' "$1" | tr -c 'A-Za-z0-9._~-' '\n' | grep -E "^$2$" | head -6; }
try_detect(){
  local blob="$1" low frag key re vurl exp v B2
  # 1) NAME=value صريح
  if printf '%s' "$blob" | grep -qE '^[A-Z][A-Z0-9_]{2,}=[^= ]'; then
    key="$(printf '%s' "$blob" | grep -oE '^[A-Z][A-Z0-9_]{2,}' | head -1)"
    v="$(printf '%s' "$blob" | sed -n "s/^${key}=//p" | head -1 | tr -d ' \r\n')"
    [ -n "$v" ] && { printf '%s|%s' "$key" "$v"; return 0; }
  fi
  low="$(printf '%s' "$blob" | tr 'A-Z' 'a-z')"
  while IFS='|' read -r frag key re vurl exp; do
    [ -z "${frag:-}" ] && continue
    case "$low" in *"$frag"*) ;; *) continue ;; esac
    for v in $(toks "$blob" "$re"); do
      [ ${#v} -lt 4 ] && continue
      if [ -n "$vurl" ]; then
        B2="$(curl -fsS -m 15 "${vurl//\{v\}/$v}" 2>/dev/null || true)"
        [ -n "$exp" ] && [ -n "$B2" ] && { printf '%s' "$B2" | grep -qF "$exp" || continue; }
      fi
      printf '%s|%s' "$key" "$v"; return 0
    done
  done <<< "$DET"
  # 2) وضع حرّ: مفتاح واحد فقط فارغ ومطابق
  python3 - "$blob" "$LAST" <<'PY'
import sys, os, re, json
blob, last = sys.argv[1], sys.argv[2]
CAT = json.load(open("data/cat.json", encoding="utf-8"))
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
if blob == last: sys.exit(1)
if re.match(r'^[0-9a-fA-F]{16}$', blob): sys.exit(1)   # رمز تفويض
tok = [t for t in re.split(r'[^A-Za-z0-9._~\-]+', blob) if len(t) >= 4]
hit = []
for k, rx in CAT.items():
    if E.get(k): continue
    if any(re.match("^%s$" % rx, t) for t in tok): hit.append(k)
if len(hit) == 1:
    for t in tok:
        if re.match("^%s$" % CAT[hit[0]], t): print("%s|%s" % (hit[0], t)); break
else: sys.exit(1)
PY
}

printf '\n%s══ مراقبة الحافظة ══%s\n' "$C" "$N"
printf '  انسخ كود إعلان من أي موقع (a-ads · exoclick · adsterra · monetag) وسيُلتقط.\n'
printf '  %sأوامر: o فتح a-ads · p حالة المفاتيح · s تجاهل الحالي · q خروج%s\n' "$D" "$N"
printf '  %sملاحظة: رمز التفويض (%s) مُتجاهَل تلقائيًا.%s\n\n' "$D" "${LAST:0:16}" "$N"

prev="$(clip)"; t0=$(date +%s)
while :; do
  sleep 2
  line=""; read -r -t 1 line </dev/tty 2>/dev/null || true
  case "$line" in
    q|Q) break ;;
    o|O) openurl "https://a-ads.com/"; printf '  ↗ a-ads\n'; continue ;;
    s|S) prev="$(clip)"; printf '  · تُجوهل الحالي\n'; continue ;;
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
  esac
  now="$(clip)"
  if [ -z "$now" ] || [ "$now" = "$prev" ]; then
    el=$(( $(date +%s) - t0 ))
    printf '\r%-74s' "$(printf '  … %dث — انسخ كود إعلان' "$el")"
    continue
  fi
  prev="$now"
  R2="$(try_detect "$now" || true)"
  if [ -z "$R2" ]; then
    printf '\r%-74s\r%s·%s لم يُعرَف (%.26s) — انسخ الكود كاملًا\n' '' "$Y" "$N" "$now"
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
  cat > verify.txt <<VEOF
CineHub 3099 — تفويض
الحساب: $U
الموقع: $SITE
الرمز: $COD
المفاتيح: $NK
VEOF
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
    printf '  التطبيق: %s/app.html · الروابط: %s/links.html\n' "$SITE" "$SITE"
  else wrn "حُفظ — الدفع فشل (bash PUSH.sh)"; fi
  printf '  %sانسخ كودًا آخر أو q%s\n' "$D" "$N"
done
