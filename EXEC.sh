#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# CineHub 3099 · EXEC.sh — محفظة + محتوى + انتشار + أتمتة
# ═══════════════════════════════════════════════════════════════
set -u
cd ~/cinehub3099 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR" content data m a
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
OWNER="alkazmybwhwr-dot"; REPO="alisalimax3.github.io"; BRANCH="main"
SITE="https://${OWNER}.github.io"
G(){ printf '\033[32m  ✓ %s\033[0m\n' "$1"; }
W(){ printf '\033[33m  ! %s\033[0m\n' "$1"; }
R(){ printf '\033[31m  ✗ %s\033[0m\n' "$1"; }
H(){ printf '\n\033[36m━━ %s ━━\033[0m\n' "$1"; }
[ -f config.env ] && { set -a; . ./config.env; set +a; }

# ═══════════ 1/8 محفظة التطبيق ═══════════
H "1/8 محفظة التطبيق"
[ -f wallet.json ] || cat > wallet.json <<'EOF'
{
  "app_wallet": {
    "evm": "0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB",
    "tron": "",
    "networks": ["Base", "BNB Chain", "Polygon", "Ethereum"]
  },
  "chain": [
    { "step": 1, "label": "الشبكات الإعلانية تدفع", "to": "محفظة التطبيق (USDT)" },
    { "step": 2, "label": "محفظة التطبيق", "to": "صرافة محلية" },
    { "step": 3, "label": "الصرافة", "to": "حسابك في بنك الكريمي" }
  ],
  "min_network_payout_usd": 5,
  "min_user_withdraw_usd": 5,
  "owner_share": 0.30,
  "user_share": 0.70
}
EOF
G "wallet.json"

