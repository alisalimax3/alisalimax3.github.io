#!/data/data/com.termux/files/usr/bin/bash
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p tools data/profiles logs/shots

echo "══ 1. الاعتماديات (بلا playwright) ══"
pip install websocket-client 2>&1 | tail -2

echo "══ 2. إصلاح ledger التالف ══"
python3 - << 'PY'
import json, os
p = "data/ledger.json"
d = {}
if os.path.exists(p):
    try: d = json.load(open(p))
    except Exception: d = {}
if not isinstance(d, dict): d = {}
d.setdefault("entries", [])
json.dump(d, open(p, "w"), ensure_ascii=False, indent=2)
print("ledger.json =", d)
PY

echo "══ 3. إصلاح core.load ══"
python3 - << 'PY'
import re, io
p = "tools/core.py"
s = open(p, encoding="utf-8").read()
old = '''def load(name, default=None):
    p = _r(name)
    try:
        if p.exists(): return json.loads(p.read_text(encoding="utf-8"))
    except Exception as e: log(f"قراءة {p.name}: {e}", "warn")
    return {} if default is None else default'''
new = '''def load(name, default=None):
    p = _r(name)
    try:
        if p.exists() and p.stat().st_size > 0:
            d = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(d, dict) and isinstance(default, dict):
                for k, v in default.items(): d.setdefault(k, v)
            return d
    except Exception as e: log(f"قراءة {p.name}: {e}", "warn")
    return {} if default is None else default'''
assert old in s, "نمط core.load غير موجود"
open(p, "w", encoding="utf-8").write(s.replace(old, new))
print("core.load محصّن")
PY

# ===================== tools/inject.js =====================
cat > tools/inject.js << 'JSEOF'
(function(){
if (window.__ch) return;
function sig(el){
  var p=[];
  ['name','id','placeholder','aria-label','autocomplete','title','data-testid'].forEach(function(a){
    var v = el.getAttribute && el.getAttribute(a); if(v) p.push(String(v).toLowerCase());
  });
  try{ if(el.labels && el.labels.length) p.push(el.labels[0].innerText.toLowerCase()); }catch(e){}
  try{
    var pd = el.parentElement;
    if(pd){ var t=(pd.innerText||'').toLowerCase(); if(t.length<70) p.push(t); }
  }catch(e){}
  return p.join(' ');
}
function setVal(el,val){
  var P = el.tagName==='TEXTAREA' ? HTMLTextAreaElement.prototype
        : (el.tagName==='SELECT' ? HTMLSelectElement.prototype : HTMLInputElement.prototype);
  var d = Object.getOwnPropertyDescriptor(P,'value');
  try{ if(d && d.set) d.set.call(el,val); else el.value=val; }catch(e){ el.value=val; }
  el.dispatchEvent(new Event('input',{bubbles:true}));
  el.dispatchEvent(new Event('change',{bubbles:true}));
  el.dispatchEvent(new Event('blur',{bubbles:true}));
}
window.__ch = {
  scan: function(){
    var all = document.querySelectorAll('input,textarea,select');
    var out=[];
    for(var i=0;i<all.length;i++){
      var el=all[i]; el.setAttribute('data-ch', String(i));
      var r=el.getBoundingClientRect(), st=getComputedStyle(el);
      var vis = r.width>1 && r.height>1 && st.visibility!=='hidden' && st.display!=='none' && !el.disabled;
      out.push({ i:i, tag:el.tagName.toLowerCase(), type:(el.type||'').toLowerCase(),
                 sig: vis ? sig(el) : '', val: el.value||'', checked: !!el.checked, vis: vis,
                 opts: el.tagName==='SELECT' ? Array.prototype.slice.call(el.options,0,400).map(function(o){return o.text;}) : null });
    }
    return out;
  },
  put: function(i,v){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; setVal(el,v); return true; },
  putSel: function(i,needle){
    var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return '';
    var n=String(needle).toLowerCase();
    for(var k=0;k<el.options.length;k++){ var o=el.options[k];
      if((o.text||'').toLowerCase().indexOf(n)>=0 || (o.value||'').toLowerCase()===n){
        el.value=o.value; el.dispatchEvent(new Event('change',{bubbles:true})); return o.text; } }
    return '';
  },
  check: function(i){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; if(!el.checked) el.click(); return true; },
  submitBtn: function(){
    var pats=['sign up','signup','register','create account','create','join','submit','continue','next','get started','انشاء','تسجيل'];
    var els=document.querySelectorAll('button,input[type=submit],input[type=button],a[role=button],a.button');
    for(var i=0;i<els.length;i++){
      var el=els[i], r=el.getBoundingClientRect(); if(r.width<2||r.height<2) continue;
      var t=((el.innerText||'')+' '+(el.value||'')+' '+(el.getAttribute('aria-label')||'')).trim().toLowerCase();
      for(var p=0;p<pats.length;p++){ if(t.indexOf(pats[p])>=0){ el.setAttribute('data-ch-btn','1'); return t; } }
    }
    return '';
  },
  clickBtn: function(){ var b=document.querySelector('[data-ch-btn]'); if(!b) return false; try{b.scrollIntoView({block:'center'});}catch(e){} b.click(); return true; },
  captcha: function(){
    function v(sel,attr){ var e=document.querySelector(sel); if(!e) return ''; var x=e.getAttribute(attr)||e.value||''; return x; }
    var g=v('textarea[name="g-recaptcha-response"]','') || v('#g-recaptcha-response','');
    if(g && g.length>20) return 'recaptcha-solved';
    var h=v('textarea[name="h-captcha-response"]','');
    if(h && h.length>20) return 'hcaptcha-solved';
    var t=v('input[name="cf-turnstile-response"]','');
    if(t && t.length>20) return 'turnstile-solved';
    if(document.querySelector('.g-recaptcha,iframe[src*="recaptcha"],iframe[src*="hcaptcha"],.h-captcha,#cf-turnstile,.cf-turnstile')) return 'present';
    return '';
  },
  cookies: function(){
    var pats=['accept','agree','allow all','got it','ok','accept all','موافق','قبول','alright'];
    var els=document.querySelectorAll('button,a');
    for(var i=0;i<els.length;i++){
      var el=els[i], r=el.getBoundingClientRect(); if(r.width<2) continue;
      var t=(el.innerText||'').trim().toLowerCase();
      if(t.length<26){ for(var p=0;p<pats.length;p++){ if(t===pats[p]||t.indexOf(pats[p])>=0){ el.click(); return t; } } }
    }
    return '';
  },
  ready: function(){ return document.readyState; }
};
})();
JSEOF

