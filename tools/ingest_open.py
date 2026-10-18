#!/usr/bin/env python3
"""7 مصادر مفتوحة: Dailymotion · PeerTube · iTunes · Commons · Odysee · Gutendex · YouTube(Piped)"""
import json,os,urllib.request,urllib.parse,datetime,re
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); C=os.path.join(R,'data','catalog'); os.makedirs(C,exist_ok=True)
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)','Accept':'application/json','Accept-Encoding':'identity'}
def get(u,h=None,t=45,data=None):
    rq=urllib.request.Request(u,headers=h or UA,data=data)
    return urllib.request.urlopen(rq,timeout=t).read().decode('utf-8','ignore')
def js(u,h=None,data=None): return json.loads(get(u,h,data=data))
def wr(name,items,extra=None):
    json.dump({'src':name,'items':items,**(extra or {})},open(os.path.join(C,name+'.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
    print('  %-12s %d'%(name,len(items)))
QUERY=['film','movie','documentary','animation','trailer','music video','comedy','action','horror','nature','science','history','sport','cooking','travel','technology','education','news','cartoon','drama','classic','arabic','yemen','سعودي','مصري']
def dailymotion():
    out=[]
    def one(p):
        u='https://api.dailymotion.com/videos?'+urllib.parse.urlencode(
          {'limit':100,'page':p,'sort':'visited','fields':'id,title,thumbnail_360_url,duration,owner.screenname,created_time'})
        return (js(u).get('list') or [])
    with ThreadPoolExecutor(8) as ex:
        for lst in ex.map(one,range(1,61)):
            for v in lst:
                if not v.get('id'): continue
                out.append({'id':v['id'],'t':(v.get('title') or '')[:110],'img':v.get('thumbnail_360_url') or '',
                 'emb':'https://www.dailymotion.com/embed/video/'+v['id'],'kind':'iframe',
                 'dur':v.get('duration') or 0,'by':v.get('owner.screenname') or '','c':'dailymotion'})
    return out
def itunes():
    out=[]
    def one(term):
        u='https://itunes.apple.com/search?'+urllib.parse.urlencode({'term':term,'media':'movie','limit':200,'country':'US'})
        return (js(u).get('results') or [])
    with ThreadPoolExecutor(8) as ex:
        for r in ex.map(one,QUERY[:26]):
            for v in r:
                pv=v.get('previewUrl') or ''
                if not pv: continue
                out.append({'id':str(v.get('trackId') or ''),'t':(v.get('trackName') or '')[:110],
                 'img':(v.get('artworkUrl100') or '').replace('100x100','300x300'),
                 'emb':pv,'kind':'video','dur':0,'by':v.get('artistName') or '',
                 'y':(v.get('releaseDate') or '')[:4],'c':'itunes'})
    return out
def peertube():
    out=[]
    def one(args):
        q,st=args
        u='https://sepiasearch.org/api/v1/search/videos?'+urllib.parse.urlencode({'search':q,'count':100,'start':st,'sort':'-views'})
        try: return (js(u).get('data') or [])
        except Exception: return []
    with ThreadPoolExecutor(8) as ex:
        for r in ex.map(one,[(q,s) for q in QUERY[:14] for s in (0,100)]):
            for v in r:
                e=v.get('embedUrl') or v.get('url') or ''
                if not e: continue
                out.append({'id':str(v.get('uuid') or v.get('shortUUID') or ''),'t':(v.get('name') or '')[:110],
                 'img':v.get('thumbnailUrl') or '','emb':e,'kind':'iframe','dur':v.get('duration') or 0,
                 'by':(v.get('channel') or {}).get('displayName','') if isinstance(v.get('channel'),dict) else '','c':'peertube'})
    return out
def commons():
    cats=['Videos','Videos_of_animals','Animated_gifs','Video_clips','Documentary_films','Nature_videos',
          'Videos_by_subject','Aircraft_videos','Space_videos','Music_videos','Sports_videos','Science_videos',
          'Historical_videos','Videos_of_people','Time-lapse_videos','Drone_videos']
    out=[]
    def one(c):
        u='https://commons.wikimedia.org/w/api.php?'+urllib.parse.urlencode(
          {'action':'query','generator':'categorymembers','gcmtitle':'Category:'+c,'gcmtype':'file','gcmlimit':500,
           'prop':'imageinfo','iiprop':'url|mime|size','format':'json'})
        try: return ((js(u).get('query') or {}).get('pages') or {})
        except Exception: return {}
    with ThreadPoolExecutor(6) as ex:
        for pg in ex.map(one,cats):
            for k,v in (pg or {}).items():
                ii=(v.get('imageinfo') or [{}])[0]; u=ii.get('url') or ''; mime=ii.get('mime') or ''
                if not u: continue
                if 'video' in mime or 'ogg' in mime: kind='video'
                elif mime.startswith('image/'): kind='image'
                else: continue
                out.append({'id':re.sub(r'[^A-Za-z0-9._-]','',v.get('title','').replace('File:',''))[:80],
                 't':v.get('title','').replace('File:','')[:110],'img':u if kind=='image' else '',
                 'emb':u,'kind':kind,'dur':0,'by':'Wikimedia Commons','c':'commons'})
    return out
def odysee():
    out=[]
    def one(p):
        body=json.dumps({'jsonrpc':'2.0','id':1,'method':'claim_search','params':{
          'page':p,'page_size':50,'claim_type':['stream'],'has_source':True,
          'order_by':['trending_group','trending_mixed']}}).encode()
        try:
            return (js('https://api.lbry.tv/api/v1/proxy?m=claim_search',data=body).get('result') or {}).get('items') or []
        except Exception: return []
    with ThreadPoolExecutor(8) as ex:
        for r in ex.map(one,range(1,41)):
            for v in r:
                name=v.get('name');cid=v.get('claim_id')
                if not name or not cid: continue
                tv=(v.get('value') or {})
                out.append({'id':cid,'t':(tv.get('title') or name)[:110],
                 'img':(tv.get('thumbnail') or {}).get('url') if isinstance(tv.get('thumbnail'),dict) else '',
                 'emb':'https://odysee.com/$/embed/%s:%s'%(name,cid),'kind':'iframe','dur':tv.get('duration') or 0,
                 'by':'Odysee','c':'odysee'})
    return out
def gutendex():
    out=[]
    for p in range(1,41):
        try: r=js('https://gutendex.com/books?page=%d'%p).get('results') or []
        except Exception: r=[]
        for b in r:
            f=b.get('formats') or {}
            html=f.get('text/html') or f.get('application/epub+zip') or f.get('text/plain; charset=utf-8') or ''
            if not html: continue
            out.append({'id':str(b.get('id')),'t':(b.get('title') or '')[:110],'img':(f.get('image/jpeg') or ''),
             'emb':html,'kind':'link','dur':0,'by':', '.join((b.get('authors') or [{}])[0].get('name','').split(',')[:1]) if b.get('authors') else '','c':'gutendex'})
    return out
def piped():
    hosts=['https://pipedapi.kavin.rocks','https://pipedapi.adminforge.de','https://api.piped.private.coffee']
    out=[]
    def one(q):
        for h in hosts:
            try:
                r=js(h+'/search?'+urllib.parse.urlencode({'q':q,'filter':'videos'}))
                return (r.get('items') or [])
            except Exception: continue
        return []
    with ThreadPoolExecutor(6) as ex:
        for r in ex.map(one,QUERY[:16]):
            for v in r:
                u=v.get('url') or ''
                vid=u.split('v=')[-1] if 'v=' in u else ''
                if not vid: continue
                out.append({'id':vid,'t':(v.get('title') or '')[:110],'img':v.get('thumbnail') or '',
                 'emb':'https://www.youtube.com/embed/'+vid,'kind':'iframe','dur':v.get('duration') or 0,
                 'by':v.get('uploaderName') or '','c':'piped'})
    return out
tot={}
for name,fn in (('dailymotion',dailymotion),('itunes',itunes),('peertube',peertube),('commons',commons),
                ('odysee',odysee),('gutendex',gutendex),('piped',piped)):
    try:
        it=fn(); wr(name,it); tot[name]=len(it)
    except Exception as e:
        print('  ! %s %s'%(name,type(e).__name__)); wr(name,[]); tot[name]=0
json.dump({'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),'counts':tot,
 'total':sum(tot.values())},open(os.path.join(C,'_open-index.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('  المجموع المفتوح:',sum(tot.values()))
