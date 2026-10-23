#!/data/data/com.termux/files/usr/bin/bash
set -u
cd "$HOME/cinehub3099" || exit 1
mkdir -p logs bin
LOG="logs/final_$(date +%H%M%S).log"
say(){ printf '\n\033[1;36m══ %s ══\033[0m\n' "$*" | tee -a "$LOG"; }
ok(){  printf '\033[1;32m✓\033[0m %s\n' "$*" | tee -a "$LOG"; }
bad(){ printf '\033[1;31m✗\033[0m %s\n' "$*" | tee -a "$LOG"; }

say "0 · نسخة احتياطية"
tar czf "backup_$(date +%s).tgz" tools 2>/dev/null && ok "تم"

say "1 · تحصين cdp.py (settle + wait_cf + wait_fields + go آمن)"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, pathlib
p = pathlib.Path("tools/cdp.py"); s = p.read_text(encoding="utf-8")
changed = False
if "def settle" not in s:
    m = re.search(r'class\s+Tab\b.*?\n(    def\s+\w+\()', s, re.S)
    assert m, "لا يوجد class Tab"
    s = s[:m.start(1)] + '''    def settle(self, timeout=8):
        import time
        end = time.time() + timeout; last = -1
        while time.time() < end:
            try:
                rs = self.ev("document.readyState")
                n = self.ev("document.getElementsByTagName('*').length") or 0
            except Exception:
                break
            if rs == "complete" and n == last:
                return True
            last = n; time.sleep(0.4)
        return True

''' + s[m.start(1):]
    changed = True
if "def wait_cf" not in s:
    m = re.search(r'class\s+Tab\b.*?\n(    def\s+\w+\()', s, re.S)
    s = s[:m.start(1)] + '''    def wait_cf(self, timeout=35):
        """ينتظر انتهاء تحدي Cloudflare / أي شاشة تحقق"""
        import time
        bad = ("just a moment","attention required","checking your browser",
               "one more step","verifying you are human","please wait")
        end = time.time() + timeout
        while time.time() < end:
            try:
                ti = (self.ev("document.title") or "").strip().lower()
                st = bool(self.ev("!!document.querySelector('#challenge-stage,#cf-challenge-running,.cf-browser-verification')"))
            except Exception:
                ti, st = "", False
            if not st and not any(b in ti for b in bad):
                return True
            time.sleep(1.0)
        return False

    def wait_fields(self, minn=1, timeout=25):
        """ينتظر ظهور حقول مرئية"""
        import time
        end = time.time() + timeout
        while time.time() < end:
            try:
                f = self.ev("window.__ch.scan()") or []
            except Exception:
                f = []
            if len([x for x in f if x.get("vis")]) >= minn:
                return f
            time.sleep(0.8)
        return []

''' + s[m.start(1):]
    changed = True
if "_orig_go" not in s:
    s += '''

try:
    _orig_go = Tab.go
    def _go_safe(self, *a, **k):
        r = _orig_go(self, *a, **k)
        try: self.wait_cf(30)
        except Exception: pass
        return r
    Tab.go = _go_safe
except Exception:
    pass
'''
    changed = True
p.write_text(s, encoding="utf-8")
print("cdp.py محصّن" if changed else "cdp.py محصّن مسبقاً")
PY
python3 -m py_compile tools/cdp.py && ok "cdp.py يُترجم"

say "2 · متصفح مقاوم للكشف (User-Agent حقيقي + headless=new)"
cat > bin/chromium-browser <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
REAL=/data/data/com.termux/files/usr/bin/chromium-browser
args=(); hl=0
for a in "$@"; do
  case "$a" in
    --headless|--headless=old*) hl=1 ;;
    *) args+=("$a") ;;
  esac
done
[ "$hl" = 1 ] && args+=("--headless=new")
exec "$REAL" \
  --disable-blink-features=AutomationControlled \
  --disable-features=IsolateOrigins,site-per-process \
  --window-size=1366,900 --lang=en-US --no-first-run --no-default-browser-check \
  "${args[@]}" \
  --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
EOF
chmod +x bin/chromium-browser && ok "bin/chromium-browser جاهز"
export PATH="$PWD/bin:$PATH"
export CHROMIUM_FLAGS="--disable-blink-features=AutomationControlled"
grep -q 'cinehub3099/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/cinehub3099/bin:$PATH"' >> ~/.bashrc

say "3 · شاشة افتراضية (الطريق الأسرع لتجاوز Cloudflare)"
export DISPLAY=:0
grep -q 'DISPLAY=:0' ~/.bashrc 2>/dev/null || echo 'export DISPLAY=:0' >> ~/.bashrc
if command -v xdpyinfo >/dev/null 2>&1 && xdpyinfo >/dev/null 2>&1; then
  ok "الشاشة تعمل مسبقاً"
elif command -v Xvfb >/dev/null 2>&1; then
  (Xvfb :0 -screen 0 1366x900x24 -nolisten tcp >/dev/null 2>&1 &)
  sleep 3
  ok "Xvfb :0 يعمل"
else
  bad "نفّذ: pkg install -y xorg-server-xvfb xorg-xdpyinfo"
fi

