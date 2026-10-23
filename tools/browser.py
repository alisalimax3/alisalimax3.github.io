#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""متصفح Termux — يستخدم chromium النظام (لا يحتاج playwright install)"""
import os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ARGS = ["--no-sandbox","--disable-dev-shm-usage","--disable-gpu",
        "--disable-blink-features=AutomationControlled","--no-first-run",
        "--disable-features=IsolateOrigins,site-per-process","--mute-audio"]

def find_chromium():
    for n in ("chromium-browser","chromium","chrome","google-chrome","chrome-headless-shell"):
        p = shutil.which(n)
        if p: return p
    return None

def launch(pw, headless=True, slow=0):
    exe = find_chromium()
    kw = dict(headless=headless, args=ARGS)
    if slow: kw["slow_mo"] = slow
    if exe:
        kw["executable_path"] = exe
        core.log(f"المتصفح: {exe}", "info")
    return pw.chromium.launch(**kw)

def context_args():
    return dict(
        user_agent=core.UA,
        viewport={"width":1366,"height":900},
        locale="en-US",
        timezone_id="Africa/Casablanca",
        java_script_enabled=True,
        ignore_https_errors=True,
    )

def new_page(browser, session_file=None):
    if session_file and os.path.exists(session_file):
        ctx = browser.new_context(storage_state=session_file, **context_args())
    else:
        ctx = browser.new_context(**context_args())
    try:
        ctx.add_init_script("Object.defineProperty(navigator,'webdriver',{get:()=>undefined});")
    except Exception: pass
    return ctx, ctx.new_page()

def save_session(ctx, path):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        ctx.storage_state(path=path); return True
    except Exception: return False
