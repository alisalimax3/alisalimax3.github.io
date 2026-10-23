#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core
def git(*a, timeout=90):
    try:
        r = subprocess.run(["git"]+list(a), cwd=str(core.BASE), capture_output=True, text=True, timeout=timeout)
        return r.returncode, ((r.stdout or "")+(r.stderr or "")).strip()
    except Exception as e: return 1, str(e)
def remote():
    rc,out = git("remote","get-url","origin"); return out if rc==0 else ""
def ensure():
    if not (core.BASE/".git").exists():
        git("init","-q"); git("config","user.email", core.env("MAIL_USER") or "a@local")
        git("config","user.name", core.env("GITHUB_USER") or "agent"); git("add","-A"); git("commit","-q","-m","init")
    if not remote() and core.env("REPO_URL"): git("remote","add","origin", core.env("REPO_URL"))
def push(msg=None):
    ensure()
    git("add","-A")
    git("commit","-q","-m", msg or ("sync "+time.strftime("%Y-%m-%d %H:%M")))
    if not remote(): return True, "محفوظ محلياً (اضبط REPO_URL للدفع)"
    git("pull","--rebase","--autostash","origin","HEAD")
    rc, out = git("push","origin","HEAD")
    if rc == 0: return True, "دُفع للمستودع"
    rc2, out2 = git("push","--force-with-lease","origin","HEAD")
    if rc2 == 0: return True, "دُفع (force-with-lease)"
    return False, "فشل الدفع: " + (out2 or out).splitlines()[-1][:110]

def pull():
    if not remote(): return False,"لا remote"
    rc,out = git("pull","--rebase","--autostash","origin","HEAD")
    return rc==0, (out.splitlines()[-1][:110] if out else "")
def sync():
    pull(); core.load_env(); return True
