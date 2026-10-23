#!/usr/bin/env python3
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
T = gh.token()
def api(p):
    r = urllib.request.Request("https://api.github.com" + p,
        headers={"Authorization": "Bearer " + T, "Accept": "application/vnd.github+json", "User-Agent": "CineHub"})
    with urllib.request.urlopen(r, timeout=30) as x: return json.loads(x.read().decode() or "{}")
try: me = api("/user")["login"]
except Exception: sys.exit(0)
repo = me + ".github.io"
out = {"updated": time.strftime("%F %H:%M"), "pages_url": "https://%s.github.io/" % me,
       "views_14d": 0, "uniques_14d": 0, "clones_14d": 0, "stars": 0, "top_paths": []}
for key, p in (("views", "/traffic/views"), ("clones", "/traffic/clones")):
    try:
        d = api("/repos/%s/%s%s" % (me, repo, p)); out[key + "_14d"] = d.get("count", 0)
        if key == "views": out["uniques_14d"] = d.get("uniques", 0)
    except Exception: pass
try: out["stars"] = api("/repos/%s/%s" % (me, repo)).get("stargazers_count", 0)
except Exception: pass
try: out["top_paths"] = api("/repos/%s/%s/traffic/popular/paths" % (me, repo))[:20]
except Exception: pass
os.makedirs("data", exist_ok=True)
json.dump(out, open("data/revenue.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ زيارات GitHub: %d | فريدون: %d" % (out["views_14d"], out["uniques_14d"]))
