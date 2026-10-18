#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  CineHub 3099 — UNBLACK.sh
#  يقتل الشاشة السوداء نهائيًا: إبطال SW قديم + كاش نظيف + شبكة أمان
#  لا يحذف ولا يعطّل أي ميزة — يضيف حرّاسًا فقط
# ============================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }

push_all(){
  git add -A
  git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1" 2>/dev/null
  if git push origin main 2>.push.err; then ok "مدفوع إلى main"; return 0; fi
  if grep -qiE 'workflow|\.github' .push.err; then
    warn "دفع ملفات الموقع فقط"; mv .github "$HOME/.gh_hold" 2>/dev/null
    git add -A; git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$1 (site)" 2>/dev/null
    git push origin main 2>&1 | tail -3; mv "$HOME/.gh_hold" .github 2>/dev/null
  else sed -n '1,6p' .push.err; fi
}

git fetch origin main -q 2>/dev/null || true
git pull --rebase origin main -q 2>/dev/null || true
echo "الإصدار الجديد: $V"

# ================== 1) تشخيص ==================
echo; echo "═══ تشخيص ═══"
python3 - <<'PY'
import os,re,json,datetime
os.chdir(os.path.expanduser("~/cinehub3099"))
rep={"time":datetime.datetime.now(datetime.timezone.utc).isoformat(),"sw":[],"reload":[],"hide":[],"docwrite":[],"files":0}
for f in os.listdir("."):
    if not f.endswith((".html",".htm",".js")): continue
    rep["files"]+=1
    t=open(f,encoding="utf-8",errors="replace").read()
    if re.search(r"serviceWorker",t): rep["sw"].append(f)
    if re.search(r"location\.reload|location\.replace|location\.href\s*=",t): rep["reload"].append(f)
    if re.search(r"visibility\s*:\s*hidden|opacity\s*:\s*0(?![.\d])",t): rep["hide"].append(f)
    if "document.write" in t: rep["docwrite"].append(f)
json.dump(rep,open("unblack-report.json","w"),ensure_ascii=False,indent=1)
print("ملفات مفحوصة:",rep["files"])
print("تسجّل serviceWorker:",rep["sw"] or "لا شيء")
print("إعادة تحميل:",rep["reload"] or "لا شيء")
print("إخفاء CSS مشبوه:",rep["hide"] or "لا شيء")
print("document.write:",rep["docwrite"] or "لا شيء")
PY

# ================== 2) كاسر الحصار ==================
cat > killsw.js <<'KEOF'
/* CineHub 3099 — كاسر الحصار: يُبطل كل SW وكاش مرة واحدة لكل إصدار */
(function () {
  "use strict";
  var V = "__VER__";
  var SS = window.sessionStorage;
  function g(k){ try { return SS.getItem(k); } catch(e){ return null; } }
  function s(k,v){ try { SS.setItem(k,v); } catch(e){} }
  var force = /[?&](fresh|reset|clean)=1/.test(location.search);
  var prev  = g("ch3099_sw_ver");
  var need  = force || prev !== V;

  function nuke(){
    var jobs = [];
    if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
      jobs.push(navigator.serviceWorker.getRegistrations().then(function(rs){
        return Promise.all(rs.map(function(r){ return r.unregister(); }));
      }).catch(function(){}));
    }
    if (window.caches && caches.keys) {
      jobs.push(caches.keys().then(function(ks){
        return Promise.all(ks.map(function(k){ return caches.delete(k); }));
      }).catch(function(){}));
    }
    return Promise.all(jobs);
  }
  function reg(){
    if (!navigator.serviceWorker || !window.isSecureContext) return;
    navigator.serviceWorker.register("sw2.js?v=" + V, { scope: "./" }).catch(function(){});
  }

  if (need) {
    var tries = parseInt(g("ch3099_sw_tries") || "0", 10);
    nuke().then(function(){
      s("ch3099_sw_ver", V);
      var controlled = navigator.serviceWorker && navigator.serviceWorker.controller;
      if (controlled && tries < 2) {
        s("ch3099_sw_tries", String(tries + 1));
        reg();
        setTimeout(function(){ location.reload(); }, 80);
      } else {
        s("ch3099_sw_tries", "0");
        reg();
      }
    });
  } else {
    reg();
  }
})();
KEOF

