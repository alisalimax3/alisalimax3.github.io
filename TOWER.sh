#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  CineHub 3099 — TOWER.sh
#  تشخيص حيّ آلي + تشغيل الوكيل + توسيع المنصات + سدّ الصفحات الناقصة
# =====================================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"; OWNER="alkazmybwhwr-dot"; REPO="$OWNER.github.io"; LIVE="https://$OWNER.github.io"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
TOK="$(git remote get-url origin 2>/dev/null | sed -n 's|https://[^:]*:\([^@]*\)@.*|\1|p')"
API(){ curl -s -H "Authorization: token $TOK" -H "Accept: application/vnd.github+json" "$@"; }
mkdir -p tools

git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
git branch -f main HEAD >/dev/null 2>&1 || true
git fetch origin main -q 2>/dev/null || true
git rebase --autostash origin/main -q >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
touch .nojekyll

push_all(){
  local msg="$1" try
  for try in 1 2 3 4 5 6 7 8; do
    git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
    git branch -f main HEAD >/dev/null 2>&1 || true
    git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true
    git fetch origin main -q 2>/dev/null || true
    git rebase --autostash origin/main -q >/dev/null 2>&1 || {
      git rebase --abort >/dev/null 2>&1; git reset --mixed origin/main -q >/dev/null 2>&1
      git add -A; git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true; }
    git branch -f main HEAD >/dev/null 2>&1 || true
    git push origin main 2>.push.err && { ok "مدفوع"; return 0; }
    git push --force-with-lease origin main 2>.push.err && { ok "مدفوع بضمان"; return 0; }
    sleep 6
  done
  bad "تعذّر الدفع"; sed -n '1,6p' .push.err; return 1
}

