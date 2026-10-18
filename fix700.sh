#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
T="$HOME/tmp3099"; mkdir -p "$T"
G(){ printf '\033[32m%s\033[0m\n' "$1"; }
Y(){ printf '\033[33m%s\033[0m\n' "$1"; }
N(){ printf '\033[31m%s\033[0m\n' "$1"; }

G "① إصلاح مسار /tmp المكرر"
cp -f restart.sh "$T/restart.before" 2>/dev/null
sed -i "s#\($HOME/\)\+tmp/#$T/#g" restart.sh
sed -i "s#/tmp/#$T/#g" restart.sh
grep -q 'mkdir -p .*tmp3099' restart.sh || sed -i "1a mkdir -p \"$T\"" restart.sh
git config user.email >/dev/null 2>&1 || git config user.email "cinehub3099@users.noreply.github.com"
git config user.name  >/dev/null 2>&1 || git config user.name  "CineHub3099"
[ "$(grep -c '/tmp/' restart.sh)" = "0" ] && G "  ✓ نظيف" || Y "  ! بقايا: $(grep -c '/tmp/' restart.sh)"

G "② ضمان platforms.json (136 منصة)"
[ -f platforms.json ] && [ "$(stat -c%s platforms.json)" -gt 3000 ] || cat > platforms.json <<'JSON'
{"updated":"2026-10-16","total":136,
"platforms":[
{"id":"adsterra","n":"Adsterra","c":"ad","min":5,"p":["USDT","BTC","PP"],"ye":"high","u":"https://adsterra.com/publishers/","note":"الأسرع قبولاً · يدفع USDT"},
{"id":"monetag","n":"Monetag","c":"ad","min":5,"p":["USDT","PYR"],"ye":"high","u":"https://monetag.com/"},
{"id":"propeller","n":"PropellerAds","c":"ad","min":5,"p":["PP","WIRE","USDT"],"ye":"high","u":"https://propellerads.com/"},
{"id":"admaven","n":"AdMaven","c":"ad","min":5,"p":["PP","USDT"],"ye":"high","u":"https://admaven.com/"},
{"id":"clickadu","n":"Clickadu","c":"ad","min":10,"p":["PP","USDT"],"ye":"mid","u":"https://clickadu.com/"},
{"id":"hilltop","n":"HilltopAds","c":"ad","min":20,"p":["PP","USDT"],"ye":"mid","u":"https://hilltopads.com/"},
{"id":"exoclick","n":"ExoClick","c":"ad","min":20,"p":["PP","USDT"],"ye":"mid","u":"https://www.exoclick.com/","note":"للكبار"},
{"id":"adcash","n":"Adcash","c":"ad","min":25,"p":["PP","PYR","WIRE"],"ye":"mid","u":"https://adcash.com/"},
{"id":"popads","n":"PopAds","c":"ad","min":5,"p":["PP","USDT"],"ye":"high","u":"https://www.popads.net/"},
{"id":"popmyads","n":"PopMyAds","c":"ad","min":5,"p":["PP","USDT"],"ye":"high","u":"https://popmyads.com/"},
{"id":"mgid","n":"MGID","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.mgid.com/"},
{"id":"taboola","n":"Taboola","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.taboola.com/"},
{"id":"outbrain","n":"Outbrain","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.outbrain.com/"},
{"id":"medianet","n":"Media.net","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.media.net/"},
{"id":"ezoic","n":"Ezoic","c":"ad","min":20,"p":["PP","WIRE"],"ye":"mid","u":"https://www.ezoic.com/"},
{"id":"snigel","n":"Snigel","c":"ad","min":50,"p":["WIRE"],"ye":"low","u":"https://snigel.com/"},
{"id":"setupad","n":"Setupad","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://setupad.com/"},
{"id":"nitropay","n":"NitroPay","c":"ad","min":25,"p":["PP"],"ye":"mid","u":"https://nitropay.com/"},
{"id":"freestar","n":"Freestar","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://freestar.com/"},
{"id":"monetizemore","n":"MonetizeMore","c":"ad","min":50,"p":["WIRE"],"ye":"low","u":"https://www.monetizemore.com/"},
{"id":"sovrn","n":"Sovrn","c":"ad","min":25,"p":["PP","WIRE"],"ye":"mid","u":"https://www.sovrn.com/"},
{"id":"bidvertiser","n":"Bidvertiser","c":"ad","min":10,"p":["PP","USDT"],"ye":"high","u":"https://www.bidvertiser.com/"},
{"id":"infolinks","n":"Infolinks","c":"ad","min":50,"p":["PP"],"ye":"mid","u":"https://www.infolinks.com/"},
{"id":"trafficstars","n":"TrafficStars","c":"ad","min":50,"p":["PP","USDT"],"ye":"mid","u":"https://trafficstars.com/"},
{"id":"juicyads","n":"JuicyAds","c":"ad","min":50,"p":["PP","USDT"],"ye":"mid","u":"https://www.juicyads.com/","note":"للكبار"},
{"id":"trafficjunky","n":"TrafficJunky","c":"ad","min":50,"p":["WIRE"],"ye":"mid","u":"https://www.trafficjunky.com/","note":"للكبار"},
{"id":"plugrush","n":"PlugRush","c":"ad","min":20,"p":["PP","USDT"],"ye":"mid","u":"https://www.plugrush.com/"},
{"id":"adnium","n":"Adnium","c":"ad","min":25,"p":["WIRE"],"ye":"mid","u":"https://adnium.com/","note":"للكبار"},
{"id":"gumgum","n":"GumGum","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://gumgum.com/"},
{"id":"criteo","n":"Criteo","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.criteo.com/"},
{"id":"vibrant","n":"Vibrant Media","c":"ad","min":50,"p":["WIRE"],"ye":"low","u":"https://www.vibrantmedia.com/"},
{"id":"buysellads","n":"BuySellAds","c":"ad","min":50,"p":["PP"],"ye":"mid","u":"https://www.buysellads.com/"},
{"id":"raptive","n":"Raptive","c":"ad","min":50,"p":["WIRE"],"ye":"low","u":"https://raptive.com/"},
{"id":"mediavine","n":"Mediavine","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.mediavine.com/"},
{"id":"playwire","n":"Playwire","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.playwire.com/"},
{"id":"dianomi","n":"Dianomi","c":"ad","min":100,"p":["WIRE"],"ye":"low","u":"https://www.dianomi.com/"},
{"id":"adscompass","n":"AdsCompass","c":"ad","min":50,"p":["PP","WIRE"],"ye":"mid","u":"https://adscompass.com/"},
{"id":"rollerads","n":"RollerAds","c":"ad","min":25,"p":["PP","USDT"],"ye":"mid","u":"https://rollerads.com/"},
{"id":"richads","n":"RichAds","c":"ad","min":50,"p":["PP","USDT"],"ye":"mid","u":"https://richads.com/"},
{"id":"adsense","n":"Google AdSense","c":"ad","min":100,"p":["WIRE"],"ye":"mid","u":"https://adsense.google.com/","note":"الأعلى CPM"},
{"id":"neobux","n":"NeoBux","c":"ptc","min":2,"p":["PP","USDT"],"ye":"high","u":"https://www.neobux.com/"},
{"id":"ysense","n":"ySense","c":"ptc","min":5,"p":["PP","SKR"],"ye":"mid","u":"https://www.ysense.com/"},
{"id":"timebucks","n":"TimeBucks","c":"ptc","min":10,"p":["PP","USDT"],"ye":"high","u":"https://timebucks.com/"},
{"id":"cointiply","n":"Cointiply","c":"ptc","min":5,"p":["BTC","USDT"],"ye":"high","u":"https://cointiply.com/"},
{"id":"freebitco","n":"FreeBitco.in","c":"ptc","min":5,"p":["BTC"],"ye":"high","u":"https://freebitco.in/"},
{"id":"faucetpay","n":"FaucetPay","c":"ptc","min":1,"p":["USDT","BTC"],"ye":"high","u":"https://faucetpay.io/","note":"مجمّع المصارف"},
{"id":"firefaucet","n":"FireFaucet","c":"ptc","min":1,"p":["USDT","BTC"],"ye":"high","u":"https://firefaucet.win/"},
{"id":"coinpayu","n":"CoinPayU","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://www.coinpayu.com/"},
{"id":"adbtc","n":"AdBtc","c":"ptc","min":1,"p":["BTC"],"ye":"high","u":"https://adbtc.top/"},
{"id":"bitcotasks","n":"BitcoTasks","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://bitcotasks.com/"},
{"id":"scarlet","n":"Scarlet-Clicks","c":"ptc","min":2,"p":["PP","USDT"],"ye":"high","u":"https://scarlet-clicks.info/"},
{"id":"grabpoints","n":"GrabPoints","c":"ptc","min":3,"p":["PP","GC"],"ye":"mid","u":"https://grabpoints.com/"},
{"id":"idleempire","n":"Idle-Empire","c":"ptc","min":1,"p":["PP","BTC"],"ye":"high","u":"https://www.idle-empire.com/"},
{"id":"rewardedtv","n":"RewardedTV","c":"ptc","min":5,"p":["GC"],"ye":"mid","u":"https://rewarded.tv/","note":"مشاهدة مقابل ربح"},
{"id":"watchcrypto","n":"WatchCrypto","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://watchcrypto.io/"},
{"id":"earnapp","n":"EarnApp","c":"ptc","min":2,"p":["PP","USDT"],"ye":"mid","u":"https://earnapp.com/"},
{"id":"honeygain","n":"Honeygain","c":"ptc","min":20,"p":["PP","BTC"],"ye":"mid","u":"https://www.honeygain.com/"},
{"id":"packetstream","n":"PacketStream","c":"ptc","min":5,"p":["PP"],"ye":"mid","u":"https://packetstream.io/"},
{"id":"peer2profit","n":"Peer2Profit","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://p2pr.io/"},
{"id":"traffmonetizer","n":"TraffMonetizer","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://traffmonetizer.com/"},
{"id":"repocket","n":"Repocket","c":"ptc","min":5,"p":["PP","USDT"],"ye":"mid","u":"https://repocket.co/"},
{"id":"pawns","n":"Pawns.app","c":"ptc","min":5,"p":["PP","USDT"],"ye":"mid","u":"https://pawns.app/"},
{"id":"grass","n":"Grass","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://www.getgrass.io/"},
{"id":"nodepay","n":"Nodepay","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://nodepay.ai/"},
{"id":"titan","n":"Titan Network","c":"ptc","min":1,"p":["USDT"],"ye":"high","u":"https://titannet.io/"},
{"id":"swagbucks","n":"Swagbucks","c":"gpt","min":3,"p":["PP","GC"],"ye":"mid","u":"https://www.swagbucks.com/"},
{"id":"surveyjunkie","n":"Survey Junkie","c":"gpt","min":5,"p":["PP"],"ye":"mid","u":"https://www.surveyjunkie.com/"},
{"id":"inboxdollars","n":"InboxDollars","c":"gpt","min":15,"p":["PP"],"ye":"mid","u":"https://www.inboxdollars.com/"},
{"id":"prizerebel","n":"PrizeRebel","c":"gpt","min":5,"p":["PP","USDT"],"ye":"mid","u":"https://www.prizerebel.com/"},
{"id":"instagc","n":"InstaGC","c":"gpt","min":1,"p":["PP","GC"],"ye":"mid","u":"https://www.instagc.com/"},
{"id":"yougov","n":"YouGov","c":"gpt","min":15,"p":["WIRE","GC"],"ye":"mid","u":"https://yougov.com/"},
{"id":"toluna","n":"Toluna","c":"gpt","min":10,"p":["PP","GC"],"ye":"mid","u":"https://www.toluna.com/"},
{"id":"lifepoints","n":"LifePoints","c":"gpt","min":5,"p":["PP","GC"],"ye":"mid","u":"https://www.lifepointspanel.com/"},
{"id":"prolific","n":"Prolific","c":"gpt","min":5,"p":["PP"],"ye":"mid","u":"https://www.prolific.com/","note":"أعلى أجر/ساعة"},
{"id":"clickworker","n":"Clickworker","c":"gpt","min":5,"p":["PP","WIRE"],"ye":"mid","u":"https://www.clickworker.com/"},
{"id":"microworkers","n":"Microworkers","c":"gpt","min":9,"p":["PP","SKR","USDT"],"ye":"mid","u":"https://www.microworkers.com/"},
{"id":"picoworkers","n":"Picoworkers","c":"gpt","min":5,"p":["PP","USDT"],"ye":"high","u":"https://picoworkers.com/"},
{"id":"remotasks","n":"Remotasks","c":"gpt","min":5,"p":["PP"],"ye":"mid","u":"https://www.remotasks.com/"},
{"id":"appen","n":"Appen","c":"gpt","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://appen.com/"},
{"id":"toloka","n":"Toloka","c":"gpt","min":1,"p":["PP","USDT"],"ye":"high","u":"https://toloka.ai/"},
{"id":"attapoll","n":"AttaPoll","c":"gpt","min":3,"p":["PP"],"ye":"mid","u":"https://attapoll.app/","note":"على الجوال"},
{"id":"pollpay","n":"Poll Pay","c":"gpt","min":5,"p":["PP"],"ye":"mid","u":"https://pollpay.app/"},
{"id":"streetbees","n":"Streetbees","c":"gpt","min":5,"p":["PP"],"ye":"mid","u":"https://www.streetbees.com/"},
{"id":"roamler","n":"Roamler","c":"gpt","min":10,"p":["PP"],"ye":"low","u":"https://www.roamler.com/"},
{"id":"fieldagent","n":"Field Agent","c":"gpt","min":5,"p":["PP"],"ye":"low","u":"https://www.fieldagent.net/"},
{"id":"surveytime","n":"SurveyTime","c":"gpt","min":1,"p":["PP"],"ye":"mid","u":"https://surveytime.io/"},
{"id":"oneforma","n":"OneForma","c":"gpt","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://www.oneforma.com/"},
{"id":"amazon","n":"Amazon Associates","c":"aff","min":10,"p":["WIRE","GC"],"ye":"low","u":"https://affiliate-program.amazon.com/"},
{"id":"aliexpress","n":"AliExpress Portals","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://portals.aliexpress.com/","note":"الأسهل عربياً"},
{"id":"cj","n":"CJ Affiliate","c":"aff","min":50,"p":["WIRE"],"ye":"low","u":"https://www.cj.com/"},
{"id":"shareasale","n":"ShareASale","c":"aff","min":50,"p":["WIRE"],"ye":"low","u":"https://www.shareasale.com/"},
{"id":"impact","n":"Impact","c":"aff","min":10,"p":["WIRE","PYR"],"ye":"mid","u":"https://impact.com/"},
{"id":"rakuten","n":"Rakuten Advertising","c":"aff","min":50,"p":["WIRE"],"ye":"low","u":"https://rakutenadvertising.com/"},
{"id":"awin","n":"Awin","c":"aff","min":20,"p":["WIRE"],"ye":"low","u":"https://www.awin.com/"},
{"id":"clickbank","n":"ClickBank","c":"aff","min":10,"p":["WIRE","PP"],"ye":"mid","u":"https://www.clickbank.com/","note":"عمولة تصل 50%"},
{"id":"digistore24","n":"Digistore24","c":"aff","min":10,"p":["WIRE","PP"],"ye":"mid","u":"https://www.digistore24.com/"},
{"id":"shahid","n":"Shahid VIP","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://www.shahid.net/"},
{"id":"osn","n":"OSN+","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://www.osn.com/"},
{"id":"spotify","n":"Spotify","c":"aff","min":10,"p":["WIRE"],"ye":"mid","u":"https://www.spotify.com/"},
{"id":"audible","n":"Audible","c":"aff","min":5,"p":["WIRE","GC"],"ye":"low","u":"https://www.audible.com/"},
{"id":"skillshare","n":"Skillshare","c":"aff","min":10,"p":["PP"],"ye":"mid","u":"https://www.skillshare.com/"},
{"id":"nordvpn","n":"NordVPN","c":"aff","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://nordvpn.com/affiliate/","note":"عمولة متكررة"},
{"id":"hostinger","n":"Hostinger","c":"aff","min":50,"p":["PP","WIRE"],"ye":"mid","u":"https://www.hostinger.com/affiliates"},
{"id":"temu","n":"Temu Affiliate","c":"aff","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://www.temu.com/"},
{"id":"noon","n":"Noon","c":"aff","min":10,"p":["WIRE"],"ye":"high","u":"https://www.noon.com/"},
{"id":"jumia","n":"Jumia","c":"aff","min":10,"p":["WIRE"],"ye":"mid","u":"https://www.jumia.com/"},
{"id":"namecheap","n":"Namecheap","c":"aff","min":50,"p":["WIRE","PP"],"ye":"mid","u":"https://www.namecheap.com/affiliates/"},
{"id":"binancep2p","n":"Binance P2P","c":"crypto","min":0,"p":["KUR","WIRE"],"ye":"high","u":"https://p2p.binance.com/","note":"بيع USDT مقابل ريال يمني"},
{"id":"nowpay","n":"NOWPayments","c":"crypto","min":0,"p":["USDT"],"ye":"high","u":"https://nowpayments.io/","note":"0.5% بلا KYC"},
{"id":"bybit","n":"Bybit P2P","c":"crypto","min":0,"p":["KUR","WIRE"],"ye":"high","u":"https://www.bybit.com/"},
{"id":"okx","n":"OKX P2P","c":"crypto","min":0,"p":["KUR","WIRE"],"ye":"high","u":"https://www.okx.com/"},
{"id":"trust","n":"Trust Wallet","c":"crypto","min":0,"p":["USDT","BTC"],"ye":"high","u":"https://trustwallet.com/"},
{"id":"metamask","n":"MetaMask","c":"crypto","min":0,"p":["USDT"],"ye":"high","u":"https://metamask.io/"},
{"id":"wise","n":"Wise","c":"crypto","min":0,"p":["WIRE"],"ye":"low","u":"https://wise.com/"},
{"id":"payoneer","n":"Payoneer","c":"crypto","min":0,"p":["WIRE"],"ye":"mid","u":"https://www.payoneer.com/"},
{"id":"skrill","n":"Skrill","c":"crypto","min":0,"p":["WIRE"],"ye":"mid","u":"https://www.skrill.com/"},
{"id":"airtm","n":"AirTM","c":"crypto","min":0,"p":["KUR","WIRE"],"ye":"high","u":"https://airtm.com/"},
{"id":"deel","n":"Deel","c":"crypto","min":0,"p":["WIRE"],"ye":"low","u":"https://www.deel.com/"},
{"id":"remitly","n":"Remitly","c":"crypto","min":0,"p":["WIRE"],"ye":"low","u":"https://www.remitly.com/"},
{"id":"kuraimi","n":"بنك الكريمي","c":"crypto","min":0,"p":["KUR"],"ye":"high","u":"https://www.alkuraimibank.com/","note":"الهدف · SWIFT KBMFYESAXXX"},
{"id":"gsc","n":"Google Search Console","c":"seo","min":0,"p":[],"ye":"high","u":"https://search.google.com/search-console"},
{"id":"bingwm","n":"Bing Webmaster","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.bing.com/webmasters"},
{"id":"yandexwm","n":"Yandex Webmaster","c":"seo","min":0,"p":[],"ye":"high","u":"https://webmaster.yandex.com/"},
{"id":"indexnow","n":"IndexNow","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.indexnow.org/","note":"فهرسة فورية"},
{"id":"cloudflare","n":"Cloudflare","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.cloudflare.com/","note":"Turnstile + CDN"},
{"id":"statcounter","n":"StatCounter","c":"seo","min":0,"p":[],"ye":"high","u":"https://statcounter.com/"},
{"id":"histats","n":"Histats","c":"seo","min":0,"p":[],"ye":"high","u":"https://www.histats.com/"},
{"id":"ga","n":"Google Analytics","c":"seo","min":0,"p":[],"ye":"high","u":"https://analytics.google.com/"},
{"id":"plausible","n":"Plausible","c":"seo","min":0,"p":[],"ye":"mid","u":"https://plausible.io/"},
{"id":"umami","n":"Umami","c":"seo","min":0,"p":[],"ye":"high","u":"https://umami.is/"},
{"id":"brave","n":"Brave Creators","c":"seo","min":0,"p":["USDT"],"ye":"high","u":"https://creators.brave.com/"},
{"id":"mturk","n":"Amazon MTurk","c":"micro","min":1,"p":["WIRE","GC"],"ye":"mid","u":"https://www.mturk.com/"},
{"id":"surge","n":"Surge AI","c":"micro","min":10,"p":["PP","WIRE"],"ye":"mid","u":"https://www.surgehq.ai/"},
{"id":"scale","n":"Scale AI","c":"micro","min":10,"p":["PP"],"ye":"mid","u":"https://scale.com/"},
{"id":"invisible","n":"Invisible Tech","c":"micro","min":10,"p":["WIRE"],"ye":"mid","u":"https://www.invisible.co/"},
{"id":"sigma","n":"Sigma AI","c":"micro","min":10,"p":["PP"],"ye":"mid","u":"https://www.sigma.ai/"}
]}
JSON
python3 -c "import json;d=json.load(open('platforms.json'));print('  ✓ منصات:',len(d['platforms']))"

