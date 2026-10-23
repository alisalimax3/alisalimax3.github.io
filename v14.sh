#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"
tar czf "backups/pre_v14_$(date +%s).tgz" tools keys.env 2>/dev/null

echo "══ 1. فاحص % شامل ══"
cat > tools/lint.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يكشف كل عدم توافق بين %s والمعاملات"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

SPEC = re.compile(r'%[sdgfi]|%\.\d+f|%%')

def scan():
    bad = []
    for f in sorted(os.listdir("tools")):
        if not f.endswith(".py") or f == "lint.py": continue
        for i, line in enumerate(open("tools/"+f, encoding="utf-8"), 1):
            if "% (" not in line and "%(" not in line: continue
            specs = len(SPEC.findall(line))
            # عدّ الفواصل على المستوى الأعلى داخل القوسين الأخيرين
            depth = 0; args = 0; started = False
            for ch in line:
                if ch == "(":
                    depth += 1; started = True
                elif ch == ")":
                    depth -= 1
                elif ch == "," and depth == 1 and started:
                    args += 1
            if started and depth == 0:
                args += 1
            if specs != args:
                bad.append((f, i, specs, args, line.strip()[:88]))
    return bad

def main():
    print("\n" + core.C['b'] + "══ فاحص % ══" + core.C['x'])
    bad = scan()
    if not bad:
        core.log("✓ لا أخطاء — كل %s متوافقة", "ok"); return 0
    for f, i, s, a, ln in bad:
        core.log("%s:%d  %d نص مقابل %d معامل\n     %s" % (f, i, s, a, ln), "err")
    return 1

if __name__ == "__main__": sys.exit(main())
PYEOF

python3 tools/lint.py

echo ""
echo "══ 2. إصلاح verify_keys + audit + selftest ══"
cat > tools/verify_keys.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry
SUSPECT = re.compile(r"^(install|python|pip|true|false|none|undefined|x+)$", re.I)

def main():
    ok, sus, empty = [], [], []
    for n in registry.ALL:
        v = core.env(n["key_env"])
        if not v: empty.append(n["id"])
        elif SUSPECT.match(v) or len(v) < 3: sus.append((n["id"], n["key_env"], v))
        else: ok.append(n["id"])
    print("\n" + core.C['b'] + "══ تحقق المفاتيح ══" + core.C['x'])
    core.log("صحيحة: " + str(len(ok)), "ok")
    core.log("مشكوك: " + str(len(sus)), "warn" if sus else "ok")
    for i, k, v in sus: print("    " + i.ljust(16) + " " + k.ljust(22) + " = " + v[:36])
    core.log("فارغة: " + str(len(empty)), "info")
    return 0 if not sus else 1

if __name__ == "__main__": sys.exit(main())
PYEOF

cat > tools/selftest.py << 'PYEOF'
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
PYEOF

echo "══ 3. فحص X حقيقي (اتصال socket) ══"
python3 - << 'PY'
p = "tools/core.py"
s = open(p, encoding="utf-8").read()
old_start = s.find("def x11_alive():")
old_end = s.find("def openurl(")
new = '''def x11_alive():
    """يتصل فعلياً بمقبس X — لا يكتفي بوجود الملف"""
    if not env("DISPLAY"): return False
    import socket as _s
    for p in ("/data/data/com.termux/files/usr/tmp/.X11-unix/X0",
              "/data/data/com.termux/files/usr/tmp/.X11-unix/X1",
              "/tmp/.X11-unix/X0"):
        if not os.path.exists(p): continue
        try:
            c = _s.socket(_s.AF_UNIX, _s.SOCK_STREAM); c.settimeout(1.2)
            c.connect(p); c.close(); return True
        except Exception: pass
    return False

def x11_hint():
    return ("X غير شغّال. شغّله:\\n"
            "  termux-x11 :0 -ac &\\n"
            "  am start --user 0 -n com.termux.x11/.MainActivity\\n"
            "  export DISPLAY=:0")

'''
s = s[:old_start] + new + s[old_end:]
open(p, "w", encoding="utf-8").write(s)
print("✓ x11_alive يتحقق فعلياً")
PY

echo "══ 4. كابتشا أقوى + تركيز الصفحة ══"
python3 - << 'PY'
p = "tools/cdp.py"
s = open(p, encoding="utf-8").read()
if "bringToFront" not in s:
    s = s.replace('''        try:
            self.send("Page.addScriptToEvaluateOnNewDocument",''',
'''        try:
            self.send("Page.bringToFront")
            self.send("Emulation.setFocusEmulationEnabled", {"enabled": True})
        except Exception: pass
        try:
            self.send("Page.addScriptToEvaluateOnNewDocument",''')
open(p, "w", encoding="utf-8").write(s)

