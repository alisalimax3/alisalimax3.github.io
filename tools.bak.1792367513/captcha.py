#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""حل الكابتشا عبر 2captcha (اختياري) — يكسر آخر حاجز"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

API = "https://2captcha.com"

def key(): return core.env("CAPTCHA_KEY")

def solve_recaptcha(sitekey, url, tries=30):
    k = key()
    if not k: return ""
    r = core.http(f"{API}/in.php?key={k}&method=userrecaptcha&googlekey={sitekey}&pageurl={url}&json=1")
    if not r.get("ok"): return ""
    try: import json; rid = json.loads(r["text"]).get("request")
    except Exception: return ""
    for _ in range(tries):
        time.sleep(5)
        rr = core.http(f"{API}/res.php?key={k}&action=get&id={rid}&json=1")
        try:
            import json; d = json.loads(rr["text"])
            if d.get("status") == 1: return d["request"]
        except Exception: pass
    return ""

def inject(page, token):
    if not token: return
    page.evaluate("""(t)=>{document.querySelectorAll('#g-recaptcha-response,textarea[name="g-recaptcha-response"]').forEach(e=>{e.style.display='block';e.value=t;});}""", token)
