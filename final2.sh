#!/data/data/com.termux/files/usr/bin/bash
set -u
cd "$HOME/cinehub3099" || exit 1
mkdir -p logs
LOG="logs/final2_$(date +%H%M%S).log"
say(){ printf '\n\033[1;36m══ %s ══\033[0m\n' "$*" | tee -a "$LOG"; }
ok(){  printf '\033[1;32m✓\033[0m %s\n' "$*" | tee -a "$LOG"; }
bad(){ printf '\033[1;31m✗\033[0m %s\n' "$*" | tee -a "$LOG"; }

say "1 · تثبيت الشاشة الافتراضية"
if ! command -v Xvfb >/dev/null 2>&1; then
  pkg update -y >/dev/null 2>&1
  pkg install -y xorg-server-xvfb xorg-xdpyinfo 2>&1 | tail -4 | tee -a "$LOG"
fi
command -v Xvfb >/dev/null 2>&1 && ok "Xvfb مثبّت" || bad "نفّذ يدوياً: pkg install -y xorg-server-xvfb"

say "2 · تشغيل الشاشة على :0"
export DISPLAY=:0
if xdpyinfo >/dev/null 2>&1; then ok "الشاشة تعمل مسبقاً"
else
  (Xvfb :0 -screen 0 1366x900x24 -nolisten tcp >/dev/null 2>&1 &)
  sleep 4
  if xdpyinfo >/dev/null 2>&1; then ok "Xvfb :0 يعمل"
  else bad "الشاشة لم تعمل — أرسل لي مخرجات Xvfb"; fi
fi
grep -q 'DISPLAY=:0' ~/.bashrc 2>/dev/null || echo 'export DISPLAY=:0' >> ~/.bashrc

say "3 · تحصين cdp.py: ev آمن + scan + reinject"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, pathlib
p = pathlib.Path("tools/cdp.py"); s = p.read_text(encoding="utf-8")
changed = False

if "def ev_safe" not in s:
    m = re.search(r'class\s+Tab\b.*?\n(    def\s+\w+\()', s, re.S)
    assert m, "لا يوجد class Tab"
    s = s[:m.start(1)] + '''    def ev_safe(self, js, *a, **k):
        """تقييم JS بلا انهيار — يرجع None عند الفشل"""
        try:
            return self.ev(js, *a, **k)
        except Exception:
            return None

    def reinject(self):
        """يعيد حقن __ch إن ضاع بعد تنقّل (صفحة Cloudflare = مستند جديد)"""
        if self.ev_safe("!!window.__ch"):
            return True
        try:
            import pathlib as _pl
            js = _pl.Path(__file__).with_name("inject.js").read_text(encoding="utf-8")
        except Exception:
            return False
        return bool(self.ev_safe(js))

    def scan(self):
        """يرجع الحقول المرئية دائماً — حتى على صفحات Cloudflare"""
        if not self.ev_safe("!!window.__ch"):
            self.reinject()
        return self.ev_safe("(window.__ch&&window.__ch.scan)?window.__ch.scan():[]") or []

''' + s[m.start(1):]
    changed = True

if 'f = self.ev("window.__ch.scan()") or []' in s:
    s = s.replace('f = self.ev("window.__ch.scan()") or []', 'f = self.scan()')
    changed = True

if "self.wait_cf(30); self.reinject()" not in s and "_orig_go" in s:
    s = s.replace("        try: self.wait_cf(30)\n        except Exception: pass",
                  "        try:\n            self.wait_cf(30); self.reinject()\n        except Exception: pass")
    changed = True

p.write_text(s, encoding="utf-8")
print("cdp.py محصّن" if changed else "cdp.py محصّن مسبقاً")
PY
python3 -m py_compile tools/cdp.py && ok "cdp.py يُترجم"

say "4 · منفّذ chromium نهائي (بلا كشف أتمتة + بلا GPU)"
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
  --disable-gpu --window-size=1366,900 --lang=en-US \
  --no-first-run --no-default-browser-check --no-sandbox \
  "${args[@]}" \
  --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36"
EOF
chmod +x bin/chromium-browser && ok "جاهز"
export PATH="$PWD/bin:$PATH"

say "5 · اختبار Cloudflare — الوضع المرئي"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import sys, os, time
sys.path.insert(0, "tools")
import cdp, core
headless = not os.environ.get("DISPLAY")
print("الوضع:", "headless" if headless else "مرئي (Xvfb)")
ch = cdp.Chrome(str(core.DATA/"profiles"/"_cf"), headless=headless, timeout=60)
try:
    t = ch.tab()
    t.go("https://publishers.adsterra.com/signup", timeout=45)
    time.sleep(3)
    ti = t.title()
    print("العنوان:", ti)
    f = [x for x in t.scan() if x.get("vis")]
    print("حقول مرئية:", len(f))
    for x in f[:12]:
        print("   ", x.get("tag"), "| name=", x.get("name"), "| id=", x.get("id"), "| type=", x.get("type"))
    print("النتيجة:", "✓ تجاوز Cloudflare" if "just a moment" not in (ti or "").lower() else "✗ ما زال محجوباً")
finally:
    ch.close()
PY

say "6 · توليد أكواد الإعلانات لموقعك الحقيقي"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import pathlib, json
env = {}
p = pathlib.Path("keys.env")
if p.exists():
    for l in p.read_text(encoding="utf-8").splitlines():
        if "=" in l and not l.strip().startswith("#"):
            k, _, v = l.partition("="); env[k.strip()] = v.strip()
out = pathlib.Path("site"); out.mkdir(exist_ok=True)
c = []
if env.get("ADSTERRA_ZONE"):
    c.append('<script async src="//www.highperformanceformat.com/%s/invoke.js"></script>' % env["ADSTERRA_ZONE"])
if env.get("MONETAG_MULTITAG"):
    c.append('<script src="//nap5k.com/tag/%s" data-cfasync="false"></script>' % env["MONETAG_MULTITAG"])
if env.get("POPADS_SITE") or env.get("POPADS_ZONE"):
    c.append('<!-- PopAds site id: %s -->' % (env.get("POPADS_SITE") or env.get("POPADS_ZONE")))
(out/"ads.html").write_text('<div id="ads">\n' + "\n".join(c) + "\n</div>\n", encoding="utf-8")
(out/"ads.json").write_text(json.dumps(env, indent=1, ensure_ascii=False), encoding="utf-8")
print("كُتب site/ads.html (%d كود) + site/ads.json" % len(c))
PY

say "7 · ربط الموقع الحقيقي (alisalimax3.github.io)"
if [ -d "$HOME/alisalimax3.github.io" ]; then
  cp -f site/ads.html "$HOME/alisalimax3.github.io/ads.html" && ok "نُسخ ads.html"
  ( cd "$HOME/alisalimax3.github.io" \
    && git add -A \
    && git -c user.email=a@c.local -c user.name=Agent commit -m "ads: live zones" >/dev/null 2>&1 \
    && timeout 240 git push 2>&1 | tail -2 | tee -a "$LOG" \
    && ok "رُفع الموقع" ) || bad "فشل الرفع"
else
  bad "لم أجد ~/alisalimax3.github.io — أرسل المسار الصحيح"
fi

say "تم"
echo "  export DISPLAY=:0 && export PATH=\"\$HOME/cinehub3099/bin:\$PATH\""
echo "  ./run.sh reg adsterra --show"
echo "  ./run.sh reg exoclick --show"
echo "  ./run.sh reg juicyads --show"
echo "  ./run.sh reg crakrevenue --show"
