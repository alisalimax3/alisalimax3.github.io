#!/usr/bin/env python3
import hmac, hashlib, datetime, sys, os
BASE = datetime.date(2026, 1, 1)
SEC = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.license-secret'), 'rb').read().strip()
def make(plan, days):
    d = (datetime.date.today() + datetime.timedelta(days=days) - BASE).days
    p = "%s%05d" % (plan, d)
    return "%s-%s" % (p, hmac.new(SEC, p.encode(), hashlib.sha256).hexdigest()[:6].upper())
if __name__ == '__main__':
    a = sys.argv[1:]
    plan = 'M' if (a and a[0].upper().startswith('M')) else 'P'
    days = int(a[1]) if len(a) > 1 else 30
    qty  = int(a[2]) if len(a) > 2 else 1
    for _ in range(qty): print(make(plan, days))
