import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "tools"))
import core
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CineHub Auto-Fix v3.0 — الإصلاح التلقائي الشامل
"""

import os
import sys
import subprocess
import json
from pathlib import Path

class AutoFix:
    def __init__(self):
        self.base = Path.home() / "cinehub3099"
        self.issues_found = []
        self.issues_fixed = []
        
    def log(self, msg, status="info"):
        colors = {
            "success": "\033[92m",
            "error": "\033[91m", 
            "warning": "\033[93m",
            "info": "\033[94m",
            "bold": "\033[1m",
            "end": "\033[0m"
        }
        color = colors.get(status, colors["info"])
        print(f"{color}{msg}{colors['end']}")
    
    def fix_playwright(self):
        """تثبيت Playwright"""
        self.log("\n══ تثبيت Playwright ══", "bold")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "playwright", "beautifulsoup4"], 
                        check=True, capture_output=True)
            subprocess.run([sys.executable, "-m", "playwright", "install", "chromium"],
                        check=True, capture_output=True)
            self.log("✓ Playwright مثبت", "success")
            return True
        except Exception as e:
            self.log(f"✗ فشل: {e}", "error")
            return False
    
    def fix_core_py(self):
        """إصلاح core.py النهائي"""
        self.log("\n══ إصلاح core.py ══", "bold")
        
        core_code = '''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""النواة الأساسية — النسخة المستقرة"""
import json, os, sys, subprocess, random, string
from pathlib import Path

BASE = Path(__file__).parent.parent
DATA = BASE / "data"

def ensure_dirs():
    for d in [DATA, BASE / "logs", BASE / "assets"]:
        d.mkdir(parents=True, exist_ok=True)

def load(path, default=None):
    try:
        p = Path(path) if Path(path).is_absolute() else DATA / path
        if p.exists():
            with open(p, encoding="utf-8") as f:
                return json.load(f)
    except Exception:
        pass
    return default if default is not None else {}

def save(path, data):
    try:
        p = Path(path) if Path(path).is_absolute() else DATA / path
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return True
    except Exception:
        return False

def get(key, default=""):
    return os.environ.get(key, default)

def reload_env():
    for env_file in ["keys.env", ".env"]:
        if os.path.exists(env_file):
            with open(env_file, encoding="utf-8") as f:
                for line in f:
                    if "=" in line and not line.startswith("#"):
                        k, v = line.strip().split("=", 1)
                        os.environ[k] = v

def site():
    u = get("SITE_URL")
    if u:
        return u.rstrip("/")
    gh = get("GITHUB_USER") or get("GH_USER")
    return f"https://{gh}.github.io" if gh else ""

def genpass(length=16):
    chars = string.ascii_letters + string.digits
    return "".join(random.choice(chars) for _ in range(length))

def clipboard():
    try:
        # Termux
        return subprocess.check_output(["termux-clipboard-get"], text=True).strip()
    except:
        return ""

def clipset(text):
    try:
        subprocess.run(["termux-clipboard-set"], input=text, text=True)
        return True
    except:
        return False

def openurl(url):
    try:
        subprocess.run(["termux-open", url])
        return True
    except:
        print(f"افتح يدوياً: {url}")
        return False

def http(url, timeout=15):
    try:
        import urllib.request
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return {"ok": True, "code": r.getcode()}
    except Exception as e:
        return {"ok": False, "err": str(e)}

ensure_dirs()
reload_env()
'''
        
        core_path = self.base / "tools" / "core.py"
        core_path.write_text(core_code, encoding='utf-8')
        self.log("✓ core.py تم إصلاحه", "success")
        return True
    
    def fix_agent_py(self):
        """إصلاح agent.py"""
        self.log("\n══ إصلاح agent.py ══", "bold")
        
        agent_code = '''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""وكيل التسجيل — النسخة المستقرة"""
import json, os, re, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

NETWORKS = [
    {"id": "adsterra", "name": "Adsterra", "key": "ADSTERRA_ZONE",
     "signup": "https://publishers.adsterra.com/register",
     "hint": "Zone ID (5-8 أرقام)", "pattern": r"\\\\b(\\\\d{5,8})\\\\b"},
    {"id": "exoclick", "name": "ExoClick", "key": "EXOCLICK_ZONE",
     "signup": "https://admin.exoclick.com/signup",
     "hint": "Zone ID", "pattern": r"\\\\b(\\\\d{4,9})\\\\b"},
    {"id": "stripchat", "name": "Stripchat", "key": "STRIPCHAT_REF",
     "signup": "https://affiliates.stripchat.com/",
     "hint": "رابط الإحالة", "pattern": r"(https://[^\\\\s]+stripchat[^\\\\s]+)"},
]

def main():
    print("\\\\n══ وكيل التسجيل — اختر شبكة ══")
    for i, net in enumerate(NETWORKS, 1):
        print(f"{i}. {net['name']}")
    
    try:
        choice = int(input("\\\\nاختر رقم (أو 0 للخروج): "))
        if choice == 0:
            return
        net = NETWORKS[choice - 1]
    except (ValueError, IndexError):
        print("اختيار غير صالح")
        return
    
    print(f"\\\\n📝 {net['name']}")
    print(f"🔗 {net['signup']}")
    print(f"💡 {net['hint']}")
    
    # فتح المتصفح
    core.openurl(net["signup"])
    
    # نسخ البيانات
    profile = core.load("data/profile.json", {})
    data = f"""البريد: {profile.get('email', 'alkazmybwhwr@gmail.com')}
