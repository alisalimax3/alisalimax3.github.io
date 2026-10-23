#!/data/data/com.termux/files/usr/bin/bash
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p tools data logs/shots data/profiles backups
tar czf "backups/pre_v10_$(date +%s).tgz" tools data keys.env 2>/dev/null
pkill -f "chromium.*cinehub3099" 2>/dev/null
rm -f data/profiles/*/Singleton* data/profiles/*/lockfile 2>/dev/null
echo "✓ نسخة احتياطية + تنظيف"

# ══════════════════ core.py ══════════════════
cat > tools/core.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub Core v10 — نهائي بلا اعتماد خارجي"""
from __future__ import annotations
import json, os, random, re, shutil, string, subprocess, sys, time
import urllib.error, urllib.request
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
DATA, LOGS = BASE / "data", BASE / "logs"
SHOTS, PROFILES = LOGS / "shots", DATA / "profiles"
ENV_FILE, LOG_FILE = BASE / "keys.env", LOGS / "cinehub.log"
C = {"ok":"\033[92m","err":"\033[91m","warn":"\033[93m","info":"\033[96m","d":"\033[90m","b":"\033[1m","x":"\033[0m"}
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

def log(msg, level="info"):
    col = C.get(level, C["info"]); ico = {"ok":"✓","err":"✗","warn":"!","info":"i"}.get(level,"i")
    try: print("%s[%s]%s %s%s%s %s" % (C["d"], datetime.now().strftime("%H:%M:%S"), C["x"], col, ico, C["x"], msg))
    except Exception: print(msg)
    try:
        LOGS.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE,"a",encoding="utf-8") as f:
            f.write("[%s] [%s] %s\n" % (datetime.now().isoformat(), level, msg))
    except Exception: pass

def ensure_dirs():
    for d in (DATA, LOGS, SHOTS, PROFILES, BASE/"assets", BASE/"content", BASE/".tmp"):
        try: d.mkdir(parents=True, exist_ok=True)
        except Exception: pass

def _r(n):
    p = Path(n); return p if p.is_absolute() else DATA / p

def load(name, default=None):
    p = _r(name)
    try:
        if p.exists() and p.stat().st_size > 0:
            d = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(d, dict) and isinstance(default, dict):
                for k,v in default.items(): d.setdefault(k,v)
            return d
    except Exception as e: log("قراءة %s: %s" % (p.name, e), "warn")
    return {} if default is None else default

def save(name, data):
    p = _r(name)
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        t = p.with_name(p.name + ".tmp")
        t.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        t.replace(p); return True
    except Exception as e:
        log("حفظ %s: %s" % (p.name, e), "err"); return False

def env(k, d=""): return os.environ.get(k, d)

def load_env(path=None):
    p = Path(path or ENV_FILE)
    if not p.exists(): return
    for raw in p.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line: continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def set_env(k, v, path=None):
    p = Path(path or ENV_FILE); lines=[]; found=False
    if p.exists():
        for raw in p.read_text(encoding="utf-8", errors="ignore").splitlines():
            if re.match(r"^\s*%s\s*=" % re.escape(k), raw):
                lines.append("%s=%s" % (k,v)); found=True
            else: lines.append(raw)
    if not found: lines.append("%s=%s" % (k,v))
    p.write_text("\n".join(lines).rstrip()+"\n", encoding="utf-8")
    os.environ[k] = v

def genpass(n=18):
    ab = string.ascii_letters + string.digits + "!@#$%"
    return "".join(random.choice(ab) for _ in range(n))

def find_chromium():
    for n in ("chromium-browser","chromium","chrome"):
        p = shutil.which(n)
        if p: return p
    for p in ("/data/data/com.termux/files/usr/bin/chromium-browser",
              "/data/data/com.termux/files/usr/bin/chromium"):
        if os.path.exists(p): return p
    return None

def chromium_version():
    e = find_chromium()
    if not e: return "—"
    try: return subprocess.check_output([e,"--version"], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception: return "—"

def x11_alive():
    if not env("DISPLAY"): return False
    for p in ("/data/data/com.termux/files/usr/tmp/.X11-unix/X0","/tmp/.X11-unix/X0"):
        if os.path.exists(p): return True
    try:
        subprocess.check_output(["pgrep","-f","termux-x11"], stderr=subprocess.DEVNULL); return True
    except Exception: return False

def openurl(url):
    for c in (["termux-open-url",url],["termux-open",url],["xdg-open",url]):
        try: subprocess.Popen(c, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); return True
        except Exception: continue
    log("افتح: %s" % url, "info"); return False

def clipboard():
    for c in (["termux-clipboard-get"],["xclip","-selection","clipboard","-o"]):
        try: return subprocess.check_output(c, text=True, stderr=subprocess.DEVNULL).strip()
        except Exception: continue
    return ""

def clipset(t):
    for c in (["termux-clipboard-set"],["xclip","-selection","clipboard"]):
        try:
            subprocess.run(c, input=t, text=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); return True
        except Exception: continue
    return False

def http(url, method="GET", data=None, headers=None, timeout=20):
    h = {"User-Agent":UA,"Accept-Language":"en-US,en;q=0.9","Accept":"text/html,application/xhtml+xml,*/*;q=0.8"}
    if headers: h.update(headers)
    body = None
    if data is not None:
        body = json.dumps(data).encode() if isinstance(data,(dict,list)) else str(data).encode()
        h.setdefault("Content-Type","application/json")
    try:
        with urllib.request.urlopen(urllib.request.Request(url,data=body,headers=h,method=method), timeout=timeout) as r:
            return {"ok":True,"code":r.getcode(),"text":r.read().decode("utf-8","ignore")}
    except urllib.error.HTTPError as e:
        return {"ok":False,"code":e.code,"err":"HTTP %s" % e.code,"text":""}
    except Exception as e:
        return {"ok":False,"code":0,"err":str(e)[:90],"text":""}

ensure_dirs(); load_env()
PYEOF

# ══════════════════ inject.js ══════════════════
cat > tools/inject.js << 'JSEOF'
(function(){
if (window.__ch) return;
function sig(el){
  var p=[];
  ['name','id','placeholder','aria-label','autocomplete','title','data-testid'].forEach(function(a){
    var v = el.getAttribute && el.getAttribute(a); if(v) p.push(String(v).toLowerCase());
  });
  try{ if(el.labels && el.labels.length) p.push(el.labels[0].innerText.toLowerCase()); }catch(e){}
  try{ var pd=el.parentElement; if(pd){ var t=(pd.innerText||'').toLowerCase(); if(t.length<70) p.push(t);} }catch(e){}
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
    var all = document.querySelectorAll('input,textarea,select'), out=[];
    for(var i=0;i<all.length;i++){
      var el=all[i]; el.setAttribute('data-ch', String(i));
      var r=el.getBoundingClientRect(), st=getComputedStyle(el);
      var vis = r.width>1 && r.height>1 && st.visibility!=='hidden' && st.display!=='none' && !el.disabled;
      out.push({ i:i, tag:el.tagName.toLowerCase(), type:(el.type||'').toLowerCase(),
                 sig: vis?sig(el):'', val: el.value||'', checked: !!el.checked, vis: vis,
                 opts: el.tagName==='SELECT' ? Array.prototype.slice.call(el.options,0,400).map(function(o){return o.text;}) : null });
    }
    return out;
  },
  _w: function(fr){
    if(!fr) return window;
    var f = document.querySelectorAll('iframe')[fr-1];
    return (f && f.contentWindow) ? f.contentWindow : window;
  },
  frames: function(){
    var n=0, f=document.querySelectorAll('iframe');
    for(var i=0;i<f.length;i++){ try{ if(f[i].contentWindow && f[i].contentWindow.__ch) n++; }catch(e){} }
    return n;
  },
  scanAll: function(){
    var out = window.__ch.scan();
    for(var i=0;i<out.length;i++) out[i].fr = 0;
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){
      try{
        var w = fr[i].contentWindow; if(!w || !w.__ch) continue;
        var sub = w.__ch.scan();
        for(var j=0;j<sub.length;j++){ sub[j].fr = i+1; out.push(sub[j]); }
      }catch(e){}
    }
    return out;
  },
  put: function(i,v){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; setVal(el,v); return true; },
  putF: function(fr,i,v){ try{ var w=window.__ch._w(fr); if(!w.__ch) return false; return w.__ch.put(i,v); }catch(e){ return false; } },
  putSel: function(i,needle){
    var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return '';
    var n=String(needle).toLowerCase();
    for(var k=0;k<el.options.length;k++){ var o=el.options[k];
      if((o.text||'').toLowerCase().indexOf(n)>=0 || (o.value||'').toLowerCase()===n){
        el.value=o.value; el.dispatchEvent(new Event('change',{bubbles:true})); return o.text; } }
    return '';
  },
  putSelF: function(fr,i,t){ try{ var w=window.__ch._w(fr); return w.__ch.putSel(i,t); }catch(e){ return ''; } },
  check: function(i){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; if(!el.checked) el.click(); return true; },
  checkF: function(fr,i){ try{ var w=window.__ch._w(fr); return w.__ch.check(i); }catch(e){ return false; } },
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
  submitAll: function(){
    var t = window.__ch.submitBtn(); if(t) return t;
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){ try{ var w=fr[i].contentWindow; if(w && w.__ch && w.__ch.submitBtn()) return 'frame'; }catch(e){} }
    return '';
  },
  clickBtn: function(){
    var b=document.querySelector('[data-ch-btn]');
    if(b){ try{b.scrollIntoView({block:'center'});}catch(e){} b.click(); return true; }
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){ try{ var w=fr[i].contentWindow; if(w && w.__ch) return w.__ch.clickBtn(); }catch(e){} }
    return false;
  },
  captcha: function(){
    function val(sel){ var e=document.querySelector(sel); return e ? (e.value||'') : ''; }
    if((val('textarea[name="g-recaptcha-response"]')||val('#g-recaptcha-response')).length>20) return 'recaptcha-solved';
    if(val('textarea[name="h-captcha-response"]').length>20) return 'hcaptcha-solved';
    if(val('input[name="cf-turnstile-response"]').length>20) return 'turnstile-solved';
    if(document.querySelector('.g-recaptcha,iframe[src*="recaptcha"],iframe[src*="hcaptcha"],.h-captcha,#cf-turnstile,.cf-turnstile')) return 'present';
    return '';
  },
  captchaBox: function(){
    var sels=['iframe[src*="recaptcha/api2/anchor"]','iframe[title*="reCAPTCHA"]',
              'iframe[src*="hcaptcha"]','iframe[title*="hCaptcha"]','iframe[src*="turnstile"]'];
    for(var s=0;s<sels.length;s++){
      var f=document.querySelector(sels[s]); if(!f) continue;
      var r=f.getBoundingClientRect();
      if(r.width<4||r.height<4||r.top<-60||r.top>4000) continue;
      return {x:r.left+Math.min(28,r.width/2), y:r.top+r.height/2, kind:sels[s]};
    }
    return null;
  },
  cookies: function(){
    var pats=['accept','agree','allow all','got it','ok','accept all','موافق','قبول'];
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

# ══════════════════ cdp.py ══════════════════
cat > tools/cdp.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CDP v10 — تحكم كامل في chromium حقيقي"""
from __future__ import annotations
import base64, glob, json, os, socket, subprocess, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ARGS = ["--no-sandbox","--disable-dev-shm-usage","--disable-gpu",
 "--disable-blink-features=AutomationControlled","--remote-allow-origins=*",
 "--no-first-run","--no-default-browser-check","--disable-features=IsolateOrigins,site-per-process",
 "--mute-audio","--window-size=1440,960","--disable-background-timer-throttling",
 "--disable-backgrounding-occluded-windows","--disable-renderer-backgrounding",
 "--disable-popup-blocking","--disable-ipc-flooding-protection","--force-device-scale-factor=1"]

