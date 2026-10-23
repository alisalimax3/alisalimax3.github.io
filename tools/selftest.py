#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, cdp, autoreg

FORM = """<!doctype html><html><body><form id="f">
<label for="e">Email</label><input id="e" name="email" type="email">
<label for="p">Password</label><input id="p" name="password" type="password">
<label for="c">Confirm</label><input id="c" name="confirm_password" type="password">
<label for="fn">First</label><input id="fn" name="first_name">
<label for="ln">Last</label><input id="ln" name="last_name">
<label for="u">Username</label><input id="u" name="username">
<label for="w">Website</label><input id="w" name="website">
<label for="co">Country</label><select id="co" name="country"><option value="">--</option>
<option value="US">United States</option><option value="MA">Morocco</option></select>
<label><input id="t" name="terms" type="checkbox"> Agree</label>
<button type="submit" id="s">Sign Up</button></form>
<script>document.getElementById('f').addEventListener('submit',function(e){e.preventDefault();document.title='SIGNED-UP';});</script>
</body></html>"""

def browser_and_form():
    p = core.BASE / ".tmp" / "form.html"
    p.parent.mkdir(parents=True, exist_ok=True); p.write_text(FORM, encoding="utf-8")
    try: ch = cdp.Chrome(str(core.PROFILES / "_selftest"), headless=True, timeout=45)
    except Exception as e:
        core.log("تشغيل المتصفح: " + str(e), "err"); return False
    try:
        t = ch.tab()
        if not t.go("https://example.com", timeout=35):
            core.log("فشل تصفح الإنترنت", "err"); return False
        core.log("تصفح ناجح: " + (t.title() or "?"), "ok")
        if not t.ev("typeof window.__ch!=='undefined'"):
            core.log("المحقون غائب", "err"); return False
        core.log("المحقون __ch نشط", "ok")
        if not t.go("file://" + str(p), timeout=20):
            core.log("فشل تحميل النموذج", "err"); return False
        n = len(t.ev("window.__ch.scanAll()") or [])
        core.log("حقول مكتشفة: " + str(n), "ok" if n >= 8 else "err")
        pr = {"email":"test@example.com","password":"Passw0rd!23","first":"Ali","last":"Salim",
              "username":"alisalimax3","site":"https://alisalimax3.github.io","country":"MA",
              "country_name":"Morocco","phone":"","company":"","city":"","zip":"","address":"","telegram":""}
        f = autoreg.fill(t, pr); c = autoreg.pick_country(t, pr); b = autoreg.tick(t)
        core.log("عُبّئ: " + str(f) + " | بلد: " + str(c or "-") + " | موافقات: " + str(b), "ok" if f >= 6 else "err")
        ge = t.ev("document.getElementById('e').value")
        gu = t.ev("document.getElementById('u').value")
        gc = t.ev("document.getElementById('co').value")
        gt = t.ev("document.getElementById('t').checked")
        core.log("تحقق: email=" + str(ge) + " user=" + str(gu) + " country=" + str(gc) + " terms=" + str(gt), "info")
        okv = (ge == "test@example.com" and gu == "alisalimax3" and gc == "MA" and gt is True)
        core.log("القيم دخلت فعلاً: " + ("نعم" if okv else "لا"), "ok" if okv else "err")
        btn = t.ev("window.__ch.submitAll()")
        core.log("زر الإرسال: " + (btn or "لم يُعثر"), "ok" if btn else "warn")
        if btn:
            t.ev("window.__ch.clickBtn()"); time.sleep(1.5)
            core.log("بعد الإرسال: " + (t.title() or "?"), "info")
        return bool(okv and btn)
    finally: ch.close()

def main():
    print("\n" + core.C['b'] + "══ اختبار ذاتي حقيقي ══" + core.C['x'])
    r = browser_and_form()
    print("\n" + ("✓ كل شيء يعمل فعلياً" if r else "✗ يوجد خلل"))
    return 0 if r else 1

if __name__ == "__main__": sys.exit(main())
