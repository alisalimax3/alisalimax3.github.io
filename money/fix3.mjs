#!/usr/bin/env node
/* money/fix3.mjs — كتالوج مُصفَّح + مشغّل حقيقي + تصنيفات + SW شبكي + sitemap */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const HERE=path.dirname(fileURLToPath(import.meta.url)), REPO=path.resolve(HERE,'..');
process.chdir(REPO);
const R=(p,d='')=>{try{return fs.readFileSync(p,'utf8')}catch{return d}};
const W=(p,s)=>fs.writeFileSync(p,s);
const has=p=>fs.existsSync(p);
const log=(...a)=>console.log(...a);

/* 1 · كتالوج مُصفَّح (كل الـ10 آلاف قابل للتصفح) */
let items=[];
try{const d=JSON.parse(R('catalog.json')||'[]');items=Array.isArray(d)?d:(d.items||[]);}catch{}
if(items.length){
  const CH=900,n=Math.ceil(items.length/CH);
  for(let i=0;i<n;i++) W('catalog-p'+i+'.json',JSON.stringify({page:i,pages:n,total:items.length,items:items.slice(i*CH,(i+1)*CH)}));
  W('catalog-index.json',JSON.stringify({total:items.length,pages:n,per:CH,generated:new Date().toISOString()}));
  log('✓ كتالوج مُصفَّح: '+n+' صفحة × '+CH+' = '+items.length);
}

/* 2 · مشغّل حقيقي */
if(!has('watch.html')){
W('watch.html',`<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>مشاهدة — CineHub 3099</title><link rel="manifest" href="/manifest.webmanifest"><meta name="theme-color" content="#0a0c15">
<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap" rel="stylesheet">
<style>body{margin:0;background:#0a0c15;color:#eef1f8;font-family:Cairo,system-ui,sans-serif;padding-bottom:90px}
.wrap{max-width:1000px;margin:0 auto;padding:14px}.player{aspect-ratio:16/9;background:#000;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,.1)}
.player iframe,.player video{width:100%;height:100%;border:0;display:block}h1{font-size:20px;margin:14px 0 6px}
.meta{color:#98a0b8;font-size:13px;margin-bottom:12px}.src{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0}
.src button{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.12);color:#eef1f8;padding:8px 14px;border-radius:999px;cursor:pointer;font-family:inherit}
.src button.on{background:linear-gradient(135deg,#6c5ce7,#00d2ff);border-color:transparent;color:#fff}.back{display:inline-block;margin-bottom:10px;color:#98a0b8;text-decoration:none}</style></head>
<body><div class="wrap"><a class="back" href="/">← الرئيسية</a>
<div class="player" id="pl"></div><h1 id="t">...</h1><div class="meta" id="m"></div><div class="src" id="src"></div></div>
<script>
var Q=new URLSearchParams(location.search),ID=Q.get('id'),T=Q.get('t');
function play(u){var p=document.getElementById('pl');
 if(!u){p.innerHTML='<div style="display:flex;align-items:center;justify-content:center;height:100%;color:#98a0b8">لا يوجد مصدر تشغيل</div>';return;}
 if(/\\.(mp4|m4v|webm)(\\?|$)/i.test(u))p.innerHTML='<video src="'+u+'" controls autoplay playsinline></video>';
 else p.innerHTML='<iframe src="'+u+'" allowfullscreen allow="autoplay;fullscreen"></iframe>';}
document.getElementById('t').textContent=T||('عنصر '+ID);
fetch('/catalog-lite.json').then(function(r){return r.json()}).then(function(d){
 var a=d.items||[],it=null;
 if(ID!=null)it=a.filter(function(x){return String(x.id)==String(ID)})[0];
 if(!it&&T)it=a.filter(function(x){return (x.t||x.title||x.name)==T})[0];
 if(!it){play(null);return;}
 document.getElementById('t').textContent=it.t||it.title||it.name||T||'';
 document.getElementById('m').textContent=[it.y||it.year,it.c||it.cat||it.category,it.g||it.genre].filter(Boolean).join(' · ');
 var urls=[it.u,it.url,it.link,it.embed].filter(Boolean);
 if(!urls.length)urls=['https://www.youtube.com/embed?listType=search&list='+encodeURIComponent(it.t||it.title||T||'')];
 var s=document.getElementById('src');
 s.innerHTML=urls.map(function(u,i){return '<button data-u="'+u+'"'+(i===0?' class="on"':'')+'>مصدر '+(i+1)+'</button>'}).join('');
 s.addEventListener('click',function(e){var b=e.target.closest('button');if(!b)return;
  s.querySelectorAll('button').forEach(function(x){x.classList.remove('on')});b.classList.add('on');play(b.dataset.u);});
 play(urls[0]);
}).catch(function(){play(null)});
</script></body></html>`);
log('✓ watch.html');
}

