#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ledger
from registry import by_id
P = core.DATA / "payouts.json"
DEF = {"wallets":{"USDT_TRC20":"","BTC":"","PAYPAL":"","PAYONEER":"","PAYEER":"","WISE":"","SKRILL":"","BANK_IBAN":""},
       "preferred":["USDT_TRC20","PAYPAL","PAYONEER"]}
def cfg():
    d = core.load(P, None)
    if not d: core.save(P, DEF); return DEF
    for k,v in DEF.items(): d.setdefault(k,v)
    for k,v in DEF["wallets"].items(): d["wallets"].setdefault(k,"")
    return d
def wallet():
    w = cfg()["wallets"]; print("\nالمحافظ:")
    for k,v in w.items(): print("  %-12s %s" % (k, ("✓ "+v) if v else "✗ فارغة"))
    print("\nللتعديل: ./run.sh wallet USDT_TRC20 <عنوان>")
def set_wallet(n,v):
    d = cfg(); d["wallets"][n.upper()] = v; core.save(P,d); core.log("%s = %s" % (n.upper(),v),"ok")
def ready():
    b = ledger.balances(); out=[]
    for s,v in b.items():
        try: mn = by_id(s)["payout_min"]
        except Exception: continue
        if v >= mn: out.append((s,v,mn))
    return out
def plan():
    r = ready()
    if not r: core.log("لا رصيد كافٍ","warn"); ledger.report(); return
    w = cfg()["wallets"]
    print("\n%s══ خطة السحب: %d موقع ══%s" % (core.C['b'], len(r), core.C['x']))
    for s,v,mn in sorted(r,key=lambda x:-x[1]):
        n = by_id(s)
        best = [m for m in n["methods"] if w.get(m.upper().replace(" ","_"))]
        print("\n▶ %s ($%.2f)\n  %s\n  طرق: %s\n  الأنسب: %s" % (n["name"],v,n["payout_page"],", ".join(n["methods"]),", ".join(best) or "أضف محفظة"))
    print("\nالإجمالي القابل للسحب: $%.2f" % sum(x[1] for x in r))
    if r: core.openurl(by_id(r[0][0])["payout_page"])
