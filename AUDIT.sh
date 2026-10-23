#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════════
#  AUDIT.sh — فحص فعلي كامل · دليل مكتوب · نسخة احتياطية · بلا إيقاف عمليات
# ══════════════════════════════════════════════════════════════════════
set -uo pipefail
cd "$HOME/cinehub3099" 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
export TMPDIR="$PWD/.tmp"; mkdir -p "$TMPDIR" logs tools data/audit
export GIT_HTTP_LOW_SPEED_LIMIT=0 GIT_HTTP_LOW_SPEED_TIME=999999
TS="$(date +%F_%H%M%S)"
LOG="logs/audit.$TS.log"; : > "$LOG"
# ألوان;Y=$'\033[33m';R=$'\033[31m';C=$'\033[36m';B=$'\033[1m';N=$'\033[0m';D=$'\033[2m'
ok(){ printf '%s✓%s %s\n' "$G" "$N" "$*" | tee -a "$LOG"; }
bad(){ printf '%s✗%s %s\n' "$R" "$N" "$*" | tee -a "$LOG"; }
wrn(){ printf '%s!%s %s\n' "$Y" "$N" "$*" | tee -a "$LOG"; }
hd(){ printf '\n%s══ %s ══%s\n' "$C" "$*" "$N" | tee -a "$LOG"; }

# ═════════════════════════════════ 1 · البنية
hd "1 · بنية المستودع"
du -sh . 2>/dev/null | cut -f1 | sed 's/^/  الحجم: /'
printf '  الجذر: %s ملف\n' "$(find . -maxdepth 1 -type f | wc -l)"
printf '  أدوات: %s ملف py\n' "$(ls -1 tools/*.py 2>/dev/null | wc -l)"
printf '  صفحات جذر: %s · صفحات adult: %s · go: %s\n' \
  "$(ls -1 *.html 2>/dev/null | wc -l)" "$(ls -1 adult/*.html 2>/dev/null | wc -l)" "$(ls -1 go/*.html 2>/dev/null | wc -l)"
printf '  workflows: %s\n' "$(ls -1 .github/workflows/* 2>/dev/null | wc -l)"
printf '%s\n' "--- الملفات المذكورة في الأمر ---"
for f in ADULT.sh agentd.sh keys.env .env .gitignore .env.example \
  tools/adult_ads.py tools/adult_build.py tools/adult_registry.py tools/adult_promote.py \
  tools/tasks.py tools/proof.py tools/core.py tools/ads.py \
  data/revenue.json data/adult.json ads-adult.json catalog.json films.json titles.json \
  hits.js sitemap.xml robots.txt rss.xml manifest.json index.html app.html; do
  if [ -e "$f" ]; then printf '  %s✓%s %-34s %s\n' "$G" "$N" "$f" "$(stat -c%s "$f" 2>/dev/null || echo -)"; else printf '  %s·%s %-34s مفقود\n' "$D" "$N" "$f"; fi
done
printf '%s\n' "--- كتالوج ---"
ls -1 *.json 2>/dev/null | head -30 | sed 's/^/  /'

# ═════════════════════════════════ 2 · Git
hd "2 · حالة Git"
printf '  الفرع      : %s\n' "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
printf '  HEAD       : %s\n' "$(git log -1 --format='%h %ad %s' --date=short 2>/dev/null | cut -c1-72 || echo none)"
printf '  تغييرات    : %s\n' "$(git status --porcelain 2>/dev/null | wc -l)"
printf '  غير متتبَّع : %s\n' "$(git status --porcelain 2>/dev/null | grep -c '^??' || true)"
printf '  فروع       : %s\n' "$(git branch 2>/dev/null | wc -l)"
printf '  remote     : %s\n' "$(git remote get-url origin 2>/dev/null | sed -E 's#//[^@]*@#//TOKEN@#' || echo none)"
printf '  stash      : %s\n' "$(git stash list 2>/dev/null | wc -l)"
printf '%s\n' "--- آخر 8 إيداعات ---"
git log -8 --format='  %h %ad %s' --date=short 2>/dev/null | cut -c1-78

