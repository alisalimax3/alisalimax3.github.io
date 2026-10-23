#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
تسجيل حقيقي في شبكات الإعلانات
هذا يفتح المتصفح ويملأ البيانات - أنت تضغط CAPTCHA فقط
"""
import json, os, sys, time, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

NETWORKS = [
    {
        "name": "Adsterra",
        "signup_url": "https://publishers.adsterra.com/register",
        "fields": {
            "email": "alkazmybwhwr@gmail.com",
            "password": core.genpass(),
            "first_name": "Ali",
            "last_name": "Salim",
            "country": "MA"
        },
        "requirements": ["website", "email_confirmation"],
        "expected_approval": "24-48 hours",
        "revenue_model": "CPM/CPC/CPA"
    },
    {
        "name": "ExoClick",
        "signup_url": "https://admin.exoclick.com/signup",
        "fields": {
            "email": "alkazmybwhwr@gmail.com",
            "username": "alisalimax3",
            "password": core.genpass()
        },
        "requirements": ["website", "id_verification"],
        "expected_approval": "1-3 days",
        "revenue_model": "CPM/CPC"
    },
    {
        "name": "CrakRevenue",
        "signup_url": "https://www.crakrevenue.com/signup",
        "fields": {
            "email": "alkazmybwhwr@gmail.com",
            "username": "alisalimax3",
            "password": core.genpass()
        },
        "requirements": ["experience", "traffic_source"],
        "expected_approval": "3-7 days",
        "revenue_model": "CPA/RevShare"
    }
]

def register_network(network):
    """فتح صفحة التسجيل في المتصفح"""
    print(f"\n{'='*60}")
    print(f"📝 Registering: {network['name']}")
    print(f"URL: {network['signup_url']}")
    print(f"Expected approval: {network['expected_approval']}")
    print(f"Revenue model: {network['revenue_model']}")
    print(f"\nFields to fill:")
    for field, value in network['fields'].items():
        masked = value[:3] + '*' * (len(value) - 6) + value[-3:] if len(value) > 6 else value
        print(f"  {field}: {masked}")
    
    # فتح في المتصفح
    print(f"\n⏳ Opening browser...")
    core.openurl(network['signup_url'])
    
    # نسخ البيانات للحافظة للصق سريع
    credentials = json.dumps(network['fields'], indent=2)
    core.clipset(credentials)
    
    print("✓ Credentials copied to clipboard")
    print("⚠️  Complete the CAPTCHA and submit manually")
    
    input("\nPress Enter when registration is complete...")
    
    # حفظ الحالة
    status = {
        "network": network['name'],
        "registered_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "status": "pending_approval",
        "expected_approval": network['expected_approval']
    }
    
    registrations = core.load("data/registrations.json", [])
    registrations.append(status)
    core.save("data/registrations.json", registrations)
    
    print(f"✓ {network['name']} registration saved")

def main():
    print("""
╔══════════════════════════════════════════════════════════════════╗
║     REALISTIC REGISTRATION SYSTEM                                ║
║     No magic - just automation of the boring parts               ║
╚══════════════════════════════════════════════════════════════════╝
""")
    
    print("This will open browser windows for each network.")
    print("You only need to:")
    print("  1. Complete CAPTCHA")
    print("  2. Submit the form")
    print("  3. Confirm email")
    print("\nRealistic timeline:")
    print("  - Adsterra: 24-48h approval")
    print("  - ExoClick: 1-3 days + ID verification")
    print("  - CrakRevenue: 3-7 days (adult network)")
    
    for network in NETWORKS:
        register_network(network)
        time.sleep(2)  # تأخير بين الشبكات
    
    print(f"\n{'='*60}")
    print("✓ All registrations submitted")
    print("📧 Check your email for confirmation links")
    print("⏳ Wait for approvals (check status with: python3 tools/auto_register.py status)")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "status":
        regs = core.load("data/registrations.json", [])
        print("Registration Status:")
        for r in regs:
            print(f"  {r['network']}: {r['status']} (since {r['registered_at']})")
    else:
        main()
