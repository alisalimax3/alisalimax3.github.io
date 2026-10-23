#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import email, imaplib, re, sys, time
from email.header import decode_header
from html import unescape
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
LINK = re.compile(r'https?://[^\s"\'<>\])]+')
OKRX = re.compile(r'(verif|confirm|activat|validate|welcome|signup|register)', re.I)
def creds():
    host = core.env("MAIL_IMAP_HOST") or "imap.gmail.com"
    user = core.env("MAIL_USER") or core.env("MY_EMAIL") or core.env("GMAIL_USER")
    pw = core.env("MAIL_APP_PASS") or core.env("GMAIL_APP_PASSWORD") or core.env("MAIL_PASS") or ""
    return host, user, pw.replace(" ","").replace("-","").strip()
def configured(): return all(creds())
def test():
    h,u,p = creds()
    if not (u and p): return False, "MAIL_USER/MAIL_APP_PASS فارغان"
    try:
        m = imaplib.IMAP4_SSL(h,993,timeout=20); m.login(u,p); m.select("INBOX"); m.logout()
        return True, "IMAP ناجح: %s" % u
    except Exception as e: return False, "IMAP: %s" % str(e)[:90]
def _dec(v):
    if not v: return ""
    return " ".join(p.decode(e or "utf-8","ignore") if isinstance(p,bytes) else p for p,e in decode_header(v))
def _body(msg):
    t = ""
    if msg.is_multipart():
        for p in msg.walk():
            if p.get_content_type() in ("text/plain","text/html"):
                try: t += p.get_payload(decode=True).decode(p.get_content_charset() or "utf-8","ignore")
                except Exception: pass
    else:
        try: t = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8","ignore")
        except Exception: pass
    return unescape(t)
def fetch(limit=25):
    h,u,p = creds()
    if not (h and u and p): return []
    try:
        m = imaplib.IMAP4_SSL(h,993,timeout=25); m.login(u,p); m.select("INBOX")
        _,d = m.search(None,"ALL"); ids = d[0].split()[-limit:]; out=[]
        for i in reversed(ids):
            _,raw = m.fetch(i,"(RFC822)")
            if raw and raw[0]: out.append(email.message_from_bytes(raw[0][1]))
        m.logout(); return out
    except Exception as e: core.log("IMAP: %s" % str(e)[:70],"warn"); return []
def confirm(hint="", tries=5, wait=12):
    for a in range(tries):
        for msg in fetch():
            blob = _dec(msg.get("Subject","")) + " " + _dec(msg.get("From",""))
            if hint and hint.lower() not in blob.lower(): continue
            if not OKRX.search(blob): continue
            for link in LINK.findall(_body(msg)):
                l = link.rstrip(".,;)")
                if OKRX.search(l) or "verif" in l.lower() or "confirm" in l.lower():
                    r = core.http(l, timeout=25)
                    core.log("تفعيل %s (%s)" % ("نجح" if r.get("ok") else "فشل", r.get("code")), "ok" if r.get("ok") else "warn")
                    return True
        if a < tries-1: time.sleep(wait)
    return False
