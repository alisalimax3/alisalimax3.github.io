#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
P=0; F=0; ok(){ printf '  ✔ %s\n' "$1"; P=$((P+1)); }; no(){ printf '  ✗ %s\n' "$1"; F=$((F+1)); }

echo "── صحة الصياغة ──"
for f in "$HERE"/*.js; do [ -e "$f" ] || continue; node --check "$f" >/dev/null 2>&1 && ok "js $(basename "$f")" || no "js $(basename "$f")"; done
for f in "$HERE"/*.sh "$HERE"/lib/*.sh; do [ -e "$f" ] || continue; bash -n "$f" >/dev/null 2>&1 && ok "sh $(basename "$f")" || no "sh $(basename "$f")"; done
for f in "$HERE"/*.py "$HERE"/lib/*.py; do [ -e "$f" ] || continue; python3 -m py_compile "$f" >/dev/null 2>&1 && ok "py $(basename "$f")" || no "py $(basename "$f")"; done

echo "── سلامة JSON + الجرد الحقيقي ──"
python3 - "$HERE" <<'PY'
import json,glob,os,sys,collections
h=sys.argv[1];all=[];per={};bad=[]
for f in sorted(glob.glob(os.path.join(h,"sources*.json"))):
    try:
        d=json.load(open(f,encoding="utf-8"))
        if not isinstance(d,list): raise ValueError("ليس مصفوفة")
        per[os.path.basename(f)]=len(d); all+=d
    except Exception as e: bad.append((os.path.basename(f),str(e)[:50]))
ids=collections.Counter(x["id"] for x in all if isinstance(x,dict) and x.get("id"))
print("  ملفات سليمة:",len(per),per)
if bad: print("  ✗ مكسورة:",bad)
print("  مدخلات:",len(all),"| ★ منصات فريدة:",len(ids),"| مكرر:",sum(1 for v in ids.values() if v>1))
print("  بلا مفتاح:",sum(1 for x in all if x.get("url")=="-"))
print("  حقول ناقصة → env:%d url:%d cat:%d"%(sum(1 for x in all if not x.get("env")),sum(1 for x in all if not x.get("url")),sum(1 for x in all if not x.get("cat"))))
print("  التصنيفات:",dict(collections.Counter(x.get("cat") for x in all)))
PY

echo "── keys.env ──"
if [ -f keys.env ]; then
  D=$(awk -F= '/^[A-Za-z_][A-Za-z0-9_]*=/{print $1}' keys.env | sort | uniq -d | wc -l | tr -d ' ')
  [ "$D" = "0" ] && ok "بلا تكرار" || no "$D مفتاح مكرر"
  M=$(stat -c %a keys.env 2>/dev/null || echo "?"); [ "$M" = "600" ] && ok "الصلاحيات 600" || { chmod 600 keys.env; ok "ضُبطت 600"; }
  for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do grep -q "^$K=" keys.env && ok "$K مثبّت" || no "$K ناقص"; done
else no "keys.env مفقود"; fi

echo "── الخدمات ──"
for K in PORT AUTH_PORT AGENT_PORT HUB_PORT; do
  V=$(grep -m1 "^$K=" keys.env 2>/dev/null | cut -d= -f2-)
  [ -n "$V" ] && { curl -s -o /dev/null --max-time 4 "http://127.0.0.1:$V/" && ok "$K=$V يستجيب" || no "$K=$V لا يستجيب"; }
done

echo "── فحص حقيقي لعيّنة 40 رابطًا ──"
python3 - "$HERE" <<'PY'
import json,glob,os,sys,subprocess,random
h=sys.argv[1];all=[]
for f in sorted(glob.glob(os.path.join(h,"sources*.json"))):
    try: all+=json.load(open(f,encoding="utf-8"))
    except Exception: pass
seen=set();L=[]
for x in all:
    if x.get("id") in seen: continue
    seen.add(x.get("id")); L.append(x)
random.seed(7)
live=blk=dead=0
for x in random.sample(L,min(40,len(L))):
    u=x.get("probe") or x.get("url")
    if not u or u=="-": continue
    try: c=subprocess.run(["curl","-sL","--retry","3","--retry-delay","2","-o","/dev/null","-w","%{http_code}","--max-time","12","-A","Mozilla/5.0 cinehub",u],capture_output=True,text=True,timeout=20).stdout.strip()
    except Exception: c="0"
    if c[:1] in ("2","3"): live+=1
    elif c in ("401","403","429","503"): blk+=1
    else: dead+=1; print("    ✗ %s → %s"%(x.get("id"),c))
print("  ✔ يستجيب: %d | محجوب أمام curl (ليس ميتًا): %d | فشل: %d"%(live,blk,dead))
PY

echo; echo "النتيجة: ✔ $P | ✗ $F"
[ "$F" -eq 0 ] && echo "PASS ✅" || echo "FAIL ❌"
