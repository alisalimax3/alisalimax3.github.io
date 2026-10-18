#!/usr/bin/env python3
"""Wikidata SPARQL: منظمات وشركات وعلامات وجامعات ومواقع — بمواقعها الرسمية (P856). لا مفتاح."""
import json,os,re,urllib.request,urllib.parse,datetime,time
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA={'User-Agent':'CineHub3099/1.0 (https://alkazmybwhwr-dot.github.io)','Accept':'application/sparql-results+json','Accept-Encoding':'identity'}
EP='https://query.wikidata.org/sparql'
QS=[('company','Q4830453',45000),('company','Q783794',45000),('organization','Q43229',40000),
    ('brand','Q431289',20000),('university','Q3918',12000),('website','Q35127',12000),
    ('magazine','Q41298',8000),('newspaper','Q11032',6000)]
BLOCK=set("""wikipedia wikimedia wikidata wiktionary commons doi jstor worldcat archive web.archive.org
books.google scholar.google google.com facebook.com twitter.com x.com instagram.com youtube.com
linkedin.com tiktok.com pinterest.com reddit.com t.co bit.ly ow.ly goo.gl mapy.cz geohack.toolforge.org""".split())
def sp(q,limit):
    body=urllib.parse.urlencode({'query':q%limit,'format':'json'}).encode()
    rq=urllib.request.Request(EP,data=body,headers=UA)
    return json.loads(urllib.request.urlopen(rq,timeout=90).read().decode('utf-8','ignore'))
TMPL="""SELECT ?w WHERE { ?i wdt:P31/wdt:P279* wd:%s . ?i wdt:P856 ?w . } LIMIT %d"""
def dom(u):
    try: h=urllib.parse.urlparse(u).netloc.lower().split(':')[0]
    except Exception: return None
    if h.startswith('www.'): h=h[4:]
    return h or None
def blocked(h): return any(h==b or h.endswith('.'+b) for b in BLOCK)
found={};errs={}
for kind,qid,lim in QS:
    for attempt,use in enumerate((lim,lim//2,8000)):
        try:
            j=sp(TMPL%(qid,use),use)
            rows=j.get('results',{}).get('bindings',[])
            n=0
            for r in rows:
                h=dom((r.get('w') or {}).get('value',''))
                if not h or blocked(h) or '.' not in h or len(h)>60: continue
                if h not in found: found[h]=kind; n+=1
            print('  %-11s %-9s %6d (جديد %d)'%(kind,qid,len(rows),n))
            break
        except Exception as e:
            errs['%s_%d'%(qid,attempt)]='%s'%type(e).__name__
            time.sleep(3)
print('  إجمالي نطاقات فريدة:',len(found))
if len(found)<5000: raise SystemExit('  ✗ Wikidata ضعيف — سنعتمد على ويكيبيديا')
items=[{'id':re.sub(r'[^a-z0-9]+','-',h).strip('-'),'n':h.split('.')[-2].replace('-',' ').title()[:60],
  'u':'https://'+h+'/','h':h,'k':k} for h,k in sorted(found.items())]
json.dump({'src':'wikidata','name':'Wikidata جهات','items':items},open(os.path.join(R,'data','catalog','wikidata.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'domains':len(found),'errors':errs},open(os.path.join(R,'data','wikidata-report.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
