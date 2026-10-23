#!/usr/bin/env python3
import json, os, time, urllib.request
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
def get(u, h=None):
    r = urllib.request.Request(u, headers=h or {"User-Agent": "CineHub"})
    with urllib.request.urlopen(r, timeout=25) as x: return json.loads(x.read().decode() or "{}")
src, total = [], 0.0
if E.get("ADSTERRA_API_KEY"):
    for h in ({"X-API-Key": E["ADSTERRA_API_KEY"]}, {"Authorization": "Bearer " + E["ADSTERRA_API_KEY"]}):
        try:
            d = get("https://api3.adsterra.com/api/v1/publisher/balance", h)
            b = float(d.get("balance") or d.get("amount") or 0)
            src.append({"n": "Adsterra", "usd": b, "live": True, "min": 5, "pay": "USDT/PayPal"}); total += b; break
        except Exception as e:
            src.append({"n": "Adsterra", "usd": 0, "live": False, "note": str(e)[:40], "min": 5, "pay": "USDT/PayPal"}); break
for n, k, mn, pay in (("ExoClick","EXOCLICK_ZONE",20,"Paxum/Wire"),("JuicyAds","JUICYADS_ZONE",50,"Paxum/BTC"),
                      ("Monetag","MONETAG_MULTITAG",5,"PayPal/Skrill"),("A-ADS","AADS_UNIT",0,"BTC تلقائي"),
                      ("TrafficJunky","TRAFFICJUNKY_ZONE",100,"Wire"),("PlugRush","PLUGRUSH_ZONE",25,"PayPal/BTC"),
                      ("Clickadu","CLICKADU_ZONE",5,"PayPal/Paxum"),("HilltopAds","HILLTOPADS_ZONE",50,"PayPal"),
                      ("CPAGrip","CPAGRIP_SMARTLINK",50,"PayPal"),("Stripchat","STRIPCHAT_AFF",50,"Wire")):
    src.append({"n": n, "usd": 0, "live": False, "min": mn, "pay": pay,
                "note": "المعرّف مضبوط" if E.get(k) else "ينتظر المعرّف"})
btc = 0.0
try: btc = float(get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")["bitcoin"]["usd"])
except Exception: pass
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "sources": src, "total_usd": round(total, 4), "btc_usd": btc,
  "payout": {"bank": "بنك الكريمي للتمويل الأصغر", "swift": E.get("KURAIMI_SWIFT", "KBMFYESAXXX"),
             "name": E.get("KURAIMI_NAME", ""), "account": E.get("KURAIMI_ACCOUNT", ""), "usdt": E.get("USDT_TRC20", "")},
  "ladder": ["الشبكة → USDT(TRC20) / Paxum / PayPal / BTC", "Binance P2P: USDT → نقد", "صرافة محلية", "إيداع الكريمي"]},
  open("data/wallet.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("  ✓ wallet.json ($%.4f)" % total)
