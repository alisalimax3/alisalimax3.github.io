#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يتحقق من وجود المواقع الرسمية فعليًا ويرتّب المزودين حسب الملاءمة. لا يسجّل حسابات."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

def score(p):
    s = 0
    if p.get("adult_ok") == "yes": s += 30
    if p.get("api_available") == "yes": s += 15
    mn = p.get("min_payout", "")
    import re
    m = re.search(r"\$(\d+)", mn)
    if m:
        v = int(m.group(1))
        s += 25 if v <= 10 else (18 if v <= 25 else (10 if v <= 50 else 3))
    if "BTC" in p.get("payment_methods","") or "USDT" in p.get("payment_methods",""): s += 8
    if p.get("type","").startswith("affiliate"): s += 12
    if p.get("reachable"): s += 15
    else: s -= 20
    return s

def main():
    with core.lock("discovery", 3600) as got:
        if not got: print("  · مقفول"); return
        r = RE.build()
        provs = r["providers"]
        print("  فحص %d موقعًا رسميًا…" % len(provs))
        for p in provs:
            res = core.http(p["official_url"], timeout=12)
            p["reachable"] = bool(res.get("ok"))
            p["http_code"] = res.get("code")
            p["final_url"] = res.get("final", p["official_url"])
            p["check_error"] = res.get("err", "")
            p["checked_on"] = time.strftime("%F")
            p["fit_score"] = score(p)
            mark = "✓" if p["reachable"] else "✗"
            print("    %s %-18s %s %s" % (mark, p["id"], p["http_code"] or res.get("err",""), ""))
        provs.sort(key=lambda x: -x.get("fit_score", 0))
        r["discovery"] = {"updated": time.strftime("%F %H:%M"),
                          "method": "HTTP GET على الرابط الرسمي · الباقي unverified",
                          "reachable": len([p for p in provs if p.get("reachable")]),
                          "total": len(provs)}
        core.save(RE.REG, r)
        core.save("data/providers.json", {"updated": r["discovery"]["updated"],
                  "ranked": [{"id": p["id"], "name": p["name"], "fit": p.get("fit_score"),
                              "reachable": p.get("reachable"), "min_payout": p["min_payout"],
                              "type": p["type"], "url": p["official_url"]} for p in provs]})
        print("  ✓ رُتّب %d · قابل للوصول %d" % (len(provs), r["discovery"]["reachable"]))
        print("  أعلى 6 ملاءمة: " + " · ".join(p["id"] for p in provs[:6]))

if __name__ == "__main__": main()
