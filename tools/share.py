#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني data/share.json + links.html — روابط جاهزة للنشر على 7 منصات."""
import json, os, re, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
sys.path.insert(0, "tools")
try:
    import gh; U = gh.login()
except Exception: U = "alisalimax3"
S = "https://%s.github.io" % U
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
def slug(s): return re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", str(s))[:60]
items = []
for f in ("catalog.json", "films.json", "titles.json"):
    d = rd(f, None)
    if not d: continue
    a = d.get("items") if isinstance(d, dict) else d
    if isinstance(a, dict): a = list(a.values())
    if not isinstance(a, list): continue
    for x in a:
        if not isinstance(x, dict): continue
        i = str(x.get("i") or x.get("id") or x.get("slug") or "")
        t = str(x.get("t") or x.get("title") or x.get("name") or "")
        if i and t: items.append({"i": i, "t": t, "th": x.get("th") or x.get("poster") or x.get("image") or "",
                                  "y": str(x.get("y") or x.get("year") or "")[:4],
                                  "v": x.get("v") or x.get("views") or 0})
    if items: break
items.sort(key=lambda x: -(x["v"] or 0))
out = []
for x in items[:80]:
    u = "%s/f/%s.html" % (S, x["i"])
    txt = "%s %s — شاهد مجانًا\n%s" % (x["t"], ("(%s)" % x["y"]) if x["y"] else "", u)
    out.append({"t": x["t"], "u": u, "th": x["th"], "txt": txt})
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "site": S, "count": len(out), "items": out},
          open("data/share.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
open("links.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>روابط النشر — CineHub 3099</title>
<style>*{box-sizing:border-box}body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:960px;margin:0 auto;padding:16px}h1{font-size:20px}.k{color:#8b96a8;font-size:12.5px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px;align-items:center}
.c img{width:46px;height:68px;object-fit:cover;border-radius:7px;background:#0f1520;flex:none}
.c b{font-size:13.5px;display:block;margin-bottom:5px}.s{display:flex;flex-wrap:wrap;gap:5px}
.s a,.s button{font-size:11.5px;padding:4px 10px;border-radius:999px;background:#16233a;color:#a9ccff;text-decoration:none;border:1px solid #24354f;cursor:pointer}
button.cp{background:#12301f;color:#8ff0bb;border-color:#2c6a48}
.big{background:#0f1a14;border:1px solid #1e3a28;border-radius:13px;padding:13px;margin:10px 0}
textarea{width:100%;height:52px;background:#0b0f17;border:1px solid #1c2536;border-radius:9px;color:#cfe0f5;padding:8px;font-size:12px}
nav a{color:#8fa4bf;font-size:12.5px;margin-inline-end:10px;text-decoration:none}</style>
<div class="w"><nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="money.html">الأموال</a><a href="wallet.html">الخزينة</a></nav>
<h1>🔗 روابط النشر — كل من يفتح رابطًا = زيارة = ربح</h1>
<div class="big"><b>رابط موقعك (انشره في كل مكان)</b><textarea id="site" readonly></textarea>
<div class="s" style="margin-top:7px" id="ss"></div></div>
<div class="k" id="up">…</div><div id="l"></div></div>
<script>
function enc(s){return encodeURIComponent(s)}
function sh(u,t){
 const e=enc(u),x=enc(t+"\n"+u);
 return{"X":"https://twitter.com/intent/tweet?text="+x,
 "Facebook":"https://www.facebook.com/sharer/sharer.php?u="+e,
 "WhatsApp":"https://wa.me/?text="+x,
 "Telegram":"https://t.me/share/url?url="+e+"&text="+enc(t),
 "Reddit":"https://www.reddit.com/submit?url="+e+"&title="+enc(t),
 "Pinterest":"https://pinterest.com/pin/create/button/?url="+e+"&description="+enc(t),
 "Tumblr":"https://www.tumblr.com/widgets/share/tool?canonicalUrl="+e};}
fetch('data/share.json?_='+Date.now()).then(r=>r.json()).then(d=>{
 document.getElementById('up').textContent=d.count+' رابط · آخر تحديث '+d.updated;
 document.getElementById('site').value=d.site;
 const so=sh(d.site,'CineHub 3099 — أفلام مجانية');
 document.getElementById('ss').innerHTML=Object.keys(so).map(k=>'<a target="_blank" rel="nofollow noopener" href="'+so[k]+'">'+k+'</a>').join('')+
 '<button class="cp" onclick="navigator.clipboard.writeText(document.getElementById(\\'site\\').value);this.textContent=\\'✓ نُسخ\\'">نسخ الرابط</button>';
 document.getElementById('l').innerHTML=d.items.map(function(x,i){
  const m=sh(x.u,x.t);
  return '<div class="c"><img loading="lazy" src="'+x.th+'"><div style="flex:1"><b>'+x.t+'</b>'+
  '<div class="s">'+Object.keys(m).map(k=>'<a target="_blank" rel="nofollow noopener" href="'+m[k]+'">'+k+'</a>').join('')+
  '<button class="cp" onclick="navigator.clipboard.writeText(\\''+x.u+'\\');this.textContent=\\'✓\\'">نسخ</button></div></div></div>';}).join('');
});</script></html>""")
print("  ✓ links.html · %d رابط جاهز" % len(out))
