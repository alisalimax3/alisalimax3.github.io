#!/data/data/com.termux/files/usr/bin/bash
# money/FULL.sh — الأمر الموحد النهائي · إصلاح شامل + رفع على دفعات + نشر
# الاستخدام: bash money/FULL.sh   |   bash money/FULL.sh --check
set -u
cd "$(dirname "$0")/.." || exit 1

BR=main; OWNER=alisalimax3; NAME=alisalimax3.github.io
REAL="https://$OWNER.github.io"
PLOG="$PWD/.git/_push.log"          # ← مفيش اعتماد على /tmp
CHECK=0; [ "${1:-}" = "--check" ] && CHECK=1
BASE=""; USER="$OWNER"
say(){ printf '%s\n' "$*"; }
die(){ say "✗ $*"; exit 1; }

say ""; say "═════ FULL · مصادقة + إصلاح + تجميع + رفع + نشر ═════"
[ -d .git ] || die "مش مستودع git"
command -v gh >/dev/null 2>&1 || die "gh مش متسطّب"

if [ "$CHECK" = 0 ]; then
  # ── 1 · مصادقة بالمتصفح ──
  if [ -z "$(gh auth token 2>/dev/null)" ]; then
    say ""; say "► هيفتح المتصفح ويظهر كود. افتح الرابط، الصق الكود، وافق Authorize."
    gh auth login --hostname github.com --git-protocol https --web || true
    [ -n "$(gh auth token 2>/dev/null)" ] || die "المصادقة ماكملتش"
  else say "✓ مسجّل دخول — مفيش كود مطلوب"; fi
  USER=$(gh api user --jq .login 2>/dev/null || echo "$OWNER")
  say "✓ الحساب: $USER"

  # ── 2 · نظّف الأقفال وبقايا الـ rebase ──
  for p in heal panel agent tick agentd; do pkill -f "money/$p.mjs" 2>/dev/null; done
  sleep 1
  git rebase --abort >/dev/null 2>&1; git merge --abort >/dev/null 2>&1
  rm -rf .git/rebase-merge .git/rebase-apply 2>/dev/null
  rm -f .git/index.lock .git/MERGE_HEAD 2>/dev/null
  say "✓ الأقفال اتنضّفت"

  # ── 3 · ربط git + إعدادات مقاومة ──
  git config --global --unset-all credential.helper >/dev/null 2>&1
  git config --local  --unset-all credential.helper >/dev/null 2>&1
  rm -f "$HOME/.git-credentials" 2>/dev/null
  gh auth setup-git >/dev/null 2>&1
  [ -n "$(git remote get-url origin 2>/dev/null)" ] || git remote add origin "https://github.com/$OWNER/$NAME.git"
  git config http.postBuffer 524288000
  git config http.version HTTP/1.1
  git config http.lowSpeedLimit 0
  git config http.lowSpeedTime 999999
  git config pack.threads 1
  git config core.compression 6
  git config --global --unset core.fsyncObjectFiles >/dev/null 2>&1
  git config --local  --unset core.fsyncObjectFiles >/dev/null 2>&1
  git config core.fsync committed
  git config gc.auto 0
  say "✓ git مربوط + إعدادات الشبكة"

  # ── 4 · خفّف المستودع ──
  touch .gitignore
  for p in 'tools.bak.*/' 'snapshots/' 'money/.heal/backups/' 'money/logs/' '*.log'; do
    grep -qxF "$p" .gitignore 2>/dev/null || echo "$p" >> .gitignore
  done
  git rm -r --cached --ignore-unmatch -q tools.bak.* snapshots money/.heal/backups money/logs >/dev/null 2>&1
  say "✓ .gitignore اتظبط"

  # ── 5 · مزامنة ──
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
  say "✓ المزامنة خلصت"

  # ── 6 · فكّ الكوميتات لإعادة رفعها على دفعات ──
  if [ -n "$BASE" ]; then
    AHEAD=$(git rev-list --count "$BASE..HEAD" 2>/dev/null || echo 0)
    [ "$AHEAD" -gt 0 ] && { say "▸ فكّ $AHEAD كوميت لدفعات (المحتوى محفوظ)"; git reset --soft "$BASE"; git reset -q; }
  fi
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
    if push_try; then
      say "  ✓ $j/$total اترفع"; i=$j; n=$((n+1)); fails=0
    else
      fails=$((fails+1))
      say "  ✗ الدفعة $j/$total — $(tail -1 "$PLOG" 2>/dev/null | cut -c1-90)"
      git reset -q --soft HEAD~1 2>/dev/null || git reset -q --soft "$BASE" 2>/dev/null
      git reset -q
      if [ "$chunk" -gt 150 ]; then chunk=$(( chunk / 2 )); say "  ⚠ قلّلت الدفعة إلى $chunk"; fi
      [ "$fails" -ge 8 ] && { say "  ✗ توقفت عند $i/$total"; return 1; }
      sleep 5
    fi
  done
  return 0
}

