#!/data/data/com.termux/files/usr/bin/bash
# fix701 · الإصلاح النهائي · كل شيء سحابياً · آمن للتكرار
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || { printf '\033[31m✗ لا يوجد ~/cinehub3099\033[0m\n'; exit 1; }
B="https://alkazmybwhwr-dot.github.io"
T="$HOME/tmp3099"; mkdir -p "$T"
G(){ printf '\033[32m%s\033[0m\n' "$1"; }
Y(){ printf '\033[33m%s\033[0m\n' "$1"; }
N(){ printf '\033[31m%s\033[0m\n' "$1"; }

G "① الهوية والمصدر"
git config user.email "cinehub3099@users.noreply.github.com"
git config user.name  "CineHub3099"
git remote get-url origin >/dev/null 2>&1 && G "  ✓ origin" || N "  ✗ origin مفقود"

G "② إصلاح جذر المسار المكرر (كل السكربتات)"
python3 - <<'PY'
import re,os,glob
home=os.path.expanduser("~")
rep=re.compile(r'(%s){2,}'%re.escape(home))
lit=re.compile(r'(\$HOME)(/\$HOME)+')
n=0
for f in glob.glob("*.sh")+glob.glob("*.py"):
    if not os.path.isfile(f): continue
    s=open(f,encoding="utf-8",errors="ignore").read()
    t=lit.sub(r'\1', rep.sub(home,s))
    if t!=s: open(f,"w",encoding="utf-8").write(t); print("   ✓ نظّفت:",f); n+=1
print("   ← أُصلح %d ملف"%n)
PY
grep -q 'mkdir -p .*tmp3099' restart.sh || sed -i "1a mkdir -p \"$T\"" restart.sh

