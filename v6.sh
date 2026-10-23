#!/data/data/com.termux/files/usr/bin/bash
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p tools data logs/shots backups

echo "══ 0. نسخة احتياطية ══"
tar czf "backups/pre_v6_$(date +%s).tgz" tools data keys.env 2>/dev/null
echo "✓ محفوظة"

echo "══ 1. توحيد ledger (schema قديم → جديد) ══"
python3 - << 'PY'
import json, os
p = "data/ledger.json"
d = {}
if os.path.exists(p):
    try: d = json.load(open(p))
    except Exception: d = {}
if not isinstance(d, dict): d = {}
ent = d.get("entries", [])
if not isinstance(ent, list): ent = []
tx = d.get("tx", {})
if isinstance(tx, dict):
    for k, v in tx.items():
        if not isinstance(v, dict): continue
        ent.append({"site": v.get("provider","unknown"), "amount": float(v.get("amount_usd") or v.get("amount") or 0),
                    "kind": "earning", "currency": "USD",
                    "note": v.get("note","") or ("مُرحّل من schema قديم"),
                    "at": str(v.get("date","")) + " 00:00:00"})
seen, out = set(), []
for e in ent:
    kk = (e.get("site"), e.get("at"), e.get("amount"))
    if kk in seen: continue
    seen.add(kk); out.append(e)
json.dump({"schema": 3, "entries": out}, open(p,"w"), ensure_ascii=False, indent=2)
print("✓ رُحّل %d قيد" % len(out))
PY

echo "══ 2. UA مكتبي + توجيه CDP ══"
python3 - << 'PY'
p = "tools/core.py"
s = open(p, encoding="utf-8").read()
import re
s = re.sub(r'UA = \(.*?\)\n', '''UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
''', s, count=1, flags=re.S)
open(p,"w",encoding="utf-8").write(s)
print("✓ UA مكتبي")
PY

