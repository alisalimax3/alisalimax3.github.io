#!/data/data/com.termux/files/usr/bin/bash
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p backups logs/shots

echo "══ 0. نسخة احتياطية ══"
tar czf "backups/pre_v7_$(date +%s).tgz" tools data keys.env 2>/dev/null; echo "✓"

echo "══ 1. تنظيف keys.env من القيم المسرّبة ══"
python3 - << 'PY'
import re
p = "keys.env"
bad_vals = {"install_requirements","python3","pip","true",""}
keep = {}
for line in open(p, encoding="utf-8"):
    line = line.rstrip("\n")
    if not line.strip() or line.strip().startswith("#"): continue
    if "=" not in line: continue
    k, v = line.split("=", 1)
    k, v = k.strip(), v.strip()
    if k in ("ADSTERRA_API_KEY","OMDB_API_KEY") and v in bad_vals:
        print("حُذف: %s=%s" % (k,v)); continue
    keep[k] = v
# MAIL_APP_PASS: إن كان placeholder جرّب البديل
mp = keep.get("MAIL_APP_PASS","")
if (not mp) or set(mp) == {"x"} or len(mp) < 12:
    alt = keep.get("GMAIL_APP_PASSWORD","")
    if alt:
        keep["MAIL_APP_PASS"] = alt.replace(" ","")
        print("استُخدم بديل: GMAIL_APP_PASSWORD")
keep.setdefault("MAIL_IMAP_HOST","imap.gmail.com")
keep.setdefault("MAIL_USER","alkazmybwhwr@gmail.com")
keep.setdefault("GITHUB_USER","alisalimax3")
keep.setdefault("SITE_URL","https://alisalimax3.github.io")
keep.setdefault("CAPTCHA_KEY","")
keep.setdefault("BROWSER_PROXY","")
with open(p,"w",encoding="utf-8") as f:
    for k,v in keep.items(): f.write("%s=%s\n" % (k,v))
print("✓ keys.env نظيف (%d مفتاح)" % len(keep))
PY

echo "══ 2. إصلاح cdp: كشف X حقيقي + fallback تلقائي ══"
python3 - << 'PY'
p = "tools/cdp.py"
s = open(p, encoding="utf-8").read()

s = s.replace('def x11(): return bool(os.environ.get("DISPLAY"))',
'''def x11_alive():
    """هل خادم X يعمل فعلاً؟ DISPLAY وحده لا يكفي."""
    if not os.environ.get("DISPLAY"): return False
    for p in ("/data/data/com.termux/files/usr/tmp/.X11-unix/X0",
              "/tmp/.X11-unix/X0","/data/data/com.termux/files/usr/tmp/.X11-unix/X1"):
        if os.path.exists(p): return True
    try:
        subprocess.check_output(["pgrep","-f","termux-x11"], stderr=subprocess.DEVNULL)
        return True
    except Exception: return False

def x11(): return bool(os.environ.get("DISPLAY"))''')

s = s.replace('''        self.logp = os.path.join(profile_dir, "chromium.log")
        self.lf = open(self.logp, "ab")
        self.proc = subprocess.Popen(a, stdout=self.lf, stderr=self.lf,
                                     stdin=subprocess.DEVNULL, start_new_session=True)
        self._wait(timeout)''',
'''        self.logp = os.path.join(profile_dir, "chromium.log")
        self.headless = headless
        self._argv_base = a
        self._launch(headless)
        try:
            self._wait(timeout)
        except RuntimeError:
            if not headless:
                core.log("الوضع المرئي فشل — أُعيد التشغيل headless تلقائياً", "warn")
                try: self.proc.kill()
                except Exception: pass
                time.sleep(1)
                self._launch(True); self.headless = True
                self._wait(timeout)
            else: raise

    def _launch(self, headless):
        a = list(self._argv_base)
        if headless: a.append("--headless=new")
        self.lf = open(self.logp, "ab")
        self.proc = subprocess.Popen(a, stdout=self.lf, stderr=self.lf,
                                     stdin=subprocess.DEVNULL, start_new_session=True)''')
open(p,"w",encoding="utf-8").write(s)
print("✓ cdp محصّن")
PY

