#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تسجيل تلقائي حقيقي — تعبئة + نقر كابتشا + تأكيد بريد + حصاد"""
from __future__ import annotations
import json, os, re, select, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, cdp, mailbox, captcha, registry
from registry import by_id

REGS = core.DATA / "registrations.json"
KEYMAP = [ (("confirm","retype","repeat","again"),"password"), (("email","e-mail","mail"),"email"),
 (("password","passwd","pass"),"password"), (("first","given","fname"),"first"),
 (("last","family","surname","lname"),"last"), (("username","nick","login","handle"),"username"),
 (("full","displayname","realname","name"),"fullname"), (("website","site","domain","url"),"site"),
 (("phone","mobile","tel","whatsapp"),"phone"), (("company","organization","org","business"),"company"),
 (("city","town"),"city"), (("zip","postal","postcode"),"zip"), (("address","street","addr"),"address"),
 (("telegram","skype"),"telegram") ]

def _vals(p):
    return {"email":p.get("email",""),"password":p.get("password",""),"first":p.get("first",""),
            "last":p.get("last",""),"fullname":("%s %s"%(p.get("first",""),p.get("last",""))).strip(),
            "username":p.get("username",""),"site":p.get("site",""),"phone":p.get("phone",""),
            "company":p.get("company",""),"city":p.get("city",""),"zip":p.get("zip",""),
            "address":p.get("address",""),"telegram":p.get("telegram","")}

def _match(sig, t):
    if t=="email": return "email"
    if t=="password": return "password"
    if t=="tel": return "phone"
    for words, f in KEYMAP:
        for w in words:
            if w in sig: return f
    return ""

def wait_fields(tab, timeout=30):
    """ينتظر ظهور حقول فعلية — للمواقع التي تبني نموذجها بـJS"""
    end = time.time()+timeout
    while time.time() < end:
        try:
            vis = [f for f in (tab.ev("window.__ch.scanAll()") or []) if f.get("vis")]
            if vis: return len(vis)
        except Exception: pass
        time.sleep(1.0)
    return 0

def fill(tab, profile):
    vals=_vals(profile); n=0
    for f in (tab.ev("window.__ch.scanAll()") or []):
        if not f.get("vis"): continue
        t=f.get("type","")
        if t in ("hidden","submit","button","file","image","reset","search","checkbox","radio"): continue
        if (f.get("val") or "").strip(): continue
        fld=_match(f.get("sig",""), t)
        if not fld or not vals.get(fld): continue
        try:
            if tab.ev("window.__ch.putF(%d,%d,%s)" % (f.get("fr",0), f["i"], json.dumps(str(vals[fld])))): n+=1
        except Exception: continue
    return n

def pick_country(tab, profile):
    want=[profile.get("country_name",""), profile.get("country","")]
    for f in (tab.ev("window.__ch.scanAll()") or []):
        if f.get("tag")!="select": continue
        s=f.get("sig","")
        if not any(k in s for k in ("country","nation","pays")): continue
        for c in want:
            if not c: continue
            try:
                r=tab.ev("window.__ch.putSelF(%d,%d,%s)" % (f.get("fr",0), f["i"], json.dumps(c)))
                if r: return r
            except Exception: pass
    return None

def tick(tab):
    n=0
    for f in (tab.ev("window.__ch.scanAll()") or []):
        if f.get("type")!="checkbox" or not f.get("vis") or f.get("checked"): continue
        if any(k in f.get("sig","") for k in ("term","agree","privacy","policy","accept","confirm","18","adult")):
            try:
                if tab.ev("window.__ch.checkF(%d,%d)" % (f.get("fr",0), f["i"])): n+=1
            except Exception: pass
    return n

def try_click_captcha(tab, rounds=4):
    """نقر حقيقي بإزاحات متعددة — يغطي كل أشكال الكابتشا"""
    for r in range(rounds):
        try: st = tab.ev("window.__ch.captcha()")
        except Exception: st = ""
        if not st: return False
        if st.endswith("-solved"): return True
        try: b = tab.ev("window.__ch.captchaBox()")
        except Exception: b = None
        if not b:
            time.sleep(1.2); continue
        try: tab.send("Page.bringToFront")
        except Exception: pass
        for dx, dy in ((0,0), (2,-3), (-2,2), (0,4)):
            try: tab.click_xy(b["x"]+dx, b["y"]+dy)
            except Exception: pass
            time.sleep(1.1)
            try: st = tab.ev("window.__ch.captcha()")
            except Exception: st = ""
            if st and st.endswith("-solved"):
                core.log("✓ كابتشا حُلّت آلياً", "ok"); return True
        core.log("محاولة كابتشا " + str(r+1) + "/" + str(rounds) + " — لم تُحل بعد", "info")
        time.sleep(2.5)
    return False

def wait_captcha(tab, timeout=240):
    end=time.time()+timeout; last=0
    while time.time()<end:
        try: st=tab.ev("window.__ch.captcha()")
        except Exception: st=""
        if st and st.endswith("-solved"): core.log("✓ حُلّت","ok"); return True
        if time.time()-last>8: core.log("⏳ اضغط «أنا لست روبوت» على الشاشة...","warn"); last=time.time()
        time.sleep(0.8)
    return False

