#!/usr/bin/env python3
"""IndexNow تدريجي: الجديد فقط"""
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
U = gh.login(); S = "https://%s.github.io" % U
key = next((f[:-4] for f in os.listdir(".") if f.endswith(".txt") and f[:-4].isalnum() and len(f[:-4]) in (8, 32)), None)
if not key:
    key = "cinehub3099index"
    open(key + ".txt", "w").write(key)
files = []
for dp, dn, fn in os.walk("."):
    if ".git" in dp or "node_modules" in dp or dp.startswith("./data"): continue
    for f in fn:
        if f.endswith(".html"): files.append(os.path.relpath(os.path.join(dp, f), ".").replace("\\", "/"))
files.sort()
try: st = json.load(open("data/indexed.json", encoding="utf-8"))
except Exception: st = {"done": []}
done = set(st.get("done", []))
new = [f for f in files if f not in done]
if not new:
    print("  · لا جديد"); raise SystemExit
batch = new[:500]
urls = [S + "/" + f for f in batch]
body = json.dumps({"host": "%s.github.io" % U, "key": key, "keyLocation": "%s/%s.txt" % (S, key), "urlList": urls}).encode()
try:
    r = urllib.request.Request("https://api.indexnow.org/indexnow", data=body,
        headers={"Content-Type": "application/json; charset=utf-8"})
    with urllib.request.urlopen(r, timeout=60) as x: code = x.status
except Exception as e: code = str(e)[:30]
st["done"] = list(done | set(batch)); st["at"] = time.strftime("%F %H:%M")
json.dump(st, open("data/indexed.json", "w", encoding="utf-8"))
print("  ✓ أُرسل %d رابط جديد (كود %s) · المتبقي %d" % (len(batch), code, len(new) - len(batch)))