# ===================== tools/cdp.py =====================
cat > tools/cdp.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CDP — تحكم حقيقي في chromium عبر DevTools Protocol. بلا playwright."""
from __future__ import annotations
import base64, json, os, shutil, socket, subprocess, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ARGS = [
    "--no-sandbox","--disable-dev-shm-usage","--disable-gpu",
    "--disable-blink-features=AutomationControlled",
    "--remote-allow-origins=*",
    "--no-first-run","--no-default-browser-check",
    "--disable-features=IsolateOrigins,site-per-process",
    "--mute-audio","--window-size=1366,900",
    "--disable-background-timer-throttling",
    "--disable-backgrounding-occluded-windows",
    "--disable-renderer-backgrounding",
    "--disable-popup-blocking",
]

INJECT = None
def inject_src():
    global INJECT
    if INJECT is None:
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "inject.js")
        INJECT = open(p, encoding="utf-8").read()
    return INJECT

def find_chromium():
    for n in ("chromium-browser","chromium","chrome","google-chrome"):
        p = shutil.which(n)
        if p: return p
    for p in ("/data/data/com.termux/files/usr/bin/chromium-browser",
              "/data/data/com.termux/files/usr/bin/chromium"):
        if os.path.exists(p): return p
    return None

def free_port():
    s = socket.socket(); s.bind(("127.0.0.1",0)); p = s.getsockname()[1]; s.close(); return p

def x11():
    return bool(os.environ.get("DISPLAY"))

class Chrome:
    def __init__(self, profile_dir, headless=True, port=None, timeout=50):
        self.exe = find_chromium()
        if not self.exe: raise RuntimeError("chromium غير مثبت — نفّذ: pkg install chromium")
        self.port = port or free_port()
        os.makedirs(profile_dir, exist_ok=True)
        self.headless = headless
        a = [self.exe, "--remote-debugging-port=%d" % self.port, "--user-data-dir=%s" % profile_dir] + ARGS
        if headless: a.append("--headless=new")
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
            try:
                self._get("/json/version"); return
            except Exception:
                if self.proc.poll() is not None:
                    raise RuntimeError("chromium خرج فوراً — راجع " + self.logp)
                time.sleep(0.4)
        raise RuntimeError("مهلة تشغيل chromium")

    def tab(self):
        try: targets = self._get("/json/list")
        except Exception: targets = []
        for t in targets:
            if t.get("type") == "page" and t.get("webSocketDebuggerUrl"):
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
        self.send("Page.enable"); self.send("Runtime.enable"); self.send("Network.enable")
        try:
            self.send("Emulation.setUserAgentOverride",
                      {"userAgent": core.UA, "acceptLanguage": "en-US,en;q=0.9"})
        except Exception: pass
        try:
            self.send("Page.addScriptToEvaluateOnNewDocument",
                      {"source": "Object.defineProperty(navigator,'webdriver',{get:function(){return undefined;}});"
                                 "window.chrome=window.chrome||{runtime:{}};"})
        except Exception: pass

    def send(self, method, params=None):
        self._id += 1; mid = self._id
        self.ws.send(json.dumps({"id": mid, "method": method, "params": params or {}}))
        while True:
            msg = json.loads(self.ws.recv())
            if msg.get("id") == mid:
                if "error" in msg:
                    raise RuntimeError("%s: %s" % (method, msg["error"].get("message")))
                return msg.get("result", {})

    def ev(self, expr):
        r = self.send("Runtime.evaluate", {"expression": expr, "returnByValue": True, "awaitPromise": True})
        res = r.get("result", {})
        if res.get("subtype") == "error": raise RuntimeError(res.get("description","JS error"))
        return res.get("value")

    def hook(self):
        try: self.ev("window.__ch ? 1 : 0")
        except Exception: pass
        if not self.ev("window.__ch ? 1 : 0"):
            self.ev(inject_src())
        return True

    def go(self, url, timeout=30):
        try: self.send("Page.navigate", {"url": url})
        except Exception: pass
        self.settle(timeout)

    def settle(self, timeout=30):
        end = time.time()+timeout
        while time.time() < end:
            try:
                if self.ev("document.readyState") == "complete": break
            except Exception: pass
            time.sleep(0.3)
        time.sleep(1.0)
        self.hook()

    def url(self): return self.ev("location.href")
    def title(self): return self.ev("document.title")
    def text(self, n=20000): return (self.ev("document.body ? document.body.innerText : ''") or "")[:n]

    def shot(self, path):
        r = self.send("Page.captureScreenshot", {"format":"png"})
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path,"wb").write(base64.b64decode(r["data"]))
        return path
PYEOF

# ===================== tools/autoreg.py =====================
cat > tools/autoreg.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تسجيل تلقائي حقيقي: يفتح المتصفح، يعبّي، ينتظر كابتشا، يرسل، يؤكد، يحصد."""
from __future__ import annotations
import json, os, re, select, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, cdp, mailbox
from registry import by_id

