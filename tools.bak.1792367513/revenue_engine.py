#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""محرك الإيرادات المركزي: سجل تكاملات + دفتر بقيد فريد + عملات + مزامنة."""
import json, os, sys, time, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

REG, LED, FX = "data/revenue.json", "data/ledger.json", "data/fx.json"
ACCOUNT = ("unregistered","pending_approval","pending_credentials","active","suspended","rejected","blocked")
TXSTATE = ("estimated","pending","approved","rejected","paid")
TXTYPE  = ("impression_revenue","click_revenue","lead","sale","revshare","bonus","referral","payout")

# id, name, type, official, min_payout, methods, schedule, adult, api, env_key, note, verified
P = [
 ("exoclick","ExoClick","advertising","https://www.exoclick.com/publishers/","$20 Paxum · $50 كريبتو · $200 حوالة","Paxum · كريبتو · Wire","Net7 أسبوعي أو Net20 شهري","yes","yes","EXOCLICK_ZONE","أعلى RPM إباحي","2026-10-18"),
 ("adsterra","Adsterra","advertising","https://adsterra.com/publishers/","$5 Paxum/WebMoney · $25 PayPal","PayPal · Paxum · USDT","كل أسبوعين","yes","no","ADSTERRA_ZONE","أسرع قبول (<10 دقائق) — ابدأ به","2026-10-18"),
 ("juicyads","JuicyAds","advertising","https://www.juicyads.com/signup","$25","PayPal · Paxum · كريبتو","أسبوعي (الجمعة)","yes","no","JUICYADS_ZONE","إحالة 20% مدى الحياة","2026-10-18"),
 ("hilltopads","HilltopAds","advertising","https://hilltopads.com/publishers/","$20","USDT · Wise · PayPal","Net7 الثلاثاء","yes","no","HILLTOPADS_ZONE","USDT TRC20/ERC20","2026-10-18"),
 ("popads","PopAds","advertising","https://www.popads.net/","$5","متعدد","عند الطلب","yes","no","POPADS_SITE","بوب أندر فقط","2026-10-18"),
 ("popcash","PopCash","advertising","https://popcash.net/","$10","PayPal · BTC","يومي","yes","no","POPCASH_SITE","أسرع سحب · حصة 80%","2026-10-18"),
 ("trafficstars","TrafficStars","advertising","https://trafficstars.com/","$10 USDT · $100 محافظ","USDT · BTC · Paxum","أسبوعي/شهري","yes","no","TRAFFICSTARS_ZONE","فيديو ونيتيف","2026-10-18"),
 ("clickadu","Clickadu","advertising","https://www.clickadu.com/","$50","متعدد","Net7 الثلاثاء","yes","no","CLICKADU_ZONE","إحالة 5% سنة أولى","2026-10-18"),
 ("evadav","EvaDav","advertising","https://evadav.com/","$100","بلا كريبتو","Net7 الثلاثاء","yes","no","EVADAV_ZONE","تدفع عن اشتراك push","2026-10-18"),
 ("aads","A-ADS","advertising","https://aads.com/earn/","رصيد→BTC تلقائي","BTC","تلقائي","yes","no","AADS_UNIT","بلا JS · بلا حد ترافيك · يقبل NSFW","2026-10-18"),
 ("stripchat","Stripchat (StripCash)","affiliate_lead","https://affiliates.stripchat.com/","$50","Wire · Paxum","شهري","yes","yes","STRIPCHAT_REF","$1.50/تسجيل مجاني · 20-25% مدى الحياة","2026-10-18"),
 ("crakrevenue","CrakRevenue","affiliate_sale","https://www.crakrevenue.com/","$50","Wire · Paxum","شهري","yes","yes","CRAKREVENUE_REF","$168/تحويل (عرض Stripchat)","2026-10-18"),
 ("chaturbate","Chaturbate","affiliate_revshare","https://chaturbate.com/affiliates/","$50","Wire · Paxum","شهري","yes","yes","CHATURBATE_REF","20% مدى الحياة","2026-10-18"),
 ("bonga","BongaCams","affiliate_revshare","https://bongacash.com/","$50","Wire","شهري","yes","no","BONGA_REF","revshare","2026-10-18"),
 ("jasmin","LiveJasmin","affiliate_revshare","https://www.livejasmin.com/en/affiliate","$50","Wire","شهري","yes","no","JASMIN_REF","revshare عالي","2026-10-18"),
 ("streamate","Streamate","affiliate_revshare","https://affiliate.streamate.com/","$50","Wire","شهري","yes","no","STREAMATE_REF","revshare","2026-10-18"),
 ("jerkmate","Jerkmate","affiliate_revshare","https://jerkmate.com/","$50","Wire","شهري","yes","no","JERKMATE_REF","revshare","2026-10-18"),
 ("flirt4free","Flirt4Free","affiliate_revshare","https://www.flirt4free.com/affiliates/","$50","Wire","شهري","yes","no","FLIRT4FREE_REF","revshare","2026-10-18"),
 ("imlive","ImLive","affiliate_revshare","https://www.imlive.com/affiliate/","$50","Wire","شهري","yes","no","IMLIVE_REF","revshare","2026-10-18"),
 ("camsoda","CamSoda","affiliate_revshare","https://www.camsoda.com/affiliates","$50","Wire","شهري","yes","no","CAMSODA_REF","revshare","2026-10-18"),
 ("xhlive","xHamsterLive","affiliate_revshare","https://xhamsterlive.com/","$50","Wire","شهري","yes","no","XHLIVE_REF","revshare","2026-10-18"),
 ("fancentro","FanCentro","subscription","https://fancentro.com/","$50","Wire","شهري","yes","no","FANCENTRO_REF","اشتراك شهري","2026-10-18"),
 ("lospollos","LosPollos","cpa","https://lopollos.com/","$50","PayPal","شهري","yes","no","LOSPOLLOS_REF","عائد لكل تسجيل","2026-10-18"),
 ("mobidea","Mobidea","cpa","https://www.mobidea.com/","$50","PayPal","شهري","yes","no","MOBIDEA_REF","CPA","2026-10-18"),
 ("zeydoo","Zeydoo","cpa","https://zeydoo.com/","$50","Paxum","شهري","yes","no","ZEYDOO_REF","CPA","2026-10-18"),
]

