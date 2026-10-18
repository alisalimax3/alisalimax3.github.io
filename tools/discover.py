#!/usr/bin/env python3
"""يضيف جهات حقيقية من مصادر عامة مفتوحة — يتوسّع وحده مع كل تشغيل"""
import json,os,re,urllib.request
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA={'User-Agent':'Mozilla/5.0 (CineHub3099 discover)'}
SRC=[('affiliates-md','https://raw.githubusercontent.com/lbalceda/awesome-affiliates/main/README.md'),
 ('affpaying','https://affpaying.com/affiliate-networks'),
 ('awesome-saas','https://raw.githubusercontent.com/proxio-io/awesome-affiliates/main/README.md')]
def get(u):
    try: return urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=30).read().decode('utf-8','ignore')
    except Exception as e: return ''
def slug(s):
    s=re.sub(r'[^a-z0-9]+','-',s.lower()).strip('-');return s or 'x'
found=[]
for name,u in SRC:
    h=get(u)
    if not h: print('  ! فشل',name); continue
    for m in re.finditer(r'\[([^\]]{2,60})\]\((https?://[^)\s]+)\)',h):
        n,url=m.group(1).strip(),m.group(2).strip()
        if any(x in url for x in ('github.com','twitter.com','badge','shields.io','license','#')): continue
        if not n or n.lower().startswith('http'): continue
        found.append((n,url))
    for m in re.finditer(r'href="(/affiliate-networks/[a-z0-9\-]+)"[^>]*>([^<]{2,50})<',h):
        found.append((m.group(2).strip(),'https://affpaying.com'+m.group(1)))
print('  عُثر على',len(found),'مرشّح')
j=json.load(open(os.path.join(R,'platforms.json'),encoding='utf-8'))
have={x['id'] for x in j['platforms']}; haveurl={x['u'].rstrip('/') for x in j['platforms']}
add=0
for n,u in found:
    i=slug(n)
    if i in have or u.rstrip('/') in haveurl: continue
    have.add(i); haveurl.add(u.rstrip('/'))
    j['platforms'].append({"id":i,"n":n[:60],"c":"aff","min":10,"p":["PayPal","Wire"],"ye":"mid",
      "u":u,"note":"اكتُشفت تلقائيًا","model":"commission","ref":True,"done":False,"ref_code":""})
    add+=1
j['total']=len(j['platforms']); j['discovered_at']=__import__('datetime').datetime.now(__import__('datetime').timezone.utc).replace(tzinfo=None).strftime('%FT%TZ')
json.dump(j,open(os.path.join(R,'platforms.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('  ✓ أُضيف',add,'· المجموع',j['total'])