# ═════════════════════════════════ 3 · الأسرار
hd "3 · تدقيق الأسرار (بلا طباعة قيم)"
if [ -f keys.env ]; then
  NAMES="$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' keys.env 2>/dev/null | cut -d= -f1)"
  FILLED="$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=.+' keys.env 2>/dev/null | cut -d= -f1)"
  printf '  متغيرات معرَّفة : %s\n' "$(echo "$NAMES" | grep -c . || true)"
  printf '  متغيرات بقيمة  : %s\n' "$(echo "$FILLED" | grep -c . || true)"
  printf '  فارغة          : %s\n' "$(( $(echo "$NAMES" | grep -c . || true) - $(echo "$FILLED" | grep -c . || true) ))"
  printf '  أسماء المفاتيح المملوءة:\n'
  echo "$FILLED" | sed 's/^/    · /'
  git ls-files --error-unmatch keys.env >/dev/null 2>&1 && wrn "keys.env متتبَّع في Git (سيُرفع)" || ok "keys.env غير متتبَّع"
else wrn "keys.env مفقود"; fi
printf '%s\n' "--- .gitignore ---"
for x in keys.env .env .tmp logs; do
  grep -qF "$x" .gitignore 2>/dev/null && ok "محمي: $x" || wrn "غير محمي: $x"
done

