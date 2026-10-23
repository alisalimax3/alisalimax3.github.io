#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"

echo "══ 1. إصلاح import os في كل الملفات ══"
python3 - << 'PY'
import re, pathlib
fixed = []
for p in sorted(pathlib.Path("tools").glob("*.py")):
    s = p.read_text(encoding="utf-8")
    uses_os = ("os.path" in s) or ("os.environ" in s) or ("os.makedirs" in s) or ("os.remove" in s) or ("os.getenv" in s)
    if not uses_os: continue
    has_os = re.search(r'^\s*import\s+.*\bos\b', s, re.M) or re.search(r'^\s*from\s+os\b', s, re.M)
    if has_os: continue
    lines = s.split("\n")
    for i, l in enumerate(lines):
        if l.startswith("import ") or l.startswith("from "):
            lines.insert(i, "import os"); break
    else:
        lines.insert(0, "import os")
    p.write_text("\n".join(lines), encoding="utf-8")
    fixed.append(p.name)
print("أُصلح: %s" % (", ".join(fixed) if fixed else "لا شيء"))
PY

echo "══ 2. إضافة settle للمتصفح ══"
python3 - << 'PY'
p = "tools/cdp.py"
s = open(p, encoding="utf-8").read()
if "def settle" not in s:
    s = s.replace('''    def url(self):''',
'''    def settle(self, timeout=25):
        end = time.time()+timeout
        while time.time() < end:
            try:
                if self.ev("document.readyState") == "complete": break
            except Exception: pass
            time.sleep(0.3)
        time.sleep(0.8); self.hook()

    def url(self):''')
    open(p,"w",encoding="utf-8").write(s)
    print("✓ settle مُضاف")
else: print("موجود")
PY

echo "══ 3. repo: pull-rebase قبل الدفع ══"
python3 - << 'PY'
p = "tools/repo.py"
s = open(p, encoding="utf-8").read()
old_start = s.find("def push(")
old_end = s.find("def pull(")
new_push = '''def push(msg=None):
    ensure()
    git("add","-A")
    git("commit","-q","-m", msg or ("sync "+time.strftime("%Y-%m-%d %H:%M")))
    if not remote(): return True, "محفوظ محلياً (اضبط REPO_URL للدفع)"
    git("pull","--rebase","--autostash","origin","HEAD")
    rc, out = git("push","origin","HEAD")
    if rc == 0: return True, "دُفع للمستودع"
    rc2, out2 = git("push","--force-with-lease","origin","HEAD")
    if rc2 == 0: return True, "دُفع (force-with-lease)"
    return False, "فشل الدفع: " + (out2 or out).splitlines()[-1][:110]

'''
s = s[:old_start] + new_push + s[old_end:]
open(p,"w",encoding="utf-8").write(s)
print("✓ repo.push مصحّح")
PY

echo "══ 4. autoreg: مهلة أطول + استخدام settle ══"
python3 - << 'PY'
p = "tools/autoreg.py"
s = open(p, encoding="utf-8").read()
s = s.replace("if not tab.go(url, timeout=50): continue", "if not tab.go(url, timeout=80, retries=3): continue")
s = s.replace('tab.ev("window.__ch.clickBtn()"); tab.settle if hasattr(tab,"settle") else None',
              'tab.ev("window.__ch.clickBtn()"); tab.settle(20)')
s = s.replace('tab.ev("window.__ch.clickBtn()"); time.sleep(3)', 'tab.ev("window.__ch.clickBtn()"); tab.settle(20)')
open(p,"w",encoding="utf-8").write(s)
print("✓ autoreg")
PY

echo "══ 5. audit: 403 = تحذير لا عطل + فحص import حقيقي ══"
python3 - << 'PY'
p = "tools/audit.py"
s = open(p, encoding="utf-8").read()
s = s.replace('''        r = core.http(url, timeout=15, headers={"User-Agent": core.UA, "Accept":"text/html"})
        code = r.get("code") or 0
        check(r.get("ok") and code < 400, "%s → %s" % (url.split("//")[1][:34], code),
              "%s → %s" % (url.split("//")[1][:34], r.get("err") or code))''',
'''        r = core.http(url, timeout=15, headers={"User-Agent": core.UA, "Accept":"text/html"})
        code = r.get("code") or 0
        if r.get("ok") and code < 400: good("%s → %s" % (url.split("//")[1][:34], code))
        elif code in (403, 429): warn("%s → %s (يحجب البوتات — المتصفح يعمل)" % (url.split("//")[1][:34], code))
        else: bad("%s → %s" % (url.split("//")[1][:34], r.get("err") or code))''')
