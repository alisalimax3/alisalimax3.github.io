#!/data/data/com.termux/files/usr/bin/bash
set -e
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p tools data data/sessions logs assets content .tmp

echo "══ تثبيت الحزم ══"
pkg install -y python-pip chromium 2>/dev/null || true
pip install --upgrade pip setuptools wheel 2>/dev/null || true
pip install requests beautifulsoup4 lxml playwright 2>/dev/null \
  || pip install --break-system-packages requests beautifulsoup4 lxml playwright 2>/dev/null || true

echo "══ كتابة الملفات ══"

# ============ tools/core.py ============
cat > tools/core.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub Core v4 — نواة مستقرة بلا اعتماد خارجي"""
from __future__ import annotations
import json, os, random, re, string, subprocess, sys, urllib.error, urllib.request
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
DATA, LOGS = BASE / "data", BASE / "logs"
ENV_FILE, LOG_FILE = BASE / "keys.env", LOGS / "cinehub.log"
C = {"ok":"\033[92m","err":"\033[91m","warn":"\033[93m","info":"\033[96m","d":"\033[90m","b":"\033[1m","x":"\033[0m"}

def _ts(): return datetime.now().strftime("%H:%M:%S")

def log(msg, level="info"):
    col = {"ok":C["ok"],"err":C["err"],"warn":C["warn"],"info":C["info"]}.get(level, C["info"])
    ico = {"ok":"✓","err":"✗","warn":"!","info":"i"}.get(level,"i")
    print(f"{C['d']}[{_ts()}]{C['x']} {col}{ico}{C['x']} {msg}")
    try:
        LOGS.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().isoformat()}] [{level}] {msg}\n")
    except Exception: pass

def ensure_dirs():
    for d in (DATA, LOGS, BASE/"assets", BASE/"content", BASE/".tmp", DATA/"sessions"):
        d.mkdir(parents=True, exist_ok=True)

def _r(name):
    p = Path(name); return p if p.is_absolute() else DATA / p

def load(name, default=None):
    p = _r(name)
    try:
        if p.exists(): return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e: log(f"قراءة {p.name}: {e}", "warn")
    return {} if default is None else default

def save(name, data):
    p = _r(name)
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        t = p.with_name(p.name + ".tmp")
        t.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        t.replace(p); return True
    except Exception as e:
        log(f"حفظ {p.name}: {e}", "err"); return False

def env(k, d=""): return os.environ.get(k, d)

def load_env(path=None):
    p = Path(path or ENV_FILE)
    if not p.exists(): return
    for raw in p.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line: continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def set_env(k, v, path=None):
    p = Path(path or ENV_FILE); lines=[]; found=False
    if p.exists():
        for raw in p.read_text(encoding="utf-8", errors="ignore").splitlines():
            if re.match(rf"^\s*{re.escape(k)}\s*=", raw):
                lines.append(f"{k}={v}"); found=True
            else: lines.append(raw)
    if not found: lines.append(f"{k}={v}")
    p.write_text("\n".join(lines).rstrip()+"\n", encoding="utf-8")
    os.environ[k] = v

def get_env_key(k, default=""):
    return env(k) or default

def site():
    u = env("SITE_URL")
    if u: return u.rstrip("/")
    gh = env("GITHUB_USER") or env("GH_USER")
    return f"https://{gh}.github.io" if gh else ""

def genpass(n=18):
    ab = string.ascii_letters + string.digits + "!@#$%"
    return "".join(random.choice(ab) for _ in range(n))

def openurl(url):
    for c in (["termux-open-url", url], ["termux-open", url], ["xdg-open", url]):
        try: subprocess.Popen(c, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); return True
        except Exception: continue
    log(f"افتح يدوياً: {url}", "info"); return False

def clipboard():
    for c in (["termux-clipboard-get"], ["xclip","-selection","clipboard","-o"]):
        try: return subprocess.check_output(c, text=True, stderr=subprocess.DEVNULL).strip()
        except Exception: continue
    return ""

def clipset(t):
    for c in (["termux-clipboard-set"], ["xclip","-selection","clipboard"]):
        try:
            subprocess.run(c, input=t, text=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); return True
        except Exception: continue
    return False

UA = ("Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36")

def http(url, method="GET", data=None, headers=None, timeout=20):
    h = {"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"}
    if headers: h.update(headers)
    body = None
    if data is not None:
        body = json.dumps(data).encode() if isinstance(data,(dict,list)) else str(data).encode()
        h.setdefault("Content-Type","application/json")
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=body, headers=h, method=method), timeout=timeout) as r:
            return {"ok":True,"code":r.getcode(),"text":r.read().decode("utf-8","ignore")}
    except urllib.error.HTTPError as e:
        return {"ok":False,"code":e.code,"err":str(e),"text":e.read().decode("utf-8","ignore")}
    except Exception as e:
        return {"ok":False,"code":0,"err":str(e),"text":""}

def alive(url, timeout=10):
    r = http(url, timeout=timeout)
    return bool(r.get("ok") and r.get("code",0) < 400)

ensure_dirs(); load_env()
PYEOF

# ============ tools/browser.py ============
cat > tools/browser.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""متصفح Termux — يستخدم chromium النظام (لا يحتاج playwright install)"""
import os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ARGS = ["--no-sandbox","--disable-dev-shm-usage","--disable-gpu",
        "--disable-blink-features=AutomationControlled","--no-first-run",
        "--disable-features=IsolateOrigins,site-per-process","--mute-audio"]

