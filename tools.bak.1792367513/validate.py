#!/usr/bin/env python3
import sys,json,re,urllib.request
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)','Accept':'application/json'}
def get(u,h=None):
    return urllib.request.urlopen(urllib.request.Request(u,headers=h or UA),timeout=25)
def post(u,d,h=None):
    hh={'Content-Type':'application/json'}; hh.update(h or {})
    return urllib.request.urlopen(urllib.request.Request(u,data=json.dumps(d).encode(),headers=hh),timeout=25)
t=sys.argv[1]; v=sys.argv[2].strip(); r={'ok':True,'extra':''}
try:
    if t=='github_token':
        x=get('https://api.github.com/user',{'Authorization':'token '+v,'User-Agent':'x'})
        sc=x.headers.get('x-oauth-scopes','') or ''
        j=json.loads(x.read().decode())
        miss=[s for s in ('repo','workflow') if s not in sc]
        r={'ok':not miss,'extra':'الحساب: %s · الصلاحيات: %s'%(j.get('login'),sc or '—'),
           'err':('ناقص صلاحية: '+','.join(miss)) if miss else ''}
    elif t=='adsterra_key':
        x=get('https://api3.adsterratools.com/publisher/stats.json?start_date=2024-01-01&finish_date=2030-01-01&group_by=date',
              {'X-API-Key':v,'Accept':'application/json'})
        r={'ok':x.status==200,'extra':'استجابة %s'%x.status}
    elif t=='adsterra_pubid': r={'ok':bool(re.match(r'^\d{3,}$',v))}
    elif t=='turnstile_site': r={'ok':len(v)>18}
    elif t=='turnstile_secret': r={'ok':len(v)>18}
    elif t=='supabase': r={'ok':bool(re.match(r'^https://[a-z0-9]+\.supabase\.co',v))}
    elif t=='apps_script': r={'ok':'script.google.com' in v}
    elif t=='url': r={'ok':bool(re.match(r'^https://',v))}
    elif t=='phone':
        d=re.sub(r'\D','',v); r={'ok':8<=len(d)<=15,'extra':'الرقم: '+d}
    elif t=='uid': r={'ok':bool(re.match(r'^[A-Za-z0-9@._+-]{2,64}$',v))}
    elif t=='email': r={'ok':bool(re.match(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$',v))}
    elif t=='email_or_uid': r={'ok':len(v)>=2}
    elif t=='pin': r={'ok':len(v)>=4}
except Exception as e:
    r={'ok':False,'err':'%s: %s'%(type(e).__name__,str(e)[:60])}
print(json.dumps(r,ensure_ascii=False))
