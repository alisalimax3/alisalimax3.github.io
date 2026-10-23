#!/usr/bin/env node
/* money/appfix.mjs — يصلّح تحميل الكتالوج + كتالوج خفيف + إعلانات مرنة + مسح كاش */
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
const HERE=path.dirname(fileURLToPath(import.meta.url)), REPO=path.resolve(HERE,'..');
process.chdir(REPO);
const R=(p,d)=>{try{return fs.readFileSync(p,'utf8')}catch{return d}};
const W=(p,s)=>fs.writeFileSync(p,s);

/* 1 · كتالوج خفيف يتحمّل فورًا */
try{
  const raw=R('catalog.json','');
  if(raw){
    const d=JSON.parse(raw), items=Array.isArray(d)?d:(d.items||[]);
    W('catalog-lite.json', JSON.stringify({generated:new Date().toISOString(),source:'catalog.json',count:Math.min(items.length,900),items:items.slice(0,900)}));
    const cats=[...new Set(items.map(x=>x&&(x.c||x.cat||x.category)).filter(Boolean))];
    W('catalog-cats.json', JSON.stringify({count:cats.length,cats}));
    console.log('✓ catalog-lite.json ('+Math.min(items.length,900)+' عنصر) + catalog-cats.json ('+cats.length+' تصنيف)');
  } else console.log('⚠ catalog.json مش موجود');
}catch(e){ console.log('⚠ الكتالوج الخفيف فشل: '+e.message); }

/* 2 · كل صفحات HTML: خفيف الأول + تسجيل سبب الفشل */
let fixed=0;
for(const f of fs.readdirSync('.').filter(x=>x.endsWith('.html'))){
  let s=R(f,''); if(!s) continue; let ch=false;
  if(s.includes("'catalog.json'") && !s.includes('catalog-lite.json')){
    s=s.replace(/'catalog\.json'/g,"'catalog-lite.json','catalog.json'"); ch=true;
  }
  if(s.includes('catch(e){}}return[]}') && !s.includes('__catErr')){
    s=s.replace('catch(e){}}return[]}',"catch(e){window.__catErr=(window.__catErr||'')+f+' '+(e&&e.message||'')+'; '}}return[]}"); ch=true;
  }
  if(ch){ W(f,s); fixed++; }
}
console.log('✓ اتصلّح '+fixed+' صفحة');

/* 3 · index.html: تشخيص + إخفاء الإعلانات الفاشلة + تحديث الـSW */
if(fs.existsSync('index.html')){
  let s=R('index.html','');
  if(!s.includes('VN-APPFIX')){
    const blk=`<!--VN-APPFIX-->
<script>
(function(){
  setTimeout(function(){
    var g=document.getElementById('g');
    if(g && g.textContent.indexOf('تعذّر')>-1){
      var e=(window.__catErr||'').slice(0,150)||'لم تُرجع الملفات بيانات';
      g.innerHTML='<p style="color:#8b90a6;font-size:13px">تعذّر تحميل الكتالوج<br><small style="opacity:.65;font-size:11px">'+e+'</small></p>';
    }
    document.querySelectorAll('.ad iframe').forEach(function(fr){
      try{ if(fr.getBoundingClientRect().height<10) fr.style.display='none'; }catch(x){}
    });
  },6000);
  if('serviceWorker' in navigator && navigator.serviceWorker.getRegistrations){
    navigator.serviceWorker.getRegistrations().then(function(r){r.forEach(function(x){x.update()})});
  }
})();
</script>
<!--/VN-APPFIX-->
`;
    const i=s.lastIndexOf('</body>');
    s = i>-1 ? s.slice(0,i)+blk+s.slice(i) : s+blk;
    W('index.html',s); console.log('✓ index.html: تشخيص + إعلانات مرنة');
  }
}

/* 4 · امسح كاش الـservice worker */
if(fs.existsSync('sw.js')){
  let s=R('sw.js','');
  if(!s.includes('VN-SWFIX')){
    s+="\n/* VN-SWFIX — امسح كل الكاش عند التحديث */\nself.addEventListener('activate',function(e){e.waitUntil(caches.keys().then(function(ks){return Promise.all(ks.map(function(k){return caches.delete(k)}))}))});\n";
    W('sw.js',s); console.log('✓ sw.js: مسح الكاش');
  }
}
console.log('تم.');
