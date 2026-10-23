#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ربط حساب GitHub: مستودع + دفع + تفعيل المحرّك"""
import json, os, subprocess, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, ghauth, repo

def api(path, method="GET", data=None, token=""):
    req = urllib.request.Request("https://api.github.com"+path, method=method,
        data=json.dumps(data).encode() if data is not None else None,
        headers={"Authorization":"token "+token,"User-Agent":"cinehub-agent",
                 "Accept":"application/vnd.github+json","Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.getcode(), json.loads(r.read().decode() or "{}")
    except urllib.error.HTTPError as e:
        try: return e.code, json.loads(e.read().decode() or "{}")
        except Exception: return e.code, {}
    except Exception as e:
        return 0, {"_err": str(e)[:100]}

def link(name="cinehub3099", private=True):
    tok, user = ghauth.authorize()
    if not tok: return False
    code, me = api("/user", token=tok)
    if code != 200:
        core.log("التوكن لا يملك صلاحية repo — أعد التفويض", "err"); return False
    user = me.get("login", user)

    code, r = api("/repos/%s/%s" % (user, name), token=tok)
    if code == 404:
        core.log("إنشاء مستودع %s/%s ..." % (user, name), "info")
        code, r = api("/user/repos", "POST", {"name":name,"private":private,
                      "description":"CineHub earnings engine","auto_init":False}, tok)
        if code not in (200,201):
            core.log("فشل الإنشاء: %s" % r.get("message","?"), "err"); return False
        core.log("✓ أُنشئ المستودع", "ok")
        time.sleep(2)
    else:
        core.log("المستودع موجود", "ok")

    url = "https://%s:%s@github.com/%s/%s.git" % (user, tok, user, name)
    subprocess.run(["git","remote","remove","origin"], cwd=str(core.BASE),
                   capture_output=True)
    subprocess.run(["git","remote","add","origin",url], cwd=str(core.BASE))
    subprocess.run(["git","config","user.email", core.env("MAIL_USER") or "agent@local"], cwd=str(core.BASE))
    subprocess.run(["git","config","user.name", user], cwd=str(core.BASE))
    core.set_env("GITHUB_USER", user); core.set_env("GH_REPO", name)
    core.set_env("REPO_URL", "https://github.com/%s/%s.git" % (user, name))

    core.log("دفع الملفات...", "info")
    ok, msg = repo.push("initial: CineHub v11")
    core.log(msg, "ok" if ok else "err")
    if not ok: return False

    # تفعيل Actions
    code, wfs = api("/repos/%s/%s/actions/workflows" % (user, name), token=tok)
    if code == 200:
        for w in wfs.get("workflows", []):
            api("/repos/%s/%s/actions/workflows/%s/enable" % (user, name, w["id"]), "PUT", token=tok)
        core.log("✓ Actions مُفعّل (%d workflow)" % len(wfs.get("workflows", [])), "ok")
    else:
        core.log("Actions سيُفعّل بعد أول دفع — راجع تبويب Actions", "warn")

    api("/repos/%s/%s" % (user, name), "PATCH", {"has_issues":True,"has_wiki":False}, tok)
    print("\n" + core.C['b'] + "══ تم الربط ══" + core.C['x'])
    print("  المستودع : https://github.com/" + user + "/" + name)
    print("  المحرّك   : https://github.com/" + user + "/" + name + "/actions")
    print("  الموقع    : https://" + user + ".github.io/" + name + "/")
    return True

def enable_pages():
    tok, user = ghauth.authorize()
    name = core.env("GH_REPO") or "cinehub3099"
    code, r = api("/repos/%s/%s/pages" % (user,name), "POST",
                  {"source":{"branch":"main","path":"/"}}, tok)
    if code in (201, 204, 409): core.log("✓ GitHub Pages مُفعّل: https://%s.github.io/%s/" % (user,name), "ok")
    else: core.log("Pages: %s" % r.get("message","?"), "warn")

if __name__ == "__main__":
    link()
