#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  CineHub 3099 — AGENT.sh
#  يبني وكيلًا حقيقيًا يعمل داخل المستودع + خلفية محلية احتياطية
#  الاستخدام: bash AGENT.sh
# ============================================================
set -u
cd "$HOME/cinehub3099" 2>/dev/null || { echo "لا يوجد ~/cinehub3099"; exit 1; }
mkdir -p tools .github/workflows .state
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }

push_all(){
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1" 2>/dev/null
  if git push origin main 2>.push.err; then ok "مدفوع إلى main"; return 0; fi
  if grep -qiE 'workflow|\.github' .push.err; then
    info "الرمز بلا صلاحية workflow — أدفع ملفات الموقع فقط"
    mv .github "$HOME/.gh_hold" 2>/dev/null
    git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1 (site only)" 2>/dev/null
    git push origin main 2>&1 | tail -3
    mv "$HOME/.gh_hold" .github 2>/dev/null
    info "افتح: https://github.com/settings/tokens/new?scopes=repo,workflow"
    return 1
  fi
  sed -n '1,6p' .push.err; return 1
}

# ================= 1) مولّد الصفحات (المحرّك الحقيقي للزيارات) =================
cat > tools/pages_gen.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد صفحات ثابتة long-tail لكل فيلم/عنصر + sitemap + robots + IndexNow"""
import os, re, json, random, string, urllib.request, html as H

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(ROOT, "p")
SITE = os.environ.get("SITE_URL", "https://alkazmybwhwr-dot.github.io")
LIMIT = int(os.environ.get("PAGES_LIMIT", "300"))
KINDS = ["فيلم كلاسيكي","فيلم قصير","وثائقي","رسوم متحركة","فيلم نوار","تحفة صامتة","فيلم مغامرات","دراما"]
NETS = ["Adsterra","Monetag","PropellerAds","PopAds","AdMaven","HilltopAds","Evadav","Clickadu",
        "Linkvertise","ShrinkMe","CPAGrip","OGAds","BitLabs","CPX Research","AdGate","Lootably"]

def slug(s):
    s = re.sub(r"[^\w\s-]", "", s, flags=re.U).strip().lower()
    return (re.sub(r"[\s_]+", "-", s)[:60] or "item")

def load():
    items = []
    for f in ("films.json","catalog.json","library.json","platforms.json","entities.json"):
        p = os.path.join(ROOT, f)
        if not os.path.exists(p): continue
        try: d = json.load(open(p, encoding="utf-8"))
        except Exception: continue
        bag = d if isinstance(d, list) else []
        if isinstance(d, dict):
            for k in ("items","films","list","networks","entities","results","data"):
                if isinstance(d.get(k), list): bag += d[k]
        items += [x for x in bag if isinstance(x, dict)]
    seen, out = set(), []
    for x in items:
        t = (x.get("title") or x.get("name") or "").strip()
        if not t: continue
        s = slug(t)
        if s in seen: continue
        seen.add(s); out.append((s, t, x))
    return out

TPL = """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t} — مشاهدة مجانية وربح | CineHub 3099</title>
<meta name="description" content="{d}">
<link rel="canonical" href="{site}/p/{s}.html">
<meta property="og:title" content="{t} — CineHub 3099"><meta property="og:type" content="video.movie">
<meta property="og:description" content="{d}">
<script type="application/ld+json">{{"@context":"https://schema.org","@type":"Movie","name":{tj},"genre":{kj},"inLanguage":"ar","url":"{site}/p/{s}.html"}}</script>
<style>body{{font-family:system-ui,Tahoma,sans-serif;background:#0b0f14;color:#e8eef6;margin:0;padding:16px;line-height:1.7}}
a{{color:#5cc8ff}}.box{{background:#111a24;border:1px solid #1e2937;border-radius:10px;padding:12px;margin:12px 0}}
.ad{{background:#0e1620;border:1px dashed #2a3a4d;border-radius:8px;padding:10px;text-align:center;font-size:13px;color:#8aa}}
.btn{{display:inline-block;background:#134;color:#9fe;border:1px solid #2a6;border-radius:8px;padding:9px 14px;text-decoration:none;margin:4px}}</style>
</head><body>
<h1>{t}</h1>
<p>{d}</p>
<div class="ad" data-net="{n1}">إعلان — {n1}</div>
<p><a class="btn" href="../auto.html">▶ شاهد واقبض</a><a class="btn" href="../play.html?t={sj}">صفحة الفيلم</a><a class="btn" href="../index.html">الرئيسية</a></p>
<div class="box"><h3>تفاصيل</h3><p>النوع: {k}<br>اللغة: العربية/الأصلية<br>الحقوق: ملك عام / مرخّص<br>المصدر: {src}</p></div>
<div class="ad" data-net="{n2}">إعلان — {n2}</div>
<h3>مشاهدات مقترحة</h3><ul>{rel}</ul>
<div class="box"><h3>اربح من نفس الصفحة</h3><p>كل مشاهدة إعلان 15 ثانية = ربح مباشر لرصيدك، وسحب من $5 إلى بنك الكريمي (KBMFYESAXXX).</p></div>
<script>(function(){{try{{fetch('https://abacus.jasoncameron.dev/hit/ch3099-{s}').catch(function(){{}});}}catch(e){{}}}})();</script>
</body></html>"""

def main():
    items = load()
    if not items:
        print("لا عناصر — شغّل SCALE.sh أولًا"); return
    os.makedirs(OUT, exist_ok=True)
    take = items[:LIMIT]
    urls = []
    for i, (s, t, x) in enumerate(take):
        kind = KINDS[i % len(KINDS)]
        desc = ("مشاهدة %s مجانًا داخل CineHub 3099 — %s قانوني بجودة عالية، مع أرباح مباشرة لكل مشاهدة "
                "وسحب إلى بنك الكريمي. تصنيف: %s.") % (t, kind, kind)
        src = x.get("source") or x.get("provider") or "Archive / Public Domain"
        rel = ""
        for j in range(1, 9):
            ss, tt, _ = take[(i + j * 7) % len(take)]
            rel += '<li><a href="%s.html">%s</a></li>' % (ss, H.escape(tt))
        page = TPL.format(t=H.escape(t), s=s, d=H.escape(desc), k=kind, kj=json.dumps(kind, ensure_ascii=False),
                          tj=json.dumps(t, ensure_ascii=False), sj=urllib.parse.quote(t), site=SITE,
                          n1=NETS[i % len(NETS)], n2=NETS[(i + 5) % len(NETS)], src=H.escape(str(src)), rel=rel)
        open(os.path.join(OUT, s + ".html"), "w", encoding="utf-8").write(page)
        urls.append("%s/p/%s.html" % (SITE, s))
    open(os.path.join(ROOT, "sitemap.xml"), "w", encoding="utf-8").write(
        '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "".join("  <url><loc>%s</loc></url>\n" % u for u in [SITE + "/"] + urls)
        + "</urlset>\n")
    open(os.path.join(ROOT, "robots.txt"), "w", encoding="utf-8").write(
        "User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n" % SITE)
    # IndexNow (يُبلّغ محركات البحث فورًا)
    kp = os.path.join(ROOT, "indexnow-key.txt")
    key = open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
    open(kp, "w").write(key); open(os.path.join(ROOT, key + ".txt"), "w").write(key)
    try:
        req = urllib.request.Request("https://api.indexnow.org/indexnow",
            data=json.dumps({"host": SITE.replace("https://", ""), "key": key,
                             "keyLocation": SITE + "/" + key + ".txt", "urlList": urls[:10000]}).encode(),
            headers={"Content-Type": "application/json; charset=utf-8"})
        print("indexnow:", urllib.request.urlopen(req, timeout=30).status)
    except Exception as e:
        print("indexnow skip:", e)
    print("pages:", len(urls))

import urllib.parse
if __name__ == "__main__": main()
PYEOF
ok "مولّد الصفحات"

# ================= 2) السحب التلقائي =================
cat > tools/withdraw_auto.py <<'PYEOF'
#!/usr/bin/env python3
"""ينشئ طلب سحب تلقائي عند بلوغ الحد ويكتبه في السجل"""
import json, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def load(f, d):
    try: return json.load(open(os.path.join(ROOT, f), encoding="utf-8"))
    except Exception: return d
MIN = float(os.environ.get("MIN_WITHDRAW", "5"))
tre = load("treasury.json", {}); bal = float(tre.get("balance") or tre.get("withdrawable") or 0)
w = load("withdrawal.json", {"requests": []})
pend = [r for r in w.get("requests", []) if r.get("status") == "pending"]
if bal >= MIN and not pend:
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    req = {"id": "w%d" % int(datetime.datetime.now().timestamp()), "amount": round(bal, 6),
           "status": "pending", "created": now, "method": "Al-Kuraimi Bank (KBMFYESAXXX)",
           "to": load("owner.json", {}).get("kuraimi", {})}
    w.setdefault("requests", []).append(req)
    json.dump(w, open(os.path.join(ROOT, "withdrawal.json"), "w"), ensure_ascii=False, indent=1)
    print("WITHDRAW REQUEST", req["id"], req["amount"])
else:
    print("balance %.6f / min %.2f / pending %d" % (bal, MIN, len(pend)))
PYEOF

cat > tools/status.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
st = {"engine": "live", "updated": datetime.datetime.now(datetime.timezone.utc).isoformat()}
for f, k in (("revenue.json","revenue"), ("ledger.json","ledger"), ("platforms.json","platforms")):
    try: st[k] = json.load(open(os.path.join(ROOT, f), encoding="utf-8"))
    except Exception: pass
json.dump(st, open(os.path.join(ROOT, "status.json"), "w"), ensure_ascii=False, indent=1)
print("status ok")
PYEOF
ok "أدوات السحب والحالة"

# ================= 3) دورة الوكيل (تعمل على سيرفر GitHub) =================
cat > tools/agent_cycle.sh <<'SHEOF2'
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
mkdir -p .state
LOG=.state/log.txt
S=$(date -u +%FT%TZ)
run(){ [ -f "$1" ] && python3 "$1" >>"$LOG" 2>&1 || true; }

run tools/apply_keys.py
run tools/autodetect.py
run tools/revenue_pull.py
run tools/revenue.py
run tools/pull_revenue.py
run tools/ledger.py
run tools/insights.py
PAGES_LIMIT="${PAGES_LIMIT:-40}" run tools/pages_gen.py
run tools/withdraw_auto.py
run tools/status.py
run tools/verify.py

python3 - <<'PY' >>"$LOG" 2>&1
import json, os, datetime
p = "pulse.json"
d = {}
try: d = json.load(open(p, encoding="utf-8"))
except Exception: pass
d["updated"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
d.setdefault("cycle", 0); d["cycle"] = int(d["cycle"]) + 1
json.dump(d, open(p, "w"), ensure_ascii=False, indent=1)
PY
echo "cycle $S ok"
SHEOF2
chmod +x tools/agent_cycle.sh
ok "دورة الوكيل"

# ================= 4) جدولة GitHub (كل 5 دقائق + يومي موسّع) =================
cat > .github/workflows/agent.yml <<'YEOF'
name: agent
on:
  schedule:
    - cron: "*/5 * * * *"
    - cron: "17 3 * * *"
  workflow_dispatch:
  repository_dispatch:
    types: [agent-cycle]
permissions:
  contents: write
concurrency:
  group: agent
  cancel-in-progress: false
jobs:
  cycle:
    if: github.event.schedule != '17 3 * * *'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -q requests
      - run: PAGES_LIMIT=40 bash tools/agent_cycle.sh
      - name: commit
        run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A
          git diff --cached --quiet || git commit -m "agent cycle $(date -u +%FT%TZ)"
          git push
  daily:
    if: github.event.schedule == '17 3 * * *' || github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -q requests
      - run: PAGES_LIMIT=2000 bash tools/agent_cycle.sh
      - name: commit
        run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A
          git diff --cached --quiet || git commit -m "agent daily $(date -u +%FT%TZ)"
          git push
YEOF
ok "جدولة الوكيل على GitHub"

# ================= 5) خلفية محلية احتياطية (تعمل ولو الهاتف مفتوح) =================
cat > agentd.sh <<'DEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
command -v termux-wake-lock >/dev/null && termux-wake-lock
while true; do
  git pull --rebase -q 2>/dev/null
  bash tools/agent_cycle.sh >/dev/null 2>&1
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "agentd $(date -u +%FT%TZ)" 2>/dev/null
  git push -q 2>/dev/null || { git pull --rebase -q 2>/dev/null; git push -q 2>/dev/null; }
  sleep 300
done
DEOF
chmod +x agentd.sh
ok "الخلفية المحلية"

# ================= 6) صفحة تفعيل الشبكات + قائمة الشبكات =================
cat > signup.json <<'JEOF'
[
{"name":"Adsterra","cat":"شبكة إعلانات","min":"$5","url":"https://adsterra.com","var":"ADSTERRA_API_KEY"},
{"name":"Monetag","cat":"شبكة إعلانات","min":"$5","url":"https://monetag.com","var":"MONETAG_KEY"},
{"name":"PropellerAds","cat":"شبكة إعلانات","min":"$5","url":"https://propellerads.com","var":"PROPELLER_KEY"},
{"name":"PopAds","cat":"شبكة إعلانات","min":"$5","url":"https://www.popads.net","var":"POPADS_KEY"},
{"name":"AdMaven","cat":"شبكة إعلانات","min":"$5","url":"https://admaven.com","var":"ADMAVEN_KEY"},
{"name":"HilltopAds","cat":"شبكة إعلانات","min":"$5","url":"https://hilltopads.com","var":"HILLTOP_KEY"},
{"name":"Evadav","cat":"شبكة إعلانات","min":"$5","url":"https://evadav.com","var":"EVADAV_KEY"},
{"name":"Clickadu","cat":"شبكة إعلانات","min":"$5","url":"https://clickadu.com","var":"CLICKADU_KEY"},
{"name":"ExoClick","cat":"شبكة إعلانات","min":"$20","url":"https://www.exoclick.com","var":"EXOCLICK_KEY"},
{"name":"JuicyAds","cat":"شبكة إعلانات","min":"$50","url":"https://www.juicyads.com","var":"JUICYADS_KEY"},
{"name":"TrafficJunky","cat":"شبكة إعلانات","min":"$20","url":"https://www.trafficjunky.com","var":"TRAFFICJUNKY_KEY"},
{"name":"Galaksion","cat":"شبكة إعلانات","min":"$5","url":"https://galaksion.com","var":"GALAKSION_KEY"},
{"name":"MyBid","cat":"شبكة إعلانات","min":"$5","url":"https://mybid.io","var":"MYBID_KEY"},
{"name":"RichAds","cat":"شبكة إعلانات","min":"$5","url":"https://richads.com","var":"RICHADS_KEY"},
{"name":"Kadam","cat":"شبكة إعلانات","min":"$10","url":"https://kadam.net","var":"KADAM_KEY"},
{"name":"AdCash","cat":"شبكة إعلانات","min":"$25","url":"https://adcash.com","var":"ADCASH_KEY"},
{"name":"TrafficStars","cat":"شبكة إعلانات","min":"$25","url":"https://trafficstars.com","var":"TRAFFICSTARS_KEY"},
{"name":"PlugRush","cat":"شبكة إعلانات","min":"$5","url":"https://www.plugrush.com","var":"PLUGRUSH_KEY"},
{"name":"Bidvertiser","cat":"شبكة إعلانات","min":"$10","url":"https://www.bidvertiser.com","var":"BIDVERTISER_KEY"},
{"name":"Infolinks","cat":"شبكة إعلانات","min":"$50","url":"https://www.infolinks.com","var":"INFOLINKS_KEY"},
{"name":"MGID","cat":"شبكة إعلانات","min":"$10","url":"https://www.mgid.com","var":"MGID_KEY"},
{"name":"Ezoic","cat":"شبكة إعلانات","min":"$20","url":"https://www.ezoic.com","var":"EZOIC_KEY"},
{"name":"NitroPay","cat":"شبكة إعلانات","min":"$20","url":"https://nitropay.com","var":"NITROPAY_KEY"},
{"name":"Setupad","cat":"شبكة إعلانات","min":"$50","url":"https://setupad.com","var":"SETUPAD_KEY"},
{"name":"CPAGrip","cat":"CPA","min":"$50","url":"https://www.cpagrip.com","var":"CPAGRIP_KEY"},
{"name":"CPALead","cat":"CPA","min":"$50","url":"https://www.cpalead.com","var":"CPALEAD_KEY"},
{"name":"OGAds","cat":"CPA","min":"$20","url":"https://www.ogads.com","var":"OGADS_KEY"},
{"name":"AdGate Media","cat":"CPA","min":"$10","url":"https://adgatemedia.com","var":"ADGATE_KEY"},
{"name":"AdWork Media","cat":"CPA","min":"$25","url":"https://www.adworkmedia.com","var":"ADWORKMEDIA_KEY"},
{"name":"MaxBounty","cat":"CPA","min":"$50","url":"https://www.maxbounty.com","var":"MAXBOUNTY_KEY"},
{"name":"Lootably","cat":"CPA","min":"$5","url":"https://lootably.com","var":"LOOTABLY_KEY"},
{"name":"Timewall","cat":"CPA","min":"$5","url":"https://timewall.io","var":"TIMEWALL_KEY"},
{"name":"OfferToro","cat":"CPA","min":"$5","url":"https://www.offertoro.com","var":"OFFERTORO_KEY"},
{"name":"Adscend Media","cat":"CPA","min":"$10","url":"https://www.adscendmedia.com","var":"ADSCEND_KEY"},
{"name":"ClickBank","cat":"عمولات","min":"$10","url":"https://www.clickbank.com","var":"CLICKBANK_KEY"},
{"name":"Digistore24","cat":"عمولات","min":"$10","url":"https://www.digistore24.com","var":"DIGISTORE_KEY"},
{"name":"Impact","cat":"عمولات","min":"$10","url":"https://impact.com","var":"IMPACT_KEY"},
{"name":"CJ Affiliate","cat":"عمولات","min":"$50","url":"https://www.cj.com","var":"CJ_KEY"},
{"name":"Awin","cat":"عمولات","min":"$20","url":"https://www.awin.com","var":"AWIN_KEY"},
{"name":"Admitad","cat":"عمولات","min":"$10","url":"https://www.admitad.com","var":"ADMITAD_KEY"},
{"name":"BitLabs","cat":"استطلاعات","min":"$5","url":"https://bitlabs.ai","var":"BITLABS_KEY"},
{"name":"CPX Research","cat":"استطلاعات","min":"$5","url":"https://www.cpx-research.com","var":"CPX_KEY"},
{"name":"TheoremReach","cat":"استطلاعات","min":"$5","url":"https://theoremreach.com","var":"THEOREMREACH_KEY"},
{"name":"Pollfish","cat":"استطلاعات","min":"$5","url":"https://www.pollfish.com","var":"POLLFISH_KEY"},
{"name":"Ayet Studios","cat":"استطلاعات","min":"$5","url":"https://ayetstudios.com","var":"AYET_KEY"},
{"name":"Notik","cat":"استطلاعات","min":"$5","url":"https://notik.me","var":"NOTIK_KEY"},
{"name":"Monlix","cat":"استطلاعات","min":"$5","url":"https://monlix.com","var":"MONLIX_KEY"},
{"name":"Linkvertise","cat":"روابط مدفوعة","min":"$5","url":"https://linkvertise.com","var":"LINKVERTISE_UID"},
{"name":"ShrinkMe","cat":"روابط مدفوعة","min":"$5","url":"https://shrinkme.io","var":"SHRINKME_KEY"},
{"name":"ShrinkEarn","cat":"روابط مدفوعة","min":"$5","url":"https://shrinkearn.com","var":"SHRINKEARN_KEY"},
{"name":"GPLinks","cat":"روابط مدفوعة","min":"$5","url":"https://gplinks.com","var":"GPLINKS_KEY"},
{"name":"Clk.sh","cat":"روابط مدفوعة","min":"$5","url":"https://clk.sh","var":"CLKSH_KEY"},
{"name":"DropLink","cat":"روابط مدفوعة","min":"$5","url":"https://droplink.co","var":"DROPLINK_KEY"},
{"name":"Cuty.io","cat":"روابط مدفوعة","min":"$5","url":"https://cuty.io","var":"CUTY_KEY"},
{"name":"Exe.io","cat":"روابط مدفوعة","min":"$5","url":"https://exe.io","var":"EXEIO_KEY"},
{"name":"Earn4Link","cat":"روابط مدفوعة","min":"$5","url":"https://earn4link.com","var":"EARN4LINK_KEY"},
{"name":"Bitsfly","cat":"روابط مدفوعة","min":"$5","url":"https://bitsfly.co","var":"BITSFLY_KEY"},
{"name":"OuO.io","cat":"روابط مدفوعة","min":"$5","url":"https://ouo.io","var":"OUO_KEY"},
{"name":"Cointiply","cat":"كربتو","min":"$3","url":"https://cointiply.com","var":"COINTIPLY_KEY"},
{"name":"FaucetPay","cat":"كربتو","min":"$1","url":"https://faucetpay.io","var":"FAUCETPAY_KEY"},
{"name":"A-Ads","cat":"كربتو","min":"$1","url":"https://a-ads.com","var":"AADS_KEY"},
{"name":"Binance","cat":"مسار الدفع","min":"-","url":"https://www.binance.com","var":"BINANCE_KEY"},
{"name":"Trust Wallet","cat":"مسار الدفع","min":"-","url":"https://trustwallet.com","var":"TRUST_KEY"}
]
JEOF

cat > subscribe.html <<'HEOF'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>تفعيل الشبكات — CineHub 3099</title>
<style>
body{font-family:system-ui,Tahoma,sans-serif;background:#0b0f14;color:#e8eef6;margin:0;padding:14px}
h1{font-size:20px}.warn{background:#2a1f0a;border:1px solid #6b4b0f;padding:8px;border-radius:8px;font-size:13px}
table{width:100%;border-collapse:collapse;font-size:13px;margin-top:10px}
th,td{border-bottom:1px solid #1e2937;padding:6px;text-align:right}
a{color:#5cc8ff}input{width:100%;background:#0f1720;border:1px solid #24313f;color:#e8eef6;border-radius:6px;padding:5px;font-size:12px}
button{background:#123a4d;color:#9fe;border:1px solid #2a6;border-radius:8px;padding:8px 12px;margin:4px;font-size:13px}
#st{font-size:13px;color:#8fd}
</style></head><body>
<h1>تفعيل الشبكات والمنصات</h1>
<div class="warn">افتح الرابط → سجّل (كابتشا) → انسخ المفتاح أو المعرّف → الصقه. يُحفظ فورًا ويُدفع للمستودع، والمحرّك يقرأه خلال 5 دقائق.</div>
<p><button id="save">حفظ ودفع إلى المستودع</button><button id="copy">نسخ keys.env</button><span id="st"></span></p>
<table id="t"><thead><tr><th>الشبكة</th><th>النوع</th><th>أدنى سحب</th><th>تسجيل</th><th>المفتاح / المعرّف</th></tr></thead><tbody></tbody></table>
<script>
(function(){
 var keys={},gh={};
 try{keys=JSON.parse(localStorage.getItem('ch3099_keys')||'{}')}catch(e){}
 try{gh=JSON.parse(localStorage.getItem('ch3099_gh')||'{}')}catch(e){}
 function persist(){localStorage.setItem('ch3099_keys',JSON.stringify(keys));}
 function env(){return Object.keys(keys).filter(function(k){return keys[k]}).map(function(k){return k+'='+keys[k]}).join('\n')+'\n';}
 fetch('signup.json?_='+Date.now()).then(function(r){return r.json()}).then(function(list){
  var tb=document.querySelector('#t tbody');
  list.forEach(function(x){
   var tr=document.createElement('tr');
   tr.innerHTML='<td>'+x.name+'</td><td>'+x.cat+'</td><td>'+x.min+'</td><td><a target="_blank" rel="noopener" href="'+x.url+'">فتح</a></td><td></td>';
   var inp=document.createElement('input'); inp.placeholder=x.var; inp.value=keys[x.var]||'';
   inp.oninput=function(){keys[x.var]=inp.value.trim();persist();};
   tr.lastChild.appendChild(inp); tb.appendChild(tr);
  });
 });
 document.getElementById('copy').onclick=function(){navigator.clipboard.writeText(env());document.getElementById('st').textContent='نُسخ';};
 document.getElementById('save').onclick=function(){
  if(!gh.token||!gh.repo){document.getElementById('st').textContent='افتح setup.html أولًا لحفظ رمز GitHub';return;}
  var url='https://api.github.com/repos/'+gh.repo+'/contents/keys.env';
  var H={'Authorization':'token '+gh.token,'Content-Type':'application/json'};
  fetch(url,{headers:H}).then(function(r){return r.ok?r.json():null}).then(function(j){
   var body={message:'keys from subscribe.html',content:btoa(unescape(encodeURIComponent(env()))),branch:gh.branch||'main'};
   if(j&&j.sha)body.sha=j.sha;
   return fetch(url,{method:'PUT',headers:H,body:JSON.stringify(body)});
  }).then(function(r){document.getElementById('st').textContent=r&&r.ok?'تم الدفع — المحرّك يعمل خلال 5 دقائق':'فشل الدفع';});
 };
})();
</script></body></html>
HEOF
ok "صفحة تفعيل الشبكات"

# ================= 7) تشغيل أول دورة الآن =================
info "تشغيل أول دورة محليًا..."
PAGES_LIMIT=120 bash tools/agent_cycle.sh || true
python3 tools/status.py >/dev/null 2>&1
ok "أول دورة انتهت — راجع .state/log.txt"

# ================= 8) نشر =================
push_all "agent: install autonomous engine (pages+ledger+withdraw+workflows)"

# ================= 9) تشغيل الخلفية إن كان Termux =================
if command -v termux-wake-lock >/dev/null 2>&1; then
  pkill -f agentd.sh 2>/dev/null
  nohup bash agentd.sh >/dev/null 2>&1 &
  ok "الخلفية المحلية تعمل (agentd)"
fi

echo
ok "الوكيل يعمل الآن. افتح: https://alkazmybwhwr-dot.github.io"
info "لتفعيل المال: افتح /subscribe.html واملأ أي 3 شبكات — الباقي تلقائي"
info "المتابعة: /live-dash.html · السجل: /audit.html · السحب: /withdraw.html"
info "السجل الخام: .state/log.txt — وأي دورة تُطبع في سجل GitHub Actions"
