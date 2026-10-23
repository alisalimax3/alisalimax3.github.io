#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني سجل المنصات: بذور دخل حقيقية + توسيع من الكتالوج حتى 1000 رابط حقيقي"""
import os, json, re, datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET=int(os.environ.get("PLATFORM_TARGET","1000"))

SEED=[
("Google AdSense","إعلانات","$100","https://www.google.com/adsense/start/","ADSENSE_KEY"),
("Google Ad Manager","إعلانات","$100","https://admanager.google.com","GAM_KEY"),
("Google AdMob","إعلانات","$100","https://admob.google.com","ADMOB_KEY"),
("Meta Audience Network","إعلانات","$100","https://www.facebook.com/audiencenetwork/","META_AN_KEY"),
("Microsoft Monetize","إعلانات","$50","https://about.ads.microsoft.com","MSADS_KEY"),
("Amazon Publisher Services","إعلانات","$100","https://aps.amazon.com","APS_KEY"),
("Adsterra","إعلانات","$5","https://adsterra.com","ADSTERRA_API_KEY"),
("Monetag","إعلانات","$5","https://monetag.com","MONETAG_KEY"),
("PropellerAds","إعلانات","$5","https://propellerads.com","PROPELLER_KEY"),
("PopAds","إعلانات","$5","https://www.popads.net","POPADS_KEY"),
("PopCash","إعلانات","$5","https://popcash.net","POPCASH_KEY"),
("AdMaven","إعلانات","$5","https://admaven.com","ADMAVEN_KEY"),
("HilltopAds","إعلانات","$5","https://hilltopads.com","HILLTOP_KEY"),
("Evadav","إعلانات","$5","https://evadav.com","EVADAV_KEY"),
("Clickadu","إعلانات","$5","https://clickadu.com","CLICKADU_KEY"),
("AdCash","إعلانات","$25","https://adcash.com","ADCASH_KEY"),
("Galaksion","إعلانات","$5","https://galaksion.com","GALAKSION_KEY"),
("MyBid","إعلانات","$5","https://mybid.io","MYBID_KEY"),
("RichAds","إعلانات","$5","https://richads.com","RICHADS_KEY"),
("Kadam","إعلانات","$10","https://kadam.net","KADAM_KEY"),
("ExoClick","إعلانات","$20","https://www.exoclick.com","EXOCLICK_KEY"),
("JuicyAds","إعلانات","$50","https://www.juicyads.com","JUICYADS_KEY"),
("TrafficJunky","إعلانات","$20","https://www.trafficjunky.com","TRAFFICJUNKY_KEY"),
("TrafficStars","إعلانات","$25","https://trafficstars.com","TRAFFICSTARS_KEY"),
("PlugRush","إعلانات","$5","https://www.plugrush.com","PLUGRUSH_KEY"),
("Bidvertiser","إعلانات","$10","https://www.bidvertiser.com","BIDVERTISER_KEY"),
("Infolinks","إعلانات","$50","https://www.infolinks.com","INFOLINKS_KEY"),
("MGID","إعلانات","$10","https://www.mgid.com","MGID_KEY"),
("Taboola","إعلانات","$100","https://www.taboola.com","TABOOLA_KEY"),
("Outbrain","إعلانات","$100","https://www.outbrain.com","OUTBRAIN_KEY"),
("RevContent","إعلانات","$50","https://www.revcontent.com","REVCONTENT_KEY"),
("Ezoic","إعلانات","$20","https://www.ezoic.com","EZOIC_KEY"),
("NitroPay","إعلانات","$20","https://nitropay.com","NITROPAY_KEY"),
("Setupad","إعلانات","$50","https://setupad.com","SETUPAD_KEY"),
("Playwire","إعلانات","$50","https://www.playwire.com","PLAYWIRE_KEY"),
("Mediavine","إعلانات","$100","https://www.mediavine.com","MEDIAVINE_KEY"),
("Snigel","إعلانات","$50","https://www.snigel.com","SNIGEL_KEY"),
("Publift","إعلانات","$50","https://www.publift.com","PUBLIFT_KEY"),
("A-ADS","إعلانات","$1","https://a-ads.com","AADS_KEY"),
("Coinzilla","إعلانات","$20","https://coinzilla.com","COINZILLA_KEY"),
("Bitmedia","إعلانات","$20","https://bitmedia.io","BITMEDIA_KEY"),
("Cointraffic","إعلانات","$20","https://cointraffic.io","COINTRAFFIC_KEY"),
("Teads","إعلانات","$100","https://www.teads.com","TEADS_KEY"),
("Primis","إعلانات","$50","https://www.primis.tech","PRIMIS_KEY"),
("Connatix","إعلانات","$50","https://www.connatix.com","CONNATIX_KEY"),
("Aniview","إعلانات","$50","https://aniview.com","ANIVIEW_KEY"),
("Smaato","إعلانات","$50","https://www.smaato.com","SMAATO_KEY"),
("Mobfox","إعلانات","$50","https://www.mobfox.com","MOBFOX_KEY"),
("InMobi","إعلانات","$50","https://www.inmobi.com","INMOBI_KEY"),
("Unity Ads","إعلانات","$100","https://unity.com/solutions/unity-ads","UNITYADS_KEY"),
("AppLovin","إعلانات","$100","https://www.applovin.com","APPLOVIN_KEY"),
("Chartboost","إعلانات","$100","https://www.chartboost.com","CHARTBOOST_KEY"),
("Mintegral","إعلانات","$100","https://www.mintegral.com","MINTEGRAL_KEY"),
("ironSource","إعلانات","$100","https://www.is.com","IRONSOURCE_KEY"),
("Digital Turbine","إعلانات","$100","https://www.digitalturbine.com","DIGITALTURBINE_KEY"),
("Ogury","إعلانات","$100","https://www.ogury.com","OGURY_KEY"),
("CPAGrip","CPA","$50","https://www.cpagrip.com","CPAGRIP_KEY"),
("CPALead","CPA","$50","https://www.cpalead.com","CPALEAD_KEY"),
("OGAds","CPA","$20","https://www.ogads.com","OGADS_KEY"),
("AdGate Media","CPA","$10","https://adgatemedia.com","ADGATE_KEY"),
("AdWork Media","CPA","$25","https://www.adworkmedia.com","ADWORKMEDIA_KEY"),
("MaxBounty","CPA","$50","https://www.maxbounty.com","MAXBOUNTY_KEY"),
("Lootably","CPA","$5","https://lootably.com","LOOTABLY_KEY"),
("Timewall","CPA","$5","https://timewall.io","TIMEWALL_KEY"),
("OfferToro","CPA","$5","https://www.offertoro.com","OFFERTORO_KEY"),
("Adscend Media","CPA","$10","https://www.adscendmedia.com","ADSCEND_KEY"),
("Wannads","CPA","$5","https://www.wannads.com","WANNADS_KEY"),
("AdGem","CPA","$5","https://www.adgem.com","ADGEM_KEY"),
("Persona.ly","CPA","$50","https://persona.ly","PERSONALY_KEY"),
("Mobidea","CPA","$50","https://www.mobidea.com","MOBIDEA_KEY"),
("Dr.Cash","CPA","$50","https://dr.cash","DRCASH_KEY"),
("Advidi","CPA","$100","https://advidi.com","ADVIDI_KEY"),
("Gotzha","CPA","$50","https://gotzha.com","GOTZHA_KEY"),
("Affise","CPA","$100","https://affise.com","AFFISE_KEY"),
("Everflow","CPA","$100","https://www.everflow.io","EVERFLOW_KEY"),
("TUNE","CPA","$100","https://www.tune.com","TUNE_KEY"),
("ClickBank","عمولات","$10","https://www.clickbank.com","CLICKBANK_KEY"),
("Digistore24","عمولات","$10","https://www.digistore24.com","DIGISTORE_KEY"),
("Impact","عمولات","$10","https://impact.com","IMPACT_KEY"),
("CJ Affiliate","عمولات","$50","https://www.cj.com","CJ_KEY"),
("Awin","عمولات","$20","https://www.awin.com","AWIN_KEY"),
("Rakuten Advertising","عمولات","$50","https://rakutenadvertising.com","RAKUTEN_KEY"),
("ShareASale","عمولات","$50","https://www.shareasale.com","SHAREASALE_KEY"),
("Admitad","عمولات","$10","https://www.admitad.com","ADMITAD_KEY"),
("FlexOffers","عمولات","$50","https://www.flexoffers.com","FLEXOFFERS_KEY"),
("Skimlinks","عمولات","$10","https://skimlinks.com","SKIMLINKS_KEY"),
("Sovrn","عمولات","$25","https://www.sovrn.com","SOVRN_KEY"),
("PartnerStack","عمولات","$50","https://partnerstack.com","PARTNERSTACK_KEY"),
("Tradedoubler","عمولات","$50","https://www.tradedoubler.com","TRADEDOUBLER_KEY"),
("Tradedoubler-UK","عمولات","$50","https://www.tradedoubler.com/uk/","TRADEDOUBLER_UK"),
("Webgains","عمولات","$50","https://www.webgains.com","WEBGAINS_KEY"),
("Belboon","عمولات","$50","https://www.belboon.com","BELBOON_KEY"),
("Daisycon","عمولات","$50","https://www.daisycon.com","DAISYCON_KEY"),
("Kwanko","عمولات","$50","https://www.kwanko.com","KWANKO_KEY"),
("Effiliation","عمولات","$50","https://www.effiliation.com","EFFILIATION_KEY"),
("Amazon Associates","عمولات","$10","https://affiliate-program.amazon.com","AMAZON_ASSOC"),
("AliExpress Portals","عمولات","$5","https://portals.aliexpress.com","ALIEXPRESS_KEY"),
("BitLabs","استطلاعات","$5","https://bitlabs.ai","BITLABS_KEY"),
("CPX Research","استطلاعات","$5","https://www.cpx-research.com","CPX_KEY"),
("TheoremReach","استطلاعات","$5","https://theoremreach.com","THEOREMREACH_KEY"),
("Pollfish","استطلاعات","$5","https://www.pollfish.com","POLLFISH_KEY"),
("Ayet Studios","استطلاعات","$5","https://ayetstudios.com","AYET_KEY"),
("Notik","استطلاعات","$5","https://notik.me","NOTIK_KEY"),
("Monlix","استطلاعات","$5","https://monlix.com","MONLIX_KEY"),
("Prodege","استطلاعات","$5","https://www.prodege.com","PRODEGE_KEY"),
("Cint","استطلاعات","$5","https://www.cint.com","CINT_KEY"),
("Luc.id","استطلاعات","$5","https://luc.id","LUCID_KEY"),
("Dynata","استطلاعات","$5","https://www.dynata.com","DYNATA_KEY"),
("Toluna","استطلاعات","$5","https://www.toluna.com","TOLUNA_KEY"),
("Linkvertise","روابط","$5","https://linkvertise.com","LINKVERTISE_UID"),
("ShrinkMe","روابط","$5","https://shrinkme.io","SHRINKME_KEY"),
("ShrinkEarn","روابط","$5","https://shrinkearn.com","SHRINKEARN_KEY"),
("GPLinks","روابط","$5","https://gplinks.com","GPLINKS_KEY"),
("Clk.sh","روابط","$5","https://clk.sh","CLKSH_KEY"),
("DropLink","روابط","$5","https://droplink.co","DROPLINK_KEY"),
("Cuty.io","روابط","$5","https://cuty.io","CUTY_KEY"),
("Exe.io","روابط","$5","https://exe.io","EXEIO_KEY"),
("Earn4Link","روابط","$5","https://earn4link.com","EARN4LINK_KEY"),
("Bitsfly","روابط","$5","https://bitsfly.co","BITSFLY_KEY"),
("OuO.io","روابط","$5","https://ouo.io","OUO_KEY"),
("Shorte.st","روابط","$5","https://shorte.st","SHORTEST_KEY"),
("Adf.ly","روابط","$5","https://adf.ly","ADFLY_KEY"),
("Work.ink","روابط","$5","https://work.ink","WORKINK_KEY"),
("Loot-Link","روابط","$5","https://loot-link.com","LOOTLINK_KEY"),
("Lootlabs","روابط","$5","https://lootlabs.gg","LOOTLABS_KEY"),
("Rekonise","روابط","$5","https://rekonise.com","REKONISE_KEY"),
("Boost.ink","روابط","$5","https://boost.ink","BOOSTINK_KEY"),
("Flyad","روابط","$5","https://flyad.link","FLYAD_KEY"),
("Shortzzy","روابط","$5","https://shortzzy.in","SHORTZZY_KEY"),
("Clicksfly","روابط","$5","https://clicksfly.com","CLICKSFLY_KEY"),
("Za.gl","روابط","$5","https://za.gl","ZAGL_KEY"),
("Cointiply","كربتو","$3","https://cointiply.com","COINTIPLY_KEY"),
("FaucetPay","كربتو","$1","https://faucetpay.io","FAUCETPAY_KEY"),
("Firefaucet","كربتو","$1","https://firefaucet.win","FIREFAUCET_KEY"),
("Binance","مسار الدفع","-","https://www.binance.com","BINANCE_KEY"),
("Trust Wallet","مسار الدفع","-","https://trustwallet.com","TRUST_KEY"),
("Al-Kuraimi Bank","مسار الدفع","-","https://www.alkuraimi.com","KURAIMI_KEY"),
]

