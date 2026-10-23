#!/usr/bin/env node
/* one.mjs — أمر موحد: نسخ احتياطي · إصلاح · جمع · رفع · تشغيل وكلاء · تحقق
   التشغيل:  node money/one.mjs          تحقق فقط:  node money/one.mjs --check  */
import fs from 'node:fs'; import path from 'node:path'; import { spawnSync } from 'node:child_process';
const REPO=path.resolve(path.dirname(new URL(import.meta.url).pathname),'..');
const DRY=process.argv.includes('--dry'), CHECK=process.argv.includes('--check'), KEEP=process.argv.includes('--keep-agents');
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const rd=p=>{try{return fs.readFileSync(p,'utf8')}catch{return null}}; const ex=p=>fs.existsSync(p);
const BK=path.join(REPO,'money/.heal/backups/one-'+new Date().toISOString().replace(/[:.]/g,'-'));
const bak=p=>{if(!ex(p))return;const t=path.join(BK,path.relative(REPO,p));fs.mkdirSync(path.dirname(t),{recursive:true});fs.copyFileSync(p,t)};
const wr=(p,s)=>{if(rd(p)===s)return false;bak(p);if(!DRY){fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,s)}return true};
const sh=(c,a,t=1800000)=>spawnSync(c,a,{cwd:REPO,encoding:'utf8',timeout:t,maxBuffer:1<<26});
const get=async u=>{const c=new AbortController(),id=setTimeout(()=>c.abort(),15000);try{return (await fetch(u,{redirect:'follow',headers:{'user-agent':'Mozilla/5.0'}})).status}catch{return 0}finally{clearTimeout(id)}};