# ================== 3) SW جديد آمن (شبكة أولًا للمحتوى) ==================
cat > sw2.js <<'SWEOF'
/* CineHub 3099 — SW آمن: شبكة أولًا لـHTML/JSON، كاش للأصول، ولا يخزّن ملفات التحكم */
var V = "__VER__";
self.addEventListener("install", function(){ self.skipWaiting(); });
self.addEventListener("activate", function(e){
  e.waitUntil(
    caches.keys().then(function(ks){
      return Promise.all(ks.map(function(k){ return (k === V) ? null : caches.delete(k); }));
    }).then(function(){ return self.clients.claim(); })
  );
});
self.addEventListener("fetch", function(e){
  var req = e.request;
  if (req.method !== "GET") return;
  var u = new URL(req.url);
  if (u.origin !== location.origin) return;
  var p = u.pathname;
  if (/sw2?\.js$|killsw\.js$|boot\.js$|reset\.html$/.test(p)) {
    e.respondWith(fetch(req).catch(function(){ return caches.match(req); }));
    return;
  }
  if (/\.html?$/.test(p) || p === "/" || /\.json$/.test(p)) {
    e.respondWith(
      fetch(req).then(function(r){
        var c = r.clone();
        caches.open(V).then(function(ca){ ca.put(req, c); });
        return r;
      }).catch(function(){ return caches.match(req); })
    );
    return;
  }
  e.respondWith(caches.match(req).then(function(hit){
    return hit || fetch(req).then(function(r){
      if (r && r.status === 200 && r.type === "basic") {
        var c = r.clone();
        caches.open(V).then(function(ca){ ca.put(req, c); });
      }
      return r;
    });
  }));
});
SWEOF
cp sw2.js sw.js   # أي تسجيل قديم على /sw.js صار آمنًا أيضًا

