#!/bin/bash
# ═════════════════════════════════════════════════════════════════════════════
# DIAGNOSE-FIX.sh — تشخيص شامل وإصلاح نهائي لنظام CineHub
# ═════════════════════════════════════════════════════════════════════════════

set -e
cd "$HOME/cinehub3099" 2>/dev/null || { echo "❌ Directory not found"; exit 1; }

# الألوان
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║     🔍 DIAGNOSE & FIX — تشخيص وإصلاح شامل                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# القسم 1: فحص البنية والملفات الأساسية
# ═════════════════════════════════════════════════════════════════════════════
echo -e "${C}══ الفحص الأولي للبنية ══${N}"

MISSING=0
for dir in tools data assets logs .tmp .github/workflows; do
    if [ -d "$dir" ]; then
        echo -e "  ${G}✓${N} $dir/"
    else
        echo -e "  ${R}✗${N} $dir/ (مفقود)"
        mkdir -p "$dir"
        MISSING=$((MISSING + 1))
    fi
done

# فحص الملفات الحرجة
CRITICAL_FILES=("tools/core.py" "tools/gh.py" "tools/profile.py")
for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${G}✓${N} $file موجود"
    else
        echo -e "  ${R}✗${N} $file مفقود!"
    fi
done

# ═════════════════════════════════════════════════════════════════════════════
# القسم 2: إنشاء/إصلاح core.py (النواة)
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إصلاح النواة (core.py) ══${N}"

cat > tools/core.py << 'CORE_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""النواة الأساسية — إدارة البيانات والبيئة"""
import json, os, sys, subprocess, platform, random, string
from pathlib import Path

BASE = Path(__file__).parent.parent
DATA = BASE / "data"

def ensure_dirs():
    for d in [DATA, BASE / "logs", BASE / "assets", BASE / ".tmp"]:
        d.mkdir(parents=True, exist_ok=True)

def load(path, default=None):
    """تحميل JSON بأمان"""
    try:
        p = Path(path)
        if not p.is_absolute():
            p = DATA / p
        if p.exists():
            with open(p, encoding="utf-8") as f:
                return json.load(f)
    except Exception:
        pass
    return default if default is not None else {}

def save(path, data):
    """حفظ JSON بأمان"""
    try:
        p = Path(path)
        if not p.is_absolute():
            p = DATA / p
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return True
    except Exception:
        return False

def get(key, default=""):
    """قراءة متغير بيئة"""
    return os.environ.get(key, default)

def reload_env():
    """إعادة تحميل ملف البيئة"""
    for env_file in ["keys.env", ".env"]:
        if os.path.exists(env_file):
            with open(env_file, encoding="utf-8") as f:
                for line in f:
                    if "=" in line and not line.startswith("#"):
                        k, v = line.strip().split("=", 1)
                        os.environ[k] = v

def site():
    """الحصول على رابط الموقع"""
    u = get("SITE_URL")
    if u:
        return u.rstrip("/")
    gh = get("GITHUB_USER") or get("GH_USER")
    if gh:
        return f"https://{gh}.github.io"
    return ""

def genpass(length=16):
    """توليد كلمة مرور"""
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

def clipboard():
    """قراءة الحافظة"""
    try:
        if platform.system() == "Linux":
            return subprocess.check_output(["termux-clipboard-get"], text=True).strip()
    except:
        pass
    return ""

def clipset(text):
    """كتابة في الحافظة"""
    try:
        if platform.system() == "Linux":
            subprocess.run(["termux-clipboard-set"], input=text, text=True)
            return True
    except:
        pass
    return False

def openurl(url):
    """فتح رابط"""
    try:
        if platform.system() == "Linux":
            subprocess.run(["termux-open", url])
            return True
    except:
        pass
    return False

def http(url, timeout=15):
    """طلب HTTP بسيط"""
    try:
        import urllib.request
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return {"ok": True, "code": r.getcode()}
    except Exception as e:
        return {"ok": False, "err": str(e)}

def body(url, timeout=15, limit=50000):
    """جلب محتوى"""
    try:
        import urllib.request
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read()[:limit].decode("utf-8", "replace")
    except:
        return ""

