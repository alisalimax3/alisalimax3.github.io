#!/usr/bin/env python3
import html, json, os, time, urllib.parse
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
S = json.load(open("data/revenue.json", encoding="utf-8")).get("pages_url", "") if os.path.exists("data/revenue.json") else ""
items = []
d = None
for f in ("catalog.json", "films.json"):
    try: d = json.load(open(f, encoding="utf-8"))
    except Exception: continue
    if d: break
a = (d.get("items") if isinstance(d, dict) else d) or []
for x in (a if isinstance(a, list) else [])[:60]:
    if isinstance(x, dict) and x.get("t"): items.append({"t": x["t"], "i": x.get("i", "")})
rows = ""
for x in items:
    u = "%s/f/%s.html" % (S, x["i"]); t = x["t"]
    qr = "https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=" + urllib.parse.quote(u)
    txt = "%s — شاهد مجانًا\n%s" % (t, u)
    rows += ('<div class="c"><img src="%s"><div style="flex:1"><b>%s</b><textarea readonly>%s</textarea>'
             '<a target="_blank" href="https://wa.me/?text=%s">واتساب</a> '
             '<a target="_blank" href="https://t.me/share/url?url=%s&text=%s">تليجرام</a> '
             '<a target="_blank" href="https://twitter.com/intent/tweet?text=%s">X</a></div></div>'
             % (qr, html.escape(t), html.escape(txt), urllib.parse.quote(txt), urllib.parse.quote(u),
                urllib.parse.quote(t), urllib.parse.quote(txt)))
open("promote.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>ترويج</title>
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}.w{max-width:900px;margin:0 auto;padding:16px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px}
.c img{width:110px;height:110px;border-radius:8px;background:#fff;padding:4px}.c b{font-size:13.5px}
textarea{width:100%%;height:46px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px;margin-inline-end:8px}</style>
<div class="w"><h1>📣 ترويج — QR + نص جاهز لكل فيلم</h1>
<p style="color:#8b96a8;font-size:13px">انسخ النص أو اعرض QR. كل فتح = زيارة = إعلان.</p>%s</div></html>""" % rows)
print("  ✓ promote.html (%d)" % len(items))
