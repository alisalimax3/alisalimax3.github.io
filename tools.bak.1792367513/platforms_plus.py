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
