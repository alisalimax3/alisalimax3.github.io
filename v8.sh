#!/data/data/com.termux/files/usr/bin/bash
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p tools data logs .github/workflows backups
tar czf "backups/pre_v8_$(date +%s).tgz" tools keys.env 2>/dev/null; echo "✓ نسخة احتياطية"

# ═══════════════ tools/registry.py — 250+ شبكة ═══════════════
cat > tools/registry.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""سجل ضخم — 250+ شبكة ومنصة دفع حقيقية
الصيغة: id|الاسم|التصنيف|رابط التسجيل|مفتاح البيئة|أدنى سحب|نوع التحقق
"""
RAW = """
# ── إعلانات ──
adsense|Google AdSense|ads|https://www.google.com/adsense/start/|ADSENSE_KEY|100|manual
gam|Google Ad Manager|ads|https://admanager.google.com/|GAM_KEY|100|manual
admob|Google AdMob|ads|https://apps.admob.com/|ADMOB_KEY|100|manual
meta_an|Meta Audience Network|ads|https://www.facebook.com/audiencenetwork/|META_AN_KEY|100|manual
msads|Microsoft Monetize|ads|https://about.ads.microsoft.com/|MSADS_KEY|50|manual
aps|Amazon Publisher Services|ads|https://aps.amazon.com/|APS_KEY|100|manual
adsterra|Adsterra|ads|https://publishers.adsterra.com/signup|ADSTERRA_API_KEY|5|email
monetag|Monetag|ads|https://publishers.monetag.com/|MONETAG_KEY|5|email
propellerads|PropellerAds|ads|https://publishers.propellerads.com/|PROPELLER_KEY|5|email
popads|PopAds|ads|https://www.popads.net/users/register|POPADS_KEY|5|email
popcash|PopCash|ads|https://popcash.net/register|POPCASH_KEY|5|email
admaven|AdMaven|ads|https://ad-maven.com/publishers/|ADMAVEN_KEY|5|email
hilltopads|HilltopAds|ads|https://hilltopads.com/publishers|HILLTOP_KEY|5|email
evadav|Evadav|ads|https://evadav.com/|EVADAV_KEY|5|email
clickadu|Clickadu|ads|https://pub.clickadu.com/signup|CLICKADU_KEY|5|email
adcash|AdCash|ads|https://www.adcash.com/en/publishers/|ADCASH_KEY|25|email
galaksion|Galaksion|ads|https://galaksion.com/|GALAKSION_KEY|5|email
mybid|MyBid|ads|https://mybid.io/|MYBID_KEY|5|email
richads|RichAds|ads|https://richads.com/publishers|RICHADS_KEY|5|email
kadam|Kadam|ads|https://kadam.net/|KADAM_KEY|10|email
exoclick|ExoClick|ads|https://admin.exoclick.com/signup|EXOCLICK_KEY|20|email
juicyads|JuicyAds|ads|https://www.juicyads.com/register|JUICYADS_KEY|50|email
trafficjunky|TrafficJunky|ads|https://www.trafficjunky.com/|TRAFFICJUNKY_KEY|20|email
trafficstars|TrafficStars|ads|https://trafficstars.com/|TRAFFICSTARS_KEY|25|email
plugrush|PlugRush|ads|https://www.plugrush.com/|PLUGRUSH_KEY|5|email
bidvertiser|Bidvertiser|ads|https://www.bidvertiser.com/publishers/|BIDVERTISER_KEY|10|email
infolinks|Infolinks|ads|https://www.infolinks.com/|INFOLINKS_KEY|50|email
mgid|MGID|ads|https://www.mgid.com/publishers|MGID_KEY|10|email
taboola|Taboola|ads|https://www.taboola.com/publishers|TABOOLA_KEY|100|manual
outbrain|Outbrain|ads|https://www.outbrain.com/publishers/|OUTBRAIN_KEY|100|manual
revcontent|RevContent|ads|https://www.revcontent.com/|REVCONTENT_KEY|50|manual
ezoic|Ezoic|ads|https://www.ezoic.com/signup/|EZOIC_KEY|20|email
nitropay|NitroPay|ads|https://www.nitropay.com/|NITROPAY_KEY|20|email
setupad|Setupad|ads|https://setupad.com/|SETUPAD_KEY|50|manual
playwire|Playwire|ads|https://www.playwire.com/|PLAYWIRE_KEY|50|manual
mediavine|Mediavine|ads|https://www.mediavine.com/|MEDIAVINE_KEY|100|manual
snigel|Snigel|ads|https://www.snigel.com/|SNIGEL_KEY|50|manual
publift|Publift|ads|https://www.publift.com/|PUBLIFT_KEY|50|manual
aads|A-ADS|ads|https://a-ads.com/|AADS_KEY|1|email
coinzilla|Coinzilla|ads|https://coinzilla.com/publishers|COINZILLA_KEY|20|email
bitmedia|Bitmedia|ads|https://bitmedia.io/|BITMEDIA_KEY|20|email
cointraffic|Cointraffic|ads|https://cointraffic.io/|COINTRAFFIC_KEY|20|email
teads|Teads|ads|https://www.teads.com/|TEADS_KEY|100|manual
primis|Primis|ads|https://www.primis.tech/|PRIMIS_KEY|50|manual
connatix|Connatix|ads|https://www.connatix.com/|CONNATIX_KEY|50|manual
aniview|Aniview|ads|https://www.aniview.com/|ANIVIEW_KEY|50|manual
smaato|Smaato|ads|https://www.smaato.com/|SMAATO_KEY|50|manual
mobfox|Mobfox|ads|https://www.mobfox.com/|MOBFOX_KEY|50|manual
inmobi|InMobi|ads|https://www.inmobi.com/|INMOBI_KEY|50|manual
unityads|Unity Ads|ads|https://unity.com/products/unity-ads|UNITYADS_KEY|100|manual
applovin|AppLovin|ads|https://www.applovin.com/|APPLOVIN_KEY|100|manual
chartboost|Chartboost|ads|https://www.chartboost.com/|CHARTBOOST_KEY|100|manual
mintegral|Mintegral|ads|https://www.mintegral.com/|MINTEGRAL_KEY|100|manual
ironsource|ironSource|ads|https://www.is.com/|IRONSOURCE_KEY|100|manual
digitalturbine|Digital Turbine|ads|https://www.digitalturbine.com/|DIGITALTURBINE_KEY|100|manual
ogury|Ogury|ads|https://www.ogury.com/|OGURY_KEY|100|manual
adthrive|AdThrive|ads|https://www.adthrive.com/|ADTHRIVE_KEY|5|manual
raptive|Raptive|ads|https://raptive.com/|RAPTIVE_KEY|5|manual
monumetric|Monumetric|ads|https://www.monumetric.com/|MONUMETRIC_KEY|5|manual
freestar|Freestar|ads|https://freestar.com/|FREESTAR_KEY|5|manual
adpushup|AdPushup|ads|https://www.adpushup.com/|ADPUSHUP_KEY|5|manual
adapex|Adapex|ads|https://adapex.io/|ADAPEX_KEY|5|manual
sulvo|Sulvo|ads|https://sulvo.com/|SULVO_KEY|5|manual
vidoomy|Vidoomy|ads|https://www.vidoomy.com/|VIDOOMY_KEY|5|manual
adplayerpro|AdPlayer.Pro|ads|https://adplayer.pro/|ADPLAYER_PRO_KEY|5|manual
videobyte|VideoByte|ads|https://videobyte.com/|VIDEOBYTE_KEY|5|manual
exponential|Exponential|ads|https://www.exponential.com/|EXPONENTIAL_KEY|5|manual
plista|Plista|ads|https://www.plista.com/|PLISTA_KEY|5|manual
dianomi|Dianomi|ads|https://www.dianomi.com/|DIANOMI_KEY|5|manual
zemanta|Zemanta|ads|https://www.zemanta.com/|ZEMANTA_KEY|5|manual
adyoulike|Adyoulike|ads|https://www.adyoulike.com/|ADYOULIKE_KEY|5|manual
sirdata|Sirdata|ads|https://www.sirdata.com/|SIRDATA_KEY|5|manual
# ── CPA ──
cpagrip|CPAGrip|cpa|https://www.cpagrip.com/|CPAGRIP_KEY|50|email
cpalead|CPALead|cpa|https://www.cpalead.com/|CPALEAD_KEY|50|email
ogads|OGAds|cpa|https://www.ogads.com/|OGADS_KEY|20|email
adgate|AdGate Media|cpa|https://www.adgatemedia.com/|ADGATE_KEY|10|email
adworkmedia|AdWork Media|cpa|https://www.adworkmedia.com/|ADWORKMEDIA_KEY|25|email
maxbounty|MaxBounty|cpa|https://www.maxbounty.com/|MAXBOUNTY_KEY|50|manual
lootably|Lootably|cpa|https://lootably.com/|LOOTABLY_KEY|5|email
timewall|Timewall|cpa|https://timewall.io/|TIMEWALL_KEY|5|email
offertoro|OfferToro|cpa|https://www.offertoro.com/|OFFERTORO_KEY|5|email
adscend|Adscend Media|cpa|https://www.adscendmedia.com/|ADSCEND_KEY|10|email
wannads|Wannads|cpa|https://www.wannads.com/|WANNADS_KEY|5|email
adgem|AdGem|cpa|https://www.adgem.com/|ADGEM_KEY|5|email
personaly|Persona.ly|cpa|https://persona.ly/|PERSONALY_KEY|50|manual
mobidea|Mobidea|cpa|https://www.mobidea.com/|MOBIDEA_KEY|50|manual
drcash|Dr.Cash|cpa|https://dr.cash/|DRCASH_KEY|50|email
advidi|Advidi|cpa|https://advidi.com/|ADVIDI_KEY|100|manual
gotzha|Gotzha|cpa|https://gotzha.com/|GOTZHA_KEY|50|email
affise|Affise|cpa|https://affise.com/|AFFISE_KEY|100|manual
everflow|Everflow|cpa|https://www.everflow.io/|EVERFLOW_KEY|100|manual
tune|TUNE|cpa|https://www.tune.com/|TUNE_KEY|100|manual
m4trix|M4trix|cpa|https://m4trix.me/|M4TRIX_KEY|5|email
algoaffiliates|AlgoAffiliates|cpa|https://algo-affiliates.com/|ALGOAFFILIATES_KEY|5|email
adcell|Adcell|cpa|https://www.adcell.com/|ADCELL_KEY|5|email
tradetracker|Tradetracker|cpa|https://www.tradetracker.com/|TRADETRACKER_KEY|5|email
zanox|Zanox|cpa|https://www.zanox.com/|ZANOX_KEY|5|email
publicidees|Public-Idées|cpa|https://www.public-idees.com/|PUBLIC_ID_ES_KEY|5|email
cake|Cake|cpa|https://getcake.com/|CAKE_KEY|5|manual
postaffiliatepro|Post Affiliate Pro|cpa|https://www.postaffiliatepro.com/|POST_AFFILIATE_PRO_KEY|5|email
hasoffers|HasOffers|cpa|https://www.hasoffers.com/|HASOFFERS_KEY|5|manual
tapfiliate|Tapfiliate|cpa|https://tapfiliate.com/|TAPFILIATE_KEY|5|email
firstpromoter|FirstPromoter|cpa|https://firstpromoter.com/|FIRSTPROMOTER_KEY|5|email
rewardful|Rewardful|cpa|https://www.rewardful.com/|REWARDFUL_KEY|5|email
refersion|Refersion|cpa|https://www.refersion.com/|REFERSION_KEY|5|email
buygoods|BuyGoods|cpa|https://www.buygoods.com/|BUYGOODS_KEY|5|email
smashloud|Smash Loud|cpa|https://smashloud.com/|SMASH_LOUD_KEY|5|email
maxweb|MaxWeb|cpa|https://maxweb.com/|MAXWEB_KEY|5|email
# ── عمولات ──
clickbank|ClickBank|affiliate|https://accounts.clickbank.com/signup|CLICKBANK_KEY|10|manual
digistore24|Digistore24|affiliate|https://www.digistore24.com/en/|DIGISTORE_KEY|10|manual
impact|Impact|affiliate|https://impact.com/signup/|IMPACT_KEY|10|manual
cj|CJ Affiliate|affiliate|https://signup.cj.com/|CJ_KEY|50|manual
awin|Awin|affiliate|https://www.awin.com/gb/join|AWIN_KEY|20|manual
rakuten|Rakuten Advertising|affiliate|https://rakutenadvertising.com/|RAKUTEN_KEY|50|manual
shareasale|ShareASale|affiliate|https://account.shareasale.com/shareasale.cfm?action=signup|SHAREASALE_KEY|50|manual
admitad|Admitad|affiliate|https://www.admitad.com/|ADMITAD_KEY|10|manual
flexoffers|FlexOffers|affiliate|https://www.flexoffers.com/|FLEXOFFERS_KEY|50|manual
skimlinks|Skimlinks|affiliate|https://skimlinks.com/|SKIMLINKS_KEY|10|manual
sovrn|Sovrn|affiliate|https://www.sovrn.com/|SOVRN_KEY|25|manual
partnerstack|PartnerStack|affiliate|https://partnerstack.com/|PARTNERSTACK_KEY|50|manual
tradedoubler|Tradedoubler|affiliate|https://www.tradedoubler.com/|TRADEDOUBLER_KEY|50|manual
webgains|Webgains|affiliate|https://www.webgains.com/|WEBGAINS_KEY|50|manual
belboon|Belboon|affiliate|https://www.belboon.com/|BELBOON_KEY|50|manual
daisycon|Daisycon|affiliate|https://www.daisycon.com/|DAISYCON_KEY|50|manual
kwanko|Kwanko|affiliate|https://www.kwanko.com/|KWANKO_KEY|50|manual
effiliation|Effiliation|affiliate|https://www.effiliation.com/|EFFILIATION_KEY|50|manual
amazon|Amazon Associates|affiliate|https://affiliate-program.amazon.com/|AMAZON_ASSOC|10|manual
aliexpress|AliExpress Portals|affiliate|https://portals.aliexpress.com/|ALIEXPRESS_KEY|5|manual
# ── استطلاعات ──
bitlabs|BitLabs|surveys|https://bitlabs.ai/|BITLABS_KEY|5|email
cpx|CPX Research|surveys|https://www.cpx-research.com/|CPX_KEY|5|email
theoremreach|TheoremReach|surveys|https://theoremreach.com/|THEOREMREACH_KEY|5|email
pollfish|Pollfish|surveys|https://www.pollfish.com/|POLLFISH_KEY|5|email
ayet|Ayet Studios|surveys|https://ayetstudios.com/|AYET_KEY|5|email
notik|Notik|surveys|https://notik.me/|NOTIK_KEY|5|email
monlix|Monlix|surveys|https://monlix.com/|MONLIX_KEY|5|email
prodege|Prodege|surveys|https://www.prodege.com/|PRODEGE_KEY|5|manual
cint|Cint|surveys|https://www.cint.com/|CINT_KEY|5|manual
lucid|Luc.id|surveys|https://luc.id/|LUCID_KEY|5|manual
dynata|Dynata|surveys|https://www.dynata.com/|DYNATA_KEY|5|manual
toluna|Toluna|surveys|https://www.toluna.com/|TOLUNA_KEY|5|email
adikteev|Adikteev|surveys|https://adikteev.com/|ADIKTEEV_KEY|5|manual
surveysampling|Survey Sampling|surveys|https://www.surveysampling.com/|SURVEY_SAMPLING_KEY|5|manual
attapoll|Attapoll|surveys|https://attapoll.app/|ATTAPOLL_KEY|5|email
streetbees|Streetbees|surveys|https://www.streetbees.com/|STREETBEES_KEY|5|email
pollpay|Poll Pay|surveys|https://pollpay.app/|POLL_PAY_KEY|5|email
tremendous|Tremendous|surveys|https://www.tremendous.com/|TREMENDOUS_KEY|5|email
# ── روابط ──
linkvertise|Linkvertise|shortlinks|https://publisher.linkvertise.com/|LINKVERTISE_UID|5|email
shrinkme|ShrinkMe|shortlinks|https://shrinkme.io/|SHRINKME_KEY|5|email
shrinkearn|ShrinkEarn|shortlinks|https://shrinkearn.com/|SHRINKEARN_KEY|5|email
gplinks|GPLinks|shortlinks|https://gplinks.com/|GPLINKS_KEY|5|email
clksh|Clk.sh|shortlinks|https://clk.sh/|CLKSH_KEY|5|email
droplink|DropLink|shortlinks|https://droplink.co/|DROPLINK_KEY|5|email
cuty|Cuty.io|shortlinks|https://cuty.io/|CUTY_KEY|5|email
exeio|Exe.io|shortlinks|https://exe.io/|EXEIO_KEY|5|email
earn4link|Earn4Link|shortlinks|https://earn4link.com/|EARN4LINK_KEY|5|email
bitsfly|Bitsfly|shortlinks|https://bitsfly.co/|BITSFLY_KEY|5|email
ouo|OuO.io|shortlinks|https://ouo.io/|OUO_KEY|5|email
shortest|Shorte.st|shortlinks|https://shorte.st/|SHORTEST_KEY|5|email
adfly|Adf.ly|shortlinks|https://adf.ly/|ADFLY_KEY|5|email
workink|Work.ink|shortlinks|https://work.ink/|WORKINK_KEY|5|email
lootlink|Loot-Link|shortlinks|https://loot-link.com/|LOOTLINK_KEY|5|email
lootlabs|Lootlabs|shortlinks|https://lootlabs.gg/|LOOTLABS_KEY|5|email
rekonise|Rekonise|shortlinks|https://rekonise.com/|REKONISE_KEY|5|email
boostink|Boost.ink|shortlinks|https://boost.ink/|BOOSTINK_KEY|5|email
flyad|Flyad|shortlinks|https://flyad.io/|FLYAD_KEY|5|email
shortzzy|Shortzzy|shortlinks|https://shortzzy.in/|SHORTZZY_KEY|5|email
clicksfly|Clicksfly|shortlinks|https://clicksfly.com/|CLICKSFLY_KEY|5|email
zagl|Za.gl|shortlinks|https://za.gl/|ZAGL_KEY|5|email
linkshortify|Linkshortify|shortlinks|https://linkshortify.com/|LINKSHORTIFY_KEY|5|email
mdisk|Mdisk Shortner|shortlinks|https://mdiskshortner.com/|MDISK_SHORTNER_KEY|5|email
tnlink|TnLink|shortlinks|https://tnlink.in/|TNLINK_KEY|5|email
try2link|Try2Link|shortlinks|https://try2link.com/|TRY2LINK_KEY|5|email
short2url|Short2URL|shortlinks|https://short2url.in/|SHORT2URL_KEY|5|email
sub2unlock|Sub2Unlock|shortlinks|https://sub2unlock.com/|SUB2UNLOCK_KEY|5|email
fclc|FC.lc|shortlinks|https://fc.lc/|FC_LC_KEY|5|email
payoutsclick|Payouts.click|shortlinks|https://payouts.click/|PAYOUTS_CLICK_KEY|5|email
# ── كربتو ──
cointiply|Cointiply|crypto|https://cointiply.com/|COINTIPLY_KEY|3|email
faucetpay|FaucetPay|crypto|https://faucetpay.io/|FAUCETPAY_KEY|1|email
firefaucet|Firefaucet|crypto|https://firefaucet.win/|FIREFAUCET_KEY|1|email
# ── دفع ──
binance|Binance|pay|https://www.binance.com/|BINANCE_KEY|0|manual
trust|Trust Wallet|pay|https://trustwallet.com/|TRUST_KEY|0|manual
kuraimi|Al-Kuraimi Bank|pay|https://www.al-kuraimi.com/|KURAIMI_KEY|0|manual
binancep2p|Binance P2P|pay|https://p2p.binance.com/|BINANCE_P2P_KEY|0|manual
bybit|Bybit|pay|https://www.bybit.com/|BYBIT_KEY|0|manual
okx|OKX|pay|https://www.okx.com/|OKX_KEY|0|manual
mexc|MEXC|pay|https://www.mexc.com/|MEXC_KEY|0|manual
bitget|Bitget|pay|https://www.bitget.com/|BITGET_KEY|0|manual
whitebit|WhiteBIT|pay|https://whitebit.com/|WHITEBIT_KEY|0|manual
gateio|Gate.io|pay|https://www.gate.io/|GATE_IO_KEY|0|manual
kraken|Kraken|pay|https://www.kraken.com/|KRAKEN_KEY|0|manual
coinbase|Coinbase|pay|https://www.coinbase.com/|COINBASE_KEY|0|manual
nowpayments|NOWPayments|pay|https://nowpayments.io/|NOWPAYMENTS_KEY|0|manual
paxum|Paxum|pay|https://www.paxum.com/|PAXUM_KEY|0|manual
payeer|Payeer|pay|https://payeer.com/|PAYEER_KEY|0|manual
advcash|AdvCash|pay|https://advcash.com/|ADVCASH_KEY|0|manual
skrill|Skrill|pay|https://www.skrill.com/|SKRILL_KEY|0|manual
metamask|MetaMask|pay|https://metamask.io/|METAMASK_KEY|0|manual
tether|Tether TRC20|pay|https://tether.to/|TETHER_TRC20_KEY|0|manual
airtm|AirTM|pay|https://www.airtm.com/|AIRTM_KEY|0|manual
wise|Wise|pay|https://wise.com/|WISE_KEY|0|manual
westernunion|Western Union|pay|https://www.westernunion.com/|WESTERN_UNION_KEY|0|manual
# ── كبار ──
eroadvertising|EroAdvertising|adult|https://www.eroadvertising.com/|EROADS_KEY|25|email
bitterstrawberry|BitterStrawberry|adult|https://www.bitterstrawberry.com/|BITTER_KEY|50|email
adspyglass|AdSpyglass|adult|https://www.adspyglass.com/|ADSPYGLASS_KEY|25|email
adnium|Adnium|adult|https://adnium.com/|ADNIUM_KEY|100|manual
trafficfactory|TrafficFactory|adult|https://www.trafficfactory.com/|TRAFFICFACTORY_KEY|100|manual
pinkads|PinkAds|adult|https://pinkads.com/|PINKADS_KEY|50|email
traforama|Traforama|adult|https://traforama.com/|TRAFORAMA_KEY|50|email
clickaine|Clickaine|adult|https://clickaine.com/|CLICKAINE_KEY|20|email
adamo|Adamo|adult|https://adamo.com/|ADAMO_KEY|50|email
lospollos|LosPollos|adult|https://lospollos.com/|LOSPOLLOS_KEY|50|email
crakrevenue|CrakRevenue|adult|https://www.crakrevenue.com/|CRAKREVENUE_KEY|50|email
adcombo|AdCombo|adult|https://adcombo.com/|ADCOMBO_KEY|50|email
terraleads|TerraLeads|adult|https://terraleads.com/|TERRALEADS_KEY|50|email
zeydoo|Zeydoo|adult|https://zeydoo.com/|ZEYDOO_KEY|50|email
leadbit|Leadbit|adult|https://leadbit.com/|LEADBIT_KEY|50|email
kmabiz|Kma.biz|adult|https://kma.biz/|KMA_KEY|50|email
datify|Datify|adult|https://datify.link/|DATIFY_KEY|50|email
clickdealer|ClickDealer|adult|https://www.clickdealer.com/|CLICKDEALER_KEY|50|manual
chaturbate|Chaturbate|adult|https://chaturbate.com/affiliates/|CHATURBATE_KEY|20|manual
stripchat|Stripchat|adult|https://affiliates.stripchat.com/|STRIPCHAT_KEY|50|manual
bongacams|BongaCams|adult|https://affiliates.bongacams.com/|BONGACAMS_KEY|50|manual
livejasmin|LiveJasmin|adult|https://www.livejasmin.com/en/affiliate|LIVEJASMIN_KEY|50|manual
cam4|Cam4|adult|https://www.cam4.com/affiliates|CAM4_KEY|50|manual
mfc|MyFreeCams|adult|https://www.myfreecams.com/affiliates|MFC_KEY|50|manual
flirt4free|Flirt4Free|adult|https://www.flirt4free.com/affiliates|FLIRT4FREE_KEY|50|manual
streamate|Streamate|adult|https://www.streamate.com/affiliates|STREAMATE_KEY|50|manual
imlive|ImLive|adult|https://www.imlive.com/affiliates|IMLIVE_KEY|50|manual
jerkmate|Jerkmate|adult|https://jerkmate.com/affiliates|JERKMATE_KEY|50|manual
skyprivate|SkyPrivate|adult|https://www.skyprivate.com/|SKYPRIVATE_KEY|50|email
xlovecam|XloveCam|adult|https://www.xlovecam.com/affiliate|XLOVECAM_KEY|50|manual
camsoda|Camsoda|adult|https://www.camsoda.com/affiliates|CAMSODA_KEY|50|manual
adultforce|AdultForce|adult|https://adultforce.com/|ADULTFORCE_KEY|50|manual
fancentro|FanCentro|adult|https://fancentro.com/|FANCENTRO_KEY|50|email
manyvids|ManyVids|adult|https://www.manyvids.com/|MANYVIDS_KEY|50|email
clips4sale|Clips4Sale|adult|https://www.clips4sale.com/|CLIPS4SALE_KEY|50|email
iwantclips|IWantClips|adult|https://iwantclips.com/|IWANTCLIPS_KEY|50|email
sexier|Sexier|adult|https://www.sexier.com/|SEXIER_KEY|50|manual
adultmoda|AdultModa|adult|https://adultmoda.com/|ADULTMODA_KEY|50|email
porndough|PornDough|adult|https://porndough.com/|PORNDOUGH_KEY|50|email
traffichaus|TrafficHaus|adult|https://traffichaus.com/|TRAFFICHAUS_KEY|100|email
awempire|AdultWebmasterEmpire|adult|https://www.awempire.com/|AWEMPIRE_KEY|100|email
gamma|GammaEntertainment|adult|https://www.gammae.com/|GAMMA_KEY|50|email
wecamy|WebcamAffiliates|adult|https://wecamy.com/|WECAMY_KEY|50|email
adultcams|AdultCams|adult|https://adultcams.com/|ADULTCAMS_KEY|50|email
bongacash|Bongacash|adult|https://www.bongacash.com/|BONGACASH_KEY|50|email
adultadworld|AdultAdWorld|adult|https://adultadworld.com/|ADULTADWORLD_KEY|5|email
exogroup|ExoGroup|adult|https://exogroup.com/|EXOGROUP_KEY|5|manual
trafficshop|TrafficShop|adult|https://trafficshop.com/|TRAFFICSHOP_KEY|5|email
recreativ|Recreativ|adult|https://recreativ.ru/|RECREATIV_KEY|5|email
# ── محتوى ──
internetarchive|Internet Archive|content|https://archive.org/|INTERNET_ARCHIVE_KEY|0|email
wikimedia|Wikimedia Commons|content|https://commons.wikimedia.org/|WIKIMEDIA_COMMONS_KEY|0|email
gutenberg|Project Gutenberg|content|https://www.gutenberg.org/|PROJECT_GUTENBERG_KEY|0|email
dailymotion|Dailymotion|content|https://www.dailymotion.com/|DAILYMOTION_KEY|0|email
peertube|PeerTube|content|https://joinpeertube.org/|PEERTUBE_KEY|0|email
lbry|LBRY|content|https://lbry.com/|LBRY_KEY|0|email
odysee|Odysee|content|https://odysee.com/|ODYSEE_KEY|0|email
vimeo|Vimeo|content|https://vimeo.com/|VIMEO_KEY|0|email
eporner|Eporner|content|https://www.eporner.com/|EPORNER_KEY|0|email
redtube|RedTube|content|https://www.redtube.com/|REDTUBE_KEY|0|email
pornhub|Pornhub|content|https://www.pornhub.com/|PORNHUB_KEY|0|email
xhamster|xHamster|content|https://xhamster.com/|XHAMSTER_KEY|0|email
xvideos|XVideos|content|https://www.xvideos.com/|XVIDEOS_KEY|0|email
xnxx|XNXX|content|https://www.xnxx.com/|XNXX_KEY|0|email
spankbang|SpankBang|content|https://spankbang.com/|SPANKBANG_KEY|0|email
tnaflix|TNAFlix|content|https://www.tnaflix.com/|TNAFLIX_KEY|0|email
hqporner|HQPorner|content|https://hqporner.com/|HQPORNER_KEY|0|email
porntrex|PornTrex|content|https://www.porntrex.com/|PORNTREX_KEY|0|email
adultempire|AdultEmpire|content|https://www.adultempire.com/|ADULTEMPIRE_KEY|0|email
"""

Z = r"\b(\d{4,9})\b"
AFF = r"(https?://[^\s\"'<>]*(?:ref|aff|partner|a_aid|track|utm|share)[^\s\"'<>]*)"
DIGIT_CATS = {"ads","crypto"}
URL_CATS = {"shortlinks","affiliate"}

def _mk(line):
    p = [x.strip() for x in line.split("|")]
    if len(p) < 6: return None
    i,n,c,u,k,m = p[:6]
    v = p[6] if len(p) > 6 else "email"
    try: mn = float(m)
    except Exception: mn = 0
    rx = Z if c in DIGIT_CATS else (AFF if c in URL_CATS else "")
    return dict(id=i, name=n, cat=c, signup=u, login=u, payout_page=u, payout_min=mn,
                methods=["PayPal","USDT","Wire","Paxum","Payoneer"], key_env=k, key_hint=k,
                key_regex=rx, verify=v, captcha=(c=="ads"), note="")

ALL = []
for _l in RAW.strip().splitlines():
    _l = _l.strip()
    if not _l or _l.startswith("#"): continue
    _e = _mk(_l)
    if _e: ALL.append(_e)

CATS = {"ads":"إعلانات","cpa":"CPA","affiliate":"عمولات","surveys":"استطلاعات",
        "shortlinks":"روابط مختصرة","crypto":"كريبتو","pay":"دفع","adult":"للكبار","content":"محتوى"}

BY_ID = {n["id"]: n for n in ALL}

ALTS = {
 "adsterra":["https://publishers.adsterra.com/","https://adsterra.com/publishers/"],
 "monetag":["https://monetag.com/publishers/"],
 "picoworkers":["https://picoworkers.com/register.php"],
 "freecash":["https://freecash.com/r/register"],
 "shrinkme":["https://shrinkme.io/register"],
 "gplinks":["https://gplinks.in/"],
 "clksh":["https://clk.sh/register"],
 "cuty":["https://cuty.io/register"],
 "ouo":["https://ouo.io/register"],
 "faucetpay":["https://faucetpay.io/register"],
 "cointiply":["https://cointiply.com/register"],
}

def by_id(i):
    if i not in BY_ID: raise KeyError("مصدر غير معروف: %s" % i)
    return BY_ID[i]

def by_cat(c): return [n for n in ALL if n["cat"] == c]

def candidates(net):
    seen, out = set(), []
    for u in [net["signup"]] + ALTS.get(net["id"], []):
        if u and u not in seen: seen.add(u); out.append(u)
    return out

def pending():
    import core
    return [n for n in ALL if n["key_env"] and not core.env(n["key_env"])]

def with_key():
    import core
    return [n for n in ALL if n["key_env"] and core.env(n["key_env"])]

def stats():
    return {"total": len(ALL), "with_key": len(with_key()), "pending": len(pending())}
PYEOF

# ═══════════════ tools/repo.py ═══════════════
cat > tools/repo.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مزامنة المستودع — حفظ فوري + دفع تلقائي"""
import os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def git(*a, timeout=90):
    try:
        r = subprocess.run(["git"]+list(a), cwd=str(core.BASE), capture_output=True,
                           text=True, timeout=timeout)
        return r.returncode, ((r.stdout or "")+(r.stderr or "")).strip()
    except Exception as e:
        return 1, str(e)

