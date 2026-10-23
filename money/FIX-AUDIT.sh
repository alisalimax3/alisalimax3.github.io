#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  FIX-AUDIT — إصلاح جذري لأخطاء AUDITOR + تقليل الضجيج 25195 → ~700
#  نسخة احتياطية → إصلاح دقيق بسطر محدّد → تحقق → إعادة فحص كامل
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
L="$H/lib"; BK="$H/audit/backup-fix-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BK" "$ROOT/assets"
say(){ printf '%s\n' "$*"; }

say "═══════ 0) نسخة احتياطية ═══════"
for f in "$L/q-db.js" "$L/q-load.js" "$L/q-util.js" "$L/q-lint.js" "$L/q-fix.js" "$L/q-sec.js" "$L/async.js" \
         "$ROOT/payout.js" "$ROOT/rewarded.js" "$ROOT/catalog.json" "$ROOT/.gitignore" "$ROOT/keys.env"; do
  [ -f "$f" ] && cp "$f" "$BK/$(basename "$f")" && say "  ✔ $(basename "$f")"
done
say "  ↩ للرجوع: cp -f $BK/* $L/ 2>/dev/null"

say "═══════ 1) إصلاح دقيق + تحقق لكل ملف ═══════"
python3 - "$L" "$ROOT" <<'PY'
import os,re,sys,json,shutil,subprocess,base64
L,ROOT=sys.argv[1],sys.argv[2]
NODE=shutil.which("node") or "node"
rd=lambda p: open(p,encoding="utf-8").read()
wr=lambda p,s: open(p,"w",encoding="utf-8").write(s)
def check(p):
    try: subprocess.run([NODE,"--check",p],capture_output=True,timeout=30,check=True); return True
    except Exception: return False
def patch(p,fnx,label=None):
    label=label or os.path.basename(p)
    if not os.path.exists(p): print("  ○ %s غير موجود"%label); return
    s=rd(p); n=fnx(s)
    if n==s: print("  ○ %s لا يحتاج تعديلًا"%label); return
    wr(p,n)
    if p.endswith(".js") and not check(p):
        wr(p,s); print("  ✗ %s — استُرجع (فشل --check)"%label); return
    print("  ✔ %s"%label)

# 1) q-db.js:5 — IIFE بلا أقواس → SyntaxError
def f_qdb(s):
    s=s.replace('const hasSqlite=()=>{','const hasSqlite=(()=>{',1)
    return s.replace('return false;}}();','return false;}})();',1)
patch(os.path.join(L,"q-db.js"),f_qdb,"lib/q-db.js")

# 2) q-load.js:17 — path غير مُستدعى → ReferenceError
patch(os.path.join(L,"q-load.js"),
      lambda s: s.replace('const http=require("http"),U=require("./q-util.js");',
                          'const http=require("http"),path=require("path"),U=require("./q-util.js");',1),
      "lib/q-load.js")

# 3) q-util.js — SKIP يمنع دخول .tmp + data/profiles (25195 ملف → ~700)
patch(os.path.join(L,"q-util.js"),
      lambda s: s.replace(
        'const SKIP=new Set(["node_modules",".git","logs","_backup","_deploy","audit",".cache","storage","__pycache__",".idea"]);',
        'const SKIP=new Set(["node_modules",".git","logs","_backup","_deploy","audit",".cache","storage","__pycache__",".idea",".tmp","profiles",".check","dist","build",".venv",".npm"]);',1),
      "lib/q-util.js")

# 4) node → process.execPath (يمنع EACCES من spawnSync)
f_exe=lambda s: s.replace('execFileSync("node",["--check"','execFileSync(process.execPath,["--check"')
patch(os.path.join(L,"q-lint.js"),f_exe,"lib/q-lint.js")
patch(os.path.join(L,"q-fix.js"),f_exe,"lib/q-fix.js")

# 5) q-sec.js — لا تعتبر الاسم/البريد/المحفظة أسرارًا مكشوفة
patch(os.path.join(L,"q-sec.js"),
      lambda s: s.replace('secrets.push({k,v});',
        'if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER)$/.test(k))secrets.push({k,v});',1),
      "lib/q-sec.js")