REGS = core.DATA / "registrations.json"

KEYMAP = [
    (("confirm","retype","repeat","again"), "password"),
    (("email","e-mail","mail"), "email"),
    (("password","passwd","pass"), "password"),
    (("first","given","fname"), "first"),
    (("last","family","surname","lname"), "last"),
    (("username","nick","login","handle"), "username"),
    (("full","displayname","realname","name"), "fullname"),
    (("website","site","domain","url"), "site"),
    (("phone","mobile","tel","whatsapp"), "phone"),
    (("company","organization","org","business"), "company"),
    (("city","town"), "city"),
    (("zip","postal","postcode"), "zip"),
    (("address","street","addr"), "address"),
    (("telegram","skype"), "telegram"),
]

def _vals(p):
    return {"email":p.get("email",""), "password":p.get("password",""),
            "first":p.get("first",""), "last":p.get("last",""),
            "fullname":("%s %s" % (p.get("first",""), p.get("last",""))).strip(),
            "username":p.get("username",""), "site":p.get("site",""),
            "phone":p.get("phone",""), "company":p.get("company",""),
            "city":p.get("city",""), "zip":p.get("zip",""),
            "address":p.get("address",""), "telegram":p.get("telegram","")}

def _match(sig, t):
    if t == "email": return "email"
    if t == "password": return "password"
    if t == "tel": return "phone"
    for words, f in KEYMAP:
        for w in words:
            if w in sig: return f
    return ""

def fill(tab, profile):
    vals = _vals(profile); n = 0
    for f in (tab.ev("window.__ch.scan()") or []):
        if not f.get("vis"): continue
        t = f.get("type","")
        if t in ("hidden","submit","button","file","image","reset","search","checkbox","radio"): continue
        if (f.get("val") or "").strip(): continue
        fld = _match(f.get("sig",""), t)
        if not fld or not vals.get(fld): continue
        try:
            if tab.ev("window.__ch.put(%d, %s)" % (f["i"], json.dumps(str(vals[fld])))): n += 1
        except Exception: continue
    return n

