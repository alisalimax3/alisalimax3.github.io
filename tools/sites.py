#!/usr/bin/env python3
import sys, os, json, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
F = pathlib.Path(core.DATA) / "sites.json"

def load(): return json.loads(F.read_text(encoding="utf-8")) if F.exists() else []
def save(d): F.write_text(json.dumps(d, indent=1, ensure_ascii=False), encoding="utf-8")

def main():
    a = sys.argv[1:]
    if not a or a[0] == "list":
        d = load(); print("مواقع مرتبطة: %d" % len(d))
        for s in d: print("   ", s["domain"], "→", s.get("path", "?"))
        return
    if a[0] == "add" and len(a) > 1:
        dom = a[1].replace("https://", "").replace("http://", "").rstrip("/")
        d = load()
        if any(s["domain"] == dom for s in d): print("موجود مسبقاً"); return
        path = os.path.expanduser(a[2]) if len(a) > 2 else os.path.expanduser("~/" + dom)
        d.append({"domain": dom, "path": path}); save(d)
        print("✓ أُضيف", dom, "→", path); return
    if a[0] == "del" and len(a) > 1:
        save([s for s in load() if s["domain"] != a[1]]); print("✓ حُذف"); return
    print("الاستخدام: sites.py [list | add <domain> [path] | del <domain>]")

if __name__ == "__main__":
    main()
