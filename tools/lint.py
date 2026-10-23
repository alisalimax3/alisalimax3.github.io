#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يكشف كل عدم توافق بين %s والمعاملات"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

SPEC = re.compile(r'%[sdgfi]|%\.\d+f|%%')

def scan():
    bad = []
    for f in sorted(os.listdir("tools")):
        if not f.endswith(".py") or f == "lint.py": continue
        for i, line in enumerate(open("tools/"+f, encoding="utf-8"), 1):
            if "% (" not in line and "%(" not in line: continue
            specs = len(SPEC.findall(line))
            # عدّ الفواصل على المستوى الأعلى داخل القوسين الأخيرين
            depth = 0; args = 0; started = False
            for ch in line:
                if ch == "(":
                    depth += 1; started = True
                elif ch == ")":
                    depth -= 1
                elif ch == "," and depth == 1 and started:
                    args += 1
            if started and depth == 0:
                args += 1
            if specs != args:
                bad.append((f, i, specs, args, line.strip()[:88]))
    return bad

def main():
    print("\n" + core.C['b'] + "══ فاحص % ══" + core.C['x'])
    bad = scan()
    if not bad:
        core.log("✓ لا أخطاء — كل %s متوافقة", "ok"); return 0
    for f, i, s, a, ln in bad:
        core.log("%s:%d  %d نص مقابل %d معامل\n     %s" % (f, i, s, a, ln), "err")
    return 1

if __name__ == "__main__": sys.exit(main())