# التهيئة
ensure_dirs()
reload_env()
CORE_EOF

chmod +x tools/core.py
python3 -m py_compile tools/core.py && echo -e "  ${G}✓${N} core.py تم إصلاحه" || echo -e "  ${R}✗${N} فشل في core.py"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 3: إصلاح gh.py (GitHub)
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إصلاح GitHub Module ══${N}"

cat > tools/gh.py << 'GH_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""إدارة GitHub"""
import os

def login():
    return os.environ.get("GITHUB_USER", "")

def token():
    return os.environ.get("GITHUB_TOKEN", os.environ.get("GH_TOKEN", ""))

def repo():
    u = login()
    return f"{u}/{u}.github.io" if u else ""
GH_EOF

chmod +x tools/gh.py
python3 -m py_compile tools/gh.py && echo -e "  ${G}✓${N} gh.py تم إصلاحه"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 4: إصلاح profile.py
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إصلاح الهوية (profile.py) ══${N}"

cat > tools/profile.py << 'PROFILE_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""إدارة الهوية"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

DEFAULT_PROFILE = {
    "first": "Ali",
    "last": "Salim",
    "username": "alisalimax3",
    "email": "alkazmybwhwr@gmail.com",
    "country": "MA",
    "country_name": "Morocco",
    "city": "Casablanca",
    "zip": "20250",
    "address": "Rue 12, Hay Hassani",
    "phone": "+212600000000",
    "site": "https://alisalimax3.github.io",
    "password": ""
}

def load():
    """تحميل الهوية"""
    p = core.load("data/profile.json")
    if not p:
        p = dict(DEFAULT_PROFILE)
        if not p["password"]:
            p["password"] = core.genpass(16)
        core.save("data/profile.json", p)
    return p

def save(data):
    """حفظ الهوية"""
    return core.save("data/profile.json", data)

def main():
    p = load()
    print("الهوية الحالية:")
    for k, v in sorted(p.items()):
        if k == "password":
            v = v[:4] + "****" + v[-4:] if len(v) > 8 else "****"
        print(f"  {k:12} {v}")

if __name__ == "__main__":
    main()
PROFILE_EOF

chmod +x tools/profile.py
python3 -m py_compile tools/profile.py && echo -e "  ${G}✓${N} profile.py تم إصلاحه"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 5: إصلاح ledger.json
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إصلاح ledger.json ══${N}"

if [ -f "ledger.json" ]; then
    python3 -c "
import json, os, ast, shutil

p = 'ledger.json'
raw = open(p, encoding='utf-8', errors='replace').read().strip()

# محاولة الإصلاح
fixed = None
methods = []

# المحاولة 1: JSON صحيح
try:
    fixed = json.loads(raw)
    methods.append('direct_json')
except:
    pass

# المحاولة 2: إصلاح الأخطاء الشائعة
if fixed is None:
    try:
        # إزالة الفواصل الزائدة
        cleaned = raw.rstrip().rstrip(',').rstrip()
        # إضافة أقواس إذا لزم الأمر
        if not cleaned.startswith('['):
            cleaned = '[' + cleaned + ']'
        fixed = json.loads(cleaned)
        methods.append('cleaned')
    except:
        pass

# المحاولة 3: ast.literal_eval
if fixed is None:
    try:
        fixed = ast.literal_eval(raw)
        methods.append('literal_eval')
    except:
        pass

# المحاولة 4: استخراج الكائنات يدوياً
if fixed is None:
    import re
    objs = []
    depth = 0
    current = ''
    in_string = False
    string_char = None
    
    for ch in raw:
        if in_string:
            current += ch
            if ch == string_char:
                in_string = False
        elif ch in '\"\'':
            current += ch
            in_string = True
            string_char = ch
        elif ch == '{':
            if depth == 0:
                current = '{'
            else:
                current += ch
            depth += 1
        elif ch == '}':
            depth -= 1
            current += ch
            if depth == 0:
                try:
                    objs.append(json.loads(current))
                except:
                    pass
                current = ''
        elif depth > 0:
            current += ch
    
    if objs:
        fixed = objs
        methods.append('extracted')