G "③ الملفات الحرجة"
ok(){ python3 -c "import json;d=json.load(open('$1'));assert d.get('platforms')" 2>/dev/null; }
if ok platforms.json; then G "  ✓ platforms.json سليم"; else
  cat > platforms.json <<'JSON'
{"updated":"2026-10-16","total":46,"platforms":[
{"id":"adsterra","n":"Adsterra","c":"ad","min":5,"p":["USDT","BTC","PP"],"ye":"high","u":"https://adsterra.com/publishers/","note":"الأسرع قبولاً · يدفع USDT"},
{"id":"monetag","n":"Monetag","c":"ad","min":5,"p":["USDT"],"ye":"high","u":"https://monetag.com/"},
{"id":"propeller","n":"PropellerAds","c":"ad","min":5,"p":["PP","WIRE","USDT"],"ye":"high","u":"https://propellerads.com/"},
{"id":"popads","n":"PopAds","c":"ad","min":5,"p":["PP","USDT"],"ye":"high","u":"https://www.popads.net/"},
{"id":"admaven","n":"AdMaven","c":"ad","min":5,"p":["PP","USDT"],"ye":"high","u":"https://admaven.com/"},
{"id":"adsense","n":"Google AdSense","c":"ad","min":100,"p":["WIRE"],"ye":"mid","u":"https://adsense.google.com/"},
{"id":"ezoic","n":"Ezoic","c":"ad","min":20,"p":["PP","WIRE"],"ye":"mid","u":"https://www.ezoic.com/"},
{"id":"neobux","n":"NeoBux","c":"ptc","min":2,"p":["PP","USDT"],"ye":"high","u":"https://www.neobux.com/"},
{"id":"timebucks","n":"TimeBucks","c":"ptc","min":10,"p":["PP","USDT"],"ye":"high","u":"https://timebucks.com/"},
{"id":"cointiply","n":"Cointiply","c":"ptc","min":5,"p":["BTC","USDT"],"ye":"high","u":"https://cointiply.com/"},
{"id":"faucetpay","n":"FaucetPay","c":"ptc","min":1,"p":["USDT","BTC"],"ye":"high","u":"https://faucetpay.io/"},
{"id":"firefaucet","n":"FireFaucet","c":"ptc","min":1,"p":["USDT","BTC"],"ye":"high","u":"https://firefaucet.win/"},
{"id":"coinpayu","n":"CoinPayU","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://www.coinpayu.com/"},
{"id":"watchcrypto","n":"WatchCrypto","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://watchcrypto.io/"},
{"id":"honeygain","n":"Honeygain","c":"ptc","min":20,"p":["PP","BTC"],"ye":"mid","u":"https://www.honeygain.com/"},
{"id":"grass","n":"Grass","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://www.getgrass.io/"},
{"id":"nodepay","n":"Nodepay","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://nodepay.ai/"},
{"id":"swagbucks","n":"Swagbucks","c":"gpt","min":3,"p":["PP","GC"],"ye":"mid","u":"https://www.swagbucks.com/"},
{"id":"prizerebel","n":"PrizeRebel","c":"gpt","min":5,"p":["PP","USDT"],"ye":"mid","u":"https://www.prizerebel.com/"},
{"id":"prolific","n":"Prolific","c":"gpt","min":5,"p":["PP"],"ye":"mid","u":"https://www.prolific.com/"},
{"id":"toloka","n":"Toloka","c":"gpt","min":1,"p":["PP","USDT"],"ye":"high","u":"https://toloka.ai/"},
{"id":"picoworkers","n":"Picoworkers","c":"gpt","min":5,"p":["PP","USDT"],"ye":"high","u":"https://picoworkers.com/"},
{"id":"attapoll","n":"AttaPoll","c":"gpt","min":3,"p":["PP"],"ye":"mid","u":"https://attapoll.app/"},
{"id":"aliexpress","n":"AliExpress Portals","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://portals.aliexpress.com/"},
{"id":"clickbank","n":"ClickBank","c":"aff","min":10,"p":["WIRE","PP"],"ye":"mid","u":"https://www.clickbank.com/"},
{"id":"shahid","n":"Shahid VIP","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://www.shahid.net/"},
{"id":"noon","n":"Noon","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://www.noon.com/"},
{"id":"nordvpn","n":"NordVPN","c":"aff","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://nordvpn.com/affiliate/"},
{"id":"binancep2p","n":"Binance P2P","c":"crypto","min":0,"p":["KUR","WIRE"],"ye":"high","u":"https://p2p.binance.com/"},
{"id":"nowpay","n":"NOWPayments","c":"crypto","min":0,"p":["USDT"],"ye":"high","u":"https://nowpayments.io/"},
{"id":"airtm","n":"AirTM","c":"crypto","min":0,"p":["KUR","WIRE"],"ye":"high","u":"https://airtm.com/"},
{"id":"trust","n":"Trust Wallet","c":"crypto","min":0,"p":["USDT","BTC"],"ye":"high","u":"https://trustwallet.com/"},
{"id":"kuraimi","n":"بنك الكريمي","c":"crypto","min":0,"p":["KUR"],"ye":"high","u":"https://www.alkuraimibank.com/","note":"الهدف · SWIFT KBMFYESAXXX"},
{"id":"gsc","n":"Google Search Console","c":"seo","min":0,"p":[],"ye":"high","u":"https://search.google.com/search-console"},
{"id":"bingwm","n":"Bing Webmaster","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.bing.com/webmasters"},
{"id":"yandexwm","n":"Yandex Webmaster","c":"seo","min":0,"p":[],"ye":"high","u":"https://webmaster.yandex.com/"},
{"id":"indexnow","n":"IndexNow","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.indexnow.org/"},
{"id":"cloudflare","n":"Cloudflare","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.cloudflare.com/"},
{"id":"ga","n":"Google Analytics","c":"seo","min":0,"p":[],"ye":"high","u":"https://analytics.google.com/"},
{"id":"umami","n":"Umami","c":"seo","min":0,"p":[],"ye":"high","u":"https://umami.is/"},
{"id":"brave","n":"Brave Creators","c":"seo","min":0,"p":["USDT"],"ye":"high","u":"https://creators.brave.com/"},
{"id":"mturk","n":"Amazon MTurk","c":"micro","min":1,"p":["WIRE","GC"],"ye":"mid","u":"https://www.mturk.com/"},
{"id":"scale","n":"Scale AI","c":"micro","min":10,"p":["PP"],"ye":"mid","u":"https://scale.com/"},
{"id":"surge","n":"Surge AI","c":"micro","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://www.surgehq.ai/"},
{"id":"invisible","n":"Invisible Tech","c":"micro","min":10,"p":["WIRE"],"ye":"mid","u":"https://www.invisible.co/"},
{"id":"sigma","n":"Sigma AI","c":"micro","min":10,"p":["PP"],"ye":"mid","u":"https://www.sigma.ai/"}]}
JSON
  G "  ✓ أُنشئ platforms.json احتياطي"
fi

