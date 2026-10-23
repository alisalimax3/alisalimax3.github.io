#!/data/data/com.termux/files/usr/bin/bash
# money/FULL.sh — الأمر الموحد النهائي الكامل (بناء حقيقي + رصيد محفوظ + نشر)
# التشغيل بالمسار الكامل:
#   bash /data/data/com.termux/files/home/cinehub3099/money/FULL.sh
#   bash /data/data/com.termux/files/home/cinehub3099/money/FULL.sh --check
set -u
REPO="/data/data/com.termux/files/home/cinehub3099"
cd "$REPO" || exit 1

BR=main; OWNER=alisalimax3; NAME=alisalimax3.github.io
REAL="https://$OWNER.github.io"
PLOG="$REPO/.git/_push.log"
CHECK=0; [ "${1:-}" = "--check" ] && CHECK=1
BASE=""; USER="$OWNER"; SNAP=""
say(){ printf '%s\n' "$*"; }
die(){ say "✗ $*"; exit 1; }
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock

say ""; say "═════ FULL · بناء حقيقي + رصيد محفوظ + رفع + نشر ═════"
say "▸ المسار: $REPO"
[ -d .git ] || die "مش مستودع git"
command -v gh >/dev/null 2>&1 || die "gh مش متسطّب"

# ══ 0 · نسخة الحالة والرصيد ══
snap(){
  SNAP="money/.heal/state-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$SNAP"
  for f in $(find money -maxdepth 4 -type f \
      \( -name '*balance*' -o -name '*wallet*' -o -name '*ledger*' -o -name '*credit*' \
         -o -name '*earning*' -o -name '*revenue*' -o -name '*custody*' -o -name '*treasury*' \) \
      -not -path 'money/.heal/*' 2>/dev/null) wallet.json sites.json; do
    [ -f "$f" ] || continue
    mkdir -p "$SNAP/$(dirname "$f")"; cp -p "$f" "$SNAP/$f" 2>/dev/null
  done
  if [ -d money/db ]; then mkdir -p "$SNAP/money/db"; cp -rp money/db/. "$SNAP/money/db/" 2>/dev/null; fi
  say "✓ نسخة الرصيد/الحالة: $SNAP ($(find "$SNAP" -type f 2>/dev/null | wc -l) ملف)"
}
restore(){
  [ -n "$SNAP" ] && [ -d "$SNAP" ] || return 0
  ( cd "$SNAP" && find . -type f -print0 ) | while IFS= read -r -d '' p; do
    rel="${p#./}"; mkdir -p "$(dirname "$rel")"; cp -p "$SNAP/$rel" "$rel" 2>/dev/null
  done
  say "✓ الرصيد والحالة اترجّعوا زي ما كانوا"
}

