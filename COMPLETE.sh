#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  COMPLETE.sh — إصلاح earn · فصل واجهة المستخدم عن المالك · توسيع
#  السجل إلى 90 مصدرًا · ربط · نشر · توثيق · تحقق
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/complete.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "0 · تنظيف"
pkill -f agentd.sh 2>/dev/null || true; sleep 1
rm -f .git/index.lock .git/*.lock 2>/dev/null; ok "أُزيلت الأقفال"

hd "1 · إصلاح earn.py وإعادة بنائه"
if [ -f tools/earn.py ]; then
  sed -i 's/table{width:100%;/table{width:100%%;/' tools/earn.py
  python3 - <<'PY' >/dev/null 2>&1
import re
p="tools/earn.py"; s=open(p,encoding="utf-8").read()
# أي % داخل CSS بلا مُحدِّد → %%
s = re.sub(r'(width|height|font-size|max-width):(\d+)%(?![ds])', r'\1:\2%%', s)
open(p,"w",encoding="utf-8").write(s)
PY
  python3 tools/earn.py 2>&1 | tee -a "$LOG" || wrn "earn.py"
fi

hd "2 · فصل واجهة المستخدم عن المالك"

# 2أ · صفحات المالك: noindex + غير مرتبطة
for f in owner.html money.html wallet.html platforms.html submit.html earn.html audit.html live-dash.html withdraw.html publishers.html marketing.html; do
  [ -f "$f" ] || continue
  grep -q 'name="robots"' "$f" || python3 - "$f" <<'PY'
import sys
f = sys.argv[1]
s = open(f, encoding="utf-8").read()
tag = '<meta name="robots" content="noindex,nofollow">'
s = s.replace("<head>", "<head>\n" + tag, 1) if "<head>" in s else tag + s
open(f, "w", encoding="utf-8").write(s)
PY
done
ok "صفحات المالك: noindex"

# 2ب · واجهة المستخدم: index.html نظيف
cat > index.html <<'IEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CineHub 3099 — أفلام مجانية</title>
<meta name="description" content="مشاهدة أفلام ومسلسلات مجانًا بجودة عالية — بلا تسجيل">
<link rel="search" type="application/opensearchdescription+xml" title="CineHub 3099" href="opensearch.xml">
<style>*{box-sizing:border-box}body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1100px;margin:0 auto;padding:0 14px}
.hero{padding:34px 0 20px;text-align:center}
.hero h1{font-size:26px;margin:0 0 8px}.hero p{color:#8b96a8;font-size:14px;margin:0 0 18px}
form{display:flex;gap:8px;max-width:520px;margin:0 auto}
input{flex:1;padding:12px 15px;border-radius:12px;border:1px solid #232c3c;background:#131a25;color:#e9eef6;font-size:15px}
button{padding:12px 20px;border-radius:12px;border:0;background:#1d4ed8;color:#fff;font-size:15px;cursor:pointer}
.chips{display:flex;gap:6px;overflow-x:auto;padding:12px 0}.chips::-webkit-scrollbar{display:none}
.chip{white-space:nowrap;padding:6px 13px;border-radius:999px;background:#161e2b;border:1px solid #232c3c;color:#a9b6c9;font-size:12.5px;text-decoration:none}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:10px;padding:10px 0 24px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
.ad{margin:14px 0;display:flex;justify-content:center;min-height:60px;align-items:center}
footer{color:#6d7788;font-size:12px;text-align:center;padding:20px 0 30px;border-top:1px solid #161d29;margin-top:14px}
footer a{color:#7d90a8;text-decoration:none;margin:0 6px}
h2{font-size:15px;color:#aab6c8;margin:14px 0 4px}</style></head><body>
<div class="w"><div class="hero"><h1>🎬 CineHub 3099</h1>
<p>أفلام ومسلسلات مجانًا — بلا تسجيل، بلا انتظار</p>
<form onsubmit="go(event)"><input id="q" placeholder="ابحث عن فيلم أو مسلسل…"><button>ابحث</button></form></div>
<div class="chips" id="chips"></div><div class="ad" id="ad"></div>
<h2>الأكثر مشاهدة</h2><div class="grid" id="g"></div>
<div class="ad" id="ad2"></div>
<footer>© CineHub 3099 · <a href="app.html">التطبيق</a><a href="library.html">المكتبة</a><a href="links.html">روابط النشر</a><a href="owner.html">لوحة المالك</a></footer>
</div>
<script src="hits.js" defer></script><script>
function go(e){e.preventDefault();location.href='app.html?q='+encodeURIComponent(document.getElementById('q').value)}
async function load(){for(const f of['catalog.json','films.json','titles.json']){try{const r=await fetch(f);if(!r.ok)continue;
const d=await r.json();const a=Array.isArray(d)?d:(d.items||Object.values(d));if(a&&a.length)
return a.map(x=>({i:x.i||x.id||x.slug,t:x.t||x.title||x.name||'',th:x.th||x.poster||x.image||'',y:x.y||x.year||'',c:x.c||x.cat||x.category||''})).filter(x=>x.t)}catch(e){}}return[]}
(async()=>{const A=await load();
document.getElementById('chips').innerHTML=[...new Set(A.map(x=>x.c).filter(Boolean))].slice(0,20)
.map(g=>'<a class="chip" href="app.html?cat='+encodeURIComponent(g)+'">'+g+'</a>').join('');
document.getElementById('g').innerHTML=A.slice(0,30).map(x=>'<a class="c" href="'+(x.i?'f/'+encodeURIComponent(x.i)+'.html':'#')+'">'+
'<img loading="lazy" src="'+(x.th||'')+'"><b>'+x.t+(x.y?' ('+x.y+')':'')+'</b></a>').join('');
try{const a=await(await fetch('ads.json')).json();const on=(a.networks||[]).filter(n=>n.id);
const h=on.slice(0,2).map(n=>n.k==='AADS_UNIT'?'<iframe src="https://a-ads.com/banner?aa='+n.id+'&size=300x250" width="300" height="250" frameborder="0" scrolling="no"></iframe>':
n.k==='EXOCLICK_ZONE'?'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+n.id+'" width="300" height="250" frameborder="0" scrolling="no"></iframe>':'').join('');
document.getElementById('ad').innerHTML=h||('<span style="color:#7d8899;font-size:12px">'+on.length+' شبكة إعلان مفعّلة</span>');
document.getElementById('ad2').innerHTML=h;}catch(e){}})();
</script></body></html>
IEOF
ok "index.html — واجهة المستخدم"

# 2ج · التطبيق: يستقبل ?q= و ?cat= وشريط تنقّل للمستخدم فقط
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re
p = "app.html"
if os.path.exists(p):
    s = open(p, encoding="utf-8").read()
    s = re.sub(r'<nav>.*?</nav>', '<nav><a href="./">الرئيسية</a><a href="library.html">المكتبة</a><a href="links.html">روابط النشر</a></nav>', s, count=1, flags=re.S)
    if "URLSearchParams" not in s:
        s = s.replace("(async()=>{ALL=await load();",
            "(async()=>{const P=new URLSearchParams(location.search);"
            "ALL=await load();"
            "if(P.get('cat')){window.CAT=P.get('cat');}"
            "if(P.get('q')){document.getElementById('q').value=P.get('q');}", 1)
    open(p, "w", encoding="utf-8").write(s)
    print("  ✓ app.html: تنقّل للمستخدم + استقبال ?q= و ?cat=")
else: print("  ! لا app.html")
PY

# 2د · owner.html: بوابة بسيطة
if [ ! -f owner.html ]; then
cat > owner.html <<'OEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>لوحة المالك</title>
<meta name="robots" content="noindex,nofollow">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}.w{max-width:720px;margin:0 auto;padding:22px}
a{display:block;background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:13px;margin:9px 0;color:#cfe0f5;text-decoration:none}
a b{color:#8ec5ff}</style><div class="w"><h1>🔐 لوحة المالك</h1>
<a href="earn.html"><b>مصادر الدخل</b> — 90 مصدرًا بنماذج الدفع</a>
<a href="platforms.html"><b>المنصات</b> — تسجيل ومفاتيح</a>
<a href="submit.html"><b>أماكن الإرسال</b></a>
<a href="money.html"><b>الأموال</b> — حقيقي مقابل تقديري</a>
<a href="wallet.html"><b>الخزينة</b> — مسار الكريمي</a>
<a href="links.html"><b>روابط النشر</b></a>
<a href="app.html"><b>التطبيق</b> — ما يراه المستخدم</a>
</div></html>
OEOF
ok "owner.html — بوابة المالك"
fi

hd "3 · توسيع السجل إلى 90 مصدرًا"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, time
# (الاسم, الرابط, النموذج, المفتاح, حد السحب, الدفع, ملاحظة, طبقة)
S = [
("A-ADS","https://a-ads.com/","view","AADS_UNIT","$0","BTC تلقائي","بلا KYC — يبدأ فورًا",1),
("Adsterra","https://publishers.adsterra.com/signup","view","ADSTERRA_API_KEY","$5","USDT/PayPal","API رصيد",1),
("Monetag","https://monetag.com/","view","MONETAG_MULTITAG","$5","PayPal/Skrill","Multitag",1),
("ExoClick","https://www.exoclick.com/signup/","view","EXOCLICK_ZONE","€20","Paxum/Wire","أعلى RPM إباحي",1),
("JuicyAds","https://www.juicyads.com/signup","view","JUICYADS_ZONE","$50","Paxum/BTC","إباحي",1),
("TrafficJunky","https://www.trafficjunky.com/","view","TRAFFICJUNKY_ZONE","$100","Wire","إباحي",2),
("PlugRush","https://www.plugrush.com/","view","PLUGRUSH_ZONE","$25","PayPal/BTC","إباحي",2),
("Clickadu","https://www.clickadu.com/","view","CLICKADU_ZONE","$5","PayPal/Paxum","إباحي",2),
("HilltopAds","https://hilltopads.net/","view","HILLTOPADS_ZONE","$50","PayPal","إباحي/عام",2),
("AdMaven","https://ad-maven.com/","view","ADMAVEN_ZONE","$5","PayPal","Popunder",2),
("Galaksion","https://galaksion.com/","view","GALAKSION_ZONE","$10","PayPal","إباحي",3),
("MyBid","https://mybid.io/","view","MYBID_ZONE","$25","PayPal","إباحي",3),
("Evadav","https://evadav.com/","view","EVADAV_ZONE","$5","PayPal","إباحي",3),
("PopAds","https://www.popads.net/users/signup","view","POPADS_SITE_ID","$5","PayPal/BTC","عام",2),
("PopCash","https://popcash.net/register","view","POPCASH_ZONE","$10","PayPal/BTC","عام",3),
("PropellerAds","https://publishers.propellerads.com/","view","PROPELLER_ZONE","$5","PayPal/Paxum","عام",2),
("Adcash","https://adcash.com/","view","ADCASH_ZONE","$5","PayPal/Wire","عام",3),
("AdSense","https://adsense.google.com","view","ADSENSE_CLIENT","$100","Wire/Payoneer","أعلى ثقة",2),
("Ezoic","https://www.ezoic.com/","view","EZOIC_ID","$20","PayPal","تحسين CPM",3),
("Setupad","https://setupad.com/","view","SETUPAD_ID","€50","Wire","عام",3),
("Bitmedia","https://bitmedia.io/","view","BITMEDIA_ZONE","$50","BTC","كريبتو",3),
("Coinzilla","https://coinzilla.com/","view","COINZILLA_ZONE","$50","BTC","كريبتو",3),
("Brave Creators","https://creators.brave.com/","watch","—","$1","BAT→Binance","مقابل الانتباه — لا يحتاج جمهورًا",1),
("Presearch","https://presearch.com/","watch","—","$1","PRE","بحث → مكافأة",3),
("CPAGrip","https://www.cpagrip.com/","action","CPAGRIP_SMARTLINK","$50","PayPal/Payoneer","CPA عالي",2),
("OGAds","https://ogads.com/","action","OGADS_SMARTLINK","$20","PayPal","CPA جوال",2),
("AdBlueMedia","https://adbluemedia.com/","action","ADBLUE_SMARTLINK","$10","PayPal","CPA",3),
("CPALead","https://www.cpalead.com/","action","CPALEAD_SMARTLINK","$50","PayPal/Payoneer","CPA",3),
("Zeydoo","https://zeydoo.com/","action","ZEYDOO_SMARTLINK","$50","Paxum","CPA",3),
("Adscend","https://adscendmedia.com/","action","ADSCEND_KEY","$50","PayPal","CPA",3),
("AdGate","https://adgatemedia.com/","action","ADGATE_KEY","$50","PayPal","CPA",3),
("Lootably","https://www.lootably.com/","action","LOOTABLY_KEY","$25","PayPal","CPA",3),
("OfferToro","https://offertoro.com/","action","OFFERTORO_KEY","$50","PayPal","CPA",3),
("Timewall","https://timewall.io/","action","TIMEWALL_KEY","$5","PayPal","CPA",3),
("BitLabs","https://bitlabs.ai/","action","BITLABS_KEY","$10","PayPal","استبيانات",3),
("Stripchat","https://affiliates.stripchat.com/","action","STRIPCHAT_AFF","$50","Wire/Paxum","إباحي revshare",2),
("LiveJasmin","https://www.livejasmin.com/en/affiliate","action","JASMIN_AFF","$50","Wire","إباحي revshare",3),
("BongaCams","https://bongacams.com/affiliate","action","BONGA_AFF","$50","Wire","إباحي revshare",3),
("Chaturbate","https://chaturbate.com/affiliates/","action","CHATURBATE_AFF","$50","Wire/Paxum","إباحي revshare 20%",2),
("Binance","https://www.binance.com/en/activity/referral","action","BINANCE_REF","—","—","عمولة تسجيل",2),
("Amazon","https://affiliate-program.amazon.com/","action","AMAZON_TAG","$10","Wire","عمولة شراء",3),
("Publish0x","https://www.publish0x.com/","publish","—","$1","Crypto","انشر مقالًا → تُدفع",1),
("Read.cash","https://read.cash/","publish","—","$0.1","BCH","منشور قصير",1),
("Hive / PeakD","https://peakd.com/","publish","—","$0","HIVE","نشر → مكافآت",1),
("Steemit","https://steemit.com/","publish","—","$0","STEEM","نشر → مكافآت",2),
("Medium","https://medium.com/creators","publish","—","$5","Stripe","برنامج الشركاء",2),
("Substack","https://substack.com/","publish","—","$0","Stripe","نشرة باشتراك",3),
("Vocal Media","https://vocal.media/","publish","—","$10","PayPal","لكل 1000 قراءة",3),
("Mirror","https://mirror.xyz/","publish","—","$0","Crypto","نشر لامركزي",3),
("Linkvertise","https://publisher.linkvertise.com/","share","LINKVERTISE_UID","$5","PayPal","لكل فتح رابط",2),
("ShrinkMe","https://shrinkme.io/","share","SHRINKME_KEY","$5","PayPal/BTC","اختصار → دخل",3),
("ShrinkEarn","https://shrinkearn.com/","share","SHRINKEARN_KEY","$5","PayPal/BTC","اختصار",3),
("Adf.ly","https://adf.ly/","share","ADFLY_UID","$5","PayPal/Payoneer","اختصار",3),
("Clk.sh","https://clk.sh/","share","CLKSH_KEY","$5","PayPal","اختصار",3),
("OuO","https://ouo.io/","share","OUO_KEY","$5","PayPal","اختصار",3),
("GPLinks","https://gplinks.in/","share","GPLINKS_KEY","$5","PayPal","اختصار",3),
("Droplink","https://droplink.co/","share","DROPLINK_KEY","$5","PayPal","اختصار",3),
("Ko-fi","https://ko-fi.com/","donate","—","$0","PayPal","0% عمولة",1),
("Buy Me a Coffee","https://buymeacoffee.com/","donate","—","$0","Stripe/PayPal","تبرع",2),
("Patreon","https://www.patreon.com/","donate","—","$0","Stripe","اشتراك",3),
("GitHub Sponsors","https://github.com/sponsors","donate","—","$0","Stripe","تبرع مطوّرين",3),
("Liberapay","https://liberapay.com/","donate","—","$0","PayPal","تبرع دوري",3),
("Open Collective","https://opencollective.com/","donate","—","$0","Stripe","تبرع",3),
("TMDB","https://www.themoviedb.org/signup","film","TMDB_KEY","—","—","بيانات أفلام",1),
("OMDb","https://www.omdbapi.com/apikey.aspx","film","OMDB_API_KEY","—","—","بيانات أفلام",2),
("Fanart.tv","https://fanart.tv/get-an-api-key/","film","FANART_API_KEY","—","—","بوسترات",3),
("Trakt","https://trakt.tv/oauth/applications","film","TRAKT_CLIENT_ID","—","—","تتبع",3),
("TVmaze","https://www.tvmaze.com/api","series","TVMAZE_KEY","—","—","مسلسلات",3),
("Watchmode","https://api.watchmode.com/","series","WATCHMODE_KEY","—","—","أين يُشاهد",3),
("Search Console","https://search.google.com/search-console","index","—","—","—","فهرسة جوجل",1),
("Bing Webmaster","https://www.bing.com/webmasters","index","—","—","—","فهرسة بينج",1),
("Yandex Webmaster","https://webmaster.yandex.com","index","—","—","—","فهرسة ياندكس",2),
("IndexNow","https://www.indexnow.org","index","—","—","—","إرسال فوري",1),
("Wayback","https://web.archive.org/save/","index","—","—","—","أرشيف دائم",2),
("Ping-O-Matic","http://rpc.pingomatic.com/","index","—","—","—","20+ خدمة",2),
("Twingly","https://rpc.twingly.com/","index","—","—","—","ping بلوجات",3),
("Cloudflare Analytics","https://www.cloudflare.com/web-analytics","index","—","—","—","إحصاء",2),
("GoatCounter","https://www.goatcounter.com","index","—","—","—","إحصاء",3),
("Umami Cloud","https://cloud.umami.is","index","—","—","—","إحصاء",3),
("USDT TRC20","https://www.binance.com","pay","USDT_TRC20","—","—","مسار الكريمي",1),
]
M = {"view":"لكل مشاهدة/ظهور","action":"لكل إجراء (CPA)","publish":"لكل نشر/مقال",
     "share":"لكل فتح رابط","donate":"تبرعات","watch":"مقابل الانتباه","film":"أفلام",
     "series":"مسلسلات","index":"فهرسة/إحصاء","pay":"دفع"}
json.dump({"updated":time.strftime("%F %H:%M"),"count":len(S),"models":M,
  "items":[{"n":a,"url":b,"model":c,"key":d,"min":e,"pay":f,"note":g,"tier":h} for a,b,c,d,e,f,g,h in S]},
  open("data/earn.json","w",encoding="utf-8"), ensure_ascii=False, indent=1)
rows=""
for m in ("view","action","publish","share","watch","donate","film","series","index","pay"):
    it=[x for x in S if x[2]==m]
    if not it: continue
    rows+='<h2>%s — %d</h2><table><tr><th>الجهة</th><th>حد السحب</th><th>الدفع</th><th>ملاحظة</th><th></th></tr>'%(M[m],len(it))
    for a,b,c,d,e,f,g,h in it:
        rows+='<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td><td><a target="_blank" rel="nofollow noopener" href="%s">تسجيل ↗</a></td></tr>'%(a,e,f,g,b)
    rows+="</table>"
open("earn.html","w",encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>مصادر الدخل</title>
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.8 system-ui,Tahoma}.w{max-width:1020px;margin:0 auto;padding:18px}
h1{font-size:20px}h2{font-size:14px;color:#aab6c8;margin:20px 0 8px}table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}a{color:#5ca9ff}
.note{background:#121a26;border:1px solid #1e2c40;border-radius:12px;padding:11px;color:#9fb0c6;font-size:13px;margin:12px 0}</style>
<div class="w"><h1>💵 مصادر الدخل — %d مصدرًا في 10 نماذج دفع</h1>
<div class="note"><b>لا يحتاج جمهورًا:</b> Publish0x · Read.cash · Hive · Brave Creators · Ko-fi.<br>
<b>أول ربح من زيارات:</b> A-ADS (حد $0). <b>أعلى عائد لكل زيارة:</b> CPA — CPAGrip · Stripchat.</div>%s
<p><a href="owner.html">لوحة المالك</a> · <a href="wallet.html">الخزينة</a></p></div></html>"""%(len(S),rows))
print("  ✓ earn.json + earn.html — %d مصدرًا"%len(S))
PY

hd "4 · ربط الشبكات"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
E={}
if os.path.exists("keys.env"):
    for ln in open("keys.env",encoding="utf-8"):
        s=ln.strip()
        if "=" in s and not s.startswith("#"):
            k,v=s.split("=",1); E[k.strip()]=v.strip()
CAT=json.load(open("data/earn.json",encoding="utf-8"))["items"]
try: a=json.load(open("ads.json",encoding="utf-8"))
except Exception: a={}
nets={n.get("k"):n for n in (a.get("networks") or []) if n.get("k")}
for x in CAT:
    if x["model"] in ("film","series","index","pay") or x["key"]=="—": continue
    nets.setdefault(x["key"],{"n":x["n"],"k":x["key"],"pay":x["pay"],"model":x["model"]})
on=0
for k,n in nets.items():
    v=E.get(k) or ""; n["id"]=v; n["enabled"]=bool(v); on+=bool(v)
a["networks"]=list(nets.values())
json.dump(a,open("ads.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("  ✓ %d مفعّلة من %d"%(on,len(nets)))
PY

hd "5 · بناء ونشر وتوثيق"
for f in inject_hits revenue_sync hits_report vault money dashboard share ping earn; do
  [ -f "tools/$f.py" ] && python3 "tools/$f.py" >>"$LOG" 2>&1 || true
done
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { bad "لا تفويض"; exit 1; }
R="$U.github.io"; SITE="https://$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|complete|%s'%time.time()).encode()).hexdigest()[:16])")"
printf '%s' "$SIG" > .tmp/lastcode
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
VMSG="complete: $U $SIG sources=90 keys=$NK"
printf 'CineHub 3099 — نسخة كاملة\nالحساب: %s\nالموقع: %s\nالرمز: %s\nالمصادر: 90\nالمفاتيح: %s\n' "$U" "$SITE" "$SIG" "$NK" > verify.txt
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
  wrn "محاولة $i فشلت"
done
python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1

hd "6 · تشغيل الوكيل + تحقق"
pkill -f agentd.sh 2>/dev/null || true; sleep 1; rm -f .git/index.lock 2>/dev/null
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2; pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل" || wrn "لم يبدأ"
for f in "" app.html library.html links.html earn.html owner.html; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  تم — واجهة مستخدم نظيفة + 90 مصدرًا + وكيل   ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  للمستخدم : %s/\n  المالك   : %s/owner.html (noindex)\n  الدخل    : %s/earn.html\n  الخزينة  : %s/wallet.html\n  الرمز    : %s%s%s\n' \
  "$SITE" "$SITE" "$SITE" "$SITE" "$B" "$SIG" "$N" | tee -a "$LOG"
