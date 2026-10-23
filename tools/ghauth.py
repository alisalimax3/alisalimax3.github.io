#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تفويض GitHub مباشر — Device Flow"""
import json, os, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

CLIENT = "178c6fc778ccc68e1d6a"
DEVICE = "https://github.com/login/device/code"
TOKURL = "https://github.com/login/oauth/access_token"
H = {"User-Agent": "cinehub-agent", "Accept": "application/json"}

def _post(url, data):
    body = urllib.parse.urlencode(data).encode()
    with urllib.request.urlopen(urllib.request.Request(url, data=body, headers=H), timeout=30) as r:
        return json.loads(r.read().decode())

def device_flow(scope="repo,workflow"):
    d = _post(DEVICE, {"client_id": CLIENT, "scope": scope})
    if "device_code" not in d:
        core.log("فشل بدء التفويض: " + str(d), "err"); return ""
    print("\n" + core.C['b'] + "══ تفويض GitHub ══" + core.C['x'])
    print("  1) افتح: " + core.C['b'] + d["verification_uri"] + core.C['x'])
    print("  2) الرمز: " + core.C['b'] + d["user_code"] + core.C['x'])
    print("  3) اضغط Authorize\n")
    core.openurl(d["verification_uri"]); core.clipset(d["user_code"])
    core.log("الرمز نُسخ للحافظة", "info")
    iv = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
    while time.time() < end:
        time.sleep(iv)
        try:
            t = _post(TOKURL, {"client_id": CLIENT, "device_code": d["device_code"],
                               "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        except Exception as e:
            core.log("انتظار... " + str(e)[:40], "warn"); continue
        if t.get("access_token"):
            core.log("✓ تم التفويض", "ok"); return t["access_token"]
        e = t.get("error")
        if e == "authorization_pending": continue
        if e == "slow_down": iv += 5; continue
        if e in ("expired_token", "access_denied"):
            core.log("انتهى/رُفض: " + str(e), "err"); return ""
        core.log("انتظار... " + str(e), "info")
    core.log("انتهت المهلة", "err"); return ""

def whoami(tok):
    req = urllib.request.Request("https://api.github.com/user",
        headers={"Authorization": "token " + tok, "User-Agent": "cinehub-agent", "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        return {"_err": str(e)[:90]}

def authorize():
    tok = core.env("GITHUB_TOKEN")
    if tok:
        u = whoami(tok)
        if "login" in u:
            core.log("توكن محفوظ صالح: " + u["login"], "ok"); return tok, u["login"]
    tok = device_flow()
    if not tok: return "", ""
    u = whoami(tok)
    if "login" not in u:
        core.log("توكن غير صالح: " + u.get("_err", "?"), "err"); return "", ""
    core.set_env("GITHUB_TOKEN", tok); core.set_env("GITHUB_USER", u["login"])
    core.log("✓ " + u["login"] + " مرتبط ومحفوظ", "ok")
    return tok, u["login"]
