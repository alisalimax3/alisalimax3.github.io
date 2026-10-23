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
