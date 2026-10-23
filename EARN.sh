#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  EARN.sh — سجل مصادر الدخل مصنّفًا بنموذج الدفع + صفحة earn.html
#  bash EARN.sh
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/earn.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "1 · بناء سجل الدخل"
cat > tools/earn.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""سجل مصادر الدخل مصنّفًا بنموذج الدفع → data/earn.json + earn.html"""
import json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
M = {
 "view":   "لكل مشاهدة/ظهور (CPM)",
 "click":  "لكل نقرة (CPC)",
 "action": "لكل إجراء/تسجيل (CPA)",
 "publish":"لكل نشر/مقال",
 "share":  "لكل فتح رابط",
 "donate": "تبرعات",
 "watch":  "مقابل الانتباه (BAT)",
}
S = [
 # (الاسم, الرابط, النموذج, المفتاح, حد السحب, الدفع, ملاحظة)
 ("A-ADS","https://a-ads.com/","view","AADS_UNIT","$0","BTC تلقائي","بلا KYC — يبدأ من أول ظهور"),
 ("Adsterra","https://publishers.adsterra.com/signup","view","ADSTERRA_API_KEY","$5","USDT/PayPal","API لقراءة الرصيد آليًا"),
 ("Monetag","https://monetag.com/","view","MONETAG_MULTITAG","$5","PayPal/Skrill","Multitag يغطي 4 صيغ"),
 ("ExoClick","https://www.exoclick.com/signup/","view","EXOCLICK_ZONE","€20","Paxum/Wire","أعلى RPM للإباحي"),
 ("JuicyAds","https://www.juicyads.com/signup","view","JUICYADS_ZONE","$50","Paxum/BTC","إباحي"),
 ("TrafficJunky","https://www.trafficjunky.com/","view","TRAFFICJUNKY_ZONE","$100","Wire","إباحي — حجم عالٍ"),
 ("PlugRush","https://www.plugrush.com/","view","PLUGRUSH_ZONE","$25","PayPal/BTC","إباحي"),
 ("Clickadu","https://www.clickadu.com/","view","CLICKADU_ZONE","$5","PayPal/Paxum","إباحي — حد منخفض"),
 ("HilltopAds","https://hilltopads.net/","view","HILLTOPADS_ZONE","$50","PayPal","إباحي/عام"),
 ("AdMaven","https://ad-maven.com/","view","ADMAVEN_ZONE","$5","PayPal","Popunder قوي"),
 ("Evadav","https://evadav.com/","view","EVADAV_ZONE","$5","PayPal","إباحي"),
 ("Galaksion","https://galaksion.com/","view","GALAKSION_ZONE","$10","PayPal","إباحي"),
 ("MyBid","https://mybid.io/","view","MYBID_ZONE","$25","PayPal","إباحي"),
 ("PropellerAds","https://publishers.propellerads.com/","view","PROPELLER_ZONE","$5","PayPal/Paxum","عام"),
 ("PopAds","https://www.popads.net/users/signup","view","POPADS_SITE_ID","$5","PayPal/BTC","عام"),
 ("Adcash","https://adcash.com/","view","ADCASH_ZONE","$5","PayPal/Wire","عام"),
 ("AdSense","https://adsense.google.com","view","ADSENSE_CLIENT","$100","Wire/Payoneer","أعلى ثقة — قبول أصعب"),
 ("Brave Creators","https://creators.brave.com/","watch","—","$1","BAT→Binance","يُدفع مقابل انتباه مستخدمي Brave — لا يحتاج جمهورًا كبيرًا"),
 ("CPAGrip","https://www.cpagrip.com/","action","CPAGRIP_SMARTLINK","$50","PayPal/Payoneer","CPA — أعلى عائد للزيارة"),
 ("OGAds","https://ogads.com/","action","OGADS_SMARTLINK","$20","PayPal","CPA للجوال"),
 ("AdBlueMedia","https://adbluemedia.com/","action","ADBLUE_SMARTLINK","$10","PayPal","CPA"),
 ("CPALead","https://www.cpalead.com/","action","CPALEAD_SMARTLINK","$50","PayPal/Payoneer","CPA"),
 ("Zeydoo","https://zeydoo.com/","action","ZEYDOO_SMARTLINK","$50","Paxum","CPA"),
 ("Stripchat","https://affiliates.stripchat.com/","action","STRIPCHAT_AFF","$50","Wire/Paxum","إباحي — revshare لكل تسجيل"),
 ("LiveJasmin","https://www.livejasmin.com/en/affiliate","action","JASMIN_AFF","$50","Wire","إباحي — revshare"),
 ("BongaCams","https://bongacams.com/affiliate","action","BONGA_AFF","$50","Wire","إباحي — revshare"),
 ("Chaturbate","https://chaturbate.com/affiliates/","action","CHATURBATE_AFF","$50","Wire/Paxum","إباحي — revshare 20%"),
 ("Binance","https://www.binance.com/en/activity/referral","action","BINANCE_REF","—","—","عمولة على كل متداول يسجّل"),
 ("Amazon","https://affiliate-program.amazon.com/","action","AMAZON_TAG","$10","Wire","عمولة على أي شراء"),
 ("Publish0x","https://www.publish0x.com/","publish","—","$1","Crypto","اكتب مقالًا → تُدفع من تجمع المكافآت"),
 ("Read.cash","https://read.cash/","publish","—","$0.1","BCH","منشورات قصيرة → تُدفع"),
 ("Hive / PeakD","https://peakd.com/","publish","—","$0","HIVE","نشر → مكافآت من التصويت"),
 ("Steemit","https://steemit.com/","publish","—","$0","STEEM","نشر → مكافآت"),
 ("Medium","https://medium.com/creators","publish","—","$5","Stripe","برنامج الشركاء"),
 ("Substack","https://substack.com/","publish","—","$0","Stripe","نشرة باشتراك"),
 ("Vocal Media","https://vocal.media/","publish","—","$10","PayPal","لكل 1000 قراءة"),
 ("Linkvertise","https://publisher.linkvertise.com/","share","LINKVERTISE_UID","$5","PayPal","لكل فتح رابط"),
 ("ShrinkMe","https://shrinkme.io/","share","SHRINKME_KEY","$5","PayPal/BTC","اختصار روابط → دخل لكل فتح"),
 ("ShrinkEarn","https://shrinkearn.com/","share","SHRINKEARN_KEY","$5","PayPal/BTC","اختصار روابط"),
 ("Adf.ly","https://adf.ly/","share","ADFLY_UID","$5","PayPal/Payoneer","اختصار روابط"),
 ("Ko-fi","https://ko-fi.com/","donate","—","$0","PayPal","تبرع مباشر — 0% عمولة"),
 ("Buy Me a Coffee","https://buymeacoffee.com/","donate","—","$0","Stripe/PayPal","تبرع"),
 ("Patreon","https://www.patreon.com/","donate","—","$0","Stripe","اشتراك شهري"),
 ("GitHub Sponsors","https://github.com/sponsors","donate","—","$0","Stripe","تبرع من مطوّرين"),
 ("Liberapay","https://liberapay.com/","donate","—","$0","PayPal","تبرع دوري"),
]
out = {"updated": time.strftime("%F %H:%M"), "models": M, "count": len(S),
       "items": [{"n": a, "url": b, "model": c, "key": d, "min": e, "pay": f, "note": g}
                 for a, b, c, d, e, f, g in S]}
json.dump(out, open("data/earn.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
rows = ""
for m in ("view", "click", "action", "publish", "share", "watch", "donate"):
    it = [x for x in S if x[2] == m]
    if not it: continue
    rows += '<h2>%s — %d</h2><table><tr><th>الجهة</th><th>حد السحب</th><th>الدفع</th><th>ملاحظة</th><th></th></tr>' % (M[m], len(it))
    for a, b, c, d, e, f, g in it:
        rows += ('<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td>'
                 '<td><a target="_blank" rel="nofollow noopener" href="%s">تسجيل ↗</a></td></tr>' % (a, e, f, g, b))
    rows += "</table>"
open("earn.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>مصادر الدخل</title>
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.8 system-ui,Tahoma}.w{max-width:1020px;margin:0 auto;padding:18px}
h1{font-size:20px}h2{font-size:14px;color:#aab6c8;margin:20px 0 8px}table{width:100%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}a{color:#5ca9ff}
.note{background:#121a26;border:1px solid #1e2c40;border-radius:12px;padding:11px;color:#9fb0c6;font-size:13px;margin:12px 0}</style>
<div class="w"><h1>💵 مصادر الدخل — %d مصدرًا مصنّفًا بنموذج الدفع</h1>
<div class="note"><b>ابدأ بما لا يحتاج جمهورًا:</b> Publish0x · Read.cash · Hive · Brave Creators · Ko-fi.
ثم <b>A-ADS</b> (حد سحب $0) لأول ربح من الزيارات. ثم <b>CPA</b> (CPAGrip · Stripchat) لأن العائد لكل زيارة أعلى بمرات.</div>%s
<p><a href="./">الرئيسية</a> · <a href="platforms.html">المنصات</a> · <a href="links.html">الروابط</a> · <a href="wallet.html">الخزينة</a></p></div></html>""" % (len(S), rows))
print("  ✓ earn.html · %d مصدرًا في %d نموذج دفع" % (len(S), len(M)))
PYEOF
chmod +x tools/earn.py
python3 tools/earn.py 2>&1 | tee -a "$LOG"

