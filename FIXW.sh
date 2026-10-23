#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  FIXW.sh — إصلاح جذري: تعارض secrets · userwallet · adult-networks ·
#            أدوات الفحص الناقصة · ledger.json · ثم نشر
#  bash FIXW.sh        إصلاح + اختبار + نشر
#  bash FIXW.sh reg    إصلاح + نشر + تشغيل وكيل التسجيل
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || exit 1
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data
LOG="logs/fixw.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
V0="$(python3 -c "import json;print(json.load(open('data/vault.json')).get('balance_usd',0))" 2>/dev/null || echo 0)"

# ─────────────── 1 · الإصلاح الجذري: tools/secrets.py يحجب secrets القياسي
hd "1 · إصلاح تعارض secrets (يصلح كل أدواتك لا أداة واحدة)"
cp tools/secrets.py ".tmp/secrets.py.pre" 2>/dev/null
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, subprocess, sys
p = "tools/secrets.py"
s = open(p, encoding="utf-8").read()
BRIDGE = '''

# ══ جسر: هذا الملف يحجب وحدة secrets القياسية (نفس الاسم في sys.path) ══
# نُعيد تصدير واجهة الوحدة القياسية كي لا تنهار أي أداة تستخدم secrets.choice
import importlib.util as _ilu, sysconfig as _sc, os as _os
def _bridge():
    cands = [_os.path.join(_sc.get_paths().get("stdlib", ""), "secrets.py"),
             _os.path.join(_sc.get_paths().get("stdlib", ""), "lib-dynload", "..", "secrets.py")]
    for c in cands:
        if not _os.path.exists(c): continue
        try:
            spec = _ilu.spec_from_file_location("_stdlib_secrets", c)
            m = _ilu.module_from_spec(spec); spec.loader.exec_module(m)
            for n in ("choice","randbelow","randbits","token_bytes","token_hex",
                      "token_urlsafe","compare_digest","SystemRandom","DEFAULT_ENTROPY"):
                if hasattr(m, n) and n not in globals(): globals()[n] = getattr(m, n)
            return True
        except Exception: continue
    return False
_BRIDGED = _bridge()

def genpass(n=15):
    """كلمة مرور قوية — بلا اعتماد على secrets إن فشل الجسر."""
    alpha = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    b = _os.urandom(n)
    return "".join(alpha[x % len(alpha)] for x in b)
'''
if "جسر: هذا الملف يحجب" not in s:
    open(p, "w", encoding="utf-8").write(s.rstrip() + BRIDGE)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ جسر secrets مُركّب" if r.returncode == 0 else "✗ " + r.stderr.decode()[-110:]))
if r.returncode: __import__("shutil").copy(".tmp/secrets.py.pre", p)
PY
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import sys
sys.path.insert(0, "tools")
import secrets as S
print("  اختبار: secrets.choice →", "✓" if hasattr(S, "choice") else "✗")
print("  اختبار: genpass →", S.genpass(12) if hasattr(S, "genpass") else "—")
PY

# ─────────────── 2 · إزالة الاعتماد على secrets في أدوات الوكيل
hd "2 · wizard.py و agent_register.py — مولّد مستقل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, subprocess, sys
SAFE = '''def gen_pass(n=15):
    import os as _o
    a = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(a[x % len(a)] for x in _o.urandom(n))
'''
for p, old in (("tools/wizard.py", "def gen_pass(n=15):"),
               ("tools/agent_register.py", "def newpass(n=14):")):
    try: s = open(p, encoding="utf-8").read()
    except Exception: print("  ! %s مفقود" % p); continue
    if "import os as _o" in s: print("  · %s مُصلح أصلًا" % p); continue
    name = "newpass" if "newpass" in old else "gen_pass"
    fn = SAFE.replace("gen_pass", name).replace("(n=15)", "(n=14)" if name == "newpass" else "(n=15)")
    s = re.sub(r"def %s\(n=\d+\):\n(?:    .*\n)+" % name, fn, s, count=1)
    if name not in s: s = s.replace("def main():", fn + "\ndef main():", 1)
    open(p, "w", encoding="utf-8").write(s)
    r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
    print("  " + ("✓ %s" % p if r.returncode == 0 else "✗ %s %s" % (p, r.stderr.decode()[-90:])))
PY

# ─────────────── 3 · userwallet: %d بلا مفتاح داخل صيغة dict
hd "3 · userwallet.py — إصلاح صيغة النسبة"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import re, subprocess, sys
p = "tools/userwallet.py"
s = open(p, encoding="utf-8").read()
n = s.count("%d%%")
s = s.replace("%d%%", "%(cut)d%%")
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  استُبدل %d موضع · %s" % (n, "✓" if r.returncode == 0 else "✗ " + r.stderr.decode()[-100:]))
if r.returncode == 0:
    rr = subprocess.run([sys.executable, p], capture_output=True, text=True, timeout=60)
    print("  " + ("✓ userwallet يعمل" if rr.returncode == 0 else "✗ " + (rr.stderr or "").strip().splitlines()[-1][:110]))
PY

