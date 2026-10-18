#!/usr/bin/env python3
import os,json,urllib.request,urllib.parse,datetime,subprocess,importlib.util as iu
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def wr(p,o): json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
def rd(p,d=None):
    try:return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception:return d
now=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ')
st={'t':now,'ok':False,'turnstile':'skipped','keys_applied':0,'health_score':0,'missing':[],'steps':[]}
tok=os.environ.get('TT_TOKEN',''); sec=os.environ.get('TT_SECRET','')
if sec and tok:
    try:
        rq=urllib.request.Request('https://challenges.cloudflare.com/turnstile/v0/siteverify',
          data=urllib.parse.urlencode({'secret':sec,'response':tok}).encode())
        j=json.loads(urllib.request.urlopen(rq,timeout=25).read().decode())
        st['turnstile']='passed' if j.get('success') else 'failed'
        st['steps'].append('turnstile:'+st['turnstile'])
    except Exception as e:
        st['turnstile']='error'; st['steps'].append('turnstile:error '+type(e).__name__)
elif sec: st['turnstile']='no-token'
else: st['turnstile']='no-secret'
for tool,args in (('tools/apply_keys.py',[]),('tools/adsterra_autokeys.py',[]),('tools/apply_keys.py',[])):
    try:
        r=subprocess.run(['python3',tool]+args,capture_output=True,text=True,cwd=R,timeout=180)
        st['steps'].append('%s rc=%d'%(tool,r.returncode))
    except Exception as e: st['steps'].append('%s ERR %s'%(tool,type(e).__name__))
for tool in ('tools/health.py','tools/ledger.py','tools/credit.py'):
    try:
        subprocess.run(['python3',tool],capture_output=True,text=True,cwd=R,timeout=120)
    except Exception: pass
h=rd('health.json',{}) or {}
st['health_score']=h.get('ready_score',0)
st['missing']=[k for k in ('banner_keys','nets_with_keys','shorteners_with_uid','kuraimi','whatsapp','turnstile','supabase','apps_script') if not h.get(k)]
st['ok']=True
wr('setup-status.json',st)
print('setup-status:',st['turnstile'],'score',st['health_score'],'missing',len(st['missing']))
