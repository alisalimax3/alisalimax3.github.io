#!/usr/bin/env python3
import os,json,datetime,shutil
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.makedirs(os.path.join(R,'snapshots'),exist_ok=True)
d=datetime.date.today().isoformat(); out={}
for f in ('revenue.json','treasury.json','heartbeat.json','payments.json'):
    try: out[f]=json.load(open(os.path.join(R,f),encoding='utf-8'))
    except Exception: out[f]=None
json.dump(out,open(os.path.join(R,'snapshots',d+'.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
sn=sorted(x for x in os.listdir(os.path.join(R,'snapshots')) if x.endswith('.json'))
for x in sn[:-120]:
    try: os.remove(os.path.join(R,'snapshots',x))
    except Exception: pass
print('snapshot',d)