def dom(u):
    m=re.match(r"https?://([^/]+)", u or "")
    return m.group(1).lower().replace("www.","") if m else ""

def main():
    seen=set(); items=[]
    for n,c,m,u,v in SEED:
        d=dom(u)
        if d in seen: continue
        seen.add(d)
        items.append({"name":n,"cat":c,"min":m,"url":u,"key_var":v,"pay":"USDT / Wire / محلي"})
    money=len(items)
    # توسيع من الكتالوج الحقيقي
    bag=[]
    for f in ("platforms.json","entities.json","catalog.json","films.json","library.json"):
        p=os.path.join(ROOT,f)
        if not os.path.exists(p): continue
        try: d=json.load(open(p,encoding="utf-8"))
        except Exception: continue
        if isinstance(d,list): bag+=d
        elif isinstance(d,dict):
            for k in ("items","list","entities","networks","films","results","data"):
                if isinstance(d.get(k),list): bag+=d[k]
    for x in bag:
        if len(items)>=TARGET: break
        if not isinstance(x,dict): continue
        u=x.get("url") or x.get("website") or x.get("homepage") or x.get("link") or ""
        if not u.startswith("http"): continue
        d=dom(u)
        if not d or d in seen: continue
        seen.add(d)
        items.append({"name":x.get("name") or x.get("title") or d,"cat":"قناة/شريك",
                      "min":"-","url":u,"key_var":"","pay":"-"})
    out={"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
         "count":len(items),"money_count":money,"channels_count":len(items)-money,"items":items}
    json.dump(out,open(os.path.join(ROOT,"platforms_active.json"),"w"),ensure_ascii=False,indent=1)
    json.dump([{ "name":i["name"],"cat":i["cat"],"min":i["min"],"url":i["url"],"var":i["key_var"]}
               for i in items if i["key_var"]],
              open(os.path.join(ROOT,"signup.json"),"w"),ensure_ascii=False,indent=1)
    print("منصات:",len(items),"| قنوات دخل:",money,"| جهات:",len(items)-money)

main()
