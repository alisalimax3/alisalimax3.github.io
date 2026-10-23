import io,os,re
M=os.environ['M'];A=[];S=[]
def p(r): return os.path.join(M,r)
def rd(x): return io.open(x,encoding='utf-8',errors='surrogateescape').read()
def wr(x,s): io.open(x,'w',encoding='utf-8',errors='surrogateescape').write(s)
def split_top(s):
    d=0;q=None;qi=None
    for k,c in enumerate(s):
        if q:
            if c=='\\':continue
            if c==q:q=None
            continue
        if c in '"\'`':q=c;continue
        if c in '([{':d+=1
        elif c in ')]}':d-=1
        elif c=='?' and d==0:qi=k;break
    if qi is None:return None
    d=0;q=None;ci=None
    for k in range(qi+1,len(s)):
        c=s[k]
        if q:
            if c=='\\':continue
            if c==q:q=None
            continue
        if c in '"\'`':q=c;continue
        if c in '([{':d+=1
        elif c in ')]}':d-=1
        elif c==':' and d==0:ci=k;break
    if ci is None:return None
    return s[:qi],s[qi+1:ci],s[ci+1:]
def fixlog(line):
    i=line.find('console.log(')
    if i<0:return line
    st=i+len('console.log(');d=1;q=None;j=st
    while j<len(line):
        c=line[j]
        if q:
            if c=='\\':j+=2;continue
            if c==q:q=None
        elif c in '"\'`':q=c
        elif c=='(':d+=1
        elif c==')':
            d-=1
            if d==0:break
        j+=1
    inner=line[st:j]
    if '?' not in inner:return line
    sp=split_top(inner)
    if not sp:return line
    cond,t,f=sp
    t=t if t.strip().startswith('(') and t.strip().endswith(')') else '('+t+')'
    f=f if f.strip().startswith('(') and f.strip().endswith(')') else '('+f+')'
    return line[:i]+'console.log('+cond+'?'+t+':'+f+')'+line[j+1:]

x=p('lib/async.js')
if os.path.isfile(x):
    L=rd(x).split('\n');n=0
    for k in range(len(L)):
        if 'console.log(' in L[k] and '?' in L[k]:
            o=L[k];L[k]=fixlog(L[k])
            if L[k]!=o:n+=1
    if n:wr(x,'\n'.join(L));A.append('async.js x%d'%n)
    else:S.append('async.js نظيف')

# q-sec: ابحث عن الدالة التي تُجمّع الأسرار ثم اطبع ما وجد
x=p('lib/q-sec.js')
if os.path.isfile(x):
    s=rd(x)
    if '_NAME|' in s and 'APEX' not in s: S.append('q-sec فلتر موجود')
    else:
        cands=re.findall(r'(\w+)\.push\(',s)
        A.append('q-sec arrays='+(','.join(sorted(set(cands))) or '-'))
        if cands and '_NAME|' not in s:
            arr=cands[0];arg=None
            m=re.search(r'\b'+arr+r'\.push\(([^;]+?)\)\s*;',s)
            if m:
                arg=m.group(1)
                guard='{const _s=('+arg+');if(!/_(NAME|EMAIL|USER|DOMAIN|URL|HOST|ID|CHAT_ID|HANDLE|ADDRESS|BRANCH|NUMBER|PORT|CURRENCY|TYPE|MODE|ENV)$/i.test(String(_s)))'+arr+'.push(_s);}'
                wr(x,s[:m.start()]+guard+s[m.end():]);A.append('q-sec فلتر('+arr+')')

for r in ('lib/q-lint.js','lib/q-fix.js'):
    x=p(r)
    if not os.path.isfile(x):S.append(r+' مفقود');continue
    s=rd(x);o=s
    s=re.sub(r'(spawnSync|execFileSync|spawn|execSync)\s*\(\s*(["\'])node\2',r'\1(\2"+"',s)
    s=re.sub(r'(["\'])\s*\+\s*""\s*\+\s*(["\'])',r'\1+\2',s)
    s=s.replace('""+','').replace('+""','')
    s=re.sub(r'(["\'])node --check\1',r'\1" + process.execPath + " --check\1',s)
    s=re.sub(r'(["\'])node\b',r'\1" + process.execPath + "',s)
    s=re.sub(r'(\w+)\s*\+\s*"([^"]*)"\s*\+\s*"([^"]*)"',r'\1+"\2\3"',s)
    s=re.sub(r'\(\s*"\s*\+\s*process\.execPath',r'(process.execPath',s)
    if 'process.execPath' in s and s!=o:
        wr(x,s);A.append(r+' execPath')
    else:S.append(r+' لا تغيير')
print('APPLIED: '+(' | '.join(A) or '-'))
print('SKIPPED: '+(' | '.join(S) or '-'))
