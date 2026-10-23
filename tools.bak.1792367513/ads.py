#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""كتلة إعلانات مضمّنة بعلامات: تُستبدل في مكانها فلا تتكرر ولا تُحمّل مرتين."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

# id, name, kind, zone_key, embed_key, url_template, tier, section
NETS = [
 ("exoclick","ExoClick","banner","EXOCLICK_ZONE","EXOCLICK_EMBED",
  "https://s.exoclick.com/ads.php?type={size}&zone={id}",1,"adult"),
 ("juicyads","JuicyAds","banner","JUICYADS_ZONE","JUICYADS_EMBED",
  "https://adserver.juicyads.com/adshow.php?adzone={id}",1,"adult"),
 ("aads","A-ADS","banner","AADS_UNIT","AADS_EMBED",
  "https://ad.a-ads.com/{id}?size={size}",1,"both"),
 ("adsterra","Adsterra","banner","ADSTERRA_ZONE","ADSTERRA_EMBED",None,2,"both"),
 ("hilltopads","HilltopAds","banner","HILLTOPADS_ZONE","HILLTOPADS_EMBED",None,2,"both"),
 ("trafficstars","TrafficStars","banner","TRAFFICSTARS_ZONE","TRAFFICSTARS_EMBED",None,2,"adult"),
 ("clickadu","Clickadu","banner","CLICKADU_ZONE","CLICKADU_EMBED",None,2,"both"),
 ("popads","PopAds","popunder","POPADS_SITE","POPADS_EMBED",None,3,"both"),
 ("popcash","PopCash","popunder","POPCASH_SITE","POPCASH_EMBED",None,3,"both"),
 ("evadav","EvaDav","push","EVADAV_ZONE","EVADAV_EMBED",None,3,"both"),
]
_TPL = {n[0]: n[5] for n in NETS}

def status():
    out = []
    for nid, name, kind, zk, ek, tpl, tier, sect in NETS:
        z, e = core.get(zk), core.get(ek)
        out.append({"id": nid, "n": name, "kind": kind, "zone_key": zk, "zone": z,
                    "embed_key": ek, "has_embed": bool(e), "tier": tier, "section": sect,
                    "on": bool(z or e)})
    return out

def _one(n):
    e = core.get(n["embed_key"])
    if e: return e
    z = core.get(n["zone"])
    if not z: return ""
    tpl = _TPL.get(n["id"])
    if not tpl: return ""
    z = core.esc(z)
    url = tpl.replace("{id}", z).replace("{size}", "300x250")
    # A-ADS: الوسم data-aa يجعل الصيغة الكلاسيكية تعمل أيضًا
    extra = " data-aa='%s'" % z if n["id"] == "aads" else ""
    return ('<iframe src="%s"%s width="300" height="250" frameborder="0" scrolling="no"'
            ' loading="lazy" style="border:0;max-width:100%%"></iframe>' % (url, extra))

def block(section="adult", limit=2):
    nets = sorted([n for n in status() if n["section"] in (section, "both") and n["on"]],
                  key=lambda n: n["tier"])
    codes = [c for c in (_one(n) for n in nets[:limit]) if c]
    extra = [c for c in (_one(n) for n in nets[limit:] if n["kind"] != "banner") if c]
    inner = "".join('<div class="ads">%s</div>' % c for c in codes)
    if not inner:
        inner = ('<div class="ads"><span class="adsnote">لا شبكة مفعّلة بعد — '
                 'افتح networks.html وسجّل، ثم ألصق المفتاح في keys.env</span></div>')
    if extra: inner += "".join(extra)
    return "<!--ADS:%s:start-->" % section + inner + "<!--ADS:%s:end-->" % section

def inject(page_html, section="adult"):
    blk = block(section)
    pat = re.compile(r"<!--ADS:%s:start-->.*?<!--ADS:%s:end-->" % (section, section), re.S)
    if pat.search(page_html):
        return pat.sub(lambda m: blk, page_html, count=1)
    if "</body>" in page_html:
        return page_html.replace("</body>", blk + "\n</body>", 1)
    return page_html + blk

def counts():
    s = status()
    return len(s), len([x for x in s if x["on"]])

def main():
    with core.lock("ads", 600) as got:
        if not got: print("  · مقفول"); return
        st = status()
        core.save("ads-all.json", {"updated": core.time.strftime("%F %H:%M"),
                                   "count": len(st), "enabled": len([x for x in st if x["on"]]),
                                   "note": "المفتاح يُنشأ من لوحة المزود. لا مفتاح يعمل بلا حساب.",
                                   "networks": st})
        core.save("ads-adult.json", {"updated": core.time.strftime("%F %H:%M"),
                                     "count": len(st), "enabled": len([x for x in st if x["on"]]),
                                     "networks": st})
        fixed = 0
        for d in ("adult", "."):
            if not os.path.isdir(d): continue
            for f in os.listdir(d):
                if not f.endswith(".html"): continue
                p = os.path.join(d, f)
                s = open(p, encoding="utf-8").read()
                if "<!--ADS:adult:start-->" in s: continue
                if "ads-adult.json" not in s and 'class="ads"' not in s: continue
                core.write_if_changed(p, inject(s, "adult")); fixed += 1
        n, on = counts()
        print("  ✓ ads-all.json + ads-adult.json: %d شبكة · %d مفعّلة · أُصلحت %d صفحة قديمة" % (n, on, fixed))

if __name__ == "__main__": main()
