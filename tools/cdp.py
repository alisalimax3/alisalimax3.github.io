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
            self.send("Page.bringToFront")
            self.send("Emulation.setFocusEmulationEnabled", {"enabled": True})
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
                cur = self.ev("location.href") or ""
                ready = self.ev("document.readyState") == "complete"
                if not host:
                    if ready and cur and "about:blank" not in cur:
                        time.sleep(0.8); self.hook(); return True
                elif host in cur and ready:
                    time.sleep(1.0); self.hook(); return True
            except Exception: pass
            time.sleep(0.35)
        return False

    def settle(self, timeout=25):
        end = time.time()+timeout
        while time.time() < end:
            try:
                if self.ev("document.readyState") == "complete": break
            except Exception: pass
            time.sleep(0.3)
        time.sleep(0.8); self.hook()

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
