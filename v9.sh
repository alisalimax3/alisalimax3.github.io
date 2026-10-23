#!/usr/bin/env bash
BASE="$HOME/cinehub3099"; cd "$BASE"
mkdir -p tools data logs/shots backups
tar czf "backups/pre_v9_$(date +%s).tgz" tools data keys.env 2>/dev/null; echo "✓ نسخة احتياطية"

echo "══ 1. تنظيف العمليات الميتة ══"
pkill -f "chromium.*cinehub3099" 2>/dev/null
pkill -f "termux-x11" 2>/dev/null
rm -f data/profiles/*/Singleton* data/profiles/*/lockfile 2>/dev/null
sleep 1; echo "✓ نُظّف"

echo "══ 2. cdp: نقر حقيقي + تنظيف قفل + Input ══"
python3 - << 'PY'
p = "tools/cdp.py"
s = open(p, encoding="utf-8").read()

s = s.replace('''    def _launch(self, headless):
        a = list(self._argv_base)''',
'''    def _clean_locks(self):
        import glob
        for pat in ("Singleton*","lockfile"):
            for f in glob.glob(os.path.join(self._profile, pat)):
                try: os.remove(f)
                except Exception: pass

    def _launch(self, headless):
        self._clean_locks()
        a = list(self._argv_base)''')

s = s.replace('        self.logp = os.path.join(profile_dir, "chromium.log")\n        self.headless = headless',
              '        self._profile = profile_dir\n        self.logp = os.path.join(profile_dir, "chromium.log")\n        self.headless = headless')

if "def click_xy" not in s:
    s = s.replace('''    def shot(self, path):
        r = self.send("Page.captureScreenshot", {"format":"png"})''',
'''    def click_xy(self, x, y):
        self.send("Input.dispatchMouseEvent", {"type":"mouseMoved","x":x,"y":y,"buttons":0})
        time.sleep(0.06)
        self.send("Input.dispatchMouseEvent", {"type":"mousePressed","x":x,"y":y,"button":"left","buttons":1,"clickCount":1})
        time.sleep(0.09)
        self.send("Input.dispatchMouseEvent", {"type":"mouseReleased","x":x,"y":y,"button":"left","buttons":0,"clickCount":1})

    def box(self, sel):
        r = self.ev("(function(){var e=document.querySelector(%s);if(!e)return null;var r=e.getBoundingClientRect();if(r.width<1)return null;return {x:r.left+r.width/2,y:r.top+r.height/2,w:r.width,h:r.height};})()" % json.dumps(sel))
        return r

    def shot(self, path):
        r = self.send("Page.captureScreenshot", {"format":"png"})''')
open(p,"w",encoding="utf-8").write(s)
print("✓ cdp")
PY

echo "══ 3. inject.js: مسح frames + نقر كابتشا ══"
python3 - << 'PY'
p = "tools/inject.js"
s = open(p, encoding="utf-8").read()
if "scanAll" not in s:
    s = s.replace("  ready: function(){ return document.readyState; }",
'''  ready: function(){ return document.readyState; },
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
        var w = fr[i].contentWindow;
        if(!w || !w.__ch) continue;
        var sub = w.__ch.scan();
        for(var j=0;j<sub.length;j++){ sub[j].fr = i+1; out.push(sub[j]); }
      }catch(e){}
    }
    return out;
  },
  _w: function(fr){
    if(!fr) return window;
    var f = document.querySelectorAll('iframe')[fr-1];
    return (f && f.contentWindow) ? f.contentWindow : window;
  },
  putF: function(fr,i,v){ try{ var w=window.__ch._w(fr); var el=w.document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; w.__ch.put(i,v); return true; }catch(e){ return false; } },
  putSelF: function(fr,i,t){ try{ var w=window.__ch._w(fr); return w.__ch.putSel(i,t); }catch(e){ return ''; } },
  checkF: function(fr,i){ try{ var w=window.__ch._w(fr); return w.__ch.check(i); }catch(e){ return false; } },
  captchaBox: function(){
    var sels = ['iframe[src*="recaptcha/api2/anchor"]','iframe[title*="reCAPTCHA"]',
                'iframe[src*="hcaptcha"]','iframe[title*="hCaptcha"]','iframe[src*="turnstile"]'];
    for(var s=0;s<sels.length;s++){
      var f = document.querySelector(sels[s]);
      if(!f) continue;
      var r = f.getBoundingClientRect();
      if(r.width<4||r.height<4) continue;
      if(r.top < -50 || r.top > 4000) continue;
      return {x: r.left + Math.min(28, r.width/2), y: r.top + r.height/2, w: r.width, h: r.height, kind: sels[s]};
    }
    return null;
  },
  submitAll: function(){
    var t = window.__ch.submitBtn();
    if(t) return t;
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){
      try{ var w=fr[i].contentWindow; if(w && w.__ch && w.__ch.submitBtn()) return w.__ch.submitBtn(); }catch(e){}
    }
    return '';
  }''')
open(p,"w",encoding="utf-8").write(s)
print("✓ inject.js")
PY

