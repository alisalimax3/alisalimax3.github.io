#!/usr/bin/env python3
import os,json,glob,datetime
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rd(p,d=None):
    try:return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception:return d
c=rd('ads-config.json',{}) or {}; n=rd('networks.json',{'networks':[]}) or {'networks':[]}
s=rd('shorteners.json',{'shorteners':[]}) or {'shorteners':[]}; o=rd('owner.json',{}) or {}
p=rd('platforms.json',{'platforms':[]}) or {'platforms':[]}
K=rd('keys.env',{}) or {}
def has(fld): return bool(o.get(fld))
h={'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),
 'banner_keys':sum(1 for v in (c.get('banners') or {}).values() if v.get('key')),
 'nets_enabled':sum(1 for x in n.get('networks',[]) if x.get('enabled')),
 'nets_with_keys':sum(1 for x in n.get('networks',[]) if any((x.get('keys') or {}).values())),
 'shorteners_with_uid':sum(1 for x in s.get('shorteners',[]) if x.get('uid')),
 'smartlinks':len([k for k,v in (s.get('smartlinks') or {}).items() if v]),
 'platforms':len(p.get('platforms',[])),'platforms_live':p.get('live',0),
 'entities':sum(1 for x in p.get('platforms',[]) if x.get('c')=='entity'),
 'kuraimi':has('kuraimi_account'),'whatsapp':has('whatsapp'),
 'turnstile':bool((o.get('captcha') or {}).get('turnstile_site')),
 'supabase':has('supabase_url'),'apps_script':has('endpoint'),
 'workflows':len(glob.glob(os.path.join(R,'.github/workflows/*.yml'))),
 'catalog':(rd('data/catalog-index.json',{}) or {}).get('total',0)}
h['ready_score']=sum([h['banner_keys']>0,h['nets_with_keys']>0,h['shorteners_with_uid']>0,
 h['smartlinks']>0,h['kuraimi'],h['whatsapp'],h['turnstile'],h['supabase'],h['apps_script']])
json.dump(h,open(os.path.join(R,'health.json'),'w',encoding='utf-8'),indent=1)
print('health: %d/9 جاهز · %d جهة (%d مؤسسة) · %d workflow'%(h['ready_score'],h['platforms'],h['entities'],h['workflows']))
