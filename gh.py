#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""واجهة GitHub كاملة — مستقلة بلا اعتماد على أي ملف."""
import json, os, subprocess, urllib.request, urllib.error

def token():
    t = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
    if not t:
        for f in (".secrets.gh_token", ".secrets/gh_token", ".gh_token", "auth.json"):
            if not os.path.exists(f): continue
            try:
                t = json.load(open(f)).get("token", "") if f.endswith(".json") else open(f).read()
            except Exception: t = ""
            t = (t or "").strip()
            if t: break
    return t

def api(path, method="GET", data=None, tok=None):
    tok = tok or token()
    url = path if path.startswith("http") else "https://api.github.com" + path
    body = json.dumps(data).encode() if data is not None else None
    r = urllib.request.Request(url, data=body, method=method, headers={
        "Authorization": "Bearer " + tok, "Accept": "application/vnd.github+json",
        "User-Agent": "CineHub3099", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r, timeout=40) as x:
            raw = (x.read().decode() or "{}").strip()
            return json.loads(raw) if raw[:1] in "{[(" else {"raw": raw}
    except urllib.error.HTTPError as e:
        try: return json.loads(e.read().decode() or "{}")
        except Exception: return {}
    except Exception:
        return {}

def login(t=None):
    return (api("/user", tok=t or token()) or {}).get("login", "")

def repo_name(u=None):
    return (u or login()) + ".github.io"

def ensure_repo(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    if (api("/repos/%s/%s" % (u, r), tok=t) or {}).get("full_name"): return True
    return bool((api("/user/repos", "POST",
        {"name": r, "private": False, "auto_init": True, "default_branch": "main"}, t) or {}).get("full_name"))

def enable_pages(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    api("/repos/%s/%s/pages" % (u, r), "POST", {"source": {"branch": "main", "path": "/"}}, t)
    api("/repos/%s/%s/pages" % (u, r), "PUT", {"source": {"branch": "main", "path": "/"}}, t)
    return "https://%s.github.io/" % u

def push(u=None, r=None, t=None):
    t = t or token(); u = u or login(t); r = r or (u + ".github.io")
    url = "https://x-access-token:%s@github.com/%s/%s.git" % (t, u, r)
    subprocess.run("git add -A", shell=True, capture_output=True)
    subprocess.run("git -c user.email=a@c.local -c user.name=Agent commit -m update",
                   shell=True, capture_output=True)
    p = subprocess.run("git push --force %s main" % url, shell=True, capture_output=True, text=True)
    return p.returncode == 0, (p.stdout + p.stderr)
