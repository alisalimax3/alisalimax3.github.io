#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# CineHub 3099 · DEV.sh — نمو + فيروسية + أتمتة توزيع
# ═══════════════════════════════════════════════════════════════
set -u
cd ~/cinehub3099 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR" content c
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
OWNER="alkazmybwhwr-dot"; REPO="alisalimax3.github.io"; BRANCH="main"
SITE="https://${OWNER}.github.io"
G(){ printf '\033[32m  ✓ %s\033[0m\n' "$1"; }; W(){ printf '\033[33m  ! %s\033[0m\n' "$1"; }
R(){ printf '\033[31m  ✗ %s\033[0m\n' "$1"; }; H(){ printf '\n\033[36m━━ %s ━━\033[0m\n' "$1"; }
[ -f config.env ] && { set -a; . ./config.env; set +a; }

# ═══ 1/9 الفيروسية والمكافآت ═══
H "1/9 محرك الفيروسية"
cat > viral.js <<'EOF'
(function(){
  var K='ch_viral', INVITE_TARGET=3, UNLOCK_DAYS=7;
  function read(){ try{ return JSON.parse(localStorage.getItem(K)||'null')||{streak:0,last:'',pts:0,unlocks:0}; }catch(e){ return {streak:0,last:'',pts:0,unlocks:0}; } }
  function write(o){ localStorage.setItem(K,JSON.stringify(o)); document.dispatchEvent(new Event('ch:viral')); }
  function d(off){ return new Date(Date.now()-(off||0)*864e5).toISOString().slice(0,10); }
  function claim(){
    var o=read(), t=d(0);
    if(o.last===t) return {ok:false,why:'استلمت اليوم — عد غداً'};
    o.streak = (o.last===d(1)) ? o.streak+1 : 1;
    o.last=t;
    var b = 0.0015 * (1 + Math.min(o.streak,10)*0.3);
    o.pts += b; write(o);
    if(window.CHLedger) CHLedger.bonus(b,'streak');
    return {ok:true, streak:o.streak, bonus:b};
  }
  function invites(){
    var c=0; try{ for(var k in localStorage) if(k.indexOf('ch_refcount_')===0) c+=+localStorage[k]||0; }catch(e){}
    return c;
  }
  function unlockCheck(){
    var o=read(), n=invites();
    if(n>=INVITE_TARGET && !o.unlocks){
      o.unlocks=1; write(o);
      try{ var p={plan:'pro',exp:new Date(Date.now()+UNLOCK_DAYS*864e5).toISOString().slice(0,10)}; localStorage.setItem('ch_plan',JSON.stringify(p)); }catch(e){}
      return true;
    }
    return false;
  }
  window.CHViral={ read:read, claim:claim, invites:invites, unlockCheck:unlockCheck,
    target:INVITE_TARGET, days:UNLOCK_DAYS, done:function(){ return read().last===d(0); },
    points:function(){ return read().pts; } };
  setInterval(unlockCheck,5000); unlockCheck();
})();
EOF

