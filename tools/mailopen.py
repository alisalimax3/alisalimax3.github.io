#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبحث عن رسالة من نطاق معيّن ويفتح رابط التأكيد."""
import imaplib, email, re, sys, os, time
from datetime import datetime, timedelta
dom = (sys.argv[1] if len(sys.argv) > 1 else "").lower()
wait = int(sys.argv[2]) if len(sys.argv) > 2 else 240
u = os.environ.get("MU") or ""; p = os.environ.get("MP") or ""
if not (u and p): sys.exit(3)
end = time.time() + wait
while time.time() < end:
    try:
        M = imaplib.IMAP4_SSL("imap.gmail.com"); M.login(u, p); M.select("INBOX")
        since = (datetime.utcnow() - timedelta(minutes=40)).strftime("%d-%b-%Y")
        typ, data = M.search(None, "(SINCE %s)" % since)
        for i in reversed(data[0].split()[-15:]):
            typ, d = M.fetch(i, "(RFC822)")
            msg = email.message_from_bytes(d[0][1])
            frm = msg.get("From", ""); subj = msg.get("Subject", "")
            if dom and dom not in (frm + subj).lower(): continue
            txt = ""
            if msg.is_multipart():
                for part in msg.walk():
                    if part.get_content_type() in ("text/html", "text/plain"):
                        try: txt += part.get_payload(decode=True).decode(part.get_content_charset() or "utf-8", "ignore")
                        except Exception: pass
            else:
                try: txt = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8", "ignore")
                except Exception: pass
            L = re.findall(r'https?://[^\s"\'<>)\]]+', txt)
            good = [x for x in L if re.search(r'confirm|verif|activat|validat|token|approv|welcome|signup', x, re.I)] or L
            if good:
                M.logout(); print(good[0].rstrip('.,;')); sys.exit(0)
        M.logout()
    except Exception: pass
    time.sleep(8)
sys.exit(1)
