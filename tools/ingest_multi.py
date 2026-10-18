#!/usr/bin/env python3
"""مصادر متعددة بلا مفاتيح: archive.org + Openverse + NASA"""
import json,os,re,time,urllib.request,urllib.parse
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
UA={"User-Agent":"cinehub3099/1.0"}
B=int(os.environ.get("BUDGET_SRC","240")); T0=time.time()
def left(): return B-(time.time()-T0)
def get(u,t=45):
    for a in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t) as r: return json.loads(r.read())
        except Exception:
            if a==2: raise
            time.sleep(1.5*(a+1))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
cat=rd("catalog.json",{"items":[]}) or {"items":[]}
it=cat.get("items") or []
seen={x.get("ia") or x.get("i") for x in it if isinstance(x,dict)}
def push(x):
    k=x.get("ia") or x.get("i")
    if not k or k in seen: return 0
    seen.add(k); it.append(x); return 1
added={}
# ── archive.org ──
if os.environ.get("SKIP_IA")!="1":
    COLS=os.environ.get("IA_COLS","feature_films,classic_cartoons,film_noir,sci-fi_horror,animationandcartoons,silent_films,short_films,mysteryandcrimefilms,comedy_films,television,documentaries,moviesandfilms,artsandmusicvideos,prelinger,universal_newsreels,computerchronicles,sports,newsandpublicaffairs,educationalfilms,classic_tv").split(",")
    n=0
    for col in COLS:
        if left()<40: break
        for pg in (1,2,3):
            if left()<40: break
            try:
                d=get("https://archive.org/advancedsearch.php?"+urllib.parse.urlencode(
                  {"q":"collection:(%s) AND mediatype:(movies)"%col,
                   "fl[]":["identifier","title","downloads","subject","year"],
                   "rows":200,"page":pg,"output":"json","sort[]":"downloads desc"},doseq=True))
            except Exception: break
            docs=((d.get("response") or {}).get("docs") or [])
            if not docs: break
            for x in docs:
                i=x.get("identifier")
                if not i: continue
                sj=x.get("subject")
                if isinstance(sj,list): sj=",".join(str(s) for s in sj[:6])
                n+=push({"i":i,"ia":i,"t":(x.get("title") or i)[:120],
                  "th":"https://archive.org/services/img/"+i,"e":"https://archive.org/embed/"+i,
                  "k":"iframe","s":"archive.org","v":int(x.get("downloads") or 0),
                  "y":str(x.get("year") or ""),"a":"+12","c":"عام","mt":"movies",
                  "g":str(sj or "").lower()[:120]})
            time.sleep(0.25)
    added["archive"]=n
# ── Openverse ──
if left()>30:
    n=0
    for q in "cinema,film,poster,movie,animation,space,ocean,history,city".split(","):
        if left()<20: break
        for pg in range(1,8):
            try: d=get("https://api.openverse.org/v1/images/?"+urllib.parse.urlencode({"q":q,"page_size":20,"page":pg}))
            except Exception: break
            res=d.get("results") or []
            if not res: break
            for r in res:
                i="ov-"+str(r.get("id"))[:24]
                n+=push({"i":i,"t":(r.get("title") or "بدون عنوان")[:90],
                  "th":r.get("thumbnail") or r.get("url"),"e":r.get("url"),
                  "k":"iframe","s":"openverse","v":int(r.get("width") or 0),
                  "y":"","a":"عام","c":"صور","g":str(r.get("source") or "openverse")[:60].lower()})
            time.sleep(0.2)
    added["openverse"]=n
# ── NASA ──
if left()>20:
    n=0
    for q in "space,apollo,earth,mars,nebula,launch".split(","):
        if left()<15: break
        try: d=get("https://images-api.nasa.gov/search?media_type=video&q=%s&page_size=60"%q)
        except Exception: continue
        for x in ((d.get("collection") or {}).get("items") or []):
            da=(x.get("data") or [{}])[0]; nid=da.get("nasa_id")
            lk=(x.get("links") or [{}])[0].get("href")
            if not nid or not lk: continue
            n+=push({"i":"nasa-"+nid,"t":(da.get("title") or nid)[:110],"th":lk,
              "e":"https://images-assets.nasa.gov/video/%s/%s~orig.mp4"%(nid,nid),
              "k":"iframe","s":"nasa","v":0,"y":(da.get("date_created") or "")[:4],
              "a":"عام","c":"فضاء","g":str(da.get("keywords") or "nasa space")[:100].lower()})
        time.sleep(0.3)
    added["nasa"]=n
cat["items"]=it
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
print("  "+" | ".join("%s +%d"%(k,v) for k,v in added.items())+" | الإجمالي %d"%len(it))
