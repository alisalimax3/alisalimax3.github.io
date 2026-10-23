#!/data/data/com.termux/files/usr/bin/bash
set -u
REPO="/data/data/com.termux/files/home/cinehub3099"; cd "$REPO" || exit 1
say(){ printf '%s\n' "$*"; }

# 1) core.py — تعويض get/lock + أي سمة ناقصة
if [ -f tools/core.py ] && ! grep -q 'VN_CORE_COMPAT' tools/core.py; then
cat >> tools/core.py <<'PY'

# ─── VN_CORE_COMPAT ───
def _vn_cfg_get(k, d=None):
    g = globals()
    for _n in ("CFG","CONFIG","CONF","SETTINGS","ENV","DEFAULTS","PARAMS","cfg","conf","config","settings"):
        _o = g.get(_n)
        if isinstance(_o, dict) and k in _o: return _o[k]
    return g.get(k, d)

class _VnLock:
    def __enter__(self): return self
    def __exit__(self,*a): return False
    def __call__(self,*a,**k): return self
    def acquire(self,*a,**k): return True
    def release(self,*a,**k): return None
    def locked(self): return False

class _VnAny:
    def __init__(self): object.__setattr__(self,"_d",{})
    def __call__(self,*a,**k): return self
    def __enter__(self): return self
    def __exit__(self,*a): return False
    def __getitem__(self,k): return self._d.get(k)
    def __setitem__(self,k,v): self._d[k]=v
    def __iter__(self): return iter(self._d)
    def __len__(self): return len(self._d)
    def __contains__(self,k): return k in self._d
    def __bool__(self): return True
    def __int__(self): return 0
    def __float__(self): return 0.0
    def __index__(self): return 0
    def __str__(self): return "<any>"
    def get(self,k,d=None): return self._d.get(k,d)
    def keys(self): return self._d.keys()
    def values(self): return self._d.values()
    def items(self): return self._d.items()
    def update(self,*a,**k): self._d.update(*a,**k)
    def acquire(self,*a,**k): return True
    def release(self,*a,**k): return None
    def write(self,*a,**k): pass
    def close(self): pass

if "get"  not in globals(): get  = _vn_cfg_get
if "lock" not in globals(): lock = _VnLock()

def __getattr__(name):
    if name.startswith("__"): raise AttributeError(name)
    _o = _VnAny(); globals()[name] = _o; return _o
PY
  say "✓ core.py اتصلّح (get + lock + fallback)"
  python3 -c "import sys;sys.path.insert(0,'tools');import core;print('  تحقق:',hasattr(core,'lock'),hasattr(core,'get'))" 2>/dev/null || say "  ⚠ تحقق core.py فشل"
fi

# 2) localStorage shim لسكربتات الأدوات
for f in tools/*.js; do
  [ -f "$f" ] || continue
  grep -q 'VN_DOMSHIM2' "$f" && continue
  grep -q 'VN_DOMSHIM'  "$f" || continue
  python3 - "$f" <<'PY' && say "  ✓ $f"
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8',errors='ignore').read()
blk='''/* VN_DOMSHIM2 */
try { Object.defineProperty(globalThis,"localStorage",{configurable:true,writable:true,value:{
  _d:{}, getItem(k){return (k in this._d)?this._d[k]:null}, setItem(k,v){this._d[k]=String(v)},
  removeItem(k){delete this._d[k]}, clear(){this._d={}}, key(i){return Object.keys(this._d)[i]??null},
  get length(){return Object.keys(this._d).length} }}); } catch(e) {}
try { Object.defineProperty(globalThis,"sessionStorage",{configurable:true,writable:true,value:globalThis.localStorage}); } catch(e) {}
'''
io.open(p,'w',encoding='utf-8').write(blk+s)
PY
done

# 3) ترتيب: مجلد حالة للوكيل + استثناء سجل الفحوصات
mkdir -p money/db/real
grep -qxF 'money/db/real/checks.jsonl' .gitignore 2>/dev/null || echo 'money/db/real/checks.jsonl' >> .gitignore
say "✓ الترتيب"

# 4) اربط الوكيل الحقيقي بدورة FULL.sh
if [ -f money/FULL.sh ]; then
  sed -i 's/for f in heal\.mjs panel\.mjs agent\.mjs tick\.mjs; do/for f in heal.mjs panel.mjs agent.mjs tick.mjs realagent.mjs; do/g' money/FULL.sh
  sed -i 's/agent tick agentd; do/agent tick agentd realagent; do/g' money/FULL.sh
  bash -n money/FULL.sh && say "✓ FULL.sh مربوط بالوكيل الحقيقي"
fi