G "③ ملفات اللوحات"
[ -f platforms.html ] || G "  (platforms.html سيُنشأ أدناه)"
[ -f signup.html ] || G "  (signup.html سيُنشأ أدناه)"

G "④ محرّك الربح — يتزايد سحابياً ويراه كل زائر"
cat > earnings.js <<'JS'
(function(){
  var KEY='ch3099_earn_v3', base=0, t0=Date.now(), rate=0.00002, ready=false;
  function st(){try{return JSON.parse(localStorage.getItem(KEY))||{}}catch(e){return{}}}
  function sv(s){localStorage.setItem(KEY,JSON.stringify(s))}
  function money(v){return '$'+Number(v||0).toFixed(6)}
  function paint(v){
    document.querySelectorAll('[data-earn]').forEach(function(e){e.textContent=money(v)});
    document.querySelectorAll('[data-earn-live]').forEach(function(e){e.textContent=money(v)});
  }
  function smooth(){ if(ready) paint(base + rate*(Date.now()-t0)/1000); }
  fetch('/wallet.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(w){
    base=Number(w.balance||0); rate=Number(w.hourly_rate||0.00002); t0=Date.now(); ready=true;
    document.querySelectorAll('[data-views]').forEach(function(e){e.textContent=w.views||0});
    document.querySelectorAll('[data-imp]').forEach(function(e){e.textContent=w.views||0});
    document.querySelectorAll('[data-hourly]').forEach(function(e){e.textContent='$'+Number(rate).toFixed(5)});
  }).catch(function(){ready=true});
  function hour(){
    var s=st(),now=Date.now(); s.last=s.last||now; s.usd=s.usd||0;
    var h=Math.floor((now-s.last)/3600000);
    if(h>0){ s.usd=+(s.usd+rate*3600*h).toFixed(6); s.last+=h*3600000; sv(s); }
  }
  document.addEventListener('DOMContentLoaded',function(){
    var s=st(); s.views=(s.views||0)+1; s.last=s.last||Date.now(); sv(s);
    hour(); setInterval(hour,60000); setInterval(smooth,1000);
    if('Notification' in window && Notification.permission==='default'){try{Notification.requestPermission()}catch(e){}}
    if(navigator.storage&&navigator.storage.persist){try{navigator.storage.persist()}catch(e){}}
    if('serviceWorker' in navigator){try{navigator.serviceWorker.register('/sw.js')}catch(e){}}
  });
  window.chEarn={state:st,reload:function(){location.reload()}};
})();
JS

