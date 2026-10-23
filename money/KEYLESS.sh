#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; DATA="$HERE/data"; mkdir -p "$DATA"
python3 - "$DATA" <<'PY'
import json,os,subprocess,sys,datetime
d=sys.argv[1]
KL=[("yts","YTS Movies","movie","https://movies-api.accel.li/api/v2/list_movies.json?limit=1","77,929 فيلم"),
("tvmaze","TVmaze","series","https://api.tvmaze.com/search/shows?q=breaking%20bad","مسلسلات"),
("eporner","Eporner","adult","https://www.eporner.com/api/v2/video/search/?query=test&per_page=1&format=json","بالغين"),
("coingecko","CoinGecko","crypto","https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd","أسعار"),
("erapi","ExchangeRate","fx","https://open.er-api.com/v6/latest/USD","عملات"),
("frankfurter","Frankfurter","fx","https://api.frankfurter.app/latest?from=USD","ECB"),
("jikan","Jikan MAL","series","https://api.jikan.moe/v4/anime/1","أنمي"),
("kitsu","Kitsu","series","https://kitsu.io/api/edge/anime?page%5Blimit%5D=1","أنمي"),
("wikipedia","Wikipedia","series","https://en.wikipedia.org/api/rest_v1/page/summary/Film","بيانات"),
("archive","Archive.org","movie","https://archive.org/advancedsearch.php?q=movie&rows=1&output=json","ملك عام"),
("defillama","DefiLlama","crypto","https://api.llama.fi/protocols","DeFi"),
("osm","OpenStreetMap","fx","https://nominatim.openstreetmap.org/search?q=cairo&format=json","خرائط")]
def probe(u):
    try:
        r=subprocess.run(["curl","-s","-o","/dev/null","-w","%{http_code}","--max-time","15","-A","cinehub-agent",u],capture_output=True,text=True,timeout=25)
        return r.stdout.strip() or "0"
    except Exception: return "0"
p=os.path.join(d,"keys-status.json")
st=json.load(open(p)) if os.path.exists(p) else {"keys":[],"summary":{}}
keys={k.get("id"):k for k in st.get("keys",[])}
now=datetime.datetime.now(datetime.timezone.utc).isoformat()
ok=0
for sid,name,cat,url,note in KL:
    c=probe(url)
    live = c=="200"
    if live: ok+=1
    keys[sid]={"id":sid,"name":name,"cat":cat,"status":"LIVE" if live else "DEAD",
      "revenue_source":cat in("adult","movie","series"),"note":note,"url":url,"keyless":True,"checked_at":now}
    print(("  ✔ " if live else "  ✗ ")+name+" → "+c)
st["keys"]=list(keys.values())
L=[k for k in st["keys"] if k["status"]=="LIVE"]
st["summary"]={"live":len(L),"dead":sum(1 for k in st["keys"] if k["status"]=="DEAD"),
 "missing":sum(1 for k in st["keys"] if k["status"]=="MISSING"),"set":sum(1 for k in st["keys"] if k["status"]=="SET")}
st["keys_checked_at"]=now
json.dump(st,open(p,"w"),ensure_ascii=False,indent=1)
print("  إجمالي حيّ الآن:",len(L))
PY