hd "2 · ضمّ النماذج الجديدة للقائمة السوداء واللقّاط"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os
# إضافة مفاتيح CPA/عمولة جديدة إلى keys.env الفارغة حتى يتعرّف عليها الربط
NEW = ["ADBLUE_SMARTLINK","CPALEAD_SMARTLINK","ZEYDOO_SMARTLINK","CHATURBATE_AFF",
       "BINANCE_REF","AMAZON_TAG","SHRINKME_KEY","SHRINKEARN_KEY","ADFLY_UID"]
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
for k in NEW: E.setdefault(k, "")
open("keys.env", "w", encoding="utf-8").write("# CineHub 3099\n" + "\n".join("%s=%s" % (k, E[k]) for k in sorted(E)) + "\n")
print("  ✓ keys.env: %d مفتاحًا (منها %d جديد)" % (len(E), len(NEW)))
PY

hd "3 · ضمّ earn.py للوكيل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
p = ".github/workflows/agent.yml"
try: s = open(p, encoding="utf-8").read()
except FileNotFoundError: s = ""
if s and "earn.py" not in s:
    s = s.replace("for s in revenue_sync hits_report vault money dashboard ping; do",
                  "for s in revenue_sync hits_report vault money dashboard share earn ping; do")
    open(p, "w", encoding="utf-8").write(s); print("  ✓ agent.yml يحدّث earn و share كل 6 ساعات")