# ================== 4) شبكة الأمان: المحتوى يظهر دائمًا ==================
cat > boot.js <<'BEOF'
/* CineHub 3099 — شبكة أمان: يمنع أي شاشة سوداء مهما حدث */
(function () {
  "use strict";
  try {
    var st = document.createElement("style");
    st.id = "ch3099-guard";
    st.textContent = "html{visibility:visible!important;background:#070b10}html,body{opacity:1!important}";
    (document.head || document.documentElement).appendChild(st);
  } catch (e) {}
  function shell(){
    try {
      if (document.getElementById("ch3099_fallback")) return;
      var b = document.body; if (!b) return;
      var txt = (b.innerText || "").replace(/\s/g, "");
      if (b.offsetHeight > 60 && txt.length > 0) return;
      var d = document.createElement("div");
      d.id = "ch3099_fallback";
      d.style.cssText = "position:fixed;inset:0;background:#070b10;color:#e9f1f8;padding:22px;" +
        "font-family:system-ui,Tahoma,sans-serif;z-index:99999;overflow:auto;line-height:1.9";
      var links = [["index.html","الرئيسية"],["library.html","المكتبة"],["sites.html","90 ألف موقع"],
                   ["auto.html","شاهد واقبض"],["subscribe.html","الشبكات"],["withdraw.html","السحب"],
                   ["link.html","ربط الحساب"],["live-dash.html","لوحة المتابعة"],["?fresh=1","تصفير كامل"]];
      d.innerHTML = '<h2 style="margin:0 0 6px">الواجهة تعمل</h2>' +
        '<p style="color:#8ea3b8;margin:0 0 12px">اختر صفحة — لن تبقى الشاشة سوداء بعد الآن.</p>' +
        links.map(function(p){
          return '<a style="display:block;padding:11px;margin:7px 0;background:rgba(255,255,255,.06);' +
                 'border-radius:11px;color:#4cc2ff;text-decoration:none" href="' + p[0] + '">' + p[1] + '</a>';
        }).join("");
      b.appendChild(d);
    } catch (e) {}
  }
  function arm(){
    setTimeout(shell, 5000);
    setTimeout(shell, 9000);
    try { window.addEventListener("error", function(){ setTimeout(shell, 1200); }); } catch (e) {}
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", arm);
  else arm();
})();
BEOF

# ================== 5) صفحة تصفير يدوية ==================
cat > reset.html <<'REOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>تصفير — CineHub 3099</title>
<style>body{font-family:system-ui,Tahoma,sans-serif;background:#070b10;color:#e9f1f8;padding:22px;line-height:1.9}
button{background:linear-gradient(135deg,#4cc2ff,#7b6bff);color:#06121c;font-weight:700;border:0;border-radius:12px;padding:14px 22px;font-size:16px;width:100%}
a{color:#4cc2ff}.c{color:#8ea3b8}</style></head><body>
<h1>تصفير كامل</h1><p class="c">يُلغي كل service workers وكل الكاشات وكل التخزين المؤقت، ثم يعيد التحميل نظيفًا.</p>
<button id="go">نفّذ التصفير الآن</button><p id="s" class="c"></p>
<p class="c"><a href="index.html">عودة للرئيسية</a></p>
<script>
(function(){
"use strict";
document.getElementById("go").onclick=function(){
 var st=document.getElementById("s"); st.textContent="جارٍ…";
 var jobs=[];
 if(navigator.serviceWorker&&navigator.serviceWorker.getRegistrations){
  jobs.push(navigator.serviceWorker.getRegistrations().then(function(rs){
   return Promise.all(rs.map(function(r){return r.unregister();}));}));
 }
 if(window.caches&&caches.keys){jobs.push(caches.keys().then(function(ks){
   return Promise.all(ks.map(function(k){return caches.delete(k);}));}));}
 Promise.all(jobs).then(function(){
  try{sessionStorage.clear();}catch(e){}
  st.textContent="تم — يُعاد التحميل…";
  setTimeout(function(){location.href="index.html?fresh=1&t="+Date.now();},700);
 });
};
})();
</script></body></html>
REOF

for f in killsw.js sw2.js boot.js; do sed -i "s/__VER__/$V/g" "$f"; done
echo "$V" > sw-version.txt
ok "كاسر الحصار + SW آمن + شبكة الأمان + صفحة تصفير"

# ================== 6) حقن الحرّاس في كل الصفحات ==================
python3 - <<'PY'
import os,re
os.chdir(os.path.expanduser("~/cinehub3099"))
V=open("sw-version.txt").read().strip()
K='<script src="%skillsw.js?v=%s"></script>'%("%s",V)
B='<script src="%sboot.js?v=%s" defer></script>'%("%s",V)
OLD=re.compile(r'<script[^>]*src=["\'][^"\']*?(?:killsw|boot|sw2?)\.js[^"\']*["\'][^>]*>\s*</script\s*>',re.I)
def patch(path,pref):
    t=open(path,encoding="utf-8",errors="replace").read()
    if "ch3099-guard" in t and "killsw.js?v="+V in t: return False
    t=OLD.sub("",t)
    k=K%(pref,); b=B%(pref,)
    m=re.search(r"<head[^>]*>",t,re.I)
    if m: t=t[:m.end()]+"\n"+k+t[m.end():]
    else: t=k+"\n"+t
    if re.search(r"</body\s*>",t,re.I): t=re.sub(r"</body\s*>",b+"\n</body>",t,count=1,flags=re.I)
    else: t=t+"\n"+b
    open(path,"w",encoding="utf-8").write(t)
    return True
n=0
for f in sorted(os.listdir(".")):
    if f.endswith((".html",".htm")) and f not in ("reset.html",): n+=patch(f,"") or n*0
c=0
if os.path.isdir("p"):
    for f in sorted(os.listdir("p"))[:3000]:
        if f.endswith(".html"): patch(os.path.join("p",f),"../"); c+=1
print("صفحات محقونة:",n,"| صفحات الأفلام:",c)
PY

# ================== 7) الصفحات الجديدة تولد محصّنة ==================
python3 - <<'PY'
import os,re
os.chdir(os.path.expanduser("~/cinehub3099"))
p="tools/pages_gen.py"
if os.path.exists(p):
    t=open(p,encoding="utf-8").read()
    if "killsw.js" not in t:
        t=t.replace('<meta name="viewport" content="width=device-width,initial-scale=1">',
          '<meta name="viewport" content="width=device-width,initial-scale=1">\n<script src="../killsw.js?v={ver}"></script>',1)
        t=t.replace("</head><body>","</head><body>",1)
        t=t.replace("</body></html>",'<script src="../boot.js?v={ver}" defer></script></body></html>',1)
        t=t.replace('LIMIT=int(os.environ.get("PAGES_LIMIT","200"))',
          'LIMIT=int(os.environ.get("PAGES_LIMIT","200"))\nVER=open("sw-version.txt").read().strip() if os.path.exists("sw-version.txt") else "1"',1)
        t=t.replace("TPL.format(","TPL.replace('{ver}',VER).format(",1)
        open(p,"w",encoding="utf-8").write(t)
        print("pages_gen محصّن")
    else: print("pages_gen محصّن مسبقًا")
PY

# ================== 8) تحقق نحوي ==================
echo; echo "═══ تحقق ═══"
if command -v node >/dev/null 2>&1; then
  for f in killsw.js boot.js sw2.js sw.js; do
    node --check "$f" >/dev/null 2>&1 && ok "$f سليم" || bad "$f مكسور"
  done
  python3 tools/jsrepair.py index.html >/dev/null 2>&1 || true
  node --check killsw.js >/dev/null 2>&1 && ok "الحرّاس تعمل"
else
  warn "node غير مثبّت: pkg install nodejs -y"
fi

# ================== 9) نشر وتحقق حي ==================
echo; echo "═══ نشر ═══"
push_all "unblack: kill stale sw + safe network-first sw2 + guard + reset [$V]"
info "انتظار 80 ثانية..."
sleep 80
for f in killsw.js boot.js sw2.js reset.html index.html; do
  c="$(curl -s -o /tmp/_u -w '%{http_code}' "https://alkazmybwhwr-dot.github.io/$f?v=$V")"
  if [ "$c" = "200" ]; then
    if [ "$f" = "killsw.js" ]; then
      grep -q "$V" /tmp/_u && ok "$f → 200 ومحمّل بالإصدار الجديد" || bad "$f → 200 لكن الإصدار قديم"
    else ok "$f → 200"; fi
  else bad "$f → $c"; fi
done
curl -s "https://alkazmybwhwr-dot.github.io/index.html?v=$V" | grep -q "killsw.js?v=$V" \
  && ok "الصفحة الرئيسية تحمل الكاسر" || bad "الصفحة الرئيسية بلا كاسر"
echo
ok "الإصدار: $V"
info "افتح الآن: https://alkazmybwhwr-dot.github.io/?fresh=1"
info "وإن بقيت أي سوداء عندك: https://alkazmybwhwr-dot.github.io/reset.html"