def _rec(o, pid, name, typ, url, mn, pay, sched, adult, api, key, note, ver):
    has_key = core.has(key)
    st = o.get("status") or ("pending_approval" if has_key else "unregistered")
    if has_key and st in ("unregistered","pending_credentials"): st = "pending_approval"
    if not has_key and st == "active": st = "pending_credentials"
    return {
      "id": pid, "name": name, "type": typ, "official_url": url,
      "account_status": st,
      "credential_status": "present" if has_key else "pending_credentials",
      "credential_env": key, "credential_fingerprint": core.fp(core.get(key)) if has_key else "",
      "publisher_id": o.get("publisher_id", ""),
      "clicks": int(o.get("clicks", 0)), "conversions": int(o.get("conversions", 0)),
      "estimated": float(o.get("estimated", 0.0)),
      "approved": float(o.get("approved", 0.0)),
      "pending": float(o.get("pending", 0.0)),
      "rejected": float(o.get("rejected", 0.0)),
      "paid": float(o.get("paid", 0.0)),
      "currency": "USD",
      "min_payout": mn, "payment_methods": pay, "payment_schedule": sched,
      "adult_ok": adult, "api_available": api,
      "last_ok_sync": o.get("last_ok_sync", ""), "last_attempt": o.get("last_attempt", ""),
      "last_error": o.get("last_error", ""),
      "verified_on": ver, "note": note,
      "fit_score": int(o.get("fit_score", 0)),
      "reachable": o.get("reachable"), "http_code": o.get("http_code"),
      "checked_on": o.get("checked_on", ""),
      "signup": url,
    }

def build():
    old = core.load(REG, {}) or {}
    oi = {p.get("id"): p for p in (old.get("providers") or []) if isinstance(p, dict)}
    provs = [_rec(oi.get(row[0], {}), *row) for row in P]
    tot = {k: round(sum(p[k] for p in provs), 2) for k in ("estimated","approved","pending","rejected","paid")}
    tot["clicks"] = sum(p["clicks"] for p in provs)
    tot["conversions"] = sum(p["conversions"] for p in provs)
    out = {"schema": 3, "updated": time.strftime("%F %H:%M"), "currency": "USD", "goal_usd": 100,
           "pages_url": old.get("pages_url") or core.site(),
           "rules": ["لا يُجمع estimated مع paid", "المستلم = paid فقط",
                     "العملات المختلفة لا تُجمع دون سعر وتاريخ معلومين",
                     "قيد فريد على (المزود + معرف المعاملة) يمنع تكرار العمولة"],
           "providers": provs, "totals": tot,
           "gap_usd": round(max(0.0, 100 - tot["paid"]), 2)}
    core.save(REG, out); return out