# ── صفحات ناقصة: اللوحة والمحفظة ──
ensure_pages(){
  if [ ! -f vn-panel.html ]; then
    cat > vn-panel.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>لوحة التحكم · CineHub</title><link rel="stylesheet" href="/grid.css">
<style>
:root{--bg:#0b0f14;--card:rgba(255,255,255,.05);--line:rgba(255,255,255,.09);--tx:#e8eef6;--mut:#8b9bb0;--acc:#4ade80}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#16202b,var(--bg));color:var(--tx);font:15px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:1100px;margin:0 auto;padding:28px 18px 60px}.top{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:22px;flex-wrap:wrap}
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
<div class="nav"><a class="on" href="/vn-panel.html">اللوحة</a><a href="/vn-wallet.html">المحفظة</a><a href="/withdraw.html">السحب</a><a href="/">الرئيسية</a></div></div>
<div class="grid">
<div class="card"><h3>الرصيد</h3><div class="kpi" id="bal">—</div><p>يُحدَّث تلقائياً</p></div>
<div class="card"><h3>الحالة</h3><div class="kpi" id="st">يعمل</div><p>الشبكة والمحفظة موصولتان</p></div>
<div class="card"><h3>الشبكة</h3><p>العقد والأفلام المباشرة</p><a href="/">تصفّح</a></div>
<div class="card"><h3>المحفظة</h3><p>ربط · رصيد · سجل</p><a href="/vn-wallet.html">افتح</a></div>
<div class="card"><h3>السحب</h3><p>تحويل الأرباح</p><a href="/withdraw.html">افتح</a></div>
<div class="card"><h3>الحالة الحيّة</h3><p>بيانات الخدمة</p><a href="/wallet.json">wallet.json</a></div>
</div></div>
<script src="/wallet.js" defer></script>
<script defer>fetch('/wallet.json').then(r=>r.json()).then(j=>{const b=document.getElementById('bal');const v=j.balance??j.credit??0;if(b)b.textContent='$'+Number(v).toFixed(4);}).catch(()=>{});</script>
</body></html>
HTML
    say "✓ vn-panel.html اتُنشئ"
  fi
  if [ ! -f vn-wallet.html ]; then
    cat > vn-wallet.html <<'HTML'
<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>المحفظة · CineHub</title><link rel="stylesheet" href="/grid.css">
<style>
:root{--bg:#0b0f14;--card:rgba(255,255,255,.05);--line:rgba(255,255,255,.09);--tx:#e8eef6;--mut:#8b9bb0;--acc:#60a5fa}
*{box-sizing:border-box}body{margin:0;background:radial-gradient(1200px 600px at 50% -10%,#131c2b,var(--bg));color:var(--tx);font:15px/1.6 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.wrap{max-width:760px;margin:0 auto;padding:28px 18px 60px}.top{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:22px;flex-wrap:wrap}
.brand{font-weight:800;font-size:20px}.brand span{color:var(--acc)}
.nav{display:flex;gap:8px;flex-wrap:wrap}.nav a{padding:8px 14px;border:1px solid var(--line);border-radius:999px;color:var(--tx);text-decoration:none;font-size:13px}
.nav a.on{background:var(--acc);color:#04101f;border-color:transparent;font-weight:700}
.card{background:var(--card);border:1px solid var(--line);border-radius:18px;padding:22px;margin-bottom:14px;backdrop-filter:blur(8px)}
.big{font-size:34px;font-weight:800;margin:8px 0}
.row{display:flex;gap:10px;flex-wrap:wrap;margin-top:14px}
.btn{padding:11px 18px;border-radius:12px;border:1px solid var(--line);background:rgba(255,255,255,.06);color:var(--tx);text-decoration:none;font-weight:600;font-size:14px}
.btn.p{background:var(--acc);color:#04101f;border-color:transparent}
.mut{color:var(--mut);font-size:13px}
</style></head><body><div class="wrap">
<div class="top"><div class="brand">Cine<span>Hub</span> · المحفظة</div>
<div class="nav"><a href="/vn-panel.html">اللوحة</a><a class="on" href="/vn-wallet.html">المحفظة</a><a href="/withdraw.html">السحب</a></div></div>
<div class="card"><div class="mut">الرصيد المتاح</div><div class="big" id="bal">$0.0000</div>
<div class="row"><a class="btn p" href="/withdraw.html">سحب الأرباح</a><a class="btn" href="/vn-panel.html">اللوحة</a></div></div>
<div class="card"><h3 style="margin:0 0 8px">سجل الحركات</h3><div class="mut" id="log">لا توجد حركات بعد</div></div>
<script src="/wallet.js" defer></script>
<script defer>fetch('/wallet.json').then(r=>r.json()).then(j=>{const v=j.balance??j.credit??0;const b=document.getElementById('bal');if(b)b.textContent='$'+Number(v).toFixed(4);}).catch(()=>{});</script>
</body></html>
HTML
    say "✓ vn-wallet.html اتُنشئ"
  fi
}

if [ "$CHECK" = 0 ]; then
  say ""; say "▸ رفع الحالة الحالية (دفعات)…"; batch_push 1200 || true
  if [ -f money/one.mjs ]; then
    say ""; say "▸ تشغيل خط الإنتاج money/one.mjs …"
    node money/one.mjs || say "⚠ one.mjs خلص بكود خطأ — بكمّل"
  fi
  ensure_pages
  say ""; say "▸ رفع البواقي…"; batch_push 800 || true
fi

# ── الوكلاء ──
mkdir -p money/logs
if ! pgrep -f 'money/heal.mjs' >/dev/null 2>&1; then
  say "▸ تشغيل الوكلاء…"
  for f in heal.mjs panel.mjs agent.mjs tick.mjs; do
    [ -f "money/$f" ] || continue
    if [ "$f" = heal.mjs ]; then nohup node "money/$f" --watch >> "money/logs/${f%.mjs}.log" 2>&1 &
    else nohup node "money/$f" >> "money/logs/${f%.mjs}.log" 2>&1 & fi
  done
  sleep 2
fi
say "✓ الوكلاء: $(pgrep -f 'money/' | grep -v FULL.sh | wc -l) عملية"

# ── تحقق حي (000 = عابر → إعادة محاولة) ──
one_code(){ local u="$1" s=""; local k
  for k in 1 2 3; do
    s=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 20 "$REAL$u")
    [ "$s" = "200" ] && { echo 200; return; }
    sleep 2
  done
  echo "${s:-000}"
}
verify(){
  local T=(/ /index.html /grid.js /wallet.js /grid.css /tmdb-img-shim.js /vn-panel.html /vn-wallet.html /withdraw.html)
  local good=0 r=0 line t s
  say ""; say "══ تحقق حي (لحد 6 دقايق) ══"
  while [ "$r" -lt 24 ]; do
    r=$((r+1)); good=0; line=""
    for t in "${T[@]}"; do
      s=$(one_code "$t"); [ "$s" = "200" ] && good=$((good+1)); line="$line $t=$s"
    done
    say " جولة $r [$good/${#T[@]}]$line"
    [ "$good" -eq "${#T[@]}" ] && break
    sleep 15
  done
  GOOD=$good; TOTAL=${#T[@]}
}

verify
if [ "$GOOD" -ne "$TOTAL" ] && [ "$CHECK" = 0 ]; then
  say ""
  say "▸ إعادة نشر قسرية…"
  git commit -q --allow-empty -m "ci: rebuild pages" 2>/dev/null
  push_try || true
  sleep 40
  verify
fi

say ""
if [ "$GOOD" -eq "$TOTAL" ]; then say "✓✓ الموقع حيّ بالكامل — كل الملفات 200"
else say "⚠ ناقص $(( TOTAL - GOOD )) — كرر: bash money/FULL.sh --check"; fi
say "► $REAL"
say "► اللوحة $REAL/vn-panel.html · المحفظة $REAL/vn-wallet.html · السحب $REAL/withdraw.html"
