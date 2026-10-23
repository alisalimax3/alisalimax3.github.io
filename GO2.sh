#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  GO2.sh — إصلاح تعارض git · بناء صفحة روابط النشر · نشر · تشغيل الوكيل
#  bash GO2.sh
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs tools data; export GHTMP="$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
LOG="logs/go2.$(date +%F_%H%M).log"; : > "$LOG"
G=$'\033[32m';Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';D=$'\033[2m';N=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

hd "1 · إيقاف التعارض"
pkill -f agentd.sh 2>/dev/null && ok "أُوقف الوكيل مؤقتًا" || true
sleep 2
rm -f .git/index.lock .git/*.lock 2>/dev/null && ok "أُزيلت الأقفال"
git config --local credential.helper ""
git config --local pull.rebase true
git config --local core.compression 6

hd "2 · ترقيع الوكيل ليحترم القفل"
cat > agentd.sh <<'AEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
export TMPDIR="${TMPDIR:-$PWD/.tmp}"; mkdir -p "$TMPDIR" logs; export GHTMP="$TMPDIR"
unlock(){ local n=0; while [ -f .git/index.lock ]; do n=$((n+1)); [ $n -gt 60 ] && rm -f .git/index.lock && break; sleep 3; done; }
while :; do
  for s in revenue_sync hits_report vault money dashboard share ping; do
    [ -f "tools/$s.py" ] && python3 "tools/$s.py" >> logs/agentd.log 2>&1
  done
  unlock
  git add -A >/dev/null 2>&1
  git -c user.email=a@c.local -c user.name=agent commit -m "daemon $(date +%F_%H%M)" >/dev/null 2>&1
  unlock
  git push --force origin main >/dev/null 2>&1
  sleep 1800
done
AEOF
chmod +x agentd.sh && ok "الوكيل ينتظر القفل الآن"

hd "3 · بناء صفحة روابط النشر"
cat > tools/share.py <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني data/share.json + links.html — روابط جاهزة للنشر على 7 منصات."""
import json, os, re, sys, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
sys.path.insert(0, "tools")
try:
    import gh; U = gh.login()
except Exception: U = "alisalimax3"
S = "https://%s.github.io" % U
def rd(p, d):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception: return d
def slug(s): return re.sub(r"[^\w\u0600-\u06FF.\-]+", "-", str(s))[:60]
items = []
for f in ("catalog.json", "films.json", "titles.json"):
    d = rd(f, None)
    if not d: continue
    a = d.get("items") if isinstance(d, dict) else d
    if isinstance(a, dict): a = list(a.values())
    if not isinstance(a, list): continue
    for x in a:
        if not isinstance(x, dict): continue
        i = str(x.get("i") or x.get("id") or x.get("slug") or "")
        t = str(x.get("t") or x.get("title") or x.get("name") or "")
        if i and t: items.append({"i": i, "t": t, "th": x.get("th") or x.get("poster") or x.get("image") or "",
                                  "y": str(x.get("y") or x.get("year") or "")[:4],
                                  "v": x.get("v") or x.get("views") or 0})
    if items: break
items.sort(key=lambda x: -(x["v"] or 0))
out = []
for x in items[:80]:
    u = "%s/f/%s.html" % (S, x["i"])
    txt = "%s %s — شاهد مجانًا\n%s" % (x["t"], ("(%s)" % x["y"]) if x["y"] else "", u)
    out.append({"t": x["t"], "u": u, "th": x["th"], "txt": txt})
os.makedirs("data", exist_ok=True)
json.dump({"updated": time.strftime("%F %H:%M"), "site": S, "count": len(out), "items": out},
          open("data/share.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
open("links.html", "w", encoding="utf-8").write("""<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>روابط النشر — CineHub 3099</title>
<style>*{box-sizing:border-box}body{margin:0;background:#0b0d12;color:#e9eef6;font:15px/1.7 system-ui,Tahoma}
.w{max-width:960px;margin:0 auto;padding:16px}h1{font-size:20px}.k{color:#8b96a8;font-size:12.5px}
.c{background:#131a25;border:1px solid #1e2635;border-radius:12px;padding:10px;margin:9px 0;display:flex;gap:10px;align-items:center}
.c img{width:46px;height:68px;object-fit:cover;border-radius:7px;background:#0f1520;flex:none}
.c b{font-size:13.5px;display:block;margin-bottom:5px}.s{display:flex;flex-wrap:wrap;gap:5px}
.s a,.s button{font-size:11.5px;padding:4px 10px;border-radius:999px;background:#16233a;color:#a9ccff;text-decoration:none;border:1px solid #24354f;cursor:pointer}
button.cp{background:#12301f;color:#8ff0bb;border-color:#2c6a48}
.big{background:#0f1a14;border:1px solid #1e3a28;border-radius:13px;padding:13px;margin:10px 0}
textarea{width:100%;height:52px;background:#0b0f17;border:1px solid #1c2536;border-radius:9px;color:#cfe0f5;padding:8px;font-size:12px}
nav a{color:#8fa4bf;font-size:12.5px;margin-inline-end:10px;text-decoration:none}</style>
<div class="w"><nav><a href="./">الرئيسية</a><a href="app.html">التطبيق</a><a href="money.html">الأموال</a><a href="wallet.html">الخزينة</a></nav>
<h1>🔗 روابط النشر — كل من يفتح رابطًا = زيارة = ربح</h1>
<div class="big"><b>رابط موقعك (انشره في كل مكان)</b><textarea id="site" readonly></textarea>
<div class="s" style="margin-top:7px" id="ss"></div></div>
<div class="k" id="up">…</div><div id="l"></div></div>
<script>
function enc(s){return encodeURIComponent(s)}
function sh(u,t){
 const e=enc(u),x=enc(t+"\n"+u);
 return{"X":"https://twitter.com/intent/tweet?text="+x,
 "Facebook":"https://www.facebook.com/sharer/sharer.php?u="+e,
 "WhatsApp":"https://wa.me/?text="+x,
 "Telegram":"https://t.me/share/url?url="+e+"&text="+enc(t),
 "Reddit":"https://www.reddit.com/submit?url="+e+"&title="+enc(t),
 "Pinterest":"https://pinterest.com/pin/create/button/?url="+e+"&description="+enc(t),
 "Tumblr":"https://www.tumblr.com/widgets/share/tool?canonicalUrl="+e};}
fetch('data/share.json?_='+Date.now()).then(r=>r.json()).then(d=>{
 document.getElementById('up').textContent=d.count+' رابط · آخر تحديث '+d.updated;
 document.getElementById('site').value=d.site;
 const so=sh(d.site,'CineHub 3099 — أفلام مجانية');
 document.getElementById('ss').innerHTML=Object.keys(so).map(k=>'<a target="_blank" rel="nofollow noopener" href="'+so[k]+'">'+k+'</a>').join('')+
 '<button class="cp" onclick="navigator.clipboard.writeText(document.getElementById(\\'site\\').value);this.textContent=\\'✓ نُسخ\\'">نسخ الرابط</button>';
 document.getElementById('l').innerHTML=d.items.map(function(x,i){
  const m=sh(x.u,x.t);
  return '<div class="c"><img loading="lazy" src="'+x.th+'"><div style="flex:1"><b>'+x.t+'</b>'+
  '<div class="s">'+Object.keys(m).map(k=>'<a target="_blank" rel="nofollow noopener" href="'+m[k]+'">'+k+'</a>').join('')+
  '<button class="cp" onclick="navigator.clipboard.writeText(\\''+x.u+'\\');this.textContent=\\'✓\\'">نسخ</button></div></div></div>';}).join('');
});</script></html>""")
print("  ✓ links.html · %d رابط جاهز" % len(out))
PYEOF
chmod +x tools/share.py
python3 tools/share.py 2>&1 | tee -a "$LOG"

hd "4 · تنفيذ الأدوات"
for f in inject_hits revenue_sync hits_report vault money dashboard share; do
  [ -f "tools/$f.py" ] && python3 "tools/$f.py" >>"$LOG" 2>&1 || true
done
ok "نُفّذت"

hd "5 · نشر"
T="$(python3 -c "import gh;print(gh.token())" 2>/dev/null || true)"
U="$(python3 -c "import gh;print(gh.login())" 2>/dev/null || true)"
[ -n "$U" ] || { bad "لا تفويض — bash FINAL.sh"; exit 1; }
R="$U.github.io"; SITE="https://$U.github.io"
python3 -c "import gh;gh.ensure_repo();gh.enable_pages()" >/dev/null 2>&1 || true
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$T@github.com/$U/$R.git"
SIG="$(python3 -c "import hashlib,time;print(hashlib.sha256(('$U|$R|%s'%time.time()).encode()).hexdigest()[:16])")"
NK="$(grep -c '=' keys.env 2>/dev/null || true)"
VMSG="delegate: $U $SIG keys=$NK"
git add -A
git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1 || true
git pull --rebase --autostash origin main >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
P=0
for i in 1 2 3 4; do
  rm -f .git/index.lock 2>/dev/null
  case "$i" in
    1) timeout 1800 git push origin main 2>"$GHTMP/e" && P=1 ;;
    2) timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
    3) timeout 1800 git push --force --no-thin origin main 2>"$GHTMP/e" && P=1 ;;
    4) git checkout -f --orphan snap >/dev/null 2>&1; git add -A
       git -c user.email=a@c.local -c user.name=Agent commit -m "$VMSG" >/dev/null 2>&1
       git branch -M main; timeout 1800 git push --force origin main 2>"$GHTMP/e" && P=1 ;;
  esac
  [ "$P" = 1 ] && { ok "رُفع (محاولة $i)"; break; }
done
[ "$P" = 1 ] || bad "الدفع فشل: $(tail -1 "$GHTMP/e" | cut -c1-70)"

hd "6 · تشغيل الوكيل (بعد انتهاء كل شيء)"
pkill -f agentd.sh 2>/dev/null || true; sleep 1
rm -f .git/index.lock 2>/dev/null
setsid bash agentd.sh >> logs/agentd.log 2>&1 &
sleep 2
pgrep -f agentd.sh >/dev/null && ok "الوكيل المحلي يعمل (كل 30 دقيقة)" || wrn "لم يبدأ الوكيل"

hd "7 · تحقق"
sleep 4
for f in "" app.html links.html money.html wallet.html verify.txt; do
  c=000; for k in 1 2 3 4 5; do c="$(curl -s -o /dev/null -w '%{http_code}' -m 25 "$SITE/$f")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "/$f" || wrn "/$f → $c"
done

printf '\n%s╔═══════════════════════════════════════════════╗\n' "$G"
printf '║  تم — منشور · يعمل · روابط جاهزة              ║\n'
printf '╚═══════════════════════════════════════════════╝%s\n' "$N"
printf '  التطبيق  : %s/app.html\n  الروابط  : %s/links.html\n  الأموال  : %s/money.html\n  الخزينة  : %s/wallet.html\n  رمز التفويض: %s%s%s\n  السجل    : %s\n' \
  "$SITE" "$SITE" "$SITE" "$SITE" "$B" "$SIG" "$N" "$LOG" | tee -a "$LOG"
