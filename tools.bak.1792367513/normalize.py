#!/usr/bin/env python3
"""يوحّد كل العناصر لمخطط واحد وحقول نصية. يعالج القوائم والقواميس والفوارغ."""
import json,os,re,hashlib
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def S(v):
    if v is None: return ""
    if isinstance(v,list): return ",".join(S(x) for x in v)
    if isinstance(v,dict): return S(v.get("name") or v.get("title") or v.get("label") or "")
    if isinstance(v,(int,float)): return str(v)
    return str(v)
def num(v):
    try: return int(float(str(v).strip() or 0))
    except Exception: return 0
def rd(p,d):
    try: return json.load(open(p,encoding="utf-8"))
    except Exception: return d
cat=rd("catalog.json",{"items":[]}) or {"items":[]}
if isinstance(cat,list): cat={"items":cat}
raw=cat.get("items") or []
out=[]; seen=set(); drop=0
for x in raw:
    if not isinstance(x,dict): drop+=1; continue
    y={k:S(v).strip() for k,v in x.items()}
    y["i"]=y.get("i") or y.get("id") or ""
    # استخراج ia/e من أي حقل
    for f in ("e","embed","u","url","link","src","th","i","id","identifier"):
        v=y.get(f,"")
        m=re.search(r"archive\.org/(?:embed|details|download|services/img|metadata)/([^/?#\"'&]+)",v)
        if m and not y.get("ia"): y["ia"]=m.group(1)
    if not y.get("ia") and y.get("s")=="archive.org" and y.get("i"):
        y["ia"]=re.sub(r"^ia:","",y["i"])
    if y.get("ia"):
        y["e"]=y.get("e") or "https://archive.org/embed/"+y["ia"]
        y["th"]=y.get("th") or "https://archive.org/services/img/"+y["ia"]
        y["k"]="iframe"
    # ترميز الحقول النصية
    y["t"]=re.sub(r"\s+"," ",y.get("t") or y.get("title") or y.get("i") or "بدون عنوان")[:120]
    y["t"]=y["t"].replace(","," ") if y["t"].count(",")>4 else y["t"]
    y["g"]=y.get("g") or y.get("tags") or y.get("keywords") or ""
    y["c"]=y.get("c") or y.get("cat") or y.get("category") or "عام"
    y["y"]=S(y.get("y") or y.get("year"))[:4]
    y["a"]=y.get("a") or "+12"
    y["s"]=y.get("s") or "archive.org"
    y["v"]=num(y.get("v") or y.get("views") or y.get("downloads"))
    y["th"]=y.get("th") or ""
    y["e"]=y.get("e") or ""
    y["mt"]=y.get("mt") or "movies"
    key=y.get("ia") or y.get("i")
    if not key or key in seen: drop+=1; continue
    seen.add(key)
    out.append({k:y.get(k,"") for k in ("i","ia","t","y","c","a","th","e","k","s","v","g","d","mt")})
out.sort(key=lambda x:-x["v"])
cat["items"]=out
json.dump(cat,open("catalog.json","w",encoding="utf-8"),ensure_ascii=False)
play=sum(1 for x in out if x.get("ia"))
print("  عناصر %d | قابلة للتشغيل %d | مستبعد %d"%(len(out),play,drop))
