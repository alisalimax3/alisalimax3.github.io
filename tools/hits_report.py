#!/usr/bin/env python3
import json, os, re, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
def slug(p): return re.sub(r"[^\w.\-]", "_", p.strip("/").replace("/", "__")) or "home"
def get(u):
    try:
        r = urllib.request.Request(u, headers={"User-Agent": "CineHub"})
        with urllib.request.urlopen(r, timeout=15) as x: return json.loads(x.read().decode() or "{}")
    except Exception: return {}
pages = ["/", "/app.html", "/library.html"]
for x in (rd("data/revenue.json", {}).get("top_paths") or [])[:25]:
    if x.get("path"): pages.append(x["path"])
seen, top, total = set(), [], 0
for p in pages:
    k = slug(p)
    if k in seen: continue
    seen.add(k)
    d = get("https://api.counterapi.dev/v1/cinehub3099/%s" % k)
    c = int(d.get("count") or 0)
    total += c
    if c: top.append({"p": p, "n": c})
top.sort(key=lambda x: -x["n"])
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "total": total, "checked": len(seen), "top": top[:40]},
          open("data/hits.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ عدّاد حقيقي: %d مشاهدة (%d صفحة)" % (total, len(seen)))
