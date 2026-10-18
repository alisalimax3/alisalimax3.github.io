#!/usr/bin/env python3
"""CineHub 3099 · ناشر تيليجرام تلقائي — يرسل عنصراً جديداً كل دورة"""
import json, os, random, sys, time, urllib.request, urllib.parse, re
ROOT=os.path.dirname(os.path.abspath(__file__)); os.chdir(ROOT)
TOKEN=os.environ.get('TG_TOKEN',''); CHAT=os.environ.get('TG_CHAT',''); REF=os.environ.get('TG_REF','')
B="https://alkazmybwhwr-dot.github.io"
def api(m,data):
    u='https://api.telegram.org/bot%s/%s'%(TOKEN,m)
    d=urllib.parse.urlencode(data).encode()
    try: return json.loads(urllib.request.urlopen(urllib.request.Request(u,data=d),timeout=30).read())
    except Exception as e: return {'ok':False,'err':str(e)}
def slug(s):
    s=re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]',' ',s or ''); return (re.sub(r'\s+','-',s.strip().lower())[:60] or 'item').strip('-')
def main(n=1):
    if not TOKEN or not CHAT: print('  ! ضع TG_TOKEN و TG_CHAT في config.env'); return
    try: D=json.load(open('data/index.json',encoding='utf-8'))
    except Exception: print('  ! لا محتوى — شغّل build.py'); return
    pool=[]
    for x in D.get('movies',[]):
        if x.get('thumb'): pool.append((x['title'],B+'/movies.html',x.get('thumb'),'🎬 فيلم'))
    for x in D.get('adult',[]):
        if x.get('thumb'): pool.append((x['title'],B+'/adult.html',x.get('thumb'),'🔞 للكبار'))
    for x in D.get('channels',[]):
        if x.get('thumb'): pool.append((x['title'],B+'/channels.html',x.get('thumb'),'📺 قناة'))
    if not pool: print('  ! لا عناصر'); return
    seen=set()
    try: seen=set(json.load(open('.tg-sent.json')))
    except Exception: pass
    sent=0
    for t,u,img,tag in random.sample(pool,min(len(pool),max(n*4,n))):
        if t in seen: continue
        link=u+('?ref='+REF if REF else '')
        cap='%s <b>%s</b>\n\nشاهد مجاناً بلا تحميل 👇\n%s'%(tag,t.replace('<','&lt;'),link)
        r=api('sendPhoto',{'chat_id':CHAT,'photo':img,'caption':cap,'parse_mode':'HTML'})
        if not r.get('ok'):
            r=api('sendMessage',{'chat_id':CHAT,'text':cap,'parse_mode':'HTML'})
        if r.get('ok'): seen.add(t); sent+=1
        if sent>=n: break
        time.sleep(2)
    json.dump(sorted(seen)[-400:],open('.tg-sent.json','w'))
    print('  أُرسل: %d'%sent)
if __name__=='__main__': main(int(sys.argv[1]) if len(sys.argv)>1 else 1)
