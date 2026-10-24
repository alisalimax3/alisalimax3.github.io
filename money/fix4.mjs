#!/usr/bin/env node
/* money/fix4.mjs — تطبيع الحقول th/e→p/u + إصلاح العرض والمشغّل + مُصفَّح + sites */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const HERE=path.dirname(fileURLToPath(import.meta.url)),REPO=path.resolve(HERE,'..');
process.chdir(REPO);
const R=(p,d='')=>{try{return fs.readFileSync(p,'utf8')}catch{return d}};
const W=(p,s)=>fs.writeFileSync(p,s);
const log=(...a)=>console.log(...a);

function norm(o){
  if(!o||typeof o!=='object')return o;
  const t=o.t||o.title||o.name||'';
  const th=o.th||o.p||o.poster||o.img||o.image||o.thumb||'';
  const e=o.e||o.embed||o.u||o.url||o.link||'';
  const c=o.c||o.cat||o.category||o.genre||'';
  const y=o.y||o.year||'';
  return Object.assign({},o,{t:t,title:t,p:th,th:th,e:e,u:e,c:c,cat:c,y:y,year:y});
}

let items=[];
try{const d=JSON.parse(R('catalog.json')||'[]');items=(Array.isArray(d)?d:(d.items||[])).map(norm);}catch(e){log('⚠ '+e.message)}
if(!items.length){log('✗ لا كتالوج');process.exit(1);}
log('✓ كتالوج: '+items.length+' عنصر');
log('  ببوستر: '+items.filter(x=>x.p).length+'/'+items.length+' · برابط تشغيل: '+items.filter(x=>x.e).length+'/'+items.length);

W('catalog.json',JSON.stringify({count:items.length,items:items}));
const lite=items.slice(0,900);
W('catalog-lite.json',JSON.stringify({generated:new Date().toISOString(),count:lite.length,items:lite}));
const cats=[...new Set(items.map(x=>x.c).filter(Boolean))];
W('catalog-cats.json',JSON.stringify({count:cats.length,cats:cats}));
const CH=900,n=Math.ceil(items.length/CH);
for(let i=0;i<n;i++)W('catalog-p'+i+'.json',JSON.stringify({page:i,pages:n,total:items.length,items:items.slice(i*CH,(i+1)*CH)}));
W('catalog-index.json',JSON.stringify({total:items.length,pages:n,per:CH}));
log('✓ lite 900 · تصنيفات '+cats.length+' · مُصفَّح '+n+'×'+CH);

let n1=0;
for(const f of fs.readdirSync('.').filter(x=>x.endsWith('.html'))){
  let s=R(f);if(!s)continue;const b=s;
  s=s.replace(/\.thumb\|\|/g,'.th||').replace(/\.poster\|\|/g,'.th||').replace(/\.image\|\|/g,'.th||');
  s=s.replace(/\.embed\|\|/g,'.e||');
  if(s!==b){W(f,s);n1++;}
}
log('✓ سلاسل الحقول: '+n1+' صفحة');

if(fs.existsSync('watch.html')){
  let s=R('watch.html');const b=s;
  s=s.replace(/\[it\.u\s*,\s*it\.url\s*,\s*it\.link\s*,\s*it\.embed\]/,'[it.e,it.embed,it.u,it.url,it.link]');
  s=s.replace(/it\.u\s*\|\|\s*it\.url/,'it.e||it.u||it.url');
  s=s.replace(/it\.p\s*\|\|\s*it\.poster/,'it.th||it.p||it.poster');
  if(s!==b){W('watch.html',s);log('✓ watch.html مُصلَّح');}
}

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

try{
  const hs=fs.readdirSync('.').filter(x=>x.endsWith('.html'));
  W('sitemap.xml','<?xml version="1.0" encoding="UTF-8"?>\\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\\n'+hs.map(x=>'  <url><loc>https://alisalimax3.github.io/'+(x==='index.html'?'':x)+'</loc></url>').join('\\n')+'\\n</urlset>\\n');
  W('robots.txt','User-agent: *\\nAllow: /\\nSitemap: https://alisalimax3.github.io/sitemap.xml\\n');
  log('✓ sitemap ('+hs.length+') + robots');
}catch(e){log('⚠ '+e.message)}

try{
  const lj=JSON.parse(R('links.json')||'{}');
  const arr=Array.isArray(lj)?lj:(lj.items||lj.links||[]);
  const uniq=[...new Set(arr.map(x=>typeof x==='string'?x:(x.url||x.u||'')).filter(Boolean))];
  const L=JSON.stringify(uniq);
  W('sites.html','<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">'+
  '<meta name="viewport" content="width=device-width,initial-scale=1"><title>المواقع — CineHub 3099</title>'+
  '<meta name="theme-color" content="#0a0c15"><style>body{margin:0;background:#0a0c15;color:#eef1f8;'+
  'font-family:Cairo,system-ui,sans-serif;padding:16px 16px 100px}h1{font-size:20px}'+
  '.g{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:10px;margin-top:14px}'+
  'a.c{display:block;padding:12px 14px;border-radius:14px;background:rgba(255,255,255,.045);'+
  'border:1px solid rgba(255,255,255,.09);color:inherit;text-decoration:none;font-size:13px;word-break:break-all}'+
  'a.c:hover{border-color:#6c5ce7}</style></head><body><h1>المواقع المربوطة ('+uniq.length+')</h1>'+
  '<div class="g" id="g"></div><script>var U='+L+';document.getElementById("g").innerHTML=U.map(function(u){'+
  'var h="";try{h=new URL(u).hostname}catch(e){h=u}return \'<a class="c" href="\'+u+\'" target="_blank" rel="noopener">\'+h+'+
  '\'<br><small style="opacity:.5">\'+u.slice(0,50)+\'</small></a>\'}).join("");<\\/script></body></html>');
  log('✓ sites.html ('+uniq.length+' موقع)');
}catch(e){log('⚠ sites: '+e.message)}
log('تم.');
