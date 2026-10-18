#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص حقيقي شامل: بيئة · مستودع · حيّ · واجهات · مفاتيح · وكيل · مال · فجوات"""
import json,os,re,subprocess,sys,urllib.request,urllib.error,datetime,shutil
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
TOK=os.environ.get("CH_TOK",""); REPO=os.environ.get("CH_REPO","alkazmybwhwr-dot/alkazmybwhwr-dot.github.io")
LIVE="https://"+REPO.split("/")[0]+".github.io"
R={"at":datetime.datetime.now(datetime.timezone.utc).isoformat(),"gaps":[]}
def sh(c):
    try: return subprocess.run(c,shell=True,capture_output=True,text=True,timeout=25).stdout.strip()
    except Exception: return ""
def api(path,method="GET",body=None):
    try:
        req=urllib.request.Request("https://api.github.com"+path,
            data=json.dumps(body).encode() if body else None,
            headers={"Authorization":"token "+TOK,"Accept":"application/vnd.github+json","Content-Type":"application/json"})
        if method!="GET": req.method=method
        r=urllib.request.urlopen(req,timeout=25)
        return json.loads(r.read().decode()) if r.status!=204 else {}, r.status
    except urllib.error.HTTPError as e: return None,e.code
    except Exception as e: return None,str(e)[:60]
def get(u,t=25):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,headers={"User-Agent":"ch3099"}),timeout=t)
        return r.status,r.read().decode("utf-8","replace")
    except urllib.error.HTTPError as e: return e.code,""
    except Exception: return 0,""
def head(u,t=20):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,method="HEAD",headers={"User-Agent":"ch3099"}),timeout=t)
        return r.status
    except urllib.error.HTTPError as e: return e.code
    except Exception: return 0
def L(f,d):
    try: return json.load(open(f,encoding="utf-8"))
    except Exception: return d

# --- بيئة ---
R["env"]={"python":sys.version.split()[0],"node":sh("node -v") or "غير مثبّت",
          "curl":sh("curl --version | head -1")[:40] or "غير مثبّت",
          "termux":os.path.isdir("/data/data/com.termux/files/usr"),
          "disk":sh("df -h . | tail -1")}

# --- مستودع ---
R["repo"]={"branch":sh("git rev-parse --abbrev-ref HEAD"),
           "detached":sh("git rev-parse --abbrev-ref HEAD")=="HEAD",
           "remote":sh("git remote get-url origin").split("@")[-1],
           "token_present":bool(TOK)}
ri,_=api("/repos/"+REPO)
if isinstance(ri,dict):
    R["repo"]["default_branch"]=ri.get("default_branch")
    R["repo"]["private"]=ri.get("private")
perm,_=api("/repos/"+REPO+"/actions/permissions")
R["repo"]["actions_enabled"]=(isinstance(perm,dict) and perm.get("enabled",True)) if perm is not None else "غير معروف"
wl,_=api("/repos/"+REPO+"/actions/workflows")
R["repo"]["workflows_registered"]=[{"id":x.get("id"),"name":x.get("name"),"path":x.get("path"),"state":x.get("state")} for x in (wl or {}).get("workflows",[])]
R["repo"]["workflows_local"]=sorted(os.listdir(".github/workflows")) if os.path.isdir(".github/workflows") else []
git ls-files > .ls.txt 2>/dev/null
files=open(".ls.txt",encoding="utf-8").read().split() if os.path.exists(".ls.txt") else []
R["repo"]["tracked_files"]=len(files)
R["repo"]["workflows_tracked"]=[f for f in files if f.startswith(".github/workflows")]

# --- حيّ ---
LF=["index.html","library.html","adult.html","play.html","watch.html","go.html","earn.html","rise.html",
"agent.html","withdraw.html","keys.html","share.html","rails.html","tower.html","diag.html","check.html",
"cinema.html","auto.html","surveys.html","rewards.html","audit.html","live-dash.html",
"nav.js","ads.js","auto.js","authtoken.js","catalog.json","adult.json","auth.json","browse.json",
"keys-status.json","tasks.json","rewards.json","treasury.json","revenue.json","diag.json",
"platforms_active.json","sitemap.xml","rss.xml","robots.txt"]
R["live"]={f:head("%s/%s?a=%s"%(LIVE,f,int(datetime.datetime.now().timestamp()))) for f in LF}
R["live_missing"]=[f for f,c in R["live"].items() if c!=200]

