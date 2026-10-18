#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يُبلّغ محركات البحث: IndexNow + Sitemap"""
import os, json, random, urllib.request
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
SITE = os.environ.get("SITE_URL", "https://alkazmybwhwr-dot.github.io")
host = SITE.replace("https://", "")
kp = "indexnow-key.txt"
key = open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
open(kp, "w").write(key); open(key + ".txt", "w").write(key)
urls = [SITE + "/"]
if os.path.isdir("p"):
    urls += [SITE + "/p/" + f for f in sorted(os.listdir("p"))[:500] if f.endswith(".html")]
for ep, payload in (("https://api.indexnow.org/indexnow",
                     {"host": host, "key": key, "keyLocation": SITE + "/" + key + ".txt", "urlList": urls[:10000]}),):
    try:
        r = urllib.request.Request(ep, data=json.dumps(payload).encode(),
                                   headers={"Content-Type": "application/json; charset=utf-8"})
        print("indexnow", urllib.request.urlopen(r, timeout=30).status)
    except Exception as e:
        print("indexnow skip", e)
for ep in ("https://www.google.com/ping?sitemap=%s/sitemap.xml" % SITE,
           "https://www.bing.com/ping?sitemap=%s/sitemap.xml" % SITE):
    try: print("ping", ep.split("/")[2], urllib.request.urlopen(ep, timeout=25).status)
    except Exception as e: print("ping skip", e)
