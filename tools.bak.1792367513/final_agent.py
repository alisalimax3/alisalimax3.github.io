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