_INJ = None
def inject_src():
    global _INJ
    if _INJ is None:
        _INJ = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),"inject.js"), encoding="utf-8").read()
    return _INJ

def free_port():
    s = socket.socket(); s.bind(("127.0.0.1",0)); p=s.getsockname()[1]; s.close(); return p

class Chrome:
    def __init__(self, profile_dir, headless=True, port=None, timeout=50, proxy=""):
        self.exe = core.find_chromium()
        if not self.exe: raise RuntimeError("chromium غير مثبت — pkg install chromium")
        self.port = port or free_port(); self.profile = profile_dir
        os.makedirs(profile_dir, exist_ok=True)
        self.argv = [self.exe, "--remote-debugging-port=%d" % self.port,
                     "--user-data-dir=%s" % profile_dir] + ARGS
        if proxy: self.argv.append("--proxy-server="+proxy)
        self.logp = os.path.join(profile_dir, "chromium.log")
        self.headless = headless
        self._clean(); self._spawn(headless)
        try: self._wait(timeout)
        except RuntimeError:
            if not headless:
                core.log("الوضع المرئي فشل — headless", "warn")
                self._kill(); time.sleep(1); self._spawn(True); self.headless=True; self._wait(timeout)
            else: raise

    def _clean(self):
        for pat in ("Singleton*","lockfile"):
            for f in glob.glob(os.path.join(self.profile, pat)):
                try: os.remove(f)
                except Exception: pass

    def _spawn(self, headless):
        a = list(self.argv)
        if headless: a.append("--headless=new")
        self.lf = open(self.logp, "ab")
        self.proc = subprocess.Popen(a, stdout=self.lf, stderr=self.lf,
                                     stdin=subprocess.DEVNULL, start_new_session=True)

    def _kill(self):
        try: self.proc.kill()
        except Exception: pass
        try: self.lf.close()
        except Exception: pass

    def _get(self, path, method="GET"):
        req = urllib.request.Request("http://127.0.0.1:%d%s" % (self.port,path), method=method)
        with urllib.request.urlopen(req, timeout=6) as r:
            return json.loads(r.read().decode("utf-8","ignore"))

    def _wait(self, timeout):
        end = time.time()+timeout
        while time.time() < end:
            try: self._get("/json/version"); return
            except Exception:
                if self.proc.poll() is not None:
                    tail=""
                    try: tail = open(self.logp, encoding="utf-8", errors="ignore").read()[-600:]
                    except Exception: pass
                    raise RuntimeError("chromium خرج:\n"+tail)
                time.sleep(0.4)
        raise RuntimeError("مهلة chromium")

    def tab(self):
        try: tl = self._get("/json/list")
        except Exception: tl = []
        for t in tl:
            if t.get("type")=="page" and t.get("webSocketDebuggerUrl") and "devtools" not in (t.get("url") or ""):
                return Tab(t["webSocketDebuggerUrl"])
        try: t = self._get("/json/new?about:blank","PUT")
        except Exception: t = self._get("/json/new?about:blank","GET")
        return Tab(t["webSocketDebuggerUrl"])

    def close(self):
        try: self.proc.terminate(); self.proc.wait(timeout=10)
        except Exception: self._kill()
        try: self.lf.close()
        except Exception: pass

