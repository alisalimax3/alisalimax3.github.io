#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يقرأ العدّادات الحقيقية من الشبكة ويكتبها في pulse.json"""
import json, os, urllib.request, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
NS = os.environ.get("CH_NS", "ch3099-alkazmybwhwr-dot")
KEYS = ["visits", "impressions", "clicks"]
def g(u):
    try:
        r = urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "cinehub3099"}), timeout=20)
        return json.loads(r.read().decode())
    except Exception:
        return None
out = {}
for k in KEYS:
    v = None
    d = g("https://abacus.jasoncameron.dev/get/%s/%s" % (NS, k))
    if isinstance(d, dict): v = d.get("value")
    if v is None:
        d2 = g("https://api.counterapi.dev/v1/%s/%s/" % (NS, k))
        if isinstance(d2, dict): v = d2.get("count")
    out[k] = int(v) if isinstance(v, (int, float)) else 0
json.dump(out, open("counts.json", "w"), ensure_ascii=False, indent=1)
p = {}
try: p = json.load(open("pulse.json", encoding="utf-8"))
except Exception: pass
p.update({"visits": out["visits"], "impressions": out["impressions"], "clicks": out["clicks"],
          "source": "abacus/counterapi (حقيقي)", "updated": datetime.datetime.now(datetime.timezone.utc).isoformat()})
json.dump(p, open("pulse.json", "w"), ensure_ascii=False, indent=1)
print("counts", out)
