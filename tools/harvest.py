#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""حصاد الأرباح — من الدفتر + مسح مباشر للوحات"""
import json, os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, repo
from registry import by_id

MONEY = re.compile(r'(?:USD|\$|€|£)\s?([0-9]{1,6}(?:\.[0-9]{1,2})?)')
REG = core.DATA / "registrations.json"

def registered():
    d = core.load(REG, {})
    return [k for k, v in d.items() if v.get("status") in ("registered","confirmed","key_set")]

def scan(limit=0):
    """يفتح لوحة كل شبكة مسجّلة ويحاول قراءة الرصيد"""
    import cdp
    ids = [i for i in registered() if i in registry.BY_ID][:limit or 999]
    if not ids: core.log("لا شبكات مسجّلة بعد","warn"); return {}
    found = {}
    core.log("مسح %d لوحة..." % len(ids), "info")
    for i in ids:
        n = by_id(i)
        prof = str(core.PROFILES / i)
        if not os.path.isdir(prof): continue
        try:
            ch = cdp.Chrome(prof, headless=True, timeout=45)
            try:
                t = ch.tab()
                if not t.go(n["payout_page"], timeout=60):
                    core.log("%s: تعذّر التحميل" % i, "warn"); continue
                txt = t.text(8000)
                nums = [float(x) for x in MONEY.findall(txt)]
                nums = [x for x in nums if 0 < x < 100000]
                if nums:
                    found[i] = max(nums)
                    core.log("%s → $%.2f" % (i, found[i]), "ok")
                else:
                    core.log("%s → لا رقم ظاهر" % i, "warn")
            finally: ch.close()
        except Exception as e:
            core.log("%s: %s" % (i, str(e)[:60]), "err")
        time.sleep(0.5)
    if found: core.save("data/scanned.json", {"at": time.strftime("%Y-%m-%d %H:%M"), "balances": found})
    return found

def report():
    b = ledger.balances(); reg = registered()
    print("\n" + core.C['b'] + "╔══════════════════════════════════════════════════╗")
    print("║   💰 تقرير الحصاد — أموال حقيقية                  ║")
    print("╚══════════════════════════════════════════════════╝" + core.C['x'])
    print("\n  شبكات مسجّلة: %d | مصادر بمفاتيح: %d" % (len(reg), len(registry.with_key())))
    if not b:
        print("\n  لا أرباح مسجّلة بعد. سجّل ربحاً: ./run.sh earn <id> <مبلغ>")
        return
    ready = []
    print("\n  %-18s %10s %8s  %s" % ("المصدر","الرصيد","الحد","الحالة")); print("  "+"-"*54)
    for s, v in sorted(b.items(), key=lambda x: -x[1]):
        try: mn = by_id(s)["payout_min"]
        except Exception: mn = 0
        st = "✓ جاهز للسحب" if v >= mn else "ينقص $%.2f" % (mn-v)
        if v >= mn: ready.append((s,v,mn))
        print("  %-18s %10s %8s  %s" % (s, "$%.2f"%v, "$%g"%mn, st))
    print("  "+"-"*54)
    print("  %-18s %10s" % ("الإجمالي", "$%.2f" % ledger.total()))
    print("  %-18s %10s" % ("قابل للسحب الآن", "$%.2f" % sum(x[1] for x in ready)))
    out = {"at": time.strftime("%Y-%m-%d %H:%M"), "total": ledger.total(),
           "ready": [x[0] for x in ready], "balances": b}
    core.save("data/harvest.json", out)
    if ready: core.log("%d شبكة جاهزة للسحب — نفّذ: ./run.sh payout" % len(ready), "ok")

def ci():
    """يعمل داخل GitHub Actions"""
    report()
    return 0

if __name__ == "__main__":
    a = sys.argv[1:]
    if "--scan" in a: scan(int(a[a.index("--scan")+1]) if a.index("--scan")+1 < len(a) and a[a.index("--scan")+1].isdigit() else 0)
    if "--push" in a: core.log(repo.push("harvest")[1], "info")
    if "--ci" in a: sys.exit(ci())
    report()
