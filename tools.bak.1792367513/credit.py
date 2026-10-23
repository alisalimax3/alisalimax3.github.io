#!/usr/bin/env python3
"""يدمج الأرباح الخارجية الحقيقية في الخزينة والسجل الموثّق"""
import json,os,datetime,importlib.util as iu
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rd(p,d):
    try:return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception:return d
def wr(p,o):json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
e=rd('external-earnings.json',{'items':[]}) or {'items':[]}
tot=round(sum(float(x.get('usd',0)) for x in e['items']),6)
wr('external-total.json',{'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),'total':tot,'n':len(e['items'])})
try:
    sp=iu.spec_from_file_location('led',os.path.join(R,'tools','ledger.py'));m=iu.module_from_spec(sp);sp.loader.exec_module(m)
    for x in e['items']: m.add('external',float(x.get('usd',0)),x.get('src',''),{'note':x.get('note','')})
    t,b=m.verify(); wr('ledger-index.json',{'t':datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).strftime('%FT%TZ'),'entries':t,'broken':b,'chain':'sha256'})
except Exception: pass
print('external total $%.4f من %d قيد'%(tot,len(e['items'])))
