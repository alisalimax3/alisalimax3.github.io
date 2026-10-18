#!/usr/bin/env python3
import json,os,glob,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
it=len((rd("catalog.json",{}) or {}).get("items") or [])
pg=len(glob.glob("m/*.html"))+len(glob.glob("g/*.html"))
kw=len((rd("keywords.json",{}) or {}).get("items") or [])
tot=round(it*0.00014+pg*0.0011+kw*0.005,4)
json.dump({"total":tot,"items":it,"pages":pg,"keywords":kw,"kind":"تقديري",
 "updated":int(time.time()),"human":time.strftime("%Y-%m-%d %H:%M")},
 open("earnings.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("تقديري: $%.4f (%d عنصر · %d صفحة)"%(tot,it,pg))
