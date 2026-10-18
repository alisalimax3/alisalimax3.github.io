#!/usr/bin/env python3
import os,re,json,urllib.request,subprocess
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def sh(c):
    return subprocess.run(c,shell=True,capture_output=True,text=True,cwd=R).stdout.strip()
url=sh('git remote get-url origin')
m=re.search(r'https://([^:]+):([^@]+)@',url)
tok=m.group(2) if m else ''
if not tok and os.path.exists(os.path.expanduser('~/.git-token')):
    tok=open(os.path.expanduser('~/.git-token')).read().strip()
if not tok: print('  ! لا توكن — الدورات ستعمل بالموعد المجدول'); raise SystemExit
def post(path,body=None):
    u='https://api.github.com/repos/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io/'+path
    rq=urllib.request.Request(u,data=json.dumps(body or {'ref':'main'}).encode(),
      headers={'Authorization':'token '+tok,'Accept':'application/vnd.github+json','Content-Type':'application/json'})
    try:
        r=urllib.request.urlopen(rq,timeout=25); return r.status
    except Exception as e: return getattr(e,'code',str(e)[:40])
for w in ('ingest.yml','pulse.yml','apply-keys.yml','verify-links.yml','ping.yml','tick.yml'):
    print('  %s → %s'%(w,post('actions/workflows/%s/dispatches'%w)))
