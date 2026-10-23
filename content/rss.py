#!/usr/bin/env python3
import json,os,html,datetime,re
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
B="https://alisalimax3.github.io"
D=json.load(open('data/index.json',encoding='utf-8'))
def slug(s):
    s=re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]',' ',s or ''); return (re.sub(r'\s+','-',s.strip().lower())[:60] or 'item').strip('-')
items=[]
for x in D.get('movies',[])[:60]: items.append((x['title'],B+'/movies.html',x.get('desc',''),x.get('thumb','')))
for x in D.get('adult',[])[:40]: items.append((x['title'],B+'/adult.html',x.get('keywords',''),x.get('thumb','')))
now=datetime.datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S +0000')
x='<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"><channel>\n'
x+='<title>CineHub 3099</title><link>%s/</link><description>أفلام ومسلسلات مجاناً</description><language>ar</language>\n'%B
x+='<lastBuildDate>%s</lastBuildDate>\n'%now
for t,u,d,img in items[:70]:
    x+='<item><title>%s</title><link>%s</link><description>%s</description>'%(html.escape(t),u,html.escape(d or ''))
    if img: x+='<enclosure url="%s" type="image/jpeg"/>'%html.escape(img)
    x+='<pubDate>%s</pubDate></item>\n'%now
x+='</channel></rss>'
open('feed.xml','w',encoding='utf-8').write(x)
print('  feed.xml:',min(len(items),70),'عنصر')
