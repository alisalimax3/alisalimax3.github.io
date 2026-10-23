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
    """يتصل فعلياً بمقبس X — لا يكتفي بوجود الملف"""
    if not env("DISPLAY"): return False
    import socket as _s
    for p in ("/data/data/com.termux/files/usr/tmp/.X11-unix/X0",
              "/data/data/com.termux/files/usr/tmp/.X11-unix/X1",
              "/tmp/.X11-unix/X0"):
        if not os.path.exists(p): continue
        try:
            c = _s.socket(_s.AF_UNIX, _s.SOCK_STREAM); c.settimeout(1.2)
            c.connect(p); c.close(); return True
        except Exception: pass
    return False

def x11_hint():
    return ("X غير شغّال. شغّله:\n"
            "  termux-x11 :0 -ac &\n"
            "  am start --user 0 -n com.termux.x11/.MainActivity\n"
            "  export DISPLAY=:0")

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
