import os,re,glob,json,urllib.request
B="https://alkazmybwhwr-dot.github.io";H="alkazmybwhwr-dot.github.io"
k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
if not k: print("! لا ملف مفتاح IndexNow"); raise SystemExit
U=re.findall(r"<loc>(.*?)</loc>",open("sitemap.xml").read())[:900]
d=json.dumps({"host":H,"key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":U}).encode()
r=urllib.request.Request("https://api.indexnow.org/indexnow",data=d,headers={"Content-Type":"application/json; charset=utf-8"})
try: print("IndexNow:",urllib.request.urlopen(r,timeout=30).status,"·",len(U),"رابط")
except Exception as e: print("IndexNow:",e)