echo "══ 3. autoreg: تجربة روابط بديلة + كشف X حقيقي ══"
python3 - << 'PY'
p = "tools/autoreg.py"
s = open(p, encoding="utf-8").read()
s = s.replace('    headless = not (show and cdp.x11())\n    if show and not cdp.x11():\n        core.log("DISPLAY غير موجود — سيعمل headless. راجع قسم X11.", "warn")',
'''    live_x = cdp.x11_alive()
    headless = not (show and live_x)
    if show and not live_x:
        core.log("X غير شغّال — headless. للتفعيل: termux-x11 :0 -ac &", "warn")''')

s = s.replace('''        tab = ch.tab()
        ok = tab.go(net["signup"], timeout=60)
        if not ok:
            core.log("فشل تحميل %s — تشخيص:" % net["signup"], "err")
            core.log("  العنوان الحالي: %s" % (tab.url() or "فارغ"), "err")
            tab.dump(net_id + "_fail")
            record(net, "nav_failed", note=tab.url())
            return False
        tab.ev("window.__ch && window.__ch.cookies()")
        core.log("الصفحة: %s" % (tab.title() or "(بلا عنوان)")[:70], "info")
        core.log("الحقول المرئية: %d" % len([f for f in (tab.ev("window.__ch.scan()") or []) if f.get("vis")]), "info")''',
'''        tab = ch.tab()
        import registry as _rg
        ok = False
        for url in _rg.candidates(net):
            core.log("محاولة: %s" % url, "info")
            if not tab.go(url, timeout=50):
                core.log("لم يُحمّل — بديل", "warn"); continue
            vis = [f for f in (tab.ev("window.__ch.scan()") or []) if f.get("vis")]
            if len(vis) >= 1:
                ok = True
                core.log("✓ %s | %d حقل مرئي" % ((tab.title() or "?")[:50], len(vis)), "ok")
                break
            core.log("صفحة بلا حقول — بديل", "warn")
        if not ok:
            core.log("كل الروابط فشلت لـ %s" % net["name"], "err")
            tab.dump(net_id + "_fail"); record(net, "nav_failed"); return False
        tab.ev("window.__ch && window.__ch.cookies()")''')
open(p,"w",encoding="utf-8").write(s)
print("✓ autoreg")
PY

echo "══ 4. registry: روابط بديلة مصحّحة ══"
python3 - << 'PY'
p = "tools/registry.py"
s = open(p, encoding="utf-8").read()
if "ALTS = {" not in s:
    s = s.replace('BY_ID = {n["id"]: n for n in ALL}',
'''# روابط بديلة إن تغيّر الرابط الرسمي
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

BY_ID = {n["id"]: n for n in ALL}''')
open(p,"w",encoding="utf-8").write(s)
print("✓ registry + بدائل")
PY

