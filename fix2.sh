#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
D="$(pwd)"
G(){ printf '\033[32m✓ %s\033[0m\n' "$1"; }; B(){ printf '\033[31m✗ %s\033[0m\n' "$1"; }
H(){ printf '\n\033[36m▶ %s\033[0m\n' "$1"; }

H "0/6 فك القفل الميت + مستودع مستقل"
rm -f ~/.git/index.lock
GD="$(git rev-parse --show-toplevel 2>/dev/null || echo NONE)"
echo "  المستودع الحالي: $GD"
if [ "$GD" != "$D" ]; then
  echo "  ! خاطئ — إنشاء مستودع مستقل في $D"
  rm -rf "$D/.git"
  git init -q "$D"
  git symbolic-ref HEAD refs/heads/main
fi
[ "$(git rev-parse --show-toplevel)" = "$D" ] && G "المستودع صحيح: $D" || { B "فشل"; exit 1; }

H "1/6 publish.sh مُحصَّن"
cat > publish.sh <<'PUB'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
D="$(pwd)"
O="alkazmybwhwr-dot"; R="alisalimax3.github.io"; B="main"
rm -f "$D/.git/index.lock" ~/.git/index.lock 2>/dev/null
if [ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$D" ]; then
  rm -rf "$D/.git"; git init -q "$D"; git symbolic-ref HEAD refs/heads/$B
fi
[ -f .gh-token ] || { echo "✗ نفّذ: python3 auth.py"; exit 1; }
T="$(tr -d '\n\r ' < .gh-token)"
printf 'node_modules/\nbackups/\n*.log\n.gh-token\n__pycache__/\n*.tgz\n' > .gitignore
git config user.email "cinehub@local"; git config user.name "CineHub"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${O}/${R}.git"
git add -A
if git ls-files | grep -q '^cinehub3099/'; then echo "  ! المسارات مسبوقة — خطأ"; exit 1; fi
git rm --cached -q --ignore-unmatch .gh-token 2>/dev/null
if git diff --cached --quiet; then echo "  لا تغييرات"; else git commit -q -m "publish $(date -u +%FT%TZ)"; fi
n=0; until bash deploy.sh main "auto $(date -u +%FT%TZ)"; do n=$((n+1)); [ $n -ge 5 ] && { echo "✗ فشل"; exit 1; }; sleep $((n*3)); done
echo "✓ نُشر → https://${O}.github.io"
PUB
chmod +x publish.sh; bash -n publish.sh && G "publish.sh"

H "2/6 wallet.sh برسالة واضحة"
cat > wallet.sh <<'WSH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
W="${1:-}"
if [ -z "$W" ]; then
  echo "استخدم: bash wallet.sh 0xعنوانك"
  echo "  ↑ اكتب العنوان الفعلي (42 خانة تبدأ 0x) — لا تكتب كلمة عربية"
  echo "  لإنشاء محفظة: ثبّت MetaMask أو Trust Wallet وانسخ عنوان Base"
  exit 1
fi
if ! printf '%s' "$W" | grep -Eq '^0x[0-9a-fA-F]{40}$'; then
  echo "✗ '$W' ليس عنوانًا"
  echo "  المطلوب بالضبط: 0x ثم 40 خانة hex (أرقام 0-9 وحروف a-f)"
  echo "  مثال صحيح: 0x1234567890abcdef1234567890abcdef12345678"
  exit 1
fi
python3 wallet.py "$W"
WSH
chmod +x wallet.sh; bash -n wallet.sh && G "wallet.sh"

H "3/6 index.html — واجهة تعمل بذاتها"
cat > index.html <<'HTML'
<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>CineHub 3099 — لوحة الأرباح الحقيقية</title>
<meta name="description" content="CineHub 3099 — أفلام ومسلسلات + أرباح إعلانات حقيقية. أرقام من العدّاد ومن بلوكتشين Base، ومسار سحب إلى الكريمي."/>
<link rel="manifest" href="manifest.json"/>
<meta name="theme-color" content="#0a0e1a"/>
<style>
:root{--bg:#0a0e1a;--card:#111827;--line:#1e2a44;--txt:#e8f6ff;--dim:#8aa0bd;--cy:#4dd0e1;--vi:#a78bfa;--ok:#34d399;--warn:#fbbf24;--bad:#f87171}
*{box-sizing:border-box}
body{margin:0;background:radial-gradient(1100px 520px at 50% -10%,#14203a,#0a0e1a 62%);color:var(--txt);font:15px/1.75 system-ui,"Segoe UI",Tahoma,sans-serif}
a{color:var(--cy)}
.wrap{max-width:980px;margin:0 auto;padding:16px}
header{display:flex;align-items:center;gap:12px;padding:14px 0;border-bottom:1px solid var(--line);flex-wrap:wrap}
.logo{width:38px;height:38px;border-radius:11px;background:linear-gradient(135deg,var(--cy),var(--vi));display:grid;place-items:center;font-weight:900;color:#04121a;font-size:18px}
h1{font-size:19px;margin:0}
.sub{color:var(--dim);font-size:12px}
nav{margin-right:auto;display:flex;gap:7px;flex-wrap:wrap}
nav a{font-size:12.5px;text-decoration:none;border:1px solid var(--line);padding:6px 11px;border-radius:9px}
nav a:hover{border-color:var(--cy)}
.grid{display:grid;gap:11px;grid-template-columns:repeat(auto-fit,minmax(155px,1fr));margin:14px 0}
.card{background:linear-gradient(180deg,#131c30,#0f1728);border:1px solid var(--line);border-radius:14px;padding:13px}
.k{color:var(--dim);font-size:11.5px}
.v{font-size:24px;font-weight:800;letter-spacing:-.5px}
h2{font-size:15.5px;margin:24px 0 8px;display:flex;align-items:center;gap:8px}
h2::before{content:"";width:4px;height:15px;border-radius:2px;background:linear-gradient(var(--cy),var(--vi))}
table{width:100%;border-collapse:collapse;font-size:12.5px}
th,td{padding:8px 6px;border-bottom:1px solid var(--line);text-align:right}
th{color:var(--dim);font-weight:600}
.pill{display:inline-block;padding:2px 9px;border-radius:999px;font-size:11px;border:1px solid}
.ok{color:var(--ok);border-color:#34d39955;background:#34d39911}
.bad{color:var(--bad);border-color:#f8717155;background:#f8717111}
input{width:100%;padding:9px 11px;border-radius:10px;border:1px solid var(--line);background:#0c1424;color:var(--txt);font:inherit}
pre{background:#0c1424;border:1px solid var(--line);padding:12px;border-radius:12px;overflow:auto;direction:ltr;font-size:12px;text-align:left}
code{background:#0c1424;border:1px solid var(--line);padding:1px 6px;border-radius:6px;font-size:12px;direction:ltr;display:inline-block}
.foot{color:var(--dim);font-size:12px;text-align:center;padding:24px 0;border-top:1px solid var(--line);margin-top:24px}
</style>
</head>
<body>
<div class="wrap">
<header>
  <div class="logo">&#9654;</div>
  <div><h1>CineHub 3099</h1><div class="sub">لوحة الأرباح الحقيقية — لا تقديرات مُجمّلة</div></div>
  <nav>
    <a href="earn.html">الأرباح</a><a href="withdraw.html">السحب</a>
    <a href="surveys.html">الاستطلاعات</a><a href="partners.html">الشركاء</a>
    <a href="b/movies-2026.html">أفلام 2026</a>
  </nav>
</header>

<div class="grid">
  <div class="card"><div class="k">زيارات هذا الجهاز</div><div class="v" id="v">0</div></div>
  <div class="card"><div class="k">ظهور الإعلانات</div><div class="v" id="i">0</div></div>
  <div class="card"><div class="k">RPM الافتراضي</div><div class="v">$1.20</div></div>
  <div class="card"><div class="k">تقدير الإيراد</div><div class="v" id="est">$0.0000</div></div>
</div>

<h2>حالة التفعيل — من الملفات الفعلية</h2>
<div class="card" id="status">… يُقرأ</div>

<h2>رصيد المحفظة — حقيقي من بلوكتشين Base</h2>
<div class="card">
  <div id="waddr" class="k">…</div>
  <div class="grid" id="wbal" style="margin:10px 0 0"></div>
  <div class="sub">يُقرأ مباشرة من شبكة Base عبر RPC عام — هذا رصيد قابل للسحب لحظيًا.</div>
</div>

<h2>حاسبة الإيراد</h2>
<div class="card">
  <div class="k">زيارات/شهر</div><input id="vis" value="10000"/>
  <div class="k" style="margin-top:10px">RPM ($ لكل 1000 ظهور)</div><input id="r2" value="1.2"/>
  <div style="margin-top:12px">الإيراد المتوقع/شهر: <b id="calc">$12.00</b> · الظهور ≈ <b id="imp">10,000</b></div>
  <div class="sub">RPM واقعي: 0.5–3$ للغرب · 0.3–1.5$ للعربي. لا أوهام.</div>
</div>

<h2>الشبكات — أدنى سحب وطرق الدفع</h2>
<div class="card" style="padding:0;overflow:auto">
<table><thead><tr><th>الشبكة</th><th>النوع</th><th>أدنى سحب</th><th>الدفع</th></tr></thead><tbody id="nets"></tbody></table>
</div>

<h2>الوصول إلى الكريمي</h2>
<div class="card">
<pre>Adsterra  (حد أدنى $5)
   |  سحب USDT (TRC20)
محفظة USDT (Binance / Trust Wallet)
   |  بيع على Binance P2P
حسابك في بنك الكريمي  (ريال يمني)</pre>
<div class="sub">PayPal شبه مغلق في اليمن — USDT هو الطريق. <a href="withdraw.html">التفاصيل الكاملة</a></div>
</div>

<h2>المحتوى</h2>
<div class="card" id="links">…</div>

<div class="foot">CineHub 3099 · <span id="stamp">—</span> · <a href="https://alisalimax3.github.io">alisalimax3.github.io</a></div>
</div>

<script>
(function(){
  var q=function(s){return document.querySelector(s)};
  var N=function(v){return isFinite(+v)?+v:0};
  function tick(){var v=N(localStorage.getItem("ch_visits")),i=N(localStorage.getItem("ch_impressions"));
    q("#v").textContent=v.toLocaleString("ar-EG");q("#i").textContent=i.toLocaleString("ar-EG");
    q("#est").textContent="$"+((i/1000)*1.2).toFixed(4);}
  tick();setInterval(tick,2000);
  function calc(){var v=N(q("#vis").value),r=N(q("#r2").value);
    q("#calc").textContent="$"+(v/1000*r).toFixed(2);q("#imp").textContent=v.toLocaleString("ar-EG");}
  q("#vis").oninput=calc;q("#r2").oninput=calc;calc();
  [["Adsterra","Display/Pop","$5","PayPal · Paxum · USDT · BTC"],["Monetag","Multi","$5","PayPal · Payoneer · Crypto"],
   ["PropellerAds","Push/Pop","$5","PayPal · Wire · Crypto"],["AdMaven","Push","$5","PayPal · Crypto"],
   ["Clickadu","Multi","$10","PayPal · Paxum · Crypto"],["HilltopAds","Multi","$20","PayPal · Paxum · Crypto"],
   ["ExoClick","Adult","$20","Paxum · PayPal · Crypto"],["Adcash","Multi","$25","PayPal · Payoneer · Wire"],
   ["NOWPayments","Premium","—","Crypto 0.5% · بلا KYC"]].forEach(function(n){
    var tr=document.createElement("tr");tr.innerHTML="<td><b>"+n[0]+"</b></td><td>"+n[1]+"</td><td>"+n[2]+"</td><td>"+n[3]+"</td>";
    q("#nets").appendChild(tr);});
  fetch("ads-config.json").then(function(r){return r.json()}).then(function(c){
    var a=[];
    if(c.main)a.push(["رابط الإعلان الرئيسي","ok","مُفعّل"]);
    if(c.adsterra&&c.adsterra.banner)a.push(["Adsterra banner","ok","مُفعّل"]);
    if(c.monetag&&c.monetag.vignette)a.push(["Monetag","ok","مُفعّل"]);
    if(!a.length)a.push(["لا شبكة مُفعّلة","bad","نفّذ: bash activate.sh"]);
    q("#status").innerHTML=a.map(function(x){return '<div style="margin:4px 0"><span class="pill '+x[1]+'">'+x[2]+'</span> '+x[0]+'</div>'}).join("");
  }).catch(function(){q("#status").innerHTML='<span class="pill bad">تعذّر قراءة ads-config.json</span>'});
  var RPC=["https://base.llamarpc.com","https://mainnet.base.org","https://base-rpc.publicnode.com","https://1rpc.io/base"];
  var TK={USDC:["0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",6],USDT:["0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",6],
          VVV:["0xacfE6019Ed1A7Dc6f7B508C02d1b04ec88cC21bf",18],DIEM:["0xf4d97f2da56e8c3098f3a8d538db630a2606a024",18]};
  function rpc(m,p){var b=JSON.stringify({jsonrpc:"2.0",id:1,method:m,params:p}),n=0;
    function go(){if(n>=RPC.length)return Promise.reject();
      return fetch(RPC[n++],{method:"POST",headers:{"Content-Type":"application/json"},body:b})
      .then(function(r){return r.json()}).then(function(j){return j.result?j.result:go()}).catch(go);}return go();}
  fetch("wallet.json").then(function(r){return r.json()}).then(function(w){
    var a=w.address||"";
    if(!/^0x[0-9a-fA-F]{40}$/.test(a)){q("#waddr").textContent="✗ لم تُحدَّد — نفّذ: bash wallet.sh 0x...";return;}
    q("#waddr").textContent="العنوان: "+a;
    var pad=a.toLowerCase().slice(2).padStart(64,"0");
    Object.keys(TK).forEach(function(s){var t=TK[s];
      rpc("eth_call",[{to:t[0],data:"0x70a08231"+pad},"latest"]).then(function(h){
        var d=document.createElement("div");d.className="card";
        d.innerHTML='<div class="k">'+s+' · Base</div><div class="v">'+(Number(BigInt(h))/Math.pow(10,t[1])).toFixed(4)+'</div>';
        q("#wbal").appendChild(d);}).catch(function(){
        var d=document.createElement("div");d.className="card";
        d.innerHTML='<div class="k">'+s+'</div><div class="v">—</div>';q("#wbal").appendChild(d);});});});
  fetch("sitemap.xml").then(function(r){return r.text()}).then(function(x){
    var u=(x.match(/<loc>(.*?)<\/loc>/g)||[]).map(function(s){return s.replace(/<\/?loc>/g,"")}).slice(0,14);
    q("#links").innerHTML=u.map(function(l){var t=l.split("/").pop().replace(".html","")||"الرئيسية";
      return '<a href="'+l+'" style="display:inline-block;margin:3px;border:1px solid #1e2a44;padding:4px 9px;border-radius:8px;font-size:12px;text-decoration:none">'+t+'</a>'}).join("");
  }).catch(function(){});
  q("#stamp").textContent=new Date().toISOString().slice(0,10);
})();
</script>
</body>
</html>
HTML
G "index.html مكتوبة"

H "4/6 withdraw.html — مسار الكريمي"
cat > withdraw.html <<'WD'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>السحب إلى الكريمي — CineHub 3099</title>
<link rel="stylesheet" href="index.html"/><style>
body{margin:0;background:#0a0e1a;color:#e8f6ff;font:15px/1.8 system-ui,Tahoma,sans-serif}
.wrap{max-width:820px;margin:0 auto;padding:18px}h1{font-size:20px}
h2{font-size:16px;margin:22px 0 6px;color:#4dd0e1}
table{width:100%;border-collapse:collapse;font-size:13px;margin:10px 0}
th,td{border-bottom:1px solid #1e2a44;padding:8px 6px;text-align:right}th{color:#8aa0bd}
pre{background:#0c1424;border:1px solid #1e2a44;padding:12px;border-radius:12px;direction:ltr;text-align:left;font-size:12px}
a{color:#4dd0e1}.n{background:#111827;border:1px solid #1e2a44;border-radius:12px;padding:12px;margin:10px 0}
</style></head><body><div class="wrap">
<h1>السحب الحقيقي → بنك الكريمي</h1>
<p>لا تحويل بنكي دولي. المسار الأقصر والأنسب لليمن:</p>
<pre>1. Adsterra  →  حد أدنى $5  →  سحب USDT (TRC20)
2. محفظة USDT (Binance أو Trust Wallet)
3. بيع USDT على Binance P2P  →  استلام ريال يمني
4. الدفع عبر بنك الكريمي  →  نقد في يدك</pre>
<h2>لماذا USDT وليس PayPal؟</h2>
<p>PayPal شبه مغلق في اليمن، والتحويل البنكي الدولي مكلف. USDT على TRC20 عمولته أقل من دولار ووصل فوري.</p>
<h2>الشبكات التي تدفع USDT/Crypto (ابدأ بها)</h2>
<table><tr><th>الشبكة</th><th>أدنى سحب</th><th>مدة الدفعة</th></tr>
<tr><td>Adsterra</td><td>$5</td><td>NET-15 إلى 30</td></tr>
<tr><td>Monetag</td><td>$5</td><td>NET-30</td></tr>
<tr><td>PropellerAds</td><td>$5</td><td>NET-15</td></tr>
<tr><td>AdMaven</td><td>$5</td><td>NET-30</td></tr></table>
<h2>خطوات لا تتخطاها (وإلا يُوقف الدفع)</h2>
<div class="n"><b>1.</b> املأ نموذج <b>W-8BEN</b> في كل شبكة — بدونه يُحجز المال مهما ربحت.<br>
<b>2.</b> وثّق الإيميل والهاتف وفعّل المصادقة الثنائية.<br>
<b>3.</b> اضبط طريقة الدفع (USDT TRC20) قبل الوصول للحد الأدنى.<br>
<b>4.</b> لا تفتح موقعك بVPN متقافز ولا refresh آلي — anti-fraud يجمّد الحساب.</div>
<h2>الأرقام الصادقة</h2>
<p>الإيراد = (الظهور ÷ 1000) × RPM. للوصول لأول $5 تحتاج ≈ <b>5,000 ظهور</b> ≈ 1,500–2,500 زيارة. أول قبض واقعي: <b>30–60 يومًا</b> من بدء الإعلانات الفعلي.</p>
<p><a href="index.html">← رجوع للوحة</a></p>
</div></body></html>
WD
G "withdraw.html"

H "5/6 تنظيف + نشر"
python3 - <<'PY'
import json,os,re
def bad(v): return bool(re.search(r"[\u0600-\u06FF]|TOKEN|\.\.\.|xxx|XXX|PUT-|YOUR",str(v)))
def fix(v):
    if isinstance(v,str): return "" if bad(v) else v
    if isinstance(v,dict): return {k:fix(x) for k,x in v.items()}
    if isinstance(v,list): return [fix(x) for x in v]
    return v
for f in ("ads-config.json","surveys-config.json","wallet.json","payouts.json"):
    if not os.path.exists(f): continue
    try: d=json.load(open(f,encoding="utf-8"))
    except Exception: continue
    json.dump(fix(d),open(f,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
PY
bash publish.sh || exit 1

H "6/6 تحقق حيّ (بعد 80 ثانية من بناء Pages)"
sleep 80
python3 - <<'PY'
import urllib.request,re
B="https://alisalimax3.github.io"
def get(u):
    try:
        r=urllib.request.urlopen(B+u,timeout=25); return r.status,r.read().decode("utf-8","ignore")
    except Exception as e: return getattr(e,"code","ERR"),""
ok=True
for u in ["/","/index.html","/withdraw.html","/ads.js","/ads-config.json","/wallet.json","/sitemap.xml","/robots.txt"]:
    s,b=get(u); print("  %s  %s"%(s,u)); ok = ok and s==200
s,_=get("/cinehub3099/"); print("  %s  /cinehub3099/  (يجب 404 = المسارات صحيحة)"%s)
s,b=get("/")
print("  محتوى الصفحة:", "CineHub 3099 موجود ✓" if "CineHub 3099" in b else "✗ لا يحتوي العنوان")
print("  الحجم:",len(b),"بايت")
print("\n"+("✓ الموقع يعمل فعليًا" if ok else "✗ توجد صفحات فاشلة"))
PY