cat > rewards.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>المكافآت · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:680px;margin:auto}.card{background:var(--p);border:1px solid var(--b);border-radius:14px;padding:16px;margin:12px 0;text-align:center}
.big{font-size:36px;font-weight:800;color:var(--a)}.l{color:var(--m);font-size:13px}
button{background:var(--a);color:#04121a;border:0;border-radius:10px;padding:12px 20px;font-weight:800;cursor:pointer}
button.alt{background:#1b2740;color:var(--t);border:1px solid var(--b)}
.bar{height:10px;background:#0d1424;border-radius:6px;overflow:hidden;margin:10px 0}
.bar i{display:block;height:100%;background:var(--a);width:0}
code{background:#0d1424;padding:4px 8px;border-radius:6px;word-break:break-all}
</style></head><body><div class="wrap">
<h1>مكافآت يومية</h1>
<div class="card"><div class="l">سلسلتك</div><div class="big" id="st">0</div><div class="l">يوم متواصل</div>
  <button onclick="cl()">استلم مكافأة اليوم</button><p id="m" class="l"></p></div>
<div class="card"><h3>افتح Pro مجاناً</h3>
  <p class="l">ادعُ <b id="tg"></b> أصدقاء → Pro لمدة <b id="dy"></b> أيام</p>
  <div class="bar"><i id="bar"></i></div>
  <p class="l" id="pr"></p>
  <p>رابطك: <code id="rl"></code></p><button class="alt" onclick="cp()">نسخ</button></div>
<div class="card"><div class="l">نقاطك من المكافآت</div><div class="big" id="pt">$0</div></div>
<p class="l"><a href="/leaderboard.html">المتصدرون</a> · <a href="/earn.html">اربح</a> · <a href="/favorites.html">مفضلتي</a></p>
</div>
<script src="/auth.js" defer></script><script src="/ledger.js" defer></script>
<script src="/ref.js" defer></script><script src="/viral.js" defer></script>
<script>
function paint(){ var o=CHViral.read(); document.getElementById('st').textContent=o.streak;
  document.getElementById('pt').textContent='$'+CHViral.points().toFixed(4);
  document.getElementById('tg').textContent=CHViral.target; document.getElementById('dy').textContent=CHViral.days;
  var n=CHViral.invites(); document.getElementById('bar').style.width=Math.min(100,n/CHViral.target*100)+'%';
  document.getElementById('pr').textContent=n+' / '+CHViral.target+' مدعوّين';
  document.getElementById('rl').textContent=CHRef.link();
  document.getElementById('m').textContent=CHViral.done()?'✓ استلمت اليوم':'';
  if(CHViral.done()) document.querySelector('button').disabled=true; }
document.readyState==='loading'?addEventListener('DOMContentLoaded',paint):paint();
document.addEventListener('ch:viral',paint);
function cl(){ var r=CHViral.claim(); document.getElementById('m').textContent=r.ok?('✓ +$'+r.bonus.toFixed(4)+' · سلسلة '+r.streak):r.why; paint(); }
function cp(){ CHRef.copy(); }
</script></body></html>
EOF

cat > leaderboard.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>المتصدرون · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:600px;margin:auto}.card{background:var(--p);border:1px solid var(--b);border-radius:12px;padding:12px;margin:8px 0;display:flex;justify-content:space-between}
.r{font-weight:800;color:var(--a);width:34px}table{width:100%;border-collapse:collapse}
td,th{border-bottom:1px solid var(--b);padding:8px;text-align:right;font-size:13px}.l{color:var(--m);font-size:12px}</style>
</head><body><div class="wrap"><h1>لوحة المتصدرين</h1>
<div class="card"><span class="l">ترتيبك (محلي)</span><b id="me">—</b></div>
<table><thead><tr><th>#</th><th>المستخدم</th><th>النقاط</th><th>الدعوات</th></tr></thead><tbody id="tb"></tbody></table>
<p class="l">المصدر الحقيقي بعد ربط الباكند = Google Sheet.</p>
<p class="l"><a href="/rewards.html">المكافآت</a> · <a href="/earn.html">اربح</a></p></div>
<script src="/auth.js" defer></script><script src="/ledger.js" defer></script><script src="/viral.js" defer></script>
<script>
function go(){ var o=CHLedger.read(), v=CHViral.read();
  var rows=[{u:'أنت',p:v.pts,i:CHViral.invites(),me:1}];
  for(var k in localStorage){ var m=k.match(/^ch_refearn_(.+)$/); if(m) rows.push({u:m[1],p:+localStorage[k]||0,i:0}); }
  rows.sort(function(a,b){return b.p-a.p});
  document.getElementById('tb').innerHTML=rows.map(function(r,i){return '<tr><td>'+(i+1)+'</td><td>'+r.u+(r.me?' ★':'')+'</td><td>$'+r.p.toFixed(4)+'</td><td>'+r.i+'</td></tr>'}).join('');
  document.getElementById('me').textContent='#'+(rows.findIndex(function(r){return r.me})+1); }
document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
</script></body></html>
EOF

cat > favorites.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>مفضلتي · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.8 system-ui,Tahoma;padding:16px}
.wrap{max-width:1000px;margin:auto}.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fill,minmax(150px,1fr))}
.c{background:var(--p);border:1px solid var(--b);border-radius:12px;overflow:hidden;text-decoration:none;color:var(--t);display:block}
.c img{width:100%;height:190px;object-fit:cover}.c b{display:block;padding:8px;font-size:13px}.l{color:var(--m);font-size:12px}</style>
</head><body><div class="wrap"><h1>مفضلتي</h1>
<div class="grid" id="g"></div><p class="l" id="e"></p>
<p class="l"><a href="/movies.html">أفلام</a> · <a href="/adult.html">للكبار</a> · <a href="/rewards.html">مكافآت</a></p></div>
<script>
function go(){ var f=[]; try{ f=JSON.parse(localStorage.getItem('ch_fav')||'[]'); }catch(e){}
  if(!f.length){ document.getElementById('e').textContent='لا مفضلة بعد — اضغط ★ في أي صفحة.'; return; }
  document.getElementById('g').innerHTML=f.map(function(x){
    return '<a class="c" href="'+x.u+'"><img loading="lazy" src="'+(x.t||'')+'" onerror="this.style.opacity=.2"><b>'+x.n+'</b></a>'}).join(''); }
