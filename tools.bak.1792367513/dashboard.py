#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""owner.html — فصل صريح: تقديري · معلق · مؤكد · مرفوض · مستلم. لا جمع."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue_engine as RE

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>لوحة الإيرادات — CineHub 3099</title><meta name="robots" content="noindex">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1020px;margin:0 auto;padding:18px}h1{font-size:21px}h2{font-size:16px;color:#9fb0c6;margin-top:26px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(148px,1fr));gap:10px;margin:14px 0}
.b{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:12px}
.b .v{font-size:23px;font-weight:700}.b .l{font-size:12px;color:#8b96a8}
.paid .v{color:#39d98a}.appr .v{color:#5ca9ff}.pend .v{color:#e8c76a}.rej .v{color:#ff7b7b}.est .v{color:#9aa6b6}
table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}
a{color:#5ca9ff}.tag{padding:2px 8px;border-radius:20px;font-size:11.5px;border:1px solid}
.t-active{color:#39d98a;border-color:#1d5c3c;background:#0d2418}
.t-pending_approval,.t-pending_credentials{color:#e8c76a;border-color:#5c4a12;background:#241d08}
.t-unregistered{color:#8b96a8;border-color:#2a3341}
.t-suspended,.t-rejected,.t-blocked{color:#ff7b7b;border-color:#5c1d1d;background:#240d0d}
.k{color:#8b96a8;font-size:12.5px}code{background:#0b0f17;padding:2px 6px;border-radius:5px;font-size:12px}
.bar{height:8px;background:#1a2230;border-radius:6px;overflow:hidden;margin:8px 0}
.bar i{display:block;height:100%%;background:linear-gradient(90deg,#2f6df6,#39d98a)}
.warn{background:#1b1508;border:1px solid #3a2c08;color:#e8c76a;padding:10px;border-radius:10px;font-size:13px}</style>
</head><body><div class="w"><h1>📊 لوحة الإيرادات</h1>
<p class="k">آخر تحديث: %(upd)s · مصدر: دفتر بقيد فريد + محرك إزاءات · <b>لا جمع بين الحالات</b></p>
<div class="grid">
<div class="b paid"><div class="l">مستلم فعليًا</div><div class="v">$%(paid).2f</div></div>
<div class="b appr"><div class="l">مؤكد</div><div class="v">$%(appr).2f</div></div>
<div class="b pend"><div class="l">معلق</div><div class="v">$%(pend).2f</div></div>
<div class="b rej"><div class="l">مرفوض</div><div class="v">$%(rej).2f</div></div>
<div class="b est"><div class="l">تقديري (غير مؤكد)</div><div class="v">$%(est).2f</div></div>
</div>
<h2>التقدّم نحو 100$ (من المستلم فقط)</h2>
<div class="bar"><i style="width:%(pct).1f%%"></i></div>
<p class="k">$%(paid).2f / $100 · الفجوة $%(gap).2f</p>
<h2>أرقام حقيقية من السيرفر</h2>
<div class="grid">
<div class="b"><div class="l">زيارات اليوم</div><div class="v" data-hits="dv">…</div></div>
<div class="b"><div class="l">زوار فريدون اليوم</div><div class="v" data-hits="uvtoday">…</div></div>
<div class="b"><div class="l">مطالبات المكافآت</div><div class="v" data-hits="claims">…</div></div>
<div class="b"><div class="l">معاملات الدفتر</div><div class="v">%(txn)d</div></div>
</div>
<h2>المزودون (%(np)d) — مرتبون حسب الملاءمة</h2>
<table><tr><th>الجهة</th><th>النوع</th><th>المفتاح</th><th>اعتماد</th><th>الحالة</th><th>ملاءمة</th>
<th>معلق</th><th>مؤكد</th><th>مستلم</th><th>آخر نجاح/خطأ</th></tr>%(rows)s</table>
<h2>المكافآت</h2><p>الصندوق = 50%% من المؤكد = <b>$%(pool).4f</b> · الحالة <b>%(fstat)s</b></p>
<p class="k">%(honest)s</p>
<h2>التنبيهات</h2>%(alerts)s
<h2>الخطوات التالية</h2><ol>%(next)s</ol>
<div class="warn"><b>قاعدة:</b> %(rule)s<br>
<b>تنبيه:</b> «active» تعني وجود مفتاح، وليست دليل أرباح. التسجيل ≠ القبول.
الأسعار مقروءة من صفحات المزودين 2026-10-18.</div>
<p class="k"><a href="./">الرئيسية</a> · <a href="networks.html">المزودون</a> · <a href="providers.html">الترتيب</a> · <a href="rewards.html">المكافآت</a> · <a href="share.html">روابط</a></p>
</div><script src="hits.js" defer></script></body></html>"""

NEXT = [
 "سجّل في <b>Adsterra</b> (حد $5 · قبول <10 دقائق) → الصق ADSTERRA_ZONE → شغّل ENGINE.sh.",
 "سجّل في <b>ExoClick</b> → الصق EXOCLICK_ZONE (أعلى RPM إباحي).",
 "سجّل في <b>Stripchat/StripCash</b> واختر PPL ($1.50/تسجيل) → الصق STRIPCHAT_REF. أسرع طريق لـ100$.",
 "انشر من promote-adult.html و share.html في r/nsfw · r/porn · r/hentai.",
 "أنشئ توكن API في ExoClick → EXOCLICK_API_TOKEN → المزامنة تصير تلقائية.",
 "سجّل أول عائد: <code>python3 tools/revenue_engine.py add exoclick 5.20 approved --id EXO-1</code>",
]

def main():
    r = RE.apply_ledger(); t = r["totals"]
    _, n, unconv, _ = RE.ledger_totals()
    rw = core.load("data/rewards.json", {}) or {}
    provs = sorted(r["providers"], key=lambda p: -p.get("fit_score", 0))
    rows = ""
    for p in provs:
        cred = "✓ %s" % (p.get("credential_fingerprint") or "") if p["credential_status"] == "present" else '<span class="k">لا شيء</span>'
        rows += ("<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td>"
                 "<td><span class='tag t-%s'>%s</span></td><td>%s</td><td>$%.2f</td><td>$%.2f</td>"
                 "<td>$%.2f</td><td class='k'>%s %s</td></tr>"
                 % (core.esc(p["name"]), core.esc(p["type"]), core.esc(p["credential_env"]), cred,
                    p["account_status"], p["account_status"], p.get("fit_score", "-"),
                    p["pending"], p["approved"], p["paid"],
                    core.esc(p.get("last_ok_sync") or "—"), core.esc((p.get("last_error") or "")[:34])))
    al = core.load("data/alerts.json", {}) or {}
    op = [a for a in al.get("alerts", []) if a.get("open")]
    alerts = "".join("<div class='k'>• %s — %s</div>" % (core.esc(a["kind"]), core.esc(a["msg"])) for a in op[:10]) or "<div class='k'>لا تنبيهات</div>"
    core.write_if_changed("owner.html", TPL % {
      "upd": r["updated"], "paid": t["paid"], "appr": t["approved"], "pend": t["pending"],
      "rej": t["rejected"], "est": t["estimated"], "gap": r["gap_usd"], "pct": min(100.0, t["paid"]),
      "txn": n, "np": len(provs), "rows": rows, "pool": (rw.get("funding") or {}).get("pool_usd", 0.0),
      "fstat": (rw.get("funding") or {}).get("status", "—"), "honest": core.esc(rw.get("honest", "")),
      "alerts": alerts, "next": "".join("<li>%s</li>" % x for x in NEXT),
      "rule": core.esc(r["rules"][0] + " · " + r["rules"][1])})
    if unconv: print("  ! %d معاملة بلا سعر صرف" % unconv)
    print("  ✓ owner.html · مستلم=$%.2f · فجوة=$%.2f" % (t["paid"], r["gap_usd"]))

if __name__ == "__main__": main()