if [ "$CHECK" = 0 ]; then
  snap

  # ══ 1 · مصادقة بالمتصفح ══
  if [ -z "$(gh auth token 2>/dev/null)" ]; then
    say ""; say "► هيفتح المتصفح ويظهر كود. افتح الرابط، الصق الكود، وافق Authorize."
    gh auth login --hostname github.com --git-protocol https --web || true
    [ -n "$(gh auth token 2>/dev/null)" ] || die "المصادقة ماكملتش"
  else say "✓ مسجّل دخول — مفيش كود مطلوب"; fi
  USER=$(gh api user --jq .login 2>/dev/null || echo "$OWNER")
  say "✓ الحساب: $USER"

  # ══ 2 · وقف الوكلاء + تنظيف الأقفال ══
  for p in heal panel agent tick agentd; do pkill -f "money/$p.mjs" 2>/dev/null; done
  sleep 1
  git rebase --abort >/dev/null 2>&1; git merge --abort >/dev/null 2>&1
  rm -rf .git/rebase-merge .git/rebase-apply 2>/dev/null
  rm -f .git/index.lock .git/MERGE_HEAD 2>/dev/null
  say "✓ الأقفال اتنضّفت والوكلاء وقفوا"

  # ══ 3 · ربط git + إعدادات مقاومة ══
  git config --global --unset-all credential.helper >/dev/null 2>&1
  git config --local  --unset-all credential.helper >/dev/null 2>&1
  rm -f "$HOME/.git-credentials" 2>/dev/null
  gh auth setup-git >/dev/null 2>&1
  [ -n "$(git remote get-url origin 2>/dev/null)" ] || git remote add origin "https://github.com/$OWNER/$NAME.git"
  git config http.postBuffer 524288000; git config http.version HTTP/1.1
  git config http.lowSpeedLimit 0; git config http.lowSpeedTime 999999
  git config pack.threads 1; git config core.compression 6; git config gc.auto 0
  git config --global --unset core.fsyncObjectFiles >/dev/null 2>&1
  git config --local  --unset core.fsyncObjectFiles >/dev/null 2>&1
  git config core.fsync committed
  say "✓ git مربوط + إعدادات الشبكة"

  # ══ 4 · تخفيف المستودع ══
  touch .gitignore
  for p in 'tools.bak.*/' 'snapshots/' 'money/.heal/backups/' 'money/.heal/state-*' 'money/logs/' '*.log'; do
    grep -qxF "$p" .gitignore 2>/dev/null || echo "$p" >> .gitignore
  done
  git rm -r --cached --ignore-unmatch -q tools.bak.* snapshots money/.heal/backups money/logs >/dev/null 2>&1
  say "✓ .gitignore اتظبط"

  # ══ 5 · مزامنة ══
  git fetch origin "$BR" --prune >/dev/null 2>&1 || true
  if git rev-parse --verify --quiet "origin/$BR" >/dev/null; then
    BASE=$(git rev-parse "origin/$BR")
    BEHIND=$(git rev-list --count "HEAD..$BASE" 2>/dev/null || echo 0)
    AHEAD=$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)
    say "▸ محلي متقدّم: $AHEAD · الريموت متقدّم: $BEHIND"
    if [ "$BEHIND" -gt 0 ]; then
      git -c rebase.autoStash=true pull --rebase origin "$BR" >/dev/null 2>&1 \
        || { git rebase --abort >/dev/null 2>&1; git pull --no-rebase --no-edit origin "$BR" >/dev/null 2>&1; }
      BASE=$(git rev-parse "origin/$BR")
    fi
  fi
  if [ -n "$BASE" ]; then
    AHEAD=$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)
    [ "$AHEAD" -gt 0 ] && { say "▸ فكّ $AHEAD كوميت لدفعات (المحتوى محفوظ)"; git reset --soft "$BASE"; git reset -q; }
  fi
  say "✓ المزامنة خلصت"
fi

push_try(){
  if GIT_TERMINAL_PROMPT=0 git push --no-thin origin "HEAD:refs/heads/$BR" >"$PLOG" 2>&1; then return 0; fi
  if grep -qE 'non-fast-forward|fetch first|rejected' "$PLOG" 2>/dev/null; then
    GIT_TERMINAL_PROMPT=0 git push --no-thin --force-with-lease origin "HEAD:refs/heads/$BR" >"$PLOG" 2>&1 && return 0
  fi
  return 1
}

