#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص الأسرار: أسماء · بصمات · تسرّب للواجهة · حالة Git. لا يطبع قيمًا."""
import os, re, sys, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

# VN_CORE_SHIM — يوفّر core.get لو core.py مش بيوفّره
try:
    import core as _vncore
    if not hasattr(_vncore, "get"):
        def _vn_get(k, d=None):
            for _n in ("CFG","CONFIG","CONF","SETTINGS","ENV","DEFAULTS","PARAMS","cfg","conf","config","settings"):
                _o = getattr(_vncore, _n, None)
                if isinstance(_o, dict) and k in _o: return _o[k]
            return getattr(_vncore, k, d)
        _vncore.get = _vn_get
except Exception:
    pass


GROUPS = {
 "ads": ["EXOCLICK_ZONE","JUICYADS_ZONE","AADS_UNIT","ADSTERRA_ZONE","HILLTOPADS_ZONE",
         "TRAFFICSTARS_ZONE","CLICKADU_ZONE","POPADS_SITE","POPCASH_SITE","EVADAV_ZONE"],
 "embeds": [k + "_EMBED" for k in ("ADSTERRA","HILLTOPADS","TRAFFICSTARS","CLICKADU","AADS","POPADS","POPCASH","EVADAV")],
 "affiliate": ["STRIPCHAT_REF","CRAKREVENUE_REF","CHATURBATE_REF","BONGA_REF","JASMIN_REF",
               "STREAMATE_REF","JERKMATE_REF","FLIRT4FREE_REF","IMLIVE_REF","CAMSODA_REF",
               "XHLIVE_REF","FANCENTRO_REF","LOSPOLLOS_REF","MOBIDEA_REF","ZEYDOO_REF"],
 "api": ["EXOCLICK_API_TOKEN","EXOCLICK_API_USER","EXOCLICK_API_PASS"],
 "site": ["GH_USER","SITE_URL","REF_CODE"],
}
SECRET = {"EXOCLICK_API_TOKEN","EXOCLICK_API_PASS"}
# مفاتيح عامة بطبيعتها: معرّف المنطقة وروابط الإحالة — آمن ظهورها في الريبو
PUBLIC_OK = {"GH_USER","SITE_URL","REF_CODE"}
WHITELIST = {"GH_USER","SITE_URL","REF_CODE"}

def report():
    E = core.env()
    out = {"present": [], "missing": [], "leaks": [], "tracked": None}
    for g, names in GROUPS.items():
        for n in names:
            (out["present"] if (E.get(n) or "").strip() else out["missing"]).append(n)
    try:
        r = subprocess.run(["git", "ls-files", "--error-unmatch", "keys.env"],
                           capture_output=True, text=True)
        out["tracked"] = (r.returncode == 0)
    except Exception: pass
    for d in (".", "go", "adult"):
        if not os.path.isdir(d): continue
        for f in os.listdir(d):
            if not f.endswith((".html", ".js", ".json")): continue
            if f in ("ads-all.json", "ads-adult.json"): continue
            try: s = open(os.path.join(d, f), encoding="utf-8", errors="ignore").read()
            except Exception: continue
            for n in SECRET:
                v = (E.get(n) or "").strip()
                if len(v) > 6 and v in s:
                    out["leaks"].append("%s→%s" % (n, os.path.join(d, f)))
    return out

def main():
    r = report()
    print("  أسرار مضبوطة : %d" % len(r["present"]))
    for n in r["present"]: print("    ✓ %-22s بصمة %s" % (n, core.fp(core.get(n))))
    print("  ناقصة        : %d" % len(r["missing"]))
    print("    " + " ".join(r["missing"][:24]))
    print("  keys.env في Git: %s" % ("نعم" if r["tracked"] else "لا"))
    print("  تسرّب للواجهة: %s" % (len(r["leaks"]) or "لا شيء"))
    for l in r["leaks"][:8]: print("    ·", l)
    core.save("data/secrets_state.json", {
        "updated": core.time.strftime("%F %H:%M"),
        "present": [{"name": n, "fingerprint": core.fp(core.get(n))} for n in r["present"]],
        "missing": r["missing"], "leaks": r["leaks"], "tracked_in_git": r["tracked"]})

if __name__ == "__main__": main()

# ══ جسر: هذا الملف يحجب وحدة secrets القياسية (نفس الاسم في sys.path) ══
# نُعيد تصدير واجهة الوحدة القياسية كي لا تنهار أي أداة تستخدم secrets.choice
import importlib.util as _ilu, sysconfig as _sc, os as _os
def _bridge():
    cands = [_os.path.join(_sc.get_paths().get("stdlib", ""), "secrets.py"),
             _os.path.join(_sc.get_paths().get("stdlib", ""), "lib-dynload", "..", "secrets.py")]
    for c in cands:
        if not _os.path.exists(c): continue
        try:
            spec = _ilu.spec_from_file_location("_stdlib_secrets", c)
            m = _ilu.module_from_spec(spec); spec.loader.exec_module(m)
            for n in ("choice","randbelow","randbits","token_bytes","token_hex",
                      "token_urlsafe","compare_digest","SystemRandom","DEFAULT_ENTROPY"):
                if hasattr(m, n) and n not in globals(): globals()[n] = getattr(m, n)
            return True
        except Exception: continue
    return False
_BRIDGED = _bridge()

def genpass(n=15):
    """كلمة مرور قوية — بلا اعتماد على secrets إن فشل الجسر."""
    alpha = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    b = _os.urandom(n)
    return "".join(alpha[x % len(alpha)] for x in b)
