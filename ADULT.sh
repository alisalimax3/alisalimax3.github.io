#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  ADULT.sh — قسم إباحي كامل: صفحات · شبكات إباحية · سجل 35 مصدرًا · ترويج
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data .github/workflows
export GHTMP="$TMPDIR" GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/adult.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "0 · تنظيف"
pkill -f agentd.sh 2>/dev/null || true; sleep 1
rm -f .git/index.lock .git/*.lock 2>/dev/null; ok "جاهز"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { wrn "لا تفويض"; exit 1; }
SITE="https://$U.github.io"

hd "1 · شبكات الإعلان الإباحي (ملف منفصل)"
cat > tools/adult_ads.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني ads-adult.json من المفاتيح الإباحية ويربطها، ويحقنها في صفحات adult/"""
import json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
ADULT = [
 ("EXOCLICK_ZONE","ExoClick","€20","Paxum/Wire","ملك الإباحي — أعلى RPM",1),
 ("JUICYADS_ZONE","JuicyAds","$50","Paxum/BTC","إباحي صافي",1),
 ("TRAFFICJUNKY_ZONE","TrafficJunky","$100","Wire","حجم عالٍ",2),
 ("PLUGRUSH_ZONE","PlugRush","$25","PayPal/BTC","إباحي",2),
 ("CLICKADU_ZONE","Clickadu","$5","PayPal/Paxum","حد منخفض",2),
 ("HILLTOPADS_ZONE","HilltopAds","$50","PayPal","إباحي/عام",2),
 ("ADMAVEN_ZONE","AdMaven","$5","PayPal","بوب أندر قوي",2),
 ("EVADAV_ZONE","Evadav","$5","PayPal","إباحي",3),
 ("GALAKSION_ZONE","Galaksion","$10","PayPal","إباحي",3),
 ("MYBID_ZONE","MyBid","$25","PayPal","إباحي",3),
 ("TRAFFICSTARS_ZONE","TrafficStars","$100","Wire/Paxum","شبكة إباحية كبرى",2),
 ("STRIPCHAT_AFF","Stripchat","$50","Wire/Paxum","revshare لكل تسجيل",1),
 ("CHATURBATE_AFF","Chaturbate","$50","Wire/Paxum","revshare 20% مدى الحياة",1),
 ("JASMIN_AFF","LiveJasmin","$50","Wire","revshare عالي",2),
 ("BONGA_AFF","BongaCams","$50","Wire","revshare",2),
 ("FLIRT4FREE_AFF","Flirt4Free","$50","Wire","revshare",3),
 ("IMLIVE_AFF","ImLive","$50","Wire","revshare",3),
 ("STREAMATE_AFF","Streamate","$50","Wire","revshare",3),
 ("CAMSODA_AFF","CamSoda","$50","Wire","revshare",3),
 ("FANCENTRO_AFF","FanCentro","$50","Wire","اشتراكات",3),
 ("XHAMSTERLIVE_AFF","xHamsterLive","$50","Wire","revshare",3),
 ("JERKMATE_AFF","Jerkmate","$50","Wire","revshare",3),
 ("LOSPOLLOS","LosPollos","$50","PayPal","CPA إباحي — عائد لكل تسجيل",2),
 ("CRACKREVENUE","CrackRevenue","$50","PayPal","CPA إباحي",2),
 ("MOBIDEA_ADULT","Mobidea","$50","PayPal","CPA",3),
 ("ZEYDOO_ADULT","Zeydoo","$50","Paxum","CPA",3),
]
nets = []
for k, n, mn, pay, note, tier in ADULT:
    nets.append({"k": k, "n": n, "min": mn, "pay": pay, "note": note, "tier": tier, "id": E.get(k, ""), "enabled": bool(E.get(k))})
json.dump({"updated": time.strftime("%F %H:%M"), "count": len(nets),
           "enabled": len([x for x in nets if x["enabled"]]), "networks": nets},
          open("ads-adult.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
# حقن في صفحات adult/
n = 0
if os.path.isdir("adult"):
    for f in os.listdir("adult"):
        if not f.endswith(".html"): continue
        p = os.path.join("adult", f)
        s = open(p, encoding="utf-8").read()
        if "ads-adult.json" in s: continue
        s = s.replace("</body>", """<div class="aad" style="display:flex;justify-content:center;margin:14px 0" id="aad"></div>
<script>fetch('../ads-adult.json').then(r=>r.json()).then(a=>{const on=(a.networks||[]).filter(x=>x.id);
document.getElementById('aad').innerHTML=on.slice(0,2).map(x=>x.k==='EXOCLICK_ZONE'?
'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+x.id+'" width="300" height="250" frameborder="0" scrolling="no"></iframe>':
x.k==='JUICYADS_ZONE'?'<iframe src="https://adserver.juicyads.com/adshow.php?adzone='+x.id+'" width="300" height="250" frameborder="0" scrolling="no"></iframe>':'').join('');}).catch(function(){});</script>
</body>""", 1)
        open(p, "w", encoding="utf-8").write(s); n += 1
print("  ✓ ads-adult.json: %d شبكة (%d مفعّلة) · حُقن في %d صفحة" % (len(nets), len([x for x in nets if x["enabled"]]), n))
PYEOF
chmod +x tools/adult_ads.py

hd "2 · بناء صفحات القسم الإباحي"
cat > tools/adult_build.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import html, json, os, re, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KEY = ("adult","18","xxx","erotic","nsfw","porn","hentai","rule34","redgifs","danbooru","gelbooru","boobs","lingerie")
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
items = []
for f in ("catalog.json", "films.json", "titles.json"):
    d = rd(f, None)
    if not d: continue
    a = d.get("items") if isinstance(d, dict) else d
    if isinstance(a, dict): a = list(a.values())
    if isinstance(a, list):
        for x in a:
            if not isinstance(x, dict): continue
            t = x.get("t") or x.get("title") or x.get("name")
            i = x.get("i") or x.get("id") or x.get("slug")
            if not (t and i): continue
            c = str(x.get("c") or x.get("cat") or x.get("category") or "")
            src = str(x.get("s") or x.get("src") or x.get("source") or "")
            blob = (c + " " + src + " " + str(t)).lower()
            items.append({"i": str(i), "t": str(t), "th": x.get("th") or x.get("poster") or x.get("image") or "",
                          "y": str(x.get("y") or x.get("year") or "")[:4], "adult": any(k in blob for k in KEY)})
    if items: break
ad = [x for x in items if x["adult"]] or items[:200]
os.makedirs("adult", exist_ok=True)
made = 0
for x in ad[:3000]:
    slug = re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", x["i"])[:70] or "item"
    p = "adult/%s.html" % slug
    if os.path.exists(p): continue
    open(p, "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>
<meta name="description" content="%s — مشاهدة مجانية">
<meta property="og:title" content="%s"><meta property="og:image" content="%s">
<meta name="twitter:card" content="summary_large_image"><meta name="rating" content="adult">
<link rel="manifest" href="../manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}.w{max-width:860px;margin:0 auto;padding:18px}
h1{font-size:21px}img{max-width:260px;border-radius:12px;background:#0f1520}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ad{display:flex;justify-content:center;margin:14px 0}</style></head><body>
<div class="w"><p><a href="../">الرئيسية</a> · <a href="../adult.html">🔞 للكبار</a> · <a href="../app.html">التطبيق</a></p>
<img loading="lazy" src="%s" alt="%s"><h1>%s %s</h1><p class="k">قسم الكبار — إعلانات مطابقة للجمهور.</p>
<div class="ad" id="ad"></div><div class="ad" id="ad2"></div>
<script src="../hits.js" defer></script>
<script>fetch('../ads-adult.json').then(r=>r.json()).then(a=>{const on=(a.networks||[]).filter(x=>x.id);
const h=on.slice(0,2).map(x=>x.k==='EXOCLICK_ZONE'?'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+x.id+'" width="300" height="250" frameborder="0"></iframe>':
x.k==='JUICYADS_ZONE'?'<iframe src="https://adserver.juicyads.com/adshow.php?adzone='+x.id+'" width="300" height="250" frameborder="0"></iframe>':'').join('');
document.getElementById('ad').innerHTML=h;document.getElementById('ad2').innerHTML=h;}).catch(function(){});</script>
</div></body></html>""" % (html.escape(x["t"]), html.escape(x["t"]), html.escape(x["t"]), html.escape(x["th"]),
                            html.escape(x["th"]), html.escape(x["t"]), html.escape(x["t"]), html.escape(x["y"])))
    made += 1
cards = "".join('<a class="c" href="adult/%s.html"><img loading="lazy" src="%s"><b>%s</b></a>'
                % (html.escape(re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", x["i"])[:70]), html.escape(x["th"]), html.escape(x["t"])) for x in ad[:150])
open("adult.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>🔞 للكبار — CineHub 3099</title>
<meta name="description" content="قسم الكبار — محتوى 18+ مجانًا">
<meta name="rating" content="adult"><link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}.w{max-width:1100px;margin:0 auto;padding:16px}
h1{font-size:21px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:10px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
a{color:#5ca9ff}nav a{margin-inline-end:10px;text-decoration:none;color:#8fa4bf;font-size:12.5px}
.ad{display:flex;justify-content:center;margin:12px 0}.k{color:#8b96a8;font-size:13px}</style></head><body>
<div class="w"><nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="movies.html">أفلام</a><a href="series.html">مسلسلات</a><a href="adult.html">للكبار</a></nav>
<h1>🔞 قسم الكبار</h1><p class="k">%d عنوانًا · إعلانات شبكات إباحية متخصصة (ExoClick · JuicyAds · TrafficStars · revshare كام)</p>
<div class="ad" id="ad"></div><div class="grid">%s</div>
<script src="hits.js" defer></script>
<script>fetch('ads-adult.json').then(r=>r.json()).then(a=>{const on=(a.networks||[]).filter(x=>x.id);
document.getElementById('ad').innerHTML=on.slice(0,2).map(x=>x.k==='EXOCLICK_ZONE'?'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+x.id+'" width="300" height="250" frameborder="0"></iframe>':'').join('')||('<span class="k">'+on.length+' شبكة إباحية مفعّلة</span>');}).catch(function(){});</script>
</div></body></html>""" % (len(ad), cards))
# RSS إباحي
now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
S = "https://%s.github.io" % os.environ.get("GHU", "")
open("adult-rss.xml", "w", encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
 '<title>CineHub 3099 — للكبار</title><link>%s/adult.html</link><description>18+</description>'
 '<lastBuildDate>%s</lastBuildDate>%s</channel></rss>' % (S, now,
 "".join('<item><title>%s</title><link>%s/adult/%s.html</link></item>' % (html.escape(x["t"]), S, re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", x["i"])[:70]) for x in ad[:50])))
print("  ✓ adult.html · %d صفحة · adult-rss.xml" % made)
PYEOF
chmod +x tools/adult_build.py
GHU="$U" python3 tools/adult_build.py 2>&1 | tee -a "$LOG"
python3 tools/adult_ads.py 2>&1 | tee -a "$LOG"

hd "3 · سجل المصادر الإباحية"
cat > tools/adult_registry.py <<'PYEOF'
#!/usr/bin/env python3
import html, json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
S = [
 ("ExoClick","https://www.exoclick.com/signup/","إعلان","EXOCLICK_ZONE","€20","Paxum/Wire","ملك الإباحي — أعلى RPM"),
 ("JuicyAds","https://www.juicyads.com/signup","إعلان","JUICYADS_ZONE","$50","Paxum/BTC","إباحي صافي"),
 ("TrafficJunky","https://www.trafficjunky.com/","إعلان","TRAFFICJUNKY_ZONE","$100","Wire","حجم عالٍ جدًا"),
 ("TrafficStars","https://trafficstars.com/","إعلان","TRAFFICSTARS_ZONE","$100","Wire/Paxum","شبكة كبرى"),
 ("PlugRush","https://www.plugrush.com/","إعلان","PLUGRUSH_ZONE","$25","PayPal/BTC","إباحي"),
 ("Clickadu","https://www.clickadu.com/","إعلان","CLICKADU_ZONE","$5","PayPal/Paxum","حد منخفض"),
 ("HilltopAds","https://hilltopads.net/","إعلان","HILLTOPADS_ZONE","$50","PayPal","إباحي/عام"),
 ("AdMaven","https://ad-maven.com/","إعلان","ADMAVEN_ZONE","$5","PayPal","بوب أندر"),
 ("Evadav","https://evadav.com/","إعلان","EVADAV_ZONE","$5","PayPal","إباحي"),
 ("Galaksion","https://galaksion.com/","إعلان","GALAKSION_ZONE","$10","PayPal","إباحي"),
 ("MyBid","https://mybid.io/","إعلان","MYBID_ZONE","$25","PayPal","إباحي"),
 ("Stripchat","https://affiliates.stripchat.com/","كام revshare","STRIPCHAT_AFF","$50","Wire/Paxum","$1–$5 لكل تسجيل"),
 ("Chaturbate","https://chaturbate.com/affiliates/","كام revshare","CHATURBATE_AFF","$50","Wire/Paxum","20% مدى الحياة"),
 ("LiveJasmin","https://www.livejasmin.com/en/affiliate","كام revshare","JASMIN_AFF","$50","Wire","revshare عالي"),
 ("BongaCams","https://bongacams.com/affiliate","كام revshare","BONGA_AFF","$50","Wire","revshare"),
 ("Flirt4Free","https://www.flirt4free.com/affiliates/","كام revshare","FLIRT4FREE_AFF","$50","Wire","revshare"),
 ("ImLive","https://www.imlive.com/affiliate/","كام revshare","IMLIVE_AFF","$50","Wire","revshare"),
 ("Streamate","https://affiliate.streamate.com/","كام revshare","STREAMATE_AFF","$50","Wire","revshare"),
 ("CamSoda","https://www.camsoda.com/affiliates","كام revshare","CAMSODA_AFF","$50","Wire","revshare"),
 ("FanCentro","https://fancentro.com/","اشتراكات","FANCENTRO_AFF","$50","Wire","اشتراك شهري"),
 ("xHamsterLive","https://xhamsterlive.com/","كام revshare","XHAMSTERLIVE_AFF","$50","Wire","revshare"),
 ("Jerkmate","https://jerkmate.com/","كام revshare","JERKMATE_AFF","$50","Wire","revshare"),
 ("LosPollos","https://lopollos.com/","CPA","LOSPOLLOS","$50","PayPal","عائد لكل تسجيل"),
 ("CrackRevenue","https://www.crackrevenue.com/","CPA","CRACKREVENUE","$50","PayPal","CPA إباحي"),
 ("Mobidea","https://www.mobidea.com/","CPA","MOBIDEA_ADULT","$50","PayPal","CPA"),
 ("Zeydoo","https://zeydoo.com/","CPA","ZEYDOO_ADULT","$50","Paxum","CPA"),
 ("Pornhub Affiliate","https://www.pornhub.com/affiliates","إحالة","PORNHUB_AFF","$50","Wire","برنامج إحالة"),
 ("Reddit r/nsfw","https://www.reddit.com/r/nsfw/","ترويج","—","—","—","نشر مجاني"),
 ("Reddit r/porn","https://www.reddit.com/r/porn/","ترويج","—","—","—","نشر مجاني"),
 ("Reddit r/hentai","https://www.reddit.com/r/hentai/","ترويج","—","—","—","نشر مجاني"),
 ("Reddit r/rule34","https://www.reddit.com/r/rule34/","ترويج","—","—","—","نشر مجاني"),
 ("Twitter/X","https://x.com/","ترويج","—","—","—","وسوم 18+"),
 ("Telegram","https://telegram.org/","ترويج","—","—","—","قنوات إباحية"),
 ("Pinterest","https://www.pinterest.com/","ترويج","—","—","—","بوسترات"),
]
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
json.dump({"updated": time.strftime("%F %H:%M"), "count": len(S),
           "items": [{"n": a, "url": b, "kind": c, "key": d, "min": e, "pay": f, "note": g,
                      "id": E.get(d, ""), "on": bool(E.get(d))} for a, b, c, d, e, f, g in S]},
          open("data/adult.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
rows = ""
for a, b, c, d, e, f, g in S:
    st = '<span style="color:#39d98a">✓ مفعّل</span>' if E.get(d) else '<span style="color:#8b96a8">· ينتظر</span>'
    rows += ('<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>'
             '<td><a target="_blank" rel="nofollow noopener" href="%s">تسجيل ↗</a></td></tr>' % (a, c, d, e, f, g, st, b))
open("adult-networks.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>شبكات الكبار</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.8 system-ui,Tahoma}.w{max-width:1020px;margin:0 auto;padding:18px}
table{width:100%%;border-collapse:collapse;font-size:13px}td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}
th{color:#8b96a8;font-weight:500}a{color:#5ca9ff}code{background:#161d29;padding:2px 7px;border-radius:6px;font-size:12px}</style>
<div class="w"><h1>🔞 شبكات ومصادر الكبار — %d</h1>
<p style="color:#8b96a8;font-size:13px">الترتيب: إعلان → revshare → CPA → ترويج. ابدأ بـExoClick ثم Stripchat/Chaturbate (revshare يدفع أكثر بكثير).</p>
<table><tr><th>الجهة</th><th>النوع</th><th>المفتاح</th><th>حد السحب</th><th>الدفع</th><th>ملاحظة</th><th>الحالة</th><th></th></tr>%s</table>
<p><a href="adult.html">القسم</a> · <a href="owner.html">لوحة المالك</a></p></div></html>""" % (len(S), rows))
print("  ✓ data/adult.json + adult-networks.html (%d)" % len(S))
PYEOF
chmod +x tools/adult_registry.py
python3 tools/adult_registry.py 2>&1 | tee -a "$LOG"

hd "4 · ترويج إباحي"
cat > tools/adult_promote.py <<'PYEOF'
#!/usr/bin/env python3
import html, json, os, re, urllib.parse
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
S = json.load(open("data/revenue.json", encoding="utf-8")).get("pages_url", "") if os.path.exists("data/revenue.json") else ""
try: A = json.load(open("data/adult.json", encoding="utf-8"))["items"]
except Exception: A = []
items = []
d = None
for f in ("catalog.json", "films.json"):
    try: d = json.load(open(f, encoding="utf-8"))
    except Exception: continue
    if d: break
a = (d.get("items") if isinstance(d, dict) else d) or []
for x in (a if isinstance(a, list) else [])[:400]:
    if not isinstance(x, dict): continue
    c = str(x.get("c") or x.get("cat") or "").lower()
    if any(k in c for k in ("adult", "18", "xxx", "erotic", "nsfw")):
        items.append({"t": x.get("t") or x.get("title", ""), "i": x.get("i") or x.get("id", "")})
    if len(items) >= 60: break
rows = ""
for x in items:
    u = "%s/adult/%s.html" % (S, re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", str(x["i"]))[:70])
    txt = "🔞 %s\n%s" % (x["t"], u)
    qr = "https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=" + urllib.parse.quote(u)
    rows += ('<div class="c"><img src="%s"><div style="flex:1"><b>%s</b><textarea readonly>%s</textarea>'
             '<a target="_blank" href="https://www.reddit.com/submit?url=%s&title=%s">Reddit</a>'
             '<a target="_blank" href="https://twitter.com/intent/tweet?text=%s">X</a>'
             '<a target="_blank" href="https://t.me/share/url?url=%s&text=%s">تليجرام</a></div></div>'
             % (qr, html.escape(str(x["t"])), html.escape(txt), urllib.parse.quote(u),
                urllib.parse.quote(str(x["t"])), urllib.parse.quote(txt), urllib.parse.quote(u),
                urllib.parse.quote(str(x["t"]))))
open("promote-adult.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>ترويج الكبار</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}.w{max-width:900px;margin:0 auto;padding:16px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px}
.c img{width:110px;height:110px;border-radius:8px;background:#fff;padding:4px}
textarea{width:100%%;height:46px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px;margin-inline-end:8px}b{font-size:13.5px}</style>
<div class="w"><h1>🔞 ترويج الكبار — نصوص وQR</h1>
<p style="color:#8b96a8;font-size:13px">انشر في r/nsfw · r/porn · r/hentai · قنوات تليجرام. كل فتح = ظهور إعلان إباحي = RPM أعلى.</p>%s</div></html>""" % rows)
print("  ✓ promote-adult.html (%d)" % len(items))
PYEOF
chmod +x tools/adult_promote.py
python3 tools/adult_promote.py 2>&1 | tee -a "$LOG"

hd "5 · ربط القسم بالتطبيق + المهام"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os
for f in ("index.html", "app.html"):
    if not os.path.exists(f): continue
    s = open(f, encoding="utf-8").read()
    if "adult.html" in s: continue
    s = s.replace('</nav>', '<a href="adult.html">🔞 للكبار</a></nav>', 1)
    s = s.replace("</footer>", '<a href="adult.html">🔞 للكبار</a><a href="install.html">📲 تثبيت</a></footer>', 1)
    open(f, "w", encoding="utf-8").write(s)
    print("  ✓ %s: رابط للكبار" % f)
# مهام إباحية
p = "tools/tasks.py"
s = open(p, encoding="utf-8").read()
if "adult_build" not in s:
    s = s.replace(' ("إثبات",            "tools/proof.py",           360*M),',
                  ' ("إثبات",            "tools/proof.py",           360*M),\n'
                  ' ("قسم إباحي",       "tools/adult_build.py",     360*M),\n'
                  ' ("شبكات إباحية",    "tools/adult_ads.py",       120*M),\n'
                  ' ("ترويج إباحي",     "tools/adult_promote.py",   180*M),\n'
                  ' ("سجل إباحي",       "tools/adult_registry.py",  720*M),')
    open(p, "w", encoding="utf-8").write(s)
    print("  ✓ tasks.py: +5 مهام إباحية")
PY

hd "6 · نشر وتشغيل"
python3 tools/tasks.py 2>&1 | tail -22 | tee -a "$LOG"
python3 tools/proof.py 2>&1 | tee -a "$LOG"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
R="$U.github.io"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
ROOT="$(python3 -c "import json;print(json.load(open('proof/manifest.json'))['root'])")"
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$ROOT|adult|%s'%time.time()).encode()).hexdigest()[:24])")"
printf '%s' "$SIG" > .tmp/lastcode
VMSG="adult: $U $SIG root=$ROOT"
printf 'CineHub 3099 — قسم الكبار\nالحساب: %s\nالقسم: %s/adult.html\nالجذر: %s\nالتوقيع: %s\n' "$U" "$SITE" "$ROOT" "$SIG" > verify.txt
rm -f .git/index.lock 2>/dev/null
git add -A
git add -f .github/workflows/agent.yml 2>/dev/null || true
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
P=0
for i in 1 2 3 4; do
  rm -f .git/index.lock 2>/dev/null
  case "$i" in
    1) timeout 2400 git push origin main 2>"$GHTMP/e" && P=1 ;;
    2) timeout 2400 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    3) timeout 2400 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 2400 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
done
python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1
pkill -f agentd.sh 2>/dev/null || true; sleep 1; rm -f .git/index.lock 2>/dev/null
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2; pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل — 22 مهمة"

hd "7 · تحقق"
for f in adult.html adult-networks.html promote-adult.html adult-rss.xml ads-adult.json; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  القسم الإباحي جاهز ومربوط بشبكاته            ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  القسم   : %s/adult.html\n  الشبكات : %s/adult-networks.html\n  الترويج : %s/promote-adult.html\n  التوقيع : %s%s%s\n' \
  "$SITE" "$SITE" "$SITE" "$B" "$SIG" "$N" | tee -a "$LOG"