cat > wallet.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>محفظة التطبيق · CineHub 3099</title>
<meta property="og:title" content="محفظة CineHub 3099"><meta property="og:type" content="website">
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:760px;margin:auto}.card{background:var(--p);border:1px solid var(--b);border-radius:14px;padding:16px;margin:12px 0}
h1{font-size:20px}.big{font-size:32px;font-weight:800;color:var(--a)}
code{background:#0d1424;padding:5px 9px;border-radius:7px;word-break:break-all;display:inline-block;margin:3px 0}
button{background:var(--a);color:#04121a;border:0;border-radius:9px;padding:10px 15px;font-weight:800;cursor:pointer;margin:4px 0}
button.alt{background:#1b2740;color:var(--t);border:1px solid var(--b)}
table{width:100%;border-collapse:collapse;font-size:13px}td,th{border-bottom:1px solid var(--b);padding:7px;text-align:right}
.l{color:var(--m);font-size:12px}.ok{color:var(--g)}.grid{display:grid;gap:10px;grid-template-columns:repeat(auto-fit,minmax(130px,1fr))}
.k{font-size:20px;font-weight:700;color:var(--a)}</style></head><body><div class="wrap">
<h1>محفظة التطبيق</h1>
<div class="card"><div class="l">رصيدك الداخلي القابل للسحب</div><div class="big" id="bal">$0.0000</div>
  <div class="grid" style="margin-top:10px">
    <div><div class="k" id="p1">$0</div><div class="l">نصيبك 70%</div></div>
    <div><div class="k" id="p2">$0</div><div class="l">مكافآت</div></div>
    <div><div class="k" id="p3">$0</div><div class="l">إحالات</div></div>
  </div></div>

<div class="card"><h3>عنوان إيداع التطبيق (USDT)</h3>
  <p class="l">لدفع الاشتراكات أو استقبال الدخل — الشبكات المدعومة:</p>
  <div id="nets"></div>
  <p>EVM (Base / BNB / Polygon / Ethereum):<br><code id="evm"></code></p>
  <p id="trc"></p>
  <button onclick="cp('evm')">نسخ العنوان</button></div>

<div class="card"><h3>سلسلة التحويل إلى بنك الكريمي</h3><table><tbody id="chain"></tbody></table>
  <p class="l">أقل مبلغ للسحب من الشبكة: $5 · تُحوّل يدوياً عبر صرافة محلية إلى الكريمي.</p></div>

<div class="card"><h3>للمالك — إجمالي المستحقات</h3>
  <p class="l">مجموع أرصدة المستخدمين المحلية على هذا الجهاز:</p>
  <div class="big" id="liab">$0.0000</div>
  <p class="l">صافي التطبيق 30% = <b id="own">$0</b> · المستحق للمستخدمين 70% = <b id="usr">$0</b></p>
  <button class="alt" onclick="sync()">مزامنة مع الباكند</button> <span id="sm" class="l"></span></div>

<p class="l"><a href="/withdraw.html">السحب</a> · <a href="/earn.html">اربح</a> · <a href="/admin.html">التحكم</a></p>
</div>
<script src="/auth.js" defer></script><script src="/ledger.js" defer></script>
<script>
function cp(id){ var t=document.getElementById(id).textContent; navigator.clipboard&&navigator.clipboard.writeText(t); }
function tick(){ var o=CHLedger.read();
  document.getElementById('bal').textContent='$'+CHLedger.balance().toFixed(4);
  document.getElementById('p1').textContent='$'+(CHLedger.net(o)*0.7).toFixed(4);
  document.getElementById('p2').textContent='$'+(o.bonus||0).toFixed(4);
  document.getElementById('p3').textContent='$'+(window.CHRef?CHRef.earned():0).toFixed(4);
  var n=CHLedger.net(o); document.getElementById('liab').textContent='$'+n.toFixed(4);
  document.getElementById('own').textContent='$'+(n*0.30).toFixed(4);
  document.getElementById('usr').textContent='$'+(n*0.70).toFixed(4); }
document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
document.addEventListener('ch:ledger',tick);
async function go(){ tick(); var w=await (await fetch('/wallet.json')).json();
  document.getElementById('evm').textContent=w.app_wallet.evm;
  document.getElementById('nets').innerHTML=w.app_wallet.networks.map(function(x){return '<code>'+x+'</code> '}).join('');
  if(w.app_wallet.tron) document.getElementById('trc').innerHTML='TRON (TRC20):<br><code>'+w.app_wallet.tron+'</code>';
  document.getElementById('chain').innerHTML=w.chain.map(function(c){return '<tr><td>'+c.step+'</td><td>'+c.label+'</td><td>→ '+c.to+'</td></tr>'}).join(''); }
function sync(){ var ep=localStorage.getItem('ch_endpoint')||''; if(!ep){ document.getElementById('sm').textContent='✗ لا باكند'; return; }
  var o=CHLedger.read();
  fetch(ep,{method:'POST',mode:'no-cors',headers:{'Content-Type':'text/plain'},
    body:JSON.stringify({type:'earnings',uid:CH.uid(),payload:{gross:CHLedger.gross(o),net:CHLedger.net(o),bal:CHLedger.balance()}})});
  document.getElementById('sm').textContent='✓ أُرسل'; }
</script></body></html>
EOF
G "wallet.html"

# ═══════════ 2/8 محرك المحتوى ═══════════
H "2/8 محرك المحتوى (5 مصادر مجانية)"
cat > content/build.py <<'PYEOF'
#!/usr/bin/env python3
# CineHub 3099 · محرك المحتوى — Archive.org · Ophim · Eporner · YouTube · TMDB
import json, os, re, sys, time, urllib.request, urllib.parse
UA = {'User-Agent': 'Mozilla/5.0 (CineHub3099; +https://alisalimax3.github.io)'}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
def get(url, t=35):
    return json.loads(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=t).read().decode('utf-8', 'ignore'))
def raw(url, t=35):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=t).read()
def slug(s):
    s = re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]', ' ', s or '')
    return (re.sub(r'\s+', '-', s.strip().lower())[:60] or 'item').strip('-')
def clean(h, n=230):
    return re.sub(r'\s+', ' ', re.sub('<[^>]+>', '', h or '')).strip()[:n]

def archive(q='collection:(feature_films) AND mediatype:(movies)', rows=48):
    p = [('q', q), ('rows', str(rows)), ('page', '1'), ('output', 'json'), ('sort[]', 'downloads desc')]
    p += [('fl[]', f) for f in ('identifier', 'title', 'year', 'description')]
    out = []
    for x in get('https://archive.org/advancedsearch.php?' + urllib.parse.urlencode(p)).get('response', {}).get('docs', []):
        t = (x.get('title') or '').strip()
        if not t: continue
        out.append({'src': 'archive', 'id': x['identifier'], 'title': t, 'year': x.get('year') or '',
                    'desc': clean(x.get('description')), 'embed': 'https://archive.org/embed/' + x['identifier'],
                    'thumb': 'https://archive.org/services/img/' + x['identifier']})
    return out

