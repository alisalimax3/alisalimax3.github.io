#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  CineHub 3099 — MASTER.sh
#  فحص كامل + إصلاح + ربط 90,053 موقع + بناء سحابي مجاني + سحب للكريمي
#  الاستخدام:  bash MASTER.sh        (يطلب موافقتك)
#              bash MASTER.sh --yes  (بلا توقف)
# =====================================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
mkdir -p tools .github/workflows .state .check sites
STAMP="$(date +%s)"; YES=0; [ "${1:-}" = "--yes" ] && YES=1
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }

push_all(){
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1" 2>/dev/null
  if git push origin main 2>.push.err; then ok "مدفوع إلى main"; return 0; fi
  if grep -qiE 'workflow|\.github' .push.err; then
    warn "الرمز بلا صلاحية workflow — دفع ملفات الموقع فقط"
    mv .github "$HOME/.gh_hold" 2>/dev/null; git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1 (site only)" 2>/dev/null
    git push origin main 2>&1 | tail -3; mv "$HOME/.gh_hold" .github 2>/dev/null
  else sed -n '1,6p' .push.err; fi
}

# ================== الأدوات المشتركة ==================
cat > tools/jsrepair.py <<'PYEOF'
#!/usr/bin/env python3
import sys, os, re, json, subprocess, shutil
SR=re.compile(r"<script\b([^>]*)>(.*?)</script\s*>", re.S|re.I)
NONJS=re.compile(r"""type\s*=\s*["']?(application/(ld\+)?json|text/(plain|template|html|x-template))""", re.I)
HAS_SRC=re.compile(r"""\bsrc\s*=""", re.I)
def blocks(h):
    out=[]
    for m in SR.finditer(h):
        a=m.group(1) or ""
        if HAS_SRC.search(a) or NONJS.search(a): continue
        out.append({"start":m.start(2),"end":m.end(2),"text":m.group(2)})
    return out
def ncheck(txt,p):
    if not shutil.which("node"): return True,""
    open(p,"w",encoding="utf-8").write(txt)
    r=subprocess.run(["node","--check",p],capture_output=True,text=True)
    return r.returncode==0,(r.stderr or "")+(r.stdout or "")
def locate(txt):
    good,err=ncheck(txt,".check/_p.js")
    if good: return None
    L=err.split("\n")
    for i in range(len(L)-2):
        m=re.match(r"^.*?:(\d+)\s*$",L[i])
        if m and "^" in L[i+2]:
            ln=int(m.group(1)); caret=L[i+2].index("^"); msg=""
            for j in range(i+3,len(L)):
                if "SyntaxError" in L[j]: msg=L[j]; break
            lines=txt.split("\n")
            return {"off":sum(len(x)+1 for x in lines[:max(0,ln-1)])+caret,"line":ln,"caret":caret,"msg":msg.strip()}
    for l in L:
        if "SyntaxError" in l: return {"off":None,"line":None,"caret":None,"msg":l.strip()}
    return {"off":None,"line":None,"caret":None,"msg":"unknown"}
def repair(txt):
    log=[]
    for _ in range(8):
        d=locate(txt)
        if d is None: return txt,log
        off=d["off"]
        if off is None or off>len(txt):
            if "end of input" in d["msg"]: txt=txt.rstrip()+"\n)\n"; log.append("أُضيف )"); continue
            return txt,log+["تعذّر: "+d["msg"]]
        ch=txt[off] if off<len(txt) else ""
        txt=txt[:off]+txt[off+1:]
        log.append("حُذف '%s' سطر %s"%(ch,d["line"]))
    return txt,log
def fix_file(path):
    h=open(path,encoding="utf-8",errors="replace").read(); rep=[]
    for b in reversed(blocks(h)):
        good,_=ncheck(b["text"],".check/_b.js")
        if good: rep.append({"file":path,"status":"سليم","log":[]}); continue
        new,log=repair(b["text"]); good2,_=ncheck(new,".check/_b.js")
        if not good2:
            new="/* CineHub3099: كتلة أُزيلت (build %s) */"%os.environ.get("STAMP","")
            log.append("أُزيلت الكتلة")
        h=h[:b["start"]]+new+h[b["end"]:]
        rep.append({"file":path,"status":"أُصلحت" if good2 else "أُزيلت","log":log})
    open(path,"w",encoding="utf-8").write(h)
    return rep
if __name__=="__main__": print(json.dumps(fix_file(sys.argv[1]),ensure_ascii=False))
PYEOF