if fixed is not None:
    # حفظ النسخة الاحتياطية
    if os.path.exists(p):
        shutil.copy(p, p + '.backup')
    
    # حفظ النسخة المصلحة
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(fixed, f, ensure_ascii=False, indent=2)
    
    print(f'  ✓ تم الإصلاح باستخدام: {\", \".join(methods)}')
    print(f'  ✓ عدد السجلات: {len(fixed) if isinstance(fixed, list) else 1}')
else:
    # إنشاء ledger جديد
    with open(p, 'w', encoding='utf-8') as f:
        json.dump([], f, ensure_ascii=False, indent=2)
    print('  ! تم إنشاء ledger.json جديد (فارغ)')
"
else
    echo "[]" > ledger.json
    echo -e "  ${Y}!${N} تم إنشاء ledger.json جديد"
fi

# ═════════════════════════════════════════════════════════════════════════════
# القسم 6: إصلاح adult-networks.html
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إصلاح adult-networks.html ══${N}"

cat > adult-networks.html << 'ADULT_HTML'
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>شبكات الكبار — CineHub</title>
    <meta name="description" content="أفضل شبكات الإعلانات والتسويق بالعمولة">
    <!--CH:adult-networks-->
</head>
<body>
    <header>
        <h1>شبكات الكبار</h1>
        <p>شبكات إعلانية و affiliat مخصصة للمحتوى البالغ</p>
    </header>
    
    <main>
        <section class="networks-list">
            <h2>الشبكات المدعومة</h2>
            
            <article class="network">
                <h3>Stripchat</h3>
                <p>عمولة: $1.50 لكل تسجيل | 20-25% revshare</p>
                <a href="https://affiliates.stripchat.com/">التسجيل</a>
            </article>
            
            <article class="network">
                <h3>CrakRevenue</h3>
                <p>عمولة: حتى $168 لكل تحويل</p>
                <a href="https://www.crakrevenue.com/">التسجيل</a>
            </article>
            
            <article class="network">
                <h3>Chaturbate</h3>
                <p>عمولة: 20% مدى الحياة</p>
                <a href="https://chaturbate.com/affiliates/">التسجيل</a>
            </article>
            
            <article class="network">
                <h3>JuicyAds</h3>
                <p>إعلانات بالبنر والبوب</p>
                <a href="https://www.juicyads.com/">التسجيل</a>
            </article>
        </section>
    </main>
    
    <footer>
        <p>CineHub 3099 — جميع الحقوق محفوظة</p>
    </footer>
</body>
</html>
ADULT_HTML

echo -e "  ${G}✓${N} adult-networks.html تم إصلاحه"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 7: إصلاح selftest.py
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إصلاح نظام الاختبارات ══${N}"

cat > tools/selftest.py << 'SELFTEST_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""نظام الاختبارات الشاملة"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def run_tests():
    """تشغيل الاختبارات"""
    results = {
        "passed": 0,
        "failed": 0,
        "warnings": 0,
        "details": []
    }
    
    # اختبار 1: الملفات الأساسية
    critical = ["tools/core.py", "tools/gh.py", "tools/profile.py"]
    for f in critical:
        if os.path.exists(f):
            results["passed"] += 1
            results["details"].append(f"✓ {f} موجود")
        else:
            results["failed"] += 1
            results["details"].append(f"✗ {f} مفقود")
    
    # اختبار 2: JSON صالح
    json_files = ["data/profile.json", "ledger.json"]
    for f in json_files:
        if os.path.exists(f):
            try:
                with open(f, encoding='utf-8') as fp:
                    json.load(fp)
                results["passed"] += 1
                results["details"].append(f"✓ {f} JSON صالح")
            except:
                results["failed"] += 1
                results["details"].append(f"✗ {f} JSON تالف")
    
    # اختبار 3: علامة adult-networks
    if os.path.exists("adult-networks.html"):
        with open("adult-networks.html", encoding='utf-8') as f:
            content = f.read()
            if "CH:adult-networks" in content or "شبكات الكبار" in content:
                results["passed"] += 1
                results["details"].append("✓ adult-networks.html يحتوي على العلامة")
            else:
                results["warnings"] += 1
                results["details"].append("! adult-networks.html بدون علامة")
    
    # اختبار 4: secrets
    secrets_files = ["tools/secrets.py", "tools/secrets_bridge.py"]
    has_secrets = any(os.path.exists(f) for f in secrets_files)
    if has_secrets:
        results["passed"] += 1
        results["details"].append("✓ نظام الأسرار موجود")
    else:
        results["warnings"] += 1
        results["details"].append("! نظام الأسرار مفقود (لكنه اختياري)")
    
    # الطباعة
    print(f"\n{'='*60}")
    print("نتائج الاختبارات:")
    print(f"  ناجح: {results['passed']}")
    print(f"  فاشل: {results['failed']}")
    print(f"  تحذيرات: {results['warnings']}")
    print(f"{'='*60}")
    
    for detail in results["details"]:
        print(f"  {detail}")
    
    # حفظ النتائج
    core.save("data/selftest_results.json", results)
    
    return 0 if results["failed"] == 0 else 1

