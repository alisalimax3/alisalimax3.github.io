#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
from registry import by_id
L = core.DATA / "ledger.json"

def _d():
    d = core.load(L, {"entries": []})
    if not isinstance(d, dict): d = {}
    d.setdefault("entries", [])
    if not isinstance(d["entries"], list): d["entries"] = []
    return d

def add(site, amount, kind="earning", currency="USD", note=""):
    d = _d()
    d["entries"].append({"site":site,"amount":float(amount),"kind":kind,
                         "currency":currency,"note":note,"at":time.strftime("%Y-%m-%d %H:%M:%S")})
    core.save(L, d); core.log("%s: %s = %s %s" % ("ربح" if kind=="earning" else "سحب", site, amount, currency), "ok")

def balances():
    b = {}
    for e in _d()["entries"]:
        b[e["site"]] = b.get(e["site"], 0.0) + (e["amount"] if e["kind"]=="earning" else -abs(e["amount"]))
    return b

def total(): return round(sum(balances().values()), 2)

def report():
    b = balances()
    if not b: core.log("لا أرباح مسجّلة","warn"); return
    print("\n%-22s %10s %8s  %s" % ("المصدر","الرصيد","الحد","الحالة")); print("-"*58)
    for s,v in sorted(b.items(), key=lambda x:-x[1]):
        try: mn = by_id(s)["payout_min"]
        except Exception: mn = 0
        print("%-22s %10s %8s  %s" % (s, "$%.2f"%v, "$%g"%mn, "✓ جاهز" if v>=mn else "ينقص $%.2f"%(mn-v)))
    print("-"*58); print("%-22s %10s" % ("الإجمالي","$%.2f"%total()))
