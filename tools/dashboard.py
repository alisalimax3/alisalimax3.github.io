#!/usr/bin/env python3
import os
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
open("money.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>الأموال — CineHub</title>
<style>body{margin:0;background:#0b0d12;color:#e8ecf3;font:15px/1.7 system-ui,Tahoma}.w{max-width:960px;margin:0 auto;padding:18px}
h1{font-size:20px}h2{font-size:14px;color:#aab6c8;margin:20px 0 8px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px}
.c{background:#141924;border:1px solid #1e2635;border-radius:13px;padding:13px}.k{color:#8b96a8;font-size:12px}
.v{font-size:23px;font-weight:700}.g{color:#39d98a}.y{color:#ffcf5c}.tag{font-size:11px;padding:2px 8px;border-radius:999px}
.on{background:#12301f;color:#39d98a}.off{background:#2a1c1c;color:#ff9b9b}table{width:100%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}a{color:#5ca9ff}</style>
<div class="w"><h1>💰 لوحة الأموال</h1><div class="k" id="up">…</div>
<div class="grid" id="r"></div><h2>تقديري (ليس نقدًا)</h2><div class="grid" id="e"></div>
<h2>الشبكات</h2><div class="c"><table id="n"></table></div>
<p><a href="./">الرئيسية</a> · <a href="wallet.html">الخزينة</a> · <a href="app.html">التطبيق</a></p></div>
<script>fetch('data/money.json?_='+Date.now()).then(r=>r.json()).then(m=>{
document.getElementById('up').textContent='آخر تحديث: '+m.updated;const R=m.real||{};
document.getElementById('r').innerHTML=[['زيارات GitHub',R.github_views_14d,'g'],['زوار فريدون',R.github_uniques_14d,'y'],
['عدّاد الصفحات',R.hits_total,'b'],['شبكات مفعّلة',R.live_ad_networks,'g']]
.map(x=>'<div class="c"><div class="k">'+x[0]+'</div><div class="v '+x[2]+'">'+(x[1]??0)+'</div></div>').join('');
const E=m.estimated||{};document.getElementById('e').innerHTML=[['عروض',E.impressions,''],['eCPM',E.ecpm_used,'b'],['$',E.usd,'g']]
.map(x=>'<div class="c"><div class="k">'+x[0]+'</div><div class="v '+x[2]+'">'+(x[1]??0)+'</div></div>').join('');
let h='<tr><th>الشبكة</th><th>الدفع</th><th>الحالة</th></tr>';
(m.networks_live||[]).forEach(x=>h+='<tr><td>'+x.n+'</td><td>'+x.pay+'</td><td><span class="tag on">مفعّلة</span></td></tr>');
(m.networks_off||[]).forEach(x=>h+='<tr><td>'+x.n+'</td><td>—</td><td><span class="tag off">تنتظر '+x.k+'</span></td></tr>');
document.getElementById('n').innerHTML=h;});</script></html>""")
print("  ✓ money.html")
