#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""سجل 40 مصدر دفع حقيقي"""

def N(i,n,c,s,l,p,m,me,k="",h="",rx="",v="email",cap=False,note=""):
    return dict(id=i,name=n,cat=c,signup=s,login=l,payout_page=p,payout_min=m,
                methods=me,key_env=k,key_hint=h,key_regex=rx,verify=v,captcha=cap,note=note)

Z = r"\b(\d{5,8})\b"
AFF = r"(https?://[^\s\"'<>]*(?:ref|aff|partner|a_aid|track|utm)[^\s\"'<>]*)"

ALL = [
# ---------- شبكات إعلانات (Publisher) ----------
N("adsterra","Adsterra","ads","https://publishers.adsterra.com/signup","https://publishers.adsterra.com/login","https://publishers.adsterra.com/payments",5,["PayPal","Paxum","USDT","BTC","Wire"],"ADSTERRA_ZONE","Zone ID (5-8 أرقام)",Z,note="CPM عالي، موافقة سريعة"),
N("monetag","Monetag","ads","https://publishers.monetag.com/","https://publishers.monetag.com/","https://publishers.monetag.com/",5,["PayPal","Paxum","USDT","BTC","Wire"],"MONETAG_ZONE","Zone ID",Z,note="In-Page Push + Vignette"),
N("propellerads","PropellerAds","ads","https://publishers.propellerads.com/","https://publishers.propellerads.com/","https://publishers.propellerads.com/",5,["PayPal","Paxum","Wire","USDT"],"PROPELLER_ZONE","Zone ID",Z),
N("popads","PopAds","ads","https://www.popads.net/users/register","https://www.popads.net/users/login","https://www.popads.net/users/payments",5,["PayPal","Paxum","Payoneer","BTC"],"POPADS_SITE","Site ID",r"\b(\d{4,9})\b"),
N("exoclick","ExoClick","ads","https://admin.exoclick.com/signup","https://admin.exoclick.com/login","https://admin.exoclick.com/payments",20,["PayPal","Paxum","Wire","USDT"],"EXOCLICK_ZONE","Zone ID",r"\b(\d{4,9})\b",note="الأقوى للمحتوى الكبير"),
N("juicyads","JuicyAds","ads","https://www.juicyads.com/register/","https://www.juicyads.com/login/","https://www.juicyads.com/payments/",50,["PayPal","Paxum","Wire","USDT","BTC"],"JUICYADS_SITE","Site ID",r"\b(\d{4,9})\b",note="متخصص Adult"),
N("clickadu","Clickadu","ads","https://pub.clickadu.com/signup","https://pub.clickadu.com/","https://pub.clickadu.com/",10,["Paxum","USDT","Wire"],"CLICKADU_ZONE","Zone ID",Z),
N("hilltopads","HilltopAds","ads","https://hilltopads.com/publishers","https://hilltopads.com/login","https://hilltopads.com/",50,["Paxum","USDT","Wire","BTC"],"HILLTOP_ZONE","Zone ID",Z),
N("adcash","Adcash","ads","https://www.adcash.com/en/publishers/","https://www.adcash.com/login/","https://www.adcash.com/",25,["PayPal","Wire","Skrill"],"ADCASH_ZONE","Zone ID",Z),
N("adsense","Google AdSense","ads","https://www.google.com/adsense/start/","https://www.google.com/adsense/","https://www.google.com/adsense/",100,["Wire","Payoneer"],"ADSENSE_PUB","Publisher ID",r"(pub-\d{16})",v="manual",note="يحتاج موافقة موقع"),
N("ezoic","Ezoic","ads","https://www.ezoic.com/signup/","https://www.ezoic.com/login/","https://www.ezoic.com/",20,["PayPal","Wire"],"EZOIC_SITE","Site ID",r"\b(\d{5,8})\b",v="manual"),
N("mgid","MGID","ads","https://www.mgid.com/publishers","https://www.mgid.com/login","https://www.mgid.com/",100,["Wire","Payoneer"],"MGID_PUB","Publisher ID",r"\b(\d{5,9})\b",v="manual"),

# ---------- تسويق بالعمولة ----------
N("amazon","Amazon Associates","affiliate","https://affiliate-program.amazon.com/","https://affiliate-program.amazon.com/","https://affiliate-program.amazon.com/home/payment",10,["Wire","GiftCard"],"AMAZON_TAG","Tracking ID",r"(?:tag=)([a-z0-9\-]+)",v="manual"),
N("aliexpress","AliExpress Affiliate","affiliate","https://portals.aliexpress.com/","https://portals.aliexpress.com/","https://portals.aliexpress.com/",16,["PayPal","Wire"],"ALIEXPRESS_PID","PID",r"(?:aff_short_key=|pid=)([A-Za-z0-9]+)",v="manual"),
N("clickbank","ClickBank","affiliate","https://accounts.clickbank.com/signup.htm","https://accounts.clickbank.com/","https://accounts.clickbank.com/",10,["Wire","Payoneer"],"CLICKBANK_NICK","Nickname",r"\b([a-z0-9]{6,12})\b",v="manual"),
N("digistore24","Digistore24","affiliate","https://www.digistore24.com/en/","https://www.digistore24.com/","https://www.digistore24.com/",50,["PayPal","Wire"],"DIGISTORE_AFF","Affiliate ID",r"\b(\d{5,8})\b",v="manual"),
N("hotmart","Hotmart","affiliate","https://signup.hotmart.com/","https://app.hotmart.com/","https://app.hotmart.com/",10,["PayPal","Wire"],"HOTMART_AFF","Affiliate ID",r"\b(\d{5,9})\b",v="manual"),
N("shareasale","ShareASale","affiliate","https://account.shareasale.com/shareasale.cfm?action=signup","https://account.shareasale.com/","https://account.shareasale.com/",50,["Wire","PayPal"],"SAS_AFF","Affiliate ID",r"\b(\d{5,9})\b",v="manual"),
N("cj","CJ Affiliate","affiliate","https://signup.cj.com/","https://members.cj.com/","https://members.cj.com/",50,["Wire","PayPal","Payoneer"],"CJ_PID","PID",r"\b(\d{6,9})\b",v="manual"),
N("awin","Awin","affiliate","https://www.awin.com/gb/join","https://ui.awin.com/","https://ui.awin.com/",20,["Wire","PayPal"],"AWIN_PID","Publisher ID",r"\b(\d{5,8})\b",v="manual"),
N("impact","Impact","affiliate","https://impact.com/signup/","https://app.impact.com/","https://app.impact.com/",10,["Wire","PayPal"],"IMPACT_ACCOUNT","Account SID",r"([A-Za-z0-9_\-]{8,})",v="manual"),
N("hostinger","Hostinger Affiliate","affiliate","https://www.hostinger.com/affiliates","https://affiliates.hostinger.com/","https://affiliates.hostinger.com/",100,["PayPal","Wire"],"HOSTINGER_REF","رابط الإحالة",AFF,v="manual",note="60% لكل بيعة"),
N("crakrevenue","CrakRevenue","affiliate","https://www.crakrevenue.com/","https://www.crakrevenue.com/login","https://www.crakrevenue.com/",50,["Paxum","Wire","PayPal"],"CRAK_AFF","Affiliate ID",r"\b(\d{4,9})\b",v="manual"),
N("stripchat","Stripchat Affiliates","affiliate","https://affiliates.stripchat.com/","https://affiliates.stripchat.com/","https://affiliates.stripchat.com/",50,["Paxum","Wire","USDT"],"STRIPCHAT_REF","رابط الإحالة",r"(https?://[^\s\"'<>]*stripchat[^\s\"'<>]*)",v="manual",note="حتى 50% Revenue Share"),
N("chaturbate","Chaturbate Affiliate","affiliate","https://chaturbate.com/affiliates/","https://chaturbate.com/affiliates/","https://chaturbate.com/affiliates/",50,["Wire","Paxum","BTC"],"CHATURBATE_REF","رابط الإحالة",r"(https?://[^\s\"'<>]*chaturbate[^\s\"'<>]*)",v="manual"),
N("bongacams","BongaCams Affiliate","affiliate","https://affiliates.bongacams.com/","https://affiliates.bongacams.com/","https://affiliates.bongacams.com/",50,["Wire","Paxum","USDT"],"BONGA_REF","رابط الإحالة",r"(https?://[^\s\"'<>]*bonga[^\s\"'<>]*)",v="manual"),
N("livejasmin","LiveJasmin Affiliate","affiliate","https://www.livejasmin.com/en/affiliate","https://www.livejasmin.com/en/affiliate","https://www.livejasmin.com/",50,["Wire","Paxum","Payoneer"],"JASMIN_REF","رابط الإحالة",r"(https?://[^\s\"'<>]*jasmin[^\s\"'<>]*)",v="manual"),

# ---------- مهام مصغّرة ----------
N("clickworker","Clickworker","tasks","https://www.clickworker.com/clickworker/","https://workplace.clickworker.com/","https://workplace.clickworker.com/",5,["PayPal","Wire"],"CLICKWORKER_ID","Account ID",r"\b(\d{5,9})\b",v="manual"),
N("toloka","Toloka","tasks","https://toloka.ai/","https://toloka.ai/","https://toloka.ai/",1,["PayPal","Payoneer","Skrill"],"TOLOKA_ID","Worker ID",r"\b(\d{6,10})\b",v="manual"),
N("picoworkers","Picoworkers","tasks","https://picoworkers.com/register","https://picoworkers.com/login.php","https://picoworkers.com/withdraw.php",5,["PayPal","Payeer","USDT","Skrill","AirTM"],"PICOWORKERS_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
N("microworkers","Microworkers","tasks","https://www.microworkers.com/register.php","https://www.microworkers.com/login.php","https://www.microworkers.com/withdraw.php",9,["PayPal","Payoneer","Skrill"],"MICROWORKERS_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
N("timebucks","TimeBucks","tasks","https://timebucks.com/","https://timebucks.com/","https://timebucks.com/",10,["PayPal","Payeer","USDT","BTC","Skrill","AirTM"],"TIMEBUCKS_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
N("ysense","ySense","tasks","https://www.ysense.com/","https://www.ysense.com/","https://www.ysense.com/",10,["PayPal","Payoneer","Skrill","GiftCard"],"YSENSE_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b",v="manual"),
N("freecash","Freecash","tasks","https://freecash.com/","https://freecash.com/","https://freecash.com/",1,["PayPal","USDT","BTC","GiftCard"],"FREECASH_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
N("cointiply","Cointiply","tasks","https://cointiply.com/","https://cointiply.com/","https://cointiply.com/",3,["BTC","DOGE","LTC","ETH","PayPal"],"COINTIPLY_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
N("faucetpay","FaucetPay","crypto","https://faucetpay.io/","https://faucetpay.io/login","https://faucetpay.io/",1,["BTC","DOGE","LTC","ETH","TRX"],"FAUCETPAY_EMAIL","بريد الحساب","",v="email"),

# ---------- عمل حر ----------
N("fiverr","Fiverr","freelance","https://www.fiverr.com/join","https://www.fiverr.com/login","https://www.fiverr.com/users/",5,["PayPal","Payoneer","Bank"],"FIVERR_USER","اسم المستخدم",r"@([A-Za-z0-9_]{3,20})"),
N("upwork","Upwork","freelance","https://www.upwork.com/signup/","https://www.upwork.com/ab/account-security/login","https://www.upwork.com/",100,["Wire","Payoneer"],"UPWORK_USER","اسم المستخدم","",v="manual"),
N("freelancer","Freelancer","freelance","https://www.freelancer.com/signup","https://www.freelancer.com/login","https://www.freelancer.com/",30,["PayPal","Payoneer","Wire","Skrill"],"FREELANCER_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
N("peopleperhour","PeoplePerHour","freelance","https://www.peopleperhour.com/site/register","https://www.peopleperhour.com/site/login","https://www.peopleperhour.com/",50,["PayPal","Wire"],"PPH_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b",v="manual"),
]

CATS = {"ads":"شبكات إعلانات","affiliate":"تسويق بالعمولة","tasks":"مهام مصغّرة","crypto":"كريبتو","freelance":"عمل حر"}
# روابط بديلة إن تغيّر الرابط الرسمي
ALTS = {
 "adsterra": ["https://publishers.adsterra.com/signup","https://publishers.adsterra.com/","https://adsterra.com/publishers/"],
 "monetag": ["https://publishers.monetag.com/signup","https://monetag.com/publishers/"],
 "propellerads": ["https://publishers.propellerads.com/#/pub/registration","https://propellerads.com/"],
 "popads": ["https://www.popads.net/users/register/","https://www.popads.net/"],
 "exoclick": ["https://admin.exoclick.com/signup/","https://www.exoclick.com/publishers/"],
 "juicyads": ["https://www.juicyads.com/register","https://www.juicyads.com/"],
 "clickadu": ["https://www.clickadu.com/signup","https://pub.clickadu.com/"],
 "hilltopads": ["https://hilltopads.com/signup","https://hilltopads.com/"],
 "picoworkers": ["https://picoworkers.com/register","https://picoworkers.com/"],
 "freecash": ["https://freecash.com/r/register","https://freecash.com/"],
 "timebucks": ["https://timebucks.com/register.php","https://timebucks.com/"],
 "cointiply": ["https://cointiply.com/register","https://cointiply.com/"],
 "faucetpay": ["https://faucetpay.io/register","https://faucetpay.io/"],
 "ySense": ["https://www.ysense.com/register","https://www.ysense.com/"],
 "clickworker": ["https://www.clickworker.com/registration/","https://www.clickworker.com/"],
 "microworkers": ["https://www.microworkers.com/register","https://www.microworkers.com/"],
 "toloka": ["https://toloka.ai/signup","https://toloka.ai/"],
 "fiverr": ["https://www.fiverr.com/registration","https://www.fiverr.com/join"],
 "freelancer": ["https://www.freelancer.com/signup/","https://www.freelancer.com/"],
 "upwork": ["https://www.upwork.com/signup","https://www.upwork.com/"],
 "peopleperhour": ["https://www.peopleperhour.com/signup","https://www.peopleperhour.com/"],
 "adsense": ["https://www.google.com/adsense/start/","https://adsense.google.com/"],
 "ezoic": ["https://www.ezoic.com/signup","https://www.ezoic.com/"],
 "mgid": ["https://www.mgid.com/publishers/","https://www.mgid.com/"],
 "adcash": ["https://www.adcash.com/en/register/","https://www.adcash.com/"],
 "amazon": ["https://affiliate-program.amazon.com/","https://associates.amazon.com/"],
 "aliexpress": ["https://portals.aliexpress.com/","https://www.aliexpress.com/"],
 "clickbank": ["https://accounts.clickbank.com/signup","https://www.clickbank.com/"],
 "digistore24": ["https://www.digistore24.com/en/signup","https://www.digistore24.com/"],
 "hotmart": ["https://signup.hotmart.com/","https://www.hotmart.com/"],
 "shareasale": ["https://account.shareasale.com/shareasale.cfm?action=signup","https://www.shareasale.com/"],
 "cj": ["https://signup.cj.com/","https://www.cj.com/"],
 "awin": ["https://www.awin.com/gb/join","https://www.awin.com/"],
 "impact": ["https://impact.com/signup","https://impact.com/"],
 "hostinger": ["https://www.hostinger.com/affiliates","https://www.hostinger.com/"],
 "crakrevenue": ["https://www.crakrevenue.com/signup","https://www.crakrevenue.com/"],
 "stripchat": ["https://affiliates.stripchat.com/","https://stripchat.com/"],
 "chaturbate": ["https://chaturbate.com/affiliates/","https://chaturbate.com/"],
 "bongacams": ["https://affiliates.bongacams.com/","https://bongacams.com/"],
 "livejasmin": ["https://www.livejasmin.com/en/affiliate","https://www.livejasmin.com/"],
}
def candidates(net):
    seen, out = set(), []
    for u in [net["signup"]] + ALTS.get(net["id"], []):
        if u and u not in seen: seen.add(u); out.append(u)
    return out

BY_ID = {n["id"]: n for n in ALL}

def by_id(i):
    if i not in BY_ID: raise KeyError(f"مصدر غير معروف: {i}")
    return BY_ID[i]

def by_cat(c): return [n for n in ALL if n["cat"] == c]

def pending():
    import core
    out = []
    for n in ALL:
        if n["key_env"] and not core.env(n["key_env"]): out.append(n)
    return out

def with_key():
    import core
    return [n for n in ALL if n["key_env"] and core.env(n["key_env"])]
