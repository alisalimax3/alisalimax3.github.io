#!/usr/bin/env python3
import os,datetime,json
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); base='https://alisalimax3.github.io'
u=[]
for root,dirs,files in os.walk(R):
    if '/.git' in root: continue
    for f in files:
        if f.endswith('.html'):
            rel=os.path.relpath(os.path.join(root,f),R).replace('\\','/')
            u.append(base+'/'+('' if rel=='index.html' else rel))
u=sorted(set(u)); t=datetime.date.today().isoformat()
open(os.path.join(R,'sitemap.xml'),'w',encoding='utf-8').write(
 '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
 ''.join('<url><loc>%s</loc><lastmod>%s</lastmod></url>\n'%(x,t) for x in u)+'</urlset>\n')
open(os.path.join(R,'rss.xml'),'w',encoding='utf-8').write(
 '<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>CineHub 3099</title><link>%s/</link>'%base+
 ''.join('<item><title>%s</title><link>%s</link><pubDate>%s</pubDate></item>'%(x.split('/')[-1] or 'home',x,t) for x in u[:80])+
 '</channel></rss>\n')
print('sitemap',len(u))
