#!/usr/bin/env python3
import json,os,re,html,hashlib
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
os.makedirs("p",exist_ok=True)
COLS=["#4cc2ff","#7c5cff","#22c55e","#f59e0b","#ef4444","#06b6d4","#ec4899","#8b5cf6"]
try: cat=json.load(open("catalog.json",encoding="utf-8"))
except Exception: print("لا كتالوج"); raise SystemExit
it=cat.get("items") or []
def svg(x):
    t=(x.get("t") or "بدون عنوان").strip()
    h=hashlib.md5(str(x.get("i") or t).encode()).hexdigest()[:12]; fn="p/%s.svg"%h
    if os.path.exists(fn): return fn
    w=t.split(); lines=[]; cur=""
    for a in w:
        if len(cur+" "+a)<=22: cur=(cur+" "+a).strip()
        else: lines.append(cur); cur=a
    if cur: lines.append(cur)
    lines=lines[:3] or ["بدون عنوان"]
    c1=COLS[int(h[:2],16)%len(COLS)]; c2=COLS[int(h[2:4],16)%len(COLS)]
    tsp="".join('<tspan x="150" dy="%d">%s</tspan>'%(0 if i==0 else 22,html.escape(l)) for i,l in enumerate(lines))
    y=430-(len(lines)-1)*11
    open(fn,"w",encoding="utf-8").write(
'<svg xmlns="http://www.w3.org/2000/svg" width="300" height="450" viewBox="0 0 300 450">'
'<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>'
'<rect width="300" height="450" fill="#0b1119"/><rect width="300" height="450" fill="url(#g)" opacity=".35"/>'
'<circle cx="150" cy="200" r="52" fill="rgba(255,255,255,.12)"/><path d="M138 178 L176 200 L138 222 Z" fill="#eaf4ff"/>'
'<text x="150" y="%d" text-anchor="middle" font-family="system-ui,Tahoma" font-size="17" font-weight="700" fill="#eaf4ff">%s</text>'
'<text x="150" y="430" text-anchor="middle" font-family="system-ui" font-size="11" fill="rgba(234,244,255,.6)">CineHub 3099</text></svg>'%(c1,c2,y,tsp))
    return fn
n=0; tot=0
for x in it:
    tot+=1
    if not (x.get("th") or "").strip():
        x["th"]=svg(x); n+=1
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
print("  بلا صورة أُصلحت: %d من %d"%(n,tot))
