#!/usr/bin/env python3
import json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
rev = rd("data/revenue.json", {}); hit = rd("data/hits.json", {}); ads = rd("ads.json", {})
live = [n for n in (ads.get("networks") or []) if n.get("id")]
off = [n for n in (ads.get("networks") or []) if not n.get("id")]
views = rev.get("views_14d", 0); hv = hit.get("total", 0)
impr = int(views * 1.7 + hv * 1.0); ecpm = 1.35 if live else 0.65
m = {"updated": time.strftime("%F %H:%M"),
     "real": {"github_views_14d": views, "github_uniques_14d": rev.get("uniques_14d", 0),
              "hits_total": hv, "live_ad_networks": len(live)},
     "estimated": {"impressions": impr, "ecpm_used": ecpm, "usd": round(impr / 1000.0 * ecpm, 4)},
     "networks_live": [{"n": n.get("n"), "pay": n.get("pay")} for n in live],
     "networks_off": [{"n": n.get("n"), "k": n.get("k")} for n in off],
     "live_url": rev.get("pages_url", "")}
os.makedirs("data", exist_ok=True)
json.dump(m, open("data/money.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ money.json | real views=%d hits=%d live=%d | est $%s" % (views, hv, len(live), m["estimated"]["usd"]))
