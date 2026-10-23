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
  reg <id> [--show]       تسجيل حقيقي (--show لرؤية المتصفح)
  reg --dry <id>          معاينة دون تنفيذ
  login <id>              فتح جلسة محفوظة
  batch <id1> <id2> ...   تسجيل جماعي
  show <id>               عرض آخر صورة للصفحة
  profile                 عرض بياناتك
  key <id> [value]        عرض/تعيين مفتاح
  confirm <id>            تأكيد البريد تلقائياً
  earn <id> <مبلغ> [note] تسجيل ربح
  spend <id> <مبلغ> [note]تسجيل سحب
  ledger                  تقرير الأرباح
  payout                  خطة السحب الجاهزة
  wallet [name value]     إدارة المحافظ
  status                  حالة النظام
  doctor                  فحص سريع
  audit                   فحص شامل حقيقي
  checkurls [id...]       اختبار روابط التسجيل بمتصفح حقيقي
  setenv <KEY> <value>    تعيين مفتاح
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
        dry = "--dry" in a; show = ("--show" in a) or ("--headful" in a)
        ids = [x for x in a[1:] if not x.startswith("--")]
        import autoreg
        for i in ids: autoreg.register(i, show=show, dry=dry)
    elif c == "show":
        import glob
        g = sorted(glob.glob(str(core.LOGS / "shots" / (a[1] + "_*.png"))))
        if not g: print("لا توجد صور بعد")
        else: core.openurl(g[-1]); print(g[-1])
    elif c == "profile":
        pr = core.load("data/profile.json")
        for k in ("first","last","username","email","password","country","site"):
            print("  %-10s %s" % (k, pr.get(k,"")))
    elif c == "batch":
        import autoreg; autoreg.batch(a[1:], show=("--show" in a))
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
    elif c == "checkurls":
        import checkurls; checkurls.main()
    elif c == "audit":
        import audit; audit.main()
    elif c == "setenv":
        core.set_env(a[1], a[2]); core.log("%s حُفظ" % a[1], "ok")
    elif c == "doctor":
        import doctor; doctor.main()
    else: usage()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print(f"\n{core.C['warn']}أُوقف{core.C['x']}")
    except KeyError as e: print(f"{core.C['err']}{e}{core.C['x']}")