كلمة المرور: {profile.get('password', 'غير محدد')}
"""
    core.clipset(data)
    print("\\\\n📋 البيانات نُسخت للحافظة")
    
    # انتظار المفتاح
    print("\\\\n⏳ بعد إكمال التسجيل، انسخ المفتاح والصقه هنا...")
    input("اضغط Enter للمتابعة...")
    
    # محاولة قراءة المفتاح
    clip = core.clipboard()
    match = re.search(net["pattern"], clip)
    
    if match:
        key = match.group(1)
        print(f"✓ تم العثور على المفتاح: {key}")
        
        # حفظ
        keys = {}
        if os.path.exists("keys.env"):
            with open("keys.env") as f:
                for line in f:
                    if "=" in line:
                        k, v = line.strip().split("=", 1)
                        keys[k] = v
        
        keys[net["key"]] = key
        with open("keys.env", "w") as f:
            for k, v in keys.items():
                f.write(f"{k}={v}\\\\n")
        
        print(f"✓ حُفظ في keys.env")
    else:
        key = input("أدخل المفتاح يدوياً: ").strip()
        if key:
            print(f"✓ حُفظ: {key}")

if __name__ == "__main__":
    main()
'''
        
        agent_path = self.base / "tools" / "agent.py"
        agent_path.write_text(agent_code, encoding='utf-8')
        self.log("✓ agent.py تم إصلاحه", "success")
        return True
    
    def fix_profile(self):
        """إصلاح profile.json"""
        self.log("\n══ إصلاح الهوية ══", "bold")
        
        profile = {
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
            "password": core.genpass(16) if 'core' in sys.modules else "AutoGen123!"
        }
        
        core.save("data/profile.json", profile)
        self.log("✓ الهوية تم إصلاحها", "success")
        return True
    
    def fix_keys_env(self):
        """إعداد keys.env"""
        self.log("\n══ إعداد المفاتيح ══", "bold")
        
        keys_file = self.base / "keys.env"
        if not keys_file.exists():
            keys_content = """# المفاتيح — تم إنشاؤه تلقائياً
MY_EMAIL=alkazmybwhwr@gmail.com
MAIL_USER=alkazmybwhwr@gmail.com
SITE_URL=https://alisalimax3.github.io
GITHUB_USER=alisalimax3
"""
            keys_file.write_text(keys_content, encoding='utf-8')
            self.log("✓ keys.env تم إنشاؤه", "success")
    
    def run_all(self):
        """تشغيل جميع الإصلاحات"""
        print("\033[1;36m")
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║           🔧 CineHub Auto-Fix v3.0                              ║")
        print("║           النظام الشامل للإصلاح التلقائي                      ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print("\033[0m")
        
        # تنفيذ الإصلاحات
        self.fix_playwright()
        self.fix_core_py()
        self.fix_agent_py()
        self.fix_profile()
        self.fix_keys_env()
        
        # اختبار نهائي
        self.log("\n══ الاختبار النهائي ══", "bold")
        
        tests = [
            ("python3 -m py_compile tools/core.py", "core.py"),
            ("python3 -m py_compile tools/agent.py", "agent.py"),
            ("python3 -c 'import json; json.load(open(\"data/profile.json\"))'", "profile.json"),
        ]
        
        all_passed = True
        for cmd, name in tests:
            result = subprocess.run(cmd, shell=True, capture_output=True)
            if result.returncode == 0:
                self.log(f"✓ {name} يعمل", "success")
            else:
                self.log(f"✗ {name} فشل", "error")
                all_passed = False
        
        # الملخص
        self.log("\n══ الملخص ══", "bold")
        if all_passed:
            self.log("✅ جميع الإصلاحات ناجحة!", "success")
            self.log("\nالأوامر المتاحة الآن:", "info")
            self.log("  python3 tools/agent.py  — تشغيل الوكيل", "info")
            self.log("  python3 tools/core.py   — اختبار النواة", "info")
        else:
            self.log("⚠️ بعض الإصلاحات تحتاج مراجعة يدوية", "warning")

if __name__ == "__main__":
    fixer = AutoFix()
    fixer.run_all()
