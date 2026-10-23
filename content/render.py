#!/usr/bin/env python3
import json, os, re, html, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
B = "https://alisalimax3.github.io"
if not os.path.exists('data/index.json'): raise SystemExit('شغّل build.py أولاً')
D = json.load(open('data/index.json', encoding='utf-8'))
def esc(s): return html.escape(str(s or ''), quote=True)
def slug(s):
    s = re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]', ' ', s or '')
    return (re.sub(r'\s+', '-', s.strip().lower())[:60] or 'item').strip('-')

HEAD = '''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{t} · CineHub 3099</title>
<meta name="description" content="{d}">
<meta property="og:title" content="{t}"><meta property="og:description" content="{d}">
<meta property="og:type" content="video.other"><meta property="og:image" content="{img}">
<meta name="twitter:card" content="summary_large_image">
<style>
:root{{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--t);font:15px/1.8 system-ui,Tahoma;padding:14px 14px 90px}}
.wrap{{max-width:1100px;margin:auto}}h1{{font-size:20px}}
.grid{{display:grid;gap:12px;grid-template-columns:repeat(auto-fill,minmax(150px,1fr))}}
.c{{background:var(--p);border:1px solid var(--b);border-radius:12px;overflow:hidden;text-decoration:none;color:var(--t);display:block}}
.c img{{width:100%;height:200px;object-fit:cover;background:#0d1424;display:block}}
.c b{{display:block;padding:8px;font-size:13px;line-height:1.5}}
.c span{{color:var(--m);font-size:11px;padding:0 8px 8px;display:block}}
input,button{{background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:10px}}
button{{background:var(--a);color:#04121a;font-weight:800;cursor:pointer}}
.ply{{position:fixed;inset:0;background:#000c;display:none;z-index:9999;align-items:center;justify-content:center;padding:10px}}
.ply.on{{display:flex}}.ply iframe{{width:min(1000px,96vw);height:min(60vw,600px);border:0;border-radius:10px;background:#000}}
.ply .x{{position:absolute;top:14px;left:14px;font-size:26px;color:#fff;cursor:pointer;background:none;border:0}}
.sh{{display:flex;gap:6px;flex-wrap:wrap;margin:10px 0}}
.sh a{{background:#1b2740;border:1px solid var(--b);color:var(--t);padding:6px 11px;border-radius:8px;text-decoration:none;font-size:12px}}
</style></head><body><div class="wrap">'''
FOOT = '<div class="ply" id="ply"><button class="x" onclick="closeP()">✕</button><div id="pbody"></div></div></div></body></html>'

def card(x, link=None):
    u = link or x.get('embed') or '#'
    return ('<a class="c" href="%s" onclick="return play(event,\'%s\',\'%s\')"><img loading="lazy" src="%s" alt="%s" onerror="this.style.opacity=.2">'
            '<b>%s</b><span>%s</span></a>') % (esc(u), esc(x.get('embed') or u), esc(x.get('title')), esc(x.get('thumb')), esc(x.get('title')), esc(x.get('title')), esc(x.get('year') or x.get('channel') or ''))

def page(fn, title, items, sub=''):
    s = HEAD.format(t=esc(title), d=esc(sub or title), img=(items[0].get('thumb') if items else ''))
    s += '<h1>%s</h1><p style="color:var(--m)">%s</p>' % (esc(title), esc(sub))
    s += '<input id="q" placeholder="ابحث..." style="width:100%%;margin:8px 0" oninput="flt()">'
    s += '<div class="grid" id="g">' + ''.join(card(x) for x in items) + '</div>'
    s += '''<script>function play(e,u,t){e.preventDefault();document.getElementById('pbody').innerHTML='<iframe src="'+u+'" allowfullscreen allow="autoplay;encrypted-media"></iframe>';document.getElementById('ply').classList.add('on');return false}
function closeP(){document.getElementById('ply').classList.remove('on');document.getElementById('pbody').innerHTML=''}
function flt(){var q=document.getElementById('q').value.toLowerCase();document.querySelectorAll('#g .c').forEach(function(c){c.style.display=c.textContent.toLowerCase().indexOf(q)>-1?'':'none'})}
document.addEventListener('keydown',function(e){if(e.key==='Escape')closeP()});</script>'''
    s += FOOT
    open(fn, 'w', encoding='utf-8').write(s)
    return fn

def item_page(x, kind):
    fn = ('%s/%s.html' % (kind, slug(x.get('title'))))
    t = x.get('title'); img = x.get('thumb') or ''
    ld = {"@context": "https://schema.org", "@type": "VideoObject", "name": t,
          "description": x.get('desc') or t, "thumbnailUrl": img,
          "uploadDate": (x.get('year') or '2026') + '-01-01' if x.get('year') else '2026-01-01',
          "embedUrl": x.get('embed') or '', "url": B + '/' + fn}
    s = HEAD.format(t=esc(t), d=esc(x.get('desc') or t), img=esc(img))
    s += '<script type="application/ld+json">%s</script>' % json.dumps(ld, ensure_ascii=False)
    s += '<h1>%s</h1>' % esc(t)
    if x.get('embed'): s += '<iframe src="%s" style="width:100%%;height:min(60vw,600px);border:0;border-radius:12px" allowfullscreen></iframe>' % esc(x['embed'])
    s += '<p style="color:var(--m)">%s</p>' % esc(x.get('desc') or '')
    u = B + '/' + fn
    s += ('<div class="sh"><a target="_blank" href="https://wa.me/?text=%s">واتساب</a>'
          '<a target="_blank" href="https://t.me/share/url?url=%s&text=%s">تليجرام</a>'
          '<a target="_blank" href="https://www.facebook.com/sharer/sharer.php?u=%s">فيسبوك</a>'
          '<a target="_blank" href="https://twitter.com/intent/tweet?url=%s">X</a></div>') % tuple(
        [urllib_quote(x)] * 5) if False else ''
    import urllib.parse as up
    s += ('<div class="sh"><a target="_blank" href="https://wa.me/?text=%s">واتساب</a>'
          '<a target="_blank" href="https://t.me/share/url?url=%s">تليجرام</a>'
          '<a target="_blank" href="https://www.facebook.com/sharer/sharer.php?u=%s">فيسبوك</a>'
          '<a target="_blank" href="https://twitter.com/intent/tweet?url=%s">X</a></div>') % (
        up.quote(u + ' — ' + t), up.quote(u), up.quote(u), up.quote(u))
    s += '<p><a href="/movies.html" style="color:var(--a)">كل الأفلام</a></p>' + FOOT
    open(fn, 'w', encoding='utf-8').write(s)
    return fn

os.makedirs('m', exist_ok=True); os.makedirs('a', exist_ok=True)
mv = D.get('movies', []); ad = D.get('adult', []); ch = D.get('channels', [])
page('movies.html', 'أفلام', mv, 'أفلام حديثة وكلاسيكية بجودة عالية')
page('adult.html', 'للكبار', ad, 'محتوى مموّل — إعلانات أخف وأرباح أعلى')
page('channels.html', 'قنوات ومسلسلات', ch, 'مقاطع وقنوات مختارة')
json.dump(mv + ad + ch, open('data/all.json', 'w', encoding='utf-8'), ensure_ascii=False)

n = 0
for x in mv[:45]:
    if x.get('embed'): item_page(x, 'm'); n += 1
for x in ad[:35]:
    item_page(x, 'a'); n += 1
print('  صفحات العناصر:', n)
print('  صفحات العرض: movies.html adult.html channels.html')