def ready():
    return (core.BASE/".git").exists()

def remote():
    rc, out = git("remote","get-url","origin")
    return out if rc == 0 else ""

def ensure():
    if not ready():
        git("init","-q")
        git("config","user.email", core.env("MAIL_USER") or "agent@local")
        git("config","user.name", core.env("GITHUB_USER") or "agent")
        git("add","-A"); git("commit","-q","-m","init")
        core.log("مستودع git مُنشأ", "ok")
    if not remote():
        u = core.env("REPO_URL")
        if u: git("remote","add","origin",u); core.log("origin مضبوط", "ok")
    return True

def status():
    if not ready(): return "لا مستودع"
    rc, out = git("status","--porcelain")
    n = len([l for l in out.splitlines() if l.strip()])
    return "origin=%s | تغييرات=%d" % (remote() or "غير مضبوط", n)

def push(msg=None):
    ensure()
    git("add","-A")
    rc, out = git("commit","-q","-m", msg or ("sync " + time.strftime("%Y-%m-%d %H:%M")))
    committed = rc == 0
    if not remote():
        return committed, "محفوظ محلياً — اضبط REPO_URL للدفع"
    rc2, out2 = git("push","origin","HEAD")
    if rc2 == 0: return True, "دُفع إلى المستودع"
    return False, "فشل الدفع: " + out2.splitlines()[-1][:120]