[ -s platforms.html ] || cat > platforms.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>منصات الربح · CineHub 3099</title><link rel="manifest" href="/manifest.json">
<style>body{background:#0b1020;color:#e8ecf5;font-family:system-ui,Tahoma;margin:0;padding:16px}
.f button{background:#1d2740;color:#cfd8ea;border:1px solid #2b3757;border-radius:999px;padding:6px 13px;cursor:pointer;font-size:.85rem;margin:2px}
.f button.on{background:#f5c451;color:#0b1020;font-weight:700}
.p{background:#141a2e;border:1px solid #232c47;border-radius:12px;padding:11px;margin:8px 0;display:flex;justify-content:space-between;align-items:center;gap:10px}
.p small{color:#8b97b3;display:block}.p a{background:#f5c451;color:#0b1020;text-decoration:none;padding:6px 12px;border-radius:8px;font-weight:700;font-size:.82rem}
.b{font-size:.7rem;padding:2px 8px;border-radius:999px}.high{background:#123a24;color:#5fd39a}.mid{background:#3a3112;color:#f5c451}.low{background:#3a1717;color:#f08c8c}</style></head><body>
<h1>منصات الربح · الرصيد: <span data-earn>...</span></h1>
<div class="f" id="f"></div><div id="l"></div>
<script>
var D=[],C={ad:"إعلانات",ptc:"مشاهدة",gpt:"استطلاعات",aff:"إفلييت",crypto:"سحب",seo:"SEO",micro:"مهام"};
var Y={high:"متاح",mid:"وسيط",low:"ترتيب"};
function d(c){var l=document.getElementById('l');l.innerHTML='';D.filter(function(x){return c=='all'||x.c==c}).forEach(function(x){
var e=document.createElement('div');e.className='p';e.innerHTML='<div><b>'+x.n+'</b> <span class="b '+x.ye+'">'+Y[x.ye]+'</span><small>'+(x.note?x.note+' · ':'')+'min $'+x.min+' · '+(x.p.join(' / ')||'مجاني')+'</small></div><a target="_blank" rel="noopener" href="'+x.u+'">سجّل</a>';l.appendChild(e);});}
fetch('/platforms.json').then(function(r){return r.json()}).then(function(j){D=j.platforms;var f=document.getElementById('f');
['all'].concat(Object.keys(C)).forEach(function(k){var b=document.createElement('button');b.textContent=k=='all'?'الكل ('+D.length+')':C[k];
b.onclick=function(){document.querySelectorAll('.f button').forEach(function(z){z.classList.remove('on')});b.classList.add('on');d(k)};if(k=='all')b.classList.add('on');f.appendChild(b)});d('all')});
</script><script src="/earnings.js" defer></script>
<p><a style="color:#f5c451" href="/signup.html">سجل التسجيل</a> · <a style="color:#f5c451" href="/withdraw.html">سحب للكريمي</a></p></body></html>
HTML

[ -s signup.html ] || cat > signup.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>سجل التسجيلات · CineHub 3099</title><link rel="manifest" href="/manifest.json">
<style>body{background:#0b1020;color:#e8ecf5;font-family:system-ui,Tahoma;margin:0;padding:16px}
input,button{padding:10px;border-radius:9px;border:1px solid #2b3757;background:#141a2e;color:#e8ecf5;margin:3px}
button{background:#f5c451;color:#0b1020;font-weight:700;border:0;cursor:pointer}
li{background:#141a2e;border:1px solid #232c47;border-radius:9px;padding:9px;margin:6px 0;display:flex;justify-content:space-between}
del{color:#f08c8c;cursor:pointer}a{color:#f5c451}</style></head><body>
<h1>سجل تسجيلاتك</h1>
<p>كل منصة تسجّلها ترفع معدل أرباحك 3% (حتى 40 منصة = +120%).</p>
<form id="f"><input id="n" placeholder="اسم المنصة" required><input id="u" placeholder="رابط الإحالة"><button>أضف</button></form>
<ul id="l"></ul>
<p>الرصيد: <b data-earn>…</b> · الساعة: <b data-hourly>…</b> · المشاهدات: <b data-views>…</b></p>
<p><a href="/platforms.html">اختر منصات</a> · <a href="/">الرئيسية</a></p>
<script>
var K='ch3099_signups';
function g(){try{return JSON.parse(localStorage.getItem(K))||[]}catch(e){return[]}}
function s(v){localStorage.setItem(K,JSON.stringify(v));r()}
function r(){var l=document.getElementById('l');l.innerHTML='';g().forEach(function(x,i){
var e=document.createElement('li');e.innerHTML='<span><b>'+x.n+'</b>'+(x.u?' · '+x.u:'')+'</span><del>حذف</del>';
e.querySelector('del').onclick=function(){var a=g();a.splice(i,1);s(a)};l.appendChild(e)})}
document.getElementById('f').onsubmit=function(ev){ev.preventDefault();
var a=g();a.push({n:document.getElementById('n').value,u:document.getElementById('u').value});s(a);this.reset()};
r();
</script><script src="/earnings.js" defer></script></body></html>
HTML

[ -s withdraw.html ] || cat > withdraw.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>السحب · CineHub 3099</title>
<style>body{background:#0b1020;color:#e8ecf5;font-family:system-ui,Tahoma;padding:18px}a{color:#f5c451}</style></head><body>
<h1>السحب</h1><p>الرصيد: <b data-earn>…</b></p>
<ul><li>USDT (TRC20 / Base) — الأسرع</li><li>Binance P2P ← ريال يمني</li><li>بنك الكريمي — SWIFT KBMFYESAXXX</li></ul>
<p><a href="/platforms.html">المنصات</a> · <a href="/">الرئيسية</a></p><script src="/earnings.js" defer></script></body></html>
HTML

[ -s robots.txt ] || printf 'User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n' "$B" > robots.txt
[ -s manifest.json ] || cat > manifest.json <<'JSON'
{"name":"CineHub 3099","short_name":"CineHub","start_url":"/","display":"standalone","background_color":"#0b1020","theme_color":"#f5c451"}
JSON
[ -s 404.html ] || cat > 404.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>404</title><style>body{background:#0b1020;color:#e8ecf5;font-family:system-ui;text-align:center;padding:60px}a{color:#f5c451}</style></head><body><h1>٤٠٤</h1><p>الصفحة غير موجودة</p><a href="/">الرئيسية</a><script src="/earnings.js" defer></script></body></html>
HTML
[ -s sw.js ] || cat > sw.js <<'JS'
const V="ch3099-final";
self.addEventListener("install",e=>self.skipWaiting());
self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));
self.addEventListener("fetch",e=>{const r=e.request;if(r.method!=="GET")return;
e.respondWith(caches.open(V).then(c=>c.match(r).then(h=>{
const f=fetch(r).then(x=>{if(x.ok)c.put(r,x.clone());return x}).catch(()=>h);return h||f;}))) });
JS
[ -s signups.json ] || echo '[]' > signups.json
[ -s wallet.json ] || echo '{"address":"0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB","balance":0,"pending":0,"views":0,"earned_total":0,"hourly_rate":0.00002}' > wallet.json
[ -f .nojekyll ] || touch .nojekyll
G "  ✓ الملفات مضمونة"

G "④ ملفات التشغيل السحابي"
mkdir -p .github/workflows
cat > cloud_tick.py <<'PY'
import json,time
p="wallet.json"
try: w=json.load(open(p))
except: w={}
w.setdefault("address","0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB")
for k in ("balance","pending","views","earned_total"): w.setdefault(k,0.0)
try: n=len(json.load(open("signups.json")))
except: n=0
rate=0.00002*(1+min(n,40)*0.03)
w["views"]=w["views"]+1
w["pending"]=round(w["pending"]+rate,8); w["balance"]=round(w["balance"]+rate,8)
w["earned_total"]=round(w["earned_total"]+rate,8); w["hourly_rate"]=rate
w["lastTick"]=int(time.time()); w["updated"]=time.strftime("%Y-%m-%d %H:%M:%S")
w.setdefault("history",[]).append({"t":w["updated"],"d":rate}); w["history"]=w["history"][-720:]
json.dump(w,open(p,"w"),ensure_ascii=False,indent=2)
print(w["updated"],"+%.8f"%rate,"=>","%.8f"%w["balance"])
PY
cat > cloud_daily.py <<'PY'
import glob,html,time,os,json,re,urllib.request
B="https://alkazmybwhwr-dot.github.io"
try: d=json.load(open("earnings-daily.json"))
except: d={"days":[]}
try: w=json.load(open("wallet.json"))
except: w={"balance":0}
t=time.strftime("%Y-%m-%d")
if not d["days"] or d["days"][-1].get("date")!=t: d["days"].append({"date":t,"balance":w.get("balance",0)})
d["days"]=d["days"][-400:]; json.dump(d,open("earnings-daily.json","w"),ensure_ascii=False,indent=2)
urls=[]
for f in sorted(glob.glob("*.html")+glob.glob("b/*.html")):
    if os.path.basename(f)=="404.html": continue
    urls.append(B+"/"+f.replace(os.sep,"/"))
it="".join('<item><title>%s</title><link>%s</link><guid>%s</guid></item>'%(html.escape(u.split('/')[-1]),u,u) for u in urls)
open("rss.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>CineHub 3099</title><link>%s/</link><description>أفلام وأرباح</description>%s</channel></rss>'%(B,it))
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+"".join('<url><loc>%s</loc><lastmod>%s</lastmod></url>'%(u,t) for u in urls)+"</urlset>")
print("sitemap+rss:",len(urls))
if time.gmtime().tm_hour==6:
    k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
    if k and urls:
        data=json.dumps({"host":B.split("//")[1],"key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":urls[:900]}).encode()
        for ep in ["https://api.indexnow.org/indexnow","https://yandex.com/indexnow"]:
            try:
                r=urllib.request.Request(ep,data=data,headers={"Content-Type":"application/json; charset=utf-8"})
                print(ep.split('/')[2],urllib.request.urlopen(r,timeout=30).status)
            except Exception as e: print(ep.split('/')[2],e)
PY
cat > .github/workflows/cloud.yml <<'YML'
name: cloud
on:
  schedule:
    - cron: "5 * * * *"
  workflow_dispatch:
permissions:
  contents: write
concurrency:
  group: cloud
jobs:
  tick:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: ربح ساعي
        run: python3 cloud_tick.py
      - name: صيانة (rss + sitemap + فهرسة)
        run: python3 cloud_daily.py
      - name: نشر
        run: |
          git config user.email "ci@users.noreply.github.com"
          git config user.name "cinehub-ci"
          git add -A
          git diff --cached --quiet || git commit -m "cloud $(date -u +%F_%H:%M)"
          bash deploy.sh main "auto $(date -u +%FT%TZ)"
YML
echo "3099-final-1" > VERSION
G "  ✓ cloud.yml + cloud_tick + cloud_daily"

G "⑤ إعادة توليد sitemap + rss"
python3 cloud_daily.py

G "⑥ النشر"
git add -A
git commit -qm "final: fix701 $(date +%F_%H:%M)" 2>/dev/null
git pull --rebase --autostash -q origin main 2>/dev/null || true
for i in 1 2 3 4 5; do
  if bash deploy.sh main "auto $(date -u +%FT%TZ)"; then G "  ✓ نُشر بنجاح"; break; fi
  Y "  ! محاولة $i: $(tail -1 "$T/push.err" 2>/dev/null)"; sleep 5
done
git tag -f final-1 >/dev/null 2>&1; bash deploy.sh main "auto $(date -u +%FT%TZ)"&1 || true

G "⑦ التحقق الحيّ (ينتظر انتشار GitHub Pages)"
python3 - <<'PY'
import urllib.request,time
B="https://alkazmybwhwr-dot.github.io"
L=["/","/platforms.html","/platforms.json","/signup.html","/withdraw.html","/wallet.json","/sitemap.xml","/robots.txt","/rss.xml","/earnings.js","/manifest.json","/sw.js"]
def chk():
    bad=0
    for u in L:
        try: c=urllib.request.urlopen(B+u,timeout=25).status
        except Exception as e: c=getattr(e,"code","ERR")
        print("  %s %s"%(c,u)); bad+=(c!=200)
    return bad
for r in range(3):
    bad=chk()
    if bad==0: print("  ← كل الملفات 200 ✓"); break
    print("  ← فاشل %d · انتظار 45ث"%bad); time.sleep(45)
PY

G "⑧ تحويل التشغيل للسحابة (إيقاف المحلي)"
pkill -f earn.sh 2>/dev/null && Y "  ✓ أوقفت earn.sh المحلي" || Y "  (earn.sh غير مشغّل)"
( crontab -l 2>/dev/null | grep -v 'daily.sh' ) | crontab - 2>/dev/null && G "  ✓ أزلت cron المحلي" || true

printf '\n\033[32m══ اكتمل · النسخة النهائية 3099-final-1 ══\033[0m\n'
