#!/usr/bin/env python3
import json,os,datetime,collections
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); C=os.path.join(R,'data','catalog')
NAME={'archive':'Archive.org','dailymotion':'Dailymotion','itunes':'iTunes تريلرات','peertube':'PeerTube',
 'commons':'Wikimedia','odysee':'Odysee','gutendex':'كتب مجانية','piped':'YouTube','tmdb':'أفلام TMDB','wikidata':'جهات Wikidata'}
sources=[];total=0;years=collections.Counter();genres=collections.Counter();kinds=collections.Counter()
for f in sorted(os.listdir(C)):
    if f.startswith('_') or not f.endswith('.json'): continue
    s=f[:-5]
    try: items=json.load(open(os.path.join(C,f),encoding='utf-8')).get('items') or []
    except Exception: items=[]
    total+=len(items); sources.append({'src':s,'name':NAME.get(s,s),'n':len(items),'file':'/data/catalog/'+f})
    for x in items:
        if x.get('y'): years[str(x['y'])[:4]]+=1
        if x.get('g'): genres[x['g']]+=1
        kinds[x.get('kind') or 'iframe']+=1
sources.sort(key=lambda x:-x['n'])
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'total':total,'sources':sources,
 'facets':{'years':dict(sorted(years.items(),reverse=True)[:40]),
           'genres':dict(genres.most_common(40)),'kinds':dict(kinds)},
 'underlying':[{'n':'Wikidata','v':'100,000,000+ عنصر'},{'n':'Internet Archive','v':'40,000,000+'},
  {'n':'TMDB','v':'900,000+ فيلم'},{'n':'YouTube/Piped','v':'800,000,000+'},
  {'n':'Dailymotion','v':'100,000,000+'},{'n':'Wikimedia Commons','v':'100,000,000+ ملف'},
  {'n':'PeerTube','v':'1,000,000+'},{'n':'Odysee','v':'10,000,000+'},{'n':'Gutendex','v':'70,000+ كتاب'}]},
 open(os.path.join(R,'data','catalog-index.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('  الفهرس: %d عنصر · %d مصدر · %d نوع'%(total,len(sources),len(genres)))