# --- محتوى ---
R["content"]={"films":L("catalog.json",{}).get("count",0),"adult":L("adult.json",{}).get("count",0),
              "film_pages":len(os.listdir("p")) if os.path.isdir("p") else 0,
              "tag_pages":len(os.listdir("x")) if os.path.isdir("x") else 0}

# --- واجهات خارجية (اختبار حقيقي) ---
APIS=[("archive.org","https://archive.org/advancedsearch.php?q=mediatype:movies&rows=1&output=json","response"),
("Eporner","https://www.eporner.com/api/v2/video/search/?query=&per_page=5&page=1&thumbsize=big&order=top-weekly&gay=0&lq=1&format=json","videos"),
("Eporner top","https://www.eporner.com/api/v2/video/top/?per_page=5&page=1&thumbsize=big&format=json","videos"),
("RedTube","https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=1&ordering=newest&search=","videos"),
("iTunes","https://itunes.apple.com/search?term=action&media=movie&limit=5","results"),
("Wikidata","https://query.wikidata.org/sparql?query=SELECT%20?x%20WHERE%20{?x%20wdt:P31%20wd:Q11424}%20LIMIT%205&format=json","results"),
("IndexNow","https://api.indexnow.org/indexnow","status")]
R["apis"]=[]
for name,u,key in APIS:
    c,b=get(u,30)
    items=None
    try:
        d=json.loads(b); v=d.get(key)
        items=len(v.get("docs",v)) if isinstance(v,dict) else (len(v) if isinstance(v,list) else None)
    except Exception: pass
    R["apis"].append({"name":name,"code":c,"items":items,"ok":c in (200,202,204)})

# --- مفاتيح ---
env={}
if os.path.exists("keys.env"):
    for ln in open("keys.env",encoding="utf-8",errors="replace"):
        ln=ln.strip()
        if ln and not ln.startswith("#") and "=" in ln:
            k,v=ln.split("=",1); env[k.strip()]=v.strip()
ks=L("keys-status.json",{})
R["keys"]={"total":len(env),"nonempty":sum(1 for v in env.values() if v),
           "valid":ks.get("valid",0),"items":ks.get("items",[]),
           "names":sorted([k for k,v in env.items() if v])}

# --- وكيل ---
runs,_=api("/repos/"+REPO+"/actions/runs?per_page=5")
R["agent"]={"browse":L("browse.json",{}),"cycles":L("pulse.json",{}).get("cycle",0),
            "rewards":L("rewards.json",{}).get("total",0),
            "ad_requests":L("browse.json",{}).get("ad_requests",0),
            "runs":[{"name":x.get("name"),"status":x.get("status"),"conclusion":x.get("conclusion"),
                     "at":x.get("created_at")} for x in (runs or {}).get("workflow_runs",[])[:5]] if runs else []}

# --- مال ---
tr=L("treasury.json",{}); rv=L("revenue.json",{}); po=L("payouts.json",{"requests":[]}); wd=L("withdrawal.json",{"requests":[]})
R["money"]={"balance":tr.get("balance",0),"buckets":tr.get("buckets",{}),
            "confirmed":rv.get("confirmed_total",0),"estimated":(rv.get("estimated") or {}).get("value",0),
            "payouts":len(po.get("requests",[])),"withdrawals":len(wd.get("requests",[])),
            "min":tr.get("min",5)}

# --- تحليل الفجوات ---
G=R["gaps"]
def gap(i,sev,what,fix,how):
    G.append({"id":i,"sev":sev,"what":what,"fix":fix,"how":how})
