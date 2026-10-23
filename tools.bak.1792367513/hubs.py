#!/usr/bin/env python3
import html, json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
S = rd("data/revenue.json", {}).get("pages_url") or ""
items = []
for f in ("catalog.json", "films.json", "titles.json"):
    d = rd(f, None)
    if not d: continue
    a = d.get("items") if isinstance(d, dict) else d
    if isinstance(a, dict): a = list(a.values())
    if isinstance(a, list):
        for x in a:
            if isinstance(x, dict) and (x.get("t") or x.get("title")):
                items.append({"i": x.get("i") or x.get("id") or "", "t": x.get("t") or x.get("title"),
                              "th": x.get("th") or x.get("poster") or "", "y": str(x.get("y") or "")[:4],
                              "c": x.get("c") or x.get("cat") or ""})
    if items: break
def page(title, desc, arr, fn, extra=""):
    cards = "".join('<a class="c" href="f/%s.html"><img loading="lazy" src="%s"><b>%s</b></a>'
                    % (html.escape(str(x["i"])), html.escape(x["th"] or ""), html.escape(str(x["t"]))) for x in arr[:120])
    open(fn, "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title>
<meta name="description" content="%s">
<link rel="manifest" href="manifest.json"><link rel="alternate" type="application/rss+xml" title="CineHub" href="feed.xml">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}.w{max-width:1100px;margin:0 auto;padding:16px}
h1{font-size:21px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(118px,1fr));gap:10px;padding:10px 0}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;overflow:hidden;text-decoration:none;color:#e9eef6}
.c img{width:100%%;aspect-ratio:2/3;object-fit:cover;background:#0f1520;display:block}
.c b{display:block;font-size:12.5px;padding:6px;height:50px;overflow:hidden;font-weight:500}
a{color:#5ca9ff}nav a{margin-inline-end:10px;text-decoration:none;color:#8fa4bf;font-size:12.5px}</style></head><body>
<div class="w"><nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="movies.html">أفلام</a><a href="series.html">مسلسلات</a><a href="adult.html">للكبار</a><a href="install.html">تثبيت</a></nav>
<h1>%s</h1><p style="color:#8b96a8;font-size:13px">%s</p>%s<div class="grid">%s</div>
<p><a href="feed.xml">📡 اشترك في RSS</a></p></div></body></html>"""
    % (title, desc, title, desc, extra, cards))
adult = [x for x in items if any(k in (x["c"] or "").lower() for k in ("adult","18","xxx","erotic"))] or items[:60]
page("أفلام مجانية", "أحدث الأفلام — مشاهدة مباشرة بلا تسجيل", items, "movies.html")
page("مسلسلات", "مسلسلات وحلقات — تحديث مستمر", items[20:] or items, "series.html")
page("للكبار", "قسم الأفلام للكبار", adult, "adult.html")
# feed
now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
open("feed.xml", "w", encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
 '<title>CineHub 3099</title><link>%s</link><description>أفلام مجانية</description><language>ar</language>'
 '<lastBuildDate>%s</lastBuildDate>%s</channel></rss>'
 % (S, now, "".join('<item><title>%s</title><link>%s/f/%s.html</link></item>' % (html.escape(str(x["t"])), S, html.escape(str(x["i"]))) for x in items[:50])))
print("  ✓ movies/series/adult + feed.xml")
