#!/usr/bin/env python3
"""يبني سجل المواقع + صفحة تسجيل قابلة للنقر + .env.example"""
import sys,os,json,html,datetime
HERE=os.path.dirname(os.path.abspath(__file__)); M=os.path.dirname(HERE); ROOT=os.path.dirname(M); D=os.path.join(M,"data")
rows=[]
for l in open(os.path.join(M,"sites.tsv"),encoding="utf-8"):
    l=l.rstrip("\n")
    if not l or l.startswith("id|"): continue
    f=l.split("|")
    if len(f)<10: continue
    rows.append(dict(id=f[0],name=f[1],cat=f[2],signup=f[3],env=f[4],mode=f[5],url=f[6],headers=f[7],rev=f[8]=="1",payout=f[9],note=f[10] if len(f)>10 else ""))
st=os.path.join(D,"sites.json")
state=json.load(open(st)) if os.path.exists(st) else {}
for r in rows: state.setdefault(r["id"],{"status":"pending"})
json.dump(state,open(st,"w"),indent=2)
json.dump(rows,open(os.path.join(ROOT,"sites.json"),"w"),indent=2,ensure_ascii=False)
# .env.example
seen=[]
for r in rows:
    for v in r["env"].split(","):
        if v and v not in seen: seen.append(v)
open(os.path.join(ROOT,".env.example"),"w").write("\n".join(v+"=" for v in seen)+"\n")
# register.html
cats={}
for r in rows: cats.setdefault(r["cat"],[]).append(r)
BADGE={"pending":("#3b3b3b","بانتظار التسجيل"),"opened":("#8a6d00","فُتح"),"registered":("#1d4ed8","تم التسجيل"),"key_set":("#7c3aed","المفتاح مضاف"),"live":("#15803d","يعمل وحي")}
body=[]
for c,items in cats.items():
    body.append(f'<h2>{html.escape(c)} <span class=pill>{len(items)}</span></h2><div class=grid>')
    for r in items:
        body.append(f'''<div class=card data-id="{r['id']}">
<div class=head><b>{html.escape(r['name'])}</b><span class=b id="b_{r['id']}">…</span></div>
<div class=env><code>{html.escape(r['env'])}</code></div>
<div class=meta>{'<span class=rev>مصدر ربح</span>' if r['rev'] else ''}<span>{html.escape(r['note'])}</span><span>سحب: {html.escape(r['payout'])}</span><span>تحقق: {r['mode']}</span></div>
<div class=acts><a href="{r['signup']}" target="_blank" rel="noopener" onclick="mark('{r['id']}','opened')">تسجيل ↗</a>
<button onclick="mark('{r['id']}','registered')">تم</button><button onclick="mark('{r['id']}','key_set')">المفتاح أُضيف</button></div></div>''')
    body.append("</div>")
htmlout=f'''<!doctype html><html lang=ar dir=rtl><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>سجل 60 موقع — CineHub</title><style>
body{{margin:0;font:15px/1.6 system-ui,Segoe UI,Tahoma;background:#0b0e14;color:#e8eef7}}
header{{padding:20px 24px;border-bottom:1px solid #1e2733;display:flex;gap:14px;align-items:center;flex-wrap:wrap;position:sticky;top:0;background:#0b0e14ee;backdrop-filter:blur(6px)}}
h1{{margin:0;font-size:19px}}.pill{{background:#1e2733;border-radius:99px;padding:1px 9px;font-size:12px;color:#8fa2b8}}
main{{padding:18px 24px 60px;max-width:1200px}}.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:12px;margin-bottom:26px}}
.card{{background:#141a24;border:1px solid #1e2733;border-radius:12px;padding:12px}}
.head{{display:flex;justify-content:space-between;gap:8px;align-items:center}}.b{{font-size:11px;padding:2px 8px;border-radius:99px;background:#222;color:#aaa}}
.env code{{font-size:11px;color:#7dd3fc;word-break:break-all}}.meta{{font-size:11px;color:#8fa2b8;display:flex;gap:8px;flex-wrap:wrap;margin:7px 0}}
.rev{{color:#4ade80}}.acts{{display:flex;gap:6px;flex-wrap:wrap}}a,button{{font:12px inherit;padding:5px 10px;border-radius:8px;border:1px solid #24303f;background:#0b0e14;color:#cfe1f5;cursor:pointer;text-decoration:none}}
a:hover,button:hover{{background:#1b2431}}code{{background:#0b0e14;padding:1px 5px;border-radius:5px}}</style>
<header><h1>سجل المواقع — {len(rows)} موقع</h1><span class=pill id=prog>0 / {len(rows)}</span>
<button onclick="location.href='/api/status'">حالة المفاتيح</button><button onclick="localStorage.clear();location.reload()">تصفير</button></header>
<main>{''.join(body)}</main><script>
const N={len(rows)},BADGE={json.dumps({k:v[1] for k,v in BADGE.items()},ensure_ascii=False)},COL={json.dumps({k:v[0] for k,v in BADGE.items()})};
function st(id){{return JSON.parse(localStorage.ch||'{{}}')[id]||'pending'}}
function mark(id,s){{const m=JSON.parse(localStorage.ch||'{{}}');m[id]=s;localStorage.setItem('ch',JSON.stringify(m));draw()}}
function draw(){{let n=0;document.querySelectorAll('.card').forEach(c=>{{const s=st(c.dataset.id);if(s!=='pending'&&s!=='opened')n++;
const b=document.getElementById('b_'+c.dataset.id);b.textContent=BADGE[s];b.style.background=COL[s];b.style.color='#fff';
c.style.borderColor=s==='live'?'#15803d':s==='key_set'?'#7c3aed':'#1e2733'}});document.getElementById('prog').textContent=n+' / '+N}}
draw();</script></html>'''
open(os.path.join(ROOT,"register.html"),"w",encoding="utf-8").write(htmlout)
print(json.dumps({"sites":len(rows),"rev_sources":sum(1 for r in rows if r["rev"]),"api_modes":sum(1 for r in rows if r["mode"]!="dash"),"register_page":os.path.join(ROOT,"register.html")},indent=2))
