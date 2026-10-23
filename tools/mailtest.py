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
