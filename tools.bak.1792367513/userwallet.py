#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""واجهة المستخدم: مشاهدة · مشاركة · إحالة · أرباح. عمولة المالك 20% تُضاف للخزينة."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE, custody

CUT = custody.POLICY["owner_cut_pct"]

def main():
    with core.lock("userwallet", 900) as got:
        if not got: print("  · مقفول"); return
        r = RE.apply_ledger(); conf = r["totals"]["approved"] + r["totals"]["paid"]
        pool = round(conf * 50 / 100.0, 4)
        core.write_if_changed("me.html", """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>محفظتي — CineHub 3099</title><meta name="description" content="شاهد · شارك · اربح">
<link rel="manifest" href="manifest.json"><link rel="stylesheet" href="assets/app.css">
</head><body><div class="wrap">
<div class="top"><span class="brand">CineHub 3099</span>
<a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="rewards.html">🎁 المكافأة</a>
<a href="share.html">🔗 شارك</a><a href="me.html" class="on">محفظتي</a></div>
<h1>محفظتي</h1>
<div class="card"><p class="k">أدخل كودك — يظهر لك ما كسبته من الإحالات.</p>
<input id="code" placeholder="كودك (مثال: alisalimax3)" oninput="save()">
<p class="k">رابط إحالتك:</p><input id="link" readonly onclick="this.select()"></div>
<div class="stats">
<div class="stat"><div class="l">مطالباتك</div><div class="v" id="mine">—</div></div>
<div class="stat"><div class="l">إحالاتك (مطالبات)</div><div class="v" id="refs">—</div></div>
<div class="stat"><div class="l">نقاطك التقديرية</div><div class="v ok" id="pts">—</div></div>
<div class="stat"><div class="l">صندوق المكافآت</div><div class="v">$%(pool).4f</div></div>
</div>
<div class="card"><b>كيف تُحسب</b>
<table><tr><td>عائد الموقع المؤكد</td><td>$%(conf).2f</td></tr>
<tr><td>حصة المستخدمين (50%%)</td><td>$%(pool).4f</td></tr>
<tr><td>عمولة المالك من أرباح المستخدمين</td><td>%(cut)d%%</td></tr>
<tr><td>حصتك</td><td>مطالباتك ÷ إجمالي المطالبات × الحصة</td></tr></table>
<p class="k">النقاط ليست دولارًا قابلاً للسحب بعد — تصبح كذلك عند بلوغ العائد المؤكد 20$.</p></div>
<div class="card"><b>شارك واربح</b><p class="k">كل من يأتي عبر رابطك ويطالب يوميًا يزيد إحالاتك.</p>
<button class="btn" onclick="cp()">انسخ رابطي</button>
<a class="btn ghost" href="share.html">روابط جاهزة</a></div>
<div class="card"><b>القواعد</b><p class="k">مطالبة واحدة يوميًا لكل جهاز · المنع من السيرفر ·
لا سقف يومي · لا رصيد وهمي · عمولة المالك %(cut)d%% تُضاف لخزينته مباشرة.</p></div>
<div class="foot"><a href="owner.html">لوحة المالك</a> · <a href="income.html">المصادر</a></div>
</div><script src="hits.js" defer></script>
<script>
var NS="%(ns)s",S="%(site)s";
function g(k,d){try{return localStorage.getItem(k)||d}catch(e){return d}}
function s(k,v){try{localStorage.setItem(k,v)}catch(e){}}
function save(){var c=(document.getElementById("code").value||"").trim();s("ch_code",c);
document.getElementById("link").value=S+"/?ref="+encodeURIComponent(c);load(c);}
function cp(){var l=document.getElementById("link");l.select();document.execCommand("copy");}
function load(c){if(!c)return;
fetch("https://abacus.jasoncameron.dev/get/"+NS+"/ref-"+c.replace(/[^A-Za-z0-9._-]/g,"-"))
.then(function(r){return r.json()}).then(function(j){document.getElementById("refs").textContent=(j&&j.value)||0;})
.catch(function(){document.getElementById("refs").textContent="0";});}
var c0=g("ch_code","");if(c0){document.getElementById("code").value=c0;
document.getElementById("link").value=S+"/?ref="+encodeURIComponent(c0);load(c0);}
document.getElementById("mine").textContent=parseInt(g("ch_claims","0"),10);
document.getElementById("pts").textContent=parseInt(g("ch_claims","0"),10)*5;
</script></body></html>""" % {"pool": pool, "conf": conf, "ns": core.ns(),
                           "site": core.site(), "cut": CUT})
        # robots: منع فهرسة صفحات المستخدم/المالك
        print("  ✓ me.html · عمولة المالك %d%%" % CUT)

if __name__ == "__main__": main()