def find_chromium():
    for n in ("chromium-browser","chromium","chrome","google-chrome","chrome-headless-shell"):
        p = shutil.which(n)
        if p: return p
    return None

def launch(pw, headless=True, slow=0):
    exe = find_chromium()
    kw = dict(headless=headless, args=ARGS)
    if slow: kw["slow_mo"] = slow
    if exe:
        kw["executable_path"] = exe
        core.log(f"المتصفح: {exe}", "info")
    return pw.chromium.launch(**kw)

def context_args():
    return dict(
        user_agent=core.UA,
        viewport={"width":1366,"height":900},
        locale="en-US",
        timezone_id="Africa/Casablanca",
        java_script_enabled=True,
        ignore_https_errors=True,
    )

def new_page(browser, session_file=None):
    if session_file and os.path.exists(session_file):
        ctx = browser.new_context(storage_state=session_file, **context_args())
    else:
        ctx = browser.new_context(**context_args())
    try:
        ctx.add_init_script("Object.defineProperty(navigator,'webdriver',{get:()=>undefined});")
    except Exception: pass
    return ctx, ctx.new_page()

def save_session(ctx, path):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        ctx.storage_state(path=path); return True
    except Exception: return False
PYEOF

# ============ tools/registry.py ============
cat > tools/registry.py << 'PYEOF'
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
N("adsterra","Adsterra","ads","https://publishers.adsterra.com/register","https://publishers.adsterra.com/login","https://publishers.adsterra.com/payments",5,["PayPal","Paxum","USDT","BTC","Wire"],"ADSTERRA_ZONE","Zone ID (5-8 أرقام)",Z,note="CPM عالي، موافقة سريعة"),
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
N("picoworkers","Picoworkers","tasks","https://picoworkers.com/register.php","https://picoworkers.com/login.php","https://picoworkers.com/withdraw.php",5,["PayPal","Payeer","USDT","Skrill","AirTM"],"PICOWORKERS_USER","اسم المستخدم",r"\b([A-Za-z0-9_]{3,20})\b"),
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
PYEOF