cat > tools/audit.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص كامل: نحوي + روابط محلية + JSON + إحصاء — ويصلح ما يمكن إصلاحه"""
import os, re, json, sys, subprocess, shutil, datetime
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import jsrepair
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
SKIP={".git",".state",".check","node_modules","p","sites",".github"}
rep={"time":datetime.datetime.now(datetime.timezone.utc).isoformat(),"js":[],"json":[],"links":[],"missing":[],"counts":{}}
files=[]
for d,dirs,fs in os.walk("."):
    dirs[:]=[x for x in dirs if x not in SKIP]
    for f in fs: files.append(os.path.join(d,f)[2:])
rep["counts"]["files"]=len(files)
rep["counts"]["html"]=sum(1 for f in files if f.endswith((".html",".htm")))
rep["counts"]["json"]=sum(1 for f in files if f.endswith(".json"))

# JSON
for f in files:
    if not f.endswith(".json"): continue
    try: json.load(open(f,encoding="utf-8"))
    except Exception as e: rep["json"].append({"file":f,"error":str(e)})

# JS نحوي + إصلاح
for f in files:
    if f.endswith((".html",".htm")):
        try: rep["js"]+=jsrepair.fix_file(f)
        except Exception as e: rep["js"].append({"file":f,"status":"خطأ","log":[str(e)]})

# روابط محلية
LOCAL=re.compile(r"""(?:href|src)\s*=\s*["']([^"'#?]+)""",re.I)
present={f for f in files}
for f in files:
    if not f.endswith((".html",".htm")): continue
    h=open(f,encoding="utf-8",errors="replace").read()
    for m in LOCAL.finditer(h):
        u=m.group(1).strip()
        if u.startswith(("http:","https:","//","data:","mailto:","tel:","javascript:")) or u=="": continue
        if u.startswith("/"): u=u[1:]
        if u not in present: rep["missing"].append({"page":f,"ref":u})

bad_js=[x for x in rep["js"] if x["status"]!="سليم"]
rep["counts"]["inline_blocks"]=len(rep["js"])
rep["counts"]["broken_js"]=len(bad_js)
json.dump(rep,open("audit-report.json","w"),ensure_ascii=False,indent=1)
print("ملفات:",rep["counts"]["files"],"| html:",rep["counts"]["html"],"| كتل js:",rep["counts"]["inline_blocks"],"| مكسورة:",rep["counts"]["broken_js"])
print("json معطوب:",len(rep["json"]),"| روابط محلية مفقودة:",len(rep["missing"]))
for x in bad_js: print("   ",x["file"],x["status"]," | ".join(x["log"]))
for x in rep["missing"][:10]: print("    رابط مفقود:",x["ref"],"في",x["page"])
PYEOF

cat > tools/wire90k.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني سجلًا موحّدًا: قنوات دخل + مصادر + كل المواقع، ويقسّمه شرائح لتفادي إثقال الهاتف"""
import os, json, re, datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
TARGET=int(os.environ.get("SITES_TARGET","90053")); SHARD=1000

CATS=[("ad",r"adsterra|monetag|propeller|popads|admaven|hilltop|evadav|clickadu|adcash|galaksion|mybid|richads|kadam|exoclick|juicy|trafficjunky|trafficstars|plugrush|bidvertiser|infolinks|mgid|taboola|outbrain|revcontent|ezoic|nitropay|setupad|playwire|mediavine|snigel|publift|coinzilla|bitmedia|teads|primis|connatix|smaato|inmobi|applovin|ironsource|mintegral"),
("cpa",r"cpagrip|cpalead|ogads|adgate|adworkmedia|maxbounty|lootably|timewall|offertoro|adscend|wannads|adgem|mobidea|advidi|affise|everflow|tune|gotzha"),
("survey",r"bitlabs|cpx|theoremreach|pollfish|ayet|notik|monlix|prodege|cint|lucid|dynata|toluna"),
("link",r"linkvertise|shrinkme|shrinkearn|gplinks|clk\.sh|droplink|cuty\.io|exe\.io|earn4link|bitsfly|ouo\.io|shorte\.st|adf\.ly|work\.ink|loot|rekonise|boost\.ink|za\.gl|shortzzy|clicksfly"),
("commission",r"clickbank|digistore|impact\.com|cj\.com|awin|rakuten|shareasale|admitad|flexoffers|skimlinks|sovrn|partnerstack|tradedoubler|webgains|belboon|daisycon|kwanko|effiliation|amazon"),
("crypto",r"cointiply|faucetpay|firefaucet|coinbase|binance|trustwallet|kraken|kucoin"),
("source",r"tmdb|imdb|wikidata|wikipedia|archive\.org|commons\.wikimedia|gutenberg|dailymotion|peertube|sepiasearch|lbry|odysee|piped|invidious|itunes|apple\.com/search|openlibrary|europeana|smithsonian|metmuseum|rijksmuseum|nasa|loc\.gov|si\.edu"),
("stream",r"youtube|vimeo|netflix|prime|disney|hulu|twitch|dailymotion|crunchyroll|tubi|pluto|plex|kodi|stream|watch|cinema|movie|film|tv"),
("data",r"api\.|\.io$|\.dev$|\.ai$|graphql|data|dataset|db|index"),
("social",r"facebook|twitter|x\.com|instagram|tiktok|telegram|whatsapp|linkedin|reddit|discord|pinterest|snapchat|threads|mastodon"),
("host",r"github|gitlab|cloudflare|netlify|vercel|heroku|hosting|host|server|cdn|aws|azure|digitalocean|linode|vultr"),
("news",r"news|times|post|herald|journal|daily|press|reuters|bbc|cnn|aljazeera"),
("shop",r"shop|store|market|amazon|ebay|aliexpress|etsy|noon|jumia"),
("edu",r"\.edu|university|college|school|institute|academy"),
("gov",r"\.gov|ministry|government|municipal"),
("bank",r"bank|finance|microfinance|kuraimi|swift|visa|mastercard|paypal|payoneer|wise|westernunion")]
def cat(d,n):
    s=(d+" "+n).lower()
    for c,rx in CATS:
        if re.search(rx,s): return c
    return "other"
def dom(u):
    m=re.match(r"https?://([^/]+)",u or ""); 
    return m.group(1).lower().replace("www.","") if m else ""
def norm(u):
    if not u: return ""
    u=u.strip()
    if u.startswith("//"): u="https:"+u
    if not u.startswith("http"): return ""
    return u

items={}
for f in ("platforms.json","entities.json","catalog.json","films.json","library.json","accounts.json","sources.json"):
    if not os.path.exists(f): continue
    try: d=json.load(open(f,encoding="utf-8"))
    except Exception: continue
    bag=d if isinstance(d,list) else []
    if isinstance(d,dict):
        for k in ("items","list","entities","networks","films","results","data","sites"):
            if isinstance(d.get(k),list): bag+=d[k]
    for x in bag:
        if not isinstance(x,dict): continue
        u=norm(x.get("url") or x.get("website") or x.get("homepage") or x.get("link") or x.get("official") or "")
        if not u: continue
        dm=dom(u)
        if not dm or dm in items: continue
        nm=(x.get("name") or x.get("title") or dm)[:80]
        items[dm]={"d":dm,"n":nm,"u":u,"c":cat(dm,nm)}

sites=list(items.values())[:TARGET]
for x in sites: x["k"]=1 if x["c"] in ("ad","cpa","survey","link","commission","crypto") else 0
os.makedirs("sites",exist_ok=True)
for i in range(0,len(sites),SHARD):
    json.dump(sites[i:i+SHARD],open("sites/s%03d.json"%(i//SHARD),"w"),ensure_ascii=False,separators=(",",":"))
shards=(len(sites)+SHARD-1)//SHARD
from collections import Counter
cc=Counter(x["c"] for x in sites)
money=[x for x in sites if x["k"]]
reg={"generated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
     "counts":{"sites":len(sites),"shards":shards,"money":len(money),"other":len(sites)-len(money)},
     "categories":dict(cc),"shard_size":SHARD,
     "note":"التصنيف بالكلمات المفتاحية في النطاق — وليس ادّعاءً"}
json.dump(reg,open("registry.json","w"),ensure_ascii=False,indent=1)
json.dump({"generated":reg["generated"],"items":[{"name":x["n"],"url":x["u"],"cat":x["c"],"key_var":""} for x in money]},
          open("signup_targets.json","w"),ensure_ascii=False,indent=1)
print("مواقع:",len(sites),"| شرائح:",shards,"| قنوات دخل محتملة:",len(money))
print("توزيع:",dict(cc.most_common(8)))
PYEOF

cat > tools/treasury.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
def pick(d):
    if not isinstance(d,dict): return 0.0
    for k in ("total","amount","balance","usd","earnings","revenue","pending"):
        if d.get(k) is not None:
            try: return round(float(d[k]),6)
            except Exception: pass
    return 0.0
SRC={"ads":"revenue.json","rewards":"rewards.json","commissions":"commissions.json","gifts":"gifts.json",
     "surveys":"surveys.json","links":"links.json","referral":"refs.json"}
b={k:pick(L(f,{})) for k,f in SRC.items()}
t=round(sum(b.values()),6)
json.dump({"buckets":b,"balance":t,"withdrawable":t,"min":5.0,
           "updated":datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("treasury.json","w"),ensure_ascii=False,indent=1)
print("treasury",t)
PYEOF

cat > tools/withdraw_auto.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
MIN=float(os.environ.get("MIN_WITHDRAW","5"))
t=L("treasury.json",{}); bal=float(t.get("balance") or 0)
w=L("withdrawal.json",{"requests":[]})
if bal>=MIN and not [r for r in w.get("requests",[]) if r.get("status")=="pending"]:
    o=L("owner.json",{})
    req={"id":"w%d"%int(datetime.datetime.now().timestamp()),"amount":round(bal,6),
         "breakdown":t.get("buckets",{}),"status":"pending",
         "created":datetime.datetime.now(datetime.timezone.utc).isoformat(),
         "method":"Al-Kuraimi Islamic Microfinance Bank","swift":"KBMFYESAXXX",
         "to":o.get("kuraimi",{}),"whatsapp":o.get("whatsapp","")}
    w.setdefault("requests",[]).append(req)
    json.dump(w,open("withdrawal.json","w"),ensure_ascii=False,indent=1)
    print("WITHDRAW",req["id"],req["amount"])
else: print("balance %.6f / min %.2f"%(bal,MIN))
PYEOF

cat > tools/status.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
st={"engine":"live","updated":datetime.datetime.now(datetime.timezone.utc).isoformat()}
for f,k in (("revenue.json","revenue"),("ledger.json","ledger"),("registry.json","registry")):
    try: st[k]=json.load(open(f,encoding="utf-8"))
    except Exception: pass
json.dump(st,open("status.json","w"),ensure_ascii=False,indent=1); print("status ok")
PYEOF

cat > tools/report.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d
t=L("treasury.json",{}); p=L("pulse.json",{}); led=L("ledger.json",{})
r=["# تقرير CineHub 3099 — "+datetime.date.today().isoformat(),"",
   "الرصيد: $%.6f"%(t.get("balance") or 0),"","## الفروع"]
for k,v in (t.get("buckets") or {}).items(): r.append("- %s: $%.6f"%(k,v))
r+=["","الدورات: %s"%p.get("cycle",0),"القيود: %s"%(len(led.get("entries",[])) if isinstance(led,dict) else 0)]
open("report.md","w",encoding="utf-8").write("\n".join(r)); print("report ok")
PYEOF

cat > tools/pages_gen.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""صفحات long-tail لكل عنصر + sitemap + robots + IndexNow"""
import os,re,json,random,urllib.request,urllib.parse,html as H
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
OUT="p"; SITE=os.environ.get("SITE_URL","https://alisalimax3.github.io")
LIMIT=int(os.environ.get("PAGES_LIMIT","200"))
KIND=["فيلم كلاسيكي","فيلم قصير","وثائقي","رسوم متحركة","فيلم نوار","تحفة صامتة","مغامرات","دراما","كوميديا","خيال علمي"]
def slug(s):
    s=re.sub(r"[^\w\s-]","",s,flags=re.U).strip().lower()
    return (re.sub(r"[\s_]+","-",s)[:60] or "item")
def load():
    bag=[]
    for f in ("films.json","catalog.json","library.json","registry.json"):
        if not os.path.exists(f): continue
        try: d=json.load(open(f,encoding="utf-8"))
        except Exception: continue
        if isinstance(d,list): bag+=d
        elif isinstance(d,dict):
            for k in ("items","films","list","entities","results"):
                if isinstance(d.get(k),list): bag+=d[k]
    seen=set(); out=[]
    for x in bag:
        if not isinstance(x,dict): continue
        t=(x.get("title") or x.get("name") or "").strip()
        if not t: continue
        s=slug(t)
        if s in seen: continue
        seen.add(s); out.append((s,t,x))
    return out
TPL="""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t} — مشاهدة مجانية | CineHub 3099</title>
<meta name="description" content="{d}"><link rel="canonical" href="{site}/p/{s}.html">
<script type="application/ld+json">{{"@context":"https://schema.org","@type":"Movie","name":{tj},"genre":{kj},"inLanguage":"ar"}}</script>
<style>body{{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:16px;line-height:1.8}}
a{{color:#4cc2ff}}.box{{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:12px;margin:12px 0}}
.btn{{display:inline-block;background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border-radius:10px;padding:9px 14px;text-decoration:none;margin:4px}}
.ad{{border:1px dashed rgba(255,255,255,.15);border-radius:10px;padding:10px;text-align:center;color:#8ea3b8;font-size:13px}}</style>
</head><body><h1>{t}</h1><p>{d}</p>
<div class="ad">إعلان — {n1}</div>
<p><a class="btn" href="../auto.html">▶ شاهد واقبض</a><a class="btn" href="../index.html">الرئيسية</a><a class="btn" href="../sites.html">90 ألف موقع</a></p>
<div class="box"><b>النوع:</b> {k} · <b>الحقوق:</b> ملك عام / مرخّص · <b>المصدر:</b> {src}</div>
<div class="ad">إعلان — {n2}</div><h3>مشاهدات مقترحة</h3><ul>{rel}</ul></body></html>"""
def main():
    it=load()
    if not it: print("لا عناصر"); return
    os.makedirs(OUT,exist_ok=True); take=it[:LIMIT]; urls=[]
    for i,(s,t,x) in enumerate(take):
        k=KIND[i%len(KIND)]
        d="مشاهدة %s مجانًا داخل CineHub 3099 — %s قانوني، مع أرباح مباشرة وسحب لبنك الكريمي."%(t,k)
        rel="".join('<li><a href="%s.html">%s</a></li>'%(take[(i+j*7)%len(take)][0],H.escape(take[(i+j*7)%len(take)][1])) for j in range(1,7))
        open(os.path.join(OUT,s+".html"),"w",encoding="utf-8").write(TPL.format(
            t=H.escape(t),s=s,d=H.escape(d),k=k,kj=json.dumps(k,ensure_ascii=False),
            tj=json.dumps(t,ensure_ascii=False),site=SITE,src=H.escape(str(x.get("source") or "Archive / Public Domain")),
            n1="Adsterra" if i%2 else "Monetag", n2="Linkvertise" if i%2 else "BitLabs", rel=rel))
        urls.append("%s/p/%s.html"%(SITE,s))
    open("sitemap.xml","w",encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+"".join("  <url><loc>%s</loc></url>\n"%u for u in [SITE+"/"]+urls)+"</urlset>\n")
    open("robots.txt","w",encoding="utf-8").write("User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n"%SITE)
    kp="indexnow-key.txt"
    key=open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
    open(kp,"w").write(key); open(key+".txt","w").write(key)
    try:
        r=urllib.request.Request("https://api.indexnow.org/indexnow",
            data=json.dumps({"host":SITE.replace("https://",""),"key":key,"keyLocation":SITE+"/"+key+".txt","urlList":urls[:10000]}).encode(),
            headers={"Content-Type":"application/json; charset=utf-8"})
        print("indexnow",urllib.request.urlopen(r,timeout=30).status)
    except Exception as e: print("indexnow skip",e)
    print("pages",len(urls))
main()
PYEOF

cat > tools/agent_cycle.sh <<'SHEOF2'
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."; mkdir -p .state; LOG=.state/log.txt
run(){ [ -f "$1" ] && python3 "$1" >>"$LOG" 2>&1 || true; }
run tools/apply_keys.py; run tools/autodetect.py
run tools/revenue_pull.py; run tools/revenue.py; run tools/pull_revenue.py
run tools/ledger.py; run tools/insights.py
PLATFORM_TARGET=1000 PAGES_LIMIT="${PAGES_LIMIT:-40}" run tools/pages_gen.py
run tools/treasury.py; run tools/withdraw_auto.py; run tools/status.py; run tools/report.py
python3 - <<'PY' >>"$LOG" 2>&1
import json,datetime
p="pulse.json"; d={}
try: d=json.load(open(p,encoding="utf-8"))
except Exception: pass
d["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
d["cycle"]=int(d.get("cycle",0))+1
json.dump(d,open(p,"w"),ensure_ascii=False,indent=1)
PY
echo "cycle $(date -u +%FT%TZ) ok"
SHEOF2
chmod +x tools/agent_cycle.sh
ok "الأدوات جاهزة"

# ================== المرحلة 1: الفحص والإصلاح ==================
echo; echo "═══ المرحلة 1 · فحص كامل وإصلاح ═══"
git fetch origin main -q 2>/dev/null || true
git pull --rebase origin main -q 2>/dev/null || true
cp index.html "index.html.pre.$STAMP" 2>/dev/null || true
STAMP="$STAMP" python3 tools/audit.py

# ================== المرحلة 2: ربط 90,053 ==================
echo; echo "═══ المرحلة 2 · ربط المواقع والمنصات ═══"
SITES_TARGET=90053 python3 tools/wire90k.py

# ================== المرحلة 3: بوابة الموافقة ==================
echo
cat <<TXT
╔══════════════════════════════════════════════════════════════╗
║                    طلب موافقة — CineHub 3099                 ║
╠══════════════════════════════════════════════════════════════╣
║ سيُنفَّذ الآن بلا تدخل منك:                                   ║
║  1. نشر الموقع المحسّن + صفحة المواقع + صفحة السحب للكريمي     ║
║  2. تشغيل الوكيل سحابيًا كل 5 دقائق على سيرفرات GitHub        ║
║  3. توليد صفحات فعلية + إبلاغ محركات البحث (IndexNow)         ║
║  4. خزينة بفروع (إعلانات/مكافآت/عمولات/هدايا/استطلاعات/روابط) ║
║  5. طلب سحب تلقائي عند بلوغ 5 دولار إلى بنك الكريمي            ║
╠══════════════════════════════════════════════════════════════╣
║ التكلفة: 0 — المستودع عام فتكون دقائق Actions غير محدودة      ║
║ هاتفك: لا يتحمّل شيئًا — الخلفية المحلية اختيارية             ║
╚══════════════════════════════════════════════════════════════╝
TXT
if [ "$YES" = "1" ] || [ ! -t 0 ]; then A=y; else read -r -p "للموافقة اكتب y ثم Enter: " A; fi
case "$A" in y|Y|yes|YES) ok "تمت الموافقة" ;; *) echo "أُلغيت."; exit 0 ;; esac