echo "══ 4. autoreg: كسر الكابتشا آلياً + frames + منع الانهيار ══"
python3 - << 'PY'
p = "tools/autoreg.py"
s = open(p, encoding="utf-8").read()

s = s.replace('''def fill(tab, profile):
    vals = _vals(profile); n = 0
    for f in (tab.ev("window.__ch.scan()") or []):''',
'''def fill(tab, profile):
    vals = _vals(profile); n = 0
    for f in (tab.ev("window.__ch.scanAll()") or []):''')
s = s.replace('if tab.ev("window.__ch.put(%d, %s)" % (f["i"], json.dumps(str(vals[fld])))): n += 1',
              'if tab.ev("window.__ch.putF(%d, %d, %s)" % (f.get("fr",0), f["i"], json.dumps(str(vals[fld])))): n += 1')
s = s.replace('''    for f in (tab.ev("window.__ch.scan()") or []):
        if f.get("tag") != "select": continue''',
'''    for f in (tab.ev("window.__ch.scanAll()") or []):
        if f.get("tag") != "select": continue''')
s = s.replace('r = tab.ev("window.__ch.putSel(%d, %s)" % (f["i"], json.dumps(cand)))',
              'r = tab.ev("window.__ch.putSelF(%d, %d, %s)" % (f.get("fr",0), f["i"], json.dumps(cand)))')
s = s.replace('''    for f in (tab.ev("window.__ch.scan()") or []):
        if f.get("type") != "checkbox" or not f.get("vis") or f.get("checked"): continue''',
'''    for f in (tab.ev("window.__ch.scanAll()") or []):
        if f.get("type") != "checkbox" or not f.get("vis") or f.get("checked"): continue''')
s = s.replace('if tab.ev("window.__ch.check(%d)" % f["i"]): n += 1',
              'if tab.ev("window.__ch.checkF(%d, %d)" % (f.get("fr",0), f["i"])): n += 1')

s = s.replace('''def wait_captcha(tab, timeout=300):''',
'''def try_click_captcha(tab, tries=3):
    """نقر آلي حقيقي على مربع الكابتشا"""
    for k in range(tries):
        try: st = tab.ev("window.__ch.captcha()")
        except Exception: st = ""
        if not st or st.endswith("-solved"): return bool(st and st.endswith("-solved"))
        try: b = tab.ev("window.__ch.captchaBox()")
        except Exception: b = None
        if not b: time.sleep(1); continue
        core.log("نقر آلي على الكابتشا (%s) عند %d,%d" % (b.get("kind","?")[:22], b["x"], b["y"]), "info")
        try: tab.click_xy(b["x"], b["y"])
        except Exception: pass
        time.sleep(3.2)
        try: st = tab.ev("window.__ch.captcha()")
        except Exception: st = ""
        if st and st.endswith("-solved"):
            core.log("✓ الكابتشا حُلّت آلياً", "ok"); return True
    return False

def wait_captcha(tab, timeout=300):''')

s = s.replace('''            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                core.log("كابتشا موجودة قبل الإرسال", "warn"); wait_captcha(tab, 300)
            btn = tab.ev("window.__ch.submitBtn()")''',
'''            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                if not try_click_captcha(tab, 2):
                    if captcha.key(): pass
                    else:
                        core.log("كابتشا عصيّة — انتظار", "warn"); wait_captcha(tab, 240)
            btn = tab.ev("window.__ch.submitAll()")''')

s = s.replace('''            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                wait_captcha(tab, 300)
                tab.ev("window.__ch.clickBtn()"); tab.settle(25); time.sleep(2)''',
'''            cap = tab.ev("window.__ch.captcha()")
            if cap == "present":
                if not try_click_captcha(tab, 2): wait_captcha(tab, 240)
                tab.ev("window.__ch.clickBtn()"); tab.settle(25); time.sleep(2)''')

# بعد التأكيد: احصد من لوحة التحكم
s = s.replace('''        if net["verify"] == "email" and mailbox.configured():
            core.log("فحص بريد التحقق...", "info")
            if mailbox.confirm(net["id"]):
                record(net, "confirmed", key)
                tab.go(net["signup"]); time.sleep(2)''',
'''        if net["verify"] == "email" and mailbox.configured():
            core.log("فحص بريد التحقق...", "info")
            if mailbox.confirm(net["id"]):
                record(net, "confirmed", key)
                for u in (net["login"], net["payout_page"], net["signup"]):
                    if key: break
                    try:
                        tab.go(u, timeout=30); time.sleep(2)
                        k2, _ = harvest(tab, net)
                        if k2: key = k2; core.log("مفتاح من لوحة التحكم: %s" % k2, "ok")
                    except Exception: pass''')
open(p,"w",encoding="utf-8").write(s)
print("✓ autoreg")
PY