# ============ tools/mailbox.py ============
cat > tools/mailbox.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""قراءة بريد التحقق تلقائياً عبر IMAP — يكسر حاجز تأكيد الحساب"""
import email, imaplib, os, re, sys, time
from email.header import decode_header
from html import unescape
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

LINK_RX = re.compile(r'https?://[^\s"\'<>\])]+')
OK_RX = re.compile(r'(verif|confirm|activat|validate|welcome|signup|register)', re.I)

def _dec(v):
    if not v: return ""
    out = []
    for part, enc in decode_header(v):
        out.append(part.decode(enc or "utf-8", "ignore") if isinstance(part, bytes) else part)
    return " ".join(out)

def _body(msg):
    txt = ""
    if msg.is_multipart():
        for p in msg.walk():
            ct = p.get_content_type()
            if ct in ("text/plain", "text/html"):
                try: txt += p.get_payload(decode=True).decode(p.get_content_charset() or "utf-8", "ignore")
                except Exception: pass
    else:
        try: txt = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8", "ignore")
        except Exception: pass
    return unescape(txt)

def configured():
    return bool(core.env("MAIL_IMAP_HOST") and core.env("MAIL_USER") and core.env("MAIL_APP_PASS"))

def fetch(since_min=45, limit=25):
    host, user, pw = core.env("MAIL_IMAP_HOST"), core.env("MAIL_USER"), core.env("MAIL_APP_PASS")
    if not (host and user and pw): return []
    try:
        m = imaplib.IMAP4_SSL(host, 993); m.login(user, pw); m.select("INBOX")
        typ, data = m.search(None, "ALL")
        ids = data[0].split()[-limit:]
        out = []
        for i in reversed(ids):
            typ, raw = m.fetch(i, "(RFC822)")
            if raw and raw[0]: out.append(email.message_from_bytes(raw[0][1]))
        m.logout(); return out
    except Exception as e:
        core.log(f"IMAP: {e}", "warn"); return []

def find_confirm_link(domain_hint="", tries=6, wait=15):
    """يبحث عن رابط تأكيد من موقع معيّن"""
    for attempt in range(tries):
        for msg in fetch():
            subj = _dec(msg.get("Subject",""))
            frm = _dec(msg.get("From",""))
            blob = subj + " " + frm
            if domain_hint and domain_hint.lower() not in blob.lower():
                continue
            if not OK_RX.search(blob): continue
            for link in LINK_RX.findall(_body(msg)):
                l = link.rstrip(".,;)")
                if OK_RX.search(l) or "verif" in l.lower() or "confirm" in l.lower():
                    return l, subj
        if attempt < tries - 1:
            core.log(f"انتظار بريد التحقق... ({attempt+1}/{tries})", "info"); time.sleep(wait)
    return "", ""

def confirm(domain_hint=""):
    link, subj = find_confirm_link(domain_hint)
    if not link:
        core.log("لم يُعثر على رابط تحقق", "warn"); return False
    core.log(f"بريد: {subj}", "ok")
    r = core.http(link, timeout=25)
    core.log(f"تفعيل {'نجح' if r.get('ok') else 'فشل'} ({r.get('code')})", "ok" if r.get("ok") else "warn")
    return True
PYEOF

# ============ tools/captcha.py ============
cat > tools/captcha.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""حل الكابتشا عبر 2captcha (اختياري) — يكسر آخر حاجز"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

API = "https://2captcha.com"

def key(): return core.env("CAPTCHA_KEY")

def solve_recaptcha(sitekey, url, tries=30):
    k = key()
    if not k: return ""
    r = core.http(f"{API}/in.php?key={k}&method=userrecaptcha&googlekey={sitekey}&pageurl={url}&json=1")
    if not r.get("ok"): return ""
    try: import json; rid = json.loads(r["text"]).get("request")
    except Exception: return ""
    for _ in range(tries):
        time.sleep(5)
        rr = core.http(f"{API}/res.php?key={k}&action=get&id={rid}&json=1")
        try:
            import json; d = json.loads(rr["text"])
            if d.get("status") == 1: return d["request"]
        except Exception: pass
    return ""

def inject(page, token):
    if not token: return
    page.evaluate("""(t)=>{document.querySelectorAll('#g-recaptcha-response,textarea[name="g-recaptcha-response"]').forEach(e=>{e.style.display='block';e.value=t;});}""", token)
PYEOF

# ============ tools/autoreg.py ============
cat > tools/autoreg.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""محرّك التسجيل التلقائي الحقيقي — تعبئة ذكية + إرسال + حصاد المفاتيح"""
from __future__ import annotations
import json, os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, browser, mailbox, captcha
from registry import by_id

STATE = core.DATA / "sessions"; STATE.mkdir(parents=True, exist_ok=True)
REGS = core.DATA / "registrations.json"

KEYMAP = [
    (("confirm","retype","repeat","again"), "password"),
    (("email","e-mail","mail"), "email"),
    (("password","passwd","pass"), "password"),
    (("first","given","fname"), "first"),
    (("last","family","surname","lname"), "last"),
    (("username","nick","login","handle"), "username"),
    (("full","displayname","realname","name"), "fullname"),
    (("website","site","domain","url"), "site"),
    (("phone","mobile","tel","whatsapp"), "phone"),
    (("company","organization","org","business"), "company"),
    (("city","town"), "city"),
    (("zip","postal","postcode"), "zip"),
    (("address","street","addr"), "address"),
    (("telegram","skype"), "telegram"),
]

