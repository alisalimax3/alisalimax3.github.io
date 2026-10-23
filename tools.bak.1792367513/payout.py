#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""محرّك السحب الحقيقي — يجهّز كل موقع جاهز للسحب"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ledger
from registry import by_id

P = core.DATA / "payouts.json"
DEFAULT = {"wallets": {"USDT_TRC20":"","USDT_ERC20":"","BTC":"","ETH":"","PAYPAL":"","PAYONEER":"","PAYEER":"","WISE":"","SKRILL":"","BANK_IBAN":""},
           "preferred": ["USDT_TRC20","PAYPAL","PAYONEER"]}

def cfg():
    d = core.load(P, None)
    if not d:
        core.save(P, DEFAULT); return DEFAULT
    return d

def wallet():
    w = cfg()["wallets"]
    print("\nالمحافظ المُسجّلة:")
    for k, v in w.items():
        print(f"  {k:<12} {'✓ '+v if v else '✗ فارغة'}")
    print(f"\nللتعديل: python3 tools/agent.py wallet <الاسم> <القيمة>")

def set_wallet(name, value):
    d = cfg(); d["wallets"][name.upper()] = value
    core.save(P, d); core.log(f"{name.upper()} = {value}", "ok")

def ready():
    b = ledger.balances(); out = []
    for s, v in b.items():
        try: mn = by_id(s)["payout_min"]
        except Exception: continue
        if v >= mn: out.append((s, v, mn))
    return out

def plan():
    r = ready()
    if not r: core.log("لا يوجد رصيد كافٍ للسحب بعد", "warn"); ledger.report(); return
    w = cfg()["wallets"]
    print(f"\n{'='*64}\n  خطة السحب — {len(r)} موقع جاهز\n{'='*64}")
    for s, v, mn in sorted(r, key=lambda x: -x[1]):
        n = by_id(s)
        meth = [m for m in n["methods"] if w.get(m.upper().replace(" ","_"))]
        print(f"\n▶ {n['name']}  (${v:.2f})")
        print(f"  الصفحة: {n['payout_page']}")
        print(f"  الطرق المتاحة: {', '.join(n['methods'])}")
        print(f"  الأنسب لك: {', '.join(meth) if meth else 'أضف محفظة أولاً'}")
    print(f"\n{'='*64}\n  الإجمالي القابل للسحب: ${sum(x[1] for x in r):.2f}\n{'='*64}")
    core.openurl(r[0][0] and by_id(r[0][0])["payout_page"])

def auto_open():
    for s, v, mn in ready():
        core.openurl(by_id(s)["payout_page"])
