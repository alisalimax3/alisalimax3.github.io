#!/data/data/com.termux/files/usr/bin/bash
set -u
cd "$HOME/cinehub3099" || exit 1
mkdir -p logs data
LOG="logs/final3_$(date +%H%M%S).log"
say(){ printf '\n\033[1;36m══ %s ══\033[0m\n' "$*" | tee -a "$LOG"; }
ok(){  printf '\033[1;32m✓\033[0m %s\n' "$*" | tee -a "$LOG"; }
bad(){ printf '\033[1;31m✗\033[0m %s\n' "$*" | tee -a "$LOG"; }

say "1 · كتابة data/sources.json (112 مصدراً حقيقياً)"
cat > data/sources.json <<'JSON'
[
{"id":"adsterra","name":"Adsterra","cat":"ads","url":"https://publishers.adsterra.com/signup","alt":["https://adsterra.com/publishers/"],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"ADSTERRA_ZONE"},
{"id":"monetag","name":"Monetag","cat":"ads","url":"https://monetag.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"MONETAG_MULTITAG"},
{"id":"popads","name":"PopAds","cat":"ads","url":"https://www.popads.net/users/register","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":5,"key":"POPADS_SITE"},
{"id":"propellerads","name":"PropellerAds","cat":"ads","url":"https://propellerads.com/publishers/signup","alt":["https://propellerads.com/"],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"PROPELLER_ZONE"},
{"id":"hilltopads","name":"HilltopAds","cat":"ads","url":"https://hilltopads.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":25,"key":"HILLTOPADS_ZONE"},
{"id":"clickadu","name":"Clickadu","cat":"ads","url":"https://clickadu.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"CLICKADU_ZONE"},
{"id":"evadav","name":"Evadav","cat":"ads","url":"https://evadav.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"EVADAV_ZONE"},
{"id":"admaven","name":"AdMaven","cat":"ads","url":"https://admaven.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"ADMAVEN_ZONE"},
{"id":"galaksion","name":"Galaksion","cat":"ads","url":"https://galaksion.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":5,"key":"GALAKSION_ZONE"},
{"id":"adcash","name":"Adcash","cat":"ads","url":"https://adcash.com/publisher","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":25,"key":"ADCASH_ZONE"},
{"id":"mgid","name":"MGID","cat":"ads","url":"https://www.mgid.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":100,"key":"MGID_WIDGET"},
{"id":"taboola","name":"Taboola","cat":"ads","url":"https://www.taboola.com/publishers","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"TABOOLA_ID"},
{"id":"outbrain","name":"Outbrain","cat":"ads","url":"https://www.outbrain.com/publishers","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"OUTBRAIN_ID"},
{"id":"revcontent","name":"RevContent","cat":"ads","url":"https://www.revcontent.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"REVCONTENT_ID"},
{"id":"medianet","name":"Media.net","cat":"ads","url":"https://www.media.net","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"MEDIANET_ID"},
{"id":"bidvertiser","name":"BidVertiser","cat":"ads","url":"https://www.bidvertiser.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":10,"key":"BIDVERTISER_ZONE"},
{"id":"infolinks","name":"Infolinks","cat":"ads","url":"https://www.infolinks.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"INFOLINKS_ID"},
{"id":"ezoic","name":"Ezoic","cat":"ads","url":"https://www.ezoic.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"EZOIC_ID"},
{"id":"setupad","name":"Setupad","cat":"ads","url":"https://setupad.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"SETUPAD_ID"},
{"id":"adpushup","name":"AdPushup","cat":"ads","url":"https://www.adpushup.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"ADPUSHUP_ID"},
{"id":"pubfuture","name":"PubFuture","cat":"ads","url":"https://pubfuture.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":10,"key":"PUBFUTURE_ZONE"},
{"id":"adoperator","name":"AdOperator","cat":"ads","url":"https://adoperator.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":10,"key":"ADOPERATOR_ZONE"},
{"id":"yandexads","name":"Yandex Ads","cat":"ads","url":"https://yandex.com/ads","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"YANDEX_ID"},
{"id":"sovrn","name":"Sovrn","cat":"ads","url":"https://www.sovrn.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":25,"key":"SOVRN_ID"},
{"id":"raptive","name":"Raptive","cat":"ads","url":"https://raptive.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"RAPTIVE_ID"},
{"id":"mediavine","name":"Mediavine","cat":"ads","url":"https://www.mediavine.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"MEDIAVINE_ID"},
{"id":"snigel","name":"Snigel","cat":"ads","url":"https://snigel.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"SNIGEL_ID"},
{"id":"adplugg","name":"AdPlugg","cat":"ads","url":"https://www.adplugg.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"ADPLUGG_ID"},
{"id":"playwire","name":"Playwire","cat":"ads","url":"https://www.playwire.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"PLAYWIRE_ID"},
{"id":"broadstreet","name":"Broadstreet","cat":"ads","url":"https://broadstreetads.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"BROADSTREET_ID"},
{"id":"monumetric","name":"Monumetric","cat":"ads","url":"https://www.monumetric.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"MONUMETRIC_ID"},
{"id":"shemedia","name":"SheMedia","cat":"ads","url":"https://shemedia.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"SHEMEDIA_ID"},
{"id":"cafemedia","name":"CafeMedia","cat":"ads","url":"https://cafemedia.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"CAFEMEDIA_ID"},
{"id":"adthrive","name":"AdThrive","cat":"ads","url":"https://www.adthrive.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"ADTHRIVE_ID"},
{"id":"pushhouse","name":"Push.House","cat":"ads","url":"https://push.house","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":10,"key":"PUSHHOUSE_ZONE"},
{"id":"pushground","name":"PushGround","cat":"ads","url":"https://pushground.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"PUSHGROUND_ZONE"},
{"id":"richpush","name":"RichPush","cat":"ads","url":"https://richpush.co","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"RICHPUSH_ZONE"},
{"id":"notix","name":"Notix","cat":"ads","url":"https://notix.io","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"NOTIX_ID"},
{"id":"izooto","name":"iZooto","cat":"ads","url":"https://www.izooto.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"IZOOTO_ID"},
{"id":"onesignal","name":"OneSignal","cat":"ads","url":"https://onesignal.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"ONESIGNAL_ID"},
{"id":"exoclick","name":"ExoClick","cat":"adult","url":"https://www.exoclick.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":true,"payout":20,"key":"EXOCLICK_ZONE"},
{"id":"juicyads","name":"JuicyAds","cat":"adult","url":"https://www.juicyads.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":25,"key":"JUICYADS_ZONE"},
{"id":"trafficjunky","name":"TrafficJunky","cat":"adult","url":"https://www.trafficjunky.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":20,"key":"TJ_ZONE"},
{"id":"trafficstars","name":"TrafficStars","cat":"adult","url":"https://trafficstars.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"TSTARS_ZONE"},
{"id":"plugrush","name":"PlugRush","cat":"adult","url":"https://www.plugrush.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":10,"key":"PLUGRUSH_ZONE"},
{"id":"eroadvertising","name":"EroAdvertising","cat":"adult","url":"https://www.eroadvertising.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":25,"key":"ERO_ZONE"},
{"id":"bongacash","name":"BongaCash","cat":"adult","url":"https://bongacash.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"BONGA_REF"},
{"id":"crakrevenue","name":"CrakRevenue","cat":"adult","url":"https://www.crakrevenue.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":100,"key":"CRAKREVENUE_REF"},
{"id":"xlovecash","name":"xLoveCash","cat":"adult","url":"https://xlovecash.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"XLOVECASH_REF"},
{"id":"stripchat","name":"Stripchat Aff","cat":"adult","url":"https://stripchat.com/affiliate","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":50,"key":"STRIPCHAT_REF"},
{"id":"tubecorp","name":"TubeCorp","cat":"adult","url":"https://tubecorp.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":true,"payout":50,"key":"TUBECORP_REF"},
{"id":"adultforce","name":"AdultForce","cat":"adult","url":"https://www.adultforce.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"ADULTFORCE_REF"},
{"id":"maxbounty","name":"MaxBounty","cat":"cpa","url":"https://www.maxbounty.com","alt":[],"fields":"email/password/first/last/phone","verify":"phone","captcha":true,"payout":50,"key":"MAXBOUNTY_AFF"},
{"id":"cpagrip","name":"CPAGrip","cat":"cpa","url":"https://www.cpagrip.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":50,"key":"CPAGRIP_AFF"},
{"id":"cpalead","name":"CPALead","cat":"cpa","url":"https://www.cpalead.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":50,"key":"CPALEAD_AFF"},
{"id":"adworkmedia","name":"AdWorkMedia","cat":"cpa","url":"https://www.adworkmedia.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"AWM_AFF"},
{"id":"mobidea","name":"Mobidea","cat":"cpa","url":"https://www.mobidea.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"MOBIDEA_AFF"},
{"id":"mylead","name":"MyLead","cat":"cpa","url":"https://mylead.io","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":20,"key":"MYLEAD_AFF"},
{"id":"cpamatica","name":"CPAmatica","cat":"cpa","url":"https://cpamatica.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"CPAMATICA_AFF"},
{"id":"zeydoo","name":"Zeydoo","cat":"cpa","url":"https://zeydoo.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"ZEYDOO_AFF"},
{"id":"leadbit","name":"Leadbit","cat":"cpa","url":"https://leadbit.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"LEADBIT_AFF"},
{"id":"gotzha","name":"Gotzha","cat":"cpa","url":"https://gotzha.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"GOTZHA_AFF"},
{"id":"adsimilis","name":"Adsimilis","cat":"cpa","url":"https://adsimilis.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"ADSIMILIS_AFF"},
{"id":"offervault","name":"OfferVault","cat":"cpa","url":"https://www.offervault.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"OFFERVAULT_AFF"},
{"id":"terraleads","name":"TerraLeads","cat":"cpa","url":"https://terraleads.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"TERRALEADS_AFF"},
{"id":"advidi","name":"Advidi","cat":"cpa","url":"https://advidi.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":100,"key":"ADVIDI_AFF"},
{"id":"affiliaxe","name":"Affiliaxe","cat":"cpa","url":"https://www.affiliaxe.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"AFFILIAXE_AFF"},
{"id":"olav","name":"Olav","cat":"cpa","url":"https://olav.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":50,"key":"OLAV_AFF"},
{"id":"freecash","name":"Freecash","cat":"micro","url":"https://freecash.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":5,"key":"FREECASH_REF"},
{"id":"picoworkers","name":"Picoworkers","cat":"micro","url":"https://picoworkers.com/register","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":5,"key":"PICOWORKERS_REF"},
{"id":"timebucks","name":"TimeBucks","cat":"micro","url":"https://timebucks.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":10,"key":"TIMEBUCKS_REF"},
{"id":"ysense","name":"ySense","cat":"micro","url":"https://www.ysense.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":10,"key":"YSENSE_REF"},
{"id":"swagbucks","name":"Swagbucks","cat":"micro","url":"https://www.swagbucks.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":10,"key":"SWAGBUCKS_REF"},
{"id":"coinpayu","name":"CoinPayU","cat":"micro","url":"https://www.coinpayu.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":1,"key":"COINPAYU_REF"},
{"id":"faucetcrypto","name":"FaucetCrypto","cat":"micro","url":"https://faucetcrypto.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":1,"key":"FAUCETCRYPTO_REF"},
{"id":"firefaucet","name":"FireFaucet","cat":"micro","url":"https://firefaucet.win","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":1,"key":"FIREFAUCET_REF"},
{"id":"adbtc","name":"AdBTC","cat":"micro","url":"https://adbtc.top","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":1,"key":"ADBTC_REF"},
{"id":"cointiply","name":"Cointiply","cat":"micro","url":"https://cointiply.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":1,"key":"COINTIPLY_REF"},
{"id":"hitleap","name":"HitLeap","cat":"exchange","url":"https://hitleap.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"HITLEAP_REF"},
{"id":"10khits","name":"10KHits","cat":"exchange","url":"https://www.10khits.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"TENKHITS_REF"},
{"id":"traffup","name":"TraffUp","cat":"exchange","url":"https://traffup.net","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"TRAFFUP_REF"},
{"id":"followlike","name":"FollowLike","cat":"exchange","url":"https://followlike.net","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"FOLLOWLIKE_REF"},
{"id":"addmefast","name":"AddMeFast","cat":"exchange","url":"https://addmefast.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"ADDMEFAST_REF"},
{"id":"like4like","name":"Like4Like","cat":"exchange","url":"https://www.like4like.org","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"LIKE4LIKE_REF"},
{"id":"youlikehits","name":"YouLikeHits","cat":"exchange","url":"https://youlikehits.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"YOULIKEHITS_REF"},
{"id":"websyndic","name":"WebSyndic","cat":"exchange","url":"https://www.websyndic.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"WEBSYNDIC_REF"},
{"id":"medium","name":"Medium","cat":"platform","url":"https://medium.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"MEDIUM_HANDLE"},
{"id":"blogger","name":"Blogger","cat":"platform","url":"https://www.blogger.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"BLOGGER_URL"},
{"id":"wordpress","name":"WordPress.com","cat":"platform","url":"https://wordpress.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"WPCOM_URL"},
{"id":"substack","name":"Substack","cat":"platform","url":"https://substack.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"SUBSTACK_URL"},
{"id":"devto","name":"Dev.to","cat":"platform","url":"https://dev.to","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"DEVTO_HANDLE"},
{"id":"tumblr","name":"Tumblr","cat":"platform","url":"https://www.tumblr.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"TUMBLR_HANDLE"},
{"id":"pinterest","name":"Pinterest","cat":"platform","url":"https://www.pinterest.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"PINTEREST_HANDLE"},
{"id":"youtube","name":"YouTube","cat":"platform","url":"https://www.youtube.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"YOUTUBE_CHANNEL"},
{"id":"tiktok","name":"TikTok","cat":"platform","url":"https://www.tiktok.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"TIKTOK_HANDLE"},
{"id":"facebook","name":"Facebook","cat":"platform","url":"https://www.facebook.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"FACEBOOK_PAGE"},
{"id":"instagram","name":"Instagram","cat":"platform","url":"https://www.instagram.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"INSTAGRAM_HANDLE"},
{"id":"xtwitter","name":"X (Twitter)","cat":"platform","url":"https://x.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"X_HANDLE"},
{"id":"linkedin","name":"LinkedIn","cat":"platform","url":"https://www.linkedin.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"LINKEDIN_URL"},
{"id":"reddit","name":"Reddit","cat":"platform","url":"https://www.reddit.com","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"REDDIT_HANDLE"},
{"id":"quora","name":"Quora","cat":"platform","url":"https://www.quora.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"QUORA_URL"},
{"id":"telegram","name":"Telegram","cat":"platform","url":"https://telegram.org","alt":[],"fields":"phone","verify":"phone","captcha":false,"payout":0,"key":"TELEGRAM_CHANNEL"},
{"id":"omdb","name":"OMDb API","cat":"data","url":"https://www.omdbapi.com","alt":[],"fields":"email","verify":"email","captcha":true,"payout":0,"key":"OMDB_API_KEY"},
{"id":"tmdb","name":"TMDB API","cat":"data","url":"https://www.themoviedb.org","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"TMDB_API_KEY"},
{"id":"tvmaze","name":"TVmaze API","cat":"data","url":"https://www.tvmaze.com","alt":[],"fields":"email/password/username","verify":"email","captcha":false,"payout":0,"key":"TVMAZE_API"},
{"id":"justwatch","name":"JustWatch","cat":"data","url":"https://www.justwatch.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"JUSTWATCH_ID"},
{"id":"imdb","name":"IMDb","cat":"data","url":"https://www.imdb.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":true,"payout":0,"key":"IMDB_ID"},
{"id":"trakt","name":"Trakt","cat":"data","url":"https://trakt.tv","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"TRAKT_ID"},
{"id":"anilist","name":"AniList","cat":"data","url":"https://anilist.co","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"ANILIST_ID"},
{"id":"jikan","name":"Jikan API","cat":"data","url":"https://api.jikan.moe/v4","alt":[],"fields":"none","verify":"none","captcha":false,"payout":0,"key":"JIKAN_API"},
{"id":"wikipedia","name":"Wikipedia","cat":"data","url":"https://www.wikipedia.org","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"WIKI_USER"},
{"id":"wikidata","name":"Wikidata","cat":"data","url":"https://www.wikidata.org","alt":[],"fields":"email/password/username","verify":"email","captcha":true,"payout":0,"key":"WIKIDATA_USER"}
]
JSON
python3 -c "import json;d=json.load(open('data/sources.json'));print(len(d),'مصدراً في الملف')" | tee -a "$LOG"

say "2 · ربط registry.py بالملف (توسّع بلا كود)"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import pathlib
p = pathlib.Path("tools/registry.py"); s = p.read_text(encoding="utf-8")
if "sources.json" not in s:
    s += '''

# ── تحميل المصادر من data/sources.json ──
try:
    import json as _json, pathlib as _pl
    _f = _pl.Path(__file__).resolve().parent.parent / "data" / "sources.json"
    if _f.exists():
        _have = {n["id"] for n in ALL}
        for _n in _json.loads(_f.read_text(encoding="utf-8")):
            if _n.get("id") and _n["id"] not in _have:
                _n.setdefault("alt", []); _n.setdefault("fields", "email/password/first/last")
                _n.setdefault("verify", "email"); _n.setdefault("captcha", True)
                ALL.append(_n); _have.add(_n["id"])
except Exception:
    pass

def by_cat(cat=None):
    return [n for n in ALL if cat is None or n.get("cat") == cat]
'''
    p.write_text(s, encoding="utf-8"); print("registry مربوط بـ sources.json")
else:
    print("مربوط مسبقاً")
PY
python3 -m py_compile tools/registry.py && ok "registry يُترجم"

say "3 · tools/sites.py — إدارة عدة مواقع"
cat > tools/sites.py <<'PY'
#!/usr/bin/env python3
import sys, os, json, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
F = pathlib.Path(core.DATA) / "sites.json"

def load(): return json.loads(F.read_text(encoding="utf-8")) if F.exists() else []
def save(d): F.write_text(json.dumps(d, indent=1, ensure_ascii=False), encoding="utf-8")

def main():
    a = sys.argv[1:]
    if not a or a[0] == "list":
        d = load(); print("مواقع مرتبطة: %d" % len(d))
        for s in d: print("   ", s["domain"], "→", s.get("path", "?"))
        return
    if a[0] == "add" and len(a) > 1:
        dom = a[1].replace("https://", "").replace("http://", "").rstrip("/")
        d = load()
        if any(s["domain"] == dom for s in d): print("موجود مسبقاً"); return
        path = os.path.expanduser(a[2]) if len(a) > 2 else os.path.expanduser("~/" + dom)
        d.append({"domain": dom, "path": path}); save(d)
        print("✓ أُضيف", dom, "→", path); return
    if a[0] == "del" and len(a) > 1:
        save([s for s in load() if s["domain"] != a[1]]); print("✓ حُذف"); return
    print("الاستخدام: sites.py [list | add <domain> [path] | del <domain>]")

if __name__ == "__main__":
    main()
PY
chmod +x tools/sites.py && python3 -m py_compile tools/sites.py && ok "sites.py جاهز"

say "4 · tools/genpages.py — توليد صفحات بأماكن إعلانات"
cat > tools/genpages.py <<'PY'
#!/usr/bin/env python3
import sys, os, json, csv, html, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = pathlib.Path(__file__).resolve().parent.parent
KEYS = ROOT / "keys.env"

def env():
    d = {}
    if KEYS.exists():
        for l in KEYS.read_text(encoding="utf-8").splitlines():
            if "=" in l and not l.strip().startswith("#"):
                k, _, v = l.partition("="); d[k.strip()] = v.strip()
    return d

def ads(e):
    o = []
    if e.get("ADSTERRA_ZONE"):
        o.append('<script async src="//www.highperformanceformat.com/%s/invoke.js"></script>' % e["ADSTERRA_ZONE"])
    if e.get("MONETAG_MULTITAG"):
        o.append('<script src="//nap5k.com/tag/%s" data-cfasync="false"></script>' % e["MONETAG_MULTITAG"])
    if e.get("POPADS_SITE"):
        o.append('<!-- PopAds site: %s -->' % e["POPADS_SITE"])
    return "\n".join(o)

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — CineHub</title><meta name="description" content="{desc}">
{ads}
<style>body{{font-family:system-ui;max-width:760px;margin:auto;padding:16px;line-height:1.8;background:#111;color:#eee}}a{{color:#6cf}}.ad{{margin:18px 0;text-align:center}}</style>
</head><body><h1>{title}</h1><div class="ad">{ads}</div><p>{desc}</p>
<p><a href="../index.html">← كل الصفحات</a></p><div class="ad">{ads}</div></body></html>
"""

def main():
    n = 50
    if "--count" in sys.argv: n = int(sys.argv[sys.argv.index("--count") + 1])
    out = ROOT / "site" / "pages"
    if "--out" in sys.argv: out = pathlib.Path(sys.argv[sys.argv.index("--out") + 1]).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    A = ads(env())
    src = ROOT / "data" / "titles.csv"; items = []
    if src.exists():
        with src.open(encoding="utf-8") as f:
            for r in csv.DictReader(f): items.append((r.get("title", "").strip(), r.get("desc", "").strip()))
    if not items: items = [("عمل %d" % i, "مراجعة وتفاصيل العمل رقم %d في CineHub." % i) for i in range(1, n + 1)]
    items = (items * ((n // len(items)) + 1))[:n]
    links = []
    for i, (t, d) in enumerate(items, 1):
        slug = "p%04d" % i
        (out / (slug + ".html")).write_text(TPL.format(title=html.escape(t), desc=html.escape(d), ads=A), encoding="utf-8")
        links.append('<li><a href="pages/%s.html">%s</a></li>' % (slug, html.escape(t)))
    (out.parent / "index.html").write_text(
        '<!doctype html><meta charset="utf-8"><title>CineHub</title>\n<h1>CineHub — %d صفحة</h1>\n%s\n%s'
        % (n, A, "<ul>" + "\n".join(links) + "</ul>"), encoding="utf-8")
    print("✓ وُلّدت %d صفحة في %s" % (n, out))

if __name__ == "__main__":
    main()
PY
chmod +x tools/genpages.py && python3 -m py_compile tools/genpages.py && ok "genpages.py جاهز"

say "5 · ربط الأوامر في agent.py"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
p = "tools/agent.py"; s = open(p, encoding="utf-8").read()
if 'c == "sources"' not in s:
    s = s.replace('    elif c == "audit":', '''    elif c == "sources":
        import registry, collections
        cc = collections.Counter(n.get("cat", "?") for n in registry.ALL)
        print("إجمالي المصادر: %d" % len(registry.ALL))
        for k, v in cc.most_common(): print("   %-10s %d" % (k, v))
    elif c == "genpages":
        import genpages; genpages.main()
    elif c == "sites":
        import sites; sites.main()
    elif c == "audit":''', 1)
    open(p, "w", encoding="utf-8").write(s); print("✓ رُبطت: sources · genpages · sites")
else:
    print("مربوطة مسبقاً")
PY
python3 -m py_compile tools/*.py && ok "كل الملفات تُترجم"

say "6 · النتيجة"
python3 -c "
import sys; sys.path.insert(0,'tools')
import registry, collections
cc = collections.Counter(n.get('cat','?') for n in registry.ALL)
print('المصادر المتاحة: %d' % len(registry.ALL))
for k,v in cc.most_common(): print('   %-10s %d' % (k,v))
" 2>&1 | tee -a "$LOG"

say "تم"
echo "  ./run.sh sources              # عدّ المصادر بالفئات"
echo "  ./run.sh sites add alisalimax3.github.io"
echo "  ./run.sh genpages --count 1000"
echo "  ./run.sh checkurls adsterra exoclick juicyads"