echo "══ 5. إعادة كتابة audit.py بلا خطأ and/or ══"
cat > tools/audit.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل حقيقي — بلا منطق and/or الخاطئ"""
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, mailbox, cdp

OK, BAD, WARN = [], [], []
def h(t): print("\n%s%s══ %s ══%s" % (core.C['b'], core.C['info'], t, core.C['x']))
def good(m): OK.append(m); core.log(m, "ok")
def bad(m):  BAD.append(m); core.log(m, "err")
def warn(m): WARN.append(m); core.log(m, "warn")
def check(cond, okmsg, badmsg):
    if cond: good(okmsg)
    else: bad(badmsg)

def main():
    print("%s%s\n╔══════════════════════════════════════════════════════════╗"
          "\n║        🔬 CineHub — فحص شامل حقيقي v7                    ║"
          "\n╚══════════════════════════════════════════════════════════╝%s" % (core.C['b'], core.C['info'], core.C['x']))

    h("1. بنية المشروع")
    for d in ("tools","data","logs","assets","content"):
        check((core.BASE/d).is_dir(), "مجلد: %s" % d, "مفقود: %s" % d)
    for f in ("core.py","cdp.py","inject.js","registry.py","autoreg.py","agent.py",
              "ledger.py","payout.py","mailbox.py","doctor.py","audit.py"):
        p = core.BASE/"tools"/f
        if not p.exists(): bad("مفقود: tools/%s" % f); continue
        if f.endswith(".py"):
            r = subprocess.run([sys.executable,"-m","py_compile",str(p)], capture_output=True)
            check(not r.returncode, "سليم: tools/%s" % f, "مكسور: tools/%s" % f)
        else: good("موجود: tools/%s" % f)

    h("2. الاعتماديات")
    for mod, pkg in {"websocket":"websocket-client","requests":"requests","bs4":"beautifulsoup4","lxml":"lxml"}.items():
        check(importlib.util.find_spec(mod) is not None, "%s مثبّت" % pkg, "%s مفقود → pip install %s" % (pkg, pkg))

    h("3. المتصفح")
    exe = cdp.find_chromium()
    if not exe: bad("chromium غير مثبت → pkg install chromium")
    else: good("chromium: %s" % cdp.version())

    h("4. الشاشة")
    if cdp.x11_alive(): good("خادم X يعمل — الوضع المرئي متاح")
    elif cdp.x11():
        warn("DISPLAY=%s مضبوط لكن X لا يعمل" % core.env("DISPLAY"))
        print("    شغّل: termux-x11 :0 -ac &")
        print("    ثم:   am start --user 0 -n com.termux.x11/.MainActivity")
    else: warn("DISPLAY غير مضبوط — headless فقط (يعمل بلا مشاكل)")

    h("5. الهوية")
    pr = core.load("data/profile.json")
    for k in ("first","last","username","email","country","site"):
        check(bool(pr.get(k)), "%s = %s" % (k, pr.get(k,"")), "ناقص: %s" % k)
    check(bool(pr.get("password")), "كلمة المرور جاهزة", "لا كلمة مرور")

    h("6. المفاتيح")
    kv = {}
    if core.ENV_FILE.exists():
        for line in core.ENV_FILE.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.strip().startswith("#"):
                k,v = line.split("=",1); kv[k.strip()] = v.strip()
    junk = [k for k,v in kv.items() if v in ("install_requirements","python3","pip")]
    check(not junk, "keys.env نظيف", "قيم مسرّبة: %s" % ", ".join(junk))
    mp = kv.get("MAIL_APP_PASS","")
    check(len(mp.replace(" ","")) == 16, "MAIL_APP_PASS بطول صحيح (16)", "MAIL_APP_PASS طوله %d — الصحيح 16 حرفاً" % len(mp.replace(" ","")))
    check(bool(kv.get("CAPTCHA_KEY")), "CAPTCHA_KEY موجود", "CAPTCHA_KEY فارغ (اختياري لكن يفيد)")
    good("مصادر بمفاتيح: %d/%d" % (len(registry.with_key()), len(registry.ALL)))

    h("7. البريد التلقائي")
    okm, msg = mailbox.test()
    if okm: good(msg)
    else:
        bad(msg)
        print("    → https://myaccount.google.com/apppasswords")
        print("    → ./run.sh setenv MAIL_APP_PASS <16 حرفاً بلا مسافات>")

    h("8. الروابط الأساسية")
    for url in ("https://monetag.com","https://publishers.adsterra.com/signup",
                "https://www.popads.net/users/register","https://freecash.com"):
        r = core.http(url, timeout=15, headers={"User-Agent": core.UA, "Accept":"text/html"})
        code = r.get("code") or 0
        check(r.get("ok") and code < 400, "%s → %s" % (url.split("//")[1][:34], code),
              "%s → %s" % (url.split("//")[1][:34], r.get("err") or code))

    h("9. اختبار متصفح حقيقي")
    try:
        ch = cdp.Chrome(str(core.DATA/"profiles"/"_audit"), headless=True, timeout=45)
        try:
            t = ch.tab()
            check(t.go("https://example.com", timeout=35),
                  "تصفح ناجح — %s" % (t.title() or "?"), "فشل التصفح")
            check(t.ev("typeof window.__ch!=='undefined'") is True, "المحقون __ch نشط", "المحقون __ch غائب")
        finally: ch.close()
    except Exception as e: bad("تعذّر التشغيل: %s" % e)

    h("10. الأرباح")
    b = ledger.balances()
    good("قيود: %d | الإجمالي: $%.2f" % (len(ledger._d()["entries"]), ledger.total()))
    for s,v in sorted(b.items(), key=lambda x:-x[1])[:10]: print("    %-16s $%.2f" % (s, v))

    h("الخلاصة")
    core.log("ناجح: %d | تحذير: %d | عطل: %d" % (len(OK), len(WARN), len(BAD)),
             "err" if BAD else ("warn" if WARN else "ok"))
    if BAD:
        print("\n%sيجب إصلاح:%s" % (core.C['err'], core.C['x']))
        for i,m in enumerate(BAD,1): print("  %d. %s" % (i,m))
    if WARN:
        print("\n%sاختياري:%s" % (core.C['warn'], core.C['x']))
        for i,m in enumerate(WARN,1): print("  %d. %s" % (i,m))
    if not BAD and not WARN: print("\n%sالنظام كامل وجاهز.%s" % (core.C['ok'], core.C['x']))
    return 0 if not BAD else 2

if __name__ == "__main__": sys.exit(main())
PYEOF

echo "══ 6. أمر checkurls: اختبار 40 رابط حقيقي ══"
cat > tools/checkurls.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يختبر كل روابط التسجيل بمتصفح حقيقي ويكشف العامل منها"""
import sys, time, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, cdp