def _sig(el):
    parts = []
    for a in ("name","id","placeholder","aria-label","autocomplete"):
        try:
            v = el.get_attribute(a)
            if v: parts.append(v.lower())
        except Exception: pass
    try:
        lb = el.evaluate("e => (e.labels && e.labels.length) ? e.labels[0].innerText : ''")
        if lb: parts.append(lb.lower())
    except Exception: pass
    return " ".join(parts)

def _vals(p):
    return {
        "email": p.get("email",""), "password": p.get("password",""),
        "first": p.get("first",""), "last": p.get("last",""),
        "fullname": f'{p.get("first","")} {p.get("last","")}'.strip(),
        "username": p.get("username",""), "site": p.get("site",""),
        "phone": p.get("phone",""), "company": p.get("company",""),
        "city": p.get("city",""), "zip": p.get("zip",""),
        "address": p.get("address",""), "telegram": p.get("telegram",""),
    }

def _match(sig, t):
    if t == "email": return "email"
    if t == "password": return "password"
    if t == "tel": return "phone"
    for words, field in KEYMAP:
        if any(w in sig for w in words): return field
    return ""

def autofill(page, profile):
    vals = _vals(profile); done = []
    for el in page.query_selector_all("input, textarea"):
        try:
            if not el.is_visible() or not el.is_enabled(): continue
            t = (el.get_attribute("type") or "text").lower()
            if t in ("hidden","submit","button","file","image","reset","search","checkbox","radio"): continue
            if (el.get_attribute("value") or "").strip(): continue
            f = _match(_sig(el), t)
            if not f or not vals.get(f): continue
            el.fill(str(vals[f])); done.append(f)
        except Exception: continue
    return done

def pick_country(page, profile):
    want = [profile.get("country_name",""), profile.get("country","")]
    for sel in page.query_selector_all("select"):
        try:
            s = _sig(sel)
            if not any(k in s for k in ("country","nation","pays")): continue
            for cand in want:
                if not cand: continue
                for kw in ({"label":cand}, {"value":cand}, {"value":cand.upper()}, {"value":cand.lower()}):
                    try: sel.select_option(**kw); return cand
                    except Exception: pass
        except Exception: continue
    return None

def tick_boxes(page):
    n = 0
    for el in page.query_selector_all("input[type=checkbox]"):
        try:
            if el.is_checked(): continue
            s = _sig(el)
            if any(k in s for k in ("term","agree","privacy","policy","accept","confirm","18","adult")):
                el.check(force=True); n += 1
        except Exception: continue
    return n

def submit(page):
    pats = ("sign up","signup","register","create account","create","join","submit","continue","next","get started","انشاء")
    for el in page.query_selector_all("button, input[type=submit], a[role=button]"):
        try:
            if not el.is_visible(): continue
            txt = ((el.inner_text() or "") + " " + (el.get_attribute("value") or "")).strip().lower()
            if any(p in txt for p in pats):
                el.click(); return txt
        except Exception: continue
    return None

def harvest(page, net):
    blob = ""
    try: blob = page.inner_text("body")
    except Exception: pass
    try:
        blob += "\n" + "\n".join((a.get_attribute("href") or "") for a in page.query_selector_all("a[href]"))
    except Exception: pass
    key = ""
    if net.get("key_regex"):
        m = re.search(net["key_regex"], blob, re.I)
        if m: key = m.group(1)
    if not key:
        m = re.search(r"(https?://[^\s\"'<>]*" + re.escape(net["id"]) + r"[^\s\"'<>]*)", blob, re.I)
        if m: key = m.group(1)
    return key, blob

