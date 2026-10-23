#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CineHub Core v4 — نواة مستقرة بلا اعتماد خارجي"""
from __future__ import annotations
import json, os, random, re, string, subprocess, sys, urllib.error, urllib.request
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
DATA, LOGS = BASE / "data", BASE / "logs"
ENV_FILE, LOG_FILE = BASE / "keys.env", LOGS / "cinehub.log"
C = {"ok":"\033[92m","err":"\033[91m","warn":"\033[93m","info":"\033[96m","d":"\033[90m","b":"\033[1m","x":"\033[0m"}

def _ts(): return datetime.now().strftime("%H:%M:%S")

def log(msg, level="info"):
    col = {"ok":C["ok"],"err":C["err"],"warn":C["warn"],"info":C["info"]}.get(level, C["info"])
    ico = {"ok":"✓","err":"✗","warn":"!","info":"i"}.get(level,"i")
    print(f"{C['d']}[{_ts()}]{C['x']} {col}{ico}{C['x']} {msg}")
    try:
        LOGS.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().isoformat()}] [{level}] {msg}\n")
    except Exception: pass

def ensure_dirs():
    for d in (DATA, LOGS, BASE/"assets", BASE/"content", BASE/".tmp", DATA/"sessions"):
        d.mkdir(parents=True, exist_ok=True)

def _r(name):
    p = Path(name); return p if p.is_absolute() else DATA / p

def load(name, default=None):
    p = _r(name)
    try:
        if p.exists() and p.stat().st_size > 0:
            d = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(d, dict) and isinstance(default, dict):
                for k, v in default.items(): d.setdefault(k, v)
            return d
    except Exception as e: log(f"قراءة {p.name}: {e}", "warn")
    return {} if default is None else default

def save(name, data):
    p = _r(name)
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        t = p.with_name(p.name + ".tmp")
        t.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        t.replace(p); return True
    except Exception as e:
        log(f"حفظ {p.name}: {e}", "err"); return False

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
            if re.match(rf"^\s*{re.escape(k)}\s*=", raw):
                lines.append(f"{k}={v}"); found=True
            else: lines.append(raw)
    if not found: lines.append(f"{k}={v}")
    p.write_text("\n".join(lines).rstrip()+"\n", encoding="utf-8")
    os.environ[k] = v

def get_env_key(k, default=""):
    return env(k) or default

def site():
    u = env("SITE_URL")
    if u: return u.rstrip("/")
    gh = env("GITHUB_USER") or env("GH_USER")
    return f"https://{gh}.github.io" if gh else ""

def genpass(n=18):
    ab = string.ascii_letters + string.digits + "!@#$%"
    return "".join(random.choice(ab) for _ in range(n))

def openurl(url):
    for c in (["termux-open-url", url], ["termux-open", url], ["xdg-open", url]):
        try: subprocess.Popen(c, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); return True
        except Exception: continue
    log(f"افتح يدوياً: {url}", "info"); return False

def clipboard():
    for c in (["termux-clipboard-get"], ["xclip","-selection","clipboard","-o"]):
        try: return subprocess.check_output(c, text=True, stderr=subprocess.DEVNULL).strip()
        except Exception: continue
    return ""

def clipset(t):
    for c in (["termux-clipboard-set"], ["xclip","-selection","clipboard"]):
        try:
            subprocess.run(c, input=t, text=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); return True
        except Exception: continue
    return False

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

def http(url, method="GET", data=None, headers=None, timeout=20):
    h = {"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"}
    if headers: h.update(headers)
    body = None
    if data is not None:
        body = json.dumps(data).encode() if isinstance(data,(dict,list)) else str(data).encode()
        h.setdefault("Content-Type","application/json")
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=body, headers=h, method=method), timeout=timeout) as r:
            return {"ok":True,"code":r.getcode(),"text":r.read().decode("utf-8","ignore")}
    except urllib.error.HTTPError as e:
        return {"ok":False,"code":e.code,"err":str(e),"text":e.read().decode("utf-8","ignore")}
    except Exception as e:
        return {"ok":False,"code":0,"err":str(e),"text":""}

def alive(url, timeout=10):
    r = http(url, timeout=timeout)
    return bool(r.get("ok") and r.get("code",0) < 400)

ensure_dirs(); load_env()
