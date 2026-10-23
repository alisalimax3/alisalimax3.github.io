#!/bin/bash
# ═════════════════════════════════════════════════════════════════════════════
# AGENT-UNIFIED.sh — النظام الموحد الشامل للوكيل الأوروبي الذكي
# يجمع: أدوات التسجيل + VPN أوروبي + أتمتة كاملة + دعم 15+ شبكة
# الاستخدام: bash AGENT-UNIFIED.sh [install|run|status|vpn|fix]
# ═════════════════════════════════════════════════════════════════════════════

set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || mkdir -p "$HOME/cinehub3099" && cd "$HOME/cinehub3099"
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data assets .github/workflows

# الألوان
G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; B='\033[1;34m'; D='\033[2m'; N='\033[0m'
ok() { printf '%s✓%s %s\n' "$G" "$N" "$*"; }
bad() { printf '%s✗%s %s\n' "$R" "$N" "$*"; }
wrn() { printf '%s!%s %s\n' "$Y" "$N" "$*"; }
hd() { printf '\n%s══ %s ══%s\n' "$C" "$*" "$N"; }
info() { printf '%sℹ%s %s\n' "$B" "$N" "$*"; }

MY_EMAIL="alkazmybwhwr@gmail.com"
EU_COUNTRY="NL"  # Netherlands - أعلى أرباح
EU_CITY="Amsterdam"
EU_TIMEZONE="Europe/Amsterdam"

# ═════════════════════════════════════════════════════════════════════════════
# القسم 1: إنشاء الأدوات الأساسية (core.py)
# ═════════════════════════════════════════════════════════════════════════════
create_core() {
cat > tools/core.py << 'CORE_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""نواة النظام الموحد — إدارة البيانات والبيئة والاتصالات"""
import json, os, re, sys, time, random, subprocess, platform
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).parent.parent
DATA = BASE / "data"
LOGS = BASE / "logs"

def ensure_dirs():
    for d in [DATA, LOGS, BASE / "assets", BASE / ".tmp"]:
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
    except Exception as e:
        print(f"! خطأ في تحميل {path}: {e}")
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
    except Exception as e:
        print(f"! خطأ في حفظ {path}: {e}")
        return False

def get(key, default=""):
    """قراءة متغير بيئة"""
    return os.environ.get(key, default)

def reload_env():
    """إعادة تحميل ملف البيئة"""
    env_file = BASE / "keys.env"
    if env_file.exists():
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
    gh = get("GITHUB_USER")
    if gh:
        return f"https://{gh}.github.io"
    return ""

def clipboard():
    """قراءة الحافظة"""
    try:
        if platform.system() == "Darwin":
            return subprocess.check_output(["pbpaste"], text=True).strip()
        elif platform.system() == "Linux":
            return subprocess.check_output(["xclip", "-selection", "clipboard", "-o"], text=True).strip()
        elif platform.system() == "Windows":
            return subprocess.check_output(["powershell", "-command", "Get-Clipboard"], text=True).strip()
    except:
        pass
    return ""

def clipset(text):
    """كتابة في الحافظة"""
    try:
        if platform.system() == "Darwin":
            subprocess.run(["pbcopy"], input=text, text=True)
        elif platform.system() == "Linux":
            subprocess.run(["xclip", "-selection", "clipboard"], input=text, text=True)
        elif platform.system() == "Windows":
            subprocess.run(["powershell", "-command", f"Set-Clipboard -Value '{text}'"])
        return True
    except:
        return False

def openurl(url):
    """فتح رابط في المتصفح"""
    try:
        if platform.system() == "Darwin":
            subprocess.run(["open", url])
        elif platform.system() == "Linux":
            subprocess.run(["xdg-open", url])
        elif platform.system() == "Windows":
            subprocess.run(["start", url], shell=True)
        return True
    except Exception as e:
        print(f"! فشل فتح الرابط: {e}")
        return False

