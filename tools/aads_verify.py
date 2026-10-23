#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجرّب كل مرشّح لمعرّف A-ADS ويقول أيها يُخدم فعلًا (HTTP + حجم + كلمات)."""
import os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

# VN_CORE_SHIM — يوفّر core.get لو core.py مش بيوفّره
try:
    import core as _vncore
    if not hasattr(_vncore, "get"):
        def _vn_get(k, d=None):
            for _n in ("CFG","CONFIG","CONF","SETTINGS","ENV","DEFAULTS","PARAMS","cfg","conf","config","settings"):
                _o = getattr(_vncore, _n, None)
                if isinstance(_o, dict) and k in _o: return _o[k]
            return getattr(_vncore, k, d)
        _vncore.get = _vn_get
except Exception:
    pass

NUM = re.compile(r"\b(\d{4,8})\b")

def score(b):
    b = (b or "").lower(); s = 0
    for k, w in (("a-ads", 3), ("ads", 1), ("iframe", 2), ("banner", 2), ("<div", 1)): 
        if k in b: s += w
    for k in ("not found", "invalid", "undefined"): 
        if k in b: s -= 2
    return s

def probe(i):
    out = []
    for host in ("acceptable.a-ads.com", "ad.a-ads.com"):
        u = "https://%s/%s?size=300x250" % (host, i)
        b = core.body(u, timeout=12, limit=20000)
        out.append({"host": host, "size": len(b), "score": score(b)})
    return out

def main():
    cands, cur = [], core.get("AADS_UNIT")
    if cur: cands.append(cur)
    for f in ("keys.env", ".env", ".tmp/keys.env.bak"):
        if os.path.exists(f):
            for l in open(f, encoding="utf-8", errors="ignore"):
                if "AADS" in l.upper(): cands += NUM.findall(l)
    seen, order = set(), []
    for c in cands:
        if c and c not in seen: seen.add(c); order.append(c)
    res, best = [], None
    for c in order[:10]:
        r = probe(c); g = max(x["score"] for x in r); sz = max(x["size"] for x in r)
        okk = sz > 400 and g > 2
        res.append({"id": c, "ok": okk, "score": g, "size": sz, "res": r})
        print("    %s %-8s حجم=%-6s درجة=%d" % ("✓" if okk else "✗", c, sz, g))
        if okk and (best is None or g > best["score"]): best = res[-1]
    core.save("data/aads_verify.json", {"at": time.strftime("%F %H:%M"), "current": cur,
              "results": res, "best": best["id"] if best else None})
    if best:
        print("  ✓ الأفضل: %s" % best["id"])
        if best["id"] != cur:
            print("  ! الحالي %s مرفوض → صحّح AADS_UNIT=%s" % (cur or "—", best["id"]))
    else:
        print("  ✗ لا مرشّح يُخدم — أنشئ Ad Unit من a-ads.com/ad-units/new/")
    if cur: print("  · الحالي: %s" % cur)

if __name__ == "__main__": main()
