#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني قسم الكبار من الكتالوج الموحّد — يُحدّث الصفحات القديمة عند تغيّر البيانات."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ads

TPL = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%(t)s — CineHub 3099</title>
<meta name="description" content="%(t)s — مشاهدة مجانية بجودة عالية">
<meta property="og:title" content="%(t)s"><meta property="og:image" content="%(th)s">
<meta property="og:type" content="video.movie"><meta name="twitter:card" content="summary_large_image">
<meta name="rating" content="adult"><link rel="canonical" href="%(site)s/adult/%(slug)s.html">
<link rel="manifest" href="../manifest.json">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:860px;margin:0 auto;padding:18px}h1{font-size:21px;margin:.4em 0}
img{max-width:260px;border-radius:12px;background:#0f1520}.k{color:#8b96a8;font-size:13px}
a{color:#5ca9ff}.ads{display:flex;justify-content:center;margin:14px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}
</style></head><body><div class="w">
<p class="k"><a href="../">الرئيسية</a> · <a href="../adult.html">🔞 للكبار</a> · <a href="../app.html">التطبيق</a></p>
<img loading="lazy" src="%(th)s" alt="%(t)s" onerror="this.style.display='none'">
<h1>%(t)s <span class="k">%(y)s</span></h1>
<p class="k">قسم الكبار 18+ — إعلانات مطابقة للجمهور.</p>
%(ads)s
<p><a href="../adult.html">→ كل قسم الكبار</a> · <a href="../rewards.html">🎁 مكافأة يومية</a></p>
</div><script src="../hits.js" defer></script></body></html>"""

CARD = ('<a class="c" href="adult/%(slug)s.html"><img loading="lazy" src="%(th)s" alt="%(t)s"'
        ' onerror="this.style.display=\'none\'"><b>%(t)s</b></a>')

IDX = """<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>🔞 للكبار — CineHub 3099</title>
<meta name="description" content="قسم الكبار 18+ — %(n)d عنوانًا مشاهدة مجانية">
<meta name="rating" content="adult"><link rel="manifest" href="manifest.json">
<link rel="canonical" href="%(site)s/adult.html">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1100px;margin:0 auto;padding:16px}h1{font-size:21px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:10px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
a{color:#5ca9ff}nav a{margin-inline-end:10px;text-decoration:none;color:#8fa4bf;font-size:12.5px}
.ads{display:flex;justify-content:center;margin:12px 0;min-height:60px;align-items:center}
.adsnote{color:#6b7787;font-size:12px}.k{color:#8b96a8;font-size:13px}
</style></head><body><div class="w">
<nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="movies.html">أفلام</a><a href="series.html">مسلسلات</a><a href="adult.html">🔞 للكبار</a><a href="rewards.html">🎁</a></nav>
<h1>🔞 قسم الكبار</h1>
<p class="k">%(n)d عنوانًا · إعلانات شبكات إباحية فقط (بلا خلط مع العام)</p>
%(ads)s<div class="grid">%(cards)s</div>
</div><script src="hits.js" defer></script></body></html>"""

def main():
    with core.lock("adult_build", 1800) as got:
        if not got: print("  · مقفول"); return
        rows, src = core.catalog()
        if not rows: print("  ✗ لا كتالوج — أرسل مخرجات AUDIT قسم 5"); return
        ad = [r for r in rows if core.is_adult(r)] or rows
        S, blk = core.site(), ads.block("adult", 2)
        new = upd = 0
        os.makedirs("adult", exist_ok=True)
        for r in ad:
            p = "adult/%s.html" % r["i"]
            h = TPL % {"t": core.esc(r["t"]), "th": core.esc(r["th"]), "y": core.esc(r["y"]),
                       "slug": r["i"], "site": S, "ads": blk}
            new += 1 if core.write_if_changed(p, h) else 0
            upd += 0 if core.write_if_changed(p, h) else 1
        cards = "".join(CARD % {"slug": r["i"], "th": core.esc(r["th"]), "t": core.esc(r["t"])} for r in ad[:200])
        core.write_if_changed("adult.html", IDX % {"n": len(ad), "cards": cards, "ads": blk, "site": S})
        now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
        core.write_if_changed("adult-rss.xml",
          '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
          '<title>CineHub 3099 — للكبار</title><link>%s/adult.html</link>'
          '<description>قسم 18+</description><lastBuildDate>%s</lastBuildDate>%s</channel></rss>'
          % (S, now, "".join('<item><title>%s</title><link>%s/adult/%s.html</link></item>'
                             % (core.esc(r["t"]), S, r["i"]) for r in ad[:60])))
        core.save("data/adult_meta.json", {"updated": time.strftime("%F %H:%M"), "source": src,
                  "catalog_total": len(rows), "adult_total": len(ad), "pages": len(ad)})
        print("  ✓ %d صفحة · جديد %d · مصدر=%s" % (len(ad), new, src))

if __name__ == "__main__": main()
