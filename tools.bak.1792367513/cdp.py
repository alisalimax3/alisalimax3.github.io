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

def x11_alive():
    """هل خادم X يعمل فعلاً؟ DISPLAY وحده لا يكفي."""
    if not os.environ.get("DISPLAY"): return False
    for p in ("/data/data/com.termux/files/usr/tmp/.X11-unix/X0",
              "/tmp/.X11-unix/X0","/data/data/com.termux/files/usr/tmp/.X11-unix/X1"):
        if os.path.exists(p): return True
    try:
        subprocess.check_output(["pgrep","-f","termux-x11"], stderr=subprocess.DEVNULL)
        return True
    except Exception: return False

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
        self.headless = headless
        self._argv_base = a
        self._launch(headless)
        try:
            self._wait(timeout)
        except RuntimeError:
            if not headless:
                core.log("الوضع المرئي فشل — أُعيد التشغيل headless تلقائياً", "warn")
                try: self.proc.kill()
                except Exception: pass
                time.sleep(1)
                self._launch(True); self.headless = True
                self._wait(timeout)
            else: raise

    def _launch(self, headless):
        a = list(self._argv_base)
        if headless: a.append("--headless=new")
        self.lf = open(self.logp, "ab")
        self.proc = subprocess.Popen(a, stdout=self.lf, stderr=self.lf,
                                     stdin=subprocess.DEVNULL, start_new_session=True)

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
