#!/usr/bin/env python3
import json, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f, d):
    try: return json.load(open(f, encoding="utf-8"))
    except Exception: return d
c = L("counts.json", {}); r = L("revenue.json", {})
json.dump({"visits": c.get("visits", 0), "impressions": c.get("impressions", 0), "clicks": c.get("clicks", 0),
           "confirmed": r.get("confirmed_total", 0), "estimated": (r.get("estimated") or {}).get("value", 0),
           "updated": datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("insights.json", "w"), ensure_ascii=False, indent=1)
print("insights ok")
