#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def main():
    print("\n" + core.C['b'] + "══ رمز الكابتشا ══" + core.C['x'])
    k = core.env("CAPTCHA_KEY")
    if not k:
        print("""  غير مضبوط — الوكل ينقر آلياً على المربع فقط.
  للحل الكامل (حتى الصور):
    1) https://2captcha.com → حساب → أضف رصيداً ($3 ≈ 1000 كابتشا)
    2) انسخ API Key
    3) ./run.sh setenv CAPTCHA_KEY <المفتاح>""")
        return
    print("  الطول: " + str(len(k)) + "  (يجب 32)")
    if len(k) != 32:
        core.log("طول المفتاح خطأ — انسخه كاملاً من 2captcha", "err")
    r = core.http("https://2captcha.com/res.php?key=" + k + "&action=getbalance&json=1", timeout=25)
    try:
        d = json.loads(r["text"])
        if str(d.get("status")) == "1":
            core.log("✓ صالح — الرصيد: $" + str(d.get("request")), "ok")
        else:
            core.log("✗ " + str(d.get("request")), "err")
    except Exception:
        core.log("✗ رد غير مفهوم: " + r["text"][:80], "err")

if __name__ == "__main__": main()