def harvest(tab, net):
    blob=tab.text(20000)
    try:
        blob += "\n" + (tab.ev("Array.prototype.map.call(document.querySelectorAll('a[href]'),function(a){return a.href;}).join(String.fromCharCode(10))") or "")
    except Exception: pass
    key=""
    if net.get("key_regex"):
        m=re.search(net["key_regex"], blob, re.I)
        if m: key=m.group(1)
    if not key:
        m=re.search(r"(https?://[^\s\"'<>]*"+re.escape(net["id"])+r"[^\s\"'<>]*)", blob, re.I)
        if m: key=m.group(1)
    return key, blob

def record(net, status, key="", note=""):
    d=core.load(REGS, {})
    d[net["id"]]={"name":net["name"],"status":status,"key":key,"note":note,"at":time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save(REGS, d)

def success(tab, net):
    u=(tab.url() or "").lower()
    if u and not any(k in u for k in ("signup","register","sign-up","join","create")): return True
    t=tab.text(4000).lower()
    return any(k in t for k in ("verify your email","confirm your email","welcome","dashboard","check your inbox","account created","successfully"))

def register(net_id, show=False, dry=False):
    net=by_id(net_id)
    profile=core.load("data/profile.json")
    if not profile.get("password"):
        profile["password"]=core.genpass(); core.save("data/profile.json", profile)
    core.log("▶ %s — %s" % (net["name"], net["signup"]), "info")
    if dry:
        print("  حقول: email/password/name/username/site/country")
        print("  تحقق: %s | كابتشا: %s | حد: $%s" % (net["verify"], net["captcha"], net["payout_min"]))
        print("  نطاق: data/profiles/%s" % net_id); return True

    live=cdp.core.x11_alive() if hasattr(cdp,"core") else core.x11_alive()
    headless = not (show and live)
    if show and not live: core.log("X غير شغّال — headless", "warn")

    ch=cdp.Chrome(str(core.PROFILES/net_id), headless=headless, proxy=core.env("BROWSER_PROXY"))
    try:
        tab=ch.tab(); ok=False
        for url in registry.candidates(net):
            core.log("محاولة: %s" % url, "info")
            if not tab.go(url, timeout=80, retries=3): continue
            n = wait_fields(tab, 30)
            tt = (tab.title() or "").lower()
            if n and n < 3 and any(k in tt for k in ("log in","login","sign in")):
                core.log("صفحة دخول لا تسجيل — نجرّب بديلاً", "warn"); continue
            if n:
                ok=True; core.log("✓ %s | %d حقل" % ((tab.title() or "?")[:50], n), "ok"); break
            core.log("بلا حقول بعد 30 ثانية — بديل","warn")
        if not ok:
            core.log("كل الروابط فشلت","err"); tab.dump(net_id+"_fail"); record(net,"nav_failed"); return False
        tab.ev("window.__ch.cookies()")

        for step in range(1,4):
            f=fill(tab,profile); c=pick_country(tab,profile); b=tick(tab)
            core.log("خطوة %d: حقول=%d بلد=%s موافقات=%d" % (step,f,c or "-",b), "ok")
            if f==0 and step>1: break
            if tab.ev("window.__ch.captcha()")=="present" and not try_click_captcha(tab,2):
                wait_captcha(tab, 90)
            btn=tab.ev("window.__ch.submitAll()")
            if not btn: core.log("لا زر إرسال","warn"); break
            core.log("إرسال: %s" % btn, "info")
            tab.ev("window.__ch.clickBtn()"); tab.settle(20)
            time.sleep(4)
            if tab.ev("window.__ch.captcha()")=="present":
                if not try_click_captcha(tab,2): wait_captcha(tab,200)
                tab.ev("window.__ch.clickBtn()"); tab.settle(20)
            if success(tab,net): core.log("✓ نجح التسجيل","ok"); break

        tab.dump(net_id)
        key,_=harvest(tab,net)

        if net["verify"]=="email" and mailbox.configured():
            core.log("فحص بريد التحقق...","info")
            if mailbox.confirm(net["id"]):
                record(net,"confirmed",key)
                for u in (net["login"], net["payout_page"], net["signup"]):
                    if key: break
                    try:
                        tab.go(u, timeout=30); time.sleep(2)
                        k2,_=harvest(tab,net)
                        if k2: key=k2; core.log("مفتاح من اللوحة: %s" % k2,"ok")
                    except Exception: pass

        if key:
            core.set_env(net["key_env"], key); core.clipset(key)
            core.log("✓ %s = %s" % (net["key_env"], key), "ok"); record(net,"registered",key)
        else:
            core.log("لا مفتاح — ./run.sh add %s" % net_id,"warn"); record(net,"pending_key")
        return bool(key)
    except Exception as e:
        core.log("خطأ: %s" % e,"err"); record(net,"error",note=str(e)); return False
    finally: ch.close()

def batch(ids, show=False):
    ok=0
    for i in ids:
        try:
            if register(i, show=show): ok+=1
        except Exception as e: core.log("%s: %s" % (i,e),"err")
    core.log("النتيجة: %d/%d" % (ok,len(ids)), "ok" if ok else "warn")
