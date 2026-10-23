#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""نمو: sitemap · robots · RSS · صفحات هبوط · روابط مشاركة بحملة · go/ للنقرات."""
import json, os, sys, time, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

# VN_CORE_SHIM — يوفّر core.get لو core.py مش بيوفّره
try:
    import core as _vncore
    if not hasattr(_vncore, "get"):
        def _vn_get(k, d=None):
            for _n in ("CFG","CONFIG","CONF","SETTINGS","ENV","DEFAULTS","PARAMS","cfg","conf","config","settings"):
                _o = getattr(_vncore, _n, None)
                if isinstance(_o, dict) and k in _o: return _o[k]
            return getattr(_vncore, k, d)
        _vncore.get = _vn_get
except Exception:
    pass


def sitemap(S, urls):
    body = "".join(
      "<url><loc>%s</loc><lastmod>%s</lastmod><changefreq>%s</changefreq><priority>%s</priority></url>"
      % (core.esc(u), time.strftime("%F"), cf, pr) for u, cf, pr in urls)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">%s</urlset>' % body)

def go_pages(r):
    TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>تحويل… %(name)s</title><meta name="robots" content="noindex">
<style>body{background:#0b0d12;color:#e9eef6;font:16px system-ui,Tahoma;display:flex;align-items:center;
justify-content:center;height:100vh;margin:0;text-align:center}a{color:#5ca9ff}.k{font-size:13px;color:#8b96a8}</style>
</head><body><div><p>جارٍ التحويل إلى <b>%(name)s</b>…</p>
<p class="k">نقرات هذه الوجهة: <b data-hits="go">…</b> · إفصاح: رابط تسويق بالعمولة</p>
<p><a href="%(url)s">اضغط لو لم يتحوّل</a></p></div>
<script>(function(){var U=%(uj)s,NS=%(nj)s,ref="";try{ref=localStorage.getItem("ch_ref")||"";}catch(e){}
function go(){location.replace(U+(ref?((U.indexOf("?")>-1?"&":"?")+"subid="+encodeURIComponent(ref)):""));}
var t=setTimeout(go,1200);
fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/go-%(id)s"+(ref?"-"+ref.replace(/[^A-Za-z0-9._-]/g,"-"):""))
 .then(function(r){return r.json();}).then(function(j){var e=document.querySelector("[data-hits]");
 if(e&&j&&j.value!==undefined)e.textContent=j.value;clearTimeout(t);go();}).catch(function(){clearTimeout(t);go();});})();</script>
</body></html>"""
    os.makedirs("go", exist_ok=True)
    n = 0
    for p in r["providers"]:
        url = core.get(p["credential_env"])
        if not url or not p["credential_env"].endswith("_REF"): continue
        core.write_if_changed("go/%s.html" % p["id"], TPL % {
          "name": core.esc(p["name"]), "url": core.esc(url), "uj": json.dumps(url),
          "nj": json.dumps(core.ns()), "id": p["id"]}); n += 1
    return n

LAND = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%(title)s — CineHub 3099</title><meta name="description" content="%(desc)s">
<link rel="canonical" href="%(site)s/%(slug)s.html"><link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.9 system-ui,Tahoma}
.w{max-width:720px;margin:0 auto;padding:20px}h1{font-size:24px}h2{font-size:17px;color:#9fb0c6}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:15px;margin:12px 0}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}ul{padding-inline-start:20px}
table{width:100%%;border-collapse:collapse;font-size:13.5px}td{padding:6px;border-bottom:1px solid #1e2635}
.disc{background:#1b1508;border-color:#3a2c08;color:#e8c76a;font-size:13px}</style>
</head><body><div class="w"><h1>%(title)s</h1><p class="k">%(desc)s</p>
<div class="card">%(body)s</div>
<div class="card disc"><b>إفصاح:</b> بعض الروابط في هذه الصفحة روابط تسويق بالعمولة —
قد نحصل على عمولة عند التسجيل، دون أي زيادة في سعرك.</div>
<p><a href="./">الرئيسية</a> · <a href="adult.html">للكبار</a> · <a href="rewards.html">مكافأة يومية</a> · <a href="owner.html">لوحة المالك</a></p>
</div><script src="hits.js" defer></script></body></html>"""

def share_page(S, ref, items):
    rows = ""
    for it in items[:80]:
        u = "%s/adult/%s.html?ref=%s&utm_source=copy&utm_campaign=share" % (S, it["i"], urllib.parse.quote(ref))
        txt = "🔞 %s\n%s" % (it["t"], u)
        rows += ("<div class='c'><b>%s</b><textarea readonly onclick='this.select()'>%s</textarea>"
                 "<a target='_blank' rel='noopener' href='%s'>فتح</a></div>"
                 % (core.esc(it["t"]), core.esc(txt), core.esc(u)))
    return """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>روابط المشاركة</title>
<meta name="robots" content="noindex"><style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:820px;margin:0 auto;padding:16px}.c{background:#131a25;border:1px solid #1e2635;border-radius:10px;padding:9px;margin:8px 0}
textarea{width:100%%;height:44px;background:#0b0f17;border:1px solid #1c2536;border-radius:8px;color:#cfe0f5;font-size:12px;padding:6px;margin:5px 0}
a{color:#8ec5ff;font-size:12.5px}.k{color:#8b96a8;font-size:13px}</style></head><body><div class="w">
<h1>🔗 روابط مشاركة قابلة للنسخ</h1><p class="k">كل رابط موسوم بالحملة — يظهر المصدر في العدّاد.</p>
%s</div></body></html>""" % rows

def main():
    with core.lock("growth", 1800) as got:
        if not got: print("  · مقفول"); return
        r = RE.apply_ledger(); S = core.site()
        rows, _ = core.catalog()
        ad = [x for x in rows if core.is_adult(x)] or rows
        ref = core.get("REF_CODE") or core.get("GH_USER") or "ch"
        urls = [(S + "/", "daily", "1.0"), (S + "/adult.html", "daily", "0.9"),
                (S + "/rewards.html", "daily", "0.7"), (S + "/earn.html", "weekly", "0.7")]
        urls += [(S + "/adult/%s.html" % x["i"], "weekly", "0.6") for x in ad[:1500]]
        core.write_if_changed("sitemap.xml", sitemap(S, urls))
        core.write_if_changed("robots.txt",
          "User-agent: *\nAllow: /\nDisallow: /owner.html\nDisallow: /networks.html\n"
          "Disallow: /promote-adult.html\nDisallow: /go/\nSitemap: %s/sitemap.xml\n" % S)
        now = time.strftime("%a, %d %b %Y %H:%M:%S +0000")
        core.write_if_changed("rss.xml",
          '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel>'
          '<title>CineHub 3099</title><link>%s</link><lastBuildDate>%s</lastBuildDate>%s</channel></rss>'
          % (S, now, "".join('<item><title>%s</title><link>%s/adult/%s.html</link></item>'
                             % (core.esc(x["t"]), S, x["i"]) for x in ad[:60])))
        core.write_if_changed("share.html", share_page(S, ref, ad))
        # صفحات هبوط
        aff = [p for p in r["providers"] if p["type"].startswith(("affiliate","cpa"))]
        body = "<h2>لماذا التسجيل؟</h2><p>تسجيل مجاني تمامًا، وبلا التزام. البث والمحتوى مفتوحان للمشاهدة.</p>"
        body += "<h2>المزودون المتاحون</h2><table>"
        for p in aff:
            body += ("<tr><td><b>%s</b></td><td>%s</td><td><a rel='nofollow noopener' target='_blank' href='go/%s.html'>اذهب ↗</a></td></tr>"
                     % (core.esc(p["name"]), core.esc(p["note"]), p["id"]))
        body += "</table><p class='k'>حالة المزود: %s</p>" % (
            "مربوط" if any(x["credential_status"] == "present" for x in aff) else "بانتظار المفاتيح")
        core.write_if_changed("go-cams.html", LAND % {
          "title": "بث مباشر — مواقع موصى بها", "desc": "قائمة مواقع البث المباشر مع حالة الربط",
          "slug": "go-cams", "site": S, "body": body})
        go = go_pages(r)
        print("  ✓ sitemap(%d) · robots · rss · share.html · go-cams.html · go/(%d)" % (len(urls), go))

if __name__ == "__main__": main()
