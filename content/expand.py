#!/usr/bin/env python3
import json, os, re, urllib.request, urllib.parse, html, time
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)'}
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
B="https://alkazmybwhwr-dot.github.io"
CATS=[('archive-action','أكشن ومغامرة','collection:(feature_films) AND (subject:(action) OR subject:(adventure))'),
      ('archive-noir','نوار وجريمة','collection:(film_noir)'),
      ('archive-anim','رسوم متحركة','collection:(animationandcartoons)'),
      ('archive-kids','عائلي وأطفال','collection:(classic_cartoons)'),
      ('archive-doc','وثائقيات','collection:(documentaryfilms)'),
      ('archive-sci','خيال علمي ورعب','collection:(sci-fi_horror)'),
      ('archive-silent','سينما صامتة','collection:(silent_films)'),
      ('archive-comedy','كوميديا','collection:(feature_films) AND subject:(comedy)')]
def get(u,t=35): return json.loads(urllib.request.urlopen(urllib.request.Request(u,headers=UA),timeout=t).read().decode('utf-8','ignore'))
def clean(h,n=220): return re.sub(r'\s+',' ',re.sub('<[^>]+>','',h or '')).strip()[:n]
def slug(s):
    s=re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]',' ',s or ''); return (re.sub(r'\s+','-',s.strip().lower())[:60] or 'item').strip('-')
def fetch(q,rows=32):
    p=[('q',q),('rows',str(rows)),('page','1'),('output','json'),('sort[]','downloads desc')]
    p+=[('fl[]',f) for f in ('identifier','title','year','description')]
    out=[]
    for x in get('https://archive.org/advancedsearch.php?'+urllib.parse.urlencode(p)).get('response',{}).get('docs',[]):
        t=(x.get('title') or '').strip()
        if not t: continue
        out.append({'src':'archive','id':x['identifier'],'title':t,'year':x.get('year') or '',
                    'desc':clean(x.get('description')),'embed':'https://archive.org/embed/'+x['identifier'],
                    'thumb':'https://archive.org/services/img/'+x['identifier']})
    return out
HEAD='''<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{t} · CineHub 3099</title>
<meta name="description" content="{d}"><meta property="og:title" content="{t}"><meta property="og:description" content="{d}">
<meta property="og:image" content="{i}"><meta name="twitter:card" content="summary_large_image">
<style>:root{{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--t);font:15px/1.8 system-ui,Tahoma;padding:14px 14px 90px}}
.wrap{{max-width:1100px;margin:auto}}.grid{{display:grid;gap:12px;grid-template-columns:repeat(auto-fill,minmax(150px,1fr))}}
.c{{background:var(--p);border:1px solid var(--b);border-radius:12px;overflow:hidden;text-decoration:none;color:var(--t);display:block}}
.c img{{width:100%;height:200px;object-fit:cover;background:#0d1424}}.c b{{display:block;padding:8px;font-size:13px}}
input{{width:100%;background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:10px;margin:8px 0}}
.ply{{position:fixed;inset:0;background:#000c;display:none;z-index:9999;align-items:center;justify-content:center;padding:10px}}
.ply.on{{display:flex}}.ply iframe{{width:min(1000px,96vw);height:min(60vw,600px);border:0;border-radius:10px}}</style></head><body><div class="wrap">'''
FOOT='<div class="ply" id="ply" onclick="this.classList.remove(\'on\');document.getElementById(\'pb\').innerHTML=\'\'"><div id="pb"></div></div></div></body></html>'
JS='''<script>function play(e,u){e.preventDefault();document.getElementById('pb').innerHTML='<iframe src="'+u+'" allowfullscreen></iframe>';document.getElementById('ply').classList.add('on');return false}
function flt(){var q=document.getElementById('q').value.toLowerCase();document.querySelectorAll('#g .c').forEach(function(c){c.style.display=c.textContent.toLowerCase().indexOf(q)>-1?'':'none'})}</script>'''
idx={}
for cid,label,q in CATS:
    try: items=fetch(q); print('  %-15s %d'%(cid,len(items)))
    except Exception as e: print('  %-15s ✗ %s'%(cid,e)); items=[]
    idx[cid]={'label':label,'items':items}
    s=HEAD.format(t=html.escape(label),d=html.escape(label),i=(items[0]['thumb'] if items else ''))
    s+='<h1>%s</h1><input id="q" placeholder="ابحث..." oninput="flt()"><div class="grid" id="g">'%html.escape(label)
    s+=''.join('<a class="c" href="%s" onclick="return play(event,\'%s\')"><img loading="lazy" src="%s"><b>%s</b></a>'%(B+'/c/'+cid+'.html',html.escape(x['embed']),html.escape(x['thumb']),html.escape(x['title'])) for x in items)
    s+='</div>'+JS+FOOT
    open(cid+'.html','w',encoding='utf-8').write(s)
    # صفحة ثابتة لكل عنصر
    os.makedirs('c',exist_ok=True)
    for x in items[:12]:
        fn='c/'+cid+'-'+slug(x['title'])+'.html'
        ld={"@context":"https://schema.org","@type":"VideoObject","name":x['title'],"description":x['desc'] or x['title'],"thumbnailUrl":x['thumb'],"uploadDate":(x.get('year') or '2026')+'-01-01',"embedUrl":x['embed'],"url":B+'/'+fn}
        open(fn,'w',encoding='utf-8').write(HEAD.format(t=html.escape(x['title']),d=html.escape(x['desc'] or x['title']),i=html.escape(x['thumb']))
          +'<script type="application/ld+json">'+json.dumps(ld,ensure_ascii=False)+'</script><h1>'+html.escape(x['title'])+'</h1>'
          +'<iframe src="'+html.escape(x['embed'])+'" style="width:100%;height:min(60vw,600px);border:0;border-radius:12px" allowfullscreen></iframe>'
          +'<p style="color:#8aa0c0">'+html.escape(x['desc'] or '')+'</p><p><a href="/'+cid+'.html" style="color:#4dd0e1">كل '+html.escape(label)+'</a></p>'+FOOT)
json.dump(idx,open('data/cats.json','w',encoding='utf-8'),ensure_ascii=False)
tot=sum(len(v['items']) for v in idx.values())
print('  الإجمالي:',tot,'عنصر ·',sum(1 for v in idx.values() for _ in v['items'][:12]),'صفحة ثابتة')
