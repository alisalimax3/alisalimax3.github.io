#!/usr/bin/env python3
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
U = gh.login(); S = "https://%s.github.io" % U
try: st = json.load(open("data/wayback.json", encoding="utf-8"))
except Exception: st = {"done": []}
done = set(st.get("done", []))
CAND = ["/", "/app.html", "/movies.html", "/adult.html", "/links.html", "/install.html", "/feed.xml"]
new = [c for c in CAND if c not in done][:4]
ok = 0
for c in new:
    try:
        urllib.request.urlopen("https://web.archive.org/save/" + S + c, timeout=75)
        done.add(c); ok += 1
    except Exception: pass
st["done"] = sorted(done); st["at"] = time.strftime("%F %H:%M")
json.dump(st, open("data/wayback.json", "w", encoding="utf-8"))
print("  ✓ أُرشف %d صفحة (المجموع %d)" % (ok, len(done)))
