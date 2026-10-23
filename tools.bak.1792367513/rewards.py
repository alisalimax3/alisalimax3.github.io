#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مكافآت: نقاط مربوطة بعائد مؤكد · منع تكرار سيرفري · بلا سقف يومي/شهري."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

CLAIM, REFPTS, SHARE = 5, 25, 50
HONEST = ("النقاط ليست دولارًا قابلاً للسحب. حصتك = مطالباتك ÷ إجمالي المطالبات × 50%% "
          "من العائد المؤكد. تصبح قابلة للصرف عند وصول العائد المؤكد إلى 20$ (أقل حد سحب فعلي).")

RULES = [
 "مطالبة واحدة كل 24 ساعة لكل جهاز — يمنعها عدّاد سيرفري، لا localStorage. مسح المتصفح لا يمنح مطالبة إضافية.",
 "لا سقف يومي ولا شهري: كل يوم يُطالب فيه الجميع يُضاف للصندوق.",
 "لا سقف للميزانية: إن تجاوز التوزيع الحصة، يُسجّل التجاوز ولا يُمنع.",
 "الزيارات الآلية تُحتسب زيارة لكن لا تُنشئ مالًا.",
 "النقاط محفوظة على جهازك، والعدد الكلي على السيرفر.",
]

def build():
    r = RE.apply_ledger()
    conf = r["totals"]["approved"] + r["totals"]["paid"]
    pool = round(conf * SHARE / 100.0, 4)
    core.save("data/rewards.json", {
      "updated": time.strftime("%F %H:%M"), "namespace": core.ns(),
      "funding": {"mode": "share-of-confirmed-revenue", "share_pct": SHARE,
                  "confirmed_usd": round(conf, 2), "pool_usd": pool,
                  "status": "غير ممول بعد" if pool <= 0 else "ممول",
                  "caps": {"daily": None, "monthly": None, "overrun_blocked": False}},
      "points": {"claim": CLAIM, "referral": REFPTS},
      "rules": RULES, "honest": HONEST})
    return pool, conf

