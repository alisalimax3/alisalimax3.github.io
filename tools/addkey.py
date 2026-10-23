#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, repo
from registry import by_id, by_cat, pending
def _ex(net, raw):
    raw = (raw or "").strip()
    if not raw: return ""
    if net.get("key_regex"):
        m = re.search(net["key_regex"], raw)
        if m: return m.group(1)
    return raw.split()[0]
def add(net_id, value=None, openit=True):
    net = by_id(net_id)
    print("\n%s══ %s ══%s" % (core.C['b'], net["name"], core.C['x']))
    print("  %s\n  المفتاح: %s | حد: $%s" % (net["signup"], net["key_env"], net["payout_min"]))
    if openit:
        core.openurl(net["signup"]); core.log("فُتح","info")
    if value is None:
        try: value = input("\nالصق المفتاح (Enter للتخطي): ")
        except EOFError: value = ""
    v = _ex(net, value)
    if not v: core.log("تخطي","warn"); return False
    core.set_env(net["key_env"], v); core.log("✓ %s = %s" % (net["key_env"], v), "ok")
    d = core.load("data/registrations.json", {})
    d[net_id] = {"name":net["name"],"status":"key_set","key":v,"at":time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save("data/registrations.json", d)
    ok,m = repo.push("key: %s" % net_id); core.log(m, "ok" if ok else "warn"); return True
def missing(cat=None):
    items = by_cat(cat) if cat else pending()
    items = [n for n in items if not core.env(n["key_env"])]
    if not items: core.log("لا شيء ناقص","ok"); return
    core.log("%d موقع — Enter للتخطي" % len(items), "info")
    for i,n in enumerate(items,1):
        print("\n[%d/%d]" % (i,len(items)))
        try: add(n["id"])
        except KeyboardInterrupt: break
