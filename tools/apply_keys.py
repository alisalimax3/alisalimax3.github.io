#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يقرأ keys.env ويكتب nets.json بحالة كل شبكة (حقيقية لا وهمية)"""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
env = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8", errors="replace"):
        ln = ln.strip()
        if not ln or ln.startswith("#") or "=" not in ln: continue
        k, v = ln.split("=", 1); env[k.strip()] = v.strip()
targets = []
for f in ("signup.json", "platforms_active.json"):
    if not os.path.exists(f): continue
    d = json.load(open(f, encoding="utf-8"))
    targets = d if isinstance(d, list) else d.get("items", [])
    if targets: break
nets = []
for t in targets:
    var = t.get("var") or t.get("key_var") or ""
    v = env.get(var, "") if var else ""
    nets.append({"name": t.get("name"), "min": t.get("min") or "$5", "pay": t.get("pay") or "USDT / Wire",
                 "var": var, "key": ("…" + v[-4:]) if len(v) > 4 else ("*" if v else ""), "has_key": bool(v)})
json.dump({"count": len(nets), "with_key": sum(1 for n in nets if n["has_key"]), "networks": nets},
          open("nets.json", "w"), ensure_ascii=False, indent=1)
print("nets", len(nets), "with_key", sum(1 for n in nets if n["has_key"]))
