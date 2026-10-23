#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""طابور 20 مهمة بفواصل زمنية — ينفّذ المستحق فقط ويسجّل النتيجة"""
import json, os, subprocess, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
M = 60
T = [
    ("عدّاد فوري", "tools/hits_report.py", 15*M),
    ("الخزينة", "tools/vault.py", 15*M),
    ("الأموال", "tools/money.py", 15*M),
    ("زيارات حقيقية", "tools/revenue_sync.py", 30*M),
    ("اللوحة", "tools/dashboard.py", 30*M),
    ("فهرسة سريعة", "tools/indexnow_new.py", 30*M),
    ("روابط النشر", "tools/share.py", 60*M),
    ("ترويج QR", "tools/promote.py", 60*M),
    ("أرشفة", "tools/wayback_new.py", 120*M),
    ("سجل الدخل", "tools/earn.py", 180*M),
    ("سجل المنصات", "tools/platforms_page.py", 180*M),
    ("hubs", "tools/hubs.py", 180*M),
    ("SEO تدريجي", "tools/seo.py", 240*M),
    ("إصلاح الروابط", "tools/linkfix.py", 360*M),
    ("إشعار ping", "tools/ping.py", 60*M),
    ("إثبات", "tools/proof.py", 360*M),
    ("قسم إباحي", "tools/adult_build.py", 360*M),
    ("شبكات إباحية", "tools/adult_ads.py", 120*M),
    ("ترويج إباحي", "tools/adult_promote.py", 180*M),
    ("سجل إباحي", "tools/adult_registry.py", 720*M),
    ("محرك إيرادات", "tools/revenue_engine.py", 240*M),
    ("اكتشاف مزودين", "tools/provider_discovery.py", 1440*M),
    ("نمو", "tools/growth.py", 360*M),
    ("مكافآت", "tools/rewards.py", 720*M),
    ("تحقق شامل", "tools/selftest.py", 360*M),
    ("تحقق بصمات", "VERIFY.sh", 720*M),
    ("فحص إعلانات", "tools/adcheck.py", 720*M),
    ("توسيع", "tools/expand_pages.py", 1440*M),
    ("وكيل تسجيل", "tools/agent_register.py", 1440*M),
    ("خزينة", "tools/custody.py", 360*M),
]
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
st = rd("data/tasks.json", {"runs": 0, "log": []})
now = time.time(); done = []
for name, cmd, every in T:
    if now - st.get("last", {}).get(name, 0) < every: continue
    t0 = time.time()
    try:
        run = ("bash " if cmd.endswith(".sh") else "python3 ") + cmd
        p = subprocess.run(run, shell=True, capture_output=True, text=True, timeout=900)
        out = ((p.stdout or "") + (p.stderr or "")).strip().splitlines()
        done.append({"t": name, "ok": p.returncode == 0, "s": round(time.time() - t0, 1), "msg": (out[-1][:110] if out else "")})
    except Exception as e:
        done.append({"t": name, "ok": False, "s": round(time.time() - t0, 1), "msg": str(e)[:110]})
    st.setdefault("last", {})[name] = now
st["runs"] = st.get("runs", 0) + 1; st["at"] = time.strftime("%F %H:%M")
st["log"] = (done + st.get("log", []))[:80]
json.dump(st, open("data/tasks.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ %d مهمة (دورة %d) من %d" % (len(done), st["runs"], len(T)))
for d in done: print("    %s %-16s %5.1fs %s" % ("✓" if d["ok"] else "✗", d["t"], d["s"], d["msg"][:64]))
