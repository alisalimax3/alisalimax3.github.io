#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني سجلًا موحّدًا: قنوات دخل + مصادر + كل المواقع، ويقسّمه شرائح لتفادي إثقال الهاتف"""
import os, json, re, datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
TARGET=int(os.environ.get("SITES_TARGET","90053")); SHARD=1000

CATS=[("ad",r"adsterra|monetag|propeller|popads|admaven|hilltop|evadav|clickadu|adcash|galaksion|mybid|richads|kadam|exoclick|juicy|trafficjunky|trafficstars|plugrush|bidvertiser|infolinks|mgid|taboola|outbrain|revcontent|ezoic|nitropay|setupad|playwire|mediavine|snigel|publift|coinzilla|bitmedia|teads|primis|connatix|smaato|inmobi|applovin|ironsource|mintegral"),
("cpa",r"cpagrip|cpalead|ogads|adgate|adworkmedia|maxbounty|lootably|timewall|offertoro|adscend|wannads|adgem|mobidea|advidi|affise|everflow|tune|gotzha"),
("survey",r"bitlabs|cpx|theoremreach|pollfish|ayet|notik|monlix|prodege|cint|lucid|dynata|toluna"),
("link",r"linkvertise|shrinkme|shrinkearn|gplinks|clk\.sh|droplink|cuty\.io|exe\.io|earn4link|bitsfly|ouo\.io|shorte\.st|adf\.ly|work\.ink|loot|rekonise|boost\.ink|za\.gl|shortzzy|clicksfly"),
("commission",r"clickbank|digistore|impact\.com|cj\.com|awin|rakuten|shareasale|admitad|flexoffers|skimlinks|sovrn|partnerstack|tradedoubler|webgains|belboon|daisycon|kwanko|effiliation|amazon"),
("crypto",r"cointiply|faucetpay|firefaucet|coinbase|binance|trustwallet|kraken|kucoin"),
("source",r"tmdb|imdb|wikidata|wikipedia|archive\.org|commons\.wikimedia|gutenberg|dailymotion|peertube|sepiasearch|lbry|odysee|piped|invidious|itunes|apple\.com/search|openlibrary|europeana|smithsonian|metmuseum|rijksmuseum|nasa|loc\.gov|si\.edu"),
("stream",r"youtube|vimeo|netflix|prime|disney|hulu|twitch|dailymotion|crunchyroll|tubi|pluto|plex|kodi|stream|watch|cinema|movie|film|tv"),
("data",r"api\.|\.io$|\.dev$|\.ai$|graphql|data|dataset|db|index"),
("social",r"facebook|twitter|x\.com|instagram|tiktok|telegram|whatsapp|linkedin|reddit|discord|pinterest|snapchat|threads|mastodon"),
("host",r"github|gitlab|cloudflare|netlify|vercel|heroku|hosting|host|server|cdn|aws|azure|digitalocean|linode|vultr"),
("news",r"news|times|post|herald|journal|daily|press|reuters|bbc|cnn|aljazeera"),
("shop",r"shop|store|market|amazon|ebay|aliexpress|etsy|noon|jumia"),
("edu",r"\.edu|university|college|school|institute|academy"),
("gov",r"\.gov|ministry|government|municipal"),
("bank",r"bank|finance|microfinance|kuraimi|swift|visa|mastercard|paypal|payoneer|wise|westernunion")]
def cat(d,n):
    s=(d+" "+n).lower()
    for c,rx in CATS:
        if re.search(rx,s): return c
    return "other"
def dom(u):
    m=re.match(r"https?://([^/]+)",u or ""); 
    return m.group(1).lower().replace("www.","") if m else ""
def norm(u):
    if not u: return ""
    u=u.strip()
    if u.startswith("//"): u="https:"+u
    if not u.startswith("http"): return ""
    return u

items={}
for f in ("platforms.json","entities.json","catalog.json","films.json","library.json","accounts.json","sources.json"):
    if not os.path.exists(f): continue
    try: d=json.load(open(f,encoding="utf-8"))
    except Exception: continue
    bag=d if isinstance(d,list) else []
    if isinstance(d,dict):
        for k in ("items","list","entities","networks","films","results","data","sites"):
            if isinstance(d.get(k),list): bag+=d[k]
    for x in bag:
        if not isinstance(x,dict): continue
        u=norm(x.get("url") or x.get("website") or x.get("homepage") or x.get("link") or x.get("official") or "")
        if not u: continue
        dm=dom(u)
        if not dm or dm in items: continue
        nm=(x.get("name") or x.get("title") or dm)[:80]
        items[dm]={"d":dm,"n":nm,"u":u,"c":cat(dm,nm)}

sites=list(items.values())[:TARGET]
for x in sites: x["k"]=1 if x["c"] in ("ad","cpa","survey","link","commission","crypto") else 0
os.makedirs("sites",exist_ok=True)
for i in range(0,len(sites),SHARD):
    json.dump(sites[i:i+SHARD],open("sites/s%03d.json"%(i//SHARD),"w"),ensure_ascii=False,separators=(",",":"))
shards=(len(sites)+SHARD-1)//SHARD
from collections import Counter
cc=Counter(x["c"] for x in sites)
money=[x for x in sites if x["k"]]
reg={"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
     "counts":{"sites":len(sites),"shards":shards,"money":len(money),"other":len(sites)-len(money)},
     "categories":dict(cc),"shard_size":SHARD,
     "note":"التصنيف بالكلمات المفتاحية في النطاق — وليس ادّعاءً"}
json.dump(reg,open("registry.json","w"),ensure_ascii=False,indent=1)
json.dump({"generated":reg["generated"],"items":[{"name":x["n"],"url":x["u"],"cat":x["c"],"key_var":""} for x in money]},
          open("signup_targets.json","w"),ensure_ascii=False,indent=1)
print("مواقع:",len(sites),"| شرائح:",shards,"| قنوات دخل محتملة:",len(money))
print("توزيع:",dict(cc.most_common(8)))
