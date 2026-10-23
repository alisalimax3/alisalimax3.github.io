#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""خزينة: الوارد يُحجز. الوكيل لا يصرف. المالك وحده يُفرج. قيد فريد."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

V = "data/vault.json"
POLICY = {"agent_can_spend": False, "only_owner_withdraw": True,
          "owner_cut_pct": 20, "reserve_pct": 100,
          "note": "الرصيد محفوظ. لا يُصرف إلا بإفراج صريح من المالك."}

def _v():
    d = core.load(V, None)
    if not isinstance(d, dict):
        d = {"schema": 1, "created": time.strftime("%F %H:%M"), "balance_usd": 0.0,
             "reserved_usd": 0.0, "released_usd": 0.0, "withdrawn_usd": 0.0,
             "entries": {}, "withdrawals": [], "policy": POLICY}
    d.setdefault("entries", {}); d.setdefault("withdrawals", [])
    d["policy"] = POLICY
    return d

def sync():
    """يسحب المؤكد والمدفوع من الدفتر إلى الخزينة بقيد فريد — لا تكرار."""
    d = _v(); r = RE.apply_ledger(); led = RE._led()
    added = 0.0
    for k, t in led.get("tx", {}).items():
        if t.get("state") not in ("approved", "paid"): continue
        ek = "tx::" + k
        if ek in d["entries"]: continue
        usd = t.get("amount_usd") or 0.0
        d["entries"][ek] = {"src": t.get("provider"), "amount_usd": usd,
                            "state": t.get("state"), "at": time.strftime("%F %H:%M")}
        added += usd
    bal = round(sum(e["amount_usd"] for e in d["entries"].values()), 4)
    d["balance_usd"] = bal
    d["reserved_usd"] = round(bal * POLICY["reserve_pct"] / 100.0, 4)
    d["released_usd"] = round(max(0.0, bal - d["reserved_usd"]), 4)
    d["updated"] = time.strftime("%F %H:%M")
    core.save(V, d)
    return d, added

def owner_cut(user_reward_usd):
    return round(float(user_reward_usd) * POLICY["owner_cut_pct"] / 100.0, 6)

def release(amount, note=""):
    d = _v()
    a = float(amount)
    if a > d["released_usd"] + 1e-9:
        return False, "المتاح للإفراج $%.4f فقط" % d["released_usd"]
    d["released_usd"] = round(d["released_usd"] - a, 4)
    d["withdrawals"].append({"key": "rel::%s::%.4f" % (time.strftime("%F"), a),
                             "amount_usd": a, "note": note, "at": time.strftime("%F %H:%M"),
                             "by": "owner"})
    core.save(V, d); return True, "أُفرج $%.4f" % a

def withdraw(amount, method="", ref=""):
    d = _v()
    a = float(amount)
    paid = round(sum(w["amount_usd"] for w in d["withdrawals"]), 4)
    if a + paid > d["balance_usd"] + 1e-9:
        return False, "المستلم الكلي سيتجاوز الرصيد"
    d["withdrawals"].append({"key": "wd::%s::%s::%.4f" % (time.strftime("%F"), ref or method, a),
                             "amount_usd": a, "method": method, "ref": ref,
                             "at": time.strftime("%F %H:%M"), "by": "owner"})
    d["withdrawn_usd"] = round(paid + a, 4)
    core.save(V, d); return True, "سُجّل سحب $%.4f" % a

def cli():
    a = sys.argv[1:]
    if not a:
        d, _ = sync()
        print("الرصيد $%.4f · محجوز $%.4f · متاح للإفراج $%.4f · مسحوب $%.4f"
              % (d["balance_usd"], d["reserved_usd"], d["released_usd"], d["withdrawn_usd"]))
        print("السياسة: الوكيل لا يصرف=%s · المالك وحده=%s · حصة المالك من مكافآت المستخدمين=%d%%"
              % (POLICY["agent_can_spend"], POLICY["only_owner_withdraw"], POLICY["owner_cut_pct"]))
    elif a[0] == "sync": d, add = sync(); print("أُضيف $%.4f · الرصيد $%.4f" % (add, d["balance_usd"]))
    elif a[0] == "release" and len(a) > 1: print(release(a[1], a[2] if len(a) > 2 else "")[1])
    elif a[0] == "withdraw" and len(a) > 1: print(withdraw(a[1], a[2] if len(a) > 2 else "")[1])
    elif a[0] == "cut" and len(a) > 1: print("حصة المالك: $%.6f" % owner_cut(a[1]))
    else: print("sync|release <amt>|withdraw <amt> <method>|cut <amt>")

if __name__ == "__main__": cli()
