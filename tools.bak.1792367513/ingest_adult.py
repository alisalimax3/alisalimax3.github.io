#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجلب فيديو حقيقيًا من واجهات مجانية بلا مفتاح: Eporner + RedTube"""
import json, os, re, urllib.request, urllib.parse, datetime, random
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
UA={"User-Agent":"Mozilla/5.0 (cinehub3099)"}
def j(url):
    try:
        r=urllib.request.urlopen(urllib.request.Request(url,headers=UA),timeout=40)
        return json.loads(r.read().decode("utf-8","replace"))
    except Exception as e:
        print("  تعذّر:",url[:60],str(e)[:70]); return None
def src_iframe(s):
    m=re.search(r'src=["\']([^"\']+)',s or "")
    return m.group(1) if m else (s or "")
items={}
# --- Eporner (بلا مفتاح) ---
orders=["top-weekly","top-monthly","top-all-time","top-rated","latest","longest"]
for o in orders:
    d=j("https://www.eporner.com/api/v2/video/search/?query=&per_page=100&page=1&thumbsize=big&order=%s&gay=0&lq=1&format=json"%o)
    if not d: continue
    for v in d.get("videos",[]):
        i=str(v.get("id") or "")
        if not i or i in items: continue
        th=((v.get("default_thumb") or {}).get("src")) or ""
        if not th and v.get("thumbs"): th=v["thumbs"][0].get("src","")
        tags=",".join([t.get("tag","") for t in (v.get("tags") or [])][:6])
        items[i]={"i":i,"t":re.sub(r"\s+"," ",(v.get("title") or "").strip())[:95],
                  "d":str(v.get("duration") or ""),"th":th,"e":src_iframe(v.get("embed")),
                  "g":tags,"s":"Eporner","v":int(v.get("views") or 0)}
    print("  Eporner %s: %d"%(o,len(d.get("videos",[]))))
# --- RedTube (بلا مفتاح) ---
for pg in (1,2,3,4,5,6,7,8):
    d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d&ordering=newest"%pg)
    if not d: continue
    for w in d.get("videos",[]):
        v=w.get("video") or {}
        i="rt"+str(v.get("video_id") or "")
        if i=="rt" or i in items: continue
        tags=",".join((v.get("tags") or [])[:6])
        items[i]={"i":i,"t":re.sub(r"\s+"," ",(v.get("title") or "").strip())[:95],
                  "d":str(v.get("duration") or ""),"th":v.get("thumb") or "",
                  "e":v.get("embed_url") or "","g":tags,"s":"RedTube","v":int(v.get("views") or 0)}
    print("  RedTube ص%s: %d"%(pg,len(d.get("videos",[]))))
out=[x for x in items.values() if x["e"] and x["t"]]
random.shuffle(out); out=out[:int(os.environ.get("ADULT_MAX","900"))]
tags={}
for x in out:
    for t in x["g"].split(","):
        t=t.strip().lower()
        if t: tags[t]=tags.get(t,0)+1
top=sorted(tags.items(),key=lambda k:-k[1])[:60]
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
           "count":len(out),"tags":[t for t,_ in top],"items":out},
          open("adult.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(out),"tags":[t for t,_ in top],"sources":["Eporner","RedTube"]},
          open("adult-meta.json","w"),ensure_ascii=False)
print("فيديو حقيقي للكبار:",len(out),"| وسوم:",len(top))
