#!/usr/bin/env python3
import json, os, re, glob, urllib.request, datetime
ROOT = os.path.dirname(os.path.abspath(__file__)); os.chdir(ROOT)
B = "https://alkazmybwhwr-dot.github.io"
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
    d = json.dumps({"host": "alkazmybwhwr-dot.github.io", "key": k[0], "keyLocation": B + "/" + k[0] + ".txt", "urlList": U[:900]}).encode()
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