def ophim(pages=2, detail=18):
    out = []
    for pg in range(1, pages + 1):
        try: d = get('https://ophim1.com/danh-sach/phim-moi-cap-nhat?page=%d' % pg)
        except Exception: break
        for it in d.get('items', []):
            out.append({'src': 'ophim', 'id': it.get('slug'), 'title': it.get('name') or '',
                        'orig': it.get('origin_name') or '', 'year': (it.get('year') or ''),
                        'desc': clean(it.get('content')), 'embed': '', 'quality': it.get('quality') or '',
                        'lang': it.get('lang') or '', 'type': it.get('type') or '',
                        'thumb': 'https://img.ophim.live/uploads/movies/' + (it.get('thumb_url') or '')})
    for it in out[:detail]:
        try:
            d = get('https://ophim1.com/phim/' + it['id']).get('movie', {})
            eps = d.get('episodes') or []
            if eps and eps[0].get('server_data'):
                it['embed'] = eps[0]['server_data'][0].get('link_embed') or ''
        except Exception: pass
        time.sleep(0.25)
    return out

def eporner(rows=48, order='top-weekly'):
    try: d = get('https://www.eporner.com/api/v2/video/search/?query=&per_page=%d&page=1&thumbsize=big&order=%s&format=json' % (rows, order))
    except Exception: return []
    out = []
    for v in d.get('videos', []):
        out.append({'src': 'eporner', 'id': v['id'], 'title': v['title'],
                    'dur': int(v.get('length_min') or 0) * 60 + int(v.get('length_sec') or 0),
                    'views': v.get('views') or 0, 'thumb': (v.get('default_thumb') or {}).get('src', ''),
                    'embed': 'https://www.eporner.com/embed/%s/' % v['id'], 'keywords': v.get('keywords', '')})
    return out

CH = [('UCQq0F1Z9l2VvHFGRhRFAP7g', 'أفلام عربية'),
      ('UC5Bp7cB7p4G6u4x8n9rXm0Q', 'سينما'),
      ('UC7b0kKk1V6rN1lB0j1M0m6Q', 'وثائقي')]
def yt(cid):
    import xml.etree.ElementTree as ET
    ns = {'a': 'http://www.w3.org/2005/Atom', 'yt': 'http://www.youtube.com/xml/schemas/2015'}
    try: x = ET.fromstring(raw('https://www.youtube.com/feeds/videos.xml?channel_id=' + cid))
    except Exception: return []
    out = []
    for e in x.findall('a:entry', ns)[:14]:
        v = e.find('yt:videoId', ns).text
        out.append({'src': 'yt', 'id': v, 'title': e.find('a:title', ns).text,
                    'embed': 'https://www.youtube.com/embed/' + v, 'thumb': 'https://i.ytimg.com/vi/%s/hqdefault.jpg' % v})
    return out

def tmdb(key):
    if not key: return []
    out = []
    for kind in ('movie', 'tv'):
        try: d = get('https://api.themoviedb.org/3/trending/%s/week?api_key=%s&language=ar' % (kind, key))
        except Exception: continue
        for x in d.get('results', [])[:30]:
            t = x.get('title') or x.get('name') or ''
            if not t: continue
            out.append({'src': 'tmdb', 'id': str(x['id']), 'title': t,
                        'year': (x.get('release_date') or x.get('first_air_date') or '')[:4],
                        'desc': clean(x.get('overview')), 'rating': round(x.get('vote_average') or 0, 1),
                        'thumb': 'https://image.tmdb.org/t/p/w342' + x['poster_path'] if x.get('poster_path') else '',
                        'embed': 'https://www.youtube.com/embed?listType=search&list=' + urllib.parse.quote(t + ' trailer')})
    return out

