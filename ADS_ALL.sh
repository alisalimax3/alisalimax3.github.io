#!/data/data/com.termux/files/usr/bin/bash
# تفعيل 3 شبكات إعلانات (تكديس دخل من 3 مصادر)
set -u
cd "$HOME/cinehub3099" || exit 1
echo "╔═══ مصادر الدخل — سجّل في كل واحدة (5 دقائق لكل) ═══╗"
echo "║ 1) Adsterra  : https://publishers.adsterra.com  (Popunder + Social Bar)"
echo "║ 2) Monetag   : https://monetag.com              (In-Page Push + Vignette)"
echo "║ 3) AdSense   : https://adsense.google.com       (Banner — اختياري)"
echo "╚═══════════════════════════════════════════════════╝"
echo
read -p "Adsterra API Key: " AK
read -p "Adsterra Popunder كود: " AP
read -p "Adsterra Social Bar كود: " AS
read -p "Monetag Zone ID: " MZ
read -p "AdSense client (ca-pub-...): " GC
python3 - "$AK" "$AP" "$AS" "$MZ" "$GC" <<'PY'
import json,sys
ak,ap,asb,mz,gc=[x.strip() for x in sys.argv[1:6]]
try: a=json.load(open("ads.json",encoding="utf-8"))
except Exception: a={}
a.setdefault("adsterra",{}); a.setdefault("monetag",{}); a.setdefault("adsense",{})
if ak: a["adsterra"]["api_key"]=ak
if ap: a["adsterra"]["popunder"]=ap
if asb: a["adsterra"]["socialbar"]=asb
if mz: a["monetag"]["zone"]=mz
if gc: a["adsense"]["client"]=gc
a["adsterra"]["enabled"]=bool(ak or ap or asb)
a["monetag"]["enabled"]=bool(mz)
a["adsense"]["enabled"]=bool(gc)
json.dump(a,open("ads.json","w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("ads.json محدّث: adsterra=%s monetag=%s adsense=%s"%(a["adsterra"]["enabled"],a["monetag"]["enabled"],a["adsense"]["enabled"]))
PY
python3 tools/revenue_sync.py 2>&1 | tail -3
bash PUSH2.sh "ads: 3 networks enabled"
echo "✓ الإعلانات مفعّلة — الرصيد سيظهر في https://alisalimax3.github.io/admin.html"