# 6) async.js:18 — ternary مكسور
patch(os.path.join(L,"async.js"),
      lambda s: re.sub(r'(?m)^\s*console\.log\(ok\?.*$',
        '  console.log(ok?("  ✔ رُفع إلى https://github.com/"+user+"/"+repo):("  ○ "+out.slice(0,100)));', s, count=1),
      "lib/async.js")

# 7) rewarded.js — قوس ناقص في filter
patch(os.path.join(ROOT,"rewarded.js"),
      lambda s: s.replace('n.enabled&&n.keys.popunder)[0]','n.enabled&&n.keys.popunder;})[0]',1),
      "rewarded.js")

# 8) payout.js — \n حرفي داخل الكود
def fixnl(s):
    out=[];i=0;q=None
    while i<len(s):
        c=s[i]
        if q:
            out.append(c)
            if c=="\\" and i+1<len(s): out.append(s[i+1]); i+=2; continue
            if c==q: q=None
            i+=1; continue
        if c in "'\"`": q=c; out.append(c); i+=1; continue
        if c=="\\" and i+1<len(s) and s[i+1] in "nt":
            out.append("\n" if s[i+1]=="n" else "\t"); i+=2; continue
        out.append(c); i+=1
    return "".join(out)
patch(os.path.join(ROOT,"payout.js"),fixnl,"payout.js")

# 9) catalog.json — فواصل زائدة
p=os.path.join(ROOT,"catalog.json")
if os.path.exists(p):
    s=rd(p)
    try: json.loads(s); print("  ○ catalog.json سليم")
    except Exception as e1:
        s2=re.sub(r',(\s*[}\]])',r'\1',s)
        try: json.loads(s2); wr(p,s2); print("  ✔ catalog.json — أُصلحت الفواصل الزائدة")
        except Exception as e2: print("  ⚠ catalog.json — %s"%str(e2)[:70])

# 10) .gitignore
p=os.path.join(ROOT,".gitignore"); cur=rd(p) if os.path.exists(p) else ""
need=["node_modules","keys.env","logs","*.pid","_backup","_deploy",".cache","__pycache__",".tmp"]
miss=[x for x in need if x not in cur]
if miss: wr(p,(cur.rstrip()+"\n"+"\n".join(miss)+"\n").lstrip("\n")); print("  ✔ .gitignore — %s"%", ".join(miss))
else: print("  ○ .gitignore سليم")

# 11) keys.env — تنظيم + 600
p=os.path.join(ROOT,"keys.env")
if os.path.exists(p):
    m={}
    for l in rd(p).split("\n"):
        i=l.find("=")
        if i>0 and not l.lstrip().startswith("#"): m[l[:i].strip()]=l[i+1:].strip()
    clean="\n".join(k+"="+m[k] for k in sorted(m))+"\n"
    if clean!=rd(p): wr(p,clean); print("  ✔ keys.env — نُظّف (%d مفتاح)"%len(m))
    try: os.chmod(p,0o600)
    except Exception: pass

# 12) صلاحيات الملفات الحسّاسة
for f in ["logs/codes.log","logs/vault.json","money/data/vault.enc","money/data/secrets.json","money/db/creds.json"]:
    q=os.path.join(ROOT,f)
    if os.path.exists(q):
        try: os.chmod(q,0o600)
        except Exception: pass

# 13) أصل ثابت للأيقونة (يمنع broken-ref في صفحات SEO)
lp=os.path.join(ROOT,"assets","logo.png")
if not os.path.exists(lp):
    open(lp,"wb").write(base64.b64decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="))
    print("  ✔ assets/logo.png")
print("  ── انتهى الإصلاح ──")
PY

say "═══════ 2) تحقق سريع من النواة ═══════"
for f in q-db.js q-load.js q-lint.js q-fix.js q-util.js q-sec.js; do
  node --check "$L/$f" >/dev/null 2>&1 && say "  ✔ lib/$f" || say "  ✗ lib/$f"
done
node "$L/q-db.js" init && say "  ✔ قاعدة البيانات تعمل"

say "═══════ 3) إعادة الفحص الكامل + الإصلاح الآمن ═══════"
bash "$H/AUDIT.sh" all --apply

say "═══════ 4) الحالة النهائية ═══════"
bash "$H/AUDIT.sh" status
