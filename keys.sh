#!/data/data/com.termux/files/usr/bin/bash
set -u; cd ~/cinehub3099 || exit 1
python3 - "$@" <<'PY'
import json,sys,re
a=sys.argv[1:]
if not a or a[0]=='show':
    for f in ("ads-config.json","kuraimi.json"):
        print("──",f); print(open(f,encoding="utf-8").read())
    print("── endpoint:", (re.search(r"'([^']*)'", open("payout.js",encoding="utf-8").read().split("ch_endpoint")[1]).group(1) if "ch_endpoint" in open("payout.js",encoding="utf-8").read() else ""))
    sys.exit()
c=a[0]
if c=="ads":
    d=json.load(open("ads-config.json",encoding="utf-8")); d["network"]=a[1] if len(a)>1 else "adsterra"
    if len(a)>2: d["banners"]["top"]["key"]=a[2]
    if len(a)>3: d["socialbar_src"]=a[3]
    if len(a)>4: d["popunder_src"]=a[4]
    json.dump(d,open("ads-config.json","w",encoding="utf-8"),indent=2,ensure_ascii=False); print("✓ الإعلانات")
elif c=="banner":
    d=json.load(open("ads-config.json",encoding="utf-8")); d["banners"][a[1]]={"size":a[2],"key":a[3]}
    json.dump(d,open("ads-config.json","w",encoding="utf-8"),indent=2,ensure_ascii=False); print("✓ بانر",a[1])
elif c=="captcha":
    s=open("captcha.js",encoding="utf-8").read()
    open("captcha.js","w",encoding="utf-8").write(re.sub(r"var SITEKEY='[^']*'","var SITEKEY='%s'"%a[1],s)); print("✓ كابتشا")
elif c=="endpoint":
    s=open("payout.js",encoding="utf-8").read()
    open("payout.js","w",encoding="utf-8").write(re.sub(r"var EP = [^;]*;","var EP = localStorage.getItem('ch_endpoint') || '%s';"%a[1],s)); print("✓ endpoint")
elif c=="kuraimi":
    d=json.load(open("kuraimi.json",encoding="utf-8"))
    d["holder"]=a[1] if len(a)>1 else d.get("holder","")
    d["account"]=a[2] if len(a)>2 else d.get("account","")
    d["branch"]=a[3] if len(a)>3 else d.get("branch","")
    json.dump(d,open("kuraimi.json","w",encoding="utf-8"),indent=2,ensure_ascii=False); print("✓ الكريمي")
elif c=="password":
    import hashlib
    s=open("auth.js",encoding="utf-8").read()
    open("auth.js","w",encoding="utf-8").write(re.sub(r"ADMIN_SHA='[0-9a-f]{64}'","ADMIN_SHA='%s'"%hashlib.sha256(a[1].encode()).hexdigest(),s)); print("✓ كلمة المرور")
PY
cd ~/cinehub3099 && bash restart.sh >/dev/null 2>&1; echo "أُعيد النشر"
