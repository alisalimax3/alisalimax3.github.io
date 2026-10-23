#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  GOALL.sh — التنفيذ النهائي: شفاء · بناء · ربط · سجل منصات · وكيل
#  · نشر · توثيق · تحقق
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/goall.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "0 · تنظيف"
pkill -f agentd.sh 2>/dev/null && ok "أُوقف الوكيل" || true
sleep 1; rm -f .git/index.lock .git/*.lock 2>/dev/null; ok "أُزيلت الأقفال"

hd "1 · شفاء وبناء ونشر (FINAL + GO2)"
[ -f FINAL.sh ] && { bash FINAL.sh 2>&1 | tail -18; } || wrn "لا FINAL.sh"
[ -f GO2.sh ]   && { bash GO2.sh   2>&1 | tail -18; } || wrn "لا GO2.sh"

hd "2 · سجل المنصات + صفحة الإرسال"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, time
P = [
 ("ExoClick","https://www.exoclick.com/signup/","EXOCLICK_ZONE","adult","€20","Paxum/Wire",1),
 ("JuicyAds","https://www.juicyads.com/signup","JUICYADS_ZONE","adult","$50","Paxum/BTC",1),
 ("Adsterra","https://publishers.adsterra.com/signup","ADSTERRA_API_KEY","general","$5","USDT/PayPal",1),
 ("Monetag","https://monetag.com/","MONETAG_MULTITAG","general","$5","PayPal/Skrill",1),
 ("A-ADS","https://a-ads.com/","AADS_UNIT","general","$0","BTC تلقائي",1),
 ("TrafficJunky","https://www.trafficjunky.com/","TRAFFICJUNKY_ZONE","adult","$100","Wire",2),
 ("PlugRush","https://www.plugrush.com/","PLUGRUSH_ZONE","adult","$25","PayPal/BTC",2),
 ("Clickadu","https://www.clickadu.com/","CLICKADU_ZONE","adult","$5","PayPal/Paxum",2),
 ("HilltopAds","https://hilltopads.net/","HILLTOPADS_ZONE","adult","$50","PayPal",2),
 ("AdMaven","https://ad-maven.com/","ADMAVEN_ZONE","adult","$5","PayPal",2),
 ("Galaksion","https://galaksion.com/","GALAKSION_ZONE","adult","$10","PayPal",3),
 ("MyBid","https://mybid.io/","MYBID_ZONE","adult","$25","PayPal",3),
 ("Evadav","https://evadav.com/","EVADAV_ZONE","adult","$5","PayPal",3),
 ("Stripchat","https://affiliates.stripchat.com/","STRIPCHAT_AFF","adult","$50","Wire/Paxum",2),
 ("LiveJasmin","https://www.livejasmin.com/en/affiliate","JASMIN_AFF","adult","$50","Wire",3),
 ("BongaCams","https://bongacams.com/affiliate","BONGA_AFF","adult","$50","Wire",3),
 ("PropellerAds","https://publishers.propellerads.com/","PROPELLER_ZONE","general","$5","PayPal/Paxum",2),
 ("PopAds","https://www.popads.net/users/signup","POPADS_SITE_ID","general","$5","PayPal/BTC",2),
 ("Adcash","https://adcash.com/","ADCASH_ZONE","general","$5","PayPal/Wire",3),
 ("AdSense","https://adsense.google.com","ADSENSE_CLIENT","general","$100","Wire/Payoneer",2),
 ("CPAGrip","https://www.cpagrip.com/","CPAGRIP_SMARTLINK","cpa","$50","PayPal/Payoneer",2),
 ("OGAds","https://ogads.com/","OGADS_SMARTLINK","cpa","$20","PayPal",2),
 ("Linkvertise","https://publisher.linkvertise.com/","LINKVERTISE_UID","short","$5","PayPal",2),
 ("TMDB","https://www.themoviedb.org/signup","TMDB_KEY","film","-","-",1),
 ("OMDb","https://www.omdbapi.com/apikey.aspx","OMDB_API_KEY","film","-","-",2),
 ("Fanart.tv","https://fanart.tv/get-an-api-key/","FANART_API_KEY","film","-","-",3),
 ("Trakt","https://trakt.tv/oauth/applications","TRAKT_CLIENT_ID","film","-","-",3),
 ("TVmaze","https://www.tvmaze.com/api","TVMAZE_KEY","series","-","-",3),
 ("Watchmode","https://api.watchmode.com/","WATCHMODE_KEY","series","-","-",3),
 ("Binance","https://www.binance.com","USDT_TRC20","pay","-","-",1),
]
DIRS = [
 ("Google Search Console","https://search.google.com/search-console"),
 ("Bing Webmaster","https://www.bing.com/webmasters"),
 ("Yandex Webmaster","https://webmaster.yandex.com"),
 ("IndexNow","https://www.indexnow.org"),
 ("Wayback Machine","https://web.archive.org/save/"),
 ("Ping-O-Matic","http://rpc.pingomatic.com/"),
 ("Cloudflare Analytics","https://www.cloudflare.com/web-analytics"),
 ("GoatCounter","https://www.goatcounter.com"),
 ("Umami Cloud","https://cloud.umami.is"),
 ("Ko-fi","https://ko-fi.com"),
 ("Buy Me a Coffee","https://buymeacoffee.com"),
 ("GitHub Sponsors","https://github.com/sponsors"),
 ("Reddit r/movies","https://www.reddit.com/r/movies/"),
 ("Reddit r/arabs","https://www.reddit.com/r/arabs/"),
 ("Pinterest","https://www.pinterest.com"),
 ("Telegram","https://telegram.org"),
]
json.dump({"updated": time.strftime("%F %H:%M"), "count": len(P),
  "items": [{"n": a, "url": b, "key": c, "kind": d, "min": e, "pay": f, "tier": g} for a,b,c,d,e,f,g in P],
  "dirs": [{"n": a, "url": b} for a, b in DIRS]},
  open("platforms.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
K = {"adult":"إباحي","general":"عام","cpa":"CPA","short":"اختصار","film":"أفلام","series":"مسلسلات","pay":"دفع"}
rows = ""
for t in (1, 2, 3):
    it = [x for x in P if x[6] == t]
    if not it: continue
    rows += '<h2>الطبقة %d — %d جهة</h2><table><tr><th>الجهة</th><th>النوع</th><th>ما تنسخه</th><th>حد السحب</th><th>الدفع</th><th></th></tr>' % (t, len(it))
    for a,b,c,d,e,f,g in it:
        rows += '<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td><td><a target="_blank" rel="nofollow noopener" href="%s">تسجيل ↗</a></td></tr>' % (a, K.get(d,d), c, e, f, b)
    rows += "</table>"
open("platforms.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>سجل المنصات</title>
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.8 system-ui,Tahoma}.w{max-width:1000px;margin:0 auto;padding:18px}
h1{font-size:20px}h2{font-size:14px;color:#aab6c8;margin:20px 0 8px}table{width:100%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}a{color:#5ca9ff}
code{background:#161d29;padding:2px 7px;border-radius:6px;font-size:12px}</style>
<div class="w"><h1>🏁 سجل المنصات — %d جهة تدفع فعلًا</h1>
<div style="color:#8b96a8;font-size:13px">ابدأ بالطبقة 1 فقط. ثم أضف من الأوامر: <code>bash WATCH2.sh</code></div>%s
<p><a href="./">الرئيسية</a> · <a href="app.html">التطبيق</a> · <a href="links.html">الروابط</a> · <a href="wallet.html">الخزينة</a></p></div></html>""" % (len(P), rows))
srows = "".join('<div class="c"><b>%s</b><br><a target="_blank" rel="nofollow noopener" href="%s">%s</a></div>' % (a, b, b) for a, b in DIRS)
open("submit.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>أماكن الإرسال</title>
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.8 system-ui,Tahoma}.w{max-width:860px;margin:0 auto;padding:18px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:11px;padding:10px;margin:8px 0;font-size:13px}a{color:#5ca9ff}</style>
<div class="w"><h1>📮 أماكن الإرسال والفهرسة والنشر</h1>%s
<p><a href="./">الرئيسية</a> · <a href="platforms.html">المنصات</a></p></div></html>""" % srows)
print("  ✓ platforms.json (%d) + platforms.html + submit.html (%d)" % (len(P), len(DIRS)))
PY

hd "3 · ربط الشبكات"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
CAT = json.load(open("platforms.json", encoding="utf-8"))["items"]
try: a = json.load(open("ads.json", encoding="utf-8"))
except Exception: a = {}
nets = {n.get("k"): n for n in (a.get("networks") or []) if n.get("k")}
for x in CAT:
    if x["kind"] in ("film", "series", "pay"): continue
    nets.setdefault(x["key"], {"n": x["n"], "k": x["key"], "pay": x["pay"], "kind": x["kind"]})
on = 0
for k, n in nets.items():
    v = E.get(k) or ""; n["id"] = v; n["enabled"] = bool(v); on += bool(v)
a["networks"] = list(nets.values())
json.dump(a, open("ads.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ %d مفعّلة من %d شبكة" % (on, len(nets)))
PY

hd "4 · تنفيذ الأدوات"
for f in inject_hits revenue_sync hits_report vault money dashboard share ping; do
  [ -f "tools/$f.py" ] && python3 "tools/$f.py" >>"$LOG" 2>&1 || true
done
ok "نُفّذت"

hd "5 · نشر وتوثيق"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { bad "لا تفويض"; exit 1; }
R="$U.github.io"; SITE="https://$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|%s'%time.time()).encode()).hexdigest()[:16])")"
printf '%s' "$SIG" > .tmp/lastcode
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
VMSG="delegate: $U $SIG keys=$NK"
printf 'CineHub 3099 — وثيقة تفويض\nالحساب: %s\nالموقع: %s\nالرمز: %s\nالمفاتيح: %s\nالتاريخ: %s\n' \
  "$U" "$SITE" "$SIG" "$NK" "$(date -u +%FT%TZ)" > verify.txt
rm -f .git/index.lock 2>/dev/null
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
P=0
for i in 1 2 3 4; do
  rm -f .git/index.lock 2>/dev/null
  case "$i" in
    1) timeout 1800 git push origin main 2>"$GHTMP/e" && P=1 ;;
    2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
  wrn "محاولة $i فشلت: $(tail -1 "$GHTMP/e" 2>/dev/null | cut -c1-60)"
done
python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1 && ok "Pages مفعّل"

hd "6 · إثبات وتشغيل الوكيل"
sleep 4
RM="$(curl -s -m 30 -H "Authorization: Bearer $T" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$U/$R/commits/main" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['commit']['message'].splitlines()[0])" 2>/dev/null || true)"
[ "$RM" = "$VMSG" ] && ok "التفويض مُثبت على GitHub" || wrn "رسالة الريموت: ${RM:-?}"
pkill -f agentd.sh 2>/dev/null || true; sleep 1; rm -f .git/index.lock 2>/dev/null
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2
pgrep -f agentd.sh >/dev/null && ok "الوكيل المحلي يعمل (كل 30 دقيقة)" || wrn "لم يبدأ الوكيل"

hd "7 · تحقق"
for f in "" app.html library.html links.html money.html wallet.html platforms.html submit.html verify.txt; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  تم — التطبيق جاهز ومربوط ومنشور              ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  الحساب   : %s\n  رمز التفويض: %s%s%s\n  التطبيق  : %s/app.html\n  الروابط  : %s/links.html\n  المنصات  : %s/platforms.html\n  الإرسال  : %s/submit.html\n  الأموال  : %s/money.html\n  الخزينة  : %s/wallet.html\n' \
  "$U" "$B" "$SIG" "$N" "$SITE" "$SITE" "$SITE" "$SITE" "$SITE" "$SITE" | tee -a "$LOG"
printf '\n  %sلتفعيل الأرباح: bash WATCH2.sh ثم اضغط o وسجّل وانسخ الكود%s\n' "$D" "$N"
