#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل حقيقي — بلا أسرار في المخرجات."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def main():
    R = {"at": time.strftime("%F %H:%M:%S"), "root": os.getcwd()}
    R["files"] = {}
    for d in (".", "tools", "data", "adult", "go"):
        if os.path.isdir(d):
            R["files"][d] = len([f for f in os.listdir(d) if os.path.isfile(os.path.join(d, f))])
    try:
        R["branch"] = subprocess.run(["git","rev-parse","--abbrev-ref","HEAD"],
                                     capture_output=True,text=True).stdout.strip()
        R["dirty"] = len(subprocess.run(["git","status","--porcelain"],
                          capture_output=True,text=True).stdout.splitlines())
    except Exception: pass
    E = core.env()
    R["secrets"] = {"defined": len(E), "filled": len([k for k in E if E[k]])}
    bad = []
    for d in (".", "data"):
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            if f.endswith(".json"):
                try: json.load(open(os.path.join(d, f), encoding="utf-8"))
                except Exception: bad.append(os.path.join(d, f))
    R["bad_json"] = bad
    rows, src = core.catalog()
    R["catalog"] = {"total": len(rows), "source": src, "adult": len([r for r in rows if core.is_adult(r)])}
    R["pages"] = {"root": len([f for f in os.listdir(".") if f.endswith(".html")]),
                  "adult": len([f for f in os.listdir("adult") if f.endswith(".html")]) if os.path.isdir("adult") else 0}
    os.makedirs("data/audit", exist_ok=True)
    p = "data/audit/full-%s.json" % time.strftime("%F_%H%M")
    core.save(p, R)
    print("  الملفات: %s" % R["files"])
    print("  كتالوج: %s عنوان (%s إباحي) · JSON تالف: %d" % (R["catalog"]["total"], R["catalog"]["adult"], len(bad)))
    print("  أسرار: %d مضبوط · صفحات: %s" % (R["secrets"]["filled"], R["pages"]))
    print("  ✓ %s" % p)

if __name__ == "__main__": main()