# ─────────────── 4 · adult_registry: علامة adult-networks
hd "4 · adult_registry.py — كتابة adult-networks.html بعلامة صحيحة"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import subprocess, sys
p = "tools/adult_registry.py"
s = open(p, encoding="utf-8").read()
if "شبكات الكبار" not in s:
    old = '        core.write_if_changed("income.html", HTML)'
    new = '''        AD = [p for p in r["providers"] if p.get("adult_ok") == "yes"]
        rows2 = "".join("<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td>"
                        "<td><a target='_blank' rel='nofollow noopener' href='%s'>↗</a></td></tr>"
                        % (core.esc(p["name"]), core.esc(p["type"]), core.esc(p["min_payout"]),
                           core.esc(p["account_status"]), p["official_url"]) for p in AD)
        core.write_if_changed("adult-networks.html",
            HTML.replace("<h1>مصادر الدخل", "<h1>🔞 شبكات الكبار")
                .replace('<th>النوع</th><th>المفتاح</th><th>حد السحب</th><th>التكرار</th><th>الحالة</th>',
                         '<th>النوع</th><th>حد السحب</th><th>الحالة</th>')
                .replace(rows, rows2))
        core.write_if_changed("income.html", HTML)'''
    s = s.replace(old, new, 1)
open(p, "w", encoding="utf-8").write(s)
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
print("  " + ("✓ adult_registry" if r.returncode == 0 else "✗ " + r.stderr.decode()[-100:]))
if r.returncode == 0:
    rr = subprocess.run([sys.executable, p], capture_output=True, text=True, timeout=60)
    print("  " + ((rr.stdout or "").strip().splitlines()[-1][:110] if rr.returncode == 0
                  else "✗ " + (rr.stderr or "").strip().splitlines()[-1][:110]))
    import os
    if os.path.exists("adult-networks.html"):
        c = open("adult-networks.html", encoding="utf-8").read()
        print("  علامة «شبكات الكبار»: %s · الحجم %d" % ("موجودة" if "شبكات الكبار" in c else "مفقودة", len(c)))
PY

