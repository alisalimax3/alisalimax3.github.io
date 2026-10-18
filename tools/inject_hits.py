#!/usr/bin/env python3
import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
n = 0
for dp, dn, fn in os.walk("."):
    if any(x in dp for x in (".git", "node_modules", ".tmp")): continue
    for f in fn:
        if not f.endswith(".html"): continue
        p = os.path.join(dp, f); d = max(dp.count(os.sep) - 1, 0)
        try: s = open(p, encoding="utf-8").read()
        except Exception: continue
        if "hits.js" in s or "</body>" not in s: continue
        s = s.replace("</body>", '<script src="%shits.js" defer></script></body>' % ("../" * d if d else ""), 1)
        try: open(p, "w", encoding="utf-8").write(s); n += 1
        except Exception: pass
print("  ✓ العدّاد في %d صفحة" % n)