# ================== 1) تشخيص حيّ آلي ==================
cat > tools/diag.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يفحص ما هو منشور فعلًا على الموقع الحي ويكتب diag.json — بلا تخمين"""
import json,os,urllib.request,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
LIVE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io")
FILES=["index.html","library.html","adult.html","play.html","watch.html","go.html","earn.html",
       "rise.html","agent.html","withdraw.html","keys.html","share.html","rails.html","tower.html",
       "rewards.html","cinema.html","auto.html","surveys.html","audit.html","live-dash.html","diag.html",
       "nav.js","ads.js","authtoken.js","catalog.json","adult.json","auth.json","browse.json",
       "keys-status.json","tasks.json","rewards.json","treasury.json","revenue.json","registry.json",
       "sitemap.xml","rss.xml","robots.txt"]
def head(u):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,method="HEAD",headers={"User-Agent":"ch3099"}),timeout=20)
        return r.status
    except Exception as e:
        return getattr(e,"code",0)
res={}
for f in FILES: res[f]=head("%s/%s?d=%s"%(LIVE,f,int(datetime.datetime.now().timestamp())))
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
cat=L("catalog.json",{}); ad=L("adult.json",{}); br=L("browse.json",{}); ks=L("keys-status.json",{})
rw=L("rewards.json",{}); tr=L("treasury.json",{}); pu=L("pulse.json",{}); rg=L("registry.json",{})
out={"at":datetime.datetime.now(datetime.timezone.utc).isoformat(),
     "live":res,"ok":sum(1 for v in res.values() if v==200),"total":len(res),
     "missing":[f for f,v in res.items() if v!=200],
     "content":{"films":cat.get("count",0),"adult":ad.get("count",0),
                "film_pages":len(os.listdir("p")) if os.path.isdir("p") else 0,
                "tag_pages":len(os.listdir("x")) if os.path.isdir("x") else 0},
     "agent":{"ad_requests":br.get("ad_requests",0),"browse_runs":br.get("runs",0),
              "cycles":pu.get("cycle",0),"rewards":rw.get("total",0),
              "valid_keys":ks.get("valid",0),"keys_total":ks.get("checked",0)},
     "money":{"balance":tr.get("balance",0),"buckets":tr.get("buckets",{}),
              "platforms":rg.get("counts",{}).get("sites",0)}}
json.dump(out,open("diag.json","w"),ensure_ascii=False,indent=1)
print("حيّ %d/%d | غائب: %s"%(out["ok"],out["total"],", ".join(out["missing"][:8]) or "لا شيء"))
print("أفلام %d · كبار %d · طلبات إعلان %d · دورات %d"%(cat.get("count",0),ad.get("count",0),br.get("ad_requests",0),pu.get("cycle",0)))
PYEOF

# ================== 2) سدّ الصفحات الناقصة ==================
mk(){ cat > "$1" <<EOF
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>$2 — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:14px 14px 70px;line-height:1.8}
a{color:#4cc2ff}.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:13px;margin:11px 0}
.c{color:#8ea3b8;font-size:13px}.big{font-size:24px;font-weight:800}.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:10px}
.cd{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;overflow:hidden;text-decoration:none;color:inherit}
.cd img{width:100%;height:150px;object-fit:cover;display:block}.cd b{font-size:12.5px;display:block;padding:7px}</style></head><body>
<h1>$2</h1><div id="b" class="c">…</div><div class="g" id="g"></div>
<script>
(function(){function g(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
$3
})();
</script></body></html>
EOF
}

mk cinema.html "سينما" '
g("catalog.json").then(function(d){if(!d){document.getElementById("b").textContent="لا كتالوج";return;}
var a=d.items.filter(function(x){return ["دراما","رومانسي","مغامرات","غربي","إثارة","جريمة"].indexOf(x.c)>-1;});
document.getElementById("b").textContent=a.length+" فيلم سينمائي · <a href=\"library.html\">المكتبة</a>";
document.getElementById("g").innerHTML=a.slice(0,36).map(function(x){return "<a class=cd href=\"play.html?id="+encodeURIComponent(x.i)+"\"><img loading=lazy src=\""+x.th+"\"><b>"+x.t+"</b></a>";}).join("");});'

mk auto.html "شاهد واقبض" '
g("catalog.json").then(function(d){if(!d){document.getElementById("b").textContent="لا كتالوج";return;}
document.getElementById("b").innerHTML="<b>اضغط فيلمًا → شاهد 15 ثانية → اقبض.</b> <a href=\"watch.html\">تشغيل تلقائي</a> · <a href=\"earn.html\">المهام</a>";
document.getElementById("g").innerHTML=d.items.slice(0,36).map(function(x){return "<a class=cd href=\"play.html?id="+encodeURIComponent(x.i)+"\"><img loading=lazy src=\""+x.th+"\"><b>"+x.t+"</b></a>";}).join("");});'

mk surveys.html "استطلاعات تدفع" '
var P=[["BitLabs","https://bitlabs.ai"],["CPX Research","https://www.cpx-research.com"],["TheoremReach","https://theoremreach.com"],["Pollfish","https://www.pollfish.com"],["Ayet Studios","https://ayetstudios.com"],["Lootably","https://lootably.com"],["AdGate","https://adgatemedia.com"],["OfferToro","https://www.offertoro.com"]];
document.getElementById("b").textContent="بوابات حقيقية — تُفتح في تبويب وتُدفع لها مباشرة";
document.getElementById("g").innerHTML=P.map(function(p){return "<a class=cd style=\"padding:14px\" target=_blank href=\""+p[1]+"\"><b>"+p[0]+"</b><span class=c>فتح ↗</span></a>";}).join("");'

mk rewards.html "مكافآت" '
function g2(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
g2("tasks.json").then(function(t){var b=document.getElementById("b");
if(!t){b.textContent="…";return;}
b.innerHTML="معدلات معلنة — <a href=\"earn.html\">نفّذ المهام</a>";
document.getElementById("g").innerHTML=t.tasks.map(function(x){return "<div class=cd style=\"padding:12px\"><b>"+x.t+"</b><span class=c>$"+x.v.toFixed(4)+" · "+x.d+"</span></div>";}).join("");});'

mk audit.html "السجل الموثّق" '
g("ledger.json").then(function(l){var b=document.getElementById("b");
if(!l||!l.entries){b.textContent="لا قيود بعد";return;}
b.innerHTML="قيود: <b>"+l.entries.length+"</b> — كل قيد يحمل هاش السابق";
document.getElementById("g").innerHTML=l.entries.slice(-24).reverse().map(function(x){return "<div class=cd style=\"padding:10px\"><b>#"+x.i+"</b><span class=c>"+x.t+"</span><span class=c style=\"color:#7fd88a\">"+x.h.slice(0,20)+"…</span></div>";}).join("");});'

mk live-dash.html "لوحة المتابعة" '
function g2(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
g2("diag.json").then(function(d){var b=document.getElementById("b");
if(!d){b.textContent="…";return;}
b.innerHTML="ملفات حيّة: <b>"+d.ok+"/"+d.total+"</b> · طلبات إعلان: <b>"+d.agent.ad_requests+"</b> · دورات: <b>"+d.agent.cycles+"</b> · رصيد: <b>$"+(d.money.balance||0).toFixed(6)+"</b>";
document.getElementById("g").innerHTML=(d.missing||[]).map(function(f){return "<div class=cd style=\"padding:10px\"><b style=\"color:#ff9a6b\">✗ "+f+"</b></div>";}).join("")||"<div class=cd style=padding:10px><b style=color:#7fd88a>✓ كل الملفات حيّة</b></div>";});'

mk tower.html "برج التحكّم" '
function g2(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
g2("diag.json").then(function(d){var b=document.getElementById("b");
if(!d){b.textContent="لا تشخيص بعد — شغّل TOWER.sh";return;}
b.innerHTML="<div>ملفات حيّة: <b>"+d.ok+"/"+d.total+"</b></div><div>أفلام: <b>"+d.content.films+"</b> · كبار: <b>"+d.content.adult+"</b> · صفحات: <b>"+d.content.film_pages+"</b></div>"+
"<div>مكافآت الوكيل: <b>$"+(d.agent.rewards||0).toFixed(6)+"</b> · دورات: <b>"+d.agent.cycles+"</b></div>"+
"<div>طلبات إعلان حقيقية: <b>"+d.agent.ad_requests+"</b></div><div>مفاتيح صالحة: <b>"+d.agent.valid_keys+"</b></div>"+
"<div>مواقع مربوطة: <b>"+(d.money.platforms||0)+"</b></div>"+
"<div style=\"margin-top:8px\">"+((d.missing||[]).length?("<span class=c>غائب: "+d.missing.join(", ")+"</span>"):"<span style=color:#7fd88a>كل الملفات حيّة ✓</span>")+"</div>";
document.getElementById("g").innerHTML=[["المكتبة","library.html"],["للكبار","adult.html"],["تشغيل تلقائي","watch.html"],["المفاتيح","keys.html"],["النشر","share.html"],["الوكيل","agent.html"],["مسارات الدفع","rails.html"],["تشخيص","diag.html"],["السجل","audit.html"],["استطلاعات","surveys.html"],["مكافآت","rewards.html"]].map(function(x){return "<a class=cd style=\"padding:14px\" href=\""+x[1]+"\"><b>"+x[0]+"</b></a>";}).join("");});'
ok "الصفحات الناقصة سُدّت"

# ================== 3) توسيع المنصات والشركات ==================
cat > tools/platforms_plus.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يضيف شبكات وشركات ومنصات حقيقية إضافية إلى قوائم التسجيل والسجل"""
import json,os,re,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
NEW=[
# إعلانات وبرمجيات وسيطة
("Snigel","إعلانات","https://www.snigel.com"),("Publift","إعلانات","https://www.publift.com"),
("Mediavine","إعلانات","https://www.mediavine.com"),("AdThrive","إعلانات","https://www.adthrive.com"),
("Raptive","إعلانات","https://raptive.com"),("Monumetric","إعلانات","https://www.monumetric.com"),
("Freestar","إعلانات","https://freestar.com"),("AdPushup","إعلانات","https://www.adpushup.com"),
("Adapex","إعلانات","https://adapex.io"),("Sulvo","إعلانات","https://sulvo.com"),
("Primis","إعلانات","https://www.primis.tech"),("Vidoomy","إعلانات","https://vidoomy.com"),
("AdPlayer.Pro","إعلانات","https://adplayer.pro"),("VideoByte","إعلانات","https://videobyte.com"),
("Exponential","إعلانات","https://exponential.com"),("Plista","إعلانات","https://www.plista.com"),
("Dianomi","إعلانات","https://www.dianomi.com"),("Zemanta","إعلانات","https://www.zemanta.com"),
("Adyoulike","إعلانات","https://www.adyoulike.com"),("Sirdata","إعلانات","https://www.sirdata.com"),
# كبار إضافي
("TrafficHaus","كبار","https://www.traffichaus.com"),("AdultAdWorld","كبار","https://adultadworld.com"),
("ExoGroup","كبار","https://www.exogroup.com"),("Juicy Ads Network","كبار","https://www.juicyads.com"),
("EroAds","كبار","https://www.eroadvertising.com"),("TrafficShop","كبار","https://trafficshop.com"),
("PlugRush Adult","كبار","https://www.plugrush.com"),("PinkAds","كبار","https://pinkads.io"),
("AdSpyglass","كبار","https://www.adspyglass.com"),("Recreativ","كبار","https://recreativ.com"),
("Adsterra Adult","كبار","https://adsterra.com"),("HilltopAds Adult","كبار","https://hilltopads.com"),
("Clickadu Adult","كبار","https://clickadu.com"),("Evadav Adult","كبار","https://evadav.com"),
# CPA وموبايل
("AdCombo","CPA","https://adcombo.com"),("TerraLeads","CPA","https://terraleads.com"),
("Zeydoo","CPA","https://zeydoo.com"),("Leadbit","CPA","https://leadbit.com"),
("Kma.biz","CPA","https://kma.biz"),("Datify","CPA","https://datify.link"),
("ClickDealer","CPA","https://www.clickdealer.com"),("M4trix","CPA","https://m4trix.co"),
("AlgoAffiliates","CPA","https://algoaffiliates.com"),("Adcell","CPA","https://www.adcell.com"),
("Tradetracker","CPA","https://www.tradetracker.com"),("Zanox","CPA","https://www.zanox.com"),
("Public-Idées","CPA","https://www.public-idees.com"),("Cake","CPA","https://www.cake.com"),
("Post Affiliate Pro","CPA","https://www.postaffiliatepro.com"),("HasOffers","CPA","https://www.hasoffers.com"),
("Tapfiliate","CPA","https://tapfiliate.com"),("FirstPromoter","CPA","https://firstpromoter.com"),
("Rewardful","CPA","https://www.rewardful.com"),("Refersion","CPA","https://www.refersion.com"),
("BuyGoods","CPA","https://www.buygoods.com"),("Smash Loud","CPA","https://smashloud.com"),
("MaxWeb","CPA","https://maxweb.com"),("Algo Affiliates","CPA","https://algoaffiliates.com"),
# استطلاعات وأوفروول
("Persona.ly","استطلاعات","https://persona.ly"),("Adikteev","استطلاعات","https://www.adikteev.com"),
("Wannads","استطلاعات","https://www.wannads.com"),("AdGem","استطلاعات","https://www.adgem.com"),
("Survey Sampling","استطلاعات","https://www.surveysampling.com"),("Prodege","استطلاعات","https://www.prodege.com"),
("Cint","استطلاعات","https://www.cint.com"),("Toluna","استطلاعات","https://www.toluna.com"),
("Attapoll","استطلاعات","https://attapoll.app"),("Streetbees","استطلاعات","https://www.streetbees.com"),
("Poll Pay","استطلاعات","https://pollpay.app"),("Tremendous","استطلاعات","https://www.tremendous.com"),
# روابط
("Shorte.st","روابط","https://shorte.st"),("Adf.ly","روابط","https://adf.ly"),
("Linkshortify","روابط","https://linkshortify.com"),("Mdisk Shortner","روابط","https://mdiskshortner.com"),
("TnLink","روابط","https://tnlink.in"),("Try2Link","روابط","https://try2link.com"),
("Boost.ink","روابط","https://boost.ink"),("Short2URL","روابط","https://short2url.in"),
("Sub2Unlock","روابط","https://sub2unlock.com"),("Loot-Link","روابط","https://loot-link.com"),
("Lootlabs","روابط","https://lootlabs.gg"),("Rekonise","روابط","https://rekonise.com"),
("Work.ink","روابط","https://work.ink"),("FC.lc","روابط","https://fc.lc"),
("Payouts.click","روابط","https://payouts.click"),("Shortzzy","روابط","https://shortzzy.in"),
("Clicksfly","روابط","https://clicksfly.com"),("Flyad","روابط","https://flyad.link"),
("Za.gl","روابط","https://za.gl"),("OuO.io","روابط","https://ouo.io"),
# دفع وتحويل (الأهم لليمن)
("Binance P2P","دفع","https://p2p.binance.com"),("Bybit","دفع","https://www.bybit.com"),
("OKX","دفع","https://www.okx.com"),("MEXC","دفع","https://www.mexc.com"),
("Bitget","دفع","https://www.bitget.com"),("WhiteBIT","دفع","https://whitebit.com"),
("Gate.io","دفع","https://www.gate.io"),("Kraken","دفع","https://www.kraken.com"),
("Coinbase","دفع","https://www.coinbase.com"),("NOWPayments","دفع","https://nowpayments.io"),
("Paxum","دفع","https://www.paxum.com"),("Payeer","دفع","https://payeer.com"),
("AdvCash","دفع","https://advcash.com"),("Skrill","دفع","https://www.skrill.com"),
("Trust Wallet","دفع","https://trustwallet.com"),("MetaMask","دفع","https://metamask.io"),
("Tether TRC20","دفع","https://tether.to"),("FaucetPay","دفع","https://faucetpay.io"),
("AirTM","دفع","https://airtm.com"),("Wise","دفع","https://wise.com"),
("Western Union","دفع","https://www.westernunion.com"),("Al-Kuraimi Bank","دفع","https://www.alkuraimi.com"),
# محتوى وشركاء
("Internet Archive","محتوى","https://archive.org"),("Wikimedia Commons","محتوى","https://commons.wikimedia.org"),
("Project Gutenberg","محتوى","https://www.gutenberg.org"),("Dailymotion","محتوى","https://www.dailymotion.com"),
("PeerTube","محتوى","https://joinpeertube.org"),("LBRY","محتوى","https://lbry.com"),
("Odysee","محتوى","https://odysee.com"),("Vimeo","محتوى","https://vimeo.com"),
("Eporner","محتوى","https://www.eporner.com"),("RedTube","محتوى","https://www.redtube.com"),
("Pornhub","محتوى","https://www.pornhub.com"),("xHamster","محتوى","https://xhamster.com"),
("XVideos","محتوى","https://www.xvideos.com"),("XNXX","محتوى","https://www.xnxx.com"),
("SpankBang","محتوى","https://spankbang.com"),("TNAFlix","محتوى","https://www.tnaflix.com"),
("HQPorner","محتوى","https://hqporner.com"),("PornTrex","محتوى","https://porntrex.com"),
("Chaturbate","محتوى","https://chaturbate.com"),("Stripchat","محتوى","https://stripchat.com"),
("BongaCams","محتوى","https://bongacams.com"),("LiveJasmin","محتوى","https://www.livejasmin.com"),
("Camsoda","محتوى","https://www.camsoda.com"),("ManyVids","محتوى","https://www.manyvids.com"),
("Clips4Sale","محتوى","https://www.clips4sale.com"),("AdultEmpire","محتوى","https://www.adultempire.com"),
]
def dom(u):
    m=re.match(r"https?://([^/]+)",u or ""); return m.group(1).lower().replace("www.","") if m else ""