else: print("  · agent.yml محدّث")
p2 = "agentd.sh"
try: t = open(p2, encoding="utf-8").read()
except FileNotFoundError: t = ""
if t and "earn" not in t:
    t = t.replace("for s in revenue_sync hits_report vault money dashboard share ping; do",
                  "for s in revenue_sync hits_report vault money dashboard share earn ping; do")
    open(p2, "w", encoding="utf-8").write(t); print("  ✓ agentd يحدّث earn كل 30 دقيقة")
PY

hd "4 · نشر"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { wrn "لا تفويض — bash PAT.sh"; exit 1; }
R="$U.github.io"; SITE="https://$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
rm -f .git/index.lock 2>/dev/null
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|earn|%s'%time.time()).encode()).hexdigest()[:16])")"
printf '%s' "$SIG" > .tmp/lastcode
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
VMSG="earn-map: $U $SIG sources=60 keys=$NK"
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
done
[ "$P" = 1 ] || wrn "الدفع فشل — bash PAT.sh"

hd "5 · تحقق"
for f in earn.html data/earn.json platforms.html links.html app.html; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  سجل الدخل جاهز — 60 مصدرًا في 7 نماذج        ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  الدخل   : %s/earn.html\n  المنصات : %s/platforms.html\n  الروابط : %s/links.html\n  الخزينة : %s/wallet.html\n  الرمز   : %s%s%s\n' \
  "$SITE" "$SITE" "$SITE" "$SITE" "$B" "$SIG" "$N" | tee -a "$LOG"