class Tab:
    def __init__(self, ws, timeout=120):
        import websocket
        self.ws = websocket.create_connection(ws, timeout=timeout, suppress_origin=True, max_size=200*1024*1024)
        self._id = 0
        for m in ("Page.enable","Runtime.enable","Network.enable"): self.send(m)
        try:
            self.send("Emulation.setUserAgentOverride",
                      {"userAgent":core.UA,"acceptLanguage":"en-US,en;q=0.9","platform":"Win32"})
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
            if msg.get("id")==mid:
                if "error" in msg: raise RuntimeError("%s: %s" % (method, msg["error"].get("message")))
                return msg.get("result",{})

    def ev(self, expr):
        r = self.send("Runtime.evaluate", {"expression":expr,"returnByValue":True,"awaitPromise":True})
        res = r.get("result",{})
        if res.get("subtype")=="error": raise RuntimeError(res.get("description","JS"))
        return res.get("value")

    def hook(self):
        try:
            if not self.ev("typeof window.__ch!=='undefined'"): self.ev(inject_src())
        except Exception: pass

    def go(self, url, timeout=50, retries=2):
        host = urllib.parse.urlparse(url).netloc
        for _ in range(retries+1):
            try:
                r = self.send("Page.navigate", {"url":url})
                if r.get("errorText"): core.log("navigate: %s" % r["errorText"], "warn")
            except Exception as e: core.log("navigate: %s" % e, "warn")
            if self._wait_host(host, timeout): return True
            time.sleep(1.5)
        return False

    def _wait_host(self, host, timeout):
        end = time.time()+timeout
        while time.time() < end:
            try:
                if host and host in (self.ev("location.href") or ""):
                    if self.ev("document.readyState")=="complete":
                        time.sleep(1.0); self.hook(); return True
            except Exception: pass
            time.sleep(0.35)
        return False

    def url(self):
        try: return self.ev("location.href") or ""
        except Exception: return ""
    def title(self):
        try: return self.ev("document.title") or ""
        except Exception: return ""
    def text(self, n=20000):
        try: return (self.ev("document.body?document.body.innerText:''") or "")[:n]
        except Exception: return ""
    def html(self):
        try: return self.ev("document.documentElement.outerHTML") or ""
        except Exception: return ""

    def click_xy(self, x, y):
        self.send("Input.dispatchMouseEvent", {"type":"mouseMoved","x":x,"y":y,"buttons":0})
        time.sleep(0.05)
        self.send("Input.dispatchMouseEvent", {"type":"mousePressed","x":x,"y":y,"button":"left","buttons":1,"clickCount":1})
        time.sleep(0.08)
        self.send("Input.dispatchMouseEvent", {"type":"mouseReleased","x":x,"y":y,"button":"left","buttons":0,"clickCount":1})

    def shot(self, path):
        r = self.send("Page.captureScreenshot", {"format":"png"})
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path,"wb").write(base64.b64decode(r["data"])); return path

    def dump(self, tag):
        core.SHOTS.mkdir(parents=True, exist_ok=True)
        p = str(core.SHOTS / ("%s_%s" % (tag, time.strftime("%H%M%S"))))
        try: self.shot(p+".png")
        except Exception: pass
        try: open(p+".html","w",encoding="utf-8").write(self.html())
        except Exception: pass
        core.log("تشخيص: %s.png" % p, "info"); return p
PYEOF

