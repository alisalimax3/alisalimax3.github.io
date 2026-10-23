#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مشغّل مهام: قفل · مهلة · إعادة محاولة غير محدودة (backoff) · سجل مختصر."""
import os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

ALERTS = "data/alerts.json"

def run(name, script, timeout=600, max_attempts=0, args=None):
    """max_attempts=0 → غير محدود داخل الدورة (بسقف زمني)."""
    with core.lock(name, ttl=timeout * 2) as got:
        if not got: return ("skip", 0.0, "مقفول")
        t0 = time.time(); attempt = 0; last = ""
        while True:
            attempt += 1
            try:
                r = subprocess.run([sys.executable, script] + (args or []),
                                   capture_output=True, text=True, timeout=timeout)
                out = (r.stdout or "").strip().splitlines()
                last = out[-1][:110] if out else ""
                if r.returncode == 0: return ("ok", time.time() - t0, last)
                err = (r.stderr or "").strip().splitlines()
                last = (err[-1][:110] if err else "rc=%d" % r.returncode)
            except subprocess.TimeoutExpired:
                last = "مهلة %ds" % timeout
            except Exception as e:
                last = "%s: %s" % (type(e).__name__, str(e)[:80])
            if max_attempts and attempt >= max_attempts: return ("fail", time.time() - t0, last)
            if time.time() - t0 > timeout * 3: return ("fail", time.time() - t0, last)
            time.sleep(min(30, 2 ** attempt))
    return ("fail", time.time() - t0, last)

def alert(kind, msg, key=""):
    d = core.load(ALERTS, {"alerts": []}) or {"alerts": []}
    k = key or (kind + "|" + msg[:60])
    for a in d["alerts"]:
        if a.get("key") == k and a.get("open"): return False
    d["alerts"].append({"key": k, "kind": kind, "msg": msg, "open": True,
                        "at": time.strftime("%F %H:%M")})
    core.save(ALERTS, d); return True

def daily_report():
    import revenue_engine as RE, rewards as RW
    r = RE.apply_ledger(); t, n, unconv, _ = RE.ledger_totals()
    st = core.load("data/secrets_state.json", {}) or {}
    out = {"date": time.strftime("%F"), "at": time.strftime("%H:%M"),
           "ledger_tx": n, "unconverted": unconv,
           "totals": t, "gap_usd": r["gap_usd"],
           "credentials_present": len(st.get("present", [])),
           "credentials_missing": len(st.get("missing", [])),
           "providers_active": len([p for p in r["providers"] if p["account_status"] == "active"]),
           "providers_with_keys": len([p for p in r["providers"] if p["credential_status"] == "present"]),
           "alerts": len([a for a in (core.load(ALERTS, {}) or {}).get("alerts", []) if a.get("open")])}
    os.makedirs("data/reports", exist_ok=True)
    core.save("data/reports/%s.json" % out["date"], out)
    for p in r["providers"]:
        if p["credential_status"] == "present" and not p["last_ok_sync"]:
            alert("credential_unverified", "%s: مفتاح موجود بلا مزامنة ناجحة" % p["name"], "cred:" + p["id"])
    if unconv: alert("fx_missing", "%d معاملة بلا سعر صرف" % unconv, "fx")
    return out

if __name__ == "__main__":
    print(core.load("data/reports/%s.json" % time.strftime("%F"), "لا تقرير بعد"))
