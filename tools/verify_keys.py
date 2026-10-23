#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry
SUSPECT = re.compile(r"^(install|python|pip|true|false|none|undefined|x+)$", re.I)

def main():
    ok, sus, empty = [], [], []
    for n in registry.ALL:
        v = core.env(n["key_env"])
        if not v: empty.append(n["id"])
        elif SUSPECT.match(v) or len(v) < 3: sus.append((n["id"], n["key_env"], v))
        else: ok.append(n["id"])
    print("\n" + core.C['b'] + "══ تحقق المفاتيح ══" + core.C['x'])
    core.log("صحيحة: " + str(len(ok)), "ok")
    core.log("مشكوك: " + str(len(sus)), "warn" if sus else "ok")
    for i, k, v in sus: print("    " + i.ljust(16) + " " + k.ljust(22) + " = " + v[:36])
    core.log("فارغة: " + str(len(empty)), "info")
    return 0 if not sus else 1

if __name__ == "__main__": sys.exit(main())