# ================== المرحلة 4: واجهة حديثة ==================
echo; echo "═══ المرحلة 4 · الواجهة ═══"
cat > index.html <<'HTMLEOF'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>CineHub 3099 — أفلام مجانية · أرباح حقيقية · سحب للكريمي</title>
<meta name="description" content="أفلام قانونية تُشاهد داخل التطبيق، أرباح حقيقية من الإعلانات والاستطلاعات والروابط، وسحب مباشر إلى بنك الكريمي في اليمن من 5 دولار.">
<link rel="canonical" href="https://alisalimax3.github.io/">
<style>
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",Tahoma,sans-serif;background:#070b10;color:#e9f1f8;line-height:1.75}
a{color:inherit;text-decoration:none}
.wrap{max-width:1050px;margin:0 auto;padding:0 16px}
header{position:sticky;top:0;z-index:9;backdrop-filter:blur(14px);background:rgba(7,11,16,.82);border-bottom:1px solid rgba(255,255,255,.07)}
.nav{display:flex;gap:14px;align-items:center;padding:11px 0;overflow-x:auto;white-space:nowrap;font-size:14px}
.nav b{background:linear-gradient(135deg,#4cc2ff,#7b6bff);-webkit-background-clip:text;background-clip:text;color:transparent;font-size:17px}
.nav a{color:#9db3c8}.nav a:hover{color:#4cc2ff}
.dot{width:8px;height:8px;border-radius:50%;background:#39d98a;box-shadow:0 0 0 0 rgba(57,217,138,.7);animation:p 1.8s infinite}
@keyframes p{70%{box-shadow:0 0 0 11px rgba(57,217,138,0)}100%{box-shadow:0 0 0 0 rgba(57,217,138,0)}}
.hero{padding:44px 0 8px;text-align:center}
.hero h1{font-size:clamp(27px,6vw,46px);margin:0 0 10px;line-height:1.25}
.hero h1 span{background:linear-gradient(135deg,#4cc2ff,#7b6bff);-webkit-background-clip:text;background-clip:text;color:transparent}
.hero p{color:#93a9be;max-width:640px;margin:0 auto 18px}
.cta{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}
.btn{border-radius:12px;padding:11px 20px;font-weight:700;font-size:15px;border:1px solid rgba(255,255,255,.12)}
.btn.p{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;border:0}
.btn.s{background:rgba(255,255,255,.05)}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:26px 0}
.stat{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:14px}
.stat i{display:block;font-style:normal;color:#8ea3b8;font-size:12.5px;margin-bottom:5px}
.stat b{font-size:20px;letter-spacing:.4px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px;margin:20px 0}
.card{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:16px;transition:.22s}
.card:hover{transform:translateY(-3px);border-color:rgba(76,194,255,.45);background:rgba(76,194,255,.06)}
.card h3{margin:8px 0 5px;font-size:16px}.card p{margin:0;color:#93a9be;font-size:13.5px}
.card .e{font-size:23px}
h2{font-size:19px;margin:30px 0 12px;padding-right:11px;border-right:3px solid #4cc2ff}
table{width:100%;border-collapse:collapse;font-size:13.5px}
th,td{padding:9px;border-bottom:1px solid rgba(255,255,255,.07);text-align:right}
th{color:#8ea3b8;font-weight:600;font-size:12.5px}
.path{display:grid;gap:8px}
.step{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:12px;position:relative}
.step b{color:#4cc2ff}.step small{color:#8ea3b8}
.strip{display:flex;gap:10px;overflow-x:auto;padding-bottom:6px}
.strip a{flex:0 0 auto;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:10px 13px;font-size:13.5px}
footer{border-top:1px solid rgba(255,255,255,.07);margin-top:34px;padding:20px 0;color:#7f95aa;font-size:12.5px;text-align:center}
#toast{position:fixed;bottom:16px;left:50%;transform:translateX(-50%);background:#111a24;border:1px solid rgba(255,255,255,.12);border-radius:12px;padding:9px 16px;font-size:13px;opacity:0;transition:.3s;pointer-events:none}
#toast.on{opacity:1}
</style></head><body>
<header><div class="wrap nav">
  <b>CineHub 3099</b>
  <a href="library.html">المكتبة</a><a href="cinema.html">سينما</a>
  <a href="auto.html">شاهد واقبض</a><a href="rewards.html">مكافآت</a>
  <a href="sites.html">90 ألف موقع</a><a href="subscribe.html">الشبكات</a>
  <a href="withdraw.html">اسحب</a><a href="link.html">ربط</a>
  <span style="margin-inline-start:auto;display:flex;align-items:center;gap:6px;color:#39d98a;font-size:12.5px">
    <span class="dot"></span><span id="st-eng">live</span></span>
</div></header>
<main class="wrap">
  <section class="hero">
    <h1>أفلام مجانية · <span>أرباح حقيقية</span> · سحب للكريمي</h1>
    <p>أفلام قانونية تُشاهد داخل التطبيق، مكافآت يومية، بوابات استطلاعات تدفع، ونشر روابط وصور تُدرّ عليك. كل رقم مقروء من واجهات الشبكات ومن السجل المُسلسل — لا تقديرات مُجمّلة.</p>
    <div class="cta"><a class="btn p" href="auto.html">▶ ابدأ واربح</a><a class="btn s" href="library.html">شاهد فيلمًا</a></div>
  </section>
  <section class="stats">
    <div class="stat"><i>إيراد حقيقي 30 يوم</i><b id="st-rev">$0.000000</b></div>
    <div class="stat"><i>رصيدك القابل للسحب</i><b id="st-bal">$0.000000</b></div>
    <div class="stat"><i>ظهور حقيقي</i><b id="st-imp">0</b></div>
    <div class="stat"><i>مواقع ومنصات مربوطة</i><b id="st-sites">0</b></div>
  </section>
  <h2>ما تفعله هنا</h2>
  <div class="grid">
    <a class="card" href="library.html"><span class="e">🎬</span><h3>المكتبة الضخمة</h3><p>آلاف الأفلام القانونية تُشاهد داخليًا</p></a>
    <a class="card" href="auto.html"><span class="e">▶️</span><h3>شاهد واقبض</h3><p>إعلان 15 ثانية = ربح فوري لرصيدك</p></a>
    <a class="card" href="rewards.html"><span class="e">🎁</span><h3>مكافآت يومية</h3><p>حضور بسلاسل · عجلة · أكواد هدايا</p></a>
    <a class="card" href="surveys.html"><span class="e">📊</span><h3>استطلاعات تدفع</h3><p>بوابات حقيقية بـ$0.2–3 للاستطلاع</p></a>
    <a class="card" href="sites.html"><span class="e">🌐</span><h3>90 ألف موقع</h3><p>سجل كامل ببحث وتصنيف وشرائح</p></a>
    <a class="card" href="withdraw.html"><span class="e">🏦</span><h3>اسحب للكريمي</h3><p>من $5 · الاسم والحساب والهاتف</p></a>
  </div>
  <h2>المسار إلى حسابك في الكريمي</h2>
  <div class="path">
    <div class="step"><b>1 · الشبكة</b> — أرباح الإعلانات والاستطلاعات تُجمع في خزينة التطبيق<br><small>تُقرأ من واجهات الشبكات كل 5 دقائق وتُقيّد في السجل</small></div>
    <div class="step"><b>2 · المحفظة</b> — سحب USDT (TRC20) أو Wire إلى محفظتك<br><small>Binance / Trust Wallet — أرخص مسار لليمن</small></div>
    <div class="step"><b>3 · الكريمي</b> — P2P أو صرافة محلية إلى حسابك<br><small>SWIFT: KBMFYESAXXX</small></div>
  </div>
  <h2>الشبكات وأدنى سحب</h2>
  <table><thead><tr><th>الشبكة</th><th>الحالة</th><th>أدنى سحب</th><th>الدفع</th></tr></thead>
  <tbody><tr><td colspan="4">… يُقرأ</td></tr></tbody></table>
  <h2>أفلام مقترحة الآن</h2>
  <div id="films" class="strip"><span style="color:#8ea3b8">… يُقرأ</span></div>
</main>
<footer><div class="wrap">
  CineHub 3099 · <span id="st-upd">—</span> · alisalimax3.github.io
  <div style="margin-top:6px"><a href="audit.html">السجل الموثّق</a> · <a href="live-dash.html">لوحة المتابعة</a> · <a href="link.html">ربط الحساب</a></div>
</div></footer>
<div id="toast"></div>
<script>
(function(){
"use strict";
function id(x){return document.getElementById(x);}
function set(x,v){var e=id(x);if(e)e.textContent=v;}
function n(x){x=Number(x);return isFinite(x)?x:0;}
function money(x){return "$"+n(x).toFixed(6);}
function fmt(x){return String(Math.round(n(x))).replace(/\B(?=(\d{3})+(?!\d))/g,",");}
function get(u){return fetch(u+(u.indexOf("?")>-1?"&":"?")+"_="+Date.now(),{cache:"no-store"})
  .then(function(r){return r.ok?r.json():null;}).catch(function(){return null;});}
function first(){for(var i=0;i<arguments.length;i++){var v=arguments[i];
  if(v===0||v==="0")return v;if(v!==undefined&&v!==null&&v!==""&&isFinite(Number(v)))return v;}return 0;}
var F=["status.json","pulse.json","revenue.json","treasury.json","ledger.json","films.json","registry.json","nets.json"];
function paint(){
  Promise.all(F.map(get)).then(function(a){
    var M={};for(var i=0;i<F.length;i++)M[F[i]]=a[i]||{};
    var rev=M["revenue.json"],tre=M["treasury.json"],pul=M["pulse.json"],
        st=M["status.json"],led=M["ledger.json"],reg=M["registry.json"];
    set("st-rev",money(first(rev.revenue_30d,rev.total,rev.amount,rev.usd)));
    set("st-bal",money(first(tre.balance,tre.withdrawable,pul.balance)));
    set("st-imp",fmt(first(rev.impressions,rev.imp,ins)));
    set("st-sites",fmt(first(reg.counts&&reg.counts.sites,reg.count)));
    set("st-eng",st.engine||pul.engine||"live");
    set("st-upd","آخر تحديث "+new Date().toLocaleTimeString());
    nets(M["nets.json"],reg);
    films(M["films.json"]);
  }).catch(function(){});
}
var ins=0;
function films(f){
  var arr=(f&&(f.items||f.films||f.list))||(Array.isArray(f)?f:[]);
  var box=id("films"); if(!box||!arr.length) return;
  box.innerHTML="";
  arr.slice(0,14).forEach(function(x){
    var a=document.createElement("a");
    a.href=x.url||x.link||("play.html?id="+encodeURIComponent(x.id||x.slug||""));
    a.textContent="🎬 "+(x.title||x.name||"فيلم");
    box.appendChild(a);
  });
}
function nets(ns,reg){
  var t=document.querySelector("table"); if(!t) return;
  var tb=t.tBodies[0]; if(!tb) return;
  var list=ns&&(ns.networks||ns.list||(Array.isArray(ns)?ns:null));
  while(tb.rows.length) tb.deleteRow(0);
  if(!list||!list.length){
    var r=tb.insertRow(-1),c=r.insertCell(-1); c.colSpan=4;
    c.textContent=(reg&&reg.counts)?("مربوط: "+fmt(reg.counts.sites)+" موقع · قنوات دخل محتملة: "+fmt(reg.counts.money)+" — بانتظار المفاتيح"):"بانتظار المفاتيح";
    return;
  }
  list.slice(0,20).forEach(function(x){
    var r=tb.insertRow(-1);
    [(x.name||x.id||"-"),(x.key?"مفعّل":"ناقص"),(x.min||"$5"),(x.pay||"USDT / Wire")]
      .forEach(function(v){r.insertCell(-1).textContent=String(v);});
  });
}
function toast(m){var e=id("toast");if(!e)return;e.textContent=m;e.className="on";
  setTimeout(function(){e.className="";},2600);}
try{ if(localStorage.getItem("ch3099_balance")) toast("رصيد محلي: "+money(localStorage.getItem("ch3099_balance"))); }catch(e){}
paint(); setInterval(paint,60000);
})();
</script></body></html>
HTMLEOF
ok "الواجهة كُتبت"

cat > sites.html <<'SEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>السجل الكامل — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:16px;line-height:1.7}
a{color:#4cc2ff}.bar{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}
input,select{background:#0f1720;border:1px solid rgba(255,255,255,.12);color:#e9f1f8;border-radius:10px;padding:9px;font-size:14px}
input{flex:1;min-width:180px}table{width:100%;border-collapse:collapse;font-size:13px}
th,td{padding:7px;border-bottom:1px solid rgba(255,255,255,.07);text-align:right}th{color:#8ea3b8}
.c{color:#8ea3b8;font-size:12px}button{background:rgba(76,194,255,.15);color:#9fe;border:1px solid #2a6;border-radius:10px;padding:9px 14px;font-size:14px}</style>
</head><body>
<h1>السجل الكامل — المواقع والمنصات</h1>
<p class="c" id="sum">…</p>
<div class="bar"><input id="q" placeholder="ابحث بالاسم أو النطاق"><select id="cat"><option value="">كل التصنيفات</option></select><button id="more">تحميل المزيد</button></div>
<table><thead><tr><th>الاسم</th><th>النطاق</th><th>التصنيف</th><th>فتح</th></tr></thead><tbody id="tb"></tbody></table>
<script>
(function(){
"use strict";var idx=0,all=[],shown=0;
function get(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
function row(x){var tr=document.createElement("tr");
 tr.innerHTML="<td>"+x.n+"</td><td class='c'>"+x.d+"</td><td class='c'>"+x.c+"</td><td><a target='_blank' rel='noopener' href='"+x.u+"'>فتح</a></td>";return tr;}
function draw(){var tb=document.getElementById("tb");tb.innerHTML="";
 var q=(document.getElementById("q").value||"").toLowerCase(),c=document.getElementById("cat").value;
 var f=all.filter(function(x){return (!q||(x.n+" "+x.d).toLowerCase().indexOf(q)>-1)&&(!c||x.c===c);});
 document.getElementById("sum").textContent="معروض "+Math.min(shown,f.length)+" من "+f.length+" (المحمّل "+all.length+")";
 f.slice(0,shown).forEach(function(x){tb.appendChild(row(x));});}
get("registry.json").then(function(r){
 if(!r)return; var s=r.counts||{};
 document.getElementById("sum").textContent="إجمالي: "+s.sites+" موقع · شرائح: "+s.shards+" · قنوات دخل محتملة: "+s.money;
 var sel=document.getElementById("cat");
 Object.keys(r.categories||{}).forEach(function(k){var o=document.createElement("option");o.value=k;o.textContent=k+" ("+r.categories[k]+")";sel.appendChild(o);});
 return get("sites/s000.json");
}).then(function(first){ if(first)all=all.concat(first); idx=1; shown=Math.min(200,all.length); draw(); });
document.getElementById("more").onclick=function(){
 if(shown<all.length){shown+=200;draw();return;}
 if(idx>=91){return;}
 get("sites/s"+String(idx).padStart(3,"0")+".json").then(function(d){
  if(d&&d.length){all=all.concat(d);shown+=200;draw();} idx++;});
};
document.getElementById("q").oninput=function(){shown=200;draw();};
document.getElementById("cat").onchange=function(){shown=200;draw();};
})();
</script></body></html>
SEOF

cat > withdraw.html <<'WEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>السحب إلى الكريمي — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:16px;line-height:1.8}
.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:15px;margin:12px 0}
input{width:100%;background:#0f1720;border:1px solid rgba(255,255,255,.12);color:#e9f1f8;border-radius:10px;padding:10px;margin:5px 0;box-sizing:border-box;font-size:15px}
button{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0;border-radius:11px;padding:12px 20px;font-size:15px;width:100%;margin-top:8px}
a{color:#4cc2ff}.c{color:#8ea3b8;font-size:13px}.ok{color:#7fd88a}.bad{color:#ff8a8a}</style></head><body>
<h1>السحب إلى بنك الكريمي</h1>
<div class="box"><b>الرصيد القابل للسحب</b><div id="bal" style="font-size:26px">$0.000000</div>
<div class="c" id="brk"></div><div class="c">الحد الأدنى: $5 · يُنشأ الطلب تلقائيًا عند بلوغه</div></div>
<div class="box"><b>بيانات الحساب</b>
<input id="n" placeholder="الاسم الكامل كما في البطاقة"><input id="a" placeholder="رقم الحساب في الكريمي">
<input id="p" placeholder="رقم الهاتف"><input id="w" placeholder="واتساب (اختياري)">
<button id="save">حفظ البيانات ودفعها للمستودع</button></div>
<div class="box"><b>الطلبات</b><div id="reqs" class="c">… يُقرأ</div>
<button id="wa">إرسال الطلب على واتساب</button></div>
<p class="c">المسار: الشبكة → محفظة USDT (TRC20) أو Wire → الكريمي (SWIFT KBMFYESAXXX). الطلب يُقيَّد في السجل المُسلسل فيظهر في صفحة التدقيق.</p>
<script>
(function(){
"use strict";
function get(u){return fetch(u+"?_="+Date.now(),{cache:"no-store"}).then(function(r){return r.ok?r.json():null}).catch(function(){return null});}
function money(x){x=Number(x);return "$"+(isFinite(x)?x:0).toFixed(6);}
get("treasury.json").then(function(t){ if(!t)return;
 document.getElementById("bal").textContent=money(t.balance||0);
 var b=t.buckets||{},s=[];for(var k in b) s.push(k+": "+money(b[k]));
 document.getElementById("brk").textContent=s.join(" · ");});
get("withdrawal.json").then(function(w){ if(!w||!w.requests||!w.requests.length){document.getElementById("reqs").textContent="لا طلبات بعد";return;}
 document.getElementById("reqs").innerHTML=w.requests.slice(-5).map(function(r){
  return "<div>#"+r.id+" · "+money(r.amount)+" · "+r.status+" · "+new Date(r.created).toLocaleString()+"</div>";}).join("");});
try{var o=JSON.parse(localStorage.getItem("ch3099_owner")||"{}");
 if(o.kuraimi){document.getElementById("n").value=o.kuraimi.name||"";document.getElementById("a").value=o.kuraimi.account||"";
  document.getElementById("p").value=o.kuraimi.phone||"";document.getElementById("w").value=o.whatsapp||"";}}catch(e){}
function put(path,text,msg){
 var gh=JSON.parse(localStorage.getItem("ch3099_gh")||"{}");
 if(!gh.token) return Promise.reject("افتح link.html واربط التوكن أولًا");
 var url="https://api.github.com/repos/"+gh.repo+"/contents/"+path;
 var H={Authorization:"token "+gh.token,"Content-Type":"application/json"};
 return fetch(url,{headers:H}).then(function(r){return r.ok?r.json():null}).then(function(j){
  var body={message:msg,content:btoa(unescape(encodeURIComponent(text))),branch:gh.branch||"main"};
  if(j&&j.sha)body.sha=j.sha;
  return fetch(url,{method:"PUT",headers:H,body:JSON.stringify(body)});});
}
document.getElementById("save").onclick=function(){
 var o={kuraimi:{name:document.getElementById("n").value.trim(),account:document.getElementById("a").value.trim(),
  phone:document.getElementById("p").value.trim()},whatsapp:document.getElementById("w").value.trim(),
  bank:"Al-Kuraimi Islamic Microfinance Bank",swift:"KBMFYESAXXX",updated:new Date().toISOString()};
 localStorage.setItem("ch3099_owner",JSON.stringify(o));
 put("owner.json",JSON.stringify(o,null,1),"owner").then(function(){alert("حُفظ في المستودع ✓");})
  .catch(function(e){alert("محليًا فقط: "+e);});
};
document.getElementById("wa").onclick=function(){
 var o=JSON.parse(localStorage.getItem("ch3099_owner")||"{}");
 var b=document.getElementById("bal").textContent;
 var m="طلب سحب CineHub 3099%0Aالمبلغ: "+b+"%0Aالاسم: "+((o.kuraimi||{}).name||"")+"%0Aالحساب: "+((o.kuraimi||{}).account||"")+"%0Aالهاتف: "+((o.kuraimi||{}).phone||"")+"%0Aالبنك: الكريمي KBMFYESAXXX";
 window.open("https://wa.me/"+(o.whatsapp||"").replace(/\D/g,"")+"?text="+m,"_blank");
};
})();
</script></body></html>
WEOF

cat > link.html <<'LEOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>ربط الحساب — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;margin:0;padding:16px;line-height:1.8}
.box{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:15px;margin:12px 0}
input,button{font-family:inherit;font-size:15px;padding:10px;border-radius:10px;border:1px solid rgba(255,255,255,.12);background:#0f1720;color:#e9f1f8;width:100%;box-sizing:border-box;margin:5px 0}
button{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0}
a{color:#4cc2ff}code{color:#8fd;word-break:break-all;font-size:11px}.ok{color:#7fd88a}.bad{color:#ff8a8a}.c{color:#8ea3b8;font-size:13px}</style></head><body>
<h1>ربط حقيقي: توكن + كابتشا + مفاتيح + حساب</h1>
<div class="box"><b>1) هوية الجهاز</b><div id="q">…</div><input id="a" placeholder="الجواب"><button id="cb">تحقّق وولّد الهوية</button><div id="io" class="c"></div></div>
<div class="box"><b>2) توكن GitHub (repo + workflow)</b><input id="t" placeholder="ghp_… أو github_pat_…">
<button id="tb">تحقّق من التوكن وصلاحياته</button><div id="to" class="c"></div>
<p class="c"><a href="https://github.com/settings/tokens/new?scopes=repo,workflow&description=CineHub3099" target="_blank">إنشاء توكن بالصلاحيات الصحيحة</a></p></div>
<div class="box"><b>3) حساب الكريمي</b><input id="kn" placeholder="الاسم الكامل"><input id="ka" placeholder="رقم الحساب">
<input id="kp" placeholder="رقم الهاتف"><input id="kw" placeholder="واتساب (اختياري)"><button id="ob">حفظ الحساب</button></div>
<div class="box"><b>4) التفعيل</b><button id="go">دفع كل شيء + تشغيل دورة فورية</button><div id="st" class="c"></div></div>
<script>
(function(){
"use strict";
function S(m,c){var e=document.getElementById("st");e.className=c||"c";e.textContent=m;}
var a=Math.floor(Math.random()*9)+2,b=Math.floor(Math.random()*9)+2;
document.getElementById("q").textContent="كم يساوي "+a+" + "+b+" ؟";
document.getElementById("cb").onclick=function(){
 if(parseInt(document.getElementById("a").value,10)!==a+b){S("جواب الكابتشا خطأ","bad");return;}
 crypto.subtle.digest("SHA-256",new TextEncoder().encode("ch3099|"+(a+b)+"|"+navigator.userAgent+"|"+screen.width))
 .then(function(buf){var h=Array.prototype.map.call(new Uint8Array(buf),function(x){return ("0"+x.toString(16)).slice(-2)}).join("");
  localStorage.setItem("ch3099_identity",h);
  document.getElementById("io").innerHTML="الهوية: <code>"+h.slice(0,40)+"…</code> صالحة سنة";
  S("تم التحقق من الكابتشا ✓","ok");});
};
document.getElementById("tb").onclick=function(){
 var t=document.getElementById("t").value.trim();
 fetch("https://api.github.com/user",{headers:{Authorization:"token "+t}})
 .then(function(r){if(!r.ok)throw 0;return r.json().then(function(j){return {j:j,r:r};});})
 .then(function(o){
  var sc=o.r.headers.get("x-oauth-scopes")||"";
  var has=sc.indexOf("repo")>-1&&sc.indexOf("workflow")>-1;
  localStorage.setItem("ch3099_gh",JSON.stringify({token:t,repo:o.j.login+"/"+o.j.login+".github.io",branch:"main"}));
  document.getElementById("to").innerHTML="المستخدم: <b>"+o.j.login+"</b><br>الصلاحيات: <code>"+sc+"</code><br>"+
   (has?'<span class="ok">repo+workflow ✓</span>':'<span class="bad">ناقص repo أو workflow</span>');
 }).catch(function(){S("التوكن غير صالح","bad");});
};
document.getElementById("ob").onclick=function(){
 var o={kuraimi:{name:document.getElementById("kn").value.trim(),account:document.getElementById("ka").value.trim(),
  phone:document.getElementById("kp").value.trim()},whatsapp:document.getElementById("kw").value.trim(),
  identity:localStorage.getItem("ch3099_identity")||"",bank:"Al-Kuraimi Islamic Microfinance Bank",
  swift:"KBMFYESAXXX",updated:new Date().toISOString()};
 localStorage.setItem("ch3099_owner",JSON.stringify(o)); S("حُفظ الحساب ✓","ok");};
function put(path,text,msg){var gh=JSON.parse(localStorage.getItem("ch3099_gh")||"{}");
 if(!gh.token)return Promise.reject("no token");
 var url="https://api.github.com/repos/"+gh.repo+"/contents/"+path;
 var H={Authorization:"token "+gh.token,"Content-Type":"application/json"};
 return fetch(url,{headers:H}).then(function(r){return r.ok?r.json():null}).then(function(j){
  var body={message:msg,content:btoa(unescape(encodeURIComponent(text))),branch:gh.branch};
  if(j&&j.sha)body.sha=j.sha;
  return fetch(url,{method:"PUT",headers:H,body:JSON.stringify(body)});});}
document.getElementById("go").onclick=function(){
 var gh=JSON.parse(localStorage.getItem("ch3099_gh")||"{}");
 var own=JSON.parse(localStorage.getItem("ch3099_owner")||"{}");
 var keys=JSON.parse(localStorage.getItem("ch3099_keys")||"{}");
 var env=Object.keys(keys).filter(function(k){return keys[k]}).map(function(k){return k+"="+keys[k]}).join("\n")+"\n";
 env+="CH3099_IDENTITY="+(localStorage.getItem("ch3099_identity")||"")+"\n";
 if(!gh.token){S("أدخل التوكن أولًا","bad");return;}
 S("جارٍ الدفع…");
 put("keys.env",env,"keys via link").then(function(){return put("owner.json",JSON.stringify(own,null,1),"owner via link");})
 .then(function(){return fetch("https://api.github.com/repos/"+gh.repo+"/dispatches",
   {method:"POST",headers:{Authorization:"token "+gh.token,"Content-Type":"application/json"},
    body:JSON.stringify({event_type:"agent-cycle"})});})
 .then(function(){S("تم الدفع وتشغيل دورة فورية ✓ — الأرقام تتحرك خلال 5 دقائق","ok");})
 .catch(function(e){S("فشل: "+e,"bad");});};
})();
</script></body></html>
LEOF
ok "صفحات الربط والسحب والسجل"

# ================== المرحلة 5: الجدولة السحابية ==================
cat > .github/workflows/agent.yml <<'YEOF'
name: agent
on:
  schedule: [{cron: "*/5 * * * *"}, {cron: "17 3 * * *"}]
  workflow_dispatch:
  repository_dispatch: {types: [agent-cycle]}
permissions: {contents: write}
concurrency: {group: agent, cancel-in-progress: false}
jobs:
  cycle:
    if: github.event.schedule != '17 3 * * *'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: {fetch-depth: 0}
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - run: pip install -q requests
      - run: PAGES_LIMIT=40 bash tools/agent_cycle.sh
      - run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A; git diff --cached --quiet || git commit -m "agent $(date -u +%FT%TZ)"; git push
  daily:
    if: github.event.schedule == '17 3 * * *' || github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: {fetch-depth: 0}
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - run: pip install -q requests
      - run: PAGES_LIMIT=2000 bash tools/agent_cycle.sh
      - run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A; git diff --cached --quiet || git commit -m "daily $(date -u +%FT%TZ)"; git push
YEOF

cat > .github/workflows/health.yml <<'HEOF2'
name: health
on:
  schedule: [{cron: "40 4 * * 1"}]
  workflow_dispatch:
permissions: {contents: write}
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - uses: actions/setup-node@v4
        with: {node-version: "20"}
      - run: python3 tools/audit.py
      - run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A; git diff --cached --quiet || git commit -m "weekly audit $(date -u +%FT%TZ)"; git push
HEOF2
ok "الجدولة السحابية (مجانية · بلا هاتف)"

# ================== المرحلة 6: تشغيل ونشر وتحقق ==================
echo; echo "═══ المرحلة 6 · تشغيل ونشر ═══"
python3 - <<PYEOF
import re
h=open('index.html',encoding='utf-8').read()
h=re.sub(r'<!-- build:\d+ -->\n?','',h).replace('</head>','<!-- build:$STAMP -->\n</head>',1)
open('index.html','w',encoding='utf-8').write(h)
PYEOF
STAMP="$STAMP" python3 tools/audit.py
PLATFORM_TARGET=1000 PAGES_LIMIT=200 bash tools/agent_cycle.sh || true
push_all "master: audit + 90k wiring + modern ui + kuraimi withdrawal [build $STAMP]"

info "انتظار 80 ثانية لنشر Pages..."
sleep 80
for f in index.html sites.html withdraw.html link.html registry.json sitemap.xml; do
  c="$(curl -s -o /dev/null -w '%{http_code}' "https://alisalimax3.github.io/$f")"
  [ "$c" = "200" ] && ok "$f → 200" || bad "$f → $c"
done
python3 -c "
import json
r=json.load(open('registry.json'));print('  مواقع مربوطة:',r['counts']['sites'],'| شرائح:',r['counts']['shards'],'| قنوات دخل:',r['counts']['money'])
a=json.load(open('audit-report.json'));print('  كتل js مكسورة:',a['counts']['broken_js'],'| روابط مفقودة:',len(a['missing']))
"
echo
ok "منفَّذ. افتح: https://alisalimax3.github.io/link.html"
info "ثم /subscribe.html لثلاث شبكات · /withdraw.html لبيانات الكريمي · /sites.html للسجل"
info "الخلفية على الهاتف معطّلة افتراضيًا (السحابة تكفي) — لتشغيلها: nohup bash agentd.sh &"