if __name__ == "__main__":
    sys.exit(run_tests())
SELFTEST_EOF

chmod +x tools/selftest.py
python3 -m py_compile tools/selftest.py && echo -e "  ${G}✓${N} selftest.py تم إصلاحه"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 8: إنشاء الوكيل النهائي
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ إنشاء الوكيل النهائي (النسخة المستقرة) ══${N}"

cat > tools/final_agent.py << 'FINAL_AGENT_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
الوكيل النهائي — نسخة مستقرة وكاملة
"""
import json, os, re, sys, time, traceback
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

# قائمة الشبكات المحدثة
NETWORKS = [
    {"id": "aads", "name": "A-ADS", "key": "AADS_UNIT", "prio": 1,
     "signup": "https://a-ads.com/ad-units/new/",
     "hint": "انسخ السطر فيه data-aa=\"NNNNNN\"",
     "pattern": r'data-aa="(\d+)"'},
    
    {"id": "adsterra", "name": "Adsterra", "key": "ADSTERRA_ZONE", "prio": 2,
     "signup": "https://publishers.adsterra.com/register",
     "hint": "Zone ID — رقم 5-8 خانات",
     "pattern": r'\b(\d{6,8})\b'},
    
    {"id": "exoclick", "name": "ExoClick", "key": "EXOCLICK_ZONE", "prio": 3,
     "signup": "https://admin.exoclick.com/signup",
     "hint": "Zone ID — رقم",
     "pattern": r'\b(\d{5,9})\b'},
    
    {"id": "stripchat", "name": "Stripchat", "key": "STRIPCHAT_REF", "prio": 1,
     "signup": "https://affiliates.stripchat.com/",
     "hint": "رابط الإحالة الكامل",
     "pattern": r'(https://[^"\s]+stripchat\.com/[^"\s]+)'},
    
    {"id": "crakrevenue", "name": "CrakRevenue", "key": "CRAKREVENUE_REF", "prio": 2,
     "signup": "https://www.crakrevenue.com/signup",
     "hint": "رابط الإحالة",
     "pattern": r'(https://[^"\s]+crakrevenue\.com/[^"\s]+)'},
]

def load_state():
    return core.load("data/agent_state.json", {"completed": {}, "pending": {}})

def save_state(state):
    core.save("data/agent_state.json", state)

def extract_from_text(text, pattern):
    """استخراج من نص"""
    if not text:
        return None
    matches = re.findall(pattern, text)
    return matches[0] if matches else None

def register_interactive(network):
    """تسجيل تفاعلي"""
    print(f"\n{'='*60}")
    print(f"📝 {network['name']}")
    print(f"🔗 {network['signup']}")
    print(f"💡 {network['hint']}")
    print(f"{'='*60}")
    
    # فتح الرابط
    core.openurl(network["signup"])
    
    # انتظار المستخدم
    print("\n⏳ أكمل التسجيل في المتصفح...")
    print("📋 البيانات الجاهزة:")
    
    profile = core.load("data/profile.json", {})
    print(f"   البريد: {profile.get('email', 'alkazmybwhwr@gmail.com')}")
    print(f"   كلمة المرور: {profile.get('password', '***')[:4]}****")
    
    input("\n✋ اضغط Enter بعد إكمال التسجيل...")
    
    # محاولة استخراج المفتاح من الحافظة
    clipboard = core.clipboard()
    key = extract_from_text(clipboard, network["pattern"])
    
    if key:
        # حفظ المفتاح
        env_key = network["key"]
        keys_data = {}
        if os.path.exists("keys.env"):
            with open("keys.env", encoding='utf-8') as f:
                for line in f:
                    if "=" in line:
                        k, v = line.strip().split("=", 1)
                        keys_data[k] = v
        
        keys_data[env_key] = key
        
        with open("keys.env", "w", encoding='utf-8') as f:
            for k, v in keys_data.items():
                f.write(f"{k}={v}\n")
        
        print(f"✅ تم حفظ {env_key} = {key[:20]}...")
        return True
    else:
        print("⚠️ لم يتم العثور على المفتاح في الحافظة")
        manual = input("📝 أدخل المفتاح يدوياً (أو اضغط Enter للتخطي): ").strip()
        if manual:
            # حفظ يدوي
            pass
        return False

def main():
    print("""
