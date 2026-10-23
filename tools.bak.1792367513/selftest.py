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
