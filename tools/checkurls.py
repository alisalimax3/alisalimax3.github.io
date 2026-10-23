#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يختبر كل روابط التسجيل بمتصفح حقيقي ويكشف العامل منها"""
import sys, time, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, cdp

def main():
    only = [a for a in sys.argv[1:] if not a.startswith("-") and a != "checkurls"] or [n["id"] for n in registry.ALL]
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
