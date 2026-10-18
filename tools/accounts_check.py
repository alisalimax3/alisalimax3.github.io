#!/usr/bin/env python3
"""يتحقق من كل رابط منصة بحقيقة الشبكة: حالة HTTP + زمن + شهادة. يكتب accounts-status.json"""
import json,os,urllib.request,datetime,socket
from concurrent.futures import ThreadPoolExecutor
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA={'User-Agent':'Mozilla/5.0 (CineHub3099 verifier)'}
def chk(u):
    t0=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    for meth in ('HEAD','GET'):
        try:
            rq=urllib.request.Request(u,headers=UA,method=meth)
            r=urllib.request.urlopen(rq,timeout=18)
            return {'url':u,'code':r.status,'ms':int((datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)-t0).total_seconds()*1000),'ok':r.status<400}
        except Exception as e:
            c=getattr(e,'code',None)
            if c and c<400: return {'url':u,'code':c,'ms':0,'ok':True}
            last={'url':u,'code':c or 'ERR','ms':0,'ok':False,'err':type(e).__name__}
    return last
SCOPE=os.environ.get('SCOPE','programs'); LIM=int(os.environ.get('LIMIT','0'))
j=json.load(open(os.path.join(R,'platforms.json'),encoding='utf-8'))
P=j.get('platforms',[])
if SCOPE=='programs': P=[x for x in P if x.get('c')!='entity']
if LIM: P=P[:LIM]
with ThreadPoolExecutor(24) as ex: res=list(ex.map(chk,[p['u'] for p in P]))
for p,r in zip(P,res): p['status']=r.get('code'); p['ok']=r.get('ok'); p['ms']=r.get('ms',0)
live=sum(1 for r in res if r['ok'])
j['total']=len(P); j['live']=live; j['checked']=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ')
json.dump(j,open(os.path.join(R,'platforms.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
json.dump({'t':j['checked'],'total':len(P),'live':live,'dead':len(P)-live,
 'dead_list':[{'n':p['n'],'u':p['u'],'code':p.get('status')} for p,r in zip(P,res) if not r['ok']]},
 open(os.path.join(R,'accounts-status.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('مصادقة: %d/%d رابطًا يعمل'%(live,len(P)))