def pick_country(tab, profile):
    want = [profile.get("country_name",""), profile.get("country","")]
    for f in (tab.ev("window.__ch.scan()") or []):
        if f.get("tag") != "select": continue
        s = f.get("sig","")
        if not any(k in s for k in ("country","nation","pays")): continue
        for cand in want:
            if not cand: continue
            try:
                r = tab.ev("window.__ch.putSel(%d, %s)" % (f["i"], json.dumps(cand)))
                if r: return r
            except Exception: pass
    return None

def tick(tab):
    n = 0
    for f in (tab.ev("window.__ch.scan()") or []):
        if f.get("type") != "checkbox" or not f.get("vis") or f.get("checked"): continue
        s = f.get("sig","")
        if any(k in s for k in ("term","agree","privacy","policy","accept","confirm","18","adult")):
            try:
                if tab.ev("window.__ch.check(%d)" % f["i"]): n += 1
            except Exception: pass
    return n

def wait_captcha(tab, timeout=300):
    end = time.time()+timeout; last = 0
    while time.time() < end:
        try: st = tab.ev("window.__ch.captcha()")
        except Exception: st = ""
        if st and st.endswith("-solved"):
            core.log("✓ تم حل الكابتشا — الوكيل يواصل", "ok"); return True
        if sys.stdin.isatty():
            try:
                r,_,_ = select.select([sys.stdin], [], [], 0.1)
                if r: sys.stdin.readline()
            except Exception: pass
        if time.time()-last > 6:
            core.log("⏳ بانتظارك: اضغط 'أنا لست روبوت' في المتصفح...", "warn"); last = time.time()
        time.sleep(0.7)
    core.log("انتهت مهلة الكابتشا — نتابع", "warn"); return False

def harvest(tab, net):
    blob = tab.text(20000)
    try:
        blob += "\n" + (tab.ev("Array.prototype.map.call(document.querySelectorAll('a[href]'),function(a){return a.href;}).join(String.fromCharCode(10))") or "")
    except Exception: pass
    key = ""
    if net.get("key_regex"):
        m = re.search(net["key_regex"], blob, re.I)
        if m: key = m.group(1)
    if not key:
        m = re.search(r"(https?://[^\s\"'<>]*" + re.escape(net["id"]) + r"[^\s\"'<>]*)", blob, re.I)
        if m: key = m.group(1)
    return key, blob

