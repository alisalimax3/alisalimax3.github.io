#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يقول بصدق: ما الذي يمنع الأرباح الآن"""
import json, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f, d):
    try: return json.load(open(f, encoding="utf-8"))
    except Exception: return d
nets = L("nets.json", {}); cnt = L("counts.json", {}); rev = L("revenue.json", {})
g = []
if not nets.get("with_key"):
    g.append({"id": "keys", "ok": False, "t": "لا مفتاح شبكة", "why": "الإيراد المؤكَّد لا يتحرك بلا مفتاح",
              "fix": "/subscribe.html", "fix_t": "سجّل في Adsterra والصق المفتاح"})
else:
    g.append({"id": "keys", "ok": True, "t": "%d شبكة مربوطة" % nets.get("with_key"), "why": "", "fix": "", "fix_t": ""})
if int(cnt.get("visits") or 0) < 20:
    g.append({"id": "traffic", "ok": False, "t": "الزيارات قليلة", "why": "الظهور يحتاج زوارًا حقيقيين",
              "fix": "/sites.html", "fix_t": "انشر رابطًا + IndexNow يعمل يوميًا"})
else:
    g.append({"id": "traffic", "ok": True, "t": "زيارات تتراكم", "why": "", "fix": "", "fix_t": ""})
if int(cnt.get("impressions") or 0) == 0:
    g.append({"id": "imp", "ok": False, "t": "لا ظهور مسجَّل بعد", "why": "مساحات الإعلان تُحسب عند دخولها الشاشة",
              "fix": "/rise.html", "fix_t": "افتح أي صفحة إعلانية"})
else:
    g.append({"id": "imp", "ok": True, "t": "ظهور حقيقي يُسجَّل", "why": "", "fix": "", "fix_t": ""})
if not L("owner.json", {}).get("kuraimi"):
    g.append({"id": "owner", "ok": False, "t": "بيانات الكريمي غير محفوظة", "why": "السحب يحتاجها",
              "fix": "/withdraw.html", "fix_t": "أدخل الاسم والحساب والهاتف"})
else:
    g.append({"id": "owner", "ok": True, "t": "حساب الكريمي محفوظ", "why": "", "fix": "", "fix_t": ""})
out = {"gates": g, "open": sum(1 for x in g if not x["ok"]), "updated": datetime.datetime.now(datetime.timezone.utc).isoformat()}
json.dump(out, open("gates.json", "w"), ensure_ascii=False, indent=1)
for x in g: print(("✓" if x["ok"] else "✗"), x["t"], "—", x["why"])