document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
</script></body></html>
EOF
G "الفيروسية + المكافآت + المتصدرون + المفضلة"

# ═══ 2/9 العداد الحيّ + المشاركة + القفل ═══
H "2/9 العداد الحيّ + المشاركة + قفل المحتوى"
cat > ticker.js <<'EOF'
(function(){
  var el;
  function mnt(){ if(el) return; el=document.createElement('div'); el.id='ch-tick';
    el.style.cssText='position:fixed;top:10px;left:10px;z-index:9997;background:#0b1020ee;border:1px solid #1e2a44;color:#9fe8ff;font:11px/1.5 system-ui;padding:6px 10px;border-radius:10px;text-align:right';
    document.body.appendChild(el); }
  function v(){ var i=+(localStorage.getItem('ch_impressions')||0);
    return {i:i, e:(i/1000*1.2*0.7)}; }
  function paint(){ mnt(); var x=v();
    el.innerHTML='ظهور <b>'+x.i+'</b> · أرباحك <b style="color:#7ef0a0">$'+x.e.toFixed(5)+'</b>'; }
  document.addEventListener('ch:impression',paint);
  document.addEventListener('ch:ledger',paint);
  setInterval(paint,1500);
  document.readyState==='loading'?addEventListener('DOMContentLoaded',paint):paint();
})();
EOF

cat > share.js <<'EOF'
(function(){
  function ref(){ try{ return '?ref='+CH.uid(); }catch(e){ return ''; } }
  function data(){
    var t=document.title, u=location.origin+location.pathname;
    return { t:t, u:u+(u.indexOf('?')>-1?'&':'?')+'ref='+(window.CH?CH.uid():'') };
  }
  function wa(){ var d=data(); open('https://wa.me/?text='+encodeURIComponent(d.t+' — '+d.u),'_blank'); }
  function tg(){ var d=data(); open('https://t.me/share/url?url='+encodeURIComponent(d.u)+'&text='+encodeURIComponent(d.t),'_blank'); }
  function cp(){ var d=data(); navigator.clipboard&&navigator.clipboard.writeText(d.u); return d.u; }
  function bar(){
    if(document.getElementById('chshare')) return;
    var w=document.createElement('div'); w.id='chshare';
    w.style.cssText='display:flex;gap:6px;flex-wrap:wrap;margin:12px 0';
    var b='background:#1b2740;border:1px solid #1e2a44;color:#e8f6ff;padding:7px 12px;border-radius:8px;font:12px system-ui;cursor:pointer';
    w.innerHTML='<button style="'+b+'" onclick="CHShare.wa()">واتساب</button>'
      +'<button style="'+b+'" onclick="CHShare.tg()">تليجرام</button>'
      +'<button style="'+b+'" onclick="CHShare.cp()">نسخ الرابط</button>'
      +'<button style="'+b+'" onclick="CHShare.fav()">★ مفضلة</button>';
    var g=document.querySelector('.wrap')||document.body; g.appendChild(w);
  }
  function fav(){
    var f=[]; try{ f=JSON.parse(localStorage.getItem('ch_fav')||'[]'); }catch(e){}
    var u=location.pathname;
    if(f.some(function(x){return x.u===u})){ f=f.filter(function(x){return x.u!==u}); }
    else f.unshift({u:u,n:document.title.split('·')[0].trim(),t:(document.querySelector('meta[property="og:image"]')||{}).content||''});
    localStorage.setItem('ch_fav',JSON.stringify(f.slice(0,120)));
  }
  window.CHShare={ wa:wa, tg:tg, cp:cp, fav:fav };
  document.readyState==='loading'?addEventListener('DOMContentLoaded',bar):bar();
})();
EOF