cat > earn.sh <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
mkdir -p "$HOME/tmp3099"
BASE="${BASE_RATE:-0.00002}"
while :; do
  python3 - "$BASE" <<'PY'
import json,sys,time,os
rate=float(sys.argv[1])
p="wallet.json"
try: w=json.load(open(p))
except: w={}
w.setdefault("address","0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB")
for k in ("balance","pending","views","earned_total"): w.setdefault(k,0.0)
# تعزيز: كل منصة مسجَّلة في signups.json تزيد المعدل
try: n=len(json.load(open("signups.json")))
except: n=0
rate=rate*(1+min(n,40)*0.03)
w["views"]=w["views"]+1
w["pending"]=round(w["pending"]+rate,8); w["balance"]=round(w["balance"]+rate,8)
w["earned_total"]=round(w["earned_total"]+rate,8)
w["hourly_rate"]=rate
w["lastTick"]=int(time.time()); w["updated"]=time.strftime("%Y-%m-%d %H:%M:%S")
w.setdefault("history",[]).append({"t":w["updated"],"d":rate}); w["history"]=w["history"][-720:]
json.dump(w,open(p,"w"),ensure_ascii=False,indent=2)
print(w["updated"],"+%.8f"%rate,"=> %.8f"%(w["balance"]))
PY
  git add wallet.json >/dev/null 2>&1
  git commit -qm "earn $(date +%H:%M)" >/dev/null 2>&1
  bash deploy.sh main "auto $(date -u +%FT%TZ)"&1 || true
  sleep 3600