# ── الدفتر: قيد فريد (مزود + معرف معاملة)
def _led():
    d = core.load(LED, None)
    if not isinstance(d, dict) or "tx" not in d: d = {"schema": 2, "tx": {}}
    if isinstance(d["tx"], list):
        d["tx"] = {("%s:%s" % (t.get("src",""), t.get("id",""))): t for t in d["tx"]}
        d["schema"] = 2
    return d

def add(provider, amount, state="pending", txid="", date="", ttype="click_revenue",
        currency="USD", note="", external_key=""):
    if state not in TXSTATE: raise SystemExit("حالة غير صحيحة: " + state)
    if ttype not in TXTYPE: raise SystemExit("نوع غير صحيح: " + ttype)
    d = _led()
    date = date or time.strftime("%F")
    txid = txid or external_key or ("%s|%.4f|%s|%s" % (provider, float(amount), date, ttype))
    key = "%s::%s" % (provider, txid)
    if key in d["tx"]:
        return False, key, d["tx"][key]
    usd, conv = core.convert(float(amount), currency, "USD", date)
    d["tx"][key] = {"key": key, "provider": provider, "tx_id": txid, "date": date,
                    "type": ttype, "currency": currency.upper(), "amount": round(float(amount), 4),
                    "amount_usd": usd, "fx": conv, "state": state, "note": note,
                    "imported": time.strftime("%F %H:%M")}
    core.save(LED, d)
    return True, key, d["tx"][key]

def ledger_totals():
    d = _led(); t = {s: 0.0 for s in TXSTATE}; unconv = 0
    bycur = {}
    for x in d["tx"].values():
        if x.get("amount_usd") is None: unconv += 1
        else: t[x["state"]] = round(t.get(x["state"], 0.0) + x["amount_usd"], 4)
        bycur[x["currency"]] = round(bycur.get(x["currency"], 0.0) + x["amount"], 4)
    return t, len(d["tx"]), unconv, bycur

def apply_ledger():
    r = build(); d = _led(); by = {}
    for x in d["tx"].values():
        b = by.setdefault(x["provider"], {s: 0.0 for s in TXSTATE})
        if x.get("amount_usd") is None: continue
        b[x["state"]] = round(b.get(x["state"], 0.0) + x["amount_usd"], 4)
    for p in r["providers"]:
        b = by.get(p["id"])
        if not b: continue
        for k in ("pending","approved","rejected","paid"): p[k] = b[k]
        if b["approved"] or b["paid"]: p["account_status"] = "active"
    t = {k: round(sum(x[k] for x in r["providers"]), 2) for k in ("estimated","approved","pending","rejected","paid")}
    t["clicks"] = sum(x["clicks"] for x in r["providers"])
    t["conversions"] = sum(x["conversions"] for x in r["providers"])
    r["totals"] = t; r["gap_usd"] = round(max(0.0, 100 - t["paid"]), 2)
    core.save(REG, r); return r

