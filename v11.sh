#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"
mkdir -p tools .github/workflows backups
tar czf "backups/pre_v11_$(date +%s).tgz" tools keys.env 2>/dev/null

# ══════════ ghauth: تفويض GitHub مباشر (Device Flow) ══════════
cat > tools/ghauth.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تفويض GitHub مباشر — Device Flow بلا نسخ توكن"""
import json, os, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

CLIENT = "178c6fc778ccc68e1d6a"   # GitHub CLI public client
DEVICE = "https://github.com/login/device/code"
TOKEN  = "https://github.com/login/oauth/access_token"
UA = {"User-Agent": "cinehub-agent", "Accept": "application/json"}

def _post(url, data):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, data=body, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())

def device_flow(scope="repo,workflow"):
    d = _post(DEVICE, {"client_id": CLIENT, "scope": scope})
    if "device_code" not in d:
        core.log("فشل بدء التفويض: %s" % d, "err"); return ""
    print("\n%s══ تفويض GitHub ══%s" % (core.C['b'], core.C['info'], core.C['x']))
    print("  1) افتح: %s%s%s" % (core.C['b'], d["verification_uri"], core.C['x']))
    print("  2) أدخل الرمز: %s%s%s" % (core.C['b'], d["user_code"], core.C['x']))
    print("  3) اضغط Authorize\n")
    core.openurl(d["verification_uri"])
    core.clipset(d["user_code"])
    core.log("الرمز نُسخ للحافظة","info")
    interval = d.get("interval", 5); end = time.time() + d.get("expires_in", 900)
    while time.time() < end:
        time.sleep(interval)
        try:
            t = _post(TOKEN, {"client_id": CLIENT, "device_code": d["device_code"],
                              "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        except Exception as e:
            core.log("انتظار... %s" % str(e)[:50], "warn"); continue
        if t.get("access_token"):
            core.log("✓ تم التفويض","ok"); return t["access_token"]
        err = t.get("error")
        if err == "authorization_pending": continue
        if err == "slow_down": interval += 5; continue
        if err in ("expired_token","access_denied"):
            core.log("انتهى/رُفض: %s" % err, "err"); return ""
        core.log("انتظار... %s" % err, "info")
    core.log("انتهت المهلة","err"); return ""

def whoami(token):
    req = urllib.request.Request("https://api.github.com/user",
        headers={"Authorization":"token "+token,"User-Agent":"cinehub-agent","Accept":"application/json"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        return {"_err": str(e)[:90]}

def authorize():
    tok = core.env("GITHUB_TOKEN")
    if tok:
        u = whoami(tok)
        if "login" in u:
            core.log("توكن محفوظ صالح: %s" % u["login"], "ok")
            return tok, u["login"]
    tok = device_flow()
    if not tok: return "", ""
    u = whoami(tok)
    if "login" not in u:
        core.log("توكن غير صالح: %s" % u.get("_err","?"), "err"); return "", ""
    core.set_env("GITHUB_TOKEN", tok)
    core.set_env("GITHUB_USER", u["login"])
    core.log("✓ %s مرتبط ومحفوظ" % u["login"], "ok")
    return tok, u["login"]
PYEOF

# ══════════ ghlink: إنشاء المستودع + الدفع + تفعيل Actions ══════════
cat > tools/ghlink.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ربط حساب GitHub: مستودع + دفع + تفعيل المحرّك"""
import json, os, subprocess, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ghauth, repo