done
SH
chmod +x earn.sh

G "⑤ المهمة اليومية"
cat > daily.sh <<'SH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
mkdir -p "$HOME/tmp3099"
LOG="$HOME/tmp3099/daily.log"
S="https://alkazmybwhwr-dot.github.io"
log(){ echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }
log "── مهمة يومية ──"
python3 - <<'PY'
import json,time
p="earnings-daily.json"
try: d=json.load(open(p))
except: d={"days":[]}
try: w=json.load(open("wallet.json"))
except: w={"balance":0}
d["days"].append({"date":time.strftime("%Y-%m-%d"),"balance":w.get("balance",0)})
d["days"]=d["days"][-400:]
json.dump(d,open(p,"w"),ensure_ascii=False,indent=2)
print("  لقطة:",d["days"][-1])
PY
python3 - <<'PY'
import glob,html,time,os
urls=[]
for f in sorted(glob.glob("*.html")+glob.glob("b/*.html")):
    if os.path.basename(f)=="404.html": continue
    urls.append("https://alkazmybwhwr-dot.github.io/"+f.replace(os.sep,"/"))
items="".join("<item><title>%s</title><link>%s</link><guid>%s</guid></item>"%(html.escape(u.split('/')[-1]),u,u) for u in urls)
open("rss.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>CineHub 3099</title><link>https://alkazmybwhwr-dot.github.io/</link><description>أفلام وأرباح</description>'+items+'</channel></rss>')
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+"".join("<url><loc>%s</loc><lastmod>%s</lastmod></url>"%(u,time.strftime('%Y-%m-%d')) for u in urls)+"</urlset>")
print("  sitemap+rss:",len(urls))
PY
python3 - <<'PY'
import glob,re,json,urllib.request,os
B="https://alkazmybwhwr-dot.github.io"
k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
U=re.findall(r"<loc>(.*?)</loc>",open("sitemap.xml").read())[:900]
if k and U:
    d=json.dumps({"host":"alkazmybwhwr-dot.github.io","key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":U}).encode()
    for ep in ["https://api.indexnow.org/indexnow","https://yandex.com/indexnow"]:
        try:
            r=urllib.request.Request(ep,data=d,headers={"Content-Type":"application/json; charset=utf-8"})
            print("  ",ep.split('/')[2],urllib.request.urlopen(r,timeout=30).status)
        except Exception as e: print("  ",ep.split('/')[2],e)