echo "══ 3. إعادة كتابة cdp.py (توجيه حقيقي مُتحقَّق) ══"
cat > tools/cdp.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CDP v6 — توجيه متحقَّق منه، UA مكتبي، تشخيص فشل واضح."""
from __future__ import annotations
import base64, json, os, shutil, socket, subprocess, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ARGS = [
    "--no-sandbox","--disable-dev-shm-usage","--disable-gpu",
    "--disable-blink-features=AutomationControlled",
    "--remote-allow-origins=*","--no-first-run","--no-default-browser-check",
    "--disable-features=IsolateOrigins,site-per-process",
    "--mute-audio","--window-size=1440,960",
    "--disable-background-timer-throttling",
    "--disable-backgrounding-occluded-windows","--disable-renderer-backgrounding",
    "--disable-popup-blocking","--disable-ipc-flooding-protection",
    "--force-device-scale-factor=1",
]

INJECT = None
def inject_src():
    global INJECT
    if INJECT is None:
        INJECT = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"inject.js"), encoding="utf-8").read()
    return INJECT

def find_chromium():
    for n in ("chromium-browser","chromium","chrome"):
        p = shutil.which(n)
        if p: return p
    for p in ("/data/data/com.termux/files/usr/bin/chromium-browser",
              "/data/data/com.termux/files/usr/bin/chromium"):
        if os.path.exists(p): return p
    return None

def version():
    e = find_chromium()
    if not e: return "—"
    try: return subprocess.check_output([e,"--version"], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception: return "—"

def free_port():
    s = socket.socket(); s.bind(("127.0.0.1",0)); p = s.getsockname()[1]; s.close(); return p

def x11(): return bool(os.environ.get("DISPLAY"))

class Chrome:
    def __init__(self, profile_dir, headless=True, port=None, timeout=50, proxy="", debug=False):
        self.exe = find_chromium()
        if not self.exe: raise RuntimeError("chromium غير مثبت — pkg install chromium")
        self.port = port or free_port()
        os.makedirs(profile_dir, exist_ok=True)
        a = [self.exe, "--remote-debugging-port=%d" % self.port, "--user-data-dir=%s" % profile_dir] + ARGS
        if proxy: a.append("--proxy-server=" + proxy)
        if headless: a.append("--headless=new")
        if debug: a.append("--enable-logging=stderr")
        self.logp = os.path.join(profile_dir, "chromium.log")
        self.lf = open(self.logp, "ab")
        self.proc = subprocess.Popen(a, stdout=self.lf, stderr=self.lf,
                                     stdin=subprocess.DEVNULL, start_new_session=True)
        self._wait(timeout)

    def _get(self, path, method="GET"):
        req = urllib.request.Request("http://127.0.0.1:%d%s" % (self.port, path), method=method)
        with urllib.request.urlopen(req, timeout=6) as r:
            return json.loads(r.read().decode("utf-8","ignore"))

    def _wait(self, timeout):
        end = time.time()+timeout
        while time.time() < end:
            try: self._get("/json/version"); return
            except Exception:
                if self.proc.poll() is not None:
                    tail = ""
                    try: tail = open(self.logp, encoding="utf-8", errors="ignore").read()[-800:]
                    except Exception: pass
                    raise RuntimeError("chromium خرج فوراً:\n" + tail)
                time.sleep(0.4)
        raise RuntimeError("مهلة تشغيل chromium")

    def tab(self):
        try: targets = self._get("/json/list")
        except Exception: targets = []
        for t in targets:
            if t.get("type")=="page" and t.get("webSocketDebuggerUrl") and "devtools" not in (t.get("url") or ""):
                return Tab(t["webSocketDebuggerUrl"])
        try: t = self._get("/json/new?about:blank","PUT")
        except Exception: t = self._get("/json/new?about:blank","GET")
        return Tab(t["webSocketDebuggerUrl"])

    def close(self):
        try: self.proc.terminate(); self.proc.wait(timeout=10)
        except Exception:
            try: self.proc.kill()
            except Exception: pass
        try: self.lf.close()
        except Exception: pass

class Tab:
    def __init__(self, ws_url, timeout=120):
        import websocket
        self.ws = websocket.create_connection(ws_url, timeout=timeout,
                                              suppress_origin=True, max_size=200*1024*1024)
        self._id = 0
        for m in ("Page.enable","Runtime.enable","Network.enable"):
            self.send(m)
        try:
            self.send("Emulation.setUserAgentOverride",
                      {"userAgent": core.UA, "acceptLanguage":"en-US,en;q=0.9","platform":"Win32"})
            self.send("Emulation.setDeviceMetricsOverride",
                      {"width":1440,"height":960,"deviceScaleFactor":1,"mobile":False})
        except Exception: pass
        try:
            self.send("Page.addScriptToEvaluateOnNewDocument",
                      {"source":"Object.defineProperty(navigator,'webdriver',{get:function(){return undefined;}});"
                                "window.chrome=window.chrome||{runtime:{}};"})
        except Exception: pass

    def send(self, method, params=None):
        self._id += 1; mid = self._id
        self.ws.send(json.dumps({"id":mid,"method":method,"params":params or {}}))
        while True:
            msg = json.loads(self.ws.recv())
            if msg.get("id") == mid:
                if "error" in msg:
                    raise RuntimeError("%s: %s" % (method, msg["error"].get("message")))
                return msg.get("result", {})

    def ev(self, expr):
        r = self.send("Runtime.evaluate", {"expression":expr,"returnByValue":True,"awaitPromise":True})
        res = r.get("result", {})
        if res.get("subtype") == "error": raise RuntimeError(res.get("description","JS error"))
        return res.get("value")

    def hook(self):
        try:
            if not self.ev("typeof window.__ch !== 'undefined'"): self.ev(inject_src())
        except Exception: pass

    def go(self, url, timeout=50, retries=2):
        host = urllib.parse.urlparse(url).netloc
        for attempt in range(retries+1):
            try:
                r = self.send("Page.navigate", {"url": url})
                if r.get("errorText"): core.log("navigate: %s" % r["errorText"], "warn")
            except Exception as e:
                core.log("navigate فشل: %s" % e, "warn")
            if self._wait_host(host, timeout):
                return True
            core.log("محاولة %d/%d لم تصل إلى %s" % (attempt+1, retries+1, host), "warn")
            time.sleep(2)
        return False

    def _wait_host(self, host, timeout):
        end = time.time()+timeout
        while time.time() < end:
            try:
                cur = self.ev("location.href") or ""
                if host and host in cur:
                    if self.ev("document.readyState") == "complete":
                        time.sleep(1.2); self.hook(); return True
            except Exception: pass
            time.sleep(0.4)
        return False

    def url(self):
        try: return self.ev("location.href")
        except Exception: return ""
    def title(self):
        try: return self.ev("document.title") or ""
        except Exception: return ""
    def text(self, n=20000):
        try: return (self.ev("document.body ? document.body.innerText : ''") or "")[:n]
        except Exception: return ""
    def html(self):
        try: return self.ev("document.documentElement.outerHTML") or ""
        except Exception: return ""

    def shot(self, path):
        r = self.send("Page.captureScreenshot", {"format":"png"})
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path,"wb").write(base64.b64decode(r["data"]))
        return path

    def dump(self, tag):
        d = core.LOGS / "shots"
        d.mkdir(parents=True, exist_ok=True)
        p = str(d / ("%s_%s" % (tag, time.strftime("%H%M%S"))))
        try: self.shot(p + ".png")
        except Exception: pass
        try: open(p + ".html","w",encoding="utf-8").write(self.html())
        except Exception: pass
        core.log("تشخيص محفوظ: %s.png/.html" % p, "info")
        return p
PYEOF

echo "══ 4. إصلاح IMAP (مسافات + تعدد الأسماء) ══"
python3 - << 'PY'
p = "tools/mailbox.py"
s = open(p, encoding="utf-8").read()
s = s.replace(
'''def fetch(since_min=45, limit=25):
    host, user, pw = core.env("MAIL_IMAP_HOST"), core.env("MAIL_USER"), core.env("MAIL_APP_PASS")
    if not (host and user and pw): return []
    try:
        m = imaplib.IMAP4_SSL(host, 993); m.login(user, pw); m.select("INBOX")''',
'''def creds():
    host = core.env("MAIL_IMAP_HOST") or "imap.gmail.com"
    user = core.env("MAIL_USER") or core.env("MY_EMAIL") or core.env("GMAIL_USER")
    pw = (core.env("MAIL_APP_PASS") or core.env("GMAIL_APP_PASS") or core.env("MAIL_PASS") or "")
    pw = pw.replace(" ", "").replace("-", "").strip()
    return host, user, pw

def test():
    host, user, pw = creds()
    if not (user and pw): return False, "MAIL_USER / MAIL_APP_PASS فارغان"
    try:
        m = imaplib.IMAP4_SSL(host, 993, timeout=20); m.login(user, pw); m.select("INBOX"); m.logout()
        return True, "دخول IMAP ناجح: %s" % user
    except Exception as e:
        return False, "IMAP: %s" % e

def fetch(since_min=45, limit=25):
    host, user, pw = creds()
    if not (host and user and pw): return []
    try:
        m = imaplib.IMAP4_SSL(host, 993, timeout=25); m.login(user, pw); m.select("INBOX")''')
s = s.replace('return bool(core.env("MAIL_IMAP_HOST") and core.env("MAIL_USER") and core.env("MAIL_APP_PASS"))',
              'return all(creds())')
open(p,"w",encoding="utf-8").write(s)
print("✓ mailbox مصحّح")
PY

echo "══ 5. autoreg: كشف فشل التوجيه + تشخيص ══"
python3 - << 'PY'
p = "tools/autoreg.py"
s = open(p, encoding="utf-8").read()
s = s.replace('''        tab = ch.tab()
        tab.go(net["signup"])
        tab.ev("window.__ch && window.__ch.cookies()")
        core.log("الصفحة: %s" % (tab.title() or "")[:60], "info")''',
'''        tab = ch.tab()
        ok = tab.go(net["signup"], timeout=60)
        if not ok:
            core.log("فشل تحميل %s — تشخيص:" % net["signup"], "err")
            core.log("  العنوان الحالي: %s" % (tab.url() or "فارغ"), "err")
            tab.dump(net_id + "_fail")
            record(net, "nav_failed", note=tab.url())
            return False
        tab.ev("window.__ch && window.__ch.cookies()")
        core.log("الصفحة: %s" % (tab.title() or "(بلا عنوان)")[:70], "info")
        core.log("الحقول المرئية: %d" % len([f for f in (tab.ev("window.__ch.scan()") or []) if f.get("vis")]), "info")''')
s = s.replace('    headless = not (show and cdp.x11())',
              '    proxy = core.env("BROWSER_PROXY")\n    headless = not (show and cdp.x11())')
s = s.replace('ch = cdp.Chrome(str(core.DATA / "profiles" / net_id), headless=headless)',
              'ch = cdp.Chrome(str(core.DATA / "profiles" / net_id), headless=headless, proxy=proxy)')
open(p,"w",encoding="utf-8").write(s)
print("✓ autoreg مصحّح")
PY

# ===================== tools/audit.py =====================
cat > tools/audit.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص شامل حقيقي للتطبيق — يخبرك بالضبط ما ينقص"""
import importlib.util, json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, mailbox, cdp

