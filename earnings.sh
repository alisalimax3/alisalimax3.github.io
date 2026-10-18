#!/data/data/com.termux/files/usr/bin/bash
NS=cinehub-alkazmy-3099; B=https://abacus.jasoncameron.dev; S=https://alkazmybwhwr-dot.github.io
g(){ curl -s -m 10 "$B/get/$NS/$1" | sed -n 's/.*"value":\([0-9]*\).*/\1/p'; }
V=$(g views); P=$(g plays); V=${V:-0}; P=${P:-0}
echo "════════ حقيقي من العدّاد ════════"
printf 'زيارات: %s   تشغيلات: %s\n' "$V" "$P"
echo "════════ رصيد محفظتك (بلوكتشين) ════════"
bash chain.sh 2>/dev/null | tail -n +2
echo "════════ الإسقاط (تقديري) ════════"
python3 -c "
v=$V
for n,d in (('يومي',1),('أسبوعي',7),('شهري',30)):
    x=v*d
    print('  %-7s: \$%.2f – \$%.2f' % (n, x*0.3/1000, x*3/1000))
print('  ملاحظة: الإسقاط يفترض ثبات الزيارات يوميًا')
"
echo "════════ التفعيل ════════"
python3 -c "import json;d=json.load(open('ads-config.json'));print('• إعلانات: '+('✓ مُفعّلة' if d.get('scripts') else '✗ غير مُفعّلة → bash activate.sh \"رابط\"'))" 2>/dev/null
python3 -c "import json;d=json.load(open('surveys-config.json'));print('• استطلاعات: '+(('✓ '+d['provider']) if d.get('provider') and d.get('id') else '✗ غير مُفعّلة → bash surveys.sh bitlabs TOKEN'))" 2>/dev/null
python3 -c "import json;d=json.load(open('wallet.json'));print('• محفظة: '+(d.get('address') or '✗ غير محددة → bash wallet.sh 0x...'))" 2>/dev/null
echo "════════ المنشور ════════"
for f in index.html earn.html withdraw.html ads.js surveys.js b/anime-popular.html en/index.html; do
  printf '%-24s %s\n' "$f" "$(curl -s -o /dev/null -w '%{http_code}' -m 12 "$S/$f")"
done
