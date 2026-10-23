#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""لوحة تحكم HTML — بلا معامل % نهائياً"""
import html, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{background:#0b0f14;color:#e6edf3;font:14px/1.65 system-ui,-apple-system,sans-serif}
header{padding:24px 20px;background:linear-gradient(135deg,#0d1117,#161b22);border-bottom:1px solid #21262d}
h1{font-size:20px}.sub{color:#8b98a5;font-size:12px;margin-top:5px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(145px,1fr));gap:12px;padding:20px}
.card{background:#111823;border:1px solid #21262d;border-radius:10px;padding:15px}
.card .v{font-size:24px;font-weight:700}.card .l{color:#8b98a5;font-size:12px}
.g{color:#3fb950}.r{color:#f85149}.y{color:#d29922}.b{color:#58a6ff}
main{padding:0 20px 60px}h2{font-size:15px;margin:26px 0 9px;color:#58a6ff}
h2 .n{color:#8b98a5;font-size:12px;font-weight:400}
table{width:100%;border-collapse:collapse;background:#111823;border-radius:8px;overflow:hidden}
th,td{padding:7px 10px;text-align:right;border-bottom:1px solid #1c2128;font-size:12.5px}
th{background:#161b22;color:#8b98a5;font-weight:500}
tr.ok td:first-child{color:#3fb950}tr:not(.ok) td:first-child{color:#484f58}
.k{color:#8b98a5;font-family:monospace;font-size:11.5px}
footer{padding:20px;color:#8b98a5;font-size:11.5px;text-align:center}
"""

def build():
    s = registry.stats(); b = ledger.balances()
    hv = core.load("data/harvest.json", {})
    rows = []
    for cat, name in registry.CATS.items():
        items = registry.by_cat(cat)
        rows.append("<h2>" + html.escape(name) + ' <span class="n">' + str(len(items)) + "</span></h2><table>")
        rows.append("<tr><th>الحالة</th><th>المصدر</th><th>المفتاح</th><th>الحد</th><th>الرصيد</th></tr>")
        for n in items:
            has = bool(core.env(n["key_env"]))
            bal = b.get(n["id"], 0)
            rows.append('<tr class="' + ("ok" if has else "") + '"><td>' + ("✓" if has else "✗") +
                        "</td><td>" + html.escape(n["name"]) + '</td><td class="k">' +
                        html.escape(n["key_env"]) + "</td><td>$" + str(n["payout_min"]) +
                        "</td><td>" + (("$" + format(bal, ".2f")) if bal else "—") + "</td></tr>")
        rows.append("</table>")
    doc = ('<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">'
           '<meta name="viewport" content="width=device-width,initial-scale=1">'
           "<title>CineHub — لوحة الحصاد</title><style>" + CSS + "</style></head><body>"
           "<header><h1>💰 CineHub — لوحة الحصاد</h1><div class=\"sub\">آخر تحديث: " +
           time.strftime("%Y-%m-%d %H:%M") + " | رصيد الدفتر: $" + format(ledger.total(), ".2f") +
           "</div></header><div class=\"cards\">"
           '<div class="card"><div class="v">' + str(s["total"]) + '</div><div class="l">إجمالي المصادر</div></div>'
           '<div class="card"><div class="v g">' + str(s["with_key"]) + '</div><div class="l">مفاتيح مفعّلة</div></div>'
           '<div class="card"><div class="v y">' + str(s["pending"]) + '</div><div class="l">بانتظار التسجيل</div></div>'
           '<div class="card"><div class="v b">$' + format(ledger.total(), ".2f") + '</div><div class="l">رصيد مسجّل</div></div>'
           '<div class="card"><div class="v g">' + str(len(hv.get("ready", []))) + '</div><div class="l">جاهز للسحب</div></div>'
           "</div><main>" + "\n".join(rows) + "</main>"
           "<footer>يُحدّث تلقائياً كل 5 دقائق · " + time.strftime("%Y-%m-%d") + "</footer></body></html>")
    p = core.BASE / "dashboard.html"
    p.write_text(doc, encoding="utf-8")
    core.log("✓ dashboard.html (" + str(len(doc) // 1024) + " KB)", "ok")
    return str(p)

if __name__ == "__main__": print(build())
