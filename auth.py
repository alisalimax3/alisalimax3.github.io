#!/usr/bin/env python3
"""مصادقة GitHub بكود — يعطيك رمزًا تدخله في github.com فيصدر توكن لحسابك."""
import json, urllib.request, urllib.parse, time, os, sys

CLIENT_ID = "178c6fc778ccc68e1d6a"   # معرّف عام (عميل gh الرسمي)
SCOPE = "repo"

def post(url, data):
    body = urllib.parse.urlencode(data).encode()
    r = urllib.request.Request(url, data=body,
        headers={"Accept":"application/json","User-Agent":"cinehub-3099"})
    with urllib.request.urlopen(r, timeout=30) as x:
        return json.loads(x.read())

print("→ طلب رمز من GitHub…")
d = post("https://github.com/login/device/code", {"client_id":CLIENT_ID,"scope":SCOPE})
code = d["user_code"]; uri = d["verification_uri"]
print()
print("  ┌────────────────────────────────┐")
print("  │   الكود:  %-20s│" % code)
print("  └────────────────────────────────┘")
print("  افتح: %s" % uri)
print("  أدخل الكود → وافق → انتظر هنا.")
print()
os.system("termux-open-url '%s' >/dev/null 2>&1 || true" % uri)

iv = int(d.get("interval",5)); end = time.time() + int(d.get("expires_in",900))
while time.time() < end:
    time.sleep(iv)
    try:
        t = post("https://github.com/login/oauth/access_token",
            {"client_id":CLIENT_ID,"device_code":d["device_code"],
             "grant_type":"urn:ietf:params:oauth:grant-type:device_code"})
    except Exception:
        continue
    if t.get("access_token"):
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".gh-token")
        open(p,"w").write(t["access_token"].strip())
        os.chmod(p,0o600)
        print("✓ تمت المصادقة — التوكن محفوظ في .gh-token")
        sys.exit(0)
    e = t.get("error")
    if e == "authorization_pending": continue
    if e == "slow_down": iv += 5; continue
    print("✗ %s" % e); sys.exit(1)
print("✗ انتهت صلاحية الكود — أعد التنفيذ")