def pull():
    if not ready() or not remote(): return False, "لا مستودع/remote"
    rc, out = git("pull","--rebase","--autostash","origin","HEAD")
    return rc == 0, out.splitlines()[-1][:120] if out else ""

def sync():
    pull()
    core.load_env()
    return True
PYEOF

# ═══════════════ tools/addkey.py ═══════════════
cat > tools/addkey.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""إضافة مفتاح يدوياً: فتح → تسجيل → لصق → حفظ فوري + دفع"""
import re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, repo
from registry import by_id

def _extract(net, raw):
    raw = raw.strip()
    if not raw: return ""
    if net.get("key_regex"):
        m = re.search(net["key_regex"], raw)
        if m: return m.group(1)
    if raw.startswith("http"):
        return raw.split()[0]
    return raw.split()[0]

def add(net_id, value=None, openit=True):
    net = by_id(net_id)
    print("\n%s%s══ %s ══%s" % (core.C['b'], core.C['info'], net["name"], core.C['x']))
    print("  الرابط : %s" % net["signup"])
    print("  المفتاح: %s" % net["key_env"])
    print("  التصنيف: %s | أدنى سحب: $%s | تحقق: %s" % (net["cat"], net["payout_min"], net["verify"]))
    if net["payout_min"] == 0: print("  (منصة دفع/محتوى — لا حد سحب)")
    if openit:
        core.openurl(net["signup"])
        core.log("فُتح في المتصفح", "info")
    if value is None:
        try: value = input("\nالصق المفتاح/الرابط (أو Enter للتخطي): ")
        except EOFError: value = ""
    value = _extract(net, value)
    if not value:
        core.log("تخطي — لم يُحفظ شيء", "warn"); return False
    core.set_env(net["key_env"], value)
    core.log("✓ %s = %s" % (net["key_env"], value), "ok")
    d = core.load("data/registrations.json", {})
    d[net_id] = {"name": net["name"], "status": "key_set", "key": value,
                 "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save("data/registrations.json", d)
    ok, msg = repo.push("key: %s (%s)" % (net_id, net["key_env"]))
    core.log(msg, "ok" if ok else "warn")
    return True

def batch_missing(cat=None):
    from registry import pending, by_cat
    items = by_cat(cat) if cat else pending()
    items = [n for n in items if not core.env(n["key_env"])]
    if not items: core.log("لا شيء ناقص", "ok"); return
    core.log("%d موقع ناقص — Enter للتخطي" % len(items), "info")
    for i, n in enumerate(items, 1):
        print("\n[%d/%d]" % (i, len(items)))
        try: add(n["id"])
        except KeyboardInterrupt: break
PYEOF

# ═══════════════ tools/watch.py ═══════════════
cat > tools/watch.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مزامنة دورية كل 5 دقائق — المحرّك يقرأ المفاتيح تلقائياً"""
import sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, repo, registry, ledger

