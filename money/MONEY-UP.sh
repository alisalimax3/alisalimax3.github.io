#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; DATA="$HERE/data"; cd "$ROOT"
echo "################ 1/6 فحص المفاتيح الحقيقية ################"
bash "$HERE/KEYCHECK.sh" || { echo; echo "أضف المفاتيح الحرجة في keys.env ثم أعد التشغيل (أو --force للمتابعة)"; [ "${1:-}" = "--force" ] || exit 1; }
echo "################ 2/6 ربط المفاتيح داخل التطبيق ################"
python3 - "$ROOT" "$DATA" <<'PY'
import json,os,re,sys,glob,shutil,datetime
root,data=sys.argv[1],sys.argv[2]
env={}
for f in [os.path.join(root,".env"),os.path.join(root,"keys.env"),os.path.join(data,"keys.live.env")]:
    if not os.path.exists(f): continue
    for l in open(f,encoding="utf-8",errors="replace"):
        m=re.match(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$',l)
        if m: env[m.group(1)]=m.group(2).strip().strip('"').strip("'")
cfg={"built":datetime.datetime.utcnow().isoformat()+"Z","adsense_client":env.get("ADSENSE_CLIENT",""),
     "ga_id":env.get("GA_ID",""),"adsterra_pub":env.get("ADSTERRA_PUB_ID",""),
     "postback":"/api/postback","gate":True,
     "features":{"adsense":bool(env.get("ADSENSE_CLIENT")),"analytics":bool(env.get("GA_ID")),"adsterra":bool(env.get("ADSTERRA_PUB_ID")),"telegram":bool(env.get("TELEGRAM_BOT_TOKEN"))}}
open(os.path.join(root,"config.js"),"w").write("window.CINEHUB=Object.assign(window.CINEHUB||{},"+json.dumps(cfg,ensure_ascii=False)+");\n")
if env.get("ADSENSE_CLIENT"):
    p=os.path.join(root,"ads.txt"); pub=env["ADSENSE_CLIENT"].replace("ca-","").replace("pub-","")
    line=f"google.com, pub-{pub}, DIRECT, f08c47fec0942fa0"
    cur=open(p).read() if os.path.exists(p) else ""
    if line not in cur:
        if cur and not cur.endswith("\n"): cur+="\n"
        open(p,"w").write(cur+line+"\n")
    print("  ads.txt محدّث: pub-"+pub)
TAG='<script src="/config.js"></script>'
n=0
for f in glob.glob(os.path.join(root,"*.html")):
    if os.path.basename(f) in ("404.html",): continue
    s=open(f,encoding="utf-8",errors="replace").read()
    if "config.js" in s: continue
    if "</head>" in s: s=s.replace("</head>",TAG+"\n</head>",1)
    else: s=TAG+"\n"+s
    if env.get("GA_ID") and "googletagmanager" not in s:
        s=s.replace("</head>",f'<script async src="https://www.googletagmanager.com/gtag/js?id={env["GA_ID"]}"></script>\n<script>window.dataLayer=window.dataLayer||[];function gtag(){{dataLayer.push(arguments)}}gtag("js",new Date());gtag("config","{env["GA_ID"]}");</script>\n</head>',1)
    if env.get("ADSENSE_CLIENT") and "adsbygoogle" not in s:
        s=s.replace("</head>",f'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={env["ADSENSE_CLIENT"]}" crossorigin="anonymous"></script>\n</head>',1)
    open(f,"w").write(s); n+=1
print(f"  تم حقن config.js في {n} صفحة")
PY
echo "################ 3/6 تثبيت المُرسل (ethers) ################"
( cd "$HERE" && npm install --no-audit --no-fund --silent >/dev/null 2>&1 && echo "  ethers جاهز" ) || echo "  تخطي npm (السحب سيعمل لاحقًا)"
echo "################ 4/6 تشغيل البوابة ################"
if [ -s "$DATA/gateway.pid" ] && kill -0 "$(cat "$DATA/gateway.pid")" 2>/dev/null; then kill "$(cat "$DATA/gateway.pid")" 2>/dev/null; sleep 1; fi
nohup node "$HERE/gateway.js" > "$ROOT/logs/gateway.out" 2>&1 & echo $! > "$DATA/gateway.pid"
sleep 2; curl -sS --max-time 5 "http://127.0.0.1:${PORT:-8787}/api/status" | head -20 || { echo "فشل التشغيل - راجع logs/gateway.out"; exit 1; }
echo "################ 5/6 حصد أولي ################"
bash "$HERE/HARVEST.sh"
echo "################ 6/6 تشغيل الوكيل ################"
if [ -s "$DATA/agent.pid" ] && kill -0 "$(cat "$DATA/agent.pid")" 2>/dev/null; then echo "  الوكيل يعمل"; else
  nohup bash "$HERE/AGENT-MONEY.sh" >> "$ROOT/logs/agent-money.log" 2>&1 & sleep 1; echo "  الوكيل بدأ (pid $(cat "$DATA/agent.pid" 2>/dev/null))"; fi
echo; echo "======== النظام حيّ ========"
echo "  التطبيق   : http://127.0.0.1:${PORT:-8787}/"
echo "  البوابة   : http://127.0.0.1:${PORT:-8787}/gate.html"
echo "  الحالة    : http://127.0.0.1:${PORT:-8787}/api/status"
echo "  الأرباح   : http://127.0.0.1:${PORT:-8787}/api/earnings"
echo "  الدفتر    : http://127.0.0.1:${PORT:-8787}/api/ledger"
echo "  postback  : http://127.0.0.1:${PORT:-8787}/api/postback?net=adsterra&amount=0.15&uid=USERID&sig=HMAC"