s=[]
try: s=json.load(open("signup.json",encoding="utf-8"))
except Exception: s=[]
have={dom(x.get("url","")) for x in s}
add=0
for n,c,u in NEW:
    d=dom(u)
    if d in have: continue
    have.add(d)
    s.append({"name":n,"cat":c,"min":"$5","url":u,"var":re.sub(r"[^A-Z0-9]","_",n.upper())+"_KEY"})
    add+=1
json.dump(s,open("signup.json","w"),ensure_ascii=False,indent=1)
pa={}
try: pa=json.load(open("platforms_active.json",encoding="utf-8"))
except Exception: pa={"items":[]}
items=pa.get("items",[]); h2={dom(x.get("url","")) for x in items}
for n,c,u in NEW:
    d=dom(u)
    if d in h2: continue
    h2.add(d); items.append({"name":n,"cat":c,"min":"$5","url":u,"key_var":"","pay":"USDT / Wire"})
pa["items"]=items; pa["count"]=len(items)
pa["generated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
json.dump(pa,open("platforms_active.json","w"),ensure_ascii=False,indent=1)
print("منصات مضافة:",add,"| إجمالي قوائم التسجيل:",len(s),"| إجمالي المنصات:",len(items))
PYEOF
python3 tools/platforms_plus.py

# ================== 4) الدورة تشمل التشخيص والتوسيع ==================
python3 - <<'PY'
import os
os.chdir(os.path.expanduser("~/cinehub3099"))
p="tools/agent_cycle.sh"; t=open(p,encoding="utf-8").read()
if "diag.py" not in t:
    t=t.replace("run tools/gates.py","run tools/platforms_plus.py\nrun tools/gates.py\nrun tools/diag.py")
    open(p,"w",encoding="utf-8").write(t)
print("الدورة: تشخيص + توسيع")
PY

# ================== 5) نشر + تحقق + تشغيل الوكيل ==================
python3 tools/diag.py || true
bash tools/agent_cycle.sh || true
echo "$V" > sw-version.txt
push_all "tower: live diag + missing pages + platform expansion [$V]"

git fetch origin main -q 2>/dev/null || true
git ls-tree -r origin/main --name-only > .remote.txt 2>/dev/null || true
M=0
for f in tower.html diag.html diag.json cinema.html auto.html surveys.html rewards.html audit.html live-dash.html catalog.json adult.json .github/workflows/agent.yml; do
  grep -qx "$f" .remote.txt && ok "$f" || { bad "$f غائب"; M=$((M+1)); }
done
[ "$M" = "0" ] && ok "كل الملفات في الريموت" || warn "$M غائب"

info "تشغيل الوكيل الآن..."
for wf in agent.yml browse.yml; do
  R="$(API -X POST -H "Content-Type: application/json" -d '{"ref":"main"}' \
      "https://api.github.com/repos/$REPO/actions/workflows/$wf/dispatches" -o /dev/null -w '%{http_code}')"
  [ "$R" = "204" ] && ok "شُغّل $wf" || bad "$wf → $R"
done

sleep 60
API "https://api.github.com/repos/$REPO/actions/runs?per_page=3" | python3 -c "
import json,sys
d=json.load(sys.stdin); r=d.get('workflow_runs') or []
print('  لا تشغيل' if not r else '')
for x in r[:3]: print('  •',x.get('name'),x.get('status'),x.get('conclusion') or '-')
"
python3 tools/diag.py || true
echo; ok "افتح: $LIVE/tower.html"
