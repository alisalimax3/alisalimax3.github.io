#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
echo "=== تفعيل شبكة الإعلانات ==="
echo "سجّل في https://publishers.adsterra.com ثم: Profile → API → انسخ المفتاح"
read -p "Adsterra API Key (اتركه فارغًا للتخطي): " K
if [ -n "${K:-}" ]; then
  python3 - "$K" <<'PY'
import json,sys
a=json.load(open("ads.json")); a["adsterra"]["api_key"]=sys.argv[1]; a["adsterra"]["enabled"]=True
json.dump(a,open("ads.json","w"),ensure_ascii=False,indent=1); print("حُفظ المفتاح")
PY
  python3 tools/revenue_sync.py
fi
echo "الصق كود Popunder ثم Social Bar من Adsterra (Enter للتخطي):"
read -p "Popunder: " PU; read -p "SocialBar: " SB
python3 - "$PU" "$SB" <<'PY'
import json,sys
a=json.load(open("ads.json"))
if sys.argv[1].strip(): a["adsterra"]["popunder"]=sys.argv[1].strip()
if sys.argv[2].strip(): a["adsterra"]["socialbar"]=sys.argv[2].strip()
json.dump(a,open("ads.json","w"),ensure_ascii=False,indent=1)
PY
python3 tools/ledger.py 2>/dev/null||true
bash tools/push.sh "ads: enable" && echo "✓ مرفوع — الإعلانات تعمل الآن"