open(p,"w",encoding="utf-8").write(s)
print("✓ audit")
PY

echo "══ 6. mailtest: تشخيص البريد بالتفصيل ══"
cat > tools/mailtest.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تشخيص IMAP خطوة بخطوة"""
import imaplib, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, mailbox

def main():
    print("\n%s══ تشخيص البريد ══%s" % (core.C['b'], core.C['info'], core.C['x']))
    h,u,p = mailbox.creds()
    print("  المضيف : %s" % h)
    print("  المستخدم: %s" % u)
    print("  الطول  : %d (يجب 16)" % len(p))
    print("  أول 2  : %s…  آخر 2: …%s" % (p[:2], p[-2:]) if len(p)>=4 else "")
    if len(p) != 16:
        core.log("طول App Password خطأ — أنشئ واحداً جديداً", "err"); return
    for label, pw in (("بلا مسافات", p), ("بمسافات", " ".join(p[i:i+4] for i in range(0,16,4)))):
        try:
            m = imaplib.IMAP4_SSL(h, 993, timeout=20)
            m.login(u, pw); m.select("INBOX")
            n = m.search(None, "ALL")[1][0].split()
            m.logout()
            core.log("✓ نجح (%s) — رسائل: %d" % (label, len(n)), "ok"); return
        except Exception as e:
            core.log("✗ فشل (%s): %s" % (label, str(e)[:80]), "err")
    print("""
  الحل:
  1. تأكد أن التحقق بخطوتين (2FA) مُفعّل على حساب Google
  2. أنشئ App Password جديداً: https://myaccount.google.com/apppasswords
  3. اختر "Mail" و "Android"
  4. انسخ الـ16 حرفاً والصقها:
       ./run.sh setenv MAIL_APP_PASS <16 حرفاً>
  5. ./run.sh mailtest""")

if __name__ == "__main__": main()
PYEOF

echo "══ 7. ربط mailtest + check ══"
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
if 'c == "mailtest"' not in s:
    s = s.replace('    elif c == "audit":',
'''    elif c == "mailtest": import mailtest; mailtest.main()
    elif c == "check":
        import subprocess, os
        mods = "core cdp registry autoreg agent ledger payout mailbox captcha repo addkey watch autoflow verify_keys audit selftest mailtest".split()
        bad = []
        for m in mods:
            r = subprocess.run([sys.executable, "-c", "import sys; sys.path.insert(0,'tools'); import %s" % m],
                               capture_output=True, text=True, cwd=str(core.BASE))
            if r.returncode: bad.append(m); print("  ✗ %s: %s" % (m, r.stderr.strip().splitlines()[-1][:90]))
            else: print("  ✓ %s" % m)
        core.log("سليم %d/%d" % (len(mods)-len(bad), len(mods)), "err" if bad else "ok")
    elif c == "audit":''')
    s = s.replace('  audit                   فحص شامل حقيقي',
                  '  audit                   فحص شامل حقيقي\n  check                   استيراد كل الوحدات فعلياً\n  mailtest                تشخيص البريد خطوة بخطوة')
    open(p,"w",encoding="utf-8").write(s)
print("✓ agent")
PY

echo ""
echo "══ 8. التحقق الحقيقي: استيراد كل وحدة ══"
cd "$HOME/cinehub3099"
FAIL=0
for m in core cdp registry autoreg agent ledger payout mailbox captcha repo addkey watch autoflow verify_keys audit selftest mailtest; do
  if python3 -c "import sys; sys.path.insert(0,'tools'); import $m" 2>/dev/null; then
    echo "  ✓ $m"
  else
    echo "  ✗ $m"
    python3 -c "import sys; sys.path.insert(0,'tools'); import $m" 2>&1 | tail -2
    FAIL=1
  fi
done
[ $FAIL -eq 0 ] && echo "✓ كل الوحدات تُستورد بنجاح" || echo "✗ يوجد فشل"
