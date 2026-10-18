#!/usr/bin/env python3
import urllib.request,json,sys,time
B='https://raw.githubusercontent.com/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io/main/'
LIVE='https://alkazmybwhwr-dot.github.io/'
RAW=['.github/workflows/tick.yml','.github/workflows/daily.yml','tools/networks.py','networks.json',
 'ads.js','rewarded.js','cloud.js','captcha.js','payout.js','ref.js','sw.js','ads.txt','treasury.html',
 'admin2.html','gift.json','offerwalls.json','db/schema.sql','backend/Code.gs','revenue.json','heartbeat.json','treasury.json','shorteners.json','linkgo.js','apply.html','watch.html','platforms.json','referrals.json','money.json','tools/ping.py','data/harvest-report.json','credit.html','owner.html','img.html','cinema.html','data/archive.json','tools/harvest.py','.github/workflows/ping.yml','ping.json']
LIVEU=['/','/ads-config.json','/networks.json','/treasury.html','/admin2.html','/withdraw.html','/wallet.json','/apply.html','/watch.html','/shorteners.json','/cinema.html','/owner.html']
def head(u):
    try: return urllib.request.urlopen(u,timeout=25).status
    except Exception as e: return getattr(e,'code','ERR')
bad=0
print('— ملفات الريموت —')
for u in RAW:
    c=head(B+u)
    if c!=200: bad+=1
    print('  %s %s'%(c,u))
print('— الصفحات الحيّة (قد تتأخر دقائق بعد النشر) —')
for u in LIVEU:
    c=head(LIVE+u.lstrip('/'))
    if c!=200: bad+=1
    print('  %s %s'%(c,u))
try:
    j=json.load(urllib.request.urlopen('https://api.github.com/repos/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io/actions/workflows',timeout=25))
    print('— Actions —')
    for w in j.get('workflows',[]): print('  %s · %s'%(w['name'],w['state']))
except Exception as e: print('  ! Actions:',e)
print('\n%s (%d فشل)'%('✓ كل شيء منشور' if bad==0 else '✗ ناقص',bad))
sys.exit(0 if bad==0 else 1)
