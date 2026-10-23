#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل محصّن"""
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger

CRIT = ["tools/core.py","tools/registry.py","tools/agent.py","tools/autoreg.py",
        "tools/cdp.py","tools/inject.js","tools/ledger.py","tools/payout.py","tools/mailbox.py",
        "data/profile.json","keys.env"]
DEPS = {"websocket":"websocket-client"}

def main():
    print(f"{core.C['b']}{core.C['info']}\n══ CineHub Doctor v4 ══{core.C['x']}")
    miss, brok, dep_miss = [], [], []

    print(f"\n{core.C['b']}الملفات:{core.C['x']}")
    for f in CRIT:
        p = core.BASE / f
        if not p.exists(): core.log(f"مفقود: {f}", "err"); miss.append(f)
        elif f.endswith(".py"):
            r = subprocess.run([sys.executable, "-m", "py_compile", str(p)], capture_output=True)
            if r.returncode: core.log(f"مكسور: {f}", "err"); brok.append(f)
            else: core.log(f"سليم: {f}", "ok")
        else: core.log(f"موجود: {f}", "ok")

    print(f"\n{core.C['b']}الاعتماديات:{core.C['x']}")
    for mod, pkg in DEPS.items():
        if importlib.util.find_spec(mod): core.log(f"{pkg} مثبّت", "ok")
        else: core.log(f"{pkg} مفقود", "err"); dep_miss.append(pkg)

    print(f"\n{core.C['b']}المصادر:{core.C['x']}")
    core.log(f"مسجّل: {len(registry.ALL)} مصدر | بمفاتيح: {len(registry.with_key())}", "ok")
    core.log(f"الرصيد: ${ledger.total():.2f}", "info")

    print(f"\n{core.C['b']}الملخص:{core.C['x']}")
    core.log(f"مفقودة={len(miss)} مكسورة={len(brok)} اعتماديات={len(dep_miss)}", "warn" if (miss or brok or dep_miss) else "ok")
    if dep_miss:
        print(f"\n  نفّذ: pkg install python-pip chromium && pip install {' '.join(dep_miss)}")
    if not miss and not brok:
        core.log("النظام سليم — جاهز للتنفيذ الحقيقي", "ok")
    return 0 if not (miss or brok) else 2

if __name__ == "__main__": sys.exit(main())
