import os,re
BASE="https://alkazmybwhwr-dot.github.io"
SC=["/push.js","/ads.js","/engage.js","/live-earnings.js"]
LG=[d for d in ("en","es","fr","id","pt","tr","ar") if os.path.isdir(d)]
hl="<!--hreflang-->"+"".join('\n<link rel="alternate" hreflang="%s" href="%s/%s/">'%(l,BASE,l) for l in LG)
hl+='\n<link rel="alternate" hreflang="x-default" href="%s/">'%BASE+"\n<!--/hreflang-->"
F=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in ("node_modules","backups",".git")]
    F+=[os.path.join(r,x) for x in f if x.endswith(".html")]
n=0
for p in F:
    s=o=open(p,encoding="utf-8").read()
    s=re.sub(r"<!--hreflang-->.*?<!--/hreflang-->","",s,flags=re.S)
    if "<head>" in s: s=s.replace("<head>","<head>\n"+hl,1)
    for sc in SC:
        if os.path.basename(sc) in s: continue
        t='<script src="%s" defer></script>'%sc
        s=s.replace("</body>",t+"\n</body>",1) if "</body>" in s else s+"\n"+t
    if s!=o: open(p,"w",encoding="utf-8").write(s); n+=1
print("SEO: %d ملف"%n)
