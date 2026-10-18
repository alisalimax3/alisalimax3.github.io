#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يسحب الأرباح المؤكَّدة من واجهات الشبكات — ويعلن فشل كل محوّل بصدق"""
import json, os, urllib.request, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
env = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8", errors="replace"):
        ln = ln.strip()
        if ln and not ln.startswith("#") and "=" in ln:
            k, v = ln.split("=", 1); env[k.strip()] = v.strip()
def jget(u, hdr=None):
    try:
        r = urllib.request.urlopen(urllib.request.Request(u, headers=hdr or {}), timeout=25)
        return json.loads(r.read().decode()), r.status
    except Exception as e:
        return None, str(e)
def find_rev(o, acc):
    if isinstance(o, dict):
        for k, v in o.items():
            if isinstance(v, (int, float)) and k.lower() in ("revenue", "earnings", "profit", "amount", "total_revenue"):
                acc.append(float(v))
            else: find_rev(v, acc)
    elif isinstance(o, list):
        for x in o: find_rev(x, acc)
    return acc
def today(off=30):
    d = datetime.date.today()
    return (d - datetime.timedelta(days=off)).isoformat(), d.isoformat()
src, total = [], 0.0
ak = env.get("ADSTERRA_API_KEY") or env.get("ADSTERRA")
if ak:
    s, f = today()
    url = "https://api3.adsterratools.com/publisher/stats.json?start_date=%s&finish_date=%s&group_by=day" % (s, f)
    d, st = jget(url, {"X-API-Key": ak, "Accept": "application/json"})
    if d is not None:
        rv = sum(find_rev(d, [])); total += rv
        src.append({"net": "Adsterra", "ok": True, "http": st, "value": round(rv, 6)})
    else:
        src.append({"net": "Adsterra", "ok": False, "http": str(st)[:80], "value": 0})
else:
    src.append({"net": "Adsterra", "ok": False, "http": "لا مفتاح", "value": 0})
for var, nm, url in (("MONETAG_KEY", "Monetag", "https://api.monetag.com/v1/publisher/statistics"),
                     ("LINKVERTISE_UID", "Linkvertise", "https://publisher.linkvertise.com/api/v1/statistics")):
    v = env.get(var)
    if not v:
        src.append({"net": nm, "ok": False, "http": "لا مفتاح", "value": 0}); continue
    d, st = jget(url, {"Authorization": "Bearer " + v, "Accept": "application/json"})
    if d is not None:
        rv = sum(find_rev(d, [])); total += rv
        src.append({"net": nm, "ok": True, "http": st, "value": round(rv, 6)})
    else:
        src.append({"net": nm, "ok": False, "http": str(st)[:80], "value": 0})
cnt = {}
try: cnt = json.load(open("counts.json", encoding="utf-8"))
except Exception: pass
imp = int(cnt.get("impressions") or 0)
cpm = float(env.get("ASSUMED_CPM", "1.5"))
est = round(imp / 1000.0 * cpm, 6)
out = {"confirmed_total": round(total, 6), "sources": src,
       "estimated": {"impressions": imp, "assumed_cpm": cpm, "value": est,
                     "note": "تقديري = ظهور حقيقي × CPM مفترض معلن"},
       "updated": datetime.datetime.now(datetime.timezone.utc).isoformat()}
json.dump(out, open("revenue.json", "w"), ensure_ascii=False, indent=1)
print("confirmed %.6f | estimated %.6f | impressions %d" % (total, est, imp))
