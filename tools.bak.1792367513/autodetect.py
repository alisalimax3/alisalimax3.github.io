#!/usr/bin/env python3
"""يجرب كل قيمة في keys.env على الواجهات الحقيقية ليعرف نوعها ثم يربطها. لا تخمين: كل ربط بدليل استجابة."""
import os,json,re,urllib.request,urllib.parse,subprocess
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rd(p,d):
    try:return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception:return d
def wr(p,o):json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
K={}
if os.path.exists(os.path.join(R,'keys.env')):
    for l in open(os.path.join(R,'keys.env'),encoding='utf-8'):
        l=l.strip()
        if l and not l.startswith('#') and '=' in l:
            a,b=l.split('=',1); K[a.strip()]=b.strip()
rep={'found':[],'tested':{},'wired':[]}
def head(u,h=None,t=20):
    try:
        r=urllib.request.urlopen(urllib.request.Request(u,headers=h or {'User-Agent':'ch'}),timeout=t)
        return r.status,r.read(300).decode('utf-8','ignore')
    except Exception as e: return getattr(e,'code',0),str(e)[:60]
def setk(k,v,why):
    if K.get(k)==v: return
    K[k]=v; rep['wired'].append('%s ← %s (%s)'%(k,why,'ok'))
# ---- Adsterra ----
av=K.get('ADSTERRA','') or K.get('ADSTERRA_API_KEY','')
if av:
    st,body=head('https://api3.adsterratools.com/publisher/stats.json?start_date=2024-01-01&finish_date=2030-01-01&group_by=date',{'X-API-Key':av,'Accept':'application/json'})
    rep['tested']['ADSTERRA']='stats %s'%st
    if st==200:
        setk('ADSTERRA_API_KEY',av,'نداء API ناجح')
        try:
            j=json.loads(urllib.request.urlopen(urllib.request.Request(
              'https://api3.adsterratools.com/publisher/placements.json',headers={'X-API-Key':av,'Accept':'application/json'}),timeout=25).read().decode())
            items=j.get('items') or (j if isinstance(j,list) else [])
            for it in items:
                if not isinstance(it,dict): continue
                n=((it.get('name') or '')+' '+str(it.get('size') or '')+' '+str(it.get('type') or '')).lower(); pid=it.get('id')
                if not pid: continue
                if '728' in n or '970' in n: setk('ADSTERRA_BANNER_TOP',str(pid),'زونة من API')
                elif '300x250' in n or '336' in n: setk('ADSTERRA_BANNER_MID',str(pid),'زونة من API')
                elif '160' in n or '600' in n: setk('ADSTERRA_BANNER_SIDE',str(pid),'زونة من API')
                elif '320' in n or 'mobile' in n: setk('ADSTERRA_BANNER_MOBILE',str(pid),'زونة من API')
                elif 'pop' in n: setk('ADSTERRA_POPUNDER',str(pid),'زونة من API')
                elif 'social' in n or 'bar' in n: setk('ADSTERRA_SOCIALBAR',str(pid),'زونة من API')
                elif 'push' in n: setk('ADSTERRA_INPAGE',str(pid),'زونة من API')
        except Exception as e: rep['tested']['placements']=type(e).__name__
    elif re.match(r'^\d{3,}$',av): setk('ADSTERRA_PUB_ID',av,'أرقام = معرّف ناشر')
    elif re.match(r'^[A-Za-z0-9]{16,48}$',av): setk('ADSTERRA_BANNER_MID',av,'مفتاح زونة')
# ---- TMDB ----
tv=K.get('TMDB_KEY','') or K.get('TMDB_API_KEY','')
if tv:
    st,_=head('https://api.themoviedb.org/3/configuration?api_key='+urllib.parse.quote(tv))
    rep['tested']['TMDB_KEY']='configuration %s'%st
    if st==200: setk('TMDB_KEY',tv,'نداء TMDB ناجح')
# ---- ExoClick / Worker / معالجات الدفع ----
for raw,to in (('EXOCLICK','EXOCLICK_ZONE'),('WORKER','WORKER_URL'),('CCBILL','CCBILL_ACCOUNT'),('SEGPAY','SEGPAY_ACCOUNT')):
    if K.get(raw) and not K.get(to): setk(to,K[raw],'اسم بديل')
o=rd('owner.json',{}) or {}
o.setdefault('extra',{})
for k in ('WORKER_URL','EXOCLICK_ZONE','CCBILL_ACCOUNT','SEGPAY_ACCOUNT','TMDB_KEY'):
    if K.get(k): o['extra'][k]=K[k]
wr('owner.json',o)
order=['ADSTERRA_API_KEY','ADSTERRA_PUB_ID','ADSTERRA_BANNER_TOP','ADSTERRA_BANNER_MID','ADSTERRA_BANNER_SIDE','ADSTERRA_BANNER_MOBILE','ADSTERRA_POPUNDER','ADSTERRA_SOCIALBAR','ADSTERRA_INPAGE','TMDB_KEY','EXOCLICK_ZONE','WORKER_URL','CCBILL_ACCOUNT','SEGPAY_ACCOUNT','MONETAG_API_KEY','MONETAG_MULTITAG','MONETAG_REWARDED_ZONE','PROPELLER_API_KEY','POPADS_API_KEY','LINKVERTISE_UID','WORKINK_UID','SHRINKME_UID','SHRINKERN_UID','CLKSH_UID','GPLINKS_UID','CPAGRIP_SMARTLINK','OGADS_SMARTLINK','ADSENSE_CLIENT','TURNSTILE_SITE','TURNSTILE_SECRET','SUPABASE_URL','SUPABASE_ANON','APPS_SCRIPT_URL','OWNER_WHATSAPP','OWNER_TELEGRAM','OWNER_EMAIL','KURAIMI_NAME','KURAIMI_ACCOUNT','KURAIMI_PHONE','USDT_TRC20']
for k in K:
    if k not in order: order.append(k)
open(os.path.join(R,'keys.env'),'w',encoding='utf-8').write('# CineHub 3099 — كُتب آليًا بواسطة autodetect\n'+'\n'.join('%s=%s'%(k,K.get(k,'')) for k in order)+'\n')
wr('data/autodetect-report.json',rep)
print('  جُرّبت:',len(rep['tested']),'· رُبطت:',len(rep['wired']))
for w in rep['wired'][:12]: print('     ✓',w)
for k,v in rep['tested'].items(): print('     ·',k,'→',v)
