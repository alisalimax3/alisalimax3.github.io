#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub Agent v12 — مكتوب كاملاً بلا رقع"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger

def use():
    print("""%s
الأوامر:
  creds                   بيانات الحساب الكاملة (انسخها)
  status                  الحالة السريعة
  check                   استيراد كل الوحدات فعلياً
  lint                    فاحص صيغ %s
  selftest                اختبار فعلي للتعبئة والنقر
  mailtest                تشخيص البريد
  captchatest             تحقق من رمز الكابتشا
  audit                   فحص شامل
  table [تصنيف]           الجدول الكامل
  keys                    المفاتيح النشطة
  verify                  التحقق من صحة المفاتيح
  add <id> | --missing [cat]   إضافة مفتاح
  open <id...>            فتح رابط
  reg <id...> [--headless]     تسجيل (مرئي افتراضياً)
  batch <id...>           تسجيل جماعي
  autoflow <1..5>         تنفيذ متدرّج
  ghauth                  تفويض GitHub
  ghlink [اسم] [--pages]  ربط المستودع
  harvest [--scan] [--push]    حصاد الأرباح
  dashboard [--push]      توليد اللوحة
  earn <id> <مبلغ>        تسجيل ربح
  spend <id> <مبلغ>       تسجيل سحب
  ledger                  تقرير الأرباح
  payout                  خطة السحب
  wallet [اسم قيمة]       المحافظ
  push|pull|sync          المستودع
  watch [دقائق]           مزامنة دورية
  restart                 إعادة تشغيل نظيفة
  setenv <KEY> <value>    تعيين متغير
%s""" % (core.C['info'], core.C['x']))

def creds():
    pr = core.load("data/profile.json")
    if not pr.get("password"):
        pr["password"] = core.genpass(16); core.save("data/profile.json", pr)
    txt = """الاسم    : %s %s
المستخدم : %s
البريد   : %s
كلمة السر: %s
البلد    : %s (%s)
الهاتف   : %s
الموقع   : %s
""" % (pr.get("first",""), pr.get("last",""), pr.get("username",""), pr.get("email",""),
       pr.get("password",""), pr.get("country",""), pr.get("country_name",""),
       pr.get("phone",""), pr.get("site",""))
    print("\n%s╔══════════════════════════════════════╗" % core.C['b'])
    print("║   🔑 بيانات الحساب — استخدمها في كل تسجيل   ║")
    print("╚══════════════════════════════════════╝%s" % core.C['x'])
    print(txt)
    core.clipset(txt); core.log("نُسخت للحافظة","ok")