const remote=(sh('git',['remote','get-url','origin']).stdout||'').trim();
const m=remote.replace(/\.git$/,'').match(/github\.com[:/]+([^/]+)\/([^/]+)$/i)||[];
if(!m[1]){console.error('✗ مفيش ريموت GitHub: '+remote);process.exit(1)}
const REAL=m[2].toLowerCase()===(m[1]+'.github.io').toLowerCase()?'https://'+m[1]+'.github.io':'https://'+m[1]+'.github.io/'+m[2];
const HOST=REAL.replace(/^https?:\/\//,''); const BR=(sh('git',['rev-parse','--abbrev-ref','HEAD']).stdout||'main').trim();
console.log('\n═════ أمر موحد · '+new Date().toLocaleString()+' ═════\n▸ '+m[1]+'/'+m[2]+' · فرع '+BR+'\n▸ '+REAL+'\n▸ الوضع: '+(CHECK?'تحقق فقط':DRY?'تجربة':'تنفيذ حقيقي'));

const TARGETS=['/grid.js','/wallet.js','/grid.css','/tmdb-img-shim.js','/vn-panel.html','/vn-wallet.html','/withdraw.html'];

if(!CHECK){
  /* 1 · حافظ على الأرباح القديمة */
  for(const w of ['wallet.json','money/wallet.json','live-earnings.json','earnings.json']) if(ex(path.join(REPO,w))) bak(path.join(REPO,w));
  const bal=rd(path.join(REPO,'wallet.json')); if(bal){try{console.log('💰 رصيد محفوظ: $'+(+JSON.parse(bal).balance||0).toFixed(6))}catch{}}

  /* 2 · وقّف الوكلاء اللي بتعمل git */
  if(!KEEP){ for(const p of ['money/heal.mjs','money/panel.mjs','money/agent.mjs','money/tick.mjs','money/deep.mjs'])
    sh('bash',['-lc','pkill -f "'+p+'" 2>/dev/null || true']); console.log('⏸ وقفت الوكلاء مؤقتاً'); await sleep(1500); }

  /* 3 · امسح القفل (استنى لو حيّ · امسح لو ميت) */
  const lock=path.join(REPO,'.git/index.lock');
  for(let i=0;i<40 && ex(lock);i++){ const age=Date.now()-fs.statSync(lock).mtimeMs;
    if(age>90000){try{fs.unlinkSync(lock);console.log('🧹 قفل ميت ('+Math.round(age/1000)+'ث)')}catch{}break}
    console.log('⏳ مستني القفل… '+Math.round(age/1000)+'ث'); await sleep(2500); }
  for(const f of ['.git/index.lock','.git/HEAD.lock','.git/refs/heads/'+BR+'.lock']) if(ex(f)){try{fs.unlinkSync(f)}catch{}}

  /* 4 · صحّح النطاق */
  const SK=new Set(['node_modules','.git','.cache','cache','_backup','snapshots','money']);
  const EXT=['.html','.htm','.xml','.txt','.js','.mjs','.cjs','.json','.yml','.yaml','.webmanifest','.css','.md','.svg','.py','.sh'];
  let nDom=0; (function walk(d0,dep=0){ if(dep>5)return; for(const e of fs.readdirSync(d0,{withFileTypes:true})){
    if(e.name.startsWith('.')&&!['.github','.nojekyll'].includes(e.name))continue; const f=path.join(d0,e.name);
    if(e.isDirectory()){if(SK.has(e.name))continue;walk(f,dep+1);continue}
    if(!EXT.some(x=>f.endsWith(x)))continue; let s=rd(f); if(!s||!s.includes('alkazmybwhwr-dot.github.io'))continue;
    if(wr(f,s.split('alkazmybwhwr-dot.github.io').join(HOST)))nDom++; }})(REPO);
  console.log('✓ النطاق: '+nDom+' ملف'); wr(path.join(REPO,'SITE_URL'),REAL+'\n');
  wr(path.join(REPO,'robots.txt'),'User-agent: *\nAllow: /\nDisallow: /data/\nSitemap: '+REAL+'/sitemap.xml\n');

  /* 5 · ضمان الملفات الحيّة */
  const A={};
  A['grid.css']=`#vn-grid-wrap{margin:14px 0}.vn-gtools{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0}.vn-gin{background:#111120;border:1px solid #23233a;color:#eceef6;border-radius:11px;padding:10px 13px;font:14px system-ui;flex:1;min-width:170px;max-width:380px}.vn-gchip{background:#111120;border:1px solid #23233a;color:#9aa0b8;border-radius:999px;padding:7px 15px;font:600 12.5px system-ui;cursor:pointer}.vn-gchip.on{background:#eceef6;color:#07070d;border-color:#eceef6}.vn-g{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:13px}.vn-g a{display:block;background:linear-gradient(180deg,#13131f,#0e0e18);border:1px solid #23233a;border-radius:16px;overflow:hidden;text-decoration:none;color:#eceef6;transition:.18s}.vn-g a:hover{transform:translateY(-4px);border-color:#3a3a5c;box-shadow:0 16px 40px #000a}.vn-g img{width:100%;aspect-ratio:2/3;object-fit:cover;background:#0a0a12;display:block}.vn-g b{display:block;font:600 13px/1.4 system-ui;padding:8px 10px 2px}.vn-g span{display:block;font:11.5px system-ui;color:#8b90a6;padding:0 10px 9px}.vn-gmore{width:100%;margin:14px 0;background:#171726;color:#eceef6;border:1px solid #23233a;border-radius:11px;padding:12px;font:700 13.5px system-ui;cursor:pointer}@media(max-width:520px){.vn-g{grid-template-columns:repeat(auto-fill,minmax(112px,1fr));gap:9px}}`;
  A['grid.js']=`(()=>{if(window.__VN_GRID)return;window.__VN_GRID=1;const H=document.getElementById('vn-grid')||document.querySelector('.grid,#grid,.cards,.vn-grid')||(()=>{const d=document.createElement('div');d.id='vn-grid';document.body.append(d);return d})();const w=document.createElement('div');w.id='vn-grid-wrap';H.parentNode.insertBefore(w,H);w.append(H);w.insertAdjacentHTML('afterbegin','<div class="vn-gtools"><input class="vn-gin" id="vnQ" placeholder="ابحث…"><button class="vn-gchip on" data-s="rate">الأعلى تقييماً</button><button class="vn-gchip" data-s="year">الأحدث</button><button class="vn-gchip" data-t="movie">أفلام</button><button class="vn-gchip" data-t="tv">مسلسلات</button></div>');H.className='vn-g';let all=[],q='',sort='rate',type='',n=60;const esc=s=>String(s==null?'':s).replace(/[<>&"]/g,c=>({'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;'}[c]));const draw=()=>{let L=all.filter(x=>!type||x.type===type).filter(x=>!q||(x.title||'').toLowerCase().includes(q)||String(x.tmdb||'').includes(q));L.sort((a,b)=>sort==='year'?(+b.year||0)-(+a.year||0):(+b.rate||0)-(+a.rate||0));H.innerHTML=L.slice(0,n).map(x=>'<a href="/p/'+x.token+'.html" title="'+esc(x.title)+'"><img loading="lazy" src="'+(x.poster||'/og.png')+'" alt="'+esc(x.title)+'" onerror="this.src=\\'/og.png\\'"><b>'+esc(x.title)+'</b><span>'+esc(x.year||'')+(x.rate?' · ★ '+esc(x.rate):'')+'</span></a>').join('');let m=w.querySelector('.vn-gmore');if(L.length>n){if(!m){w.insertAdjacentHTML('beforeend','<button class="vn-gmore">تحميل المزيد ('+(L.length-n)+')</button>');w.querySelector('.vn-gmore').onclick=()=>{n+=60;draw()}}else m.textContent='تحميل المزيد ('+(L.length-n)+')'}else if(m)m.remove()};w.querySelector('#vnQ').oninput=e=>{q=e.target.value.trim().toLowerCase();n=60;draw()};w.querySelectorAll('[data-s]').forEach(b=>b.onclick=()=>{w.querySelectorAll('[data-s]').forEach(x=>x.classList.remove('on'));b.classList.add('on');sort=b.dataset.s;draw()});w.querySelectorAll('[data-t]').forEach(b=>b.onclick=()=>{const on=b.classList.toggle('on');type=on?b.dataset.t:'';n=60;draw()});(async()=>{for(const u of ['/data/titles.json','/titles.json','/catalog.json']){try{const r=await fetch(u+'?v='+Date.now());if(!r.ok)continue;const j=await r.json();const a=Array.isArray(j)?j:Object.values(j);if(a.length>10){all=a.filter(x=>x&&x.token);draw();return}}catch{}}H.innerHTML='<p style="color:#8b90a6">تعذّر تحميل الكتالوج</p>'})()})();`;
  A['wallet.js']=`(()=>{if(window.__VN_WAL)return;window.__VN_WAL=1;const el=document.createElement('div');el.id='vn-wal';el.style.cssText='position:fixed;inset-block-end:14px;inset-inline-start:50%;transform:translateX(50%);z-index:99997;background:#111120f2;border:1px solid #2a2a44;border-radius:999px;padding:8px 16px;font:700 13px system-ui;color:#eceef6;box-shadow:0 12px 32px #000a;backdrop-filter:blur(10px);display:flex;gap:9px;align-items:center;direction:rtl';el.innerHTML='<span style="color:#5ee6a8">$—</span><span style="color:#8b90a6;font-weight:500">جارٍ…</span>';document.body.append(el);let prev=null;const tick=async()=>{for(const u of ['/wallet.json','/live.json','/earnings.json']){try{const r=await fetch(u+'?v='+Date.now());if(!r.ok)continue;const d=await r.json();const b=+(+d.balance||0),up=prev!=null&&b>prev;prev=b;el.innerHTML='<span style="color:#5ee6a8">$'+b.toFixed(4)+'</span>'+(up?'<span style="color:#5ee6a8">▲</span>':'')+'<span style="color:#8b90a6;font-weight:500">'+(+d.entries||0)+' قيد · '+((d.top||[]).length||+d.sources||0)+' مصدر</span><a href="/vn-wallet.html" style="color:#7c9cff;text-decoration:none;font-weight:600">تفاصيل</a>';return}catch{}}el.innerHTML='<span style="color:#8b90a6;font-weight:500">المحفظة غير متاحة</span>'};tick();setInterval(tick,30000);window.addEventListener('focus',tick)})();`;
  A['tmdb-img-shim.js']=`(()=>{if(window.__VN_IMG)return;window.__VN_IMG=1;window.vnPoster=(el,p,sz)=>{if(el&&p)el.src='https://image.tmdb.org/t/p/'+(sz||'w342')+(String(p).startsWith('/')?p:'/'+p)};window.vnImgFallback=el=>{const s=['/og.png','/og-default.jpg','/icon.svg'];const i=+(el.dataset.fb||0);el.dataset.fb=i+1;if(i<s.length)el.src=s[i];else el.onerror=null};const paint=()=>document.querySelectorAll('img[data-tmdb]:not([data-done])').forEach(el=>{const p=el.getAttribute('data-tmdb');if(!p)return;el.dataset.done=1;window.vnPoster(el,p,el.dataset.size||'w342')});document.addEventListener('error',e=>{if(e.target&&e.target.tagName==='IMG')window.vnImgFallback(e.target)},true);paint();new MutationObserver(paint).observe(document.documentElement,{childList:true,subtree:true})})();`;
  for(const [name,body] of Object.entries(A)){const p=path.join(REPO,name);
    if(!rd(p)||rd(p).length<200){wr(p,body);console.log('✓ '+name+' أُنشئ')}
    if(ex(path.join(REPO,'public'))&&(!rd(path.join(REPO,'public',name))||rd(path.join(REPO,'public',name)).length<200))wr(path.join(REPO,'public',name),rd(p)||body);}
  if(!ex(path.join(REPO,'.nojekyll'))){wr(path.join(REPO,'.nojekyll'),'');console.log('✓ .nojekyll')}
  if(!ex(path.join(REPO,'kuraimi.json'))){wr(path.join(REPO,'kuraimi.json'),JSON.stringify({bank:'Al-Kuraimi Islamic Microfinance Bank',swift:'KBMFYESAXXX',account:'',name:'',phone:'',min_withdraw:5,currency:'USD'},null,2));console.log('✓ kuraimi.json')}

  /* 6 · .gitignore */
  {const g0=rd(path.join(REPO,'.gitignore'))||'';let g=g0;
   for(const l of ['node_modules/','.cache/','cache/','*.log','!p/','!data/','!m/'])if(!g.split(/\r?\n/).includes(l))g+='\n'+l;
   if(wr(path.join(REPO,'.gitignore'),g.replace(/^\n+/,'')))console.log('✓ .gitignore')}

  /* 7 · حقن الشبكة/المحفظة */
  const TAGS='<link rel="stylesheet" href="/grid.css">\n<script src="/tmdb-img-shim.js" defer></script>\n<script src="/wallet.js" defer></script>\n<script src="/grid.js" defer></script>\n';
  let nInj=0; (function walk(d0,dep=0){if(dep>5)return;for(const e of fs.readdirSync(d0,{withFileTypes:true})){
    if(e.name.startsWith('.'))continue;const f=path.join(d0,e.name);
    if(e.isDirectory()){if(SK.has(e.name))continue;walk(f,dep+1);continue}
    if(!f.endsWith('.html'))continue;let s=rd(f);if(!s||!s.includes('</head>')||s.includes('/grid.js'))continue;
    if(wr(f,s.replace('</head>',TAGS+'</head>')))nInj++;}})(REPO);
  console.log('✓ حقن الواجهة في '+nInj+' صفحة');

  /* 8 · رتّب + ارفع */
  console.log('▸ git add -A …'); sh('git',['add','-A']);
  const st=(sh('git',['status','--porcelain']).stdout||'').trim(),n=st?st.split('\n').length:0;
  console.log('  ملفات مُرتّبة: '+n);
  if(n){const c=sh('git',['-c','user.name='+m[1],'-c','user.email='+m[1]+'@users.noreply.github.com','commit','-m','build: real domain + assets + panel + withdraw + agents']);console.log(c.status===0?'  ✓ commit':'  ✗ commit: '+(c.stderr||'').slice(-200))}
  let ok=false;
  for(let a=1;a<=3&&!ok;a++){console.log('▸ push محاولة '+a+' …');
    const r=sh('bash',['-lc','git push origin '+BR+' 2>&1 | tail -6']);console.log(r.stdout||'');
    ok=r.status===0&&!/rejected|fatal|error/i.test(r.stdout||'');
    if(!ok){try{fs.unlinkSync(lock)}catch{}await sleep(3000)}}
  console.log(ok?'✓ اترفع':'✗ الرفع فشل');

  /* 9 · شغّل الوكلاء */
  if(!KEEP){const lg=path.join(REPO,'money/logs');fs.mkdirSync(lg,{recursive:true});
    for(const [f,ar] of [['heal.mjs',['--watch']],['panel.mjs',[]],['agent.mjs',[]],['tick.mjs',[]]]){
      const p=path.join(REPO,'money',f);if(!ex(p))continue;
      sh('bash',['-lc','nohup node "'+p+'" '+ar.join(' ')+' >> "'+path.join(lg,f.replace('.mjs','.log'))+'" 2>&1 &']);}
    await sleep(1500);
    console.log('✓ الوكلاء: '+(sh('bash',['-lc',"pgrep -af money/ | grep -v one.mjs | wc -l"]).stdout||'').trim()+' عملية');}
}

/* 10 · تحقق حي — بستنى الصفحات تظهر */
console.log('\n══ تحقق حي (لحد 3 دقايق) ══');
let good=0;
for(let r=1;r<=10&&good<TARGETS.length;r++){
  good=0;const line=[];
  for(const p of TARGETS){const s=await get(REAL+p);if(s===200)good++;line.push(p.replace('/','')+'='+s)}
  console.log(' جولة '+r+' ['+good+'/'+TARGETS.length+']  '+line.join('  '));
  if(good<TARGETS.length)await sleep(18000);
}
console.log('\n'+(good===TARGETS.length?'✓✓ التطبيق حيّ بالكامل':'⚠ ناقص '+(TARGETS.length-good)+' — استنى دقيقة وأعد: node money/one.mjs --check'));
console.log('► '+REAL+'\n► اللوحة '+REAL+'/vn-panel.html · المحفظة '+REAL+'/vn-wallet.html · السحب '+REAL+'/withdraw.html');
console.log('► النسخ الاحتياطي: '+path.relative(REPO,BK));
