#!/usr/bin/env python3
"""يجلب زونات Adsterra من الـAPI ويملأ مفاتيح البانرات تلقائيًا — بلا نسخ يدوي"""
import os,json,urllib.request,re
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
K={}
if os.path.exists(os.path.join(R,'keys.env')):
    for l in open(os.path.join(R,'keys.env'),encoding='utf-8'):
        if '=' in l and not l.strip().startswith('#'):
            a,b=l.split('=',1); K[a.strip()]=b.strip()
key=K.get('ADSTERRA_API_KEY','')
if not key: print('  ! لا مفتاح Adsterra — تخطّي'); raise SystemExit
def get(u):
    rq=urllib.request.Request(u,headers={'X-API-Key':key,'Accept':'application/json'})
    return json.loads(urllib.request.urlopen(rq,timeout=30).read().decode())
found={}
for ep,fields in (('placements','id,name,size,type'),('domains','id,name')):
    try:
        j=get('https://api3.adsterratools.com/publisher/%s.json'%ep)
        items=j.get('items') or j.get('placements') or (j if isinstance(j,list) else [])
        for it in items if isinstance(items,list) else []:
            if not isinstance(it,dict): continue
            n=(it.get('name') or '')+' '+(str(it.get('size') or ''))+' '+(str(it.get('type') or ''))
            pid=it.get('id')
            if not pid: continue
            low=n.lower()
            if '728' in low or '970' in low: found.setdefault('ADSTERRA_BANNER_TOP',pid)
            elif '300x250' in low or '336' in low: found.setdefault('ADSTERRA_BANNER_MID',pid)
            elif '160' in low or '300x600' in low: found.setdefault('ADSTERRA_BANNER_SIDE',pid)
            elif '320' in low or 'mobile' in low: found.setdefault('ADSTERRA_BANNER_MOBILE',pid)
            elif 'pop' in low: found.setdefault('ADSTERRA_POPUNDER',pid)
            elif 'social' in low or 'bar' in low: found.setdefault('ADSTERRA_SOCIALBAR',pid)
            elif 'push' in low or 'inpage' in low or 'in-page' in low: found.setdefault('ADSTERRA_INPAGE',pid)
    except Exception as e: print('  !',ep,type(e).__name__)
if not found: print('  ! لم تُقرأ زونات — املأها يدويًا في keys.env'); raise SystemExit
lines=open(os.path.join(R,'keys.env'),encoding='utf-8').read().split('\n')
have={}
for l in lines:
    if '=' in l and not l.strip().startswith('#'):
        a,b=l.split('=',1); have[a.strip()]=b.strip()
n=0
for k,v in found.items():
    if not have.get(k): have[k]=str(v); n+=1
order=[l.split('=')[0].strip() for l in lines if '=' in l and not l.strip().startswith('#')]
for k in have:
    if k not in order: order.append(k)
open(os.path.join(R,'keys.env'),'w',encoding='utf-8').write('# CineHub 3099 — مصفوفة المفاتيح\n'+'\n'.join('%s=%s'%(k,have.get(k,'')) for k in order)+'\n')
print('  ✓ مُلئت %d خانة تلقائيًا من Adsterra API:'%n,', '.join(found.keys()))