def record(net, status, key="", note=""):
    d = core.load(REGS, {})
    d[net["id"]] = {"name": net["name"], "status": status, "key": key, "note": note,
                    "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save(REGS, d)

def success(tab, net):
    try: u = (tab.url() or "").lower()
    except Exception: u = ""
    if u and not any(k in u for k in ("signup","register","sign-up","join","create")):
        return True
    t = tab.text(4000).lower()
    return any(k in t for k in ("verify your email","confirm your email","welcome","dashboard",
                                "check your inbox","account created","successfully"))

def register(net_id, show=False, dry=False):
    net = by_id(net_id)
    profile = core.load("data/profile.json")
    if not profile.get("password"):
        profile["password"] = core.genpass(); core.save("data/profile.json", profile)

    core.log("▶ %s — %s" % (net["name"], net["signup"]), "info")
    if dry:
        print("  حقول ستُعبأ: email/password/first/last/username/site/country")
        print("  تحقق: %s | كابتشا: %s | حد السحب: $%s" % (net["verify"], net["captcha"], net["payout_min"]))
        print("  نطاق التخزين: data/profiles/%s" % net_id)
        return True

    headless = not (show and cdp.x11())
    if show and not cdp.x11():
        core.log("DISPLAY غير موجود — سيعمل headless. راجع قسم X11.", "warn")

    ch = cdp.Chrome(str(core.DATA / "profiles" / net_id), headless=headless)
    try:
        tab = ch.tab()
        tab.go(net["signup"])
        tab.ev("window.__ch && window.__ch.cookies()")
        core.log("الصفحة: %s" % (tab.title() or "")[:60], "info")

        for step in range(1, 4):
            f = fill(tab, profile); c = pick_country(tab, profile); b = tick(tab)
            core.log("خطوة %d: حقول=%d بلد=%s موافقات=%d" % (step, f, c or "-", b), "ok")
            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                core.log("كابتشا موجودة قبل الإرسال", "warn"); wait_captcha(tab, 300)
            btn = tab.ev("window.__ch.submitBtn()")
            if not btn: core.log("لا يوجد زر إرسال", "warn"); break
            core.log("إرسال: %s" % btn, "info")
            tab.ev("window.__ch.clickBtn()")
            tab.settle(30); time.sleep(2)
            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                wait_captcha(tab, 300)
                tab.ev("window.__ch.clickBtn()"); tab.settle(25); time.sleep(2)
            if success(tab, net): break

        tab.shot(str(core.LOGS / "shots" / ("%s_%s.png" % (net_id, time.strftime("%H%M%S")))))
        key, blob = harvest(tab, net)

        if net["verify"] == "email" and mailbox.configured():
            core.log("فحص بريد التحقق...", "info")
            if mailbox.confirm(net["id"]):
                record(net, "confirmed", key)
                tab.go(net["signup"]); time.sleep(2)

        if key:
            core.set_env(net["key_env"], key); core.clipset(key)
            core.log("✓ مفتاح %s = %s" % (net["key_env"], key), "ok")
            record(net, "registered", key)
        else:
            core.log("لم يُعثر على المفتاح تلقائياً — عيّنه: ./run.sh key %s <القيمة>" % net_id, "warn")
            record(net, "pending_key")

        core.log("✓ الجلسة محفوظة في data/profiles/%s" % net_id, "ok")
        return bool(key)
    except Exception as e:
        core.log("خطأ: %s" % e, "err"); record(net, "error", note=str(e)); return False
    finally:
        ch.close()

def batch(ids, show=False):
    ok = 0
    for i in ids:
        try:
            if register(i, show=show): ok += 1
        except Exception as e: core.log("%s: %s" % (i, e), "err")
    core.log("النتيجة: %d/%d" % (ok, len(ids)), "ok" if ok else "warn")
PYEOF

# ===================== إصلاح ledger =====================
python3 - << 'PY'
p = "tools/ledger.py"
s = open(p, encoding="utf-8").read()
s = s.replace('def _d(): return core.load(L, {"entries": []})',
'''def _d():
    d = core.load(L, {"entries": []})
    if not isinstance(d, dict): d = {}
    d.setdefault("entries", [])
    return d''')
open(p, "w", encoding="utf-8").write(s)
print("ledger محصّن")
PY

# ===================== إصلاح doctor =====================
python3 - << 'PY'
p = "tools/doctor.py"
s = open(p, encoding="utf-8").read()
s = s.replace('"tools/browser.py",', '"tools/cdp.py","tools/inject.js",')
s = s.replace('DEPS = {"requests":"requests","bs4":"beautifulsoup4","lxml":"lxml","playwright":"playwright"}',
              'DEPS = {"websocket":"websocket-client"}')
open(p, "w", encoding="utf-8").write(s)
print("doctor محدّث")
PY

# ===================== تحديث agent =====================
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
s = s.replace('''    elif c == "reg":
        dry = "--dry" in a; head = "--headful" in a
        ids = [x for x in a[1:] if not x.startswith("--")]
        import autoreg
        for i in ids: autoreg.register(i, headless=not head, dry=dry)
    elif c == "login":
        import autoreg; autoreg.login(a[1], headless="--headful" not in a)''',
'''    elif c == "reg":
        dry = "--dry" in a; show = ("--show" in a) or ("--headful" in a)
        ids = [x for x in a[1:] if not x.startswith("--")]
        import autoreg
        for i in ids: autoreg.register(i, show=show, dry=dry)
    elif c == "show":
        import glob
        g = sorted(glob.glob(str(core.LOGS / "shots" / (a[1] + "_*.png"))))
        if not g: print("لا توجد صور بعد")
        else: core.openurl(g[-1]); print(g[-1])
    elif c == "profile":
        pr = core.load("data/profile.json")
        for k in ("first","last","username","email","password","country","site"):
            print("  %-10s %s" % (k, pr.get(k,"")))''')
s = s.replace('''    elif c == "batch":
        import autoreg; autoreg.batch(a[1:])''',
'''    elif c == "batch":
        import autoreg; autoreg.batch(a[1:], show=("--show" in a))''')
s = s.replace('  batch <id1> <id2> ...   تسجيل جماعي',
              '  batch <id1> <id2> ...   تسجيل جماعي\n  show <id>               عرض آخر صورة للصفحة\n  profile                 عرض بياناتك')
s = s.replace('  reg <id> [--headful]    تسجيل تلقائي حقيقي في موقع',
              '  reg <id> [--show]       تسجيل حقيقي (--show لرؤية المتصفح)')
open(p, "w", encoding="utf-8").write(s)
print("agent محدّث")
PY

# ===================== اختبار =====================
echo ""
echo "══ الاختبار ══"
python3 -m py_compile tools/core.py tools/cdp.py tools/autoreg.py tools/agent.py tools/ledger.py tools/doctor.py tools/payout.py tools/mailbox.py tools/registry.py && echo "✓ كل الملفات تُترجم"
python3 tools/agent.py status
echo ""
echo "✅ جاهز"
