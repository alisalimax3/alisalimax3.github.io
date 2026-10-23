import io,os,re,json
M=os.environ['M']; A=[];S=[];F=[]
def p(r): return os.path.join(M,r)
def rd(x): return io.open(x,encoding='utf-8',errors='surrogateescape').read()
def wr(x,s): io.open(x,'w',encoding='utf-8',errors='surrogateescape').write(s)
def iife(s):
    return re.compile(r'=\s*\(\)\s*=>\s*\{(?P<b>.*?)\}\s*\(\s*\)\s*;',re.S).subn(lambda m:'= (()=>{'+m.group('b')+'})();',s)
def fixnl(s):
    o=[];i=0;q=None
    while i<len(s):
        c=s[i]
        if q:
            o.append(c)
            if c=='\\' and i+1<len(s): o.append(s[i+1]); i+=2; continue
            if c==q: q=None
            i+=1; continue
        if c in '"\'`': q=c; o.append(c); i+=1; continue
        if c=='\\' and i+1<len(s) and s[i+1] in 'nt':
            o.append('\n' if s[i+1]=='n' else '\t'); i+=2; continue
        o.append(c); i+=1
    return ''.join(o)

# القاتل 1: q-db.js IIFE
x=p('lib/q-db.js')
if os.path.isfile(x):
    s=rd(x); s2,n=iife(s)
    (wr(x,s2),A.append('q-db.js IIFE x%d'%n)) if n else S.append('q-db.js نظيف')
# القاتل 2: q-load.js path
x=p('lib/q-load.js')
if os.path.isfile(x):
    s=rd(x)
    if 'path.join' in s and 'require("path")' not in s and "require('path')" not in s:
        i=s.index('\n')+1 if s.startswith('#!') else 0
        wr(x,s[:i]+'const path=require("path");\n'+s[i:]); A.append('q-load.js require(path)')
    else: S.append('q-load.js ok')
# SKIP
x=p('lib/q-util.js')
if os.path.isfile(x):
    s=rd(x)
    if '.tmp' in s and 'data/profiles' in s: S.append('q-util SKIP ok')
    else:
        add='".tmp","data/profiles",".check","dist","build",".venv",".npm","node_modules"'
        m=re.search(r'(SKIP\s*=\s*new\s+Set\s*\(\s*\[)([^\]]*)(\]\s*\))',s) or re.search(r'(SKIP\s*=\s*\[)([^\]]*)(\])',s)
        if m: wr(x,s[:m.start(3)]+(','+add if m.group(2).strip() and not m.group(2).rstrip().endswith(',') else add)+s[m.start(3):]); A.append('q-util SKIP')
        else: S.append('q-util SKIP no-match')
# node -> process.execPath
for r in ('lib/q-lint.js','lib/q-fix.js'):
    x=p(r)
    if not os.path.isfile(x): S.append(r+' missing'); continue
    s=rd(x); o=s
    s=s.replace('spawnSync("node"','spawnSync(process.execPath').replace("spawnSync('node'","spawnSync(process.execPath")
    s=re.sub(r'(spawnSync\(\s*)(["\'])node\2',r'\1process.execPath',s)
    s=re.sub(r'(execFileSync\(\s*)(["\'])node\2',r'\1process.execPath',s)
    (wr(x,s),A.append(r+' execPath')) if s!=o else S.append(r+' no-match')
# q-sec فلتر
x=p('lib/q-sec.js')
if os.path.isfile(x):
    s=rd(x)
    if '_NAME|' in s: S.append('q-sec ok')
    else:
        m=re.search(r'secrets\.push\((\w+)\)',s)
        if m:
            v=m.group(1)
            wr(x,s[:m.start()]+'if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER|PORT)$/i.test(String(%s)))'%v+s[m.start():]); A.append('q-sec filter')
        else: S.append('q-sec no-match')
# async.js
x=p('lib/async.js')
if os.path.isfile(x):
    s=rd(x); o=s
    s=re.sub(r'console\.log\(ok\?([^:\n]*):([^\n]*)\);',r'console.log(ok?(\1):(\2));',s)
    (wr(x,s),A.append('async.js')) if s!=o else S.append('async.js ok')
# rewarded.js
x=p('lib/rewarded.js')
if os.path.isfile(x):
    s=rd(x); o=s
    s=re.sub(r'return\s+n\.enabled\s*&&\s*n\.keys\.popunder\s*\)\s*\[0\]','return n.enabled&&n.keys.popunder;})[0]',s)
    (wr(x,s),A.append('rewarded.js')) if s!=o else S.append('rewarded.js ok')
# payout.js
x=p('lib/payout.js')
if os.path.isfile(x):
    s=rd(x); s2=fixnl(s)
    (wr(x,s2),A.append('payout.js nl')) if s2!=s else S.append('payout.js ok')
# catalog.json
x=p('data/catalog.json')
if os.path.isfile(x):
    s=rd(x); o=s
    for _ in range(6):
        s2=re.sub(r',(\s*[}\]])',r'\1',s)
        if s2==s: break
        s=s2
    if s!=o:
        try: json.loads(s); wr(x,s); A.append('catalog.json')
        except Exception as e: S.append('catalog.json '+str(e)[:40])
    else: S.append('catalog.json ok')
# CORS مقيّد (اختياري بعلامة)
for r in ('lib/agent-core.js','lib/gateway.js'):
    x=p(r)
    if not os.path.isfile(x): continue
    s=rd(x)
    if "Access-Control-Allow-Origin" in s and 'APEX_CORS_ORIGIN' not in s:
        s=re.sub(r"(['\"])Access-Control-Allow-Origin\1\s*:\s*['\"][^'\"]*['\"]",
                 lambda m:m.group(0).replace(m.group(0).split(':')[1].strip(),
                 "process.env.APEX_CORS_ORIGIN||'*'"),s)
        wr(x,s); A.append(r+' CORS env')
# .gitignore
x=p('.gitignore'); cur=rd(x) if os.path.isfile(x) else ''
need=['*.pid','_backup/','_deploy/','.check/','*.log','.tmp/','data/profiles/','money/apex/state/','money/apex/dlq/','money/logs/','node_modules/','*.bak']
add=[n for n in need if n not in cur]
if add: wr(x,cur.rstrip()+'\n'+'\n'.join(add)+'\n'); A.append('.gitignore +%d'%len(add))
else: S.append('.gitignore ok')
# keys.env
x=p('keys.env')
if os.path.isfile(x):
    s=re.sub(r'[ \t]+(?=[A-Z][A-Z0-9_]{2,}=)','\n',rd(x)); s=re.sub(r'\n{2,}','\n',s)
    wr(x,s); os.chmod(x,0o600); A.append('keys.env normalize')
for r in ('secrets.json','data/kyc.html'):
    if os.path.isfile(p(r)): os.chmod(p(r),0o600)
# logo
d=os.path.join(M,'assets'); os.path.isdir(d) or os.makedirs(d)
lp=os.path.join(d,'logo.png')
if not os.path.isfile(lp) or os.path.getsize(lp)<100:
    import base64
    io.open(lp,'wb').write(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAXklEQVR42u3PMQEAAAgDoJnc6BpjDyQgd1MFAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEHAeWLwAAdZ0b2sAAAAASUVORK5CYII='))
    A.append('assets/logo.png')
print('APPLIED: '+(' | '.join(A) or '-'))
print('SKIPPED: '+(' | '.join(S) or '-'))