/* 3 · تصنيفات */
if(!has('cats.html')){
W('cats.html',`<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>التصنيفات — CineHub 3099</title>
<link rel="manifest" href="/manifest.webmanifest"><meta name="theme-color" content="#0a0c15">
<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap" rel="stylesheet">
<style>body{margin:0;background:#0a0c15;color:#eef1f8;font-family:Cairo,system-ui,sans-serif;padding:14px 14px 100px}
h1{font-size:20px}.chips{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0}
.chip{padding:8px 15px;border-radius:999px;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.1);cursor:pointer;font-size:13px}
.chip.on{background:linear-gradient(135deg,#6c5ce7,#00d2ff);border-color:transparent;color:#fff}
.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px}
.c{border-radius:14px;overflow:hidden;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.09);display:block;text-decoration:none;color:inherit}
.c img{width:100%;aspect-ratio:2/3;object-fit:cover;display:block}.c span{display:block;padding:8px 10px;font-size:12.5px}</style></head>
<body><h1>التصنيفات</h1><div class="chips" id="ch"><div class="chip on">الكل</div></div><div class="g" id="g"></div>
<script>var ALL=[],CAT='';
function render(){var g=document.getElementById('g');
 var a=CAT?ALL.filter(function(x){return String(x.c||x.cat||x.category||x.genre||'').indexOf(CAT)>-1}):ALL;
 g.innerHTML=a.slice(0,300).map(function(x){var t=x.t||x.title||x.name||'',p=x.p||x.poster||x.img||x.image||'';
  return '<a class="c" href="/watch.html?id='+encodeURIComponent(x.id||'')+'&t='+encodeURIComponent(t)+'">'+(p?'<img loading="lazy" src="'+p+'" onerror="this.remove()">':'')+'<span>'+t+'</span></a>'}).join('');}
fetch('/catalog-cats.json').then(function(r){return r.json()}).then(function(d){
 document.getElementById('ch').innerHTML='<div class="chip on">الكل</div>'+(d.cats||[]).map(function(c){return '<div class="chip">'+c+'</div>'}).join('');
 document.getElementById('ch').addEventListener('click',function(e){var c=e.target.closest('.chip');if(!c)return;
  document.querySelectorAll('.chip').forEach(function(x){x.classList.remove('on')});c.classList.add('on');
  CAT=c.textContent==='الكل'?'':c.textContent;render();});}).catch(function(){});
fetch('/catalog-lite.json').then(function(r){return r.json()}).then(function(d){ALL=d.items||[];render()}).catch(function(){});
</script></body></html>`);
log('✓ cats.html');
}

/* 4 · SW شبكي */
W('sw.js',`/* CineHub SW v3 */
const V='cinehub-v3';
self.addEventListener('install',e=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;
 const u=new URL(r.url);if(u.origin!==location.origin)return;
 const data=/\\.json$/i.test(u.pathname)||/\\.html$/i.test(u.pathname)||u.pathname==='/';
 if(data){e.respondWith(fetch(r).then(res=>{const c=res.clone();caches.open(V).then(x=>x.put(r,c));return res}).catch(()=>caches.match(r)));}
 else{e.respondWith(caches.match(r).then(c=>c||fetch(r).then(res=>{const cc=res.clone();caches.open(V).then(x=>x.put(r,cc));return res})));}});
`);
log('✓ sw.js شبكي v3');

/* 5 · sitemap + robots */
try{const hs=fs.readdirSync('.').filter(x=>x.endsWith('.html'));
 W('sitemap.xml','<?xml version="1.0" encoding="UTF-8"?>\\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\\n'+hs.map(x=>'  <url><loc>https://alisalimax3.github.io/'+(x==='index.html'?'':x)+'</loc></url>').join('\\n')+'\\n</urlset>\\n');
 W('robots.txt','User-agent: *\\nAllow: /\\nSitemap: https://alisalimax3.github.io/sitemap.xml\\n');
 log('✓ sitemap.xml ('+hs.length+') + robots.txt');}catch(e){log('⚠ '+e.message)}

/* 6 · تنظيف التكرار + ربط البطاقات بالمشغّل */
let n2=0;
for(const f of fs.readdirSync('.').filter(x=>x.endsWith('.html'))){
 let s=R(f);if(!s)continue;const b=s;
 s=s.replace(/'\/catalog-lite\.json','catalog-lite\.json','\/catalog-lite\.json','catalog-lite\.json'/g,"'/catalog-lite.json','catalog-lite.json','/catalog.json','catalog.json'");
 if(s.includes('<!--/VN-UI-->')&&!s.includes('VN-WATCHLINK')){
  s=s.replace('<!--/VN-UI-->','<!--VN-WATCHLINK--><script>(function(){document.addEventListener("click",function(e){var a=e.target.closest(".vn-card");if(!a)return;var h=a.getAttribute("href");if(!h||h==="#"){e.preventDefault();var t=a.querySelector(".vn-t");location.href="/watch.html?t="+encodeURIComponent(t?t.textContent:"")}});})();<\\/script><!--/VN-WATCHLINK-->\n<!--/VN-UI-->');
 }
 if(s!==b){W(f,s);n2++;}
}
log('✓ نظّفت '+n2+' صفحة (تكرار fallback + ربط المشغّل)');
log('تم.');
