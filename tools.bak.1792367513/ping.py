#!/usr/bin/env python3
import json, os, sys, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, "tools"); import gh
U = gh.login(); S = "https://%s.github.io" % U
def req(u, d=None, h=None, t=45):
    r = urllib.request.Request(u, data=d, headers=h or {"User-Agent": "CineHub"})
    with urllib.request.urlopen(r, timeout=t) as x: return x.status
def xrpc(host):
    b = ('<?xml version="1.0"?><methodCall><methodName>weblogUpdates.ping</methodName><params>'
         '<param><value>CineHub</value></param><param><value>%s</value></param></params></methodCall>' % S).encode()
    return req(host, b, {"Content-Type": "text/xml"})
res = {}
for nm, host in (("pingomatic", "http://rpc.pingomatic.com/"), ("twingly", "https://rpc.twingly.com/")):
    try: res[nm] = xrpc(host)
    except Exception as e: res[nm] = str(e)[:30]
key = next((f[:-4] for f in os.listdir(".") if f.endswith(".txt") and f[:-4].isalnum() and len(f[:-4]) in (8, 32)), None)
if key:
    try:
        b = json.dumps({"host": "%s.github.io" % U, "key": key,
                        "keyLocation": "%s/%s.txt" % (S, key),
                        "urlList": [S + "/", S + "/app.html", S + "/library.html"]}).encode()
        res["indexnow"] = req("https://api.indexnow.org/indexnow", b, {"Content-Type": "application/json"})
    except Exception as e: res["indexnow"] = str(e)[:30]
try: res["wayback"] = req("https://web.archive.org/save/" + S + "/", t=90)
except Exception as e: res["wayback"] = str(e)[:30]
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "site": S, "results": res},
          open("data/ping.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ إشعال: " + ", ".join("%s=%s" % (k, v) for k, v in res.items()))
