#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  MONEY.sh — سجل إيرادات حقيقي · دفتر مالي · مكافآت · نقرات · لوحة · نشر
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || exit 1
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data go .github/workflows
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/money.$(date +%F_%H%M%S).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }
[ -f tools/core.py ] || { bad "شغّل FIX.sh أولًا"; exit 1; }

hd "1 · سجل الإيرادات + الدفتر المالي"
cat > tools/revenue.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""سجل الإيرادات: مزودون بحالات + دفتر مالي يمنع تكرار المعاملة."""
import json, os, sys, time, datetime, urllib.request, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

REV, LED = "data/revenue.json", "data/ledger.json"
STATES = ("unregistered", "pending", "active", "suspended", "blocked")
LSTATES = ("pending", "approved", "paid", "rejected")

# id, name, kind, signup, key, min, pay, schedule, note, verified
P = [
 ("exoclick","ExoClick","banner","https://www.exoclick.com/publishers/","EXOCLICK_ZONE","$20 Paxum / $50 كريبتو / $200 حوالة","Paxum · كريبتو · Wire","Net7 أسبوعي (الاثنين) أو Net20","أعلى RPM إباحي — الأولوية 1","2026-10-18"),
 ("adsterra","Adsterra","banner","https://adsterra.com/publishers/","ADSTERRA_ZONE","$5 Paxum/WebMoney · $25 PayPal","PayPal · Paxum · USDT","كل أسبوعين (1-2 و16-17)","أسرع قبول — ابدأ به للاختبار","2026-10-18"),
 ("juicyads","JuicyAds","banner","https://www.juicyads.com/signup","JUICYADS_ZONE","$25","PayPal · Paxum · كريبتو","أسبوعي (الجمعة)","إحالة 20% مدى الحياة","2026-10-18"),
 ("hilltopads","HilltopAds","banner","https://hilltopads.com/publishers/","HILLTOPADS_ZONE","$20","USDT · Wise · PayPal","Net7 (الثلاثاء)","USDT TRC20/ERC20","2026-10-18"),
 ("popads","PopAds","popunder","https://www.popads.net/","POPADS_SITE","$5","متعدد","عند الطلب","بوب أندر فقط","2026-10-18"),
 ("popcash","PopCash","popunder","https://popcash.net/","POPCASH_SITE","$10","PayPal · BTC","يومي","أسرع سحب في الصناعة","2026-10-18"),
 ("trafficstars","TrafficStars","banner","https://trafficstars.com/","TRAFFICSTARS_ZONE","$10 USDT / $100 محافظ / $1000 حوالة","USDT · BTC · Paxum","أسبوعي/شهري","فيديو ونيتيف","2026-10-18"),
 ("clickadu","Clickadu","banner","https://www.clickadu.com/","CLICKADU_ZONE","$50","متعدد","Net7 الثلاثاء","إحالة 5% سنة أولى","2026-10-18"),
 ("evadav","EvaDav","push","https://evadav.com/","EVADAV_ZONE","$100 · $1000 حوالة","بلا كريبتو","Net7 الثلاثاء","تدفع عن اشتراك push (CPA)","2026-10-18"),
 ("aads","A-ADS","banner","https://aads.com/earn/","AADS_UNIT","رصيد → BTC تلقائي","BTC فقط","تلقائي","يقبل NSFW · بلا JS · بلا حد ترافيك","2026-10-18"),
 ("stripchat","Stripchat (StripCash)","cam-ppl","https://affiliates.stripchat.com/","STRIPCHAT_REF","$50","Wire · Paxum","شهري","$1.50 لكل تسجيل مجاني · 20-25% مدى الحياة","2026-10-18"),
 ("crakrevenue","CrakRevenue","cam-pps","https://www.crakrevenue.com/","CRAKREVENUE_REF","$50","Wire · Paxum","شهري","$168 لكل تحويل (عرض Stripchat)","2026-10-18"),
 ("chaturbate","Chaturbate","cam-rev","https://chaturbate.com/affiliates/","CHATURBATE_REF","$50","Wire · Paxum","شهري","20% مدى الحياة","2026-10-18"),
 ("bonga","BongaCams","cam-rev","https://bongacash.com/","BONGA_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("jasmin","LiveJasmin","cam-rev","https://www.livejasmin.com/en/affiliate","JASMIN_REF","$50","Wire","شهري","revshare عالي","2026-10-18"),
 ("streamate","Streamate","cam-rev","https://affiliate.streamate.com/","STREAMATE_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("jerkmate","Jerkmate","cam-rev","https://jerkmate.com/","JERKMATE_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("flirt4free","Flirt4Free","cam-rev","https://www.flirt4free.com/affiliates/","FLIRT4FREE_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("imlive","ImLive","cam-rev","https://www.imlive.com/affiliate/","IMLIVE_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("camsoda","CamSoda","cam-rev","https://www.camsoda.com/affiliates","CAMSODA_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("xhlive","xHamsterLive","cam-rev","https://xhamsterlive.com/","XHLIVE_REF","$50","Wire","شهري","revshare","2026-10-18"),
 ("fancentro","FanCentro","subs","https://fancentro.com/","FANCENTRO_REF","$50","Wire","شهري","اشتراك شهري","2026-10-18"),
 ("lospollos","LosPollos","cpa","https://lopollos.com/","LOSPOLLOS_REF","$50","PayPal","شهري","عائد لكل تسجيل","2026-10-18"),
 ("mobidea","Mobidea","cpa","https://www.mobidea.com/","MOBIDEA_REF","$50","PayPal","شهري","CPA","2026-10-18"),
 ("zeydoo","Zeydoo","cpa","https://zeydoo.com/","ZEYDOO_REF","$50","Paxum","شهري","CPA","2026-10-18"),
]

def build():
    old = core.load(REV, {}) or {}
    oi = {p.get("id"): p for p in (old.get("providers") or []) if isinstance(p, dict)}
    provs = []
    for pid, name, kind, url, key, mn, pay, sched, note, ver in P:
        o = oi.get(pid, {})
        has_key = bool(core.get(key))
        st = o.get("status") or ("active" if has_key else "unregistered")
        if has_key and st == "unregistered": st = "pending"
        provs.append({
            "id": pid, "name": name, "kind": kind, "signup": url, "key": key,
            "credential": has_key, "min_payout": mn, "methods": pay, "schedule": sched,
            "note": note, "verified_on": ver,
            "status": st, "publisher_id": o.get("publisher_id", ""),
            "clicks": int(o.get("clicks", 0)), "conversions": int(o.get("conversions", 0)),
            "estimated": float(o.get("estimated", 0.0)),
            "approved": float(o.get("approved", 0.0)),
            "pending": float(o.get("pending", 0.0)),
            "paid": float(o.get("paid", 0.0)),
            "last_sync": o.get("last_sync", ""), "last_error": o.get("last_error", ""),
        })
    out = {
        "updated": time.strftime("%F %H:%M"), "currency": "USD", "goal_usd": 100,
        "pages_url": old.get("pages_url") or core.site(),
        "rule": "لا يُجمع التقديري مع المستلم. المستلم = paid فقط.",
        "providers": provs,
        "totals": {k: round(sum(p[k] for p in provs), 2)
                   for k in ("estimated", "approved", "pending", "paid")},
    }
    out["totals"]["clicks"] = sum(p["clicks"] for p in provs)
    out["totals"]["conversions"] = sum(p["conversions"] for p in provs)
    out["gap_usd"] = round(max(0.0, 100 - out["totals"]["paid"]), 2)
    core.save(REV, out)
    return out

def _ledger():
    d = core.load(LED, {"tx": []})
    if not isinstance(d, dict) or "tx" not in d: d = {"tx": []}
    return d

def add_tx(src, amount, state="pending", txid="", date="", note="", cur="USD"):
    if state not in LSTATES: raise SystemExit("حالة غير صحيحة: " + state)
    d = _ledger()
    date = date or time.strftime("%F")
    txid = txid or "%s|%.4f|%s" % (src, float(amount), date)
    key = "%s:%s" % (src, txid)
    if any(t.get("key") == key for t in d["tx"]):
        return False, key
    d["tx"].append({"key": key, "src": src, "id": txid, "date": date,
                    "amount": round(float(amount), 4), "cur": cur,
                    "state": state, "note": note, "added": time.strftime("%F %H:%M")})
    core.save(LED, d)
    return True, key

def totals():
    d = _ledger(); t = {s: 0.0 for s in LSTATES}
    for x in d["tx"]: t[x["state"]] = round(t.get(x["state"], 0.0) + x["amount"], 4)
    return t, len(d["tx"])

def apply_ledger():
    """يُسقط الدفتر على السجل — لا جمع تقديري مع مستلم."""
    r = build(); L = _ledger()
    by = {}
    for x in L["tx"]:
        b = by.setdefault(x["src"], {"pending": 0.0, "approved": 0.0, "paid": 0.0, "rejected": 0.0})
        b[x["state"]] = round(b.get(x["state"], 0.0) + x["amount"], 4)
    for p in r["providers"]:
        b = by.get(p["id"])
        if not b: continue
        p["pending"], p["approved"], p["paid"] = b["pending"], b["approved"], b["paid"]
        if b["approved"] or b["paid"]: p["status"] = "active"
    r["totals"] = {k: round(sum(x[k] for x in r["providers"]), 2)
                   for k in ("estimated", "approved", "pending", "paid")}
    r["totals"]["clicks"] = sum(x["clicks"] for x in r["providers"])
    r["totals"]["conversions"] = sum(x["conversions"] for x in r["providers"])
    r["gap_usd"] = round(max(0.0, 100 - r["totals"]["paid"]), 2)
    core.save(REV, r)
    return r

def sync():
    """مزامنة حقيقية عبر API ExoClick — إن وُجد توكن أو حساب."""
    r = build()
    p = next(x for x in r["providers"] if x["id"] == "exoclick")
    tok = core.get("EXOCLICK_API_TOKEN")
    usr, pwd = core.get("EXOCLICK_API_USER"), core.get("EXOCLICK_API_PASS")
    if not (tok or (usr and pwd)):
        p["last_error"] = "بانتظار توكن API من لوحة ExoClick"
        p["last_sync"] = time.strftime("%F %H:%M"); core.save(REV, r)
        return "ExoClick: بانتظار بيانات الاعتماد"
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
        p["estimated"] = round(earn, 4); p["last_sync"] = time.strftime("%F %H:%M")
        p["last_error"] = ""; p["status"] = "active"
        core.save(REV, r)
        return "ExoClick: %s $ (تقديري، مؤكَّد من API)" % round(earn, 4)
    except Exception as e:
        p["last_error"] = "%s: %s" % (type(e).__name__, str(e)[:80])
        p["last_sync"] = time.strftime("%F %H:%M"); core.save(REV, r)
        return "ExoClick: فشل المزامنة → " + p["last_error"]

def cli():
    a = sys.argv[1:]
    if not a:
        r = apply_ledger()
        print("الإجمالي: مستلم $%.2f · مؤكد $%.2f · معلق $%.2f · تقديري $%.2f · الفجوة $%.2f"
              % (r["totals"]["paid"], r["totals"]["approved"], r["totals"]["pending"],
                 r["totals"]["estimated"], r["gap_usd"]))
        return
    c = a[0]
    if c == "build": build(); print("تم بناء data/revenue.json")
    elif c == "sync": print(sync())
    elif c == "report":
        r = apply_ledger(); t, n = totals()
        print("معاملات: %d" % n)
        for k in LSTATES: print("  %-9s $%.2f" % (k, t.get(k, 0.0)))
        print("فجوة نحو 100$: $%.2f" % r["gap_usd"])
    elif c == "add" and len(a) >= 4:
        kw = dict(zip([x.strip("-") for x in a[4::2]], a[5::2]))
        added, key = add_tx(a[1], a[2], a[3], kw.get("id", ""), kw.get("date", ""), kw.get("note", ""))
        print(("أُضيف " if added else "مكرر — تُخطّي ") + key); apply_ledger()
    elif c == "status" and len(a) >= 3:
        r = build()
        for p in r["providers"]:
            if p["id"] == a[1]: p["status"] = a[2]
        core.save(REV, r); print("تم: %s → %s" % (a[1], a[2]))
    elif c == "set" and len(a) >= 4:
        r = build()
        for p in r["providers"]:
            if p["id"] == a[1]:
                p[a[2]] = float(a[3]) if a[2] in ("estimated","approved","pending","paid") else a[3]
        core.save(REV, r); print("تم: %s.%s" % (a[1], a[2]))
    else:
        print("استخدام: revenue.py [build|sync|report|add <src> <amount> <state> [--id X --date Y --note Z]|status <id> <state>|set <id> <field> <v>]")

if __name__ == "__main__": cli()
PYEOF
python3 -m py_compile tools/revenue.py && ok "revenue.py" || bad "revenue.py"
python3 tools/revenue.py build 2>&1 | tee -a "$LOG"
python3 tools/revenue.py report 2>&1 | tee -a "$LOG"

hd "2 · المكافآت اليومية الحقيقية"
cat > tools/rewards.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""مكافآت يومية: نقاط مؤيدة بعائد مؤكد + منع تكرار سيرفري + صفحة هبوط."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue

CFG = {
 "model": "points-share",
 "claim_points": 5,
 "ref_points": 25,
 "share_pct": 50,
 "honest": ("النقاط ليست دولارًا. قيمتها = حصتك من 50% من العائد المؤكد. "
            "تصبح قابلة للصرف عندما يصل العائد المؤكد إلى 20$ (أقل حد سحب فعلي)."),
 "rules": [
   "مطالبة واحدة كل 24 ساعة لكل جهاز — يمنعها عدّاد سيرفري (Abacus) لا localStorage.",
   "إعادة مسح المتصفح لا تعطي مطالبة إضافية في نفس اليوم.",
   "النقاط محفوظة على جهازك؛ العدد الكلي محفوظ على السيرفر.",
   "لا تُصرف أكثر من 50% من العائد المؤكد (سقف الميزانية).",
   "الزيارات الآلية والنقرات المصطنعة تُحتسب كزيارات لكن لا تُنشئ مالًا.",
 ],
 "not_money": ["لا سحب نقدي قبل 20$ مؤكد", "لا رصيد وهمي", "لا مضاعفة بالمشاهدة الذاتية"],
}

def build():
    r = revenue.apply_ledger()
    conf = r["totals"]["approved"] + r["totals"]["paid"]
    pool = round(conf * CFG["share_pct"] / 100.0, 4)
    core.save("data/rewards.json", {
        "updated": time.strftime("%F %H:%M"), "namespace": core.ns(),
        "funding": {"mode": "share-of-confirmed-revenue", "share_pct": CFG["share_pct"],
                    "confirmed_usd": round(conf, 2), "pool_usd": pool,
                    "status": "غير ممول بعد" if pool <= 0 else "ممول"},
        "claim_points": CFG["claim_points"], "ref_points": CFG["ref_points"],
        "rules": CFG["rules"], "honest": CFG["honest"], "not_money": CFG["not_money"]})
    return pool, conf

PAGE = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>المكافأة اليومية — CineHub 3099</title>
<meta name="description" content="مطالبة يومية بنقاط حقيقية مربوطة بعائد الموقع">
<link rel="manifest" href="manifest.json">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:640px;margin:0 auto;padding:18px}
h1{font-size:22px;margin:.3em 0}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:16px;margin:12px 0}
.big{font-size:34px;font-weight:700;color:#39d98a;line-height:1.2}
.btn{display:block;width:100%%;padding:14px;border:0;border-radius:12px;background:#2f6df6;color:#fff;
font-size:16px;font-weight:600;cursor:pointer;margin-top:10px}
.btn[disabled]{background:#26303f;color:#7d8896;cursor:default}
.k{color:#8b96a8;font-size:13px}a{color:#5ca9ff}
ul{padding-inline-start:20px;font-size:13.5px;color:#c3ccd8}
.warn{background:#1b1508;border-color:#3a2c08;color:#e8c76a;font-size:13px}
</style></head><body><div class="w">
<h1>🎁 المكافأة اليومية</h1>
<p class="k">مطالبة واحدة كل يوم · %(pts)d نقطة · إحالة %(ref)d نقطة لكل مطالبة من إحالتك</p>

<div class="card">
  <div class="k">نقاطك</div>
  <div class="big" id="pts">—</div>
  <div class="k">مطالباتك: <b id="cl">—</b> · السلسلة: <b id="st">—</b> يوم</div>
  <button class="btn" id="go" onclick="claim()">جارٍ التحقق…</button>
  <div class="k" id="msg" style="margin-top:8px"></div>
</div>

<div class="card">
  <div class="k">الميزانية (سيرفر)</div>
  <div>عائد مؤكد: <b>$%(conf).2f</b> · حصة المكافآت (50%%): <b>$%(pool).4f</b> · حالة التمويل: <b>%(fstat)s</b></div>
  <div class="k">إجمالي المطالبات عالميًا: <b data-hits="claims">…</b> — حصتك = مطالباتك ÷ الإجمالي × الحصة.</div>
</div>

<div class="card warn"><b>بصراحة:</b> %(honest)s</div>

<div class="card"><b>الشروط</b><ul>%(rules)s</ul></div>
<p class="k"><a href="./">الرئيسية</a> · <a href="earn.html">اكسب أكثر</a> · <a href="owner.html">لوحة المالك</a></p>
</div>
<script src="hits.js" defer></script>
<script>
var NS="%(ns)s", PT=%(pts)d, REF=%(ref)d;
function v(){try{var x=localStorage.getItem("ch_vid");if(!x){x=Math.random().toString(36).slice(2,10)+Date.now().toString(36);localStorage.setItem("ch_vid",x);}return x;}catch(e){return "anon";}}
function ls(k,d){try{return parseInt(localStorage.getItem(k)||d,10)||0;}catch(e){return 0;}}
function ss(k,v){try{localStorage.setItem(k,String(v));}catch(e){}}
function d(){return new Date().toISOString().slice(0,10);}
function paint(){
  var c=ls("ch_claims",0); document.getElementById("pts").textContent=(c*PT)+" نقطة";
  document.getElementById("cl").textContent=c;
  document.getElementById("st").textContent=ls("ch_streak",0);
  var done=ls("ch_last",0)===parseInt(d().replace(/-/g,""),10);
  var b=document.getElementById("go");
  if(done){b.disabled=true;b.textContent="تمت مطالبة اليوم ✓";}
  else{b.disabled=false;b.textContent="اطالب بـ "+PT+" نقطة";}
}
function claim(){
  var b=document.getElementById("go"); b.disabled=true; b.textContent="جارٍ التحقق…";
  var key="claim-"+d()+"-"+v();
  fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/"+key)
   .then(function(r){return r.json();})
   .then(function(j){
     var first=(j&&j.value===1);
     if(!first){document.getElementById("msg").textContent="جهازك طالب اليوم بالفعل — منع التكرار من السيرفر.";paint();return;}
     fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/claims").catch(function(){});
     var ref="";try{ref=localStorage.getItem("ch_ref")||"";}catch(e){}
     if(ref) fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/ref-"+ref.replace(/[^A-Za-z0-9._-]/g,"-")).catch(function(){});
     var c=ls("ch_claims",0)+1; ss("ch_claims",c); ss("ch_last",parseInt(d().replace(/-/g,""),10));
     var y=new Date(Date.now()-86400000).toISOString().slice(0,10);
     var st=(ls("ch_streak_date","")===y)?ls("ch_streak",0)+1:1;
     ss("ch_streak",st); ss("ch_streak_date",d());
     document.getElementById("msg").textContent="✓ أُضيفت "+PT+" نقطة"+(st>1?" · سلسلة "+st+" يوم":"");
     paint();
   })
   .catch(function(){document.getElementById("msg").textContent="فشل الشبكة — أعد المحاولة.";b.disabled=false;b.textContent="أعد المحاولة";});
}
paint();
</script></body></html>"""