def http(url, timeout=15, headers=None):
    """طلب HTTP بسيط"""
    try:
        import urllib.request
        req = urllib.request.Request(url, headers=headers or {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return {"ok": True, "code": r.getcode(), "url": r.geturl()}
    except Exception as e:
        return {"ok": False, "err": str(e)}

def body(url, timeout=15, limit=50000, headers=None):
    """جلب محتوى الصفحة"""
    try:
        import urllib.request
        req = urllib.request.Request(url, headers=headers or {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read()[:limit].decode("utf-8", "replace")
    except:
        return ""

def genpass(length=16):
    """توليد كلمة مرور عشوائية"""
    chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(random.choice(chars) for _ in range(length))

def timestamp():
    """الوقت الحالي بتنسيق ISO"""
    return datetime.now().isoformat()

ensure_dirs()
reload_env()
CORE_EOF
chmod +x tools/core.py
python3 -m py_compile tools/core.py && ok "core.py" || bad "core.py"
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 2: ملف الهوية الأوروبية (profile.py)
# ═════════════════════════════════════════════════════════════════════════════
create_profile() {
cat > tools/profile.py << 'PROFILE_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""إدارة الهوية الأوروبية للحصول على أعلى الأرباح"""
import os, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

# إعدادات أوروبية لأعلى الأرباح
EU_CONFIG = {
    "country": "NL",           # هولندا - أعلى RPM
    "country_name": "Netherlands",
    "city": "Amsterdam",
    "zip": "1012 AB",
    "phone_prefix": "+31",
    "timezone": "Europe/Amsterdam",
    "locale": "en-GB",
    "currency": "EUR"
}

US_CONFIG = {
    "country": "US",
    "country_name": "United States",
    "city": "New York",
    "zip": "10001",
    "phone_prefix": "+1",
    "timezone": "America/New_York",
    "locale": "en-US",
    "currency": "USD"
}

def load(eu_mode=True):
    """تحميل الهوية"""
    p = "data/profile.json"
    d = core.load(p, {})
    
    # البيانات الأساسية
    base = {
        "first": "Ali",
        "last": "Salim",
        "username": "alisalimax3",
        "email": os.environ.get("MY_EMAIL", "alkazmybwhwr@gmail.com"),
        "site": core.site() or "https://alisalimax3.github.io",
        "password": d.get("password") or core.genpass(16),
        "note": "European profile for maximum revenue"
    }
    
    # اختيار التكوين
    config = EU_CONFIG if eu_mode else US_CONFIG
    
    # دمج البيانات
    result = {**base, **config}
    result["phone"] = f"{config['phone_prefix']}{random.randint(100000000, 999999999)}"
    result["address"] = f"Street {random.randint(1, 200)}, {config['city']}"
    
    # حفظ إذا كان جديداً
    if not d:
        core.save(p, result)
    
    return result

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--us", action="store_true", help="Use US profile instead of EU")
    args = parser.parse_args()
    
    p = load(eu_mode=not args.us)
    for k, v in sorted(p.items()):
        print(f"  {k:15} {v}")

if __name__ == "__main__":
    main()
PROFILE_EOF
chmod +x tools/profile.py
python3 -m py_compile tools/profile.py && ok "profile.py" || bad "profile.py"
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 3: الوكيل الذكي المتقدم (smart_agent.py)
# ═════════════════════════════════════════════════════════════════════════════
create_smart_agent() {
cat > tools/smart_agent.py << 'AGENT_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
الوكيل الذكي الأوروبي — أتمتة كاملة مع التوقف عند CAPTCHA فقط
يدعم: Adsterra, ExoClick, PropellerAds, AdMaven, JuicyAds, PopAds, PopCash,
       A-ADS, Stripchat, CrakRevenue, Chaturbate, LiveJasmin, BongaCams
"""
import asyncio
import json
import os
import random
import re
import sys
import time
import traceback
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
import profile

MY_EMAIL = os.environ.get("MY_EMAIL", "alkazmybwhwr@gmail.com")

# قائمة الشبكات المدعومة
NETWORKS = [
    # الإعلانات العامة
    {"id": "adsterra", "name": "Adsterra", "key": "ADSTERRA_ZONE", 
     "signup": "https://publishers.adsterra.com/register",
     "dash": "https://publishers.adsterra.com/websites",
     "fields": ["email", "password", "first_name", "last_name", "country"],
     "selectors": {
         "email": 'input[name="email"]',
         "password": 'input[name="password"]',
         "confirm": 'input[name="confirm_password"]',
         "first": 'input[name="first_name"]',
         "last": 'input[name="last_name"]',
         "country": 'select[name="country"]',
         "terms": 'input[name="terms"]',
         "submit": 'button[type="submit"]'
     },
     "captcha_selectors": ['iframe[src*="recaptcha"]', '.g-recaptcha', '.h-captcha'],
     "success_url": "dashboard",
     "extract": {"zone": r'(\d{6,8})'}},
    
    {"id": "exoclick", "name": "ExoClick", "key": "EXOCLICK_ZONE",
     "signup": "https://admin.exoclick.com/signup",
     "fields": ["email", "username", "password"],
     "selectors": {
         "email": 'input[name="email"]',
         "username": 'input[name="username"]',
         "password": 'input[name="password"]',
         "type_publisher": 'input[value="publisher"]',
         "submit": 'button[type="submit"]'
     },
     "captcha_selectors": ['iframe[src*="recaptcha"]'],
     "success_url": "dashboard"},
    
    {"id": "propellerads", "name": "PropellerAds", "key": "PROPELLER_ZONE",
     "signup": "https://publishers.propellerads.com/#/auth/signUp",
     "fields": ["email", "password"],
     "selectors": {
         "email": 'input[name="email"]',
         "password": 'input[name="password"]',
         "submit": 'button[type="submit"]'
     },
     "captcha_selectors": ['.g-recaptcha', '[class*="captcha"]']},
    
    {"id": "admaven", "name": "AdMaven", "key": "ADMAVEN_ZONE",
     "signup": "https://admaven.com/signup/",
     "fields": ["email", "password"],
     "selectors": {
         "email": 'input[type="email"]',
         "password": 'input[type="password"]',
         "submit": 'button[type="submit"]'
     }},
    
    {"id": "aads", "name": "A-ADS", "key": "AADS_UNIT",
     "signup": "https://a-ads.com/ad-units/new/",
     "manual": True,  # يتطلب تسجيلاً يدوياً
     "extract": {"unit": r'data-aa="(\d+)"'}},
    
    # شبكات البالغين (18+)
    {"id": "stripchat", "name": "Stripchat", "key": "STRIPCHAT_REF",
     "signup": "https://affiliates.stripchat.com/",
     "adult": True,
     "fields": ["email", "password"],
     "selectors": {
         "email": 'input[name="email"]',
         "password": 'input[name="password"]',
         "submit": 'button[type="submit"]'
     },
     "extract": {"ref": r'(https://[^"\s]+stripchat\.com/[^"\s]+)'}},
    
    {"id": "crakrevenue", "name": "CrakRevenue", "key": "CRAKREVENUE_REF",
     "signup": "https://www.crakrevenue.com/signup",
     "adult": True,
     "fields": ["email", "username", "password"],
     "selectors": {
         "email": 'input[name="email"]',
         "username": 'input[name="username"]',
         "password": 'input[name="password"]',
         "submit": 'button[type="submit"]'
     }},
    
    {"id": "chaturbate", "name": "Chaturbate", "key": "CHATURBATE_REF",
     "signup": "https://chaturbate.com/affiliates/",
     "adult": True,
     "manual": True},
    
    {"id": "livejasmin", "name": "LiveJasmin", "key": "LIVEJASMIN_REF",
     "signup": "https://www.livejasmin.com/en/affiliates",
     "adult": True,
     "fields": ["email", "password"]},
    
    {"id": "bongacams", "name": "BongaCams", "key": "BONGACAMS_REF",
     "signup": "https://bongacash.com/en/auth/registration",
     "adult": True,
     "fields": ["email", "username", "password"]},
    
    # البوب أندر
    {"id": "popads", "name": "PopAds", "key": "POPADS_SITE",
     "signup": "https://www.popads.net/",
     "fields": ["email", "password"]},
    
    {"id": "popcash", "name": "PopCash", "key": "POPCASH_SITE",
     "signup": "https://popcash.net/register",
     "fields": ["email", "password"]},
    
    {"id": "juicyads", "name": "JuicyAds", "key": "JUICYADS_ZONE",
     "signup": "https://www.juicyads.com/signup",
     "adult": True,
     "fields": ["email", "username", "password"]},
]

class EuropeanSmartAgent:
    def __init__(self):
        self.profile = profile.load()
        self.state = core.load("data/agent_state.json", {
            "completed": {}, "pending": {}, "failed": {}, "cookies": {}
        })
        self.browser = None
        self.context = None
        self.page = None
        
    async def init_browser(self, headless=False):
        """تهيئة المتصفح بالإعدادات الأوروبية"""
        try:
            from playwright.async_api import async_playwright
            
            self.playwright = await async_playwright().start()
            
            # إعدادات متقدمة لتجنب الكشف
            args = [
                '--disable-blink-features=AutomationControlled',
                '--disable-web-security',
                '--disable-features=IsolateOrigins,site-per-process',
                '--disable-dev-shm-usage',
                '--no-sandbox',
                f'--timezone={self.profile["timezone"]}',
            ]
            
            # بروكسي أوروبي
            proxy = None
            if os.path.exists("/tmp/eu_proxy"):
                with open("/tmp/eu_proxy") as f:
                    proxy_url = f.read().strip()
                    if proxy_url:
                        proxy = {"server": proxy_url}
                        print(f"✓ استخدام بروكسي: {proxy_url}")
            
            self.browser = await self.playwright.chromium.launch(
                headless=headless,
                args=args,
                proxy=proxy
            )
            
            # سياق أوروبي
            self.context = await self.browser.new_context(
                viewport={"width": 1920, "height": 1080},
                locale=self.profile["locale"],
                timezone_id=self.profile["timezone"],
                geolocation={"latitude": 52.3676, "longitude": 4.9041, "accuracy": 100},
                permissions=["geolocation"],
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                color_scheme="light"
            )
            
            # إخفاء أتمتة المتصفح
            await self.context.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                Object.defineProperty(navigator, 'plugins', {get: () => [1,2,3,4,5]});
                window.chrome = {runtime: {}};
            """)
            
            # استعادة الكوكيز
            if self.state.get("cookies"):
                await self.context.add_cookies(self.state["cookies"])
            
            self.page = await self.context.new_page()
            print(f"✓ المتصفح جاهز ({self.profile['country_name']})")
            return True
            
        except ImportError:
            print("! تثبيت Playwright: pip install playwright && playwright install chromium")
            return False
        except Exception as e:
            print(f"! خطأ: {e}")
            return False
    
    async def check_captcha(self, timeout=5):
        """التحقق من وجود CAPTCHA"""
        captcha_selectors = [
            'iframe[src*="recaptcha"]',
            'iframe[src*="captcha"]',
            '.g-recaptcha',
            '#captcha',
            '[class*="captcha"]',
            '[class*="recaptcha"]',
            '.h-captcha',
            'iframe[title*="challenge"]',
            'div[style*="challenge"]'
        ]
        
        for selector in captcha_selectors:
            try:
                element = await self.page.query_selector(selector)
                if element:
                    return True
            except:
                pass
        
        return False
    
    async def wait_for_captcha_solve(self, max_wait=300):
        """الانتظار حتى حل المستخدم لـ CAPTCHA"""
        print("\n" + "⚠️"*30)
        print("🛑 تم اكتشاف صفحة 'أنا لست روبوت'!")
        print("👆 اضغط على الزر في المتصفح...")
        print("⏳ سأنتظر حتى تنتهي (5 دقائق كحد أقصى)")
        print("⚠️"*30 + "\n")
        
        # تنبيه صوتي
        try:
            import os
            os.system('echo -e "\a" 2>/dev/null || true')
        except:
            pass
        
        # إبراز النافذة
        try:
            await self.page.bring_to_front()
        except:
            pass
        
        # الانتظار
        start = time.time()
        while time.time() - start < max_wait:
            await asyncio.sleep(2)
            
            # التحقق من اختفاء CAPTCHA
            if not await self.check_captcha(timeout=1):
                print("✓ تم حل CAPTCHA - استئناف العمل...")
                await asyncio.sleep(2)
                return True
            
            # التحقق من النجاح رغم CAPTCHA
            if await self._check_success():
                return True
        
        print("! انتهى الوقت - CAPTCHA لم تحل")
        return False
    
    async def _check_success(self):
        """التحقق من نجاح التسجيل"""
        indicators = ["dashboard", "welcome", "success", "verify", "confirmation", "account"]
        url = (await self.page.url()).lower()
        title = (await self.page.title()).lower()
        
        for ind in indicators:
            if ind in url or ind in title:
                return True
        return False
    
    async def _fill_field(self, selector, value, human_like=True):
        """ملء حقل مع محاكاة بشرية"""
        try:
            await self.page.wait_for_selector(selector, timeout=10000)
            
            if human_like:
                await asyncio.sleep(random.uniform(0.5, 2))
            
            await self.page.fill(selector, value)
            
            if human_like:
                await asyncio.sleep(random.uniform(0.3, 1))
            
            return True
        except Exception as e:
            print(f"! تعذر ملء الحقل {selector}: {e}")
            return False
    
    async def register_network(self, net):
        """التسجيل في شبكة معينة"""
        print(f"\n{'='*60}")
        print(f"🚀 {net['name']} ({net.get('country', 'Global')})")
        print(f"📧 {MY_EMAIL}")
        
        if self.state["completed"].get(net["id"]):
            print(f"✓ مسجل مسبقاً - تخطي")
            return True
        
        if net.get("manual"):
            print(f"⏭️ يتطلب تسجيلاً يدوياً - تخطى للوضع التلقائي")
            return False
        
        try:
            # فتح الصفحة
            await self.page.goto(net["signup"], wait_until="networkidle", timeout=60000)
            await asyncio.sleep(3)
            
            # ملء الحقول
            selectors = net.get("selectors", {})
            fields = net.get("fields", [])
            
            if "email" in fields:
                await self._fill_field(selectors.get("email"), self.profile["email"])
            
            if "password" in fields:
                await self._fill_field(selectors.get("password"), self.profile["password"])
                if "confirm" in selectors:
                    await self._fill_field(selectors["confirm"], self.profile["password"])
            
            if "first_name" in fields or "first" in fields:
                await self._fill_field(selectors.get("first", selectors.get("first_name")), 
                                      self.profile["first"])
            
            if "last_name" in fields or "last" in fields:
                await self._fill_field(selectors.get("last", selectors.get("last_name")), 
                                      self.profile["last"])
            
            if "username" in fields:
                uname = f"{self.profile['first'].lower()}{random.randint(10,99)}"
                await self._fill_field(selectors.get("username"), uname)
            
            if "country" in fields:
                try:
                    await self.page.select_option(selectors["country"], 
                                                 value=self.profile["country"])
                except:
                    pass
            
            # الموافقة على الشروط
            if "terms" in selectors:
                try:
                    await self.page.check(selectors["terms"])
                except:
                    pass
            
            print("✓ تم ملء جميع البيانات")
            
            # الضغط على Submit
            if "submit" in selectors:
                await self.page.click(selectors["submit"])
            
            await asyncio.sleep(3)
            
            # التحقق من CAPTCHA
            if await self.check_captcha():
                if not await self.wait_for_captcha_solve():
                    return False
            
            # انتظار النتيجة
            await asyncio.sleep(5)
            
            if await self._check_success():
                print(f"✅ نجح التسجيل في {net['name']}!")
                
                # استخراج المفاتيح
                await self._extract_keys(net)
                
                # حفظ الحالة
                self.state["completed"][net["id"]] = {
                    "date": datetime.now().isoformat(),
                    "email": MY_EMAIL
                }
                core.save("data/agent_state.json", self.state)
                
                return True
            
            return False
            
        except Exception as e:
            print(f"❌ خطأ: {e}")
            traceback.print_exc()
            return False
    
    async def _extract_keys(self, net):
        """استخراج المفاتيح من لوحة التحكم"""
        try:
            if "dash" in net:
                await self.page.goto(net["dash"], timeout=30000)
                await asyncio.sleep(5)
                
                content = await self.page.content()
                
                extract = net.get("extract", {})
                for key_type, pattern in extract.items():
                    matches = re.findall(pattern, content)
                    if matches:
                        value = matches[0]
                        env_key = net["key"]
                        print(f"🎯 {key_type}: {value}")
                        
                        # حفظ في keys.env
                        self._save_env_key(env_key, value)
                        
                        # حفظ في الحالة
                        self.state["completed"][net["id"]][key_type] = value
                        
        except Exception as e:
            print(f"! فشل استخراج المفاتيح: {e}")
    
    def _save_env_key(self, key, value):
        """حفظ مفتاح في ملف البيئة"""
        env_file = "keys.env"
        lines = []
        
        if os.path.exists(env_file):
            with open(env_file, encoding="utf-8") as f:
                lines = f.readlines()
        
        # تحديث أو إضافة
        updated = False
        for i, line in enumerate(lines):
            if line.strip().startswith(f"{key}="):
                lines[i] = f"{key}={value}\n"
                updated = True
                break
        
        if not updated:
            lines.append(f"{key}={value}\n")
        
        with open(env_file, "w", encoding="utf-8") as f:
            f.writelines(lines)
        
        os.environ[key] = value
        print(f"💾 حُفظ: {key}={value[:20]}...")
    
    async def verify_email_auto(self):
        """التحقق التلقائي من البريد"""
        print("\n📧 التحقق من البريد...")
        
        try:
            import imaplib
            import email
            
            # Gmail
            mail = imaplib.IMAP4_SSL("imap.gmail.com")
            app_pass = os.environ.get("GMAIL_APP_PASSWORD")
            
            if not app_pass:
                print("⚠️ GMAIL_APP_PASSWORD غير محدد")
                return False
            
            mail.login(MY_EMAIL, app_pass)
            mail.select("inbox")
            
            # البحث عن رسائل جديدة
            _, messages = mail.search(None, '(UNSEEN)')
            
            found = False
            for msg_id in messages[0].split()[-10:]:
                _, msg_data = mail.fetch(msg_id, "(RFC822)")
                email_body = msg_data[0][1]
                email_msg = email.message_from_bytes(email_body)
                
                # استخراج المحتوى
                body = ""
                if email_msg.is_multipart():
                    for part in email_msg.walk():
                        if part.get_content_type() in ["text/html", "text/plain"]:
                            try:
                                body += part.get_payload(decode=True).decode("utf-8", "replace")
                            except:
                                pass
                else:
                    body = email_msg.get_payload(decode=True).decode("utf-8", "replace")
                
                # البحث عن روابط التفعيل
                links = re.findall(r'https?://[^\s<>"\']{20,}(?:confirm|verify|activate|token)[^\s<>"\']*', 
                                  body, re.I)
                
                for link in links:
                    print(f"🔗 رابط تفعيل: {link[:60]}...")
                    await self.page.goto(link, timeout=30000)
                    await asyncio.sleep(5)
                    found = True
            
            mail.close()
            mail.logout()
            return found
            
        except Exception as e:
            print(f"! خطأ: {e}")
            return False
    
    async def run(self, only=None, skip_adult=False):
        """تشغيل الوكيل"""
        print("""
╔══════════════════════════════════════════════════════════════════╗
║     🇪🇺 الوكيل الأوروبي الموحد — European Unified Agent         ║
║     أتمتة كاملة مع التوقف عند CAPTCHA فقط                      ║
╚══════════════════════════════════════════════════════════════════╝
        """)
        
        if not await self.init_browser(headless=False):
            return False
        
        # تصفية الشبكات
        networks = [n for n in NETWORKS if not only or n["id"] == only]
        if skip_adult:
            networks = [n for n in networks if not n.get("adult")]
        
        for net in networks:
            success = await self.register_network(net)
            
            if success:
                await self.verify_email_auto()
            
            # تأخير عشوائي
            delay = random.uniform(10, 30)
            print(f"⏳ انتظار {delay:.0f} ثانية...")
            await asyncio.sleep(delay)
        
        # حفظ الكوكيز
        if self.context:
            cookies = await self.context.cookies()
            self.state["cookies"] = cookies
            core.save("data/agent_state.json", self.state)
        
        # إغلاق
        if self.browser:
            await self.browser.close()
        if hasattr(self, 'playwright'):
            await self.playwright.stop()
        
        # الملخص
        print("\n" + "="*60)
        print("📊 ملخص التسجيل:")
        print(f"✅ منجز: {len(self.state['completed'])}")
        print(f"⏳ معلق: {len(self.state['pending'])}")
        print(f"❌ فاشل: {len(self.state['failed'])}")
        for nid, info in self.state["completed"].items():
            print(f"   ✓ {nid}: {info.get('date', '')[:10]}")

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", help="تسجيل شبكة محددة فقط")
    parser.add_argument("--skip-adult", action="store_true", help="تخطي شبكات 18+")
    parser.add_argument("--status", action="store_true", help="عرض الحالة فقط")
    args = parser.parse_args()
    
    if args.status:
        state = core.load("data/agent_state.json", {})
        print("📊 حالة التسجيلات:")
        for nid, info in state.get("completed", {}).items():
            print(f"  ✅ {nid}: {info.get('date', '')[:10]}")
        return
    
    agent = EuropeanSmartAgent()
    asyncio.run(agent.run(only=args.only, skip_adult=args.skip_adult))

if __name__ == "__main__":
    main()
AGENT_EOF
chmod +x tools/smart_agent.py
python3 -m py_compile tools/smart_agent.py && ok "smart_agent.py" || bad "smart_agent.py"
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 4: إعداد VPN أوروبي تلقائي
# ═════════════════════════════════════════════════════════════════════════════
setup_vpn() {
    hd "إعداد VPN أوروبي"
    
    # التحقق من NordVPN
    if command -v nordvpn &> /dev/null; then
        info "NordVPN موجود - الاتصال بخادم هولندي..."
        nordvpn connect Netherlands || nordvpn connect "Netherlands - Amsterdam"
        sleep 3
        
    # التحقق من ExpressVPN
    elif command -v expressvpn &> /dev/null; then
        info "ExpressVPN موجود..."
        expressvpn connect "Netherlands - Amsterdam" || expressvpn connect "Netherlands"
        
    # التحقق من Tor
    elif pgrep -x "tor" > /dev/null || command -v tor &> /dev/null; then
        info "Tor موجود..."
        if ! pgrep -x "tor" > /dev/null; then
            tor &
            sleep 5
        fi
        echo "socks5://127.0.0.1:9050" > /tmp/eu_proxy
        ok "Tor جاهز على المنفذ 9050"
        
    # Termux / Android
    elif [ -d "/data/data/com.termux" ]; then
        wrn "Termux محتاج لـ Tor: pkg install tor"
        wrn "ثم شغل: tor &"
        
    else:
        wrn "لا يوجد VPN - سيتم استخدام الاتصال المباشر"
        wrn "للحصول على أرباح أعلى، ثبت NordVPN أو ExpressVPN"
    fi
    
    # التحقق من IP
    info "التحقق من الموقع الجغرافي..."
    IP_INFO=$(curl -s https://ipinfo.io/json 2>/dev/null || echo "{}")
    COUNTRY=$(echo "$IP_INFO" | grep -o '"country": "[^"]*' | cut -d'"' -f4 || echo "Unknown")
    CITY=$(echo "$IP_INFO" | grep -o '"city": "[^"]*' | cut -d'"' -f4 || echo "Unknown")
    IP=$(echo "$IP_INFO" | grep -o '"ip": "[^"]*' | cut -d'"' -f4 || echo "Unknown")
    
    echo "  IP: $IP"
    echo "  الموقع: $CITY, $COUNTRY"
    
    if [ "$COUNTRY" = "NL" ] || [ "$COUNTRY" = "DE" ] || [ "$COUNTRY" = "GB" ]; then
        ok "✅ أنت في أوروبا - الأرباح مضمونة!"
    else
        wrn "أنت لست في أوروبا - الأرباح قد تكون أقل"
    fi
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 5: إعداد Gmail
# ═════════════════════════════════════════════════════════════════════════════
setup_gmail() {
    hd "إعداد Gmail"
    
    if [ -z "${GMAIL_APP_PASSWORD:-}" ]; then
        echo ""
        echo "⚠️  مطلوب App Password من Google:"
        echo "1. اذهب إلى: https://myaccount.google.com/apppasswords"
        echo "2. سجل الدخول بحسابك: $MY_EMAIL"
        echo "3. أنشئ App Password جديد (اختر 'Mail')"
        echo ""
        read -sp "أدخل App Password: " app_pass
        echo ""
        export GMAIL_APP_PASSWORD="$app_pass"
    fi
    
    # حفظ في البيئة
    echo "MY_EMAIL=$MY_EMAIL" > keys.env
    echo "GMAIL_APP_PASSWORD=$GMAIL_APP_PASSWORD" >> keys.env
    echo "MAIL_USER=$MY_EMAIL" >> keys.env
    echo "MAIL_APP_PASS=$GMAIL_APP_PASSWORD" >> keys.env
    
    ok "Gmail مهيأ: $MY_EMAIL"
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 6: تثبيت المتطلبات
# ═════════════════════════════════════════════════════════════════════════════
install_requirements() {
    hd "تثبيت المتطلبات"
    
    # Python packages
    pip3 install --user playwright requests beautifulsoup4 2>/dev/null || pip install playwright requests beautifulsoup4
    
    # Playwright browsers
    python3 -m playwright install chromium 2>/dev/null || playwright install chromium
    
    ok "المتطلبات مثبتة"
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 7: تشغيل الوكيل
# ═════════════════════════════════════════════════════════════════════════════
run_agent() {
    hd "تشغيل الوكيل الأوروبي الذكي"
    
    # تصدير المتغيرات
    export MY_EMAIL="$MY_EMAIL"
    [ -f keys.env ] && source keys.env
    
    # تشغيل
    python3 tools/smart_agent.py "$@"
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم 8: الوضع التلقائي الكامل (Auto-Pilot)
# ═════════════════════════════════════════════════════════════════════════════
auto_pilot() {
    hd "الوضع التلقائي الكامل"
    
    echo "🚀 سأقوم بـ:"
    echo "   1. إعداد VPN أوروبي"
    echo "   2. التسجيل في جميع الشبكات"
    echo "   3. التوقف عند CAPTCHA فقط"
    echo "   4. التحقق من البريد تلقائياً"
    echo ""
    read -p "اضغط Enter للبدء أو Ctrl+C للإلغاء..."
    
    setup_vpn
    setup_gmail
    run_agent
}

# ═════════════════════════════════════════════════════════════════════════════
# القسم الرئيسي
# ═════════════════════════════════════════════════════════════════════════════
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           🚀 AGENT-UNIFIED — النظام الموحد الشامل              ║"
    echo "║      أتمتة كاملة للتسجيل في 15+ شبكة إعلانات أوروبية          ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    CMD="${1:-help}"
    
    case "$CMD" in
        "install"|"setup")
            create_core
            create_profile
            create_smart_agent
            install_requirements
            setup_gmail
            ok "اكتمل التثبيت!"
            ;;
        "vpn"|"connect")
            setup_vpn
            ;;
        "run"|"start")
            run_agent "${@:2}"
            ;;
        "auto"|"pilot")
            auto_pilot
            ;;
        "status")
            python3 -c "
import sys; sys.path.insert(0, 'tools')
import core
state = core.load('data/agent_state.json', {})
print('📊 حالة التسجيلات:')
for nid, info in state.get('completed', {}).items():
    print(f'  ✅ {nid}: {info.get(\"date\", \"\")[:10]}')
print(f'\\nالمجموع: {len(state.get(\"completed\", {}))} منجز')
"
            ;;
        "fix"|"repair")
            create_core
            create_profile
            create_smart_agent
            ok "تم إصلاح الأدوات"
            ;;
        "help"|"-h"|"--help"|*)
            echo "الاستخدام: bash AGENT-UNIFIED.sh [الأمر]"
            echo ""
            echo "الأوامر:"
            echo "  install     تثبيت النظام كاملاً (مرة واحدة)"
            echo "  run         تشغيل الوكيل"
            echo "  auto        الوضع التلقائي الكامل (VPN + تسجيل)"
            echo "  vpn         إعداد VPN فقط"
            echo "  status      عرض حالة التسجيلات"
            echo "  fix         إصلاح الأدوات"
            echo ""
            echo "أمثلة:"
            echo "  bash AGENT-UNIFIED.sh install"
            echo "  bash AGENT-UNIFIED.sh auto"
            echo "  bash AGENT-UNIFIED.sh run --only adsterra"
            echo "  bash AGENT-UNIFIED.sh run --skip-adult"
            ;;
    esac
    
    echo ""
}

# التشغيل
main "$@"