# ─────────────── 5 · أدوات الفحص الناقصة
hd "5 · aads_verify.py + live_verify.py (كانتا مفقودتين)"
cat > tools/aads_verify.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجرّب كل مرشّح لمعرّف A-ADS ويقول أيها يُخدم فعلًا (HTTP + حجم + كلمات)."""
import os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
NUM = re.compile(r"\b(\d{4,8})\b")

def score(b):
    b = (b or "").lower(); s = 0
    for k, w in (("a-ads", 3), ("ads", 1), ("iframe", 2), ("banner", 2), ("<div", 1)): 
        if k in b: s += w
    for k in ("not found", "invalid", "undefined"): 
        if k in b: s -= 2
    return s

def probe(i):
    out = []
    for host in ("acceptable.a-ads.com", "ad.a-ads.com"):
        u = "https://%s/%s?size=300x250" % (host, i)
        b = core.body(u, timeout=12, limit=20000)
        out.append({"host": host, "size": len(b), "score": score(b)})
    return out

def main():
    cands, cur = [], core.get("AADS_UNIT")
    if cur: cands.append(cur)
    for f in ("keys.env", ".env", ".tmp/keys.env.bak"):
        if os.path.exists(f):
            for l in open(f, encoding="utf-8", errors="ignore"):
                if "AADS" in l.upper(): cands += NUM.findall(l)
    seen, order = set(), []
    for c in cands:
        if c and c not in seen: seen.add(c); order.append(c)
    res, best = [], None
    for c in order[:10]:
        r = probe(c); g = max(x["score"] for x in r); sz = max(x["size"] for x in r)
        okk = sz > 400 and g > 2
        res.append({"id": c, "ok": okk, "score": g, "size": sz, "res": r})
        print("    %s %-8s حجم=%-6s درجة=%d" % ("✓" if okk else "✗", c, sz, g))
        if okk and (best is None or g > best["score"]): best = res[-1]
    core.save("data/aads_verify.json", {"at": time.strftime("%F %H:%M"), "current": cur,
              "results": res, "best": best["id"] if best else None})
    if best:
        print("  ✓ الأفضل: %s" % best["id"])
        if best["id"] != cur:
            print("  ! الحالي %s مرفوض → صحّح AADS_UNIT=%s" % (cur or "—", best["id"]))
    else:
        print("  ✗ لا مرشّح يُخدم — أنشئ Ad Unit من a-ads.com/ad-units/new/")
    if cur: print("  · الحالي: %s" % cur)

if __name__ == "__main__": main()
PYEOF

cat > tools/live_verify.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص الموقع المنشور فعليًا — دليل لا ادّعاء."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
PATHS = ["/", "/adult.html", "/m/", "/new.html", "/best.html", "/me.html", "/rewards.html",
         "/share.html", "/promote-adult.html", "/owner.html", "/income.html",
         "/sitemap.xml", "/sitemap-adult.xml", "/robots.txt", "/manifest.json", "/hits.js"]
def main():
    s = core.site()
    if not s: print("  ✗ لا SITE_URL"); return
    r = {}
    for p in PATHS:
        c = core.http(s + p, timeout=12)
        r[p] = c.get("code")
        print("  %s %-22s %s" % ("✓" if c.get("code") == 200 else "✗", p, c.get("code") or c.get("err")))
    core.save("data/live.json", {"at": core.time.strftime("%F %H:%M"), "site": s, "paths": r})
    print("  منشور %d · مفقود %d" % (len([x for x in r.values() if x == 200]),
                                     len([x for x in r.values() if x != 200])))
if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/aads_verify.py tools/live_verify.py && ok "أُنشئتا"
python3 tools/aads_verify.py 2>&1 | tee -a "$LOG"

# ─────────────── 6 · ledger.json — إصلاح أقوى
hd "6 · ledger.json — إصلاح بعدّاد مراحل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import ast, json, os, re, shutil
p = "./ledger.json"
if not os.path.exists(p): print("  · غير موجود"); raise SystemExit
raw = open(p, encoding="utf-8", errors="replace").read()
print("  البداية: %r" % raw[:80])
try: json.loads(raw); print("  ✓ سليم"); raise SystemExit
except Exception: pass
def stages(t):
    yield t
    t1 = re.sub(r"//[^\n]*", "", t); yield t1
    t2 = re.sub(r"/\*.*?\*/", "", t1, flags=re.S); yield t2
    t3 = re.sub(r"\bTrue\b", "true", t2); t3 = re.sub(r"\bFalse\b", "false", t3)
    t3 = re.sub(r"\bNone\b", "null", t3); yield t3
    t4 = re.sub(r"([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:", r'\1"\2":', t3); yield t4
    t5 = re.sub(r",(\s*[}\]])", r"\1", t4); yield t5
    yield t5.replace("'", '"')
done = False
for i, c in enumerate(stages(raw.strip().lstrip("\ufeff"))):
    try:
        obj = json.loads(c)
        shutil.copy(p, p + ".bak")
        json.dump(obj, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("  ✓ أُصلح في المرحلة %d → %s" % (i, type(obj).__name__)); done = True; break
    except Exception as e: last = e
if not done:
    try:
        obj = ast.literal_eval(raw.strip())
        shutil.copy(p, p + ".bak")
        json.dump(obj, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
        print("  ✓ أُصلح بـliteral_eval"); done = True
    except Exception: pass
if not done:
    shutil.copy(p, p + ".broken")
    open(p, "w", encoding="utf-8").write('{"tx": {}}\n')
    print("  ! تعذّر — الأصل في ledger.json.broken · كُتب {} صالح")
PY

# ─────────────── 7 · تشغيل واختبار
hd "7 · تشغيل واختبار"
if pgrep -f agentd.sh >/dev/null 2>&1; then pkill -f agentd.sh; sleep 1; fi
for s in ads adult_build adult_registry fix_pages growth rewards dashboard userwallet custody adcheck; do
  printf '  · %-16s ' "$s"; python3 "tools/$s.py" >>"$LOG" 2>&1 && printf '%s✓%s\n' "$G" "$N" || printf '%s✗%s\n' "$R" "$N"
done
python3 tools/selftest.py 2>&1 | tail -18 | tee -a "$LOG"
ST="${PIPESTATUS[0]}"

# ─────────────── 8 · نشر
hd "8 · نشر"
if [ "$ST" = "0" ]; then
  U="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.login())" 2>/dev/null)"
  T="$(python3 -c "import sys;sys.path.insert(0,'tools');import gh;print(gh.token())" 2>/dev/null)"
  if [ -n "$U" ] && [ -n "$T" ]; then
    git remote remove origin 2>/dev/null
    git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
    rm -f .git/index.lock; git add -A; git add -f .github/workflows/agent.yml 2>/dev/null
    git -c user.email=a@c.local -c user.name=Agent commit -m "fix: secrets shadowing + userwallet fmt + adult-networks + verifiers + ledger" >/dev/null 2>&1
    git fetch origin main 2>/dev/null && git -c user.email=a@c.local -c user.name=Agent pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1
    timeout 2400 git push origin main 2>"$TMPDIR/e" && ok "رُفع" || bad "فشل: $(tail -2 "$TMPDIR/e" | head -1)"
    sleep 50; python3 tools/live_verify.py 2>&1 | tail -4 | tee -a "$LOG"
  else wrn "لا توكن"; fi
else wrn "الاختبارات فشلت ($ST)"; fi

V1="$(python3 -c "import json;print(json.load(open('data/vault.json')).get('balance_usd',0))" 2>/dev/null || echo 0)"
printf '\nالرصيد قبل $%s → بعد $%s %s\n' "$V0" "$V1" "$([ "$V0" = "$V1" ] && echo '✓ محفوظ' || echo '! تغيّر')"
rm -f .git/index.lock; setsid bash agentd.sh >> logs/agentd.log 2>&1 & sleep 2
pgrep -f agentd.sh >/dev/null && ok "الوكيل يعمل" || wrn "لم يبدأ"

if [ "${1:-}" = "reg" ]; then hd "9 · وكيل التسجيل"; bash REGISTER.sh; fi
printf '\n%sتم — لتشغيل وكيل التسجيل: bash REGISTER.sh%s\n' "$B" "$N"