def cycle():
    repo.sync()
    core.load_env()
    s = registry.stats()
    core.log("مزامنة | مصادر=%d بمفاتيح=%d ناقص=%d | رصيد=$%.2f | %s"
             % (s["total"], s["with_key"], s["pending"], ledger.total(),
                time.strftime("%H:%M:%S")), "info")
    if s["with_key"]: core.log("مفاتيح نشطة: %s" % ", ".join(n["id"] for n in registry.with_key()[:15]), "ok")

def main(mins=5):
    core.log("خادم المزامنة — كل %d دقيقة (Ctrl+C للخروج)" % mins, "info")
    while True:
        try: cycle()
        except KeyboardInterrupt: core.log("توقف", "warn"); return
        except Exception as e: core.log("خطأ: %s" % e, "err")
        try: time.sleep(mins*60)
        except KeyboardInterrupt: core.log("توقف", "warn"); return
PYEOF

# ═══════════════ سير عمل GitHub كل 5 دقائق ═══════════════
cat > .github/workflows/engine.yml << 'YEOF'
name: cinehub-engine
on:
  schedule: [{cron: "*/5 * * * *"}]
  workflow_dispatch:
  push: {paths: ["keys.env","data/**"]}
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.12"}
      - name: تحميل المفاتيح
        run: |
          echo "=== المفاتيح النشطة ==="
          grep -v '^#' keys.env | grep '=' | sed 's/=.*/=<set>/' || true
      - name: تقرير الحالة
        run: |
          python3 - <<'PY'
          import os
          keys=[l.split('=',1)[0] for l in open('keys.env') if '=' in l and not l.startswith('#')]
          print("عدد المفاتيح:", len(keys))
          PY
