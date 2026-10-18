#!/usr/bin/env python3
import json,os,re,urllib.request,urllib.parse,datetime,random
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
UA={"User-Agent":"Mozilla/5.0 (cinehub3099)"}
def s(v):
    if v is None: return ""
    if isinstance(v,list): return " ".join(str(i) for i in v)
    return str(v)
def j(u,t=40):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t)
        return json.loads(r.read().decode("utf-8","replace"))
    except Exception: return None
SUBJ=[("كوميديا","عائلي","comedy"),("دراما","+13","drama"),("مغامرات","عائلي","adventure"),
("خيال علمي","+12","\"science fiction\""),("رعب","+13","horror"),("غربي","+12","western"),
("غموض","+12","mystery"),("رومانسي","+12","romance"),("كرتون","كل الأعمار","cartoon"),
("رسوم متحركة","كل الأعمار","animation"),("أطفال","كل الأعمار","children"),("وثائقي","عائلي","documentary"),
("صامت","+12","\"silent film\""),("حربي","+13","war"),("موسيقي","عائلي","musical"),
("جريمة","+13","crime"),("فانتازيا","عائلي","fantasy"),("سيرة","عائلي","biography"),
("تاريخي","+12","history"),("رياضة","عائلي","sport"),("عائلي","كل الأعمار","family"),
("إثارة","+13","thriller")]
films={}
for cat,age,q in SUBJ:
    for page in (1,2,3):
        u=("https://archive.org/advancedsearch.php?q="+urllib.parse.quote("mediatype:movies AND subject:(%s)"%q)+
           "&rows=100&page=%d&output=json&sort[]=downloads+desc"%page+
           "&fl[]=identifier&fl[]=title&fl[]=year&fl[]=subject&fl[]=downloads")
        d=j(u)
        if not d: continue
        for x in d.get("response",{}).get("docs",[]):
            i=s(x.get("identifier")).strip(); t=re.sub(r"\s+"," ",s(x.get("title")).strip())
            if not i or not t or i in films: continue
            films[i]={"i":i,"t":t[:95],"y":s(x.get("year"))[:4],"c":cat,"a":age,
                      "th":"https://archive.org/services/img/"+i,"e":"https://archive.org/embed/"+i,
                      "k":"iframe","s":"archive.org","v":int(x.get("downloads") or 0)}
fl=list(films.values()); random.shuffle(fl)
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),"count":len(fl),
           "cats":sorted({x["c"] for x in fl}),"ages":["كل الأعمار","عائلي","+12","+13"],"items":fl},
          open("catalog.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(fl),"cats":sorted({x["c"] for x in fl})},open("films.json","w"),ensure_ascii=False)
print("أفلام:",len(fl))
def emb(x):
    m=re.search(r'src=["\']([^"\']+)',s(x)); return m.group(1) if m else ""
ad={}
for o in ["top-weekly","top-monthly","top-all-time","top-rated","latest","longest","most-popular","top"]:
    d=j(("https://www.eporner.com/api/v2/video/top/?per_page=100&page=1&thumbsize=big&format=json" if o=="top" else ("https://www.eporner.com/api/v2/video/top/?per_page=100&page=1&thumbsize=big&format=json" if o=="top" else "https://www.eporner.com/api/v2/video/search/?query=&per_page=100&page=1&thumbsize=big&order=%s&gay=0&lq=1&format=json"%o)))
    if not d: continue
    for v in d.get("videos",[]):
        i=s(v.get("id"))
        if not i or i in ad: continue
        ad[i]={"i":i,"t":re.sub(r"\s+"," ",s(v.get("title")).strip())[:95],"d":s(v.get("duration")),
               "th":s((v.get("default_thumb") or {}).get("src")),"e":emb(v.get("embed")),
               "g":",".join([s(t.get("tag")) for t in (v.get("tags") or [])][:6]),"k":"iframe","s":"Eporner","v":int(v.get("views") or 0)}
for pg in range(1,13):
    d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d&ordering=newest&search="%pg)
    if not d: d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d"%pg)
    if not d: continue
    for w in d.get("videos",[]):
        v=w.get("video") or {}; i="rt"+s(v.get("video_id"))
        if i=="rt" or i in ad: continue
        ad[i]={"i":i,"t":re.sub(r"\s+"," ",s(v.get("title")).strip())[:95],"d":s(v.get("duration")),
               "th":s(v.get("thumb")),"e":s(v.get("embed_url")),"g":",".join([s(t) for t in (v.get("tags") or [])][:6]),
               "k":"iframe","s":"RedTube","v":int(v.get("views") or 0)}
al=[x for x in ad.values() if x["e"] and x["t"]]
if not al:
    try:
        old=json.load(open("adult.json",encoding="utf-8"))
        if old.get("count",0)>0:
            print("  الكبار: فشل الجلب — أُبقي الملف القديم (%d)"%old["count"]); raise SystemExit(0)
    except SystemExit: raise
    except Exception: pass
random.shuffle(al)
tg={}
for x in al:
    for t in x["g"].split(","):
        t=t.strip().lower()
        if t: tg[t]=tg.get(t,0)+1
top=[t for t,_ in sorted(tg.items(),key=lambda k:-k[1])[:70]]
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),"count":len(al),
           "tags":top,"items":al},open("adult.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(al),"tags":top},open("adult-meta.json","w"),ensure_ascii=False)
print("كبار:",len(al))