def main():
    key = os.environ.get('TMDB_KEY', '')
    data = {'movies': [], 'series': [], 'adult': [], 'channels': [], 'updated': time.strftime('%Y-%m-%d %H:%M')}
    for name, fn in (('archive', archive), ('ophim', ophim), ('eporner', eporner)):
        try:
            r = fn(); print('  %-9s %d' % (name, len(r)))
        except Exception as e:
            r = []; print('  %-9s ✗ %s' % (name, e))
        if name == 'eporner': data['adult'] = r
        else: data['movies'] += r
    try:
        r = tmdb(key); data['movies'] += r; print('  %-9s %d' % ('tmdb', len(r)))
    except Exception as e: print('  tmdb ✗', e)
    for cid, label in CH:
        try:
            v = yt(cid)
            for x in v: x['channel'] = label
            data['channels'] += v
            print('  yt %-8s %d' % (label, len(v)))
        except Exception: pass
    os.makedirs('data', exist_ok=True)
    json.dump(data, open('data/index.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for k in ('movies', 'adult', 'channels'):
        json.dump(data[k], open('data/%s.json' % k, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('  المجموع: %d عنصر' % (len(data['movies']) + len(data['adult']) + len(data['channels'])))
    return data

if __name__ == '__main__':
    main()
PYEOF
chmod +x content/build.py
G "build.py"

# ═══════════ 3/8 صفحات المحتوى ═══════════
H "3/8 صفحات العرض"
cat > content/render.py <<'PYEOF'
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
PYEOF
chmod +x content/render.py
G "render.py"

# ═══════════ 4/8 انتشار تلقائي ═══════════
H "4/8 الانتشار والفهرسة"
cat > spread.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, re, glob, urllib.request, datetime
ROOT = os.path.dirname(os.path.abspath(__file__)); os.chdir(ROOT)
B = "https://alisalimax3.github.io"
def urls():
    U = []
    for r, d, f in os.walk('.'):
        d[:] = [x for x in d if x not in ('.git', 'node_modules', 'backups', '.tmp', 'content')]
        for x in f:
            if x.endswith('.html'):
                p = os.path.relpath(os.path.join(r, x), '.').replace('\\', '/')
                U.append(B + '/' if p == 'index.html' else B + '/' + p)
    return sorted(set(U))
U = urls(); T = datetime.date.today().isoformat()
open('sitemap.xml', 'w').write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    + ''.join('  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n' % (u, T) for u in U)
    + '</urlset>')
open('robots.txt', 'w').write('User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n' % B)
print('  sitemap: %d رابط' % len(U))
k = [f[:-4] for f in glob.glob('*.txt') if re.fullmatch(r'[0-9a-f]{32}\.txt', f)]
if k:
    d = json.dumps({"host": "alisalimax3.github.io", "key": k[0], "keyLocation": B + "/" + k[0] + ".txt", "urlList": U[:900]}).encode()
    for ep in ('https://api.indexnow.org/indexnow', 'https://www.bing.com/indexnow'):
        try:
            r = urllib.request.Request(ep, data=d, headers={'Content-Type': 'application/json; charset=utf-8'})
            print('  IndexNow %s → %s' % (ep.split('/')[2], urllib.request.urlopen(r, timeout=30).status))
        except Exception as e: print('  IndexNow ✗', e)
else:
    print('  ! لا يوجد مفتاح IndexNow (ملف 32hex.txt)')
for ping in ('https://www.google.com/ping?sitemap=%s/sitemap.xml' % B,):
    try: print('  ping', ping.split('/')[2], urllib.request.urlopen(ping, timeout=25).status)
    except Exception as e: print('  ping ✗', e)
PYEOF

cat > nav.js <<'EOF'
(function(){
  var items=[['/','الرئيسية'],['/movies.html','أفلام'],['/channels.html','مسلسلات'],['/adult.html','للكبار'],['/earn.html','اربح'],['/wallet.html','محفظتي']];
  function go(){
    if(document.getElementById('chnav')) return;
    var p=location.pathname, w=document.createElement('div'); w.id='chnav';
    w.style.cssText='position:fixed;bottom:0;left:0;right:0;z-index:9998;background:#0b1020f2;border-top:1px solid #1e2a44;display:flex;overflow-x:auto';
    w.innerHTML=items.map(function(i){var a=p===i[0]||(i[0]!=='/'&&p.indexOf(i[0])===0);
      return '<a href="'+i[0]+'" style="flex:1;min-width:70px;text-align:center;padding:11px 6px;font:12px system-ui;text-decoration:none;color:'+(a?'#4dd0e1':'#8aa0c0')+'">'+i[1]+'</a>'}).join('');
    document.body.appendChild(w); document.body.style.paddingBottom='64px';
  }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
})();
EOF
G "spread.py + nav.js"

# ═══════════ 5/8 الأتمتة ═══════════
H "5/8 حلقة الأتمتة"
cat > auto.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 · auto.sh — يعمل وحده كل 3 ساعات
#   nohup bash auto.sh >auto.log 2>&1 &
cd ~/cinehub3099 || exit 1
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR"
command -v termux-wake-lock >/dev/null && termux-wake-lock
while true; do
  printf '\n=== %s ===\n' "$(date -u +%FT%TZ)"
  python3 content/build.py 2>&1 | tail -12
  python3 content/render.py 2>&1 | tail -4
  python3 - <<'PY'
import os,re
F=[]
for r,d,f in os.walk('.'):
    d[:]=[x for x in d if x not in ('.git','node_modules','backups','.tmp','content')]
    F+=[os.path.join(r,x) for x in f if x.endswith('.html')]
SC=['/nav.js']
for p in F:
    s=open(p,encoding='utf-8').read()
    if 'nav.js' in s: continue
    s=s.replace('</body>','<script src="/nav.js" defer></script>\n</body>',1) if '</body>' in s else s+'<script src="/nav.js" defer></script>'
    open(p,'w',encoding='utf-8').write(s)
PY
  python3 spread.py 2>&1 | tail -6
  T="$(tr -d '\n\r ' < .gh-token)"
  git remote set-url origin "https://x-access-token:${T}@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git" 2>/dev/null || \
  git remote add origin "https://x-access-token:${T}@github.com/alkazmybwhwr-dot/alisalimax3.github.io.git"
  git add -A; git rm --cached -q --ignore-unmatch .gh-token .license-secret 2>/dev/null
  git diff --cached --quiet || git commit -q -m "auto: content refresh $(date -u +%FT%TZ)"
  bash deploy.sh main "auto $(date -u +%FT%TZ)"&& echo "  ✓ نُشر" || { echo "  ✗"; cat "$D/.gp.err"; }
  sleep 10800
done
EOF
chmod +x auto.sh
G "auto.sh"

# ═══════════ 6/8 بناء المحتوى الآن ═══════════
H "6/8 بناء المحتوى"
python3 content/build.py 2>&1 | tail -12
python3 content/render.py 2>&1 | tail -5

# ═══════════ 7/8 حقن + نشر ═══════════
H "7/8 حقن ونشر"
python3 - <<'PY'
import os
F=[]
for r,d,f in os.walk('.'):
    d[:]=[x for x in d if x not in ('.git','node_modules','backups','.tmp','content')]
    F+=[os.path.join(r,x) for x in f if x.endswith('.html')]
for p in F:
    s=open(p,encoding='utf-8').read()
    if 'nav.js' in s: continue
    s=s.replace('</body>','<script src="/nav.js" defer></script>\n</body>',1) if '</body>' in s else s+'<script src="/nav.js" defer></script>'
    open(p,'w',encoding='utf-8').write(s)
print('  nav مُحقن في',len(F))
PY
python3 spread.py 2>&1 | tail -6
[ -f .nojekyll ] || : > .nojekyll
T="$(tr -d '\n\r ' < .gh-token)"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${OWNER}/${REPO}.git"
git add -A; git rm --cached -q --ignore-unmatch .gh-token .license-secret 2>/dev/null
git diff --cached --quiet || git commit -q -m "feat: wallet+content engine+auto-spread $(date -u +%FT%TZ)"
bash deploy.sh main "auto $(date -u +%FT%TZ)"&& G "نُشر" || { R "فشل"; cat "$D/.gp.err"; }

# ═══════════ 8/8 تحقق ═══════════
H "8/8 تحقق"
sleep 80
python3 - <<'PY'
import urllib.request,json
B="https://alisalimax3.github.io"
for p in ("/","/movies.html","/adult.html","/channels.html","/wallet.html","/earn.html","/withdraw.html","/data/all.json","/sitemap.xml"):
    try: c=urllib.request.urlopen(B+p,timeout=25).status
    except Exception as e: c=getattr(e,"code","ERR")
    print("  %-20s %s %s"%(p,c,"✓" if c==200 else "✗"))
try:
    n=len(json.loads(urllib.request.urlopen(B+"/data/all.json",timeout=25).read()))
    print("  عناصر المحتوى المنشورة:",n)
except Exception as e: print("  محتوى:",e)
PY
printf '\n\033[32m══ اكتمل · %s/wallet.html ══\033[0m\n' "$SITE"
printf '\033[33mللتشغيل الذاتي: cd ~/cinehub3099 && nohup bash auto.sh >auto.log 2>&1 &\033[0m\n'
