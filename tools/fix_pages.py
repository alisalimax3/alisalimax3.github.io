#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""RTL + viewport + عدّاد في الصفحات الموجودة."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
SKIP = {"promote-adult.html","promote.html","adult-networks.html","networks.html","providers.html","owner.html","share.html"}

def fix(p, depth):
    s = open(p, encoding="utf-8").read(); o = s
    m = re.search(r"<html([^>]*)>", s)
    if m and 'dir="rtl"' not in m.group(1):
        s = s[:m.start()] + '<html%s lang="ar" dir="rtl">' % re.sub(r'\s*(lang|dir)="[^"]*"', "", m.group(1)) + s[m.end():]
    if "viewport" not in s[:600] and "<head>" in s:
        s = s.replace("<head>", '<head><meta name="viewport" content="width=device-width,initial-scale=1">', 1)
    if "hits.js" not in s and "</body>" in s and depth <= 1:
        s = s.replace("</body>", '<script src="%shits.js" defer></script>\n</body>' % ("../" * depth), 1)
    if s != o: core.write_if_changed(p, s); return True
    return False

def main():
    with core.lock("fix_pages", 1800) as got:
        if not got: print("  · مقفول"); return
        n = 0
        for d, depth in ((".", 0), ("adult", 1)):
            if not os.path.isdir(d): continue
            for f in sorted(os.listdir(d)):
                if f.endswith(".html") and f not in SKIP and fix(os.path.join(d, f), depth): n += 1
        print("  ✓ أُصلحت %d صفحة" % n)

if __name__ == "__main__": main()
