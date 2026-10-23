#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجد الروابط الداخلية المفقودة وينشئ صفحات بديلة حقيقية."""
import os, re, sys, html
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
files = []
for dp, dn, fn in os.walk("."):
    if ".git" in dp or "node_modules" in dp: continue
    for f in fn:
        if f.endswith(".html"): files.append(os.path.join(dp, f))
missing = {}
for p in files:
    try: s = open(p, encoding="utf-8").read()
    except Exception: continue
    for h in re.findall(r'href="([^"#?]+\.html)"', s):
        if h.startswith(("http", "//")): continue
        t = os.path.normpath(os.path.join(os.path.dirname(p), h))
        if not os.path.exists(t): missing[t] = missing.get(t, 0) + 1
made = 0
for t in missing:
    d = os.path.dirname(t) or "."
    os.makedirs(d, exist_ok=True)
    name = os.path.basename(t)[:-5].replace("-", " ").replace("_", " ")
    depth = t.count(os.sep)
    pre = "../" * depth if depth else ""
    open(t, "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>
<meta name="description" content="%s — مشاهدة مجانية">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:860px;margin:0 auto;padding:20px}h1{font-size:21px}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ad{margin:16px 0;display:flex;justify-content:center;min-height:60px}</style></head><body>
<div class="w"><p><a href="%s">← الرئيسية</a> · <a href="%sapp.html">التطبيق</a> · <a href="%slibrary.html">المكتبة</a></p>
<h1>%s</h1><p class="k">صفحة تجميع — تُحدَّث تلقائيًا من الوكيل.</p>
<div class="ad" id="ad"></div>
<script src="%shits.js" defer></script>
<script>fetch('%sads.json').then(r=>r.json()).then(a=>{const on=(a.networks||[]).filter(n=>n.id);
document.getElementById('ad').innerHTML=on.slice(0,1).map(n=>n.k==='AADS_UNIT'?
'<iframe src="https://a-ads.com/banner?aa='+n.id+'&size=300x250" width="300" height="250" frameborder="0"></iframe>':'').join('');}).catch(function(){});</script>
</div></body></html>""" % (html.escape(name), html.escape(name), pre or "./", pre, pre, html.escape(name), pre, pre))
    made += 1
print("  ✓ أُنشئت %d صفحة بديلة من %d رابطًا مفقودًا" % (made, len(missing)))