OK, BAD, WARN = [], [], []

def h(t): print("\n%s%s══ %s ══%s" % (core.C['b'], core.C['info'], t, core.C['x']))
def good(m): OK.append(m); core.log(m, "ok")
def bad(m):  BAD.append(m); core.log(m, "err")
def warn(m): WARN.append(m); core.log(m, "warn")

def main():
    print("%s%s\n╔══════════════════════════════════════════════════════════╗"
          "\n║        🔬 CineHub — فحص شامل حقيقي                       ║"
          "\n╚══════════════════════════════════════════════════════════╝%s" % (core.C['b'], core.C['info'], core.C['x']))

    h("1. بنية المشروع")
    for d in ("tools","data","logs","assets","content"):
        (core.BASE/d).is_dir() and good("مجلد: %s" % d) or bad("مفقود: %s" % d)
    need = ["core.py","cdp.py","inject.js","registry.py","autoreg.py","agent.py",
            "ledger.py","payout.py","mailbox.py","doctor.py"]
    for f in need:
        p = core.BASE/"tools"/f
        if not p.exists(): bad("سكربت مفقود: tools/%s" % f); continue
        if f.endswith(".py"):
            r = subprocess.run([sys.executable,"-m","py_compile",str(p)], capture_output=True)
            good("سليم: tools/%s" % f) if not r.returncode else bad("مكسور: tools/%s" % f)
        else: good("موجود: tools/%s" % f)

    h("2. الاعتماديات")
    for mod, pkg in {"websocket":"websocket-client","requests":"requests","bs4":"beautifulsoup4","lxml":"lxml"}.items():
        importlib.util.find_spec(mod) and good("%s مثبّت" % pkg) or bad("%s مفقود → pip install %s" % (pkg, pkg))
    importlib.util.find_spec("playwright") and good("playwright موجود (غير مطلوب)") or warn("playwright غائب — لا يضر")

    h("3. المتصفح الحقيقي")
    exe = cdp.find_chromium()
    if not exe: bad("chromium غير مثبت → pkg install chromium")
    else:
        good("chromium: %s" % cdp.version())
        core.log("المسار: %s" % exe, "info")

    h("4. الشاشة (لعرض المتصفح)")
    if cdp.x11():
        good("DISPLAY=%s — الوضع المرئي متاح" % core.env("DISPLAY"))
    else:
        warn("DISPLAY غير مضبوط — يعمل headless فقط")
        print("    للتفعيل: pkg install x11-repo && pkg install termux-x11-nightly")
        print("    ثم: termux-x11 :0 -ac & ; export DISPLAY=:0")

    h("5. الهوية")
    pr = core.load("data/profile.json")
    for k in ("first","last","username","email","country","site"):
        pr.get(k) and good("%s = %s" % (k, pr[k])) or bad("ناقص: %s" % k)
    if pr.get("password"): good("كلمة المرور مُولّدة (%d حرف)" % len(pr["password"]))
    else: bad("لا كلمة مرور")

    h("6. المفاتيح")
    kv = {}
    if core.ENV_FILE.exists():
        for line in core.ENV_FILE.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.strip().startswith("#"):
                k,v = line.split("=",1); kv[k.strip()] = v.strip()
    secret = {"MAIL_APP_PASS","CAPTCHA_KEY","SMTP_PASS"}
    for k,v in kv.items():
        if k in secret:
            good("%s = %s" % (k, ("*"*len(v) if v else "فارغ"))) if v else bad("%s فارغ" % k)
        else:
            good("%s = %s" % (k, v or "فارغ"))
    good("مصادر مفاتيح مُعبّأة: %d/%d" % (len(registry.with_key()), len(registry.ALL)))

    h("7. البريد التلقائي")
    okm, msg = mailbox.test()
    good(msg) if okm else bad(msg)
    if not okm:
        print("    → https://myaccount.google.com/apppasswords  (الصقها بلا مسافات)")
        print("    → ثم: ./run.sh setenv MAIL_APP_PASS xxxxxxxxxxxxxxxx")

    h("8. الشبكة")
    for url in ("https://publishers.adsterra.com/register","https://monetag.com","https://picoworkers.com/register.php"):
        r = core.http(url, timeout=15)
        good("%s → %s" % (url.split("//")[1][:32], r.get("code"))) if r.get("ok") else bad("%s → %s" % (url.split("//")[1][:32], r.get("err","فشل")))

    h("9. اختبار متصفح فعلي")
    try:
        ch = cdp.Chrome(str(core.DATA/"profiles"/"_audit"), headless=True, timeout=45)
        try:
            t = ch.tab()
            if t.go("https://example.com", timeout=35):
                good("تصفح ناجح — العنوان: %s" % (t.title() or "(فارغ)"))
                good("__ch محقون: %s" % ("نعم" if t.ev("typeof window.__ch!=='undefined'") else "لا"))
            else:
                bad("فشل التصفح — راجع data/profiles/_audit/chromium.log")
                try: print(open(str(core.DATA/"profiles"/"_audit"/"chromium.log"),encoding="utf-8",errors="ignore").read()[-500:])
                except Exception: pass
        finally: ch.close()
    except Exception as e:
        bad("تعذّر تشغيل المتصفح: %s" % e)

    h("10. الأرباح")
    b = ledger.balances()
    good("قيود: %d | الإجمالي: $%.2f" % (len(ledger._d()["entries"]), ledger.total()))
    for s,v in b.items(): print("    %-16s $%.2f" % (s, v))

    h("الخلاصة")
    core.log("ناجح: %d | تحذير: %d | عطل: %d" % (len(OK), len(WARN), len(BAD)), "err" if BAD else ("warn" if WARN else "ok"))
    if BAD:
        print("\n%sيجب إصلاح:%s" % (core.C['err'], core.C['x']))
        for i,m in enumerate(BAD,1): print("  %d. %s" % (i,m))
    if WARN:
        print("\n%sاختياري لكن يُحسّن:%s" % (core.C['warn'], core.C['x']))
        for i,m in enumerate(WARN,1): print("  %d. %s" % (i,m))
    if not BAD and not WARN: print("\n%sالنظام كامل وجاهز للتنفيذ الحقيقي.%s" % (core.C['ok'], core.C['x']))
    return 0 if not BAD else 2

