import os,datetime
B="https://alisalimax3.github.io";U=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in ("node_modules","backups",".git")]
    for x in f:
        if x.endswith(".html"):
            p=os.path.relpath(os.path.join(r,x),".").replace("\\","/")
            U.append(B+"/" if p=="index.html" else B+"/"+p)
U=sorted(set(U));T=datetime.date.today().isoformat()
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
+"".join("  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"%(u,T) for u in U)+"</urlset>")
print("sitemap: %d رابط"%len(U))