def record(net, status, key="", note=""):
    d = core.load(REGS, {})
    d[net["id"]] = {"name": net["name"], "status": status, "key": key,
                    "note": note, "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save(REGS, d)

def register(net_id, headless=True, dry=False):
    from playwright.sync_api import sync_playwright
    net = by_id(net_id)
    profile = core.load("data/profile.json")
    if not profile.get("password"):
        profile["password"] = core.genpass(); core.save("data/profile.json", profile)

    core.log(f"▶ {net['name']} — {net['signup']}", "info")
    if dry:
        print(f"  الحقول ستُعبأ: email/password/name/site/country")
        print(f"  نوع التحقق: {net['verify']} | كابتشا: {net['captcha']} | حد السحب: ${net['payout_min']}")
        return True

    with sync_playwright() as pw:
        b = browser.launch(pw, headless=headless)
        ctx, page = browser.new_page(b, str(STATE / f"{net['id']}.json"))
        try:
            page.goto(net["signup"], wait_until="domcontentloaded", timeout=70000)
            page.wait_for_timeout(3000)
            core.log(f"الصفحة: {page.title()[:60]}", "info")

            for step in range(3):
                f = autofill(page, profile)
                c = pick_country(page, profile)
                t = tick_boxes(page)
                core.log(f"خطوة {step+1}: حقول={len(f)} بلد={c or '-'} موافقات={t}", "ok")
                btn = submit(page)
                if not btn: core.log("لم يُعثر على زر الإرسال", "warn"); break
                core.log(f"إرسال عبر: {btn}", "info")
                try: page.wait_for_load_state("networkidle", timeout=40000)
                except Exception: pass
                page.wait_for_timeout(3500)
                if "signup" not in page.url.lower() and "register" not in page.url.lower():
                    break

            # كابتشا
            if net.get("captcha") and captcha.key():
                try:
                    sk = page.get_attribute("div.g-recaptcha", "data-sitekey")
                    if sk:
                        core.log("حل الكابتشا...", "info")
                        captcha.inject(page, captcha.solve_recaptcha(sk, page.url))
                except Exception: pass

            key, blob = harvest(page, net)

            # تأكيد البريد
            if net["verify"] == "email" and mailbox.configured():
                core.log("فحص بريد التحقق...", "info")
                if mailbox.confirm(net["id"]): record(net, "confirmed", key)

            if key:
                core.set_env(net["key_env"], key)
                core.log(f"✓ مفتاح {net['key_env']} = {key}", "ok")
                core.clipset(key)
                record(net, "registered", key)
            else:
                core.log("لم يُعثر على المفتاح — انسخه يدوياً بـ: agent key <id>", "warn")
                record(net, "pending_key")

            browser.save_session(ctx, str(STATE / f"{net['id']}.json"))
            core.log(f"✓ جلسة {net['name']} محفوظة", "ok")
            return bool(key)
        except Exception as e:
            core.log(f"خطأ: {e}", "err"); record(net, "error", note=str(e)); return False
        finally:
            try: b.close()
            except Exception: pass

def login(net_id, headless=True):
    from playwright.sync_api import sync_playwright
    net = by_id(net_id)
    with sync_playwright() as pw:
        b = browser.launch(pw, headless=headless)
        ctx, page = browser.new_page(b, str(STATE / f"{net['id']}.json"))
        try:
            page.goto(net["login"], wait_until="domcontentloaded", timeout=70000)
            page.wait_for_timeout(3000)
            autofill(page, core.load("data/profile.json")); submit(page)
            page.wait_for_timeout(4000)
            core.log(f"الحالة: {page.url}", "info")
            browser.save_session(ctx, str(STATE / f"{net['id']}.json"))
        finally: b.close()

def batch(ids, headless=True):
    ok = 0
    for i in ids:
        try:
            if register(i, headless=headless): ok += 1
        except Exception as e: core.log(f"{i}: {e}", "err")
    core.log(f"النتيجة: {ok}/{len(ids)}", "ok" if ok else "warn")
PYEOF

# ============ tools/ledger.py ============
cat > tools/ledger.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""دفتر الأرباح والسحوبات"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
from registry import by_id

L = core.DATA / "ledger.json"

def _d(): return core.load(L, {"entries": []})

def add(site_id, amount, kind="earning", currency="USD", note=""):
    d = _d()
    d["entries"].append({"site": site_id, "amount": float(amount), "kind": kind,
                         "currency": currency, "note": note,
                         "at": time.strftime("%Y-%m-%d %H:%M:%S")})
    core.save(L, d)
    core.log(f"{'ربح' if kind=='earning' else 'سحب'}: {site_id} = {amount} {currency}", "ok")

def balances():
    d = _d(); b = {}
    for e in d["entries"]:
        b.setdefault(e["site"], 0.0)
        b[e["site"]] += e["amount"] if e["kind"] == "earning" else -abs(e["amount"])
    return b

def total():
    return sum(balances().values())

def report():
    b = balances()
    if not b: core.log("لا توجد أرباح مسجّلة بعد", "warn"); return
    print(f"\n{'المصدر':<24}{'الرصيد':>10}{'الحد':>8}  الحالة")
    print("-"*60)
    for s, v in sorted(b.items(), key=lambda x: -x[1]):
        try: mn = by_id(s)["payout_min"]
        except Exception: mn = 0
        st = "✓ جاهز للسحب" if v >= mn else f"يحتاج ${mn-v:.2f}"
        print(f"{s:<24}{'$'+format(v,'.2f'):>10}{'$'+str(mn):>8}  {st}")
    print("-"*60)
    print(f"{'الإجمالي':<24}{'$'+format(total(),'.2f'):>10}")
PYEOF

# ============ tools/payout.py ============
cat > tools/payout.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""محرّك السحب الحقيقي — يجهّز كل موقع جاهز للسحب"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ledger
from registry import by_id

P = core.DATA / "payouts.json"
DEFAULT = {"wallets": {"USDT_TRC20":"","USDT_ERC20":"","BTC":"","ETH":"","PAYPAL":"","PAYONEER":"","PAYEER":"","WISE":"","SKRILL":"","BANK_IBAN":""},
           "preferred": ["USDT_TRC20","PAYPAL","PAYONEER"]}

def cfg():
    d = core.load(P, None)
    if not d:
        core.save(P, DEFAULT); return DEFAULT
    return d

def wallet():
    w = cfg()["wallets"]
    print("\nالمحافظ المُسجّلة:")
    for k, v in w.items():
        print(f"  {k:<12} {'✓ '+v if v else '✗ فارغة'}")
    print(f"\nللتعديل: python3 tools/agent.py wallet <الاسم> <القيمة>")

def set_wallet(name, value):
    d = cfg(); d["wallets"][name.upper()] = value
    core.save(P, d); core.log(f"{name.upper()} = {value}", "ok")

def ready():
    b = ledger.balances(); out = []
    for s, v in b.items():
        try: mn = by_id(s)["payout_min"]
        except Exception: continue
        if v >= mn: out.append((s, v, mn))
    return out

def plan():
    r = ready()
    if not r: core.log("لا يوجد رصيد كافٍ للسحب بعد", "warn"); ledger.report(); return
    w = cfg()["wallets"]
    print(f"\n{'='*64}\n  خطة السحب — {len(r)} موقع جاهز\n{'='*64}")
    for s, v, mn in sorted(r, key=lambda x: -x[1]):
        n = by_id(s)
        meth = [m for m in n["methods"] if w.get(m.upper().replace(" ","_"))]
        print(f"\n▶ {n['name']}  (${v:.2f})")
        print(f"  الصفحة: {n['payout_page']}")
        print(f"  الطرق المتاحة: {', '.join(n['methods'])}")
        print(f"  الأنسب لك: {', '.join(meth) if meth else 'أضف محفظة أولاً'}")
    print(f"\n{'='*64}\n  الإجمالي القابل للسحب: ${sum(x[1] for x in r):.2f}\n{'='*64}")
    core.openurl(r[0][0] and by_id(r[0][0])["payout_page"])

def auto_open():
    for s, v, mn in ready():
        core.openurl(by_id(s)["payout_page"])
PYEOF

# ============ tools/agent.py ============
cat > tools/agent.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub Agent v4 — وكيل تنفيذي حقيقي"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, payout, mailbox

def banner():
    print(f"""{core.C['b']}{core.C['info']}
╔══════════════════════════════════════════════════════════════╗
║          🤖 CineHub Agent v4 — وكيل تنفيذي                   ║
║   تسجيل تلقائي • حصاد مفاتيح • تتبّع أرباح • سحب حقيقي       ║
╚══════════════════════════════════════════════════════════════╝{core.C['x']}""")

def usage():
    banner()
    print("""
الأوامر:
  list [cat]              عرض المصادر (ads|affiliate|tasks|crypto|freelance)
  pending                 المصادر التي لا تملك مفتاحها بعد
  reg <id> [--headful]    تسجيل تلقائي حقيقي في موقع
  reg --dry <id>          معاينة دون تنفيذ
  login <id>              فتح جلسة محفوظة
  batch <id1> <id2> ...   تسجيل جماعي
  key <id> [value]        عرض/تعيين مفتاح
  confirm <id>            تأكيد البريد تلقائياً
  earn <id> <مبلغ> [note] تسجيل ربح
  spend <id> <مبلغ> [note]تسجيل سحب
  ledger                  تقرير الأرباح
  payout                  خطة السحب الجاهزة
  wallet [name value]     إدارة المحافظ
  status                  حالة النظام
  doctor                  فحص شامل
  auto                    تسجيل في كل المصادر بالدور
""")

def cmd_list(cat=None):
    for c, name in registry.CATS.items():
        if cat and c != cat: continue
        items = registry.by_cat(c)
        print(f"\n{core.C['b']}{name} ({len(items)}){core.C['x']}")
        for n in items:
            mark = core.C['ok']+"✓"+core.C['x'] if n["key_env"] and core.env(n["key_env"]) else " "
            print(f"  {mark} {n['id']:<16} {n['name']:<24} حد ${n['payout_min']:<5} {n['verify']}")

def cmd_status():
    core.log(f"المصادر: {len(registry.ALL)} | بمفاتيح: {len(registry.with_key())} | بلا مفاتيح: {len(registry.pending())}", "info")
    core.log(f"البريد التلقائي: {'مُفعّل' if mailbox.configured() else 'غير مُفعّل (أضف MAIL_APP_PASS)'}", "ok" if mailbox.configured() else "warn")
    core.log(f"الكابتشا: {'مُفعّلة' if core.env('CAPTCHA_KEY') else 'غير مُفعّلة (اختياري)'}", "info")
    core.log(f"الرصيد المُسجّل: ${ledger.total():.2f}", "ok")
    p = registry.pending()
    if p: print("\nالمصادر التالية للتنفيذ:"); print("  " + " ".join(n["id"] for n in p[:12]))

def main():
    a = sys.argv[1:]
    if not a: usage(); return
    c = a[0]
    if c == "list": cmd_list(a[1] if len(a)>1 else None)
    elif c == "status": cmd_status()
    elif c == "pending":
        for n in registry.pending(): print(f"  {n['id']:<16} {n['name']}")
    elif c == "reg":
        dry = "--dry" in a; head = "--headful" in a
        ids = [x for x in a[1:] if not x.startswith("--")]
        import autoreg
        for i in ids: autoreg.register(i, headless=not head, dry=dry)
    elif c == "login":
        import autoreg; autoreg.login(a[1], headless="--headful" not in a)
    elif c == "batch":
        import autoreg; autoreg.batch(a[1:])
    elif c == "auto":
        import autoreg
        ids = [n["id"] for n in registry.pending()][:10]
        core.log(f"تشغيل تلقائي على {len(ids)} مصدر", "info"); autoreg.batch(ids)
    elif c == "key":
        if len(a) >= 3:
            n = registry.by_id(a[1]); core.set_env(n["key_env"], a[2]); core.log(f"{n['key_env']} = {a[2]}", "ok")
        else:
            n = registry.by_id(a[1]); print(core.env(n["key_env"]) or "—")
    elif c == "confirm":
        n = registry.by_id(a[1]); mailbox.confirm(n["id"])
    elif c == "earn": ledger.add(a[1], a[2], "earning", note=" ".join(a[3:]))
    elif c == "spend": ledger.add(a[1], a[2], "withdraw", note=" ".join(a[3:]))
    elif c == "ledger": ledger.report()
    elif c == "payout": payout.plan()
    elif c == "wallet":
        if len(a) >= 3: payout.set_wallet(a[1], a[2])
        else: payout.wallet()
    elif c == "doctor":
        import doctor; doctor.main()
    else: usage()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print(f"\n{core.C['warn']}أُوقف{core.C['x']}")
    except KeyError as e: print(f"{core.C['err']}{e}{core.C['x']}")
PYEOF

# ============ tools/doctor.py ============
cat > tools/doctor.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل محصّن"""
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger

CRIT = ["tools/core.py","tools/registry.py","tools/agent.py","tools/autoreg.py",
        "tools/browser.py","tools/ledger.py","tools/payout.py","tools/mailbox.py",
        "data/profile.json","keys.env"]
DEPS = {"requests":"requests","bs4":"beautifulsoup4","lxml":"lxml","playwright":"playwright"}

def main():
    print(f"{core.C['b']}{core.C['info']}\n══ CineHub Doctor v4 ══{core.C['x']}")
    miss, brok, dep_miss = [], [], []

    print(f"\n{core.C['b']}الملفات:{core.C['x']}")
    for f in CRIT:
        p = core.BASE / f
        if not p.exists(): core.log(f"مفقود: {f}", "err"); miss.append(f)
        elif f.endswith(".py"):
            r = subprocess.run([sys.executable, "-m", "py_compile", str(p)], capture_output=True)
            if r.returncode: core.log(f"مكسور: {f}", "err"); brok.append(f)
            else: core.log(f"سليم: {f}", "ok")
        else: core.log(f"موجود: {f}", "ok")

    print(f"\n{core.C['b']}الاعتماديات:{core.C['x']}")
    for mod, pkg in DEPS.items():
        if importlib.util.find_spec(mod): core.log(f"{pkg} مثبّت", "ok")
        else: core.log(f"{pkg} مفقود", "err"); dep_miss.append(pkg)

    print(f"\n{core.C['b']}المصادر:{core.C['x']}")
    core.log(f"مسجّل: {len(registry.ALL)} مصدر | بمفاتيح: {len(registry.with_key())}", "ok")
    core.log(f"الرصيد: ${ledger.total():.2f}", "info")

    print(f"\n{core.C['b']}الملخص:{core.C['x']}")
    core.log(f"مفقودة={len(miss)} مكسورة={len(brok)} اعتماديات={len(dep_miss)}", "warn" if (miss or brok or dep_miss) else "ok")
    if dep_miss:
        print(f"\n  نفّذ: pkg install python-pip chromium && pip install {' '.join(dep_miss)}")
    if not miss and not brok:
        core.log("النظام سليم — جاهز للتنفيذ الحقيقي", "ok")
    return 0 if not (miss or brok) else 2

if __name__ == "__main__": sys.exit(main())
PYEOF

# ============ البيانات ============
if [ ! -f data/profile.json ]; then
cat > data/profile.json << 'JSONEOF'
{
  "first": "Ali", "last": "Salim", "username": "alisalimax3",
  "email": "alkazmybwhwr@gmail.com", "password": "",
  "country": "MA", "country_name": "Morocco",
  "city": "Casablanca", "zip": "20250",
  "address": "Rue 12, Hay Hassani", "phone": "+212600000000",
  "company": "CineHub", "telegram": "",
  "site": "https://alisalimax3.github.io"
}
JSONEOF
fi

python3 - << 'PYEOF'
import json, sys, os
sys.path.insert(0, "tools")
import core
p = core.load("data/profile.json")
if not p.get("password"):
    p["password"] = core.genpass(18); core.save("data/profile.json", p)
    print(f"كلمة مرور مُولّدة: {p['password']}")
PYEOF

# مفاتيح البيئة
touch keys.env
grep -q "^GITHUB_USER=" keys.env || echo "GITHUB_USER=alisalimax3" >> keys.env
grep -q "^SITE_URL=" keys.env || echo "SITE_URL=https://alisalimax3.github.io" >> keys.env
grep -q "^MAIL_USER=" keys.env || echo "MAIL_USER=alkazmybwhwr@gmail.com" >> keys.env
grep -q "^MAIL_IMAP_HOST=" keys.env || echo "MAIL_IMAP_HOST=imap.gmail.com" >> keys.env
grep -q "^MAIL_APP_PASS=" keys.env || echo "MAIL_APP_PASS=" >> keys.env
grep -q "^CAPTCHA_KEY=" keys.env || echo "CAPTCHA_KEY=" >> keys.env

cat > run.sh << 'SHEOF2'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"
exec python3 tools/agent.py "$@"
SHEOF2
chmod +x run.sh

echo ""
echo "✅ اكتمل التثبيت"
python3 tools/doctor.py
