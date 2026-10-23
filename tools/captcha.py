#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import json, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
def key(): return core.env("CAPTCHA_KEY")
def solve(sitekey, url, tries=30):
    k = key()
    if not k: return ""
    r = core.http("https://2captcha.com/in.php?key=%s&method=userrecaptcha&googlekey=%s&pageurl=%s&json=1" % (k,sitekey,url))
    try: rid = json.loads(r["text"]).get("request")
    except Exception: return ""
    if not rid: return ""
    for _ in range(tries):
        time.sleep(5)
        rr = core.http("https://2captcha.com/res.php?key=%s&action=get&id=%s&json=1" % (k,rid))
        try:
            d = json.loads(rr["text"])
            if d.get("status")==1: return d["request"]
        except Exception: pass
    return ""
