#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""إيراد حقيقي: زيارات GitHub + مستنسخات + مصادر + مسارات + نجوم."""
import json, os, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import gh

def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d

def wr(p, o):
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    json.dump(o, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

def main():
    tok = gh.token()
    base = {"updated": time.strftime("%Y-%m-%d %H:%M"), "views_14d": 0, "uniques_14d": 0,
            "clones_14d": 0, "stars": 0, "forks": 0, "referrers": [], "top_pages": [],
            "impressions_est": 0, "revenue_est_usd": 0.0, "revenue_real_usd": 0.0,
            "pages_url": "", "source": "github"}
    if not tok:
        wr(os.path.join(ROOT, "data/revenue.json"), base); return
    user = gh.login(tok)
    repo = gh.repo_name()
    if not user:
        wr(os.path.join(ROOT, "data/revenue.json"), base); return
    r = gh.api("/repos/%s/%s" % (user, repo), tok=tok)
    if isinstance(r, dict) and r.get("_code"):
        wr(os.path.join(ROOT, "data/revenue.json"), base); return
    v = gh.api("/repos/%s/%s/traffic/views" % (user, repo), tok=tok)
    c = gh.api("/repos/%s/%s/traffic/clones" % (user, repo), tok=tok)
    rf = gh.api("/repos/%s/%s/traffic/popular/referrers" % (user, repo), tok=tok)
    tp = gh.api("/repos/%s/%s/traffic/popular/paths" % (user, repo), tok=tok)
    if isinstance(v, dict) and not v.get("_code"):
        base["views_14d"] = v.get("count", 0); base["uniques_14d"] = v.get("uniques", 0)
    if isinstance(c, dict) and not c.get("_code"):
        base["clones_14d"] = c.get("count", 0)
    if isinstance(rf, list):
        base["referrers"] = [{"source": x.get("referrer"), "count": x.get("count", 0), "uniques": x.get("uniques", 0)} for x in rf[:12]]
    if isinstance(tp, list):
        base["top_pages"] = [{"path": x.get("path"), "count": x.get("count", 0)} for x in tp[:12]]
    base["stars"] = r.get("stargazers_count", 0)
    base["forks"] = r.get("forks_count", 0)
    base["watchers"] = r.get("subscribers_count", 0)
    base["size_kb"] = r.get("size", 0)
    base["pages_url"] = "https://%s.github.io/%s/" % (user, repo)
    ecpm = 0.65
    p = os.path.join(ROOT, "keys.env")
    if os.path.exists(p):
        for ln in open(p, encoding="utf-8"):
            if ln.startswith("ECPM="): ecpm = float(ln.split("=", 1)[1].strip() or 0.65)
    base["impressions_est"] = int(base["views_14d"] * 1.7 + base["clones_14d"] * 1.2)
    base["revenue_est_usd"] = round(base["impressions_est"] / 1000.0 * ecpm, 4)
    led = rd(os.path.join(ROOT, "wallet.json"), {})
    base["wallet_usd"] = led.get("balance") or led.get("usd") or 0
    wr(os.path.join(ROOT, "data/revenue.json"), base)
    with open(os.path.join(ROOT, "data/revenue_history.jsonl"), "a", encoding="utf-8") as f:
        f.write(json.dumps({"t": base["updated"], "views": base["views_14d"],
                            "rev": base["revenue_est_usd"]}, ensure_ascii=False) + "\n")
    print("  زيارات 14 يوم: %s | زوار فريدون: %s | تقديري: $%s"
          % (base["views_14d"], base["uniques_14d"], base["revenue_est_usd"]))

if __name__ == "__main__":
    main()