def sync():
    r = build()
    p = next((x for x in r["providers"] if x["id"] == "exoclick"), None)
    if not p: return "لا ExoClick"
    tok, usr, pwd = core.get("EXOCLICK_API_TOKEN"), core.get("EXOCLICK_API_USER"), core.get("EXOCLICK_API_PASS")
    p["last_attempt"] = time.strftime("%F %H:%M")
    if not (tok or (usr and pwd)):
        p["last_error"] = "pending_credentials: ضع EXOCLICK_API_TOKEN"
        core.save(REG, r); return "ExoClick: pending_credentials"
    try:
        body = {"api_token": tok} if tok else {"username": usr, "password": pwd}
        req = urllib.request.Request("https://api.exoclick.com/v2/login",
              data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        j = json.loads(urllib.request.urlopen(req, timeout=30).read())
        t = j.get("token") or (j.get("data") or {}).get("token")
        if not t: raise ValueError("لا توكن في الرد")
        d0 = time.strftime("%Y-%m-%d")
        q = urllib.parse.urlencode({"filter[date_from]": d0, "filter[date_to]": d0})
        req2 = urllib.request.Request("https://api.exoclick.com/v2/statistics/p/global?" + q,
               data=b"", headers={"Authorization": "Bearer " + t})
        s = json.loads(urllib.request.urlopen(req2, timeout=30).read())
        rows = s.get("result") or s.get("data") or []
        earn = sum(float(x.get("revenue") or x.get("earnings") or 0) for x in rows if isinstance(x, dict))
        p["estimated"] = round(earn, 4); p["last_ok_sync"] = time.strftime("%F %H:%M")
        p["last_error"] = ""; p["account_status"] = "active"
        core.save(REG, r); return "ExoClick: $%.4f (من API)" % earn
    except Exception as e:
        p["last_error"] = "%s: %s" % (type(e).__name__, str(e)[:70])
        core.save(REG, r); return "ExoClick: فشل → " + p["last_error"]

def fx_set(frm, to, rate, date="", source="manual"):
    d = core.load(FX, {"rates": []}) or {"rates": []}
    d["rates"] = [r for r in d.get("rates", [])
                  if not (r["from"] == frm.upper() and r["to"] == to.upper() and r["date"] == (date or time.strftime("%F")))]
    d["rates"].append({"from": frm.upper(), "to": to.upper(), "rate": float(rate),
                       "date": date or time.strftime("%F"), "source": source})
    d["updated"] = time.strftime("%F %H:%M"); core.save(FX, d)
    return "سعر مثبّت: %s→%s = %s (%s)" % (frm, to, rate, d["rates"][-1]["date"])

def report():
    r = apply_ledger(); t, n, unconv, bycur = ledger_totals()
    print("معاملات: %d · بلا سعر صرف: %d" % (n, unconv))
    for k in TXSTATE: print("  %-10s $%.4f" % (k, t.get(k, 0.0)))
    if len(bycur) > 1: print("  عملات:", bycur)
    print("الفجوة نحو 100$ (من المستلم): $%.2f" % r["gap_usd"])
    act = [p for p in r["providers"] if p["credential_status"] == "present"]
    print("مزودون بمفاتيح: %d من %d" % (len(act), len(r["providers"])))
    for p in act: print("  · %-18s %s" % (p["id"], p["account_status"]))

def cli():
    a = sys.argv[1:]
    if not a: return report()
    c = a[0]
    if c == "build": build(); print("✓ data/revenue.json")
    elif c == "sync": print(sync())
    elif c == "report": report()
    elif c == "add" and len(a) >= 4:
        kw = dict(zip([x.lstrip("-") for x in a[4::2]], a[5::2]))
        okk, key, tx = add(a[1], a[2], a[3], kw.get("id",""), kw.get("date",""),
                           kw.get("type","click_revenue"), kw.get("cur","USD"), kw.get("note",""))
        print(("✓ أُضيف " if okk else "= مكرر، تُخطّي ") + key)
        if tx.get("amount_usd") is None: print("  ! بلا سعر صرف — اضبطه: revenue_engine.py fx %s USD <rate>" % tx["currency"])
        apply_ledger()
    elif c == "status" and len(a) >= 3:
        r = build()
        for p in r["providers"]:
            if p["id"] == a[1]:
                if a[2] not in ACCOUNT: print("حالات: " + ", ".join(ACCOUNT)); return
                p["account_status"] = a[2]
        core.save(REG, r); print("✓ %s → %s" % (a[1], a[2]))
    elif c == "set" and len(a) >= 4:
        r = build()
        for p in r["providers"]:
            if p["id"] == a[1]:
                p[a[2]] = float(a[3]) if a[2] in ("estimated","approved","pending","rejected","paid") else a[3]
        core.save(REG, r); print("✓ %s.%s" % (a[1], a[2]))
    elif c == "fx" and len(a) >= 4: print(fx_set(a[1], a[2], a[3], a[4] if len(a) > 4 else ""))
    elif c == "dupes":
        d = _led(); print("معاملات: %d · مفاتيح فريدة: %d" % (len(d["tx"]), len(set(d["tx"]))))
    else:
        print("build|sync|report|dupes|fx <from> <to> <rate> [date]|add <p> <amt> <state> [--id X --type T --cur C --note N]|status <id> <state>|set <id> <f> <v>")

if __name__ == "__main__": cli()
