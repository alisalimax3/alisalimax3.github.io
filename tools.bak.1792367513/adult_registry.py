#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""صفحة المزودين — الحالة من المحرك المركزي، لا من ادعاءات."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

def main():
    with core.lock("registry", 1800) as got:
        if not got: print("  · مقفول"); return
        r = RE.apply_ledger()
        rows = ""
        for p in r["providers"]:
            cls = {"active":"on","pending_approval":"warn","pending_credentials":"warn",
                   "unregistered":"off","suspended":"off","rejected":"off","blocked":"off"}.get(p["account_status"],"off")
            rows += ("<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td>"
                     "<td class='%s'>%s</td><td><a target='_blank' rel='nofollow noopener' href='%s'>↗</a></td></tr>"
                     % (core.esc(p["name"]), core.esc(p["type"]), core.esc(p["credential_env"]),
                        core.esc(p["min_payout"]), core.esc(p["payment_schedule"]), cls,
                        core.esc(p["account_status"]), p["official_url"]))
        HTML = """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>مصادر الدخل — CineHub 3099</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:1000px;margin:0 auto;padding:18px}table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}code{background:#0b0f17;padding:2px 6px;border-radius:5px}
.on{color:#39d98a}.warn{color:#e8c76a}.off{color:#8b96a8}</style></head><body><div class="w">
<h1>مصادر الدخل — %d</h1>
<p class="k">الأسعار مقروءة من صفحات المزودين 2026-10-18. التسجيل ≠ القبول. «active» تعني وجود مفتاح فقط.</p>
<table><tr><th>الجهة</th><th>النوع</th><th>المفتاح</th><th>حد السحب</th><th>التكرار</th><th>الحالة</th><th></th></tr>
%s</table><p><a href="owner.html">لوحة المالك</a> · <a href="adult-networks.html">شبكات الكبار</a> · <a href="providers.html">الترتيب</a></p>
</div></body></html>""" % (len(r["providers"]), rows)
        core.write_if_changed("income.html", HTML)
        core.write_if_changed("networks.html", HTML)
        print("  ✓ income.html + networks.html (%d مزود)" % len(r["providers"]))

if __name__ == "__main__": main()