# ═════════════════════════════════ 4 · صحة الكود
hd "4 · صحة Python وJSON وHTML"
PF=0; for p in tools/*.py; do python3 -m py_compile "$p" 2>/dev/null || { bad "خطأ نحوي: $p"; PF=1; }; done
[ "$PF" = 0 ] && ok "كل ملفات Python سليمة ($(ls -1 tools/*.py | wc -l))"
JF=0; for j in $(find . -maxdepth 2 -name '*.json' -not -path './.git/*' -not -path './.tmp/*' 2>/dev/null); do
  python3 -c "import json,sys;json.load(open(sys.argv[1],encoding='utf-8'))" "$j" 2>/dev/null || { bad "JSON تالف: $j"; JF=1; }
done
[ "$JF" = 0 ] && ok "كل ملفات JSON سليمة"
RTL=0; VP=0; TOT=0
for f in $(find . -maxdepth 2 -name '*.html' -not -path './.git/*' 2>/dev/null); do
  TOT=$((TOT+1))
  head -c 400 "$f" | grep -q 'dir="rtl"' || RTL=$((RTL+1))
  head -c 400 "$f" | grep -q 'viewport' || VP=$((VP+1))
done
printf '  صفحات: %d · بلا RTL: %d · بلا viewport: %d\n' "$TOT" "$RTL" "$VP"

# ═════════════════════════════════ 5 · تشخيص الكتالوج (سبب 0 عناوين)
hd "5 · تشخيص الكتالوج"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
from collections import Counter
CAND = ["catalog.json","films.json","titles.json","data/catalog.json","data/films.json","data/items.json","data/titles.json"]
LISTK = ("items","data","results","rows","entries","catalog","list","films","titles","movies","all")
found = False
for f in CAND:
    if not os.path.exists(f): continue
    found = True
    try: d = json.load(open(f, encoding="utf-8"))
    except Exception as e: print("  %-24s JSON تالف → %s" % (f, e)); continue
    rows = None
    if isinstance(d, list): rows, shape = d, "list"
    elif isinstance(d, dict):
        for k in LISTK:
            if isinstance(d.get(k), list): rows = d[k]; shape = "dict[%s]" % k; break
        if rows is None and d and all(isinstance(v, dict) for v in d.values()):
            rows = list(d.values()); shape = "map[%s]" % ",".join(list(d)[:3])
        if rows is None: shape = "dict(%s)" % ",".join(list(d)[:6])
    if not rows: print("  %-24s شكل غير قابل للقراءة → %s" % (f, shape)); continue
    print("  %-24s %d عنصر · %s" % (f, len(rows), shape))
    c = Counter()
    for x in rows[:4000]:
        if isinstance(x, dict):
            for k in x: c[k] += 1
    print("      " + " · ".join("%s=%d" % (k, v) for k, v in c.most_common(16)))
    sample = rows[0] if rows else {}
    if isinstance(sample, dict):
        print("      عيّنة مفاتيح: " + ", ".join(list(sample)[:12]))
if not found: print("  ✗ لا ملف كتالوج من الأسماء المعروفة")
PY

# ═════════════════════════════════ 6 · حالة التكاملات
hd "6 · حالة الملفات الحسّاسة للإيرادات"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os
for f in ("ads-adult.json","data/adult.json","data/revenue.json","data/ledger.json",
          "data/rewards.json","data/adult_meta.json","go/index.json","data/providers.json"):
    if not os.path.exists(f): print("  · %-24s —" % f); continue
    try: d = json.load(open(f, encoding="utf-8"))
    except Exception as e: print("  ✗ %-24s تالف" % f); continue
    if isinstance(d, dict):
        keys = ("count","enabled","networks","providers","items","totals","pages")
        bits = ["%s=%s" % (k, (len(d[k]) if isinstance(d[k], (list, dict)) else d[k])) for k in keys if k in d]
        print("  ✓ %-24s %s" % (f, " ".join(bits) or "موجود"))
PY
if [ -f ads-adult.json ]; then
  python3 -c "
import json;d=json.load(open('ads-adult.json'))
n=d.get('networks',[]);print('  شبكات=%d مفعّلة=%d'%(len(n),len([x for x in n if x.get('on')])))" 2>/dev/null
fi
pgrep -f agentd.sh >/dev/null 2>&1 && ok "الوكيل يعمل (لن يُوقَف)" || wrn "الوكيل لا يعمل"
[ -f agentd.sh ] && printf '  agentd.sh: %s سطر\n' "$(wc -l < agentd.sh)"
[ -f tools/tasks.py ] && printf '  tasks.py : %s سطر · مهام: %s\n' "$(wc -l < tools/tasks.py)" "$(grep -cE '^\s*\("' tools/tasks.py 2>/dev/null || echo 0)"

# ═════════════════════════════════ 7 · نسخة احتياطية
hd "7 · نسخة احتياطية قابلة للاستعادة"
BK="$HOME/cinehub-backups/$TS"; mkdir -p "$BK"
tar czf "$BK/tree.tgz" --exclude=.git --exclude=.tmp --exclude=logs --exclude=node_modules . 2>/dev/null
git bundle create "$BK/repo.bundle" --all >/dev/null 2>&1 && ok "bundle تاريخ Git" || wrn "bundle فشل"
cp keys.env "$BK/keys.env.bak" 2>/dev/null && ok "نسخة المفاتيح"
cp -r data "$BK/data" 2>/dev/null && ok "نسخة البيانات"
printf '%s\n' "$BK" > "$HOME/.cinehub_lastbackup"
printf '  الموقع: %s (%s)\n' "$BK" "$(du -sh "$BK" 2>/dev/null | cut -f1)"
printf '  استعادة: tar xzf %s/tree.tgz -C ~/cinehub3099\n' "$BK"
printf '  استعادة Git: git clone %s/repo.bundle restored\n' "$BK"

# ═════════════════════════════════ 8 · تقرير
hd "8 · كتابة التقرير"
python3 - <<'PY' 2>&1 | tee -a "$LOG"
import json, os, subprocess, time
R = {"ts": time.strftime("%F %H:%M:%S"), "root": os.getcwd()}
R["files"] = {f: (os.path.getsize(f) if os.path.exists(f) else None)
              for f in ("keys.env","catalog.json","tools/tasks.py","tools/core.py","agentd.sh","data/revenue.json")}
try: R["branch"] = subprocess.run(["git","rev-parse","--abbrev-ref","HEAD"],capture_output=True,text=True).stdout.strip()
except Exception: R["branch"] = "?"
try: R["dirty"] = len(subprocess.run(["git","status","--porcelain"],capture_output=True,text=True).stdout.splitlines())
except Exception: R["dirty"] = -1
try:
    n = open("keys.env", encoding="utf-8").read().splitlines()
    R["secrets_defined"] = sum(1 for l in n if "=" in l and not l.strip().startswith("#"))
    R["secrets_filled"] = sum(1 for l in n if "=" in l and l.split("=",1)[1].strip() and not l.strip().startswith("#"))
except Exception: R["secrets_defined"] = R["secrets_filled"] = 0
os.makedirs("data/audit", exist_ok=True)
json.dump(R, open("data/audit/audit-%s.json" % time.strftime("%F_%H%M"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
print("  ✓ data/audit/audit-*.json")
PY

printf '\n%s╔════════════════════════════════════════╗\n' "$G"
printf '║  AUDIT انتهى — أرسل مخرجات القسمين 5 و6 ║\n'
printf '╚════════════════════════════════════════╝%s\n' "$N"
printf 'السجل: %s\nالنسخة: %s\n' "$LOG" "$BK"
