#!/usr/bin/env bash
# يحقن الإعلانات المفعّلة في كل صفحات التطبيق — نفس منطق WIRE.sh لكن للشرائح
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
python3 - "$ROOT" "$HERE" <<'PY'
import os,sys,glob,json,re
root,here=sys.argv[1],sys.argv[2]
A=os.path.join(here,"data","ads.json")
try: ads=[x for x in json.load(open(A,encoding="utf-8")) if x.get("enabled") and x.get("snippet")]
except Exception: ads=[]
block="<!-- CINEHUB-ADS -->\n"+"\n".join("<!-- "+x["id"]+" -->\n"+x["snippet"] for x in ads)+"\n<!-- /CINEHUB-ADS -->"
pat=re.compile(r"<!-- CINEHUB-ADS -->.*?<!-- /CINEHUB-ADS -->",re.S)
n=0
for f in glob.glob(os.path.join(root,"**","*.html"),recursive=True):
    if "/_backup/" in f or "/node_modules/" in f: continue
    try: s=open(f,encoding="utf-8").read()
    except Exception: continue
    if "</body>" not in s and pat.search(s) is None: continue
    s2=pat.sub(block,s) if pat.search(s) else s.replace("</body>",block+"\n</body>",1)
    if s2!=s: open(f,"w",encoding="utf-8").write(s2); n+=1
print("  ✔ حُقنت %d شريحة في %d صفحة"%(len(ads),n) if ads else "  ⚠ لا شرائح مفعّلة — فعّل ads.json أولًا")
PY
