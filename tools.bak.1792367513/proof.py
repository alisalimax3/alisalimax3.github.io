#!/usr/bin/env python3
import hashlib, json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CRIT = ["index.html","app.html","library.html","links.html","earn.html","owner.html","proof.html",
        "ads.json","hits.js","robots.txt","sitemap.xml","verify.txt","manifest.json","sw.js",
        "gh.py",".github/workflows/agent.yml","tools/tasks.py","tools/linkfix.py","tools/seo.py"]
man = {"at": time.strftime("%Y-%m-%dT%H:%M:%SZ"), "files": {}}
os.makedirs("proof", exist_ok=True)
for f in CRIT:
    if not os.path.exists(f): continue
    h = hashlib.sha256(open(f, "rb").read()).hexdigest()
    man["files"][f] = h[:32]
    open("proof/" + f.replace("/", "_") + ".sha", "w").write(h + "\n")
man["count"] = len(man["files"])
man["root"] = hashlib.sha256("".join(sorted(man["files"].values())).encode()).hexdigest()[:32]
json.dump(man, open("proof/manifest.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ مانيفست %d · جذر %s" % (man["count"], man["root"]))