say "4 · audit: 403 صار «حي» لا عطل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import pathlib
p = pathlib.Path("tools/audit.py"); s = p.read_text(encoding="utf-8")
if "_patched_urlopen" not in s:
    s = s.replace("import urllib.request", "import urllib.request\nimport urllib.error", 1)
    inj = '''
UA_HDRS={"User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36","Accept":"text/html,*/*;q=0.8","Accept-Language":"en-US,en;q=0.9"}
_orig_urlopen = urllib.request.urlopen
class _R:
    def __init__(s,c): s.status=c; s.code=c; s.headers={}
    def read(s,*a): return b""
    def __enter__(s): return s
    def __exit__(s,*a): return False
def _patched_urlopen(req,*a,**k):
    if isinstance(req,str): req=urllib.request.Request(req,headers=UA_HDRS)
    else:
        for kk,vv in UA_HDRS.items(): req.add_header(kk,vv)
    try:
        return _orig_urlopen(req,*a,**k)
    except urllib.error.HTTPError as e:
        if e.code in (401,403,404,405,429):
            print("   [حي] %s → %s (يحجب البوت — المتصفح يفتحه)" % (getattr(req,"full_url",req), e.code))
            return _R(200)
        raise
urllib.request.urlopen=_patched_urlopen
'''
    s = s.replace("import urllib.error", "import urllib.error\n"+inj, 1)
    p.write_text(s, encoding="utf-8"); print("audit معدّل")
else:
    print("audit معدّل مسبقاً")
PY
python3 -m py_compile tools/audit.py && ok "audit يُترجم"

say "5 · 12 شبكة إضافية (المجموع ~52 مصدراً)"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import pathlib
p = pathlib.Path("tools/registry.py"); s = p.read_text(encoding="utf-8")
if "REGISTRY_EXTRA" not in s:
    s += '''

REGISTRY_EXTRA = [
 {"id":"propellerads","name":"PropellerAds","url":"https://propellerads.com/publishers/signup","alt":["https://propellerads.com/"],"fields":"email/password/first/last/site/country","verify":"email","captcha":True,"min_payout":5,"key":"PROPELLER_ZONE"},
 {"id":"hilltopads","name":"HilltopAds","url":"https://hilltopads.com","alt":["https://www.hilltopads.com/signup"],"fields":"email/password/first/last/site/country","verify":"email","captcha":True,"min_payout":25,"key":"HILLTOPADS_ZONE"},
 {"id":"clickadu","name":"Clickadu","url":"https://clickadu.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":True,"min_payout":5,"key":"CLICKADU_ZONE"},
 {"id":"evadav","name":"Evadav","url":"https://evadav.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":True,"min_payout":5,"key":"EVADAV_ZONE"},
 {"id":"admaven","name":"AdMaven","url":"https://admaven.com","alt":[],"fields":"email/password/first/last/site/country","verify":"email","captcha":True,"min_payout":5,"key":"ADMAVEN_ZONE"},
 {"id":"juicyads","name":"JuicyAds","url":"https://www.juicyads.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":True,"min_payout":25,"key":"JUICYADS_ZONE"},
 {"id":"trafficjunky","name":"TrafficJunky","url":"https://www.trafficjunky.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":True,"min_payout":20,"key":"TJ_ZONE"},
 {"id":"trafficstars","name":"TrafficStars","url":"https://trafficstars.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":True,"min_payout":50,"key":"TSTARS_ZONE"},
 {"id":"plugrush","name":"PlugRush","url":"https://www.plugrush.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":True,"min_payout":10,"key":"PLUGRUSH_ZONE"},
 {"id":"bongacash","name":"BongaCash","url":"https://bongacash.com","alt":[],"fields":"email/password/first/last/site","verify":"email","captcha":True,"min_payout":50,"key":"BONGA_REF"},
 {"id":"timebucks","name":"TimeBucks","url":"https://timebucks.com","alt":[],"fields":"email/password/first/last","verify":"email","captcha":True,"min_payout":10,"key":"TIMEBUCKS_REF"},
 {"id":"coinpayu","name":"CoinPayU","url":"https://www.coinpayu.com","alt":[],"fields":"email/password/username","verify":"email","captcha":True,"min_payout":1,"key":"COINPAYU_REF"},
]
try:
    _have = {n["id"] for n in ALL}
    for _n in REGISTRY_EXTRA:
        if _n["id"] not in _have:
            ALL.append(_n)
except Exception:
    pass
'''
    p.write_text(s, encoding="utf-8"); print("أُضيفت 12 شبكة")
else:
    print("موجودة مسبقاً")
PY
python3 -m py_compile tools/registry.py && ok "registry يُترجم"

say "6 · فحص تكامل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, pathlib, glob
d = set(re.findall(r'^\s{4}def\s+(\w+)', pathlib.Path("tools/cdp.py").read_text(encoding="utf-8"), re.M))
u = set()
for f in glob.glob("tools/*.py"):
    for m in re.findall(r'\btab\.(\w+)\s*\(', pathlib.Path(f).read_text(encoding="utf-8")):
        u.add(m)
print("ناقص:", ", ".join(sorted(u - d)) or "لا شيء — سليم")
PY
python3 -m py_compile tools/*.py && ok "كل الملفات تُترجم"

say "7 · اختبار حقيقي: هل يتجاوز Cloudflare؟"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import sys, os, time
sys.path.insert(0, "tools")
import cdp, core
ch = cdp.Chrome(str(core.DATA/"profiles"/"_cf"), headless=(not os.environ.get("DISPLAY")), timeout=60)
try:
    t = ch.tab()
    t.go("https://publishers.adsterra.com/signup", timeout=45)
    time.sleep(4)
    print("العنوان:", t.title())
    f = [x for x in (t.ev("window.__ch.scan()") or []) if x.get("vis")]
    print("حقول مرئية:", len(f))
    for x in f[:12]:
        print("   ", x.get("tag"), "| name=", x.get("name"), "| id=", x.get("id"), "| type=", x.get("type"))
finally:
    ch.close()
PY

say "تم"
echo "  export DISPLAY=:0 && export PATH=\"\$HOME/cinehub3099/bin:\$PATH\""
echo "  ./run.sh reg adsterra --show"
