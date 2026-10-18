#!/usr/bin/env python3
"""نبضة كل 5 دقائق: تقرأ الحقيقة، تكتب live.json + live.jsonl + ACTIVITY.md + insights.json"""
import os,json,datetime,urllib.request,statistics
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L=os.path.join(R,'live'); os.makedirs(L,exist_ok=True)
def rd(p,d=None):
    try:return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception:return d
def wr(p,o):json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
now=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None); ts=now.strftime('%FT%TZ')
rev=rd('revenue.json',{}) or {}; tre=rd('treasury.json',{}) or {}
live=rd('live.json',{'points':[],'last_rev':0,'seq':0}) or {'points':[],'last_rev':0,'seq':0}
views=None
for u in ('https://abacus.jasoncameron.dev/get/cinehub3099/views','https://api.counterapi.dev/v1/cinehub3099/views/'):
    try:
        r=urllib.request.urlopen(u,timeout=15).read().decode()
        j=json.loads(r); views=j.get('value',j.get('count')); break
    except Exception: pass
clk=None
try:
    r=urllib.request.urlopen('https://abacus.jasoncameron.dev/get/cinehub3099/outclicks',timeout=15).read().decode()
    clk=json.loads(r).get('value')
except Exception: pass
r=float(rev.get('revenue') or 0)
delta=round(r-float(live.get('last_rev') or 0),6)
p={'t':ts,'rev':r,'imp':int(rev.get('impressions') or 0),'clk':int(rev.get('clicks') or 0),
   'views':views,'outclicks':clk,'delta':delta,'nets':list((rev.get('networks') or {}).keys())}
live['points']=(live.get('points') or [])[-287:]+[p]
live['last_rev']=r; live['seq']=(live.get('seq') or 0)+1; live['t']=ts
live['rev']=r; live['imp']=p['imp']; live['views']=views
wr('live.json',live)
open(os.path.join(L,'%s.jsonl'%now.strftime('%Y-%m')),'a',encoding='utf-8').write(json.dumps(p,ensure_ascii=False)+'\n')
try:
    import importlib.util as iu
    sp=iu.spec_from_file_location('led',os.path.join(R,'tools','ledger.py'));m=iu.module_from_spec(sp);sp.loader.exec_module(m)
    for k,v in (rev.get('networks') or {}).items():
        if v.get('revenue'): m.add('net_'+k,v['revenue'],k,{'imp':v.get('impressions',0)})
    if delta>0: m.add('pulse_delta',delta,'delta',{})
    tot,bad=m.verify(); wr('ledger-index.json',{'t':ts,'entries':tot,'broken':bad,'chain':'sha256'})
except Exception as e: pass
line='- %s · إيراد $%.6f · ظهور %d · نقرات %d · زيارات عالمية %s · قيود %d'%(
 ts,r,p['imp'],p['clk'],views if views is not None else '—',(rd('ledger-index.json',{}) or {}).get('entries',0))
f=os.path.join(R,'ACTIVITY.md')
if not os.path.exists(f): open(f,'w',encoding='utf-8').write('# سجل النشاط التلقائي\n\n> يُكتب وحده كل 5 دقائق. هذا ما يجعلك ترى الأثر لحظة بلحظة.\n\n')
open(f,'a',encoding='utf-8').write(line+'\n')
h=rd('health.json',{}) or {}
ins={'t':ts,'score':h.get('ready_score',0),
 'verdict':'مكتمل' if (h.get('ready_score',0)>=6) else 'ينقص تفعيل',
 'missing':[k for k in ('banner_keys','nets_with_keys','shorteners_with_uid','kuraimi','whatsapp','turnstile','supabase','apps_script') if not h.get(k)],
 'top_source':max((rev.get('networks') or {}).items(),key=lambda x:x[1].get('revenue',0))[0] if (rev.get('networks')) else None,
 'rev_24h':round(sum(x.get('delta',0) for x in (live.get('points') or [])),6),
 'views_global':views,'pulses':live.get('seq',0)}
wr('insights.json',ins)
wr('pulse.json',{'t':ts,'seq':live['seq'],'next':'+5 دقائق'})
print('pulse #%d · rev $%.6f · delta %.6f · views %s'%(live['seq'],r,delta,views))
