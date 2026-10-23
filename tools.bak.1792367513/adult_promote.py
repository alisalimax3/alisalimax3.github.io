#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ترويج بنصوص جاهزة + QR + وسم الحملة — تعمل بلا أي مفتاح."""
import os, sys, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ROW = """<div class="c"><img src="%(qr)s" alt="QR"><div style="flex:1">
<b>%(t)s</b><textarea readonly onclick="this.select()">%(txt)s</textarea>
<a target="_blank" rel="noopener" href="https://www.reddit.com/submit?url=%(eu)s&title=%(et)s">Reddit ↗</a>
<a target="_blank" rel="noopener" href="https://twitter.com/intent/tweet?text=%(etxt)s">X ↗</a>
<a target="_blank" rel="noopener" href="https://t.me/share/url?url=%(eu)s&text=%(et)s">تليجرام ↗</a>
<a target="_blank" rel="noopener" href="%(u)s">فتح ↗</a></div></div>"""

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ترويج الكبار — CineHub 3099</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:900px;margin:0 auto;padding:16px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px}
.c img{width:110px;height:110px;border-radius:8px;background:#fff;padding:4px}
textarea{width:100%%;height:52px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px;margin-inline-end:8px}b{font-size:13.5px}.k{color:#8b96a8;font-size:13px}</style>
</head><body><div class="w"><h1>🔞 ترويج الكبار — %(n)d نص جاهز</h1>
<p class="k">كل رابط يحمل <code>?ref=%(ref)s&utm_source=…&utm_campaign=…</code> لتتبع المصدر.
انشر في r/nsfw · r/porn · r/hentai · تليجرام · X.</p>%(rows)s</div></body></html>"""

def main():
    with core.lock("adult_promote", 900) as got:
        if not got: print("  · مقفول"); return
        rows, _ = core.catalog()
        if not rows: print("  ✗ لا كتالوج"); return
        ad = [r for r in rows if core.is_adult(r)] or rows
        S, ref = core.site(), (core.get("REF_CODE") or core.get("GH_USER") or "ch")
        out = []
        for r in ad[:60]:
            base = "%s/adult/%s.html" % (S, r["i"])
            links = {k: base + "?ref=%s&utm_source=%s&utm_campaign=%s" % (
                urllib.parse.quote(ref), k, k) for k in ("reddit","x","telegram")}
            u = links["reddit"]
            txt = "🔞 %s\n%s" % (r["t"], u)
            out.append(ROW % {
              "qr": "https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=" + urllib.parse.quote(u, safe=""),
              "t": core.esc(r["t"]), "txt": core.esc(txt), "u": core.esc(u),
              "eu": urllib.parse.quote(u, safe=""), "et": urllib.parse.quote(r["t"], safe=""),
              "etxt": urllib.parse.quote(txt, safe="")})
        core.write_if_changed("promote-adult.html", TPL % {"n": len(out), "rows": "".join(out), "ref": core.esc(ref)})
        print("  ✓ promote-adult.html (%d نص · بحملات موسومة)" % len(out))

if __name__ == "__main__": main()