def main():
    only = sys.argv[1:] or [n["id"] for n in registry.ALL]
    core.log("اختبار %d مصدر بمتصفح حقيقي..." % len(only), "info")
    ch = cdp.Chrome(str(core.DATA/"profiles"/"_check"), headless=True, timeout=45)
    live, dead = [], []
    try:
        tab = ch.tab()
        for i, nid in enumerate(only, 1):
            net = registry.by_id(nid)
            hit = ""
            for url in registry.candidates(net):
                try:
                    if not tab.go(url, timeout=30): continue
                    vis = [f for f in (tab.ev("window.__ch.scan()") or []) if f.get("vis")]
                    if vis:
                        hit = "%s | %d حقل | %s" % (url, len(vis), (tab.title() or "?")[:40]); break
                except Exception: continue
            if hit: live.append((nid, hit)); core.log("[%d/%d] ✓ %s" % (i,len(only),hit), "ok")
            else:
                dead.append(nid); core.log("[%d/%d] ✗ %s — كل البدائل فشلت" % (i,len(only),net["name"]), "err")
            time.sleep(0.4)
    finally: ch.close()
    core.save("data/urls_status.json", {"live": [l[0] for l in live], "dead": dead,
                                        "at": time.strftime("%Y-%m-%d %H:%M")})
    print("\n%s%s══ النتيجة ══%s" % (core.C['b'], core.C['info'], core.C['x']))
    core.log("روابط عاملة: %d/%d" % (len(live), len(only)), "ok" if live else "warn")
    if dead: core.log("تحتاج مراجعة: %s" % ", ".join(dead), "warn")
    core.save("data/urls_live.json", {"live": [l[0] for l in live]})

if __name__ == "__main__": main()
PYEOF

echo "══ 7. ربط الأوامر ══"
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
if 'c == "checkurls"' not in s:
    s = s.replace('    elif c == "audit":',
'''    elif c == "checkurls":
        import checkurls; checkurls.main()
    elif c == "audit":''')
    s = s.replace('  audit                   فحص شامل حقيقي',
                  '  audit                   فحص شامل حقيقي\n  checkurls [id...]       اختبار روابط التسجيل بمتصفح حقيقي')
    open(p,"w",encoding="utf-8").write(s)
print("✓ agent")
PY

echo "══ 8. تثبيت إصلاح الروابط المعروفة ══"
python3 - << 'PY'
import re
p = "tools/registry.py"
s = open(p, encoding="utf-8").read()
s = s.replace('"https://publishers.adsterra.com/register"', '"https://publishers.adsterra.com/signup"')
s = s.replace('"https://picoworkers.com/register.php"', '"https://picoworkers.com/register"')
open(p,"w",encoding="utf-8").write(s)
print("✓ روابط مُصحّحة")
PY

echo "══ 9. اختبار ══"
python3 -m py_compile tools/*.py && echo "✓ كل الملفات تُترجم"
echo ""
echo "✅ v7 جاهز"