YEOF

# ═══════════════ ربط الأوامر ═══════════════
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
if 'c == "add"' not in s:
    s = s.replace('    elif c == "audit":',
'''    elif c == "add":
        import addkey
        if a[1:] and a[1] == "--missing": addkey.batch_missing(a[2] if len(a)>2 else None)
        else:
            for i in [x for x in a[1:] if not x.startswith("--")]: addkey.add(i)
    elif c == "open":
        import addkey, registry
        for i in a[1:]: core.openurl(registry.by_id(i)["signup"])
    elif c == "push":
        import repo; core.log(repo.push(" ".join(a[1:]) or None)[1], "ok")
    elif c == "pull":
        import repo; core.log(repo.pull()[1] or "مُحدّث", "ok")
    elif c == "sync":
        import repo; repo.sync(); core.log("تمت المزامنة", "ok")
    elif c == "watch":
        import watch; watch.main(int(a[1]) if len(a)>1 else 5)
    elif c == "keys":
        for n in registry.with_key():
            print("  %-18s %-22s %s" % (n["id"], n["key_env"], (core.env(n["key_env"]) or "")[:44]))
        print("\\nالإجمالي: %d/%d" % (len(registry.with_key()), len(registry.ALL)))
    elif c == "table":
        for cat, name in registry.CATS.items():
            items = registry.by_cat(cat)
            if not items: continue
            print("\\n%s%s (%d)%s" % (core.C['b'], name, len(items), core.C['x']))
            for n in items:
                m = core.C['ok']+"✓"+core.C['x'] if core.env(n["key_env"]) else " "
                print("  %s %-18s %-26s %-24s $%s" % (m, n["id"], n["name"][:26], n["key_env"][:24], n["payout_min"]))
    elif c == "audit":''')
    s = s.replace('  audit                   فحص شامل حقيقي',
'''  add <id> | --missing [cat]  إضافة مفتاح (فتح+لصق+حفظ+دفع)
  open <id...>            فتح رابط التسجيل
  keys                    المفاتيح النشطة
  table [cat]             الجدول الكامل
  push | pull | sync      المستودع
  watch [دقائق]           مزامنة دورية
  audit                   فحص شامل حقيقي''')
    open(p,"w",encoding="utf-8").write(s)
print("✓ agent موصول")
PY

python3 -m py_compile tools/*.py && echo "✓ كل الملفات تُترجم"
python3 -c "
import sys; sys.path.insert(0,'tools')
import registry as r
print('المصادر:', len(r.ALL), '| التصنيفات:', len(r.CATS))
for c,n in r.CATS.items(): print('  %-12s %d' % (n, len(r.by_cat(c))))
"
echo ""
echo "✅ v8 جاهز"