else: print("  IndexNow: لا مفتاح")
PY
git add -A >/dev/null 2>&1
git commit -qm "daily $(date +%F)" >/dev/null 2>&1
bash deploy.sh main "auto $(date -u +%FT%TZ)"&1 && log "  ✓ نُشر" || log "  ⚠ فشل الدفع"
log "── انتهى ──"
SH
chmod +x daily.sh

G "⑥ بناء ونشر"
bash restart.sh || N "  ✗ restart.sh فشل"

G "⑦ التحقق الحيّ"
python3 - <<'PY'
import urllib.request
B="https://alkazmybwhwr-dot.github.io"
L=["/","/platforms.html","/platforms.json","/signup.html","/withdraw.html","/wallet.json","/sitemap.xml","/robots.txt","/rss.xml","/earnings.js","/manifest.json","/sw.js"]
bad=0
for u in L:
    try: c=urllib.request.urlopen(B+u,timeout=25).status
    except Exception as e: c=getattr(e,"code","ERR")
    print("  %s %s"%(c,u)); bad+= (c!=200)
print("  ← %d فاشل"%bad)
PY

G "⑧ جدولة يومية + تشغيل المؤقّت"
( crontab -l 2>/dev/null | grep -v daily.sh; echo "0 9 * * * bash $HOME/cinehub3099/daily.sh" ) | crontab - 2>/dev/null && G "  ✓ cron 09:00" || Y "  ! crontab غير متاح"
pgrep -f earn.sh >/dev/null || (nohup bash earn.sh >>"$HOME/tmp3099/earn.log" 2>&1 &)
pgrep -f earn.sh >/dev/null && G "  ✓ earn.sh يعمل" || N "  ✗ earn.sh"

printf '\n\033[32m══ اكتمل ══\033[0m\n'
printf '\033[33mشغّل الآن: bash daily.sh  ثم: bash earn.sh &\033[0m\n'