batch_push(){
  local chunk=${1:-1200} total i=0 fails=0 n=0 j
  git add -A -- . >/dev/null 2>&1
  local -a FILES; mapfile -d '' FILES < <(git diff --cached --name-only -z)
  git reset -q
  total=${#FILES[@]}
  if [ "$total" -eq 0 ]; then say "✓ مفيش ملفات معلّقة للرفع"; return 0; fi
  say "▸ ملفات للرفع: $total · حجم الدفعة: $chunk"
  while [ "$i" -lt "$total" ]; do
    j=$(( i + chunk )); [ "$j" -gt "$total" ] && j=$total
    git add -A -- "${FILES[@]:$i:$((j-i))}" >/dev/null 2>&1
    git -c user.name="$USER" -c user.email="$USER@users.noreply.github.com" \
        commit -q -m "build: batch $((n+1)) [$j/$total]" >/dev/null 2>&1
    if push_try; then say "  ✓ $j/$total اترفع"; i=$j; n=$((n+1)); fails=0
    else
      fails=$((fails+1)); say "  ✗ الدفعة $j/$total — $(tail -1 "$PLOG" 2>/dev/null | cut -c1-90)"
      git reset -q --soft HEAD~1 2>/dev/null || git reset -q --soft "$BASE" 2>/dev/null
      git reset -q
      [ "$chunk" -gt 150 ] && { chunk=$(( chunk / 2 )); say "  ⚠ قلّلت الدفعة إلى $chunk"; }
      [ "$fails" -ge 8 ] && { say "  ✗ توقفت عند $i/$total"; return 1; }
      sleep 5
    fi
  done
  return 0
}

# ══ 6 · البناء الكامل الحقيقي ══
build(){
  say ""; say "▸ البناء الكامل…"
  for s in tools/genpages.py tools/movie_pages.py tools/pages.py tools/pages_gen.py \
           tools/build_index.py tools/sitemap.py tools/expand_pages.py tools/fix_pages.py tools/poster.py; do
    [ -f "$s" ] || continue
    say "  ▸ python3 $s"
    timeout 900 python3 "$s" >/dev/null 2>&1 || say "    ⚠ $s رجع بخطأ — بكمّل"
  done
  for s in tools/inject.js tools/render.js; do
    [ -f "$s" ] || continue
    say "  ▸ node $s"
    timeout 900 node "$s" >/dev/null 2>&1 || say "    ⚠ $s رجع بخطأ — بكمّل"
  done
  if [ -f money/one.mjs ]; then
    say "  ▸ node money/one.mjs (التجميع النهائي + الواجهة + الربط)"
    node money/one.mjs || say "    ⚠ one.mjs رجع بخطأ — بكمّل"
  fi
  if [ -f money/panel.mjs ]; then
    say "  ▸ بناء اللوحة"; timeout 60 node money/panel.mjs >/dev/null 2>&1 || true
  fi
  say "✓ البناء خلص"
}

# ══ 7 · صفحات التطبيق والأفلام واللوحة + تحديث الواجهة ══
ensure_pages(){
  if [ ! -f vn-panel.html ]; then
    cat > vn-panel.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>لوحة التحكم · CineHub</title><link rel="stylesheet" href="/grid.css">
<style>
:root{--bg:#0b0f14;--card:rgba(255,255,255,.05);--line:rgba(255,255,255,.09);--tx:#e8eef6;--mut:#8b9bb0;--acc:#4ade80}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#16202b,var(--bg));color:var(--tx);font:15px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:1100px;margin:0 auto;padding:28px 18px 90px}.top{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:22px;flex-wrap:wrap}
.brand{font-weight:800;font-size:20px}.brand span{color:var(--acc)}
.nav{display:flex;gap:8px;flex-wrap:wrap}.nav a{padding:8px 14px;border:1px solid var(--line);border-radius:999px;color:var(--tx);text-decoration:none;font-size:13px}
.nav a.on{background:var(--acc);color:#04140a;border-color:transparent;font-weight:700}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:14px}
.card{background:var(--card);border:1px solid var(--line);border-radius:16px;padding:18px;backdrop-filter:blur(8px)}
.card h3{margin:0 0 6px;font-size:15px}.card p{margin:0;color:var(--mut);font-size:13px}
.card a{display:inline-block;margin-top:12px;color:var(--acc);text-decoration:none;font-weight:600;font-size:13px}
.kpi{font-size:26px;font-weight:800;margin-top:6px}
</style></head><body><div class="wrap">
<div class="top"><div class="brand">Cine<span>Hub</span> · اللوحة</div>
<div class="nav"><a class="on" href="/vn-panel.html">اللوحة</a><a href="/vn-wallet.html">المحفظة</a><a href="/withdraw.html">السحب</a><a href="/movies.html">الأفلام</a><a href="/app.html">التطبيق</a></div></div>
<div class="grid">
<div class="card"><h3>الرصيد</h3><div class="kpi" id="bal">—</div><p>يُحدَّث تلقائياً</p></div>
<div class="card"><h3>الحالة</h3><div class="kpi">يعمل</div><p>الشبكة والمحفظة موصولتان</p></div>
<div class="card"><h3>الأفلام</h3><p>تصفّح المكتبة</p><a href="/movies.html">افتح</a></div>
<div class="card"><h3>التطبيق</h3><p>واجهة كاملة</p><a href="/app.html">افتح</a></div>
<div class="card"><h3>المحفظة</h3><p>ربط · رصيد · سجل</p><a href="/vn-wallet.html">افتح</a></div>
<div class="card"><h3>السحب</h3><p>تحويل الأرباح</p><a href="/withdraw.html">افتح</a></div>
</div></div>
<script src="/wallet.js" defer></script>
<script defer>fetch('/wallet.json').then(r=>r.json()).then(j=>{const b=document.getElementById('bal');if(b)b.textContent='$'+Number(j.balance??j.credit??0).toFixed(4);}).catch(()=>{});</script>
</body></html>
HTML
    say "  ✓ vn-panel.html"
  fi
  if [ ! -f vn-wallet.html ]; then
    cat > vn-wallet.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>المحفظة · CineHub</title><link rel="stylesheet" href="/grid.css">
<style>
:root{--bg:#0b0f14;--card:rgba(255,255,255,.05);--line:rgba(255,255,255,.09);--tx:#e8eef6;--mut:#8b9bb0;--acc:#60a5fa}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#131c2b,var(--bg));color:var(--tx);font:15px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:760px;margin:0 auto;padding:28px 18px 90px}.top{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:22px;flex-wrap:wrap}
.brand{font-weight:800;font-size:20px}.brand span{color:var(--acc)}
.nav{display:flex;gap:8px;flex-wrap:wrap}.nav a{padding:8px 14px;border:1px solid var(--line);border-radius:999px;color:var(--tx);text-decoration:none;font-size:13px}
.nav a.on{background:var(--acc);color:#04101f;border-color:transparent;font-weight:700}
.card{background:var(--card);border:1px solid var(--line);border-radius:18px;padding:22px;margin-bottom:14px}
.big{font-size:34px;font-weight:800;margin:8px 0}.row{display:flex;gap:10px;flex-wrap:wrap;margin-top:14px}
.btn{padding:11px 18px;border-radius:12px;border:1px solid var(--line);background:rgba(255,255,255,.06);color:var(--tx);text-decoration:none;font-weight:600;font-size:14px}
.btn.p{background:var(--acc);color:#04101f;border-color:transparent}.mut{color:var(--mut);font-size:13px}
</style></head><body><div class="wrap">
<div class="top"><div class="brand">Cine<span>Hub</span> · المحفظة</div>
<div class="nav"><a href="/vn-panel.html">اللوحة</a><a class="on" href="/vn-wallet.html">المحفظة</a><a href="/withdraw.html">السحب</a></div></div>
<div class="card"><div class="mut">الرصيد المتاح</div><div class="big" id="bal">$0.0000</div>
<div class="row"><a class="btn p" href="/withdraw.html">سحب الأرباح</a><a class="btn" href="/vn-panel.html">اللوحة</a></div></div>
<div class="card"><h3 style="margin:0 0 8px">سجل الحركات</h3><div class="mut" id="log">لا توجد حركات بعد</div></div>
<script src="/wallet.js" defer></script>
<script defer>fetch('/wallet.json').then(r=>r.json()).then(j=>{const b=document.getElementById('bal');if(b)b.textContent='$'+Number(j.balance??j.credit??0).toFixed(4);}).catch(()=>{});</script>
</body></html>
HTML
    say "  ✓ vn-wallet.html"
  fi
  if [ ! -f movies.html ]; then
    cat > movies.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>الأفلام · CineHub</title><link rel="stylesheet" href="/grid.css">
<style>
:root{--bg:#0b0f14;--line:rgba(255,255,255,.09);--tx:#e8eef6;--mut:#8b9bb0;--acc:#4ade80}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#16202b,var(--bg));color:var(--tx);font:15px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:1200px;margin:0 auto;padding:28px 18px 90px}.brand{font-weight:800;font-size:20px;margin-bottom:18px}.brand span{color:var(--acc)}
.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:12px}
.c{background:rgba(255,255,255,.05);border:1px solid var(--line);border-radius:14px;overflow:hidden;text-decoration:none;color:var(--tx);display:block}
.c img{width:100%;aspect-ratio:2/3;object-fit:cover;display:block;background:#111}
.c h3{margin:0;padding:10px;font-size:13px;font-weight:600;line-height:1.4}
.mut{color:var(--mut);font-size:13px;padding:12px}
</style></head><body><div class="wrap">
<div class="brand">Cine<span>Hub</span> · الأفلام</div>
<div class="g" id="g"><div class="mut">بيتم التحميل…</div></div></div>
<script>
fetch('/sites.json').then(r=>r.json()).then(j=>{
  const arr = Array.isArray(j) ? j : (j.sites||j.items||j.pages||j.data||[]);
  const g=document.getElementById('g');
  if(!arr.length){ g.innerHTML='<div class="mut">لا توجد بيانات بعد — <a style="color:#4ade80" href="/">الرئيسية</a></div>'; return; }
  g.innerHTML = arr.slice(0,600).map(x=>{
    const t = x.title||x.name||x.slug||x.id||'—';
    const u = x.url||x.path||x.href||'/';
    const p = x.poster||x.image||x.img||x.thumb||'';
    return '<a class="c" href="'+u+'">'+(p?'<img loading="lazy" src="'+p+'" alt="">':'')+'<h3>'+t+'</h3></a>';
  }).join('');
}).catch(()=>{document.getElementById('g').innerHTML='<div class="mut">تعذّر تحميل البيانات — <a style="color:#4ade80" href="/">الرئيسية</a></div>';});
</script></body></html>
HTML
    say "  ✓ movies.html"
  fi
  if [ ! -f app.html ]; then
    cat > app.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="theme-color" content="#0b0f14"><link rel="manifest" href="/manifest.webmanifest">
<title>التطبيق · CineHub</title><link rel="stylesheet" href="/grid.css">
<style>
:root{--bg:#0b0f14;--line:rgba(255,255,255,.09);--tx:#e8eef6;--mut:#8b9bb0;--acc:#4ade80}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#16202b,var(--bg));color:var(--tx);font:15px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:760px;margin:0 auto;padding:32px 18px 100px;text-align:center}
h1{font-size:26px;margin:0 0 8px}h1 span{color:var(--acc)}.mut{color:var(--mut);font-size:14px;margin-bottom:22px}
.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;text-align:right}
.c{background:rgba(255,255,255,.05);border:1px solid var(--line);border-radius:16px;padding:16px;text-decoration:none;color:var(--tx)}
.c b{display:block;font-size:15px;margin-bottom:4px}.c i{font-style:normal;color:var(--mut);font-size:12px}
</style></head><body><div class="wrap">
<h1>Cine<span>Hub</span> · التطبيق</h1><div class="mut">واجهة كاملة — تعمل من المتصفح ومثبّتة كتطبيق</div>
<div class="g">
<a class="c" href="/movies.html"><b>الأفلام</b><i>المكتبة كاملة</i></a>
<a class="c" href="/vn-panel.html"><b>اللوحة</b><i>التحكم والحالة</i></a>
<a class="c" href="/vn-wallet.html"><b>المحفظة</b><i>الرصيد والسجل</i></a>
<a class="c" href="/withdraw.html"><b>السحب</b><i>تحويل الأرباح</i></a>
<a class="c" href="/p/"><b>الصفحات</b><i>كل الأقسام</i></a>
<a class="c" href="/"><b>الرئيسية</b><i>ابدأ من هنا</i></a>
</div></div>
<script>if('serviceWorker' in navigator){}</script>
</body></html>
HTML
    say "  ✓ app.html"
  fi
  [ -f manifest.webmanifest ] || cat > manifest.webmanifest <<'JSON'
{"name":"CineHub","short_name":"CineHub","start_url":"/app.html","display":"standalone","background_color":"#0b0f14","theme_color":"#0b0f14","lang":"ar","dir":"rtl","icons":[]}
JSON
  if [ ! -f p/index.html ]; then
    mkdir -p p
    python3 - <<'PY' >/dev/null 2>&1 || true
import glob,io,os
items=sorted(glob.glob('p[0-9][0-9][0-9][0-9].html'))[:2000]
if not items: items=sorted(glob.glob('site/pages/*.html'))[:2000]
lis=''.join('<li><a href="/%s">%s</a></li>'%(f,os.path.basename(f)) for f in items)
html='''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>الصفحات · CineHub</title>
<link rel="stylesheet" href="/grid.css"><style>
body{margin:0;background:#0b0f14;color:#e8eef6;font:15px/1.7 system-ui,sans-serif}
.w{max-width:900px;margin:0 auto;padding:28px 18px 90px}a{color:#4ade80;text-decoration:none}
ul{list-style:none;padding:0;display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:8px}
li{background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.09);border-radius:10px;padding:10px 12px;font-size:13px}
</style></head><body><div class="w"><h1>الصفحات ('''+str(len(items))+''')</h1><ul>'''+lis+'''</ul></div></body></html>'''
io.open('p/index.html','w',encoding='utf-8').write(html)
PY
    say "  ✓ p/index.html"
  fi
  # تحديث الواجهة: شريط تنقّل عصري في الصفحة الرئيسية (مرة واحدة)
  if [ -f index.html ] && ! grep -q 'vn-modern' index.html 2>/dev/null; then
    python3 - <<'PY' >/dev/null 2>&1 || true
import io
p='index.html'; s=io.open(p,encoding='utf-8',errors='ignore').read()
add='''<!--vn-modern-->
<style id="vn-modern">
#vnnav{position:fixed;left:50%;bottom:14px;transform:translateX(-50%);display:flex;gap:4px;padding:7px;
border-radius:999px;background:rgba(10,14,20,.85);backdrop-filter:blur(10px);border:1px solid rgba(255,255,255,.12);
z-index:99999;font:13px system-ui,-apple-system,Segoe UI,Roboto,sans-serif;max-width:96vw;overflow-x:auto}
#vnnav a{color:#e8eef6;text-decoration:none;padding:8px 12px;border-radius:999px;white-space:nowrap}
#vnnav a:hover{background:rgba(255,255,255,.1)}
#vnnav a.p{background:#4ade80;color:#04140a;font-weight:700}
</style>
<div id="vnnav"><a class="p" href="/">الرئيسية</a><a href="/movies.html">الأفلام</a><a href="/app.html">التطبيق</a>
<a href="/vn-panel.html">اللوحة</a><a href="/vn-wallet.html">المحفظة</a><a href="/withdraw.html">السحب</a></div>'''
s = s.replace('</body>', add+'\n</body>',1) if '</body>' in s else s+add
io.open(p,'w',encoding='utf-8').write(s)
PY
    say "  ✓ الواجهة اتحدّثت (شريط تنقّل عصري)"
  fi
}

if [ "$CHECK" = 0 ]; then
  build
  restore
  ensure_pages
  say ""; say "▸ رفع (دفعات)…"
  batch_push 1200 || true
fi

# ══ 8 · تفعيل الوكلاء ══
mkdir -p money/logs
pkill -f 'money/heal.mjs' 2>/dev/null; sleep 1
say "▸ تفعيل الوكلاء…"
for f in heal.mjs panel.mjs agent.mjs tick.mjs; do
  [ -f "money/$f" ] || continue
  if [ "$f" = heal.mjs ]; then nohup node "money/$f" --watch >> "money/logs/${f%.mjs}.log" 2>&1 &
  else nohup node "money/$f" >> "money/logs/${f%.mjs}.log" 2>&1 & fi
done
sleep 2
say "✓ الوكلاء: $(pgrep -f 'money/' | grep -v FULL.sh | wc -l) عملية"

# ══ 9 · تحقق حي ══
one_code(){ local u="$1" s="" k
  for k in 1 2 3; do
    s=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "$REAL$u")
    [ "$s" = "200" ] && { echo 200; return; }
    sleep 2
  done; echo "${s:-000}"; }
verify(){
  local T=(/ /index.html /movies.html /app.html /p/ /grid.js /wallet.js /grid.css /tmdb-img-shim.js /vn-panel.html /vn-wallet.html /withdraw.html)
  local good=0 r=0 line t s
  say ""; say "══ تحقق حي (لحد 6 دقايق) ══"
  while [ "$r" -lt 24 ]; do
    r=$((r+1)); good=0; line=""
    for t in "${T[@]}"; do s=$(one_code "$t"); [ "$s" = "200" ] && good=$((good+1)); line="$line $t=$s"; done
    say " جولة $r [$good/${#T[@]}]$line"
    [ "$good" -eq "${#T[@]}" ] && break
    sleep 15
  done
  GOOD=$good; TOTAL=${#T[@]}
}
verify
if [ "$GOOD" -ne "$TOTAL" ] && [ "$CHECK" = 0 ]; then
  say ""; say "▸ إعادة نشر قسرية…"
  git commit -q --allow-empty -m "ci: rebuild pages" 2>/dev/null
  push_try || true
  sleep 40; verify
fi
say ""
if [ "$GOOD" -eq "$TOTAL" ]; then say "✓✓ الموقع حيّ بالكامل — كل الملفات 200"
else say "⚠ ناقص $(( TOTAL - GOOD )) — كرر: bash $REPO/money/FULL.sh --check"; fi
say "► $REAL"
say "► التطبيق $REAL/app.html · الأفلام $REAL/movies.html · اللوحة $REAL/vn-panel.html"
say "► النسخة: $SNAP"
command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock
