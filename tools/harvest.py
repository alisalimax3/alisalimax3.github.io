#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json, os, subprocess, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
sys.path.insert(0, os.path.join(ROOT, "tools"))
import engines2, gh

BUD = int(os.environ.get("SRC_BUDGET", "150"))
NOPUSH = "--no-push" in sys.argv
G, Y, C, R = "\033[32m", "\033[33m", "\033[36m", "\033[0m"

def run(c, t=1800):
    try:
        p = subprocess.run(c, shell=True, capture_output=True, text=True, timeout=t)
        return ((p.stdout or "") + (p.stderr or "")).strip()
    except Exception as e:
        return str(e)[:200]

def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d

def wr(p, o):
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    json.dump(o, open(p, "w", encoding="utf-8"), ensure_ascii=False)

def main():
    t0 = time.time()
    print(C + "═══ دورة %s ═══" % time.strftime("%Y-%m-%d %H:%M") + R)
    cat = rd("catalog.json", {"items": []}) or {"items": []}
    it = cat.get("items") or []
    seen = set(x.get("i") for x in it if isinstance(x, dict))
    print("المكتبة قبل: %d" % len(it))

    def prog(name, r):
        n = r[0] if isinstance(r, tuple) else 0
        sec = r[1] if isinstance(r, tuple) else 0
        err = r[2] if isinstance(r, tuple) and not isinstance(r[2], list) else ""
        print("  %-16s %s+%-6d%s %.1fs %s" % (name, G if n else Y, n, R, sec, str(err)[:46]))

    print(C + "── حصد من 32 مصدرًا ──" + R)
    res = engines2.run(budget=BUD, progress=prog)
    add = 0
    for name, r in res.items():
        if not isinstance(r[2], list): continue
        for x in r[2]:
            i = x.get("i")
            if not i or i in seen: continue
            seen.add(i); it.append(x); add += 1
    it.sort(key=lambda x: -(x.get("v") or 0))
    cat["items"] = it
    wr("catalog.json", cat)
    print(G + "المكتبة بعد: %d (+%d)" % (len(it), add) + R)

    print(C + "── بناء ──" + R)
    for lbl, c in (("توحيد", "python3 tools/normalize.py"), ("بوسترات", "python3 tools/fix_posters.py"),
                   ("صفحات أفلام", "python3 tools/movie_pages.py"), ("أنواع وكلمات", "python3 tools/pages.py"),
                   ("أقسام", "python3 tools/sections.py"), ("إعلانات", "python3 tools/ads.py"),
                   ("RSS", "python3 tools/feed.py"), ("محفظة", "python3 tools/ledger.py")):
        if not os.path.exists(c.split()[1]): continue
        o = run(c)
        print("  %-12s %s" % (lbl, (o.splitlines() or ["—"])[-1][:100]))

    print(C + "── تتبّع + فهرسة + أموال ──" + R)
    run("python3 tools/track.py")
    run("python3 tools/revenue_sync.py")
    run("python3 tools/boost.py")
    run("python3 tools/money.py")
    run("python3 tools/status.py")
    run("python3 tools/dashboard.py")

    tok = gh.token()
    if tok and not NOPUSH:
        user = gh.login(tok); repo = gh.repo_name()
        if user:
            print(C + "── نشر ──" + R)
            gh.ensure_repo(user, repo, tok)
            run("git add -A")
            ok, out = gh.push(user, repo, tok)
            url = gh.enable_pages(user, repo, tok)
            print(("  %s%s" % (G if ok else Y, (out.splitlines() or ['—'])[-1][:100])) + R)
            print(G + "  الموقع: %s\n  الأموال: %smoney.html" % (url, url) + R)
            st = rd("data/status.json", {}); st["live_url"] = url; wr("data/status.json", st)

    st = rd("agent_state.json", {})
    st.update({"cycles": st.get("cycles", 0) + 1, "items": len(it), "added": add,
               "engines": {k: (v[0] if isinstance(v, tuple) else 0) for k, v in res.items()},
               "last": time.strftime("%Y-%m-%d %H:%M"), "status": "ok"})
    wr("agent_state.json", st)
    print(G + "انتهت الدورة %.1fs | +%d" % (time.time() - t0, add) + R)

if __name__ == "__main__":
    main()