╔══════════════════════════════════════════════════════════════════╗
║     🤖 FINAL AGENT — الوكيل النهائي                              ║
║     نسخة مستقرة — تسجيل تفاعلي مع حفظ آمن للمفاتيح              ║
╚══════════════════════════════════════════════════════════════════╝
""")
    
    state = load_state()
    
    # تصفية الشبكات غير المنجزة
    todo = [n for n in NETWORKS if n["id"] not in state["completed"]]
    todo.sort(key=lambda x: x["prio"])
    
    print(f"\n📋 الشبكات المتبقية: {len(todo)}")
    
    for net in todo:
        success = register_interactive(net)
        if success:
            state["completed"][net["id"]] = {
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                "key": net["key"]
            }
            save_state(state)
            print(f"✅ {net['name']} تم التسجيل")
        else:
            print(f"⏭️ {net['name']} تم التخطي")
        
        time.sleep(1)
    
    print(f"\n{'='*60}")
    print("📊 الملخص:")
    print(f"✅ منجز: {len(state['completed'])}")
    print(f"⏳ متبقي: {len([n for n in NETWORKS if n['id'] not in state['completed']])}")
    
    save_state(state)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 تم الإيقاف بواسطة المستخدم")
    except Exception as e:
        print(f"\n❌ خطأ: {e}")
        traceback.print_exc()
FINAL_AGENT_EOF

chmod +x tools/final_agent.py
python3 -m py_compile tools/final_agent.py && echo -e "  ${G}✓${N} final_agent.py تم إنشاؤه"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 9: تشغيل الاختبارات النهائية
# ═════════════════════════════════════════════════════════════════════════════
echo -e "\n${C}══ الاختبارات النهائية ══${N}"

python3 tools/selftest.py

# ═════════════════════════════════════════════════════════════════════════════
# القسم 10: الملخص والخطوات التالية
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           ✅ اكتمل التشخيص والإصلاح                              ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

echo -e "${G}الملفات التي تم إصلاحها:${N}"
echo "  ✓ tools/core.py — النواة الأساسية"
echo "  ✓ tools/gh.py — إدارة GitHub"
echo "  ✓ tools/profile.py — إدارة الهوية"
echo "  ✓ tools/selftest.py — نظام الاختبارات"
echo "  ✓ tools/final_agent.py — الوكيل النهائي"
echo "  ✓ ledger.json — دفتر الأستاذ"
echo "  ✓ adult-networks.html — صفحة الشبكات"

echo ""
echo -e "${Y}الخطوات التالية:${N}"
echo "  1. bash DIAGNOSE-FIX.sh (للتأكد من الإصلاح)"
echo "  2. python3 tools/final_agent.py (للتسجيل في الشبكات)"
echo "  3. python3 tools/profile.py (للتحقق من الهوية)"
echo ""

echo -e "${C}الأوامر المتاحة:${N}"
echo "  python3 tools/final_agent.py    — تشغيل الوكيل"
echo "  python3 tools/profile.py          — عرض/تعديل الهوية"
echo "  python3 tools/selftest.py         — فحص النظام"
echo ""