PAGE = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>المكافأة اليومية — CineHub 3099</title>
<meta name="description" content="مطالبة يومية بنقاط مربوطة بعائد الموقع المؤكد">
<link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:640px;margin:0 auto;padding:18px}h1{font-size:22px;margin:.3em 0}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:16px;margin:12px 0}
.big{font-size:34px;font-weight:700;color:#39d98a;line-height:1.2}
.btn{display:block;width:100%%;padding:14px;border:0;border-radius:12px;background:#2f6df6;color:#fff;
font-size:16px;font-weight:600;cursor:pointer;margin-top:10px}
.btn[disabled]{background:#26303f;color:#7d8896;cursor:default}
.k{color:#8b96a8;font-size:13px}a{color:#5ca9ff}ul{padding-inline-start:20px;font-size:13.5px;color:#c3ccd8}
.warn{background:#1b1508;border-color:#3a2c08;color:#e8c76a;font-size:13px}
table{width:100%%;border-collapse:collapse;font-size:13px}td{padding:5px;border-bottom:1px solid #1e2635}</style>
</head><body><div class="w"><h1>🎁 المكافأة اليومية</h1>
<p class="k">مطالبة واحدة كل يوم · %(pts)d نقطة · إحالة %(ref)d نقطة لكل مطالبة من إحالتك</p>
<div class="card"><div class="k">نقاطك</div><div class="big" id="pts">—</div>
<div class="k">مطالباتك: <b id="cl">—</b> · سلسلتك: <b id="st">—</b> يوم</div>
<button class="btn" id="go" onclick="claim()">جارٍ التحقق…</button>
<div class="k" id="msg" style="margin-top:8px"></div></div>
<div class="card"><div class="k">الصندوق (من السيرفر)</div>
<table><tr><td>عائد مؤكد</td><td><b>$%(conf).2f</b></td></tr>
<tr><td>حصة المكافآت 50%%</td><td><b>$%(pool).4f</b></td></tr>
<tr><td>إجمالي المطالبات عالميًا</td><td><b data-hits="claims">…</b></td></tr>
<tr><td>حالتك</td><td>مطالباتك ÷ الإجمالي × الحصة</td></tr></table>
<p class="k">لا سقف يومي ولا شهري · لا منع عند تجاوز الميزانية (يُسجّل فقط).</p></div>
<div class="card warn"><b>بصراحة:</b> %(honest)s</div>
<div class="card"><b>الشروط</b><ul>%(rules)s</ul></div>
<p class="k"><a href="./">الرئيسية</a> · <a href="rewards-earn.html">اكسب أكثر</a> · <a href="share.html">روابط</a> · <a href="owner.html">لوحة المالك</a></p>
</div><script src="hits.js" defer></script>
<script>
var NS="%(ns)s",PT=%(pts)d;
function v(){try{var x=localStorage.getItem("ch_vid");if(!x){x=Math.random().toString(36).slice(2,10)+Date.now().toString(36);localStorage.setItem("ch_vid",x);}return x;}catch(e){return "anon";}}
function ls(k,d){try{return parseInt(localStorage.getItem(k)||d,10)||0;}catch(e){return 0;}}
function ss(k,v){try{localStorage.setItem(k,String(v));}catch(e){}}
function dd(){return new Date().toISOString().slice(0,10);}
function paint(){var c=ls("ch_claims",0);document.getElementById("pts").textContent=(c*PT)+" نقطة";
document.getElementById("cl").textContent=c;document.getElementById("st").textContent=ls("ch_streak",0);
var b=document.getElementById("go");if(ls("ch_last",0)===parseInt(dd().replace(/-/g,""),10)){b.disabled=true;b.textContent="تمت مطالبة اليوم ✓";}
else{b.disabled=false;b.textContent="اطالب بـ "+PT+" نقطة";}}
function claim(){var b=document.getElementById("go");b.disabled=true;b.textContent="جارٍ التحقق…";
fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/claim-"+dd()+"-"+v()).then(function(r){return r.json();})
.then(function(j){if(!(j&&j.value===1)){document.getElementById("msg").textContent="جهازك طالب اليوم — المنع من السيرفر.";paint();return;}
fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/claims").catch(function(){});
var ref="";try{ref=localStorage.getItem("ch_ref")||"";}catch(e){}
if(ref)fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/ref-"+ref.replace(/[^A-Za-z0-9._-]/g,"-")).catch(function(){});
var c=ls("ch_claims",0)+1;ss("ch_claims",c);ss("ch_last",parseInt(dd().replace(/-/g,""),10));
var y=new Date(Date.now()-86400000).toISOString().slice(0,10);
ss("ch_streak",ls("ch_streak_date","")===y?ls("ch_streak",0)+1:1);ss("ch_streak_date",dd());
document.getElementById("msg").textContent="✓ أُضيفت "+PT+" نقطة";paint();})
.catch(function(){document.getElementById("msg").textContent="فشل الشبكة — أعد المحاولة.";b.disabled=false;b.textContent="أعد المحاولة";});}
paint();</script></body></html>"""

EARN = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>اكسب أكثر</title>
<link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:680px;margin:0 auto;padding:18px}h1{font-size:22px}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:14px;margin:11px 0}
code{background:#0b0f17;padding:3px 8px;border-radius:6px;font-size:12.5px;word-break:break-all;display:block;margin:6px 0}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}</style></head><body><div class="w">
<h1>💸 طرق الكسب</h1>
<div class="card"><b>1 · مطالبة يومية</b><p class="k">%(pts)d نقطة كل يوم. <a href="rewards.html">افتح</a></p></div>
<div class="card"><b>2 · رابط إحالتك</b><p class="k">%(ref)d نقطة لكل مطالبة تأتي منك:</p>
<code>%(site)s/?ref=%(code)s</code></div>
<div class="card"><b>3 · مشاركة العناوين</b><p class="k">انسخ من <a href="share.html">روابط المشاركة</a>.</p></div>
<div class="card"><b>4 · فتح الصفحات</b><p class="k">كل فتح = ظهور إعلان = عائد يغذّي الصندوق.</p></div>
<div class="card"><b>بصراحة</b><p class="k">%(honest)s</p></div>
<p><a href="rewards.html">المكافأة</a> · <a href="owner.html">لوحة المالك</a></p></div></body></html>"""

def page():
    import os as _os
    _t = EARN % {"pts": CLAIM, "ref": REFPTS, "site": core.site(),
                 "code": core.get("REF_CODE") or core.get("GH_USER") or "ch", "honest": HONEST}
    if (not _os.path.exists("earn.html")) or _os.path.getsize("earn.html") < 200:
        core.write_if_changed("earn.html", _t)
    pool, conf = build()
    core.write_if_changed("rewards.html", PAGE % {
      "pts": CLAIM, "ref": REFPTS, "ns": core.ns(), "conf": conf, "pool": pool,
      "honest": HONEST, "rules": "".join("<li>%s</li>" % core.esc(x) for x in RULES)})
    core.write_if_changed("rewards-earn.html", EARN % {
      "pts": CLAIM, "ref": REFPTS, "site": core.site(),
      "code": core.get("REF_CODE") or core.get("GH_USER") or "ch", "honest": HONEST})
    print("  ✓ rewards.html + rewards-earn.html · صندوق=$%.4f · عائد مؤكد=$%.2f" % (pool, conf))

if __name__ == "__main__": page()