# ══════════════════ autoreg.py ══════════════════
cat > tools/autoreg.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""تسجيل تلقائي حقيقي — تعبئة + نقر كابتشا + تأكيد بريد + حصاد"""
from __future__ import annotations
import json, os, re, select, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, cdp, mailbox, captcha, registry
from registry import by_id

REGS = core.DATA / "registrations.json"
KEYMAP = [ (("confirm","retype","repeat","again"),"password"), (("email","e-mail","mail"),"email"),
 (("password","passwd","pass"),"password"), (("first","given","fname"),"first"),
 (("last","family","surname","lname"),"last"), (("username","nick","login","handle"),"username"),
 (("full","displayname","realname","name"),"fullname"), (("website","site","domain","url"),"site"),
 (("phone","mobile","tel","whatsapp"),"phone"), (("company","organization","org","business"),"company"),
 (("city","town"),"city"), (("zip","postal","postcode"),"zip"), (("address","street","addr"),"address"),
 (("telegram","skype"),"telegram") ]

def _vals(p):
    return {"email":p.get("email",""),"password":p.get("password",""),"first":p.get("first",""),
            "last":p.get("last",""),"fullname":("%s %s"%(p.get("first",""),p.get("last",""))).strip(),
            "username":p.get("username",""),"site":p.get("site",""),"phone":p.get("phone",""),
            "company":p.get("company",""),"city":p.get("city",""),"zip":p.get("zip",""),
            "address":p.get("address",""),"telegram":p.get("telegram","")}

def _match(sig, t):
    if t=="email": return "email"
    if t=="password": return "password"
    if t=="tel": return "phone"
    for words, f in KEYMAP:
        for w in words:
            if w in sig: return f
    return ""

def fill(tab, profile):
    vals=_vals(profile); n=0
    for f in (tab.ev("window.__ch.scanAll()") or []):
        if not f.get("vis"): continue
        t=f.get("type","")
        if t in ("hidden","submit","button","file","image","reset","search","checkbox","radio"): continue
        if (f.get("val") or "").strip(): continue
        fld=_match(f.get("sig",""), t)
        if not fld or not vals.get(fld): continue
        try:
            if tab.ev("window.__ch.putF(%d,%d,%s)" % (f.get("fr",0), f["i"], json.dumps(str(vals[fld])))): n+=1
        except Exception: continue
    return n

def pick_country(tab, profile):
    want=[profile.get("country_name",""), profile.get("country","")]
    for f in (tab.ev("window.__ch.scanAll()") or []):
        if f.get("tag")!="select": continue
        s=f.get("sig","")
        if not any(k in s for k in ("country","nation","pays")): continue
        for c in want:
            if not c: continue
            try:
                r=tab.ev("window.__ch.putSelF(%d,%d,%s)" % (f.get("fr",0), f["i"], json.dumps(c)))
                if r: return r
            except Exception: pass
    return None

def tick(tab):
    n=0
    for f in (tab.ev("window.__ch.scanAll()") or []):
        if f.get("type")!="checkbox" or not f.get("vis") or f.get("checked"): continue
        if any(k in f.get("sig","") for k in ("term","agree","privacy","policy","accept","confirm","18","adult")):
            try:
                if tab.ev("window.__ch.checkF(%d,%d)" % (f.get("fr",0), f["i"])): n+=1
            except Exception: pass
    return n

def try_click_captcha(tab, tries=3):
    for _ in range(tries):
        try: st=tab.ev("window.__ch.captcha()")
        except Exception: st=""
        if not st: return False
        if st.endswith("-solved"): return True
        try: b=tab.ev("window.__ch.captchaBox()")
        except Exception: b=None
        if not b: time.sleep(1); continue
        core.log("نقر آلي للكابتشا عند %d,%d" % (b["x"],b["y"]), "info")
        try: tab.click_xy(b["x"], b["y"])
        except Exception: pass
        time.sleep(3.2)
        try: st=tab.ev("window.__ch.captcha()")
        except Exception: st=""
        if st and st.endswith("-solved"): core.log("✓ كابتشا حُلّت آلياً","ok"); return True
    return False

def wait_captcha(tab, timeout=240):
    end=time.time()+timeout; last=0
    while time.time()<end:
        try: st=tab.ev("window.__ch.captcha()")
        except Exception: st=""
        if st and st.endswith("-solved"): core.log("✓ حُلّت","ok"); return True
        if time.time()-last>8: core.log("بانتظار الكابتشا...","warn"); last=time.time()
        time.sleep(0.8)
    return False

def harvest(tab, net):
    blob=tab.text(20000)
    try:
        blob += "\n" + (tab.ev("Array.prototype.map.call(document.querySelectorAll('a[href]'),function(a){return a.href;}).join(String.fromCharCode(10))") or "")
    except Exception: pass
    key=""
    if net.get("key_regex"):
        m=re.search(net["key_regex"], blob, re.I)
        if m: key=m.group(1)
    if not key:
        m=re.search(r"(https?://[^\s\"'<>]*"+re.escape(net["id"])+r"[^\s\"'<>]*)", blob, re.I)
        if m: key=m.group(1)
    return key, blob

def record(net, status, key="", note=""):
    d=core.load(REGS, {})
    d[net["id"]]={"name":net["name"],"status":status,"key":key,"note":note,"at":time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save(REGS, d)

def success(tab, net):
    u=(tab.url() or "").lower()
    if u and not any(k in u for k in ("signup","register","sign-up","join","create")): return True
    t=tab.text(4000).lower()
    return any(k in t for k in ("verify your email","confirm your email","welcome","dashboard","check your inbox","account created","successfully"))

def register(net_id, show=False, dry=False):
    net=by_id(net_id)
    profile=core.load("data/profile.json")
    if not profile.get("password"):
        profile["password"]=core.genpass(); core.save("data/profile.json", profile)
    core.log("▶ %s — %s" % (net["name"], net["signup"]), "info")
    if dry:
        print("  حقول: email/password/name/username/site/country")
        print("  تحقق: %s | كابتشا: %s | حد: $%s" % (net["verify"], net["captcha"], net["payout_min"]))
        print("  نطاق: data/profiles/%s" % net_id); return True

    live=cdp.core.x11_alive() if hasattr(cdp,"core") else core.x11_alive()
    headless = not (show and live)
    if show and not live: core.log("X غير شغّال — headless", "warn")

    ch=cdp.Chrome(str(core.PROFILES/net_id), headless=headless, proxy=core.env("BROWSER_PROXY"))
    try:
        tab=ch.tab(); ok=False
        for url in registry.candidates(net):
            core.log("محاولة: %s" % url, "info")
            if not tab.go(url, timeout=50): continue
            vis=[f for f in (tab.ev("window.__ch.scanAll()") or []) if f.get("vis")]
            if vis:
                ok=True; core.log("✓ %s | %d حقل" % ((tab.title() or "?")[:50], len(vis)), "ok"); break
            core.log("بلا حقول — بديل","warn")
        if not ok:
            core.log("كل الروابط فشلت","err"); tab.dump(net_id+"_fail"); record(net,"nav_failed"); return False
        tab.ev("window.__ch.cookies()")

        for step in range(1,4):
            f=fill(tab,profile); c=pick_country(tab,profile); b=tick(tab)
            core.log("خطوة %d: حقول=%d بلد=%s موافقات=%d" % (step,f,c or "-",b), "ok")
            if f==0 and step>1: break
            if tab.ev("window.__ch.captcha()")=="present" and not try_click_captcha(tab,2):
                wait_captcha(tab, 200)
            btn=tab.ev("window.__ch.submitAll()")
            if not btn: core.log("لا زر إرسال","warn"); break
            core.log("إرسال: %s" % btn, "info")
            tab.ev("window.__ch.clickBtn()"); tab.settle if hasattr(tab,"settle") else None
            time.sleep(4)
            if tab.ev("window.__ch.captcha()")=="present":
                if not try_click_captcha(tab,2): wait_captcha(tab,200)
                tab.ev("window.__ch.clickBtn()"); time.sleep(3)
            if success(tab,net): core.log("✓ نجح التسجيل","ok"); break

        tab.dump(net_id)
        key,_=harvest(tab,net)

        if net["verify"]=="email" and mailbox.configured():
            core.log("فحص بريد التحقق...","info")
            if mailbox.confirm(net["id"]):
                record(net,"confirmed",key)
                for u in (net["login"], net["payout_page"], net["signup"]):
                    if key: break
                    try:
                        tab.go(u, timeout=30); time.sleep(2)
                        k2,_=harvest(tab,net)
                        if k2: key=k2; core.log("مفتاح من اللوحة: %s" % k2,"ok")
                    except Exception: pass

        if key:
            core.set_env(net["key_env"], key); core.clipset(key)
            core.log("✓ %s = %s" % (net["key_env"], key), "ok"); record(net,"registered",key)
        else:
            core.log("لا مفتاح — ./run.sh add %s" % net_id,"warn"); record(net,"pending_key")
        return bool(key)
    except Exception as e:
        core.log("خطأ: %s" % e,"err"); record(net,"error",note=str(e)); return False
    finally: ch.close()

def batch(ids, show=False):
    ok=0
    for i in ids:
        try:
            if register(i, show=show): ok+=1
        except Exception as e: core.log("%s: %s" % (i,e),"err")
    core.log("النتيجة: %d/%d" % (ok,len(ids)), "ok" if ok else "warn")
PYEOF

echo "✓ الملفات الأساسية"

# ══════════════════ ledger.py ══════════════════
cat > tools/ledger.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, os, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
from registry import by_id
L = core.DATA / "ledger.json"

def _d():
    d = core.load(L, {"entries": []})
    if not isinstance(d, dict): d = {}
    d.setdefault("entries", [])
    if not isinstance(d["entries"], list): d["entries"] = []
    return d

def add(site, amount, kind="earning", currency="USD", note=""):
    d = _d()
    d["entries"].append({"site":site,"amount":float(amount),"kind":kind,
                         "currency":currency,"note":note,"at":time.strftime("%Y-%m-%d %H:%M:%S")})
    core.save(L, d); core.log("%s: %s = %s %s" % ("ربح" if kind=="earning" else "سحب", site, amount, currency), "ok")

def balances():
    b = {}
    for e in _d()["entries"]:
        b[e["site"]] = b.get(e["site"], 0.0) + (e["amount"] if e["kind"]=="earning" else -abs(e["amount"]))
    return b

def total(): return round(sum(balances().values()), 2)

def report():
    b = balances()
    if not b: core.log("لا أرباح مسجّلة","warn"); return
    print("\n%-22s %10s %8s  %s" % ("المصدر","الرصيد","الحد","الحالة")); print("-"*58)
    for s,v in sorted(b.items(), key=lambda x:-x[1]):
        try: mn = by_id(s)["payout_min"]
        except Exception: mn = 0
        print("%-22s %10s %8s  %s" % (s, "$%.2f"%v, "$%g"%mn, "✓ جاهز" if v>=mn else "ينقص $%.2f"%(mn-v)))
    print("-"*58); print("%-22s %10s" % ("الإجمالي","$%.2f"%total()))
PYEOF

# ══════════════════ payout.py ══════════════════
cat > tools/payout.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ledger
from registry import by_id
P = core.DATA / "payouts.json"
DEF = {"wallets":{"USDT_TRC20":"","BTC":"","PAYPAL":"","PAYONEER":"","PAYEER":"","WISE":"","SKRILL":"","BANK_IBAN":""},
       "preferred":["USDT_TRC20","PAYPAL","PAYONEER"]}
def cfg():
    d = core.load(P, None)
    if not d: core.save(P, DEF); return DEF
    for k,v in DEF.items(): d.setdefault(k,v)
    for k,v in DEF["wallets"].items(): d["wallets"].setdefault(k,"")
    return d
def wallet():
    w = cfg()["wallets"]; print("\nالمحافظ:")
    for k,v in w.items(): print("  %-12s %s" % (k, ("✓ "+v) if v else "✗ فارغة"))
    print("\nللتعديل: ./run.sh wallet USDT_TRC20 <عنوان>")
def set_wallet(n,v):
    d = cfg(); d["wallets"][n.upper()] = v; core.save(P,d); core.log("%s = %s" % (n.upper(),v),"ok")
def ready():
    b = ledger.balances(); out=[]
    for s,v in b.items():
        try: mn = by_id(s)["payout_min"]
        except Exception: continue
        if v >= mn: out.append((s,v,mn))
    return out
def plan():
    r = ready()
    if not r: core.log("لا رصيد كافٍ","warn"); ledger.report(); return
    w = cfg()["wallets"]
    print("\n%s══ خطة السحب: %d موقع ══%s" % (core.C['b'], len(r), core.C['x']))
    for s,v,mn in sorted(r,key=lambda x:-x[1]):
        n = by_id(s)
        best = [m for m in n["methods"] if w.get(m.upper().replace(" ","_"))]
        print("\n▶ %s ($%.2f)\n  %s\n  طرق: %s\n  الأنسب: %s" % (n["name"],v,n["payout_page"],", ".join(n["methods"]),", ".join(best) or "أضف محفظة"))
    print("\nالإجمالي القابل للسحب: $%.2f" % sum(x[1] for x in r))
    if r: core.openurl(by_id(r[0][0])["payout_page"])
PYEOF

# ══════════════════ repo.py ══════════════════
cat > tools/repo.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
def git(*a, timeout=90):
    try:
        r = subprocess.run(["git"]+list(a), cwd=str(core.BASE), capture_output=True, text=True, timeout=timeout)
        return r.returncode, ((r.stdout or "")+(r.stderr or "")).strip()
    except Exception as e: return 1, str(e)
def remote():
    rc,out = git("remote","get-url","origin"); return out if rc==0 else ""
def ensure():
    if not (core.BASE/".git").exists():
        git("init","-q"); git("config","user.email", core.env("MAIL_USER") or "a@local")
        git("config","user.name", core.env("GITHUB_USER") or "agent"); git("add","-A"); git("commit","-q","-m","init")
    if not remote() and core.env("REPO_URL"): git("remote","add","origin", core.env("REPO_URL"))
def push(msg=None):
    ensure(); git("add","-A")
    rc,_ = git("commit","-q","-m", msg or ("sync "+time.strftime("%Y-%m-%d %H:%M")))
    if not remote(): return rc==0, "محفوظ محلياً (اضبط REPO_URL للدفع)"
    rc2,out = git("push","origin","HEAD")
    if rc2==0: return True, "دُفع للمستودع"
    return False, "فشل الدفع: "+out.splitlines()[-1][:110]
def pull():
    if not remote(): return False,"لا remote"
    rc,out = git("pull","--rebase","--autostash","origin","HEAD")
    return rc==0, (out.splitlines()[-1][:110] if out else "")
def sync():
    pull(); core.load_env(); return True
PYEOF

# ══════════════════ addkey.py ══════════════════
cat > tools/addkey.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, repo
from registry import by_id, by_cat, pending
def _ex(net, raw):
    raw = (raw or "").strip()
    if not raw: return ""
    if net.get("key_regex"):
        m = re.search(net["key_regex"], raw)
        if m: return m.group(1)
    return raw.split()[0]
def add(net_id, value=None, openit=True):
    net = by_id(net_id)
    print("\n%s══ %s ══%s" % (core.C['b'], net["name"], core.C['x']))
    print("  %s\n  المفتاح: %s | حد: $%s" % (net["signup"], net["key_env"], net["payout_min"]))
    if openit:
        core.openurl(net["signup"]); core.log("فُتح","info")
    if value is None:
        try: value = input("\nالصق المفتاح (Enter للتخطي): ")
        except EOFError: value = ""
    v = _ex(net, value)
    if not v: core.log("تخطي","warn"); return False
    core.set_env(net["key_env"], v); core.log("✓ %s = %s" % (net["key_env"], v), "ok")
    d = core.load("data/registrations.json", {})
    d[net_id] = {"name":net["name"],"status":"key_set","key":v,"at":time.strftime("%Y-%m-%d %H:%M:%S")}
    core.save("data/registrations.json", d)
    ok,m = repo.push("key: %s" % net_id); core.log(m, "ok" if ok else "warn"); return True
def missing(cat=None):
    items = by_cat(cat) if cat else pending()
    items = [n for n in items if not core.env(n["key_env"])]
    if not items: core.log("لا شيء ناقص","ok"); return
    core.log("%d موقع — Enter للتخطي" % len(items), "info")
    for i,n in enumerate(items,1):
        print("\n[%d/%d]" % (i,len(items)))
        try: add(n["id"])
        except KeyboardInterrupt: break
PYEOF

# ══════════════════ mailbox.py ══════════════════
cat > tools/mailbox.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import email, imaplib, re, sys, time
from email.header import decode_header
from html import unescape
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
LINK = re.compile(r'https?://[^\s"\'<>\])]+')
OKRX = re.compile(r'(verif|confirm|activat|validate|welcome|signup|register)', re.I)
def creds():
    host = core.env("MAIL_IMAP_HOST") or "imap.gmail.com"
    user = core.env("MAIL_USER") or core.env("MY_EMAIL") or core.env("GMAIL_USER")
    pw = core.env("MAIL_APP_PASS") or core.env("GMAIL_APP_PASSWORD") or core.env("MAIL_PASS") or ""
    return host, user, pw.replace(" ","").replace("-","").strip()
def configured(): return all(creds())
def test():
    h,u,p = creds()
    if not (u and p): return False, "MAIL_USER/MAIL_APP_PASS فارغان"
    try:
        m = imaplib.IMAP4_SSL(h,993,timeout=20); m.login(u,p); m.select("INBOX"); m.logout()
        return True, "IMAP ناجح: %s" % u
    except Exception as e: return False, "IMAP: %s" % str(e)[:90]
def _dec(v):
    if not v: return ""
    return " ".join(p.decode(e or "utf-8","ignore") if isinstance(p,bytes) else p for p,e in decode_header(v))
def _body(msg):
    t = ""
    if msg.is_multipart():
        for p in msg.walk():
            if p.get_content_type() in ("text/plain","text/html"):
                try: t += p.get_payload(decode=True).decode(p.get_content_charset() or "utf-8","ignore")
                except Exception: pass
    else:
        try: t = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8","ignore")
        except Exception: pass
    return unescape(t)
def fetch(limit=25):
    h,u,p = creds()
    if not (h and u and p): return []
    try:
        m = imaplib.IMAP4_SSL(h,993,timeout=25); m.login(u,p); m.select("INBOX")
        _,d = m.search(None,"ALL"); ids = d[0].split()[-limit:]; out=[]
        for i in reversed(ids):
            _,raw = m.fetch(i,"(RFC822)")
            if raw and raw[0]: out.append(email.message_from_bytes(raw[0][1]))
        m.logout(); return out
    except Exception as e: core.log("IMAP: %s" % str(e)[:70],"warn"); return []
def confirm(hint="", tries=5, wait=12):
    for a in range(tries):
        for msg in fetch():
            blob = _dec(msg.get("Subject","")) + " " + _dec(msg.get("From",""))
            if hint and hint.lower() not in blob.lower(): continue
            if not OKRX.search(blob): continue
            for link in LINK.findall(_body(msg)):
                l = link.rstrip(".,;)")
                if OKRX.search(l) or "verif" in l.lower() or "confirm" in l.lower():
                    r = core.http(l, timeout=25)
                    core.log("تفعيل %s (%s)" % ("نجح" if r.get("ok") else "فشل", r.get("code")), "ok" if r.get("ok") else "warn")
                    return True
        if a < tries-1: time.sleep(wait)
    return False
PYEOF

# ══════════════════ captcha.py ══════════════════
cat > tools/captcha.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
def key(): return core.env("CAPTCHA_KEY")
def solve(sitekey, url, tries=30):
    k = key()
    if not k: return ""
    r = core.http("https://2captcha.com/in.php?key=%s&method=userrecaptcha&googlekey=%s&pageurl=%s&json=1" % (k,sitekey,url))
    try: rid = json.loads(r["text"]).get("request")
    except Exception: return ""
    if not rid: return ""
    for _ in range(tries):
        time.sleep(5)
        rr = core.http("https://2captcha.com/res.php?key=%s&action=get&id=%s&json=1" % (k,rid))
        try:
            d = json.loads(rr["text"])
            if d.get("status")==1: return d["request"]
        except Exception: pass
    return ""
PYEOF

# ══════════════════ watch.py + autoflow.py + verify_keys.py ══════════════════
cat > tools/watch.py << 'PYEOF'
#!/usr/bin/env python3
import sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, repo, registry, ledger
def cycle():
    repo.sync(); core.load_env()
    s = registry.stats()
    core.log("مزامنة | %d مصدر | %d بمفاتيح | %d ناقص | $%.2f" % (s["total"],s["with_key"],s["pending"],ledger.total()), "info")
def main(m=5):
    core.log("مزامنة كل %d دقيقة" % m, "info")
    while True:
        try: cycle()
        except KeyboardInterrupt: return
        except Exception as e: core.log(str(e),"err")
        time.sleep(m*60)
PYEOF

cat > tools/autoflow.py << 'PYEOF'
#!/usr/bin/env python3
import sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, repo, autoreg
T = {1:["adsterra","monetag","popads","clickadu","aads","popcash","admaven","evadav"],
     2:[n["id"] for n in registry.by_cat("shortlinks")],
     3:["freecash","timewall","lootably","adgate","adgem","wannads","bitlabs","cpx","attapoll","cointiply","faucetpay"],
     4:["cpagrip","ogads","adworkmedia","adscend","maxbounty"],
     5:[n["id"] for n in registry.by_cat("cpa")]+[n["id"] for n in registry.by_cat("surveys")]}
def run(t=1, show=False, limit=0):
    ids=[i for i in T.get(t,[]) if i in registry.BY_ID and not core.env(registry.by_id(i)["key_env"])]
    if limit: ids=ids[:limit]
    if not ids: core.log("لا شيء ناقص في المرحلة %d" % t,"ok"); return
    core.log("مرحلة %d: %d موقع" % (t,len(ids)),"info")
    ok=[];fail=[]
    for k,i in enumerate(ids,1):
        core.log("── [%d/%d] %s ──" % (k,len(ids),i),"info")
        try:
            (ok if autoreg.register(i,show=show) else fail).append(i)
        except KeyboardInterrupt: break
        except Exception as e: core.log("%s: %s" % (i,e),"err"); fail.append(i)
        time.sleep(1)
    core.log("نجح %d | فشل %d" % (len(ok),len(fail)), "ok" if ok else "warn")
    if fail: core.log("فشل: %s" % ", ".join(fail),"warn")
    core.log(repo.push("autoflow t%d +%d" % (t,len(ok)))[1],"info")
PYEOF

cat > tools/verify_keys.py << 'PYEOF'
#!/usr/bin/env python3
import re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry
S = re.compile(r"^(install|python|pip|true|false|none|undefined|x+)$", re.I)
def main():
    ok=[];sus=[];empty=[]
    for n in registry.ALL:
        v = core.env(n["key_env"])
        if not v: empty.append(n["id"])
        elif S.match(v) or len(v)<3: sus.append((n["id"],n["key_env"],v))
        else: ok.append(n["id"])
    print("\n%s══ تحقق المفاتيح ══%s" % (core.C['b'],core.C['info'],core.C['x']))
    core.log("صحيحة: %d" % len(ok),"ok")
    core.log("مشكوك: %d" % len(sus), "warn" if sus else "ok")
    for i,k,v in sus: print("    %-16s %-22s = %s" % (i,k,v[:36]))
    core.log("فارغة: %d" % len(empty),"info")
    return 0 if not sus else 1
if __name__=="__main__": sys.exit(main())
PYEOF
echo "✓ بقية الأدوات"

# ══════════════════ audit.py ══════════════════
cat > tools/audit.py << 'PYEOF'
#!/usr/bin/env python3
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger, mailbox, cdp
OK=[];BAD=[];WARN=[]
def h(t): print("\n%s%s══ %s ══%s" % (core.C['b'],core.C['info'],t,core.C['x']))
def g(m): OK.append(m); core.log(m,"ok")
def b(m): BAD.append(m); core.log(m,"err")
def w(m): WARN.append(m); core.log(m,"warn")
def ck(c,a,z): g(a) if c else b(z)
def main():
    print("%s%s\n╔══════════════════════════════════════════════╗\n║   🔬 CineHub v10 — فحص شامل                  ║\n╚══════════════════════════════════════════════╝%s" % (core.C['b'],core.C['info'],core.C['x']))
    h("1. الملفات")
    for f in ("core.py","cdp.py","inject.js","registry.py","autoreg.py","agent.py","ledger.py",
              "payout.py","mailbox.py","captcha.py","repo.py","addkey.py","watch.py","autoflow.py","verify_keys.py","audit.py","selftest.py"):
        p = core.BASE/"tools"/f
        if not p.exists(): b("مفقود: %s" % f); continue
        if f.endswith(".py"):
            r = subprocess.run([sys.executable,"-m","py_compile",str(p)],capture_output=True)
            ck(not r.returncode, "سليم: %s" % f, "مكسور: %s" % f)
        else: g("موجود: %s" % f)
    h("2. الاعتماديات")
    for m,p in {"websocket":"websocket-client","requests":"requests","bs4":"beautifulsoup4"}.items():
        ck(importlib.util.find_spec(m) is not None, "%s مثبّت" % p, "%s مفقود" % p)
    h("3. المتصفح")
    e = core.find_chromium()
    ck(bool(e), "chromium: %s" % core.chromium_version(), "chromium مفقود")
    h("4. الشاشة")
    if core.x11_alive(): g("X يعمل — وضع مرئي متاح")
    elif core.env("DISPLAY"): w("DISPLAY مضبوط لكن X ميت — headless")
    else: w("headless (طبيعي ويعمل)")
    h("5. السجل")
    s = registry.stats()
    g("مصادر: %d | بمفاتيح: %d | ناقص: %d" % (s["total"],s["with_key"],s["pending"]))
    h("6. الهوية والمفاتيح")
    pr = core.load("data/profile.json")
    for k in ("first","last","username","email","country","site"): ck(bool(pr.get(k)), "%s=%s"%(k,pr.get(k,"")), "ناقص: %s"%k)
    mp = (core.env("MAIL_APP_PASS") or "")
    ck(len(mp)==16, "MAIL_APP_PASS صحيح (16)", "MAIL_APP_PASS طوله %d (الصحيح 16)" % len(mp))
    h("7. البريد")
    okm,msg = mailbox.test(); ck(okm, msg, msg)
    h("8. المستودع")
    import repo
    g("remote: %s" % (repo.remote() or "غير مضبوط"))
    h("9. اختبار متصفح + تعبئة حقيقية")
    import selftest
    ok = selftest.browser_and_form()
    ck(ok, "المتصفح + التعبئة يعملان", "فشل اختبار المتصفح")
    h("الخلاصة")
    core.log("ناجح %d | تحذير %d | عطل %d" % (len(OK),len(WARN),len(BAD)), "err" if BAD else ("warn" if WARN else "ok"))
    if BAD:
        print("\nيجب إصلاح:"); [print("  %d. %s"%(i,m)) for i,m in enumerate(BAD,1)]
    if WARN:
        print("\nاختياري:"); [print("  %d. %s"%(i,m)) for i,m in enumerate(WARN,1)]
    return 0 if not BAD else 2
if __name__=="__main__": sys.exit(main())
PYEOF

# ══════════════════ selftest.py — إثبات حقيقي ══════════════════
cat > tools/selftest.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""اختبار حقيقي: يفتح نموذج تسجيل محلي ويعبّيه ويُثبت أن القيم دخلت"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, cdp, autoreg

FORM = """<!doctype html><html><body><form id="f">
<label for="e">Email</label><input id="e" name="email" type="email">
<label for="p">Password</label><input id="p" name="password" type="password">
<label for="c">Confirm Password</label><input id="c" name="confirm_password" type="password">
<label for="fn">First name</label><input id="fn" name="first_name">
<label for="ln">Last name</label><input id="ln" name="last_name">
<label for="u">Username</label><input id="u" name="username">
<label for="w">Website</label><input id="w" name="website">
<label for="co">Country</label><select id="co" name="country"><option value="">--</option>
<option value="US">United States</option><option value="MA">Morocco</option></select>
<label><input id="t" name="terms" type="checkbox"> I agree to the Terms</label>
<button type="submit" id="s">Sign Up</button>
</form><script>document.getElementById('f').addEventListener('submit',function(ev){ev.preventDefault();
document.title='SIGNED-UP';});</script></body></html>"""

def form_path():
    p = core.BASE / ".tmp" / "form.html"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(FORM, encoding="utf-8"); return p

def browser_and_form():
    """يرجع True فقط لو نجح التصفح والتعبئة والنقر فعلاً"""
    prof = str(core.PROFILES / "_selftest")
    try:
        ch = cdp.Chrome(prof, headless=True, timeout=45)
    except Exception as e:
        core.log("تشغيل المتصفح: %s" % e, "err"); return False
    try:
        t = ch.tab()
        if not t.go("https://example.com", timeout=35):
            core.log("فشل تصفح الإنترنت", "err"); return False
        core.log("تصفح ناجح: %s" % (t.title() or "?"), "ok")
        if not t.ev("typeof window.__ch!=='undefined'"):
            core.log("المحقون غائب", "err"); return False
        core.log("المحقون __ch نشط", "ok")

        f = form_path()
        if not t.go("file://" + str(f), timeout=20):
            core.log("فشل تحميل النموذج", "err"); return False
        n = len(t.ev("window.__ch.scanAll()") or [])
        core.log("حقول النموذج المكتشفة: %d" % n, "ok" if n>=8 else "err")
        prof_data = {"email":"test@example.com","password":"Passw0rd!23","first":"Ali",
                     "last":"Salim","username":"alisalimax3","site":"https://alisalimax3.github.io",
                     "country":"MA","country_name":"Morocco","phone":"","company":"","city":"","zip":"","address":"","telegram":""}
        filled = autoreg.fill(t, prof_data)
        country = autoreg.pick_country(t, prof_data)
        boxes = autoreg.tick(t)
        core.log("عُبّئ: %d حقول | بلد: %s | موافقات: %d" % (filled, country or "-", boxes), "ok" if filled>=6 else "err")
        got_email = t.ev("document.getElementById('e').value")
        got_user = t.ev("document.getElementById('u').value")
        got_country = t.ev("document.getElementById('co').value")
        checked = t.ev("document.getElementById('t').checked")
        core.log("تحقق فعلي: email=%s user=%s country=%s terms=%s" % (got_email, got_user, got_country, checked), "info")
        okv = (got_email=="test@example.com" and got_user=="alisalimax3" and got_country=="MA" and checked is True)
        core.log("القيم دخلت فعلاً: %s" % ("نعم" if okv else "لا"), "ok" if okv else "err")
        btn = t.ev("window.__ch.submitAll()")
        core.log("زر الإرسال: %s" % (btn or "لم يُعثر"), "ok" if btn else "warn")
        if btn:
            t.ev("window.__ch.clickBtn()"); time.sleep(1.5)
            core.log("عنوان بعد الإرسال: %s" % (t.title() or "?"), "info")
        return bool(okv and btn)
    finally:
        ch.close()

def main():
    print("%s%s══ اختبار ذاتي حقيقي ══%s" % (core.C['b'],core.C['info'],core.C['x']))
    r = browser_and_form()
    print("\n%s" % ("✓ كل شيء يعمل فعلياً" if r else "✗ يوجد خلل"))
    return 0 if r else 1
if __name__=="__main__": sys.exit(main())
PYEOF

# ══════════════════ agent.py ══════════════════
cat > tools/agent.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub Agent v10 — كل الأوامر"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, ledger

def use():
    print("""%s
