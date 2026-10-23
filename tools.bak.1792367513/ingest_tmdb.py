#!/usr/bin/env python3
import json,os,urllib.request,urllib.parse,datetime
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.makedirs(os.path.join(R,'data','catalog'),exist_ok=True)
K={}
if os.path.exists(os.path.join(R,'keys.env')):
    for l in open(os.path.join(R,'keys.env'),encoding='utf-8'):
        if '=' in l and not l.strip().startswith('#'):
            a,b=l.split('=',1); K[a.strip()]=b.strip()
key=K.get('TMDB_KEY','')
if not key: print('  ! لا TMDB_KEY'); raise SystemExit
G={28:'أكشن',12:'مغامرة',16:'أنيميشن',35:'كوميدي',80:'جريمة',99:'وثائقي',18:'دراما',10751:'عائلي',
   14:'فانتازيا',36:'تاريخ',27:'رعب',10402:'موسيقى',9648:'غموض',10749:'رومانسي',878:'خيال علمي',
   10770:'تلفزيوني',53:'إثارة',10752:'حرب',37:'غربي'}
def get(p,ex=None):
    q={'api_key':key}; q.update(ex or {})
    u='https://api.themoviedb.org/3/'+p+'?'+urllib.parse.urlencode(q)
    return json.loads(urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'ch'}),timeout=30).read().decode())
M=[]
for path,pages in (('movie/popular',range(1,26)),('movie/top_rated',range(1,26)),('movie/now_playing',range(1,11)),
                   ('movie/upcoming',range(1,11)),('trending/movie/week',[None])):
    for pg in pages:
        try: M+=get(path,{'page':pg} if pg else None).get('results') or []
        except Exception: pass
for g in G:
    for pg in (1,2,3,4,5):
        try: M+=get('discover/movie',{'with_genres':str(g),'page':pg,'sort_by':'popularity.desc'}).get('results') or []
        except Exception: pass
seen={};out=[]
for m in M:
    i=m.get('id')
    if not i or i in seen: continue
    seen[i]=1
    gs=[G[x] for x in (m.get('genre_ids') or []) if x in G]
    out.append({'id':str(i),'t':(m.get('title') or '')[:110],
      'img':'https://image.tmdb.org/t/p/w300'+m['poster_path'] if m.get('poster_path') else '',
      'emb':'','kind':'iframe','y':(m.get('release_date') or '')[:4],'g':gs[0] if gs else 'عام',
      'gs':gs,'rate':round(m.get('vote_average') or 0,1),'c':'tmdb','lang':m.get('original_language') or ''})
print('  TMDB:',len(out))
top=out[:900]
def vids(x):
    try:
        j=get('movie/%s/videos'%x['id'])
        for v in (j.get('results') or []):
            if v.get('site')=='YouTube' and v.get('type') in ('Trailer','Teaser'):
                return x['id'],'https://www.youtube.com/embed/'+v['key']
    except Exception: pass
    return x['id'],''
idx={x['id']:x for x in out}
with ThreadPoolExecutor(12) as ex:
    for pid,emb in ex.map(vids,top):
        if emb and pid in idx: idx[pid]['emb']=emb
json.dump({'src':'tmdb','name':'TMDB أفلام','items':out},open(os.path.join(R,'data','catalog','tmdb.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('  TMDB: %d فيلم · %d بتريلر'%(len(out),len([x for x in out if x['emb']])))