def api(path, method="GET", data=None, token=""):
    req = urllib.request.Request("https://api.github.com"+path, method=method,
        data=json.dumps(data).encode() if data is not None else None,
        headers={"Authorization":"token "+token,"User-Agent":"cinehub-agent",
                 "Accept":"application/vnd.github+json","Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.getcode(), json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        try: return e.code, json.loads(e.read().decode() or "{}")
        except Exception: return e.code, {}
    except Exception as e:
        return 0, {"_err": str(e)[:100]}

def link(name="cinehub3099", private=True):
    tok, user = ghauth.authorize()
    if not tok: return False
    code, me = api("/user", token=tok)
    if code != 200:
        core.log("التوكن لا يملك صلاحية repo — أعد التفويض", "err"); return False
    user = me.get("login", user)

    code, r = api("/repos/%s/%s" % (user, name), token=tok)
    if code == 404:
        core.log("إنشاء مستودع %s/%s ..." % (user, name), "info")
        code, r = api("/user/repos", "POST", {"name":name,"private":private,
                      "description":"CineHub earnings engine","auto_init":False}, tok)
        if code not in (200,201):
            core.log("فشل الإنشاء: %s" % r.get("message","?"), "err"); return False
        core.log("✓ أُنشئ المستودع", "ok")
        time.sleep(2)
    else:
        core.log("المستودع موجود", "ok")

    url = "https://%s:%s@github.com/%s/%s.git" % (user, tok, user, name)
    subprocess.run(["git","remote","remove","origin"], cwd=str(core.BASE),
                   capture_output=True)
    subprocess.run(["git","remote","add","origin",url], cwd=str(core.BASE))
    subprocess.run(["git","config","user.email", core.env("MAIL_USER") or "agent@local"], cwd=str(core.BASE))
    subprocess.run(["git","config","user.name", user], cwd=str(core.BASE))
    core.set_env("GITHUB_USER", user); core.set_env("GH_REPO", name)
    core.set_env("REPO_URL", "https://github.com/%s/%s.git" % (user, name))

    core.log("دفع الملفات...", "info")
    ok, msg = repo.push("initial: CineHub v11")
    core.log(msg, "ok" if ok else "err")
    if not ok: return False

    # تفعيل Actions
    code, wfs = api("/repos/%s/%s/actions/workflows" % (user, name), token=tok)
    if code == 200:
        for w in wfs.get("workflows", []):
            api("/repos/%s/%s/actions/workflows/%s/enable" % (user, name, w["id"]), "PUT", token=tok)
        core.log("✓ Actions مُفعّل (%d workflow)" % len(wfs.get("workflows", [])), "ok")
    else:
        core.log("Actions سيُفعّل بعد أول دفع — راجع تبويب Actions", "warn")

    api("/repos/%s/%s" % (user, name), "PATCH", {"has_issues":True,"has_wiki":False}, tok)
    print("\n%s══ تم الربط ══%s" % (core.C['b'], core.C['ok'], core.C['x']))
    print("  المستودع : https://github.com/%s/%s" % (user, name))
    print("  المحرّك   : https://github.com/%s/%s/actions" % (user, name))
    print("  الموقع    : https://%s.github.io/%s/" % (user, name))
    return True

def enable_pages():
    tok, user = ghauth.authorize()
    name = core.env("GH_REPO") or "cinehub3099"
    code, r = api("/repos/%s/%s/pages" % (user,name), "POST",
                  {"source":{"branch":"main","path":"/"}}, tok)
    if code in (201, 204, 409): core.log("✓ GitHub Pages مُفعّل: https://%s.github.io/%s/" % (user,name), "ok")
    else: core.log("Pages: %s" % r.get("message","?"), "warn")

if __name__ == "__main__":
    link()
PYEOF

# ══════════ captchatest ══════════
cat > tools/captchatest.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
def main():
    k = core.env("CAPTCHA_KEY")
    print("\n%s══ رمز الكابتشا ══%s" % (core.C['b'], core.C['info'], core.C['x']))
    if not k:
        print("""  غير مضبوط — الوكل يعمل بالنقر الآلي فقط.
  لتفعيل الحل التلقائي:
    1) https://2captcha.com  → أنشئ حساباً → أضف رصيداً ($3 تكفي ~1000 كابتشا)
    2) انسخ API Key من لوحة التحكم
    3) ./run.sh setenv CAPTCHA_KEY <المفتاح>""")
        return
    print("  الطول: %d" % len(k))
    r = core.http("https://2captcha.com/res.php?key=%s&action=getbalance&json=1" % k, timeout=25)
    try:
        d = json.loads(r["text"])
        if str(d.get("status")) == "1":
            core.log("✓ صالح — الرصيد: $%s" % d.get("request"), "ok")
        else:
            core.log("✗ خطأ: %s" % d.get("request"), "err")
    except Exception:
        core.log("✗ رد غير مفهوم: %s" % r["text"][:80], "err")
if __name__ == "__main__": main()
PYEOF

# ══════════ harvest: الحصاد الحقيقي ══════════
cat > tools/harvest.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""حصاد الأرباح — من الدفتر + مسح مباشر للوحات"""
import json, os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, repo
from registry import by_id

MONEY = re.compile(r'(?:USD|\$|€|£)\s?([0-9]{1,6}(?:\.[0-9]{1,2})?)')
REG = core.DATA / "registrations.json"

def registered():
    d = core.load(REG, {})
    return [k for k, v in d.items() if v.get("status") in ("registered","confirmed","key_set")]

def scan(limit=0):
    """يفتح لوحة كل شبكة مسجّلة ويحاول قراءة الرصيد"""
    import cdp
    ids = [i for i in registered() if i in registry.BY_ID][:limit or 999]
    if not ids: core.log("لا شبكات مسجّلة بعد","warn"); return {}
    found = {}
    core.log("مسح %d لوحة..." % len(ids), "info")
    for i in ids:
        n = by_id(i)
        prof = str(core.PROFILES / i)
        if not os.path.isdir(prof): continue
        try:
            ch = cdp.Chrome(prof, headless=True, timeout=45)
            try:
                t = ch.tab()
                if not t.go(n["payout_page"], timeout=60):
                    core.log("%s: تعذّر التحميل" % i, "warn"); continue
                txt = t.text(8000)
                nums = [float(x) for x in MONEY.findall(txt)]
                nums = [x for x in nums if 0 < x < 100000]
                if nums:
                    found[i] = max(nums)
                    core.log("%s → $%.2f" % (i, found[i]), "ok")
                else:
                    core.log("%s → لا رقم ظاهر" % i, "warn")
            finally: ch.close()
        except Exception as e:
            core.log("%s: %s" % (i, str(e)[:60]), "err")
        time.sleep(0.5)
    if found: core.save("data/scanned.json", {"at": time.strftime("%Y-%m-%d %H:%M"), "balances": found})
    return found

def report():
    b = ledger.balances(); reg = registered()
    print("\n%s╔══════════════════════════════════════════════════╗" % core.C['b'])
    print("║   💰 تقرير الحصاد — أموال حقيقية                  ║")
    print("╚══════════════════════════════════════════════════╝%s" % core.C['x'])
    print("\n  شبكات مسجّلة: %d | مصادر بمفاتيح: %d" % (len(reg), len(registry.with_key())))
    if not b:
        print("\n  لا أرباح مسجّلة بعد. سجّل ربحاً: ./run.sh earn <id> <مبلغ>")
        return
    ready = []
    print("\n  %-18s %10s %8s  %s" % ("المصدر","الرصيد","الحد","الحالة")); print("  "+"-"*54)
    for s, v in sorted(b.items(), key=lambda x: -x[1]):
        try: mn = by_id(s)["payout_min"]
        except Exception: mn = 0
        st = "✓ جاهز للسحب" if v >= mn else "ينقص $%.2f" % (mn-v)
        if v >= mn: ready.append((s,v,mn))
        print("  %-18s %10s %8s  %s" % (s, "$%.2f"%v, "$%g"%mn, st))
    print("  "+"-"*54)
    print("  %-18s %10s" % ("الإجمالي", "$%.2f" % ledger.total()))
    print("  %-18s %10s" % ("قابل للسحب الآن", "$%.2f" % sum(x[1] for x in ready)))
    out = {"at": time.strftime("%Y-%m-%d %H:%M"), "total": ledger.total(),
           "ready": [x[0] for x in ready], "balances": b}
    core.save("data/harvest.json", out)
    if ready: core.log("%d شبكة جاهزة للسحب — نفّذ: ./run.sh payout" % len(ready), "ok")

def ci():
    """يعمل داخل GitHub Actions"""
    report()
    return 0

if __name__ == "__main__":
    a = sys.argv[1:]
    if "--scan" in a: scan(int(a[a.index("--scan")+1]) if a.index("--scan")+1 < len(a) and a[a.index("--scan")+1].isdigit() else 0)
    if "--push" in a: core.log(repo.push("harvest")[1], "info")
    if "--ci" in a: sys.exit(ci())
    report()
PYEOF

# ══════════ dashboard ══════════
cat > tools/dashboard.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""لوحة تحكم HTML من البيانات الحقيقية"""
import html, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger

def build():
    s = registry.stats(); b = ledger.balances()
    reg = core.load("data/registrations.json", {})
    hv = core.load("data/harvest.json", {})
    keys = {n["id"]: bool(core.env(n["key_env"])) for n in registry.ALL}
    rows = []
    for cat, name in registry.CATS.items():
        items = registry.by_cat(cat)
        rows.append('<h2>%s <span class="n">%d</span></h2><table>' % (html.escape(name), len(items)))
        rows.append('<tr><th>الحالة</th><th>المصدر</th><th>المفتاح</th><th>الحد</th><th>الرصيد</th></tr>')
        for n in items:
            has = keys.get(n["id"])
            bal = b.get(n["id"], 0)
            st = 'ج<b>✓</b>' if has else '✗'
            rows.append('<tr class="%s"><td>%s</td><td>%s</td><td class="k">%s</td><td>$%g</td><td>%s</td></tr>'
                        % ("ok" if has else "", st, html.escape(n["name"]),
                           html.escape(n["key_env"]), n["payout_min"],
                           ("$%.2f" % bal) if bal else "—"))
        rows.append('</table>')
    doc = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>CineHub — لوحة الحصاد</title><style>
:root{--bg:#0b0f14;--c:#111823;--t:#e6edf3;--m:#8b98a5;--g:#3fb950;--r:#f85149;--y:#d29922;--b:#58a6ff}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:14px/1.6 system-ui,-apple-system,sans-serif}
header{padding:22px;background:linear-gradient(135deg,#0d1117,#161b22);border-bottom:1px solid #21262d}
h1{margin:0;font-size:20px}.sub{color:var(--m);font-size:12px;margin-top:4px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;padding:18px}
.card{background:var(--c);border:1px solid #21262d;border-radius:10px;padding:14px}
.card .v{font-size:24px;font-weight:700}.card .l{color:var(--m);font-size:12px}
.g{color:var(--g)}.r{color:var(--r)}.y{color:var(--y)}.b{color:var(--b)}
main{padding:0 18px 60px}h2{font-size:15px;margin:26px 0 8px;color:var(--b)}
h2 .n{color:var(--m);font-size:12px;font-weight:400}
table{width:100%;border-collapse:collapse;background:var(--c);border-radius:8px;overflow:hidden}
th,td{padding:7px 10px;text-align:right;border-bottom:1px solid #1c2128;font-size:12.5px}
th{background:#161b22;color:var(--m);font-weight:500}
tr.ok td:first-child{color:var(--g)}tr:not(.ok) td:first-child{color:#484f58}
.k{color:var(--m);font-family:monospace;font-size:11.5px}
footer{padding:18px;color:var(--m);font-size:11.5px;text-align:center}
</style></head><body>
<header><h1>💰 CineHub — لوحة الحصاد الحقيقية</h1>
<div class="sub">آخر تحديث: %s | رصيد الدفتر: $%.2f</div></header>
<div class="cards">
<div class="card"><div class="v">%d</div><div class="l">إجمالي المصادر</div></div>
<div class="card"><div class="v g">%d</div><div class="l">مفاتيح مفعّلة</div></div>
<div class="card"><div class="v y">%d</div><div class="l">بانتظار التسجيل</div></div>
<div class="card"><div class="v b">$%.2f</div><div class="l">رصيد مسجّل</div></div>
<div class="card"><div class="v g">%d</div><div class="l">جاهز للسحب</div></div>
</div><main>%s</main>
<footer>يُحدّث تلقائياً بواسطة المحرّك كل 5 دقائق · %s</footer>
</body></html>""" % (time.strftime("%Y-%m-%d %H:%M"), ledger.total(), s["total"], s["with_key"],
                     s["pending"], ledger.total(), len(hv.get("ready", [])),
                     "\n".join(rows), time.strftime("%Y-%m-%d"))
    p = core.BASE / "dashboard.html"
    p.write_text(doc, encoding="utf-8")
    core.log("✓ dashboard.html (%d KB)" % (len(doc)//1024), "ok")
    return str(p)

if __name__ == "__main__": print(build())
PYEOF

# ══════════ محرّك GitHub كل 5 دقائق ══════════
cat > .github/workflows/engine.yml << 'YEOF'
name: cinehub-engine
on:
  schedule: [{cron: "*/5 * * * *"}]
  workflow_dispatch:
  push: {paths: ["keys.env", "data/**"]}
permissions: {contents: write}
concurrency: {group: engine, cancel-in-progress: true}
jobs:
  engine:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: {fetch-depth: 0}
      - uses: actions/setup-python@v5
        with: {python-version: "3.12"}
      - name: تحقق من المفاتيح
        run: python3 tools/verify_keys.py || true
      - name: الحصاد
        run: python3 tools/harvest.py --ci || true
      - name: اللوحة
        run: python3 tools/dashboard.py || true
      - name: حفظ النتائج
        run: |
          git config user.name "cinehub-engine"
          git config user.email "engine@users.noreply.github.com"
          git add -A
          git diff --staged --quiet || git commit -m "engine: harvest $(date -u +%H:%M)"
          git push || true
YEOF

# ══════════ ربط الأوامر ══════════
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
if 'c == "ghlink"' not in s:
    s = s.replace('    elif c == "audit":',
'''    elif c == "ghauth": import ghauth; ghauth.authorize()
    elif c == "ghlink":
        import ghlink
        ghlink.link(p[0] if p else "cinehub3099")
        if "--pages" in a: ghlink.enable_pages()
    elif c == "captchatest": import captchatest; captchatest.main()
    elif c == "harvest":
        import harvest
        if "--scan" in a: harvest.scan()
        harvest.report()
        if "--push" in a: import repo; core.log(repo.push("harvest")[1],"info")
    elif c == "dashboard":
        import dashboard; dashboard.build()
        if "--push" in a: import repo; core.log(repo.push("dashboard")[1],"info")
    elif c == "audit":''')
    s = s.replace('  audit                   فحص شامل حقيقي',
'''  ghauth                  تفويض GitHub مباشر
  ghlink [اسم] [--pages]  إنشاء مستودع + دفع + تفعيل المحرّك
  captchatest             تحقق من رمز الكابتشا
  harvest [--scan] [--push]  حصاد الأرباح
  dashboard [--push]      توليد اللوحة
  audit                   فحص شامل حقيقي''')
    open(p,"w",encoding="utf-8").write(s)
print("✓ agent")
PY

# ══════════ run-all ══════════
cat > run-all.sh << 'REOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"
echo "╔══════════════════════════════════════════════════╗"
echo "║   CineHub — تنفيذ كامل متصل                       ║"
echo "╚══════════════════════════════════════════════════╝"
./run.sh check   || exit 1
./run.sh selftest|| exit 1
./run.sh mailtest
./run.sh captchatest
echo ""
echo "── ربط GitHub ──"
./run.sh ghlink cinehub3099
./run.sh dashboard --push
echo ""
echo "── تسجيل الشبكات الفورية ──"
./run.sh autoflow 1
./run.sh autoflow 2
echo ""
echo "── الحصاد ──"
./run.sh harvest --push
./run.sh table
echo ""
echo "✓ اكتمل — المزامنة: ./run.sh watch &"
REOF
chmod +x run-all.sh

echo ""
echo "══ التحقق الحقيقي: استيراد كل وحدة ══"
FAIL=0
for m in core cdp registry autoreg agent ledger payout mailbox captcha repo addkey watch autoflow verify_keys audit selftest mailtest ghauth ghlink captchatest harvest dashboard; do
  if python3 -c "import sys; sys.path.insert(0,'tools'); import $m" 2>/dev/null; then echo "  ✓ $m"
  else echo "  ✗ $m"; python3 -c "import sys; sys.path.insert(0,'tools'); import $m" 2>&1|tail -2; FAIL=1; fi
done
[ $FAIL -eq 0 ] && echo "✓ كل الوحدات سليمة" || echo "✗ فشل"