if __name__ == "__main__": sys.exit(main())
PYEOF

echo "══ 6. أمر audit + setenv في agent ══"
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
s = s.replace('    elif c == "doctor":',
'''    elif c == "audit":
        import audit; audit.main()
    elif c == "setenv":
        core.set_env(a[1], a[2]); core.log("%s حُفظ" % a[1], "ok")
    elif c == "doctor":''')
s = s.replace('  doctor                  فحص شامل', '  doctor                  فحص سريع\n  audit                   فحص شامل حقيقي\n  setenv <KEY> <value>    تعيين مفتاح')
open(p,"w",encoding="utf-8").write(s)
print("✓ agent")
PY

echo "══ 7. تحييد AGENT-UNIFIED القديم ══"
if [ -f AGENT-UNIFIED.sh ]; then
  mv AGENT-UNIFIED.sh AGENT-UNIFIED.old.sh
  cat > AGENT-UNIFIED.sh << 'AEOF'
#!/data/data/com.termux/files/usr/bin/bash
# نسخة موحّدة — تفوّض كل شيء إلى الوكيل الجديد
cd "$HOME/cinehub3099"
case "${1:-help}" in
  install|setup|fix|repair) python3 tools/doctor.py ;;
  audit) python3 tools/audit.py ;;
  status) python3 tools/agent.py status ;;
  auto|pilot) python3 tools/agent.py auto ;;
  vpn|connect) bash vpn.sh ;;
  run|start) shift; python3 tools/agent.py reg "$@" ;;
  *) echo "install|audit|status|auto|run <id>|vpn" ;;
esac
AEOF
  chmod +x AGENT-UNIFIED.sh
  echo "✓ AGENT-UNIFIED.sh صار غلافاً موحّداً"
fi

echo "══ 8. اختبار ══"
python3 -m py_compile tools/*.py && echo "✓ كل الملفات تُترجم"
