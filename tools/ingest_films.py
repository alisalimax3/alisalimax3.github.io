#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجلب أفلامًا قانونية حقيقية من archive.org: عنوان، سنة، وسم، صورة، مشغّل"""
import json, os, re, urllib.request, urllib.parse, datetime, random
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
ROWS=int(os.environ.get("FILM_ROWS","400"))

Q=[("كوميديا","عائلي","subject:(comedy)"),
   ("دراما","+13","subject:(drama)"),
   ("مغامرات","عائلي","subject:(adventure)"),
   ("خيال علمي","+12","subject:(\"science fiction\")"),
   ("رعب","+13","subject:(horror)"),
   ("غربي","+12","subject:(western)"),
   ("غموض","+12","subject:(mystery)"),
   ("رومانسي","+12","subject:(romance)"),
   ("كرتون","كل الأعمار","subject:(cartoon)"),
   ("رسوم متحركة","كل الأعمار","subject:(animation)"),
   ("أطفال","كل الأعمار","subject:(children)"),
   ("وثائقي","عائلي","subject:(documentary)"),
   ("صامت","+12","subject:(\"silent film\")"),
   ("حربي","+13","subject:(war)"),
   ("موسيقي","عائلي","subject:(musical)")]
def fetch(q, rows):
    p=urllib.parse.urlencode({"q":"mediatype:movies AND "+q,
        "rows":str(rows),"page":"1","output":"json",
        "sort[]":"downloads desc"}, doseq=True)
    for extra in ("&fl[]=identifier&fl[]=title&fl[]=year&fl[]=subject&fl[]=creator&fl[]=downloads",):
        pass
    url=("https://archive.org/advancedsearch.php?"+p+
         "&fl[]=identifier&fl[]=title&fl[]=year&fl[]=subject&fl[]=creator&fl[]=downloads")
    try:
        r=urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"cinehub3099"}),timeout=40)
        return json.loads(r.read().decode()).get("response",{}).get("docs",[])
    except Exception as e:
        print("  تعذّر:",q,str(e)[:60]); return []
items={}
for cat,age,q in Q:
    per=max(20,ROWS//len(Q))
    docs=fetch(q, per)
    for d in docs:
        i=(d.get("identifier") or "").strip()
        t=(d.get("title") or "").strip()
        if not i or not t or i in items: continue
        t=re.sub(r"\s+"," ",t)[:90]
        y=d.get("year") or ""
        items[i]={"i":i,"t":t,"y":str(y)[:4],"c":cat,"a":age,
                  "th":"https://archive.org/services/img/"+i,
                  "p":"https://archive.org/embed/"+i,
                  "d":"https://archive.org/details/"+i,
                  "s":"archive.org"}
    print("  %s: %d"%(cat,len(docs)))
out=list(items.values())
random.shuffle(out); out=out[:int(os.environ.get("FILM_MAX","1200"))]
cats=sorted({x["c"] for x in out}); ages=["كل الأعمار","عائلي","+12","+13"]
json.dump({"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
           "count":len(out),"cats":cats,"ages":ages,"items":out},
          open("catalog.json","w"),ensure_ascii=False,separators=(",",":"))
json.dump({"count":len(out),"cats":cats,"ages":ages,
           "generated":datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("films.json","w"),ensure_ascii=False)
print("أفلام حقيقية:",len(out))
