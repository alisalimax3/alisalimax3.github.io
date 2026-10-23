#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"
python3 - "$ROOT" "$DATA" <<'PY'
import json,os,re,sys,glob,datetime
root,data=sys.argv[1],sys.argv[2]; env={}
for f in [os.path.join(root,".env"),os.path.join(root,"keys.env"),os.path.join(data,"keys.live.env")]:
    if not os.path.exists(f): continue
    for l in open(f,encoding="utf-8",errors="replace"):
        m=re.match(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$',l)
        if m: env[m.group(1)]=m.group(2).strip().strip('"').strip("'")
cfg={"built":datetime.datetime.now(datetime.timezone.utc).isoformat(),"adsense_client":env.get("ADSENSE_CLIENT",""),
 "ga_id":env.get("GA_ID",""),"adsterra_pub":env.get("ADSTERRA_PUB_ID",""),"postback":"/api/postback","gate":True,
 "features":{"adsense":bool(env.get("ADSENSE_CLIENT")),"analytics":bool(env.get("GA_ID")),
             "adsterra":bool(env.get("ADSTERRA_PUB_ID")),"telegram":bool(env.get("TELEGRAM_BOT_TOKEN"))}}
open(os.path.join(root,"config.js"),"w").write("window.CINEHUB=Object.assign(window.CINEHUB||{},"+json.dumps(cfg,ensure_ascii=False)+");\n")
if env.get("ADSENSE_CLIENT"):
    pub=env["ADSENSE_CLIENT"].replace("ca-","").replace("pub-",""); p=os.path.join(root,"ads.txt")
    line=f"google.com, pub-{pub}, DIRECT, f08c47fec0942fa0"; cur=open(p).read() if os.path.exists(p) else ""
    if line not in cur: open(p,"w").write(cur+("" if (not cur or cur.endswith("\n")) else "\n")+line+"\n")
TAG='<script src="/config.js"></script>'; n=0
for f in glob.glob(os.path.join(root,"*.html")):
    if os.path.basename(f)=="404.html": continue
    s=open(f,encoding="utf-8",errors="replace").read()
    if "config.js" not in s: s=s.replace("</head>",TAG+"\n</head>",1) if "</head>" in s else TAG+"\n"+s
    if env.get("GA_ID") and "googletagmanager" not in s:
        s=s.replace("</head>",f'<script async src="https://www.googletagmanager.com/gtag/js?id={env["GA_ID"]}"></script>\n<script>window.dataLayer=window.dataLayer||[];function gtag(){{dataLayer.push(arguments)}}gtag("js",new Date());gtag("config","{env["GA_ID"]}");</script>\n</head>',1)
    if env.get("ADSENSE_CLIENT") and "adsbygoogle" not in s:
        s=s.replace("</head>",f'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={env["ADSENSE_CLIENT"]}" crossorigin="anonymous"></script>\n</head>',1)
    open(f,"w").write(s); n+=1
print(f"  ✔ حُقنت المفاتيح في {n} صفحة")
PY
bash "$HERE/GATEWAY.sh" restart