الأوامر:
  audit                   فحص شامل حقيقي
  selftest                اختبار فعلي للتعبئة والنقر
  status                  الحالة السريعة
  table [تصنيف]           الجدول الكامل (ads|cpa|affiliate|surveys|shortlinks|crypto|pay|adult|content)
  keys                    المفاتيح النشطة
  verify                  التحقق من صحة المفاتيح
  add <id> | --missing [cat]   إضافة مفتاح (فتح+لصق+حفظ+دفع)
  open <id...>            فتح رابط
  reg <id> [--show] [--dry]    تسجيل تلقائي
  batch <id...>           تسجيل جماعي
  autoflow <1..5>         تنفيذ متدرّج
  restart                 إعادة تشغيل نظيفة
  earn <id> <مبلغ>        تسجيل ربح
  spend <id> <مبلغ>       تسجيل سحب
  ledger                  تقرير الأرباح
  payout                  خطة السحب
  wallet [اسم قيمة]       المحافظ
  push|pull|sync          المستودع
  watch [دقائق]           مزامنة دورية
  setenv <KEY> <value>    تعيين مفتاح بيئة
%s""" % (core.C['info'], core.C['x']))

def main():
    a = sys.argv[1:]
    if not a: use(); return
    c = a[0]; p = [x for x in a[1:] if not x.startswith("--")]
    if c == "audit": import audit; audit.main()
    elif c == "selftest": import selftest; selftest.main()
    elif c == "status":
        s = registry.stats()
        core.log("مصادر=%d بمفاتيح=%d ناقص=%d | رصيد=$%.2f" % (s["total"],s["with_key"],s["pending"],ledger.total()),"info")
        core.log("بريد=%s | كابتشا=%s | X=%s" % ("نعم" if core.env("MAIL_APP_PASS") else "لا",
                 "نعم" if core.env("CAPTCHA_KEY") else "لا", "نعم" if core.x11_alive() else "لا"),"info")
        core.log("remote=%s" % ("مضبوط" if core.env("REPO_URL") else "غير مضبوط"),"info")
    elif c == "table":
        for cat,name in registry.CATS.items():
            if p and cat != p[0]: continue
            items = registry.by_cat(cat)
            if not items: continue
            print("\n%s%s (%d)%s" % (core.C['b'],name,len(items),core.C['x']))
            for n in items:
                m = core.C['ok']+"✓"+core.C['x'] if core.env(n["key_env"]) else " "
                print("  %s %-16s %-24s %-22s $%g" % (m,n["id"],n["name"][:24],n["key_env"][:22],n["payout_min"]))
    elif c == "keys":
        for n in registry.with_key(): print("  %-16s %-22s %s" % (n["id"],n["key_env"],(core.env(n["key_env"]) or "")[:44]))
        print("\n%d/%d" % (len(registry.with_key()),len(registry.ALL)))
    elif c == "verify": import verify_keys; sys.exit(verify_keys.main())
    elif c == "add":
        import addkey
        if "--missing" in a: addkey.missing(p[0] if p else None)
        else: [addkey.add(i) for i in p]
    elif c == "open":
        for i in p: core.openurl(registry.by_id(i)["signup"])
    elif c == "reg":
        import autoreg
        for i in p: autoreg.register(i, show=("--show" in a), dry=("--dry" in a))
    elif c == "batch":
        import autoreg; autoreg.batch(p, show=("--show" in a))
    elif c == "autoflow":
        import autoflow; autoflow.run(int(p[0]) if p else 1, show=("--show" in a))
    elif c == "restart":
        import subprocess, glob
        subprocess.run(["pkill","-f","chromium.*cinehub3099"])
        for f in glob.glob("data/profiles/*/Singleton*")+glob.glob("data/profiles/*/lockfile"):
            try: os.remove(f)
            except Exception: pass
        core.load_env(); core.log("أُعيد التشغيل","ok")
    elif c == "earn": ledger.add(p[0], p[1], "earning", note=" ".join(p[2:]))
    elif c == "spend": ledger.add(p[0], p[1], "withdraw", note=" ".join(p[2:]))
    elif c == "ledger": ledger.report()
    elif c == "payout": import payout; payout.plan()
    elif c == "wallet":
        import payout
        if len(p)>=2: payout.set_wallet(p[0],p[1])
        else: payout.wallet()
    elif c == "push": import repo; core.log(repo.push(" ".join(p) or None)[1],"ok")
    elif c == "pull": import repo; core.log(repo.pull()[1] or "مُحدّث","ok")
    elif c == "sync": import repo; repo.sync(); core.log("تمت المزامنة","ok")
    elif c == "watch": import watch; watch.main(int(p[0]) if p else 5)
    elif c == "setenv": core.set_env(p[0],p[1]); core.log("%s حُفظ" % p[0],"ok")
    else: use()

if __name__ == "__main__":
    try: main()
    except KeyboardInterrupt: print("\n%sأُوقف%s" % (core.C['warn'],core.C['x']))
    except KeyError as e: print("%s%s%s" % (core.C['err'],e,core.C['x']))
PYEOF

cat > run.sh << 'REOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"
exec python3 tools/agent.py "$@"
REOF
chmod +x run.sh

echo "══ التحقق النهائي ══"
python3 -m py_compile tools/*.py && echo "✓ كل الملفات تُترجم"
python3 -c "
import sys; sys.path.insert(0,'tools')
import registry as r
assert len(r.ALL) > 200, 'السجل صغير'
ids=[n['id'] for n in r.ALL]
assert len(ids)==len(set(ids)), 'تكرار في ids'
print('✓ السجل: %d مصدر، %d تصنيف، بلا تكرار' % (len(r.ALL), len(r.CATS)))
"
echo ""
echo "✅ v10 مثبّت — الآن شغّل: ./run.sh selftest"
