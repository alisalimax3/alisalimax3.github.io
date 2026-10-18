#!/usr/bin/env python3
import os,json,glob,sys
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def ok(m): print('  \033[32m✓\033[0m '+m)
def bad(m): print('  \033[31m✗\033[0m '+m)
def w(m): print('  \033[33m⚠\033[0m '+m)
p=0;f=0
need=['ads.js','ads-config.json','networks.json','cloud.js','captcha.js','authtoken.js','payout.js',
 'ref.js','sw.js','treasury.html','admin2.html','apply.html','watch.html','plan.html','start.html',
 'gate.html','go.html','gift.json','offerwalls.json','shorteners.json','linkgo.js','upsell.js',
 'db/schema.sql','backend/Code.gs','.github/workflows/tick.yml','.github/workflows/daily.yml','tools/ping.py']
for x in need:
    if os.path.exists(os.path.join(R,x)): p+=1
    else: bad('ناقص: '+x); f+=1
for wf in glob.glob(os.path.join(R,'.github/workflows/*.yml')):
    s=open(wf,encoding='utf-8').read()
    if 'permissions' not in s: bad('بلا permissions: '+os.path.basename(wf)); f+=1
    if 'contents: write' not in s: bad('بلا contents:write: '+os.path.basename(wf)); f+=1
try:
    c=json.load(open(os.path.join(R,'ads-config.json'),encoding='utf-8'))
    k=sum(1 for v in (c.get('banners') or {}).values() if v.get('key'))
    (ok if k else w)('مفاتيح بانرات مربوطة: %d'%k)
    if not k: f+=1
except Exception as e: bad('ads-config: '+str(e)); f+=1
try:
    n=json.load(open(os.path.join(R,'networks.json'),encoding='utf-8'))
    en=[x['id'] for x in n.get('networks',[]) if x.get('enabled')]
    mk=[x['id'] for x in n.get('networks',[]) if any((x.get('keys') or {}).values())]
    ok('شبكات مُفعّلة: %d · لها مفاتيح: %d'%(len(en),len(mk)))
    if not mk: w('لا شبكة لها مفتاح ⇒ الظهور 0 (طبيعي)')
except Exception as e: bad('networks: '+str(e)); f+=1
try:
    s=json.load(open(os.path.join(R,'shorteners.json'),encoding='utf-8'))
    u=[x['id'] for x in s.get('shorteners',[]) if x.get('uid')]
    (ok if u else w)('shorteners بمعرّف: %d/%d'%(len(u),len(s.get('shorteners',[]))))
except Exception as e: bad('shorteners: '+str(e)); f+=1
try:
    o=json.load(open(os.path.join(R,'owner.json'),encoding='utf-8'))
    for key,lab in (('whatsapp','واتساب'),('kuraimi_name','اسم الكريمي'),('kuraimi_account','رقم الحساب'),('kuraimi_phone','الهاتف')):
        (ok if o.get(key) else w)(lab+': '+(o.get(key) or 'غير مضبوط'))
except Exception as e: bad('owner: '+str(e)); f+=1
print('\n  %s (%d تحذير/خطأ من %d ملفًا)'%('جاهز' if f==0 else 'يحتاج إكمال',f,p))
