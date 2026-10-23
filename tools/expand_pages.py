#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يوسّع الصفحات من الكتالوج (افتراضي 3000) + hubs + sitemap مقسّم."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ads

LIMIT = int(core.get("PAGE_LIMIT") or 3000)
TPL = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%(t)s — CineHub 3099</title>
<meta name="description" content="%(t)s — مشاهدة مجانية %(y)s">
<meta property="og:title" content="%(t)s"><meta property="og:image" content="%(th)s">
<meta name="twitter:card" content="summary_large_image"><link rel="canonical" href="%(site)s/%(dir)s/%(slug)s.html">
<link rel="manifest" href="../manifest.json">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:860px;margin:0 auto;padding:18px}h1{font-size:21px}
img{max-width:260px;border-radius:12px;background:#0f1520}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ads{display:flex;justify-content:center;margin:14px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}
</style></head><body><div class="w">
<p class="k"><a href="../">الرئيسية</a> · <a href="../adult.html">🔞</a> · <a href="../new.html">جديد</a> · <a href="../best.html">الأفضل</a></p>
<img loading="lazy" src="%(th)s" alt="%(t)s" onerror="this.style.display='none'">
<h1>%(t)s <span class="k">%(y)s</span></h1>
<p class="k">%(c)s</p>
%(ads)s
<p><a href="../rewards.html">🎁 مكافأة يومية</a> · <a href="../share.html">🔗 شارك</a></p>
</div><script src="../hits.js" defer></script></body></html>"""

def main():
    with core.lock("expand", 3600) as got:
        if not got: print("  · مقفول"); return
        rows, src = core.catalog()
        if not rows: print("  ✗ لا كتالوج"); return
        ad = [r for r in rows if core.is_adult(r)]
        gen = [r for r in rows if not core.is_adult(r)]
        S = core.site()
        blk_a = ads.block("adult", 2); blk_g = ads.block("both", 2)
        made = 0
        plan = [(ad, "adult", blk_a), (gen, "m", blk_g)]
        for group, d, blk in plan:
            os.makedirs(d, exist_ok=True)
            for r in group[:LIMIT]:
                p = "%s/%s.html" % (d, r["i"])
                h = TPL % {"t": core.esc(r["t"]), "th": core.esc(r["th"]), "y": core.esc(r["y"]),
                           "slug": r["i"], "site": S, "ads": blk, "dir": d, "c": core.esc(r["c"][:80])}
                if core.write_if_changed(p, h): made += 1
        # hubs
        def hub(fn, title, items, d="."):
            cards = "".join('<a class="c" href="%s/%s.html"><img loading="lazy" src="%s" alt="%s"'
                            ' onerror="this.style.display=\'none\'"><b>%s</b></a>'
                            % (d, r["i"], core.esc(r["th"]), core.esc(r["t"]), core.esc(r["t"]))
                            for r in items)
            core.write_if_changed(fn, """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s — CineHub 3099</title>
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1100px;margin:0 auto;padding:16px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;display:block}.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden}
a{color:#5ca9ff}</style></head><body><div class="w"><h1>%s</h1><div class="grid">%s</div></div>
<script src="hits.js" defer></script></body></html>""" % (title, title, cards))
        hub("new.html", "🆕 أحدث المضاف", ad[:200] + gen[:200], ".")
        hub("best.html", "⭐ الأفضل", ad[200:500] + gen[200:500], ".")
        core.write_if_changed("sitemap-adult.xml", sitemap(S, ["/adult/%s.html" % r["i"] for r in ad[:LIMIT]]))
        core.write_if_changed("sitemap.xml", sitemap(S, ["/m/%s.html" % r["i"] for r in gen[:LIMIT]]
                              + ["/new.html", "/best.html", "/rewards.html", "/rewards-earn.html", "/share.html"]))
        core.write_if_changed("sitemap-index.xml",
          '<?xml version="1.0" encoding="UTF-8"?>\n<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
          + "".join("<sitemap><loc>%s/%s</loc><lastmod>%s</lastmod></sitemap>" % (S, f, time.strftime("%F"))
                    for f in ("sitemap.xml","sitemap-adult.xml")) + "</sitemapindex>")
        core.save("data/expand.json", {"at": time.strftime("%F %H:%M"), "limit": LIMIT,
                  "adult": min(len(ad), LIMIT), "general": min(len(gen), LIMIT), "new": made})
        print("  ✓ %d صفحة جديدة · adult %d · m %d · hubs · sitemap-index"
              % (made, min(len(ad), LIMIT), min(len(gen), LIMIT)))

def sitemap(S, paths):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
            + "".join("<url><loc>%s%s</loc><lastmod>%s</lastmod></url>" % (S, p, time.strftime("%F"))
                      for p in paths) + "</urlset>")

if __name__ == "__main__": main()
