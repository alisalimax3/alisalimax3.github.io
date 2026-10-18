import json
import time
import http.client
import urllib.request
import urllib.error
#!/usr/bin/env python3
# ناشر GitHub حقيقي عبر Git Data API — يرفع دفعة واحدة ويمسح node_modules
import os, sys, json, base64, re, glob, urllib.request, urllib.error

OWNER, REPO, BRANCH = "alkazmybwhwr-dot", "alkazmybwhwr-dot.github.io", "main"
SRC = os.path.expanduser("~/cinehub3099")
KEEP = sorted(glob.glob(os.path.join(SRC,"b","*.html")))
KEEP = ["index.html","live.js","sw.js","manifest.json","icon.svg","og.png",
        "robots.txt","sitemap.xml","partners.html","identity.json","revenue.html","earn.html","surveys.html","withdraw.html","surveys.js","surveys-config.json","payouts.json","REGISTER.md","ads.js","analytics.js","ads-config.json","wallet.json","README.md",".nojekyll"]

def find_token():
    p = os.path.join(SRC, ".gh-token")
    if os.path.exists(p):
        t = open(p).read().strip()
        if t: return t
    for v in ("GITHUB_TOKEN","GH_TOKEN"):
        if os.environ.get(v): return os.environ[v].strip()
    cands = [os.path.join(SRC,f) for f in ("gh.py","deploy.sh",".token","token.txt")]
    cands += [os.path.expanduser(p) for p in
              ("~/.github_token","~/.ghtoken","~/.config/gh/hosts.yml","~/.git-credentials")]
    for p in cands:
        if os.path.exists(p):
            m = re.search(r'gh[pousr]_[A-Za-z0-9]{30,}', open(p, errors="ignore").read())
            if m: return m.group(0)
    return None

TOK = find_token()
if not TOK:
    print("✗ لا توكن — نفّذ:  python3 auth.py"); print("  نفّذ:  export GITHUB_TOKEN=ghp_xxx  ثم أعد المحاولة")
    print("  أو ضع التوكن في ~/cinehub3099/.token"); sys.exit(1)

def api(method, path, body=None, tries=6):
    """GitHub API + إعادة محاولة (يحل RemoteDisconnected)."""
    url = "https://api.github.com" + path
    data = json.dumps(body).encode() if body is not None else None
    last = None
    for attempt in range(1, tries + 1):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", "Bearer " + TOKEN)
        req.add_header("Accept", "application/vnd.github+json")
        req.add_header("User-Agent", "cinehub-publish")
        req.add_header("Content-Type", "application/json")
        req.add_header("Connection", "close")
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read().decode()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            if e.code in (500, 502, 503, 504):
                last = e; time.sleep(2 * attempt); continue
            raise
        except (http.client.RemoteDisconnected, ConnectionResetError,
                ConnectionAbortedError, TimeoutError, urllib.error.URLError) as e:
            last = e
            if attempt == tries: break
            print("  ... retry %d/%d" % (attempt, tries)); time.sleep(2 * attempt)
    raise RuntimeError("فشل API بعد %d محاولات: %s" % (tries, last))
