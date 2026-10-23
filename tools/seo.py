#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يحقن OG + Twitter + JSON-LD في صفحات الأفلام تدريجيًا (يتابع من حيث توقف)."""
import json, os, re, sys
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CAP = int(os.environ.get("SEO_MAX", "5000"))
try: U = json.load(open("data/seo_done.json", encoding="utf-8")).get("done", [])
except Exception: U = []
done = set(U)
files = []
for dp, dn, fn in os.walk("f"):
    for f in fn:
        if f.endswith(".html"): files.append(os.path.join(dp, f))
files.sort()
n = 0
for p in files:
    if p in done: continue
    if n >= CAP: break
    try: s = open(p, encoding="utf-8").read()
    except Exception: continue
    if 'property="og:title"' in s: done.add(p); continue
    t = re.search(r"<title>(.*?)</title>", s, re.S)
    title = (t.group(1).strip() if t else os.path.basename(p)[:-5])
    img = re.search(r'<img[^>]+src="([^"]+)"', s)
    image = img.group(1) if img else "/icon.svg"
    if image.startswith("/"): image = "https://" + os.environ.get("GH_HOST", "") + image
    og = ('<meta property="og:type" content="video.movie"><meta property="og:title" content="%s">'
          '<meta property="og:image" content="%s"><meta property="og:site_name" content="CineHub 3099">'
          '<meta name="twitter:card" content="summary_large_image"><meta name="twitter:title" content="%s">'
          '<meta name="twitter:image" content="%s">'
          '<script type="application/ld+json">{"@context":"https://schema.org","@type":"Movie","name":"%s","image":"%s"}</script>'
          % (title.replace('"', "'"), image, title.replace('"', "'"), image, title.replace('"', "'"), image))
    s = s.replace("</head>", og + "</head>", 1) if "</head>" in s else og + s
    try: open(p, "w", encoding="utf-8").write(s)
    except Exception: continue
    done.add(p); n += 1
json.dump({"done": sorted(done), "at": __import__("time").strftime("%F %H:%M")},
          open("data/seo_done.json", "w", encoding="utf-8"), ensure_ascii=False)
print("  ✓ SEO: %d صفحة (المجموع %d من %d)" % (n, len(done), len(files)))