if not TOK: gap("token","high","لا توكن في الريموت — لا دفع ولا تشغيل","إنشاء توكن","https://github.com/settings/tokens/new?scopes=repo,workflow")
if R["repo"].get("detached"): gap("head","high","HEAD منفصل ⇒ الدفعات تضيع","إصلاح تلقائي","أُصلح")
if not R["repo"]["workflows_tracked"]: gap("wf","high","لا ملفات عمل في المستودع ⇒ لا وكيل","إعادة كتابتها ودفعها","أُصلح")
if not R["repo"]["workflows_registered"]: gap("wfreg","high","GitHub لا يعرف أي ملف عمل ⇒ Actions معطّل أو ليست على الفرع الافتراضي","افتح صفحة Actions وفعّلها","https://github.com/%s/actions"%REPO)
if not R["agent"]["runs"]: gap("runs","high","لا تشغيل واحد للوكيل ⇒ لا مهام ولا مكافآت","شغّل يدويًا","AUDIT يشغّل الآن")
if R["keys"]["valid"]==0: gap("keys","high","لا مفتاح شبكة صالح ⇒ الإيراد المؤكَّد صفر","اربط Adsterra (3 دقائق)","keys.html")
if R["content"]["films"]==0: gap("films","high","لا كتالوج أفلام","استيعاب","أُصلح")
if R["content"]["adult"]==0: gap("adult","high","لا مقاطع كبار","استيعاب باحتياطيات","أُصلح")
if R["live_missing"]: gap("live","high","%d ملف غير منشور: %s"%(len(R["live_missing"]),", ".join(R["live_missing"][:6])),"دفع مُتحقَّق","أُصلح")
if not env.get("OWNER_EMAIL"): gap("email","low","بريد المالك غير مسجّل","إضافته","أُصلح")
if not L("owner.json",{}).get("kuraimi"): gap("kuraimi","med","بيانات الكريمي غير محفوظة ⇒ السحب متوقف","أدخلها","withdraw.html")
if R["agent"]["ad_requests"]==0: gap("browse","med","لا طلبات إعلان من الوكيل ⇒ لا ظهور","تشغيل browse","أُصلح")
if R["money"]["balance"]<R["money"]["min"]: gap("bal","med","الرصيد أقل من حد السحب $5","مهام + مفاتيح + زيارات","earn.html")
json.dump(R,open("audit.json","w"),ensure_ascii=False,indent=1)

# تقرير مقروء
M=["# تقرير فحص CineHub 3099 — "+R["at"],"","## الفجوات (%d)"%len(G)]
for g in sorted(G,key=lambda x:{"high":0,"med":1,"low":2}[x["sev"]]):
    M.append("- **[%s]** %s → الإصلاح: %s (%s)"%(g["sev"].upper(),g["what"],g["fix"],g["how"]))
M+=["","## الأرقام","- ملفات حيّة: %d/%d"%(len(R["live"])-len(R["live_missing"]),len(R["live"])),
    "- أفلام: %d · كبار: %d · صفحات: %d"%(R["content"]["films"],R["content"]["adult"],R["content"]["film_pages"]),
    "- مفاتيح: %d (صالحة %d)"%(R["keys"]["total"],R["keys"]["valid"]),
    "- طلبات إعلان: %d · دورات: %d · مكافآت: $%.6f"%(R["agent"]["ad_requests"],R["agent"]["cycles"],R["agent"]["rewards"]),
    "- الرصيد: $%.6f"%R["money"]["balance"]]
open("audit.md","w",encoding="utf-8").write("\n".join(M))
print("فجوات: %d (عالية %d)"%(len(G),sum(1 for g in G if g["sev"]=="high")))
print("ملفات حيّة: %d/%d"%(len(R["live"])-len(R["live_missing"]),len(R["live"])))
print("أفلام %d · كبار %d · مفاتيح صالحة %d · تشغيلات %d"%(R["content"]["films"],R["content"]["adult"],R["keys"]["valid"],len(R["agent"]["runs"])))
for g in sorted(G,key=lambda x:{"high":0,"med":1,"low":2}[x["sev"]])[:8]:
    print("  [%s] %s"%(g["sev"].upper(),g["what"]))