def main():
    a = sys.argv[1:]
    if not a: use(); return
    c = a[0]; p = [x for x in a[1:] if not x.startswith("--")]
    vis = core.x11_alive() and "--headless" not in a

    if c == "creds": creds()
    elif c == "status":
        s = registry.stats()
        core.log("مصادر=%d بمفاتيح=%d ناقص=%d | رصيد=$%.2f" % (s["total"],s["with_key"],s["pending"],ledger.total()),"info")
        core.log("بريد=%s | كابتشا=%s | عرض=%s | remote=%s" % (
            "نعم" if core.env("MAIL_APP_PASS") else "لا",
            "نعم" if core.env("CAPTCHA_KEY") else "لا",
            "مرئي" if core.x11_alive() else "headless",
            "مضبوط" if core.env("GH_REPO") else "غير مضبوط"),"info")
    elif c == "lint": import lint; sys.exit(lint.main())
    elif c == "check":
        import subprocess
        mods = "core cdp registry autoreg ledger payout mailbox captcha repo addkey watch autoflow verify_keys audit selftest mailtest ghauth ghlink captchatest harvest dashboard".split()
        bad = []
        for m in mods:
            r = subprocess.run([sys.executable,"-c","import sys;sys.path.insert(0,'tools');import %s"%m],
                               capture_output=True, text=True, cwd=str(core.BASE))
            if r.returncode:
                bad.append(m); print("  ✗ %s: %s" % (m, r.stderr.strip().splitlines()[-1][:80]))
            else: print("  ✓ %s" % m)
        core.log("سليم %d/%d" % (len(mods)-len(bad), len(mods)), "err" if bad else "ok")
    elif c == "selftest": import selftest; selftest.main()
    elif c == "mailtest": import mailtest; mailtest.main()
    elif c == "captchatest": import captchatest; captchatest.main()
    elif c == "audit": import audit; audit.main()
    elif c == "table":
        for cat,name in registry.CATS.items():
            if p and cat != p[0]: continue
            items = registry.by_cat(cat)
            if not items: continue
            print("\n%s%s (%d)%s" % (core.C['b'],name,len(items),core.C['x']))
            for n in items:
                m = core.C['ok']+"✓"+core.C['x'] if core.env(n["key_env"]) else " "
                print("  %s %-16s %-24s %-22s $%g" % (m,n["id"],n["name"][:24],n["key_env"][:22],n["payout_min"]))
    elif c == "keys":
        for n in registry.with_key(): print("  %-16s %-22s %s" % (n["id"],n["key_env"],(core.env(n["key_env"]) or "")[:44]))
        print("\n%d/%d" % (len(registry.with_key()),len(registry.ALL)))
    elif c == "verify": import verify_keys; sys.exit(verify_keys.main())
    elif c == "add":
        import addkey
        if "--missing" in a: addkey.missing(p[0] if p else None)
        else: [addkey.add(i) for i in p]
    elif c == "open":
        for i in p: core.openurl(registry.by_id(i)["signup"])
    elif c == "reg":
        import autoreg
        for i in p: autoreg.register(i, show=vis, dry=("--dry" in a))
    elif c == "batch":
        import autoreg; autoreg.batch(p, show=vis)
    elif c == "autoflow":
        import autoflow; autoflow.run(int(p[0]) if p else 1, show=vis)
    elif c == "ghauth": import ghauth; ghauth.authorize()
    elif c == "ghlink":
        import ghlink; ghlink.link(p[0] if p else "cinehub3099")
        if "--pages" in a: ghlink.enable_pages()
    elif c == "harvest":
        import harvest
        if "--scan" in a: harvest.scan()
        harvest.report()
        if "--push" in a: import repo; core.log(repo.push("harvest")[1],"info")
    elif c == "dashboard":
        import dashboard; dashboard.build()
        if "--push" in a: import repo; core.log(repo.push("dashboard")[1],"info")
    elif c == "earn": ledger.add(p[0], p[1], "earning", note=" ".join(p[2:]))
    elif c == "spend": ledger.add(p[0], p[1], "withdraw", note=" ".join(p[2:]))
    elif c == "ledger": ledger.report()
    elif c == "payout": import payout; payout.plan()
    elif c == "wallet":
        import payout
        if len(p)>=2: payout.set_wallet(p[0],p[1])
        else: payout.wallet()
    elif c == "push": import repo; core.log(repo.push(" ".join(p) or None)[1],"ok")
    elif c == "pull": import repo; core.log(repo.pull()[1] or "مُحدّث","ok")
    elif c == "sync": import repo; repo.sync(); core.log("تمت المزامنة","ok")
    elif c == "watch": import watch; watch.main(int(p[0]) if p else 5)
    elif c == "restart":
        import subprocess, glob
        subprocess.run(["pkill","-f","chromium.*cinehub3099"])
        for f in glob.glob("data/profiles/*/Singleton*")+glob.glob("data/profiles/*/lockfile"):
            try: os.remove(f)
            except Exception: pass
        core.load_env(); core.log("أُعيد التشغيل","ok")
    elif c == "setenv": core.set_env(p[0],p[1]); core.log("%s حُفظ" % p[0],"ok")
    else: use()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n%sأُوقف%s" % (core.C['warn'],core.C['x']))
    except KeyError as e: print("%s%s%s" % (core.C['err'],e,core.C['x']))
