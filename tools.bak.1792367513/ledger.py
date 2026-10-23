#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""دفتر الأرباح والسحوبات"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
from registry import by_id

L = core.DATA / "ledger.json"

def _d():
    d = core.load(L, {"entries": []})
    if not isinstance(d, dict): d = {}
    d.setdefault("entries", [])
    return d

def add(site_id, amount, kind="earning", currency="USD", note=""):
    d = _d()
    d["entries"].append({"site": site_id, "amount": float(amount), "kind": kind,
                         "currency": currency, "note": note,
                         "at": time.strftime("%Y-%m-%d %H:%M:%S")})
    core.save(L, d)
    core.log(f"{'ربح' if kind=='earning' else 'سحب'}: {site_id} = {amount} {currency}", "ok")

def balances():
    d = _d(); b = {}
    for e in d["entries"]:
        b.setdefault(e["site"], 0.0)
        b[e["site"]] += e["amount"] if e["kind"] == "earning" else -abs(e["amount"])
    return b

def total():
    return sum(balances().values())

def report():
    b = balances()
    if not b: core.log("لا توجد أرباح مسجّلة بعد", "warn"); return
    print(f"\n{'المصدر':<24}{'الرصيد':>10}{'الحد':>8}  الحالة")
    print("-"*60)
    for s, v in sorted(b.items(), key=lambda x: -x[1]):
        try: mn = by_id(s)["payout_min"]
        except Exception: mn = 0
        st = "✓ جاهز للسحب" if v >= mn else f"يحتاج ${mn-v:.2f}"
        print(f"{s:<24}{'$'+format(v,'.2f'):>10}{'$'+str(mn):>8}  {st}")
    print("-"*60)
    print(f"{'الإجمالي':<24}{'$'+format(total(),'.2f'):>10}")
