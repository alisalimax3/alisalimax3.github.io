#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  STATUS.sh — دخول كامل للتطبيق: فحص · تصنيف · تقرير · توصيات حقيقية
#  الاستخدام:  bash STATUS.sh          (فحص فقط — لا يعدّل شيئًا)
#              bash STATUS.sh fix      (فحص + إصلاح الحواجز الميكانيكية)
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data
LOG="logs/status.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
MODE="${1:-scan}"

cat > tools/status_report.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""دخول كامل: يفحص التطبيق ويصنّف الحواجز ويكتب STATUS-REPORT.md"""
import json, os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

B, W, OK = [], [], []
def blk(x): B.append(x)
def wrn(x): W.append(x)
def good(x): OK.append(x)

PAGES = ["index.html","app.html","adult.html","owner.html","income.html","networks.html",
         "adult-networks.html","rewards.html","rewards-earn.html","share.html",
         "promote-adult.html","sitemap.xml","robots.txt","rss.xml","hits.js","manifest.json"]
ENGINE = ["core.py","ads.py","revenue_engine.py","dashboard.py","growth.py","rewards.py",
          "adult_build.py","adult_promote.py","adult_registry.py","fix_pages.py","selftest.py",
          "adcheck.py","secrets.py","agent_lib.py","provider_discovery.py"]

def read(p, n=400000):
    try: return open(p, encoding="utf-8", errors="replace").read()[:n]
    except Exception: return ""

def scan():
    R = {"at": time.strftime("%F %H:%M:%S"), "cwd": os.getcwd()}
    # 1 · الملفات
    R["files"] = {}
    for p in PAGES: R["files"][p] = os.path.getsize(p) if os.path.exists(p) else None
    R["engine_present"] = [e for e in ENGINE if os.path.exists("tools/" + e)]
    R["engine_missing"] = [e for e in ENGINE if not os.path.exists("tools/" + e)]
    if R["engine_missing"]: blk("أدوات المحرك ناقصة: " + ", ".join(R["engine_missing"]))
    else: good("كل أدوات المحرك موجودة (%d)" % len(ENGINE))
    for p, sz in R["files"].items():
        if sz is None: blk("صفحة مفقودة: " + p)
        elif sz < 200: blk("صفحة فارغة/تالفة: %s (%d بايت)" % (p, sz))
    # 2 · الكود
    bad_mine, bad_old = [], []
    for f in sorted(os.listdir("tools")):
        if not f.endswith(".py"): continue
        r = subprocess.run([sys.executable, "-m", "py_compile", "tools/" + f], capture_output=True)
        if r.returncode: (bad_mine if f in ENGINE else bad_old).append(f)
    R["syntax_errors_engine"], R["syntax_errors_legacy"] = bad_mine, bad_old
    if bad_mine: blk("خطأ نحوي في أدوات المحرك: " + ", ".join(bad_mine))
    else: good("كل أدوات المحرك تُترجم بنجاح")
    if bad_old: wrn("خطأ نحوي في أدوات قديمة (لا يعطّل المحرك): " + ", ".join(bad_old))
    # 3 · الأخطاء التاريخية المعروفة
    re_src = read("tools/revenue_engine.py")
    if "oi.get(pid" in re_src: blk("BUG حاجب: revenue_engine.py يستخدم pid غير معرّف → يسقط 6 أدوات")
    elif re_src: good("revenue_engine.py سليم (pid مُصلح)")
    if re_src and '"fit_score"' not in re_src: wrn("fit_score لا يُحفظ بعد build() → ترتيب الملاءمة يُفقد")
    core_src = read("tools/core.py")
    if core_src and "def _owner" not in core_src: blk("core.py بلا _owner → نطاق العدّاد سيبقى anon")
    if re.search(r'\(\["\w+","[\w.]+","\w+"\]\)', read("tools/tasks.py")): pass
    # 4 · الأسرار والنطاق
    E = core.env()
    R["secrets_filled"] = sorted([k for k in E if (E[k] or "").strip()])
    R["secrets_empty"] = sorted([k for k in E if not (E[k] or "").strip()])
    own = core._owner() if hasattr(core, "_owner") else ""
    R["owner"], R["ns"], R["site"] = own, core.ns(), core.site()
    if not own: blk("GH_USER غير قابل للاستنباط → العدّاد والصفحات بلا هوية")
    else: good("المالك: " + own)
    if core.ns().endswith("-anon"): blk("نطاق العدّاد = anon → الأرقام تُكتب لنطاق خاطئ")
    # 5 · hits.js
    hj = read("hits.js")
    if not hj: blk("hits.js مفقود")
    else:
        if "__NS__" in hj: blk("hits.js ما زال يحمل __NS__ (لم يُستبدل)")
        if core.ns() not in hj and own: blk("hits.js لا يحمل النطاق الصحيح %s" % core.ns())
        if "uvtoday" in hj and "uniq-" not in hj: wrn("hits.js بلا عدّاد زوار فريدين")
        if hj and not B: good("hits.js سليم")
    # 6 · JSON
    badj = []
    for d in (".", "data", "go"):
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            if f.endswith(".json"):
                try: json.load(open(os.path.join(d, f), encoding="utf-8"))
                except Exception: badj.append(os.path.join(d, f))
    R["bad_json"] = badj
    if badj: blk("JSON تالف: " + ", ".join(badj))
    else: good("كل ملفات JSON سليمة")
    # 7 · الصفحات: RTL / إغلاق / عدّاد
    nor, nov, nob, tot = 0, 0, 0, 0
    for d in (".", "adult"):
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            if not f.endswith(".html"): continue
            tot += 1; s = read(os.path.join(d, f), 4000)
            if 'dir="rtl"' not in s: nor += 1
            if "viewport" not in s: nov += 1
            if "</body>" not in read(os.path.join(d, f)): nob += 1
    R["pages"] = {"total": tot, "no_rtl": nor, "no_viewport": nov, "no_body_close": nob}
    if nob: wrn("%d صفحة بلا </body>" % nob)
    if nor: wrn("%d صفحة بلا RTL" % nor)
    if tot and not (nor or nov or nob): good("كل الصفحات (%d) سليمة عربيًا وهيكليًا" % tot)
    # 8 · الكتالوج
    rows, src = core.catalog()
    R["catalog"] = {"total": len(rows), "source": src, "adult": len([r for r in rows if core.is_adult(r)])}
    if not rows: blk("لا كتالوج → لا صفحات")
    else: good("كتالوج: %d عنوان (%d إباحي) من %s" % (len(rows), R["catalog"]["adult"], src))
    # 9 · الإعلانات
    try:
        import ads
        n, on = ads.counts()
        R["ads"] = {"total": n, "enabled": on,
                    "enabled_ids": [x["id"] for x in ads.status() if x["on"]]}
        if on == 0: blk("صفر شبكة مفعّلة → صفر إعلان → صفر دخل")
        else: good("شبكات مفعّلة: %d (%s)" % (on, ", ".join(R["ads"]["enabled_ids"])))
    except Exception as e: blk("ads.py لا يعمل: %s" % e)
    # 10 · الدفتر والإيرادات
    try:
        import revenue_engine as RE
        r = RE.apply_ledger(); t = r["totals"]
        _, n, unconv, _ = RE.ledger_totals()
        R["ledger"] = {"tx": n, "unconverted": unconv, "totals": t, "gap": r["gap_usd"],
                       "with_keys": len([p for p in r["providers"] if p["credential_status"] == "present"])}
        if unconv: wrn("%d معاملة بلا سعر صرف → لا تُجمع" % unconv)
        good("الدفتر: %d معاملة · مستلم $%.2f · فجوة $%.2f" % (n, t["paid"], r["gap_usd"]))
    except Exception as e: blk("revenue_engine لا يعمل: %s" % e)
    # 11 · adcheck
    ac = core.load("data/adcheck.json", {}) or {}
    R["adcheck"] = ac.get("working", [])
    if R.get("ads", {}).get("enabled") and not R["adcheck"]:
        wrn("لم يُشغّل adcheck بعد — لا دليل أن الإعلان يُخدم")
    elif R["adcheck"]: good("رابط إعلان يستجيب: " + ", ".join(R["adcheck"]))
    # 12 · الوكيل
    try:
        pg = subprocess.run(["pgrep", "-f", "agentd.sh"], capture_output=True, text=True).stdout.strip()
        R["agent_running"] = bool(pg)
        if pg: good("الوكيل يعمل")
        else: wrn("الوكيل متوقف")
    except Exception: R["agent_running"] = None
    if os.path.exists("tools/tasks.py"):
        R["tasks"] = len([l for l in open("tools/tasks.py", encoding="utf-8")
                          if re.search(r'\(\s*"[^"]*"\s*,\s*"tools/', l)])
        good("مهام مجدولة: %d" % R["tasks"])
    # 13 · الموقع الحي
    s = core.site()
    if s:
        for u in (s + "/", s + "/index.html", s + "/owner.html", s + "/adult.html"):
            res = core.http(u, timeout=12)
            R.setdefault("live", {})[u] = res.get("code")
        codes = R["live"]
        if any(c == 200 for c in codes.values()): good("الموقع المنشور يستجيب")
        else: blk("الموقع المنشور لا يستجيب: %s" % codes)
    # 14 · git
    try:
        R["branch"] = subprocess.run(["git","rev-parse","--abbrev-ref","HEAD"],capture_output=True,text=True).stdout.strip()
        R["dirty"] = len(subprocess.run(["git","status","--porcelain"],capture_output=True,text=True).stdout.splitlines())
        R["last"] = subprocess.run(["git","log","-1","--format=%h %s"],capture_output=True,text=True).stdout.strip()[:70]
        good("Git: %s · تغييرات %d" % (R["branch"], R["dirty"]))
    except Exception: pass
    R["blockers"], R["warnings"], R["ok"] = B, W, OK
    core.save("data/status.json", R)
    return R

PROV = [("A-ADS","https://aads.com/earn/","AADS_UNIT","رصيد→BTC تلقائي","يقبل NSFW · بلا JS · حد تراخيص منخفض"),
        ("Adsterra","https://adsterra.com/publishers/","ADSTERRA_ZONE","$5","أسرع قبول (<10 دقائق)"),
        ("ExoClick","https://www.exoclick.com/publishers/","EXOCLICK_ZONE","$20","أعلى RPM إباحي"),
        ("JuicyAds","https://www.juicyads.com/signup","JUICYADS_ZONE","$25","أسبوعي · إحالة 20%"),
        ("PopAds","https://www.popads.net/","POPADS_SITE","$5","بوب أندر · سحب فوري"),
        ("PopCash","https://popcash.net/","POPCASH_SITE","$10","دفع يومي"),
        ("Stripchat","https://affiliates.stripchat.com/","STRIPCHAT_REF","$50","$1.50/تسجيل · أسرع لـ100$"),
        ("CrakRevenue","https://www.crakrevenue.com/","CRAKREVENUE_REF","$50","$168/تحويل"),
        ("Chaturbate","https://chaturbate.com/affiliates/","CHATURBATE_REF","$50","20% مدى الحياة")]

def write_report(R):
    L = ["# تقرير حالة CineHub 3099", "", "**%s** · الفرع `%s` · المالك `%s` · النطاق `%s`" %
         (R["at"], R.get("branch","?"), R.get("owner") or "—", R.get("ns")), ""]
    L += ["## الحواجز (%d) — تمنع الدخل أو العمل" % len(B), ""]
    L += ["%d. %s" % (i+1, x) for i, x in enumerate(B)] or ["لا حواجز."]
    L += ["", "## تحذيرات (%d)" % len(W), ""]
    L += ["- %s" % x for x in W] or ["لا تحذيرات."]
    L += ["", "## سليم (%d)" % len(OK), ""]
    L += ["- %s" % x for x in OK]
    L += ["", "## الحالة الرقمية", "",
          "| البند | القيمة |", "|---|---|",
          "| صفحات | %s |" % R.get("pages", {}).get("total"),
          "| كتالوج | %s عنوان (%s إباحي) |" % (R["catalog"]["total"], R["catalog"]["adult"]),
          "| شبكات مفعّلة | %s |" % R.get("ads", {}).get("enabled"),
          "| رابط إعلان يستجيب | %s |" % (", ".join(R.get("adcheck", [])) or "لا شيء"),
          "| معاملات الدفتر | %s |" % R.get("ledger", {}).get("tx"),
          "| فجوة 100$ | $%s |" % R.get("ledger", {}).get("gap"),
          "| أسرار مضبوطة | %s |" % len(R.get("secrets_filled", [])),
          "| الوكيل | %s |" % ("يعمل" if R.get("agent_running") else "متوقف"),
          "| مهام مجدولة | %s |" % R.get("tasks")]
    L += ["", "## الأسرار", "", "مضبوطة: `%s`" % "`, `".join(R.get("secrets_filled", [])) or "لا شيء",
          "", "ناقصة: `%s`" % "`, `".join(R.get("secrets_empty", [])[:30])]
    L += ["", "## ربط مواقع حقيقية — بالترتيب", "",
          "| # | الجهة | الرابط الرسمي | المفتاح للصقه في .env | حد السحب | لماذا |",
          "|---|---|---|---|---|---|"]
    for i, (n, u, k, m, w) in enumerate(PROV, 1):
        st = "مضبوط" if core.get(k) else "**ينتظر**"
        L.append("| %d | %s | %s | `%s` | %s | %s (%s) |" % (i, n, u, k, m, w, st))
    L += ["", "## تطويرات حقيقية مقترحة", "",
          "1. **`tools/watch.py`** — يقارن `adcheck.json` كل ساعة، وينبّه عند سقوط شبكة (توقف مصدر دخل = أكبر خطر صامت).",
          "2. **`tools/export.py`** — يصدّر الدفتر CSV ليتطابق مع تقارير الشبكات عند التدقيق.",
          "3. **`tools/geo.py`** — يقرأ تقارير الشبكات ويصنّف حسب البلد؛ RPM العربي منخفض لذا يستحق قياسًا منفصلًا.",
          "4. **صفحات hub حقيقية** — `/best.html` و`/new.html` بمحتوى من الكتالوج، ترفع الصفحات المفهرسة من 1 إلى مئات.",
          "5. **`data/fx.json` تلقائي** — تحديث سعر الصرف يوميًا لتصبح العملات قابلة للجمع بأمان.",
          "6. **Sitemap مقسّم** — `sitemap-adult.xml` + `sitemap.xml` لأن الكبار يفهرس ببطء."]
    L += ["", "## الخطوة التالية الواحدة", ""]
    L.append(B[0] if B else ("أول عائد: `python3 tools/revenue.py add aads 0.85 pending --id AADS-$(date +%F)`" if not core.get("AADS_UNIT") else "الربط التالي: Adsterra ($5 سحب، قبول 10 دقائق)"))
    open("STATUS-REPORT.md", "w", encoding="utf-8").write("\n".join(L) + "\n")

def main():
    R = scan(); write_report(R)
    print("\n%s══ الحواجز (%d) ══%s" % ("\033[31m", len(B), "\033[0m"))
    for i, x in enumerate(B, 1): print("  %d. %s" % (i, x))
    if not B: print("  لا حواجز")
    print("\n%s══ تحذيرات (%d) ══%s" % ("\033[33m", len(W), "\033[0m"))
    for x in W: print("  - %s" % x)
    if not W: print("  لا تحذيرات")
    print("\n%s══ سليم (%d) ══%s" % ("\033[32m", len(OK), "\033[0m"))
    for x in OK: print("  ✓ %s" % x)
    print("\n══ أرقام ══")
    print("  صفحات %s · كتالوج %s · شبكات مفعّلة %s · معاملات %s · فجوة $%s" % (
        R.get("pages", {}).get("total"), R["catalog"]["total"],
        R.get("ads", {}).get("enabled"), R.get("ledger", {}).get("tx"), R.get("ledger", {}).get("gap")))
    print("  الموقع الحي: %s" % (R.get("live") or "—"))
    print("\n  ✓ STATUS-REPORT.md · data/status.json")
    return 0

if __name__ == "__main__": sys.exit(main())
PYEOF
python3 -m py_compile tools/status_report.py || { echo "✗ خطأ في الأداة"; exit 1; }

if [ "$MODE" = "fix" ]; then
  printf '\n%s══ إصلاح الحواجز الميكانيكية ══%s\n' "$C" "$N"
  # نطاق صحيح في hits.js
  if [ -f .tmp/hits.tpl ]; then
    NSV="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.ns())")"
    sed "s/__NS__/$NSV/" .tmp/hits.tpl > hits.js && printf '  ✓ hits.js ← %s\n' "$NSV"
  elif grep -q '__NS__' hits.js 2>/dev/null; then
    NSV="$(python3 -c "import sys;sys.path.insert(0,'tools');import core;print(core.ns())")"
    sed -i "s/__NS__/$NSV/" hits.js && printf '  ✓ hits.js ← %s\n' "$NSV"
  fi
  for s in ads adult_build adult_registry growth rewards dashboard audit_full; do
    [ -f "tools/$s.py" ] && python3 "tools/$s.py" >/dev/null 2>&1 && printf '  ✓ %s\n' "$s"
  done
  python3 tools/status_report.py >/dev/null 2>&1
  printf '  ✓ أُعيد الفحص\n'
fi

python3 tools/status_report.py 2>&1 | tee -a "$LOG"
printf '\n%sالتقرير الكامل: STATUS-REPORT.md%s\n' "$B" "$N"
printf 'لإصلاح الحواجز آليًا: bash STATUS.sh fix\n'
