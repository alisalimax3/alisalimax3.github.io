#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص الموقع المنشور فعليًا — دليل لا ادّعاء."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
PATHS = ["/", "/adult.html", "/m/", "/new.html", "/best.html", "/me.html", "/rewards.html",
         "/share.html", "/promote-adult.html", "/owner.html", "/income.html",
         "/sitemap.xml", "/sitemap-adult.xml", "/robots.txt", "/manifest.json", "/hits.js"]
def main():
    s = core.site()
    if not s: print("  ✗ لا SITE_URL"); return
    r = {}
    for p in PATHS:
        c = core.http(s + p, timeout=12)
        r[p] = c.get("code")
        print("  %s %-22s %s" % ("✓" if c.get("code") == 200 else "✗", p, c.get("code") or c.get("err")))
    core.save("data/live.json", {"at": core.time.strftime("%F %H:%M"), "site": s, "paths": r})
    print("  منشور %d · مفقود %d" % (len([x for x in r.values() if x == 200]),
                                     len([x for x in r.values() if x != 200])))
if __name__ == "__main__": main()