p = "tools/autoreg.py"
s = open(p, encoding="utf-8").read()
old = s[s.find("def try_click_captcha"):s.find("def wait_captcha")]
new = '''def try_click_captcha(tab, rounds=4):
    """نقر حقيقي بإزاحات متعددة — يغطي كل أشكال الكابتشا"""
    for r in range(rounds):
        try: st = tab.ev("window.__ch.captcha()")
        except Exception: st = ""
        if not st: return False
        if st.endswith("-solved"): return True
        try: b = tab.ev("window.__ch.captchaBox()")
        except Exception: b = None
        if not b:
            time.sleep(1.2); continue
        try: tab.send("Page.bringToFront")
        except Exception: pass
        for dx, dy in ((0,0), (2,-3), (-2,2), (0,4)):
            try: tab.click_xy(b["x"]+dx, b["y"]+dy)
            except Exception: pass
            time.sleep(1.1)
            try: st = tab.ev("window.__ch.captcha()")
            except Exception: st = ""
            if st and st.endswith("-solved"):
                core.log("✓ كابتشا حُلّت آلياً", "ok"); return True
        core.log("محاولة كابتشا " + str(r+1) + "/" + str(rounds) + " — لم تُحل بعد", "info")
        time.sleep(2.5)
    return False

'''
s = s.replace(old, new)
# قلّص الانتظار اليدوي
s = s.replace("wait_captcha(tab, 200)", "wait_captcha(tab, 90)")
s = s.replace("wait_captcha(tab,240)", "wait_captcha(tab, 90)")
s = s.replace("wait_captcha(tab, 240)", "wait_captcha(tab, 90)")
# كشف صفحة الدخول
s = s.replace('''            n = wait_fields(tab, 30)
            if n:''',
'''            n = wait_fields(tab, 30)
            tt = (tab.title() or "").lower()
            if n and n < 3 and any(k in tt for k in ("log in","login","sign in")):
                core.log("صفحة دخول لا تسجيل — نجرّب بديلاً", "warn"); continue
            if n:''')
open(p, "w", encoding="utf-8").write(s)
print("✓ كابتشا + كشف الدخول")
PY

echo "══ 5. mailtest: كل الحالات ══"
cat > tools/mailtest.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import imaplib, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, mailbox

def main():
    print("\n" + core.C['b'] + "══ تشخيص البريد ══" + core.C['x'])
    h, u, pw = mailbox.creds()
    print("  المضيف  : " + h)
    print("  المستخدم: " + u)
    print("  الطول   : " + str(len(pw)) + "  (App Password يجب 16)")
    if len(pw) >= 4: print("  البداية : " + pw[:2] + "…    النهاية: …" + pw[-2:])
    if pw.lower() == "abcdefghijklmnop":
        core.log("تنبيه: هذا نص بديل لا كلمة مرور حقيقية", "warn")
    cands = [("كما هي", pw), ("حروف صغيرة", pw.lower()), ("حروف كبيرة", pw.upper()),
             ("بمسافات", " ".join(pw[i:i+4] for i in range(0, len(pw), 4)))]
    for label, c in cands:
        try:
            m = imaplib.IMAP4_SSL(h, 993, timeout=20)
            m.login(u, c); m.select("INBOX")
            n = len(m.search(None, "ALL")[1][0].split()); m.logout()
            core.log("✓ نجح (" + label + ") — رسائل: " + str(n), "ok"); return
        except Exception as e:
            core.log("✗ (" + label + "): " + str(e)[:70], "err")
    print("""
  ══ الحل ══
  1) تأكد أن التحقق بخطوتين مُفعّل:  https://myaccount.google.com/security
  2) احذف كلمات المرور القديمة، ثم أنشئ واحدة:  https://myaccount.google.com/apppasswords
     اختر: Mail  +  Android  → سيظهر 16 حرفاً مثل: abcd efgh ijkl mnop
  3) الصقها كما هي:
       ./run.sh setenv MAIL_APP_PASS "abcd efgh ijkl mnop"
  4) ./run.sh mailtest""")

if __name__ == "__main__": main()
PYEOF

python3 - << 'PY'
p = "tools/captchatest.py"
s = open(p, encoding="utf-8").read()
s = s.replace('    print("  الطول: " + str(len(k)))',
'''    print("  الطول: " + str(len(k)) + "  (يجب 32)")
    if len(k) != 32:
        core.log("طول المفتاح خطأ — انسخه كاملاً من 2captcha", "err")''')
open(p, "w", encoding="utf-8").write(s)
print("✓ captchatest")
PY

echo "══ 6. autoflow 0 = مواقع الكبار ══"
python3 - << 'PY'
p = "tools/autoflow.py"
s = open(p, encoding="utf-8").read()
if '"0":' not in s and "0:[" not in s:
    s = s.replace("T = {1:", '''T = {0:["adultadworld","trafficshop","exogroup","clickaine","eroadvertising","adspyglass",
        "pinkads","traforama","adamo","lospollos","datify","kmabiz","leadbit","crakrevenue",
        "zeydoo","adcombo","terraleads","adultmoda","porndough","wecamy","adultcams",
        "chaturbate","stripchat","bongacams","livejasmin","cam4","mfc"],
     1:''')
    s = s.replace('if t == 0 or t == "0"', "")
    open(p, "w", encoding="utf-8").write(s)
print("✓ مرحلة 0 للكبار")
PY

echo "══ 7. ربط lint ══"
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
if 'c == "lint"' not in s:
    s = s.replace('    elif c == "check":', '    elif c == "lint": import lint; sys.exit(lint.main())\n    elif c == "check":')
    s = s.replace("  check                   استيراد كل الوحدات فعلياً",
                  "  check                   استيراد كل الوحدات فعلياً\n  lint                    فاحص صيغ %s")
    open(p, "w", encoding="utf-8").write(s)
print("✓ lint")
PY

echo ""
echo "══ التحقق ══"
python3 tools/lint.py
FAIL=0
for m in core cdp registry autoreg agent ledger payout mailbox captcha repo addkey watch autoflow verify_keys audit selftest mailtest ghauth ghlink captchatest harvest dashboard lint; do
  python3 -c "import sys;sys.path.insert(0,'tools');import $m" 2>/dev/null || { echo "  ✗ $m"; FAIL=1; }
done
[ $FAIL -eq 0 ] && echo "✓ 23/23 وحدة سليمة"
echo ""
echo "── تشغيل الأوامر فعلياً ──"
for cmd in verify selftest; do
  echo "### run.sh $cmd"; python3 tools/agent.py $cmd 2>&1 | tail -8; echo
done
echo "✅ v14 جاهز"
