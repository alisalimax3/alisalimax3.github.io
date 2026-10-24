#!/usr/bin/env node
/* money/audit.mjs — فحص حقيقي للموقع المباشر */
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';
const B='https://alisalimax3.github.io', out=[];
const P=s=>{out.push(s);console.log(s);};
function get(u){try{const o=execFileSync('curl',['-4','-s','-L','--max-time','25','-w','__C__%{http_code}__S__%{size_download}','-o','-',u],{encoding:'utf8',maxBuffer:3e8});
  const i=o.lastIndexOf('__C__'),m=o.slice(i).match(/__C__(\d+)__S__(\d+)/)||[];
  return{body:o.slice(0,i),code:m[1]||'?',size:+(m[2]||0)};}catch{return{body:'',code:'ERR',size:0};}}
function head(u){try{return execFileSync('curl',['-4','-s','-o','/dev/null','--max-time','15','-w','%{http_code}','-I',u],{encoding:'utf8'}).trim();}catch{return'ERR';}}

P('===== 1 · نقاط النشر =====');
const eps=['/?nocache=1','/app.html','/movies.html','/cats.html','/watch.html','/vn-panel.html','/vn-wallet.html','/links.json','/keys.json','/catalog-lite.json','/catalog-cats.json','/catalog-index.json','/manifest.webmanifest','/icon.svg','/sw.js'];
const live={};for(const e of eps){const r=get(B+e);live[e]=r;P('  '+r.code+'  '+String(r.size).padStart(8)+'B  '+e);}

P('\n===== 2 · الرئيسية: ماذا تُنتج =====');
const h=live['/?nocache=1'].body;
P('  الحجم: '+h.length+'B · إشارات catalog-lite: '+((h.match(/catalog-lite\.json/g)||[]).length)+' · VN-UI: '+(h.includes('VN-UI')?'نعم':'لا'));
P('  في مفتاح تشغيل/مشغّل: '+((h.match(/player|watch|iframe|video/gi)||[]).length));
P('  عناصر script: '+((h.match(/<script/g)||[]).length));

P('\n===== 3 · الكتالوج =====');
try{const cl=JSON.parse(live['/catalog-lite.json'].body||'{}'),it=cl.items||[];
 P('  count='+cl.count+' · عناصر='+it.length);
 if(it.length){P('  حقول: '+[...new Set(it.flatMap(o=>Object.keys(o)))].join(', '));
  P('  ببوستر: '+it.filter(o=>o.p||o.poster||o.img||o.image).length+'/'+it.length);
  P('  برابط تشغيل: '+it.filter(o=>o.u||o.url||o.link).length+'/'+it.length);
  P('  مثال: '+JSON.stringify(it[0]).slice(0,220));}
}catch(e){P('  ✗ '+e.message);}

P('\n===== 4 · الروابط =====');
try{const lj=JSON.parse(live['/links.json'].body||'{}'),arr=Array.isArray(lj)?lj:(lj.items||lj.links||[]);
 P('  العدد: '+arr.length);
 const hs={};for(const x of arr){try{hs[new URL(typeof x==='string'?x:(x.url||x.u||'')).hostname]=(hs[new URL(typeof x==='string'?x:(x.url||x.u||'')).hostname]||0)+1}catch{}}
 P('  نطاقات: '+Object.keys(hs).length+' · أعلاها: '+Object.entries(hs).sort((a,b)=>b[1]-a[1]).slice(0,10).map(x=>x[0]).join(' '));
 let ok=0,bad=0;for(const x of arr.slice(0,30)){const u=typeof x==='string'?x:(x.url||x.u||'');if(!u)continue;
  const c=head(u);if(c.startsWith('2')||c.startsWith('3'))ok++;else{bad++;if(bad<=8)P('    '+c+' '+u.slice(0,75));}}
 P('  حيّ: '+ok+' · فاشل: '+bad);
}catch(e){P('  ✗ '+e.message);}

P('\n===== 5 · المفاتيح =====');
try{const kj=JSON.parse(live['/keys.json'].body||'{}'),arr=Array.isArray(kj)?kj:(kj.keys||kj.items||[]);
 P('  العدد: '+arr.length+' · مثال: '+JSON.stringify(arr[0]).slice(0,180));}catch(e){P('  ✗ '+e.message);}

P('\n===== 6 · المستودع =====');
const f=execFileSync('git',['ls-files'],{encoding:'utf8'}).split('\n').filter(Boolean);
P('  إجمالي: '+f.length+' · html بالجذر: '+f.filter(x=>/^[^/]+\.html$/.test(x)).length+' · .sh: '+f.filter(x=>x.endsWith('.sh')).length+' · .bak: '+f.filter(x=>x.includes('.bak')).length);
const htmls=fs.readdirSync('.').filter(x=>x.endsWith('.html'));
const noUI=htmls.filter(x=>!fs.readFileSync(x,'utf8').includes('VN-UI'));
P('  VN-UI: '+(htmls.length-noUI.length)+'/'+htmls.length+(noUI.length?' · بدون: '+noUI.slice(0,12).join(', '):''));

fs.writeFileSync('audit-report.txt',out.join('\n'));
P('\n✓ التقرير محفوظ: audit-report.txt');
