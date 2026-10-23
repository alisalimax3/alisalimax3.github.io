#!/usr/bin/env python3
import json, os, sys, time, urllib.request, urllib.parse
T = os.environ.get("GHTMP") or os.path.expanduser("~/.cinehub-tmp")
os.makedirs(T, exist_ok=True)
CID = os.environ.get("GH_CLIENT_ID", "178c6fc778ccc68e1d6a")
def post(u, d):
    r = urllib.request.Request(u, data=urllib.parse.urlencode(d).encode(),
        headers={"Accept": "application/json", "User-Agent": "CineHub3099"})
    return json.load(urllib.request.urlopen(r, timeout=30))
d = post("https://github.com/login/device/code", {"client_id": CID, "scope": "repo workflow read:org"})
code, url = d["user_code"], d["verification_uri"]
print("\n  ┌──────────────────────────────┐")
print("  │  الرمز:  %-20s│" % code)
print("  └──────────────────────────────┘")
print("  افتح: %s  والصق الرمز ثم Approve\n" % url, flush=True)
try: open(T + "/gh_code", "w").write(code + "\n" + url)
except Exception: pass
iv = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
while time.time() < end:
    time.sleep(iv)
    t = post("https://github.com/login/oauth/access_token",
             {"client_id": CID, "device_code": d["device_code"],
              "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
    if t.get("access_token"):
        open(T + "/gh_tok", "w").write(t["access_token"]); sys.exit(0)
    e = t.get("error", "")
    if e == "slow_down": iv += 5
    elif e == "authorization_pending": print("  … بانتظار الموافقة", flush=True)
    elif e in ("expired_token", "access_denied"): print("  انتهت/رُفضت"); sys.exit(2)
print("  مهلة"); sys.exit(4)