cat > lock.js <<'EOF'
/* قفل محتوى — نقرة إعلان تفتح المشاهدة 24 ساعة (دخل CPA مباشر) */
(function(){
  var H='ch_unlock';
  function ok(){ var t=+localStorage.getItem(H)||0; return Date.now()<t; }
  function open24(){ localStorage.setItem(H,Date.now()+864e5); }
  function wrap(){
    if(ok()) return;
    if(!window.CHRev) return;
    CHRev.ready(function(c){
      if(!c.smartlink) return;
      var el=document.createElement('div');
      el.style.cssText='background:#111827;border:1px solid #1e2a44;border-radius:14px;padding:16px;margin:14px 0;text-align:center';
      el.innerHTML='<b>افتح المشاهدة المجانية</b><p style="color:#8aa0c0;font-size:12px;margin:6px 0">نقرة واحدة تفتح كل الأفلام 24 ساعة</p>'
        +'<button id="chul" style="background:#4dd0e1;color:#04121a;border:0;border-radius:9px;padding:11px 18px;font-weight:800;cursor:pointer">افتح الآن</button>';
      var g=document.querySelector('.wrap')||document.body; g.insertBefore(el,g.firstChild.nextSibling||g.firstChild);
      document.getElementById('chul').onclick=function(){
        window.open(c.smartlink,'_blank','noopener'); open24();
        el.innerHTML='<b style="color:#22c55e">✓ مُفتح — استمتع</b>';
      };
    });
  }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',wrap):wrap();
})();
EOF
G "ticker + share + lock"

# ═══ 3/9 PWA + إشعارات ═══
H "3/9 PWA + إشعارات"
cat > app.js <<'EOF'
(function(){
  if(!('serviceWorker' in navigator)) return;
  addEventListener('load',function(){ navigator.serviceWorker.register('/sw.js').catch(function(){}); });
  var dp=null;
  addEventListener('beforeinstallprompt',function(e){ e.preventDefault(); dp=e; show(); });
  function show(){ if(document.getElementById('chinst')) return;
    var b=document.createElement('div'); b.id='chinst';
    b.style.cssText='position:fixed;bottom:64px;left:12px;right:12px;z-index:9996;background:#111827;border:1px solid #1e2a44;border-radius:12px;padding:10px;display:flex;gap:8px;align-items:center;font:12px system-ui';
    b.innerHTML='<span style="flex:1;color:#8aa0c0">ثبّت التطبيق على شاشتك — أسرع وأوفر</span><button id="chi" style="background:#4dd0e1;color:#04121a;border:0;border-radius:8px;padding:7px 12px;font-weight:800">تثبيت</button>';
    document.body.appendChild(b);
    document.getElementById('chi').onclick=function(){ if(dp){ dp.prompt(); dp=null; } b.remove(); };
  }
  setTimeout(show,6000);
})();
EOF

cat > push.js <<'EOF'
(function(){
  var A="PUT-ONESIGNAL-APP-ID";
  if(A.indexOf("PUT")===0) return;
  window.OneSignalDeferred=window.OneSignalDeferred||[];
  var s=document.createElement("script");
  s.src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js"; s.defer=1; document.head.appendChild(s);
  OneSignalDeferred.push(function(O){ O.init({ appId:A, allowLocalhostAsSecureOrigin:true }); });
})();
EOF
G "PWA + إشعارات"

# ═══ 4/9 توسيع المحتوى ═══
H "4/9 توسيع المحتوى (8 تصنيفات)"
cat > content/expand.py <<'PYEOF'
#!/usr/bin/env python3
import json, os, re, urllib.request, urllib.parse, html, time
UA={'User-Agent':'Mozilla/5.0 (CineHub3099)'}
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
B="https://alisalimax3.github.io"
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
PYEOF
chmod +x content/expand.py
python3 content/expand.py 2>&1 | tail -12