EARN = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>اكسب أكثر</title>
<link rel="manifest" href="manifest.json">
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:680px;margin:0 auto;padding:18px}h1{font-size:22px}
.card{background:#131a25;border:1px solid #1e2635;border-radius:14px;padding:14px;margin:11px 0}
code{background:#0b0f17;padding:3px 8px;border-radius:6px;font-size:12.5px;word-break:break-all;display:block;margin:6px 0}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}</style></head><body><div class="w">
<h1>💸 طرق الكسب</h1>
<div class="card"><b>1 · مطالبة يومية</b><p class="k">%(pts)d نقطة كل يوم. <a href="rewards.html">افتح الصفحة</a></p></div>
<div class="card"><b>2 · رابط الإحالة</b><p class="k">%(ref)d نقطة لكل مطالبة تأتي من إحالتك. شارك:</p>
<code>%(site)s/?ref=%(code)s</code></div>
<div class="card"><b>3 · مشاركة العناوين</b><p class="k">انشر من <a href="promote-adult.html">صفحة الترويج</a> — كل فتح يعيدك عائدًا.</p></div>
<div class="card"><b>4 · فتح الصفحات</b><p class="k">كل صفحة تُفتح = ظهور إعلان = عائد للموقع → يغذّي صندوق المكافآت.</p></div>
<div class="card"><b>بصراحة</b><p class="k">%(honest)s</p></div>
<p><a href="rewards.html">المكافأة</a> · <a href="owner.html">لوحة المالك</a></p></div></body></html>"""

def page():
    pool, conf = build()
    core.write_if_changed("rewards.html", PAGE % {
        "pts": CFG["claim_points"], "ref": CFG["ref_points"], "ns": core.ns(),
        "conf": conf, "pool": pool,
        "fstat": "غير ممول بعد" if pool <= 0 else "ممول",
        "honest": CFG["honest"],
        "rules": "".join("<li>%s</li>" % core.esc(r) for r in CFG["rules"])})
    code = core.get("REF_CODE") or core.get("GH_USER") or "ch"
    core.write_if_changed("earn.html", EARN % {
        "pts": CFG["claim_points"], "ref": CFG["ref_points"],
        "site": core.site(), "code": code, "honest": CFG["honest"]})
    print("  ✓ rewards.html + earn.html · صندوق=$%.4f (عائد مؤكد=$%.2f)" % (pool, conf))

if __name__ == "__main__": page()
PYEOF
python3 -m py_compile tools/rewards.py && ok "rewards.py" || bad "rewards.py"
python3 tools/rewards.py 2>&1 | tee -a "$LOG"

hd "3 · صفحات النقر (تتبع حقيقي) + الشبكات العامة"
cat > tools/clicks.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ينشئ go/<id>.html: يعدّ النقرة سيرفريًا ثم يحوّل لرابط الإحالة الحقيقي."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue

GOTPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>جارٍ التحويل… — %(name)s</title><meta name="robots" content="noindex">
<style>body{background:#0b0d12;color:#e9eef6;font:16px system-ui,Tahoma;display:flex;
align-items:center;justify-content:center;height:100vh;margin:0;text-align:center}
a{color:#5ca9ff}</style></head><body><div>
<p>جارٍ التحويل إلى <b>%(name)s</b>…</p>
<p style="font-size:13px;color:#8b96a8">نقرات هذه الوجهة: <b data-hits="go">…</b></p>
<p><a href="%(url)s">اضغط لو لم يتحوّل تلقائيًا</a></p></div>
<script>
(function(){
  var U=%(urljson)s, NS=%(nsjson)s;
  function go(){ location.replace(U); }
  var done=false;
  var t=setTimeout(go, 1200);
  fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/go-%(id)s")
   .then(function(r){return r.json();}).then(function(j){
      if(j&&j.value!==undefined){var e=document.querySelector("[data-hits]");if(e)e.textContent=j.value;}
      done=true; clearTimeout(t); go();
   }).catch(function(){ if(!done) go(); });
})();
</script></body></html>"""

def main():
    with core.lock("clicks", 900) as got:
        if not got: print("  · مقفول — تخطٍ"); return
        r = revenue.build()
        os.makedirs("go", exist_ok=True)
        n = on = 0
        idx = []
        for p in r["providers"]:
            url = core.get(p["key"]) if p["key"].endswith("_REF") else ""
            if not url: continue
            n += 1
            core.write_if_changed("go/%s.html" % p["id"], GOTPL % {
                "name": core.esc(p["name"]), "url": core.esc(url),
                "urljson": __import__("json").dumps(url), "nsjson": __import__("json").dumps(core.ns()),
                "id": p["id"]})
            idx.append({"id": p["id"], "name": p["name"], "url": url})
        core.save("go/index.json", {"updated": time.strftime("%F %H:%M"), "count": len(idx), "items": idx})
        # صفحة الشبكات العامة
        rows = "".join("<tr><td><b>%s</b></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>"
                       "<td>%s</td><td><a target='_blank' rel='nofollow noopener' href='%s'>تسجيل ↗</a></td></tr>"
                       % (core.esc(p["name"]), core.esc(p["kind"]), core.esc(p["min_payout"]),
                          core.esc(p["methods"]), core.esc(p["schedule"]), core.esc(p["note"]), p["signup"])
                       for p in r["providers"])
        core.write_if_changed("networks.html", """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>مصادر الدخل — CineHub 3099</title>
<style>body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.8 system-ui,Tahoma}
.w{max-width:1000px;margin:0 auto;padding:18px}table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}th{color:#8b96a8;font-weight:500}
a{color:#5ca9ff}.k{color:#8b96a8;font-size:13px}</style></head><body><div class="w">
<h1>مصادر الدخل — %d</h1>
<p class="k">الأسعار مقروءة من صفحات المزودين بتاريخ 2026-10-18. التسجيل ≠ القبول.</p>
<table><tr><th>الجهة</th><th>النوع</th><th>حد السحب</th><th>الدفع</th><th>التكرار</th><th>ملاحظة</th><th></th></tr>
%s</table><p><a href="owner.html">لوحة المالك</a> · <a href="adult-networks.html">شبكات الكبار</a></p>
</div></body></html>""" % (len(r["providers"]), rows))
        print("  ✓ go/ (%d وجهة إحالة) + networks.html" % len(idx))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/clicks.py && ok "clicks.py" || bad "clicks.py"
python3 tools/clicks.py 2>&1 | tee -a "$LOG"

hd "4 · لوحة المالك الحقيقية"
cat > tools/dashboard.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""owner.html — تفصل المستلم عن المؤكد عن المعلق عن التقديري. لا جمع بينها."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, revenue

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>لوحة الإيرادات — CineHub 3099</title><meta name="robots" content="noindex">
<style>
body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:1000px;margin:0 auto;padding:18px}
h1{font-size:21px}h2{font-size:16px;color:#9fb0c6;margin-top:26px;font-weight:600}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:14px 0}
.b{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:12px}
.b .v{font-size:24px;font-weight:700}.b .l{font-size:12px;color:#8b96a8}
.paid .v{color:#39d98a}.appr .v{color:#5ca9ff}.pend .v{color:#e8c76a}.est .v{color:#9aa6b6}
table{width:100%%;border-collapse:collapse;font-size:13px}
td,th{padding:7px;border-bottom:1px solid #1e2635;text-align:right}
th{color:#8b96a8;font-weight:500}a{color:#5ca9ff}
.tag{padding:2px 8px;border-radius:20px;font-size:11.5px;border:1px solid}
.t-active{color:#39d98a;border-color:#1d5c3c;background:#0d2418}
.t-pending{color:#e8c76a;border-color:#5c4a12;background:#241d08}
.t-unregistered{color:#8b96a8;border-color:#2a3341}
.t-suspended,.t-blocked{color:#ff7b7b;border-color:#5c1d1d;background:#240d0d}
.k{color:#8b96a8;font-size:12.5px}code{background:#0b0f17;padding:2px 6px;border-radius:5px;font-size:12px}
.bar{height:8px;background:#1a2230;border-radius:6px;overflow:hidden;margin:8px 0}
.bar i{display:block;height:100%%;background:linear-gradient(90deg,#2f6df6,#39d98a)}
.warn{background:#1b1508;border:1px solid #3a2c08;color:#e8c76a;padding:10px;border-radius:10px;font-size:13px}
</style></head><body><div class="w">
<h1>📊 لوحة الإيرادات</h1>
<p class="k">آخر تحديث: %(upd)s · المصدر: دفتر مالي + سجل مزودين · <b>لا جمع بين التقديري والمستلم</b></p>

<div class="grid">
<div class="b paid"><div class="l">مستلم فعليًا (paid)</div><div class="v">$%(paid).2f</div></div>
<div class="b appr"><div class="l">مؤكد (approved)</div><div class="v">$%(appr).2f</div></div>
<div class="b pend"><div class="l">معلق (pending)</div><div class="v">$%(pend).2f</div></div>
<div class="b est"><div class="l">تقديري (غير مؤكد)</div><div class="v">$%(est).2f</div></div>
</div>

<h2>التقدّم نحو 100$ (من المستلم فقط)</h2>
<div class="bar"><i style="width:%(pct).1f%%"></i></div>
<p class="k">$%(paid).2f / $100 · الفجوة: <b>$%(gap).2f</b></p>

<h2>الزيارات والنقرات الحقيقية</h2>
<div class="grid">
<div class="b"><div class="l">زيارات اليوم (سيرفر)</div><div class="v" data-hits="dv">…</div></div>
<div class="b"><div class="l">زوار فريدون اليوم</div><div class="v" data-hits="uvtoday">…</div></div>
<div class="b"><div class="l">إجمالي المطالبات</div><div class="v" data-hits="claims">…</div></div>
<div class="b"><div class="l">نقرات الإحالة المسجلة</div><div class="v">%(clicks)d</div></div>
</div>

<h2>المزودون</h2>
<table><tr><th>الجهة</th><th>النوع</th><th>المفتاح</th><th>بيانات الاعتماد</th><th>الحالة</th>
<th>نقرات</th><th>معلق</th><th>مؤكد</th><th>مستلم</th><th>آخر مزامنة / خطأ</th></tr>
%(rows)s</table>

<h2>المكافآت</h2>
<p>صندوق المكافآت = 50%% من المؤكد = <b>$%(pool).4f</b> · الحالة: <b>%(fstat)s</b></p>
<p class="k">%(honest)s</p>

<h2>الخطوات التالية للوصول إلى 100$</h2>
%(next)s

<div class="warn"><b>قاعدة الحساب:</b> %(rule)s<br>
<b>تحذير:</b> لا تعتبر رابط التسجيل دليل قبول. الحالة «مفعّل» تعني وجود المفتاح فقط —
وليست دليل أرباح. الأرباح تُدخل يدويًا أو تُزامن من API.</div>

<p class="k"><a href="./">الرئيسية</a> · <a href="networks.html">المزودون</a> ·
<a href="rewards.html">المكافآت</a> · <a href="adult-networks.html">شبكات الكبار</a></p>
</div><script src="hits.js" defer></script></body></html>"""

NEXT = [
 "سجّل في <b>Adsterra</b> (حد $5، قبول 10 دقائق) → الصق ADSTERRA_ZONE في keys.env → شغّل MONEY.sh.",
 "سجّل في <b>ExoClick</b> → الصق EXOCLICK_ZONE. هذا أعلى RPM إباحي.",
 "سجّل في <b>Stripchat (StripCash)</b> واختر PPL ($1.50/تسجيل) → الصق STRIPCHAT_REF. أسرع طريق لـ100$.",
 "انشر من <b>promote-adult.html</b> في r/nsfw و r/porn و r/hentai — ترافيك مجاني ومتحوّل.",
 "أنشئ توكن API في ExoClick → الصق EXOCLICK_API_TOKEN → المزامنة تصير تلقائية.",
 "بعد أول عائد: <code>python3 tools/revenue.py add exoclick 5.20 approved --note \"تقرير\"</code>",
]

def main():
    r = revenue.apply_ledger()
    t = r["totals"]
    try: pool = core.load("data/rewards.json", {}).get("funding", {})
    except Exception: pool = {}
    rows = ""
    for p in r["providers"]:
        cred = "✓ مفتاح" if p["credential"] else '<span class="k">لا شيء</span>'
        err = core.esc(p.get("last_error") or "")[:40]
        rows += ("<tr><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td>"
                 "<td><span class='tag t-%s'>%s</span></td><td>%d</td><td>$%.2f</td><td>$%.2f</td><td>$%.2f</td>"
                 "<td class='k'>%s %s</td></tr>"
                 % (core.esc(p["name"]), core.esc(p["kind"]), core.esc(p["key"]), cred,
                    p["status"], p["status"], p["clicks"], p["pending"], p["approved"], p["paid"],
                    core.esc(p.get("last_sync") or "—"), err))
    core.write_if_changed("owner.html", TPL % {
        "upd": r["updated"], "paid": t["paid"], "appr": t["approved"], "pend": t["pending"],
        "est": t["estimated"], "gap": r["gap_usd"],
        "pct": min(100.0, t["paid"]), "clicks": t["clicks"], "rows": rows,
        "pool": pool.get("pool_usd", 0.0), "fstat": pool.get("status", "—"),
        "honest": core.esc((core.load("data/rewards.json", {}) or {}).get("honest", "")),
        "rule": core.esc(r["rule"]),
        "next": "".join("<li>%s</li>" % x for x in NEXT)})
    print("  ✓ owner.html · مستلم=$%.2f فجوة=$%.2f" % (t["paid"], r["gap_usd"]))

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/dashboard.py && ok "dashboard.py" || bad "dashboard.py"
python3 tools/dashboard.py 2>&1 | tee -a "$LOG"

hd "5 · فاحص شامل + قالب المفاتيح"
cat > tools/verify.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص: صحة Python/JSON/HTML · تسرّب الأسرار · سلامة الصفحات الحرجة."""
import json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def main():
    with core.lock("verify", 600) as got:
        if not got: print("  · مقفول"); return
        f, err = [], []
        for p in sorted(os.listdir("tools")):
            if not p.endswith(".py"): continue
            r = subprocess.run([sys.executable, "-m", "py_compile", "tools/" + p],
                               capture_output=True)
            (f if r.returncode else err).append("tools/" + p)
        print("  Python: %d سليم · %d فاشل" % (len(err), len(f)))
        for x in f: print("    ✗", x)
        bad = 0
        for d in (".", "data", "go"):
            if not os.path.isdir(d): continue
            for p in os.listdir(d):
                if not p.endswith(".json"): continue
                fp = os.path.join(d, p)
                try: json.load(open(fp, encoding="utf-8"))
                except Exception as e: print("    ✗ JSON:", fp, str(e)[:50]); bad += 1
        print("  JSON تالف: %d" % bad)
        E = core.env()
        leaks = []
        for d in (".", "go"):
            if not os.path.isdir(d): continue
            for p in os.listdir(d):
                if not p.endswith((".html", ".js")): continue
                s = open(os.path.join(d, p), encoding="utf-8", errors="ignore").read()
                for k, v in E.items():
                    if not v or len(v) < 6: continue
                    if k.startswith("GH_") or k in ("SITE_URL", "REF_CODE"): continue
                    if v in s: leaks.append("%s في %s" % (k, p))
        print("  قيم مفاتيح ظاهرة في ملفات الواجهة: %s" % (len(leaks) or "لا شيء"))
        for l in leaks[:6]: print("    ·", l)
        for p in ("owner.html", "rewards.html", "adult.html", "networks.html", "index.html"):
            if not os.path.exists(p): print("    ! مفقود:", p); continue
            s = open(p, encoding="utf-8").read()
            if "</body>" not in s: print("    ✗ HTML غير مغلق:", p)
        print("  الصفحات الحرجة: تم الفحص")

if __name__ == "__main__": main()
PYEOF
python3 -m py_compile tools/verify.py && ok "verify.py" || bad "verify.py"

cat > .env.example <<'ENVEOF'
# ═══════════════════════════════════════════════════════════════════
#  CineHub 3099 — قالب المفاتيح. انسخه: cp .env.example keys.env
#  القاعدة: المفتاح يُنشأ من لوحة المزود الرسمية. لا مفتاح يعمل بلا حساب.
#  لا تضع أي قيمة سرية في ملفات .html أو .js — تُقرأ عند البناء فقط.
# ═══════════════════════════════════════════════════════════════════

GH_USER=your_github_username
SITE_URL=https://your_github_username.github.io
REF_CODE=your_code

# ── إعلانات (Zone IDs) ────────────────────────────────────────────
# من: ExoClick → Sites & Zones → أنشئ Zone → انسخ الرقم
EXOCLICK_ZONE=
# من: Adsterra → Websites → Ad Units (ابدأ به: حد $5 وقبول 10 دقائق)
ADSTERRA_ZONE=
# من: JuicyAds → Ad Zones
JUICYADS_ZONE=
HILLTOPADS_ZONE=
TRAFFICSTARS_ZONE=
CLICKADU_ZONE=
EVADAV_ZONE=
# A-ADS: أنشئ Ad Unit واحصل على الرقم (يقبل NSFW، بلا JavaScript)
AADS_UNIT=
# بوب أندر
POPADS_SITE=
POPCASH_SITE=

# ── كود جاهز (اختياري) ────────────────────────────────────────────
# إن أعطاك المزود كودًا HTML ولا يوجد رابط iframe مباشر، الصقه هنا في سطر واحد:
ADSTERRA_EMBED=
HILLTOPADS_EMBED=
TRAFFICSTARS_EMBED=
CLICKADU_EMBED=
AADS_EMBED=
POPADS_EMBED=
POPCASH_EMBED=
EVADAV_EMBED=

# ── روابط الإحالة الحقيقية (revshare/CPA — الأسرع لـ100$) ─────────
# Stripchat: اختر PPL ($1.50/تسجيل مجاني) أو 20-25% مدى الحياة
STRIPCHAT_REF=
CRAKREVENUE_REF=
CHATURBATE_REF=
BONGA_REF=
JASMIN_REF=
STREAMATE_REF=
JERKMATE_REF=
FLIRT4FREE_REF=
IMLIVE_REF=
CAMSODA_REF=
XHLIVE_REF=
FANCENTRO_REF=
LOSPOLLOS_REF=
MOBIDEA_REF=
ZEYDOO_REF=

# ── مزامنة ExoClick (اختياري — يجعل التقارير تلقائية) ─────────────
EXOCLICK_API_TOKEN=
EXOCLICK_API_USER=
EXOCLICK_API_PASS=
ENVEOF
ok ".env.example"

grep -qxF 'keys.env' .gitignore 2>/dev/null || echo 'keys.env' >> .gitignore
grep -qxF '.env' .gitignore 2>/dev/null || echo '.env' >> .gitignore
for x in '.tmp/' 'logs/' '*.log' '*.bak' 'data/*.tmp'; do
  grep -qxF "$x" .gitignore 2>/dev/null || echo "$x" >> .gitignore
done
ok ".gitignore محدّث"

hd "6 · مهام الوكيل"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import os, re, shutil, subprocess, sys
p = "tools/tasks.py"
if not os.path.exists(p): print("  ! tools/tasks.py مفقود"); raise SystemExit
shutil.copy(p, ".tmp/tasks.py.bak")
s = open(p, encoding="utf-8").read()
NEW = [("إيرادات", "tools/revenue.py", "240*M"),
       ("لوحة إيرادات", "tools/dashboard.py", "240*M"),
       ("مكافآت", "tools/rewards.py", "720*M"),
       ("نقرات", "tools/clicks.py", "360*M"),
       ("تحقق شامل", "tools/verify.py", "180*M"),
       ("إصلاح صفحات", "tools/fix_pages.py", "720*M")]
lines = s.split("\n")
idx = [i for i, l in enumerate(lines) if re.search(r'\(\s*"[^"]*"\s*,\s*"tools/[^"]+\.py"', l)]
if not idx: print("  ! لم أجد قائمة المهام — أُضيفت لملف منفصل")
else:
    ins = ['    ("%s", "%s", %s),' % (n, f, iv) for n, f, iv in NEW if f not in s]
    lines[idx[-1] + 1: idx[-1] + 1] = ins
    open(p, "w", encoding="utf-8").write("\n".join(lines))
r = subprocess.run([sys.executable, "-m", "py_compile", p], capture_output=True)
if r.returncode:
    shutil.copy(".tmp/tasks.py.bak", p); print("  ✗ فشل — استُعيد الأصل:", r.stderr.decode()[:120])
else: print("  ✓ tasks.py: +%d مهمة" % len(NEW))
PY

hd "7 · تشغيل + نشر"
python3 tools/revenue.py build >/dev/null 2>&1
python3 tools/clicks.py 2>&1 | tee -a "$LOG"
python3 tools/dashboard.py 2>&1 | tee -a "$LOG"
python3 tools/verify.py 2>&1 | tee -a "$LOG"

U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { bad "لا تفويض gh"; exit 1; }
SITE="https://$U.github.io"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$U.github.io.git"
rm -f .git/index.lock 2>/dev/null
git add -A
git add -f .github/workflows/agent.yml 2>/dev/null || true
git -c user.email=a@c.local -c user.name=Agent commit -m "money: revenue ledger + real rewards + click tracking + owner dashboard" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
P=0
for i in 1 2 3; do
  rm -f .git/index.lock 2>/dev/null
  case "$i" in
    1) timeout 1800 git push origin main 2>"$TMPDIR/e" && P=1 ;;
    2) timeout 1800 git push --force --no-thin origin main 2>"$TMPDIR/e" && P=1 ;;
    3) timeout 1800 git push --force origin main 2>"$TMPDIR/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
done
[ "$P" = 0 ] && { bad "فشل الرفع"; tail -3 "$TMPDIR/e"; }
python3 -c "import gh;gh.enable_pages()" >/dev/null 2>&1

hd "8 · تحقق منشور"
for f in owner.html rewards.html earn.html networks.html adult-networks.html go/index.json; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done
if [ -d go ] && ls go/*.html >/dev/null 2>&1; then
  first="$(ls go/*.html | head -1 | xargs basename)"
  c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/go/$first")"
  [ "$c" = "200" ] && ok "/go/$first (تتبع النقر يعمل)" || wrn "/go/$first → $c"
else wrn "لا روابط إحالة بعد — go/ فارغ (طبيعي قبل التسجيل)"; fi

printf '\n%s╔══════════════════════════════════════╗\n' "$G"
printf '║  MONEY.sh انتهى                     ║\n'
printf '╚══════════════════════════════════════╝%s\n' "$N"
printf 'اللوحة : %s/owner.html\nالمكافآت: %s/rewards.html\nالمزودون: %s/networks.html\nالسجل : %s\n' "$SITE" "$SITE" "$SITE" "$LOG"