# ═══════════ autoflow: خط التنفيذ الحقيقي ═══════════
cat > tools/autoflow.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""خط تنفيذ حقيقي — تسجيل متدرّج بالمصادر الفورية"""
import sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, repo, autoreg, ledger

TIERS = {
 1: ["adsterra","monetag","popads","clickadu","aads","popcash","admaven","evadav"],
 2: [n["id"] for n in registry.by_cat("shortlinks")],
 3: ["freecash","timewall","lootably","adgate","adgem","wannads","bitlabs","cpx","attapoll","cointiply","faucetpay"],
 4: ["cpagrip","ogads","adworkmedia","adscend","maxbounty","driguid"],
 5: [n["id"] for n in registry.by_cat("cpa")] + [n["id"] for n in registry.by_cat("surveys")],
}

def plan(tier):
    ids = TIERS.get(tier, [])
    out = []
    for i in ids:
        try:
            n = registry.by_id(i)
            if not core.env(n["key_env"]): out.append(i)
        except KeyError: pass
    return out

def run(tier=1, show=False, limit=0):
    ids = plan(tier)
    if limit: ids = ids[:limit]
    if not ids:
        core.log("لا شيء ناقص في المرحلة %d" % tier, "ok"); return
    core.log("المرحلة %d: %d موقع | كابتشا آلي=%s | بريد=%s"
             % (tier, len(ids), "نعم" if core.env("CAPTCHA_KEY") else "نقر آلي",
                "نعم" if core.env("MAIL_APP_PASS") else "لا"), "info")
    ok, fail = [], []
    for k, i in enumerate(ids, 1):
        core.log("─── [%d/%d] %s ───" % (k, len(ids), i), "info")
        try:
            if autoreg.register(i, show=show): ok.append(i)
            else: fail.append(i)
        except KeyboardInterrupt:
            core.log("توقف يدوي", "warn"); break
        except Exception as e:
            core.log("%s: %s" % (i, e), "err"); fail.append(i)
        time.sleep(1.2)
    print("\n%s══ النتيجة ══%s" % (core.C['b'], core.C['x']))
    core.log("نجح: %d | فشل: %d" % (len(ok), len(fail)), "ok" if ok else "warn")
    if ok: core.log("نجح: %s" % ", ".join(ok), "ok")
    if fail: core.log("فشل: %s" % ", ".join(fail), "warn")
    r, m = repo.push("autoflow tier%d: +%d" % (tier, len(ok)))
    core.log(m, "ok" if r else "warn")

if __name__ == "__main__":
    t = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    run(t, show=("--show" in sys.argv))
PYEOF

# ═══════════ verify_keys ═══════════
cat > tools/verify_keys.py << 'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""التحقق من صحة صيغة المفاتيح المحفوظة"""
import re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry

SUSPECT = re.compile(r"^(install|python|pip|true|false|none|undefined)$", re.I)

def main():
    ok, sus, empty = [], [], []
    for n in registry.ALL:
        v = core.env(n["key_env"])
        if not v: empty.append(n["id"]); continue
        if SUSPECT.match(v) or len(v) < 3: sus.append((n["id"], n["key_env"], v)); continue
        ok.append(n["id"])
    print("\n%s══ تحقق المفاتيح ══%s" % (core.C['b'], core.C['info'], core.C['x']))
    core.log("صحيحة: %d" % len(ok), "ok")
    core.log("مشكوك فيها: %d" % len(sus), "warn" if sus else "ok")
    for i,k,v in sus: print("    %-18s %-22s = %s" % (i,k,v[:40]))
    core.log("فارغة: %d" % len(empty), "info")
    if len(empty) < 40:
        print("\n    الفارغة: %s" % ", ".join(empty))
    return 0 if not sus else 1

if __name__ == "__main__": sys.exit(main())
PYEOF

# ═══════════ ربط الأوامر ═══════════
python3 - << 'PY'
p = "tools/agent.py"
s = open(p, encoding="utf-8").read()
if 'c == "autoflow"' not in s:
    s = s.replace('    elif c == "audit":',
'''    elif c == "autoflow":
        import autoflow
        t = int(a[1]) if a[1:2] and a[1].isdigit() else 1
        lim = 0
        for x in a:
            if x.startswith("--limit="): lim = int(x.split("=")[1])
        autoflow.run(t, show=("--show" in a), limit=lim)
    elif c == "verify":
        import verify_keys; sys.exit(verify_keys.main())
    elif c == "restart":
        import subprocess, glob, os, time
        subprocess.run(["pkill","-f","chromium.*cinehub3099"])
        for f in glob.glob("data/profiles/*/Singleton*") + glob.glob("data/profiles/*/lockfile"):
            try: os.remove(f)
            except Exception: pass
        core.load_env()
        core.log("أُعيد التشغيل | مصادر=%d بمفاتيح=%d" % (len(registry.ALL), len(registry.with_key())), "ok")
    elif c == "audit":''')
    s = s.replace('  audit                   فحص شامل حقيقي',
'''  autoflow <مرحلة>         تنفيذ تلقائي متدرّج (1..5)
  verify                  التحقق من صحة المفاتيح
  restart                 إعادة تشغيل نظيفة
  audit                   فحص شامل حقيقي''')
    open(p,"w",encoding="utf-8").write(s)
print("✓ agent")
PY

python3 -m py_compile tools/*.py && echo "✓ كل الملفات تُترجم"
echo ""
echo "✅ v9 جاهز — النقر الآلي للكابتشا مفعّل"