cat > cats.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>التصنيفات · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--a:#4dd0e1}
body{margin:0;background:var(--bg);color:var(--t);font:15px system-ui,Tahoma;padding:16px}
.wrap{max-width:900px;margin:auto}.grid{display:grid;gap:12px;grid-template-columns:repeat(auto-fill,minmax(160px,1fr))}
a{background:var(--p);border:1px solid var(--b);border-radius:12px;padding:18px;text-decoration:none;color:var(--t);text-align:center;font-weight:700}
a:hover{border-color:var(--a)}.l{color:#8aa0c0;font-size:12px}</style></head><body><div class="wrap">
<h1>كل التصنيفات</h1><div class="grid" id="g"></div></div>
<script>
fetch('/data/cats.json').then(function(r){return r.json()}).then(function(d){
  document.getElementById('g').innerHTML=Object.keys(d).map(function(k){
    return '<a href="/'+k+'.html">'+d[k].label+'<div class="l">'+d[k].items.length+' عنوان</div></a>'}).join(''); });
</script></body></html>
EOF
G "8 تصنيفات + cats.html"

# ═══ 5/9 RSS ═══
H "5/9 RSS للتوزيع"
cat > content/rss.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,html,datetime,re
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
B="https://alisalimax3.github.io"
D=json.load(open('data/index.json',encoding='utf-8'))
def slug(s):
    s=re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]',' ',s or ''); return (re.sub(r'\s+','-',s.strip().lower())[:60] or 'item').strip('-')
items=[]
for x in D.get('movies',[])[:60]: items.append((x['title'],B+'/movies.html',x.get('desc',''),x.get('thumb','')))
for x in D.get('adult',[])[:40]: items.append((x['title'],B+'/adult.html',x.get('keywords',''),x.get('thumb','')))
now=datetime.datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S +0000')
x='<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"><channel>\n'
x+='<title>CineHub 3099</title><link>%s/</link><description>أفلام ومسلسلات مجاناً</description><language>ar</language>\n'%B
x+='<lastBuildDate>%s</lastBuildDate>\n'%now
for t,u,d,img in items[:70]:
    x+='<item><title>%s</title><link>%s</link><description>%s</description>'%(html.escape(t),u,html.escape(d or ''))
    if img: x+='<enclosure url="%s" type="image/jpeg"/>'%html.escape(img)
    x+='<pubDate>%s</pubDate></item>\n'%now
x+='</channel></rss>'
open('feed.xml','w',encoding='utf-8').write(x)
print('  feed.xml:',min(len(items),70),'عنصر')
PYEOF
python3 content/rss.py

# ═══ 6/9 بوت تيليجرام ═══
H "6/9 بوت تيليجرام للنشر التلقائي"
cat > tgbot.py <<'PYEOF'
#!/usr/bin/env python3
"""CineHub 3099 · ناشر تيليجرام تلقائي — يرسل عنصراً جديداً كل دورة"""
import json, os, random, sys, time, urllib.request, urllib.parse, re
ROOT=os.path.dirname(os.path.abspath(__file__)); os.chdir(ROOT)
TOKEN=os.environ.get('TG_TOKEN',''); CHAT=os.environ.get('TG_CHAT',''); REF=os.environ.get('TG_REF','')
B="https://alisalimax3.github.io"
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
PYEOF

cat > tg.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# CineHub 3099 · ناشر تيليجرام — bash tg.sh [عدد]  أو  bash tg.sh --watch
cd ~/cinehub3099 || exit 1
[ -f config.env ] && { set -a; . ./config.env; set +a; }
if [ "${1:-}" = "--watch" ]; then
  while true; do python3 tgbot.py 2; sleep 7200; done
else
  python3 tgbot.py "${1:-1}"
fi
EOF
chmod +x tg.sh tgbot.py
G "بوت تيليجرام"

# ═══ 7/9 حقن + سايت ماب + نشر ═══
H "7/9 حقن ونشر"
python3 - <<'PY'
import os
F=[]
for r,d,f in os.walk('.'):
    d[:]=[x for x in d if x not in ('.git','node_modules','backups','.tmp','content','c')]
    F+=[os.path.join(r,x) for x in f if x.endswith('.html')]
