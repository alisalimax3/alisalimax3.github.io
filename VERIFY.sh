#!/data/data/com.termux/files/usr/bin/bash
# مُتحقِّق مستقل: يقارن بصمات الملفات بالمانيفست
cd "$HOME/cinehub3099" || exit 1
G=$'\033[32m';R=$'\033[31m';C=$'\033[36m';N=$'\033[0m'
python3 - <<'PY'
import hashlib, json, os
m = json.load(open("proof/manifest.json", encoding="utf-8"))
bad = 0
for f, h in m["files"].items():
    if not os.path.exists(f): print("  ✗ مفقود: %s" % f); bad += 1; continue
    cur = hashlib.sha256(open(f, "rb").read()).hexdigest()[:32]
    if cur != h: print("  ✗ تغيّر: %s" % f); bad += 1
    else: print("  ✓ %s" % f)
root = hashlib.sha256("".join(sorted(m["files"].values())).encode()).hexdigest()[:32]
print("\n  الجذر: %s %s" % (root, "✓ مطابق" if root == m["root"] else "✗ مختلف"))
print("  التاريخ: %s" % m["at"])
raise SystemExit(1 if bad else 0)
PY
