#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يفحص رابط الإعلان المبني فعليًا عبر HTTP. A-ADS: يجرّب الصيغتين."""
import os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ads

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


def src_of(code):
    m = re.search(r'src="([^"]+)"', code or "")
    return m.group(1) if m else ""

def main():
    with core.lock("adcheck", 900) as got:
        if not got: print("  · مقفول"); return
        res = []
        for n in ads.status():
            if not n["on"]: continue
            code = ads._one(n)
            url = src_of(code)
            if not url: res.append({"id": n["id"], "status": "embed_only"}); continue
            r = core.http(url, timeout=10)
            entry = {"id": n["id"], "name": n["n"], "url": url, "code": r.get("code"),
                     "ok": bool(r.get("ok")), "err": r.get("err", "")}
            if not r.get("ok") and n["id"] == "aads":
                alt = url.replace("ad.a-ads.com", "acceptable.a-ads.com")
                r2 = core.http(alt, timeout=10)
                entry["alt"] = {"url": alt, "code": r2.get("code"), "ok": bool(r2.get("ok"))}
                if r2.get("ok"):
                    open(".env", "a", encoding="utf-8").write(
                        "AADS_EMBED=<iframe src=\"%s\" data-aa='%s' width=\"300\" height=\"250\""
                        " frameborder=\"0\" scrolling=\"no\" loading=\"lazy\""
                        " style=\"border:0;max-width:100%%\"></iframe>\n"
                        % (alt, core.get("AADS_UNIT")))
                    entry["switched_to"] = alt
            res.append(entry)
            print("    %s %-12s HTTP %s %s" % ("✓" if entry["ok"] else "✗", n["id"], entry["code"], entry.get("err","")))
        core.save("data/adcheck.json", {"at": time.strftime("%F %H:%M"), "results": res,
                  "working": [r["id"] for r in res if r.get("ok")],
                  "note": "فحص HTTP لرابط الإعلان. نجاح ≠ دفع، لكنه يثبت أن الوسم يُخدم."})
        w = [r["id"] for r in res if r.get("ok")]
        print("  ✓ يعمل: %s · فُحص: %d" % (", ".join(w) or "لا شيء", len(res)))

if __name__ == "__main__": main()