SC=['/auth.js','/captcha.js','/ledger.js','/ref.js','/viral.js','/rev.js','/share.js','/ticker.js','/payout.js','/ads.js','/app.js','/nav.js']
n=0
for p in F:
    s=open(p,encoding='utf-8').read(); o=s
    for sc in SC:
        b=sc.split('/')[-1]
        if b in s: continue
        t='<script src="%s" defer></script>'%sc
        s=s.replace('</body>',t+'\n</body>',1) if '</body>' in s else s+t
    if s!=o: open(p,'w',encoding='utf-8').write(s); n+=1
print('  حقن في',n)
PY
cat > nav.js <<'EOF'
(function(){
  var items=[['/','الرئيسية'],['/movies.html','أفلام'],['/cats.html','تصنيفات'],['/adult.html','للكبار'],['/rewards.html','مكافآت'],['/earn.html','اربح'],['/wallet.html','محفظتي']];
  function go(){
    if(document.getElementById('chnav')) return;
    var p=location.pathname, w=document.createElement('div'); w.id='chnav';
    w.style.cssText='position:fixed;bottom:0;left:0;right:0;z-index:9998;background:#0b1020f2;border-top:1px solid #1e2a44;display:flex;overflow-x:auto';
    w.innerHTML=items.map(function(i){var a=p===i[0]||(i[0]!=='/'&&p.indexOf(i[0])===0);
      return '<a href="'+i[0]+'" style="flex:1;min-width:66px;text-align:center;padding:11px 5px;font:12px system-ui;text-decoration:none;color:'+(a?'#4dd0e1':'#8aa0c0')+'">'+i[1]+'</a>'}).join('');
    document.body.appendChild(w); document.body.style.paddingBottom='66px';
  }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
})();
EOF
python3 spread.py 2>&1 | tail -6
T="$(tr -d '\n\r ' < .gh-token)"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${OWNER}/${REPO}.git"
git add -A; git rm --cached -q --ignore-unmatch .gh-token .license-secret 2>/dev/null
git diff --cached --quiet || git commit -q -m "feat: viral+lock+ticker+rss+tg+cats $(date -u +%FT%TZ)"
bash deploy.sh main "auto $(date -u +%FT%TZ)"&& G "نُشر" || { R "فشل"; cat "$D/.gp.err"; }

# ═══ 8/9 دمج مع auto.sh ═══
H "8/9 دمج الأتمتة"
python3 - <<'PY'
s=open('auto.sh',encoding='utf-8').read()
if 'expand.py' not in s:
    s=s.replace("python3 content/render.py 2>&1 | tail -4",
                "python3 content/render.py 2>&1 | tail -4\n  python3 content/expand.py 2>&1 | tail -3\n  python3 content/rss.py 2>&1 | tail -1")
    open('auto.sh','w',encoding='utf-8').write(s)
    print('  auto.sh مُحدّث')
else: print('  auto.sh محدّث سابقاً')
PY

# ═══ 9/9 تحقق ═══
H "9/9 تحقق"
sleep 80
python3 - <<'PY'
import urllib.request,json
B="https://alisalimax3.github.io"
for p in ("/","/cats.html","/rewards.html","/favorites.html","/leaderboard.html","/movies.html","/feed.xml","/data/cats.json","/viral.js","/tgbot.py"):
    try: c=urllib.request.urlopen(B+p,timeout=25).status
    except Exception as e: c=getattr(e,"code","ERR")
    print("  %-20s %s %s"%(p,c,"✓" if c==200 else "✗"))
try:
    d=json.loads(urllib.request.urlopen(B+"/data/cats.json",timeout=25).read())
    print("  تصنيفات:",len(d),"· عناصر:",sum(len(v['items']) for v in d.values()))
except Exception as e: print("  cats:",e)
PY
printf '\n\033[32m══ اكتمل · %s/rewards.html ══\033[0m\n' "$SITE"
printf '\033[33mتيليجرام: أضف TG_TOKEN و TG_CHAT في config.env ثم bash tg.sh --watch &\033[0m\n'
