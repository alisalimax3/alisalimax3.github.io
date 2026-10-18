#!/usr/bin/env python3
import json,os,urllib.request,urllib.parse,datetime,time
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.makedirs(os.path.join(R,'data','catalog'),exist_ok=True)
UA={'User-Agent':'CineHub3099','Accept':'application/json','Accept-Encoding':'identity'}
def raw(u,t=90): return urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t).read().decode('utf-8','ignore')
GEN={'Action':'action_films','Comedy':'comedy_films','Drama':'drama_films','Horror':'horror_films',
 'Thriller':'thriller_films','Western':'western_films','Romance':'romance_films','SciFi':'sci-fi_horror',
 'Mystery':'mystery_films','Adventure':'adventure_films','Animation':'animation','Documentary':'documentaryfilms',
 'Noir':'film_noir','Silent':'silent_films','Classic':'feature_films','Cartoon':'classic_cartoons','Short':'short_films'}
def q(med,page,rows=500,extra=None):
    p={'q':'mediatype:%s AND downloads:[200 TO null]%s'%(med,extra or ''),'fl[]':['identifier','title','year','downloads','collection'],
       'rows':rows,'page':page,'sort[]':'downloads desc','output':'json'}
    u='https://archive.org/advancedsearch.php?'+urllib.parse.urlencode(p,doseq=True)
    return ((json.loads(raw(u)).get('response') or {}).get('docs') or [])
items=[];errs={}
def job(a):
    med,page,extra,tag=a
    for _ in (1,2):
        try:
            d=q(med,page,extra=extra)
            if d: return tag,d
        except Exception as e: errs['%s%s_p%d'%(med,tag,page)]=type(e).__name__
        time.sleep(2)
    return tag,[]
tasks=[('movies',p,None,'أفلام') for p in range(1,21)]+[('audio',p,None,'صوت') for p in range(1,9)]+[('texts',p,None,'كتب') for p in range(1,6)]
for g,col in GEN.items():
    tasks.append(('movies',1,' AND collection:%s'%col,g))
with ThreadPoolExecutor(8) as ex:
    for tag,docs in ex.map(job,tasks):
        for d in docs:
            i=d.get('identifier')
            if not i: continue
            items.append({'id':i,'t':(d.get('title') or i)[:110],'y':d.get('year') or '','dl':d.get('downloads') or 0,
              'g':tag,'img':'https://archive.org/services/img/'+i,'emb':'https://archive.org/embed/'+i,
              'kind':'iframe','c':'movie' if tag in GEN or tag=='أفلام' else ('audio' if tag=='صوت' else 'book')})
seen=set();out=[]
for x in items:
    if x['id'] in seen: continue
    seen.add(x['id']); out.append(x)
json.dump({'src':'archive','name':'Archive.org','items':out},open(os.path.join(R,'data','catalog','archive.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
mov=[x for x in out if x['c']=='movie']
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'total':len(out),'movies':len(mov),'errors':errs,'cols':{'أفلام':mov[:500],'صوت':[x for x in out if x['c']=='audio'][:300],'كتب':[x for x in out if x['c']=='book'][:300]}},
 open(os.path.join(R,'data','archive.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('  archive: %d عنصر (%d فيلم) · أخطاء %d'%(len(out),len(mov),len(errs)))
