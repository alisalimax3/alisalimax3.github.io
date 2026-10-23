#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""قراءة بريد التحقق تلقائياً عبر IMAP — يكسر حاجز تأكيد الحساب"""
import email, imaplib, os, re, sys, time
from email.header import decode_header
from html import unescape
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

LINK_RX = re.compile(r'https?://[^\s"\'<>\])]+')
OK_RX = re.compile(r'(verif|confirm|activat|validate|welcome|signup|register)', re.I)

def _dec(v):
    if not v: return ""
    out = []
    for part, enc in decode_header(v):
        out.append(part.decode(enc or "utf-8", "ignore") if isinstance(part, bytes) else part)
    return " ".join(out)

def _body(msg):
    txt = ""
    if msg.is_multipart():
        for p in msg.walk():
            ct = p.get_content_type()
            if ct in ("text/plain", "text/html"):
                try: txt += p.get_payload(decode=True).decode(p.get_content_charset() or "utf-8", "ignore")
                except Exception: pass
    else:
        try: txt = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8", "ignore")
        except Exception: pass
    return unescape(txt)

def configured():
    return all(creds())

def creds():
    host = core.env("MAIL_IMAP_HOST") or "imap.gmail.com"
    user = core.env("MAIL_USER") or core.env("MY_EMAIL") or core.env("GMAIL_USER")
    pw = (core.env("MAIL_APP_PASS") or core.env("GMAIL_APP_PASS") or core.env("MAIL_PASS") or "")
    pw = pw.replace(" ", "").replace("-", "").strip()
    return host, user, pw

def test():
    host, user, pw = creds()
    if not (user and pw): return False, "MAIL_USER / MAIL_APP_PASS فارغان"
    try:
        m = imaplib.IMAP4_SSL(host, 993, timeout=20); m.login(user, pw); m.select("INBOX"); m.logout()
        return True, "دخول IMAP ناجح: %s" % user
    except Exception as e:
        return False, "IMAP: %s" % e

def fetch(since_min=45, limit=25):
    host, user, pw = creds()
    if not (host and user and pw): return []
    try:
        m = imaplib.IMAP4_SSL(host, 993, timeout=25); m.login(user, pw); m.select("INBOX")
        typ, data = m.search(None, "ALL")
        ids = data[0].split()[-limit:]
        out = []
        for i in reversed(ids):
            typ, raw = m.fetch(i, "(RFC822)")
            if raw and raw[0]: out.append(email.message_from_bytes(raw[0][1]))
        m.logout(); return out
    except Exception as e:
        core.log(f"IMAP: {e}", "warn"); return []

def find_confirm_link(domain_hint="", tries=6, wait=15):
    """يبحث عن رابط تأكيد من موقع معيّن"""
    for attempt in range(tries):
        for msg in fetch():
            subj = _dec(msg.get("Subject",""))
            frm = _dec(msg.get("From",""))
            blob = subj + " " + frm
            if domain_hint and domain_hint.lower() not in blob.lower():
                continue
            if not OK_RX.search(blob): continue
            for link in LINK_RX.findall(_body(msg)):
                l = link.rstrip(".,;)")
                if OK_RX.search(l) or "verif" in l.lower() or "confirm" in l.lower():
                    return l, subj
        if attempt < tries - 1:
            core.log(f"انتظار بريد التحقق... ({attempt+1}/{tries})", "info"); time.sleep(wait)
    return "", ""

def confirm(domain_hint=""):
    link, subj = find_confirm_link(domain_hint)
    if not link:
        core.log("لم يُعثر على رابط تحقق", "warn"); return False
    core.log(f"بريد: {subj}", "ok")
    r = core.http(link, timeout=25)
    core.log(f"تفعيل {'نجح' if r.get('ok') else 'فشل'} ({r.get('code')})", "ok" if r.get("ok") else "warn")
    return True
