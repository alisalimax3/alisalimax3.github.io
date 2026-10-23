const fs=require('fs'),path=require('path');const AX=process.argv[2],M=process.argv[3],FAST=process.argv[4]==='1';
const D={ptc:['crypto',1],faucet:['crypto',0.01],shortener:['paypal',5],ads:['bank',100],affiliate:['bank',50],
survey:['paypal',5],micro:['paypal',10],freelance:['paypal',20],content:['paypal',10],stock:['paypal',30],
merch:['paypal',10],music:['paypal',10],pod:['paypal',10],social:['paypal',100],market:['bank',10],mena:['bank',10],
crypto:['crypto',1],passive:['crypto',5],game:['paypal',5],host:['paypal',50],store:['bank',10],dir:['free',0],
jobs:['none',0],pay:['none',0],bounty:['crypto',10],test:['paypal',10],cashback:['paypal',10],ai:['paypal',10],cloud:['paypal',10]};
const map=new Map();
const add=(d,c,s)=>{d=String(d||'').trim().toLowerCase().replace(/^https?:\/\//,'').replace(/\/.*$/,'');
 if(!d||!d.includes('.'))return; const id=d.replace(/[^a-z0-9.]/g,'_');
 if(map.has(id))return; const x=D[c]||['unknown',0]; map.set(id,{id,domain:d,cat:c||'other',method:x[0],min:x[1],src:s});};
fs.readFileSync(path.join(AX,'registry/seed.tsv'),'utf8').split('\n').forEach(l=>{if(!l.trim()||l[0]==='#')return;const p=l.split('|');add(p[0],p[1]||'other','seed');});
for(const rel of ['data/catalog.json','data/platforms.json']){const f=path.join(M,rel);if(!fs.existsSync(f))continue;
 try{const j=JSON.parse(fs.readFileSync(f,'utf8'));const a=Array.isArray(j)?j:(j.platforms||j.sites||j.items||[]);
 a.forEach(x=>add(typeof x==='string'?x:(x.domain||x.host||x.url||x.site||x.name),x.cat||x.category||'other','catalog'));}catch(e){}}
const YE={crypto:1,payoneer:1,westernunion:1,moneygram:1,ria:1,payeer:1,airtm:1,skrill:.5,paypal:.4,wise:.5,bank:.5,free:1,none:1,unknown:.5};
const rows=[...map.values()];rows.forEach(r=>{r.ye=YE[r.method]??.5;r.tier=r.ye>=1?'A':(r.ye>=.5?'B':'C');});
fs.writeFileSync(path.join(AX,'registry/platforms.json'),JSON.stringify({built:new Date().toISOString(),count:rows.length,platforms:rows}));
const F=[['root','https://{d}/'],['signup','https://{d}/signup'],['login','https://{d}/login'],['api','https://api.{d}/'],
['docs','https://{d}/docs'],['help','https://{d}/help'],['terms','https://{d}/terms'],['privacy','https://{d}/privacy'],
['blog','https://{d}/blog'],['pricing','https://{d}/pricing'],['affiliate','https://{d}/affiliate'],['partners','https://{d}/partners'],
['payout','https://{d}/payout'],['sitemap','https://{d}/sitemap.xml'],['robots','https://{d}/robots.txt'],['rss','https://{d}/feed'],
['careers','https://{d}/careers'],['support','https://{d}/support'],['api2','https://{d}/api']];
const use=FAST?F.filter(f=>['root','signup','login','api'].includes(f[0])):F;
let o='';rows.forEach(r=>use.forEach(([k,t])=>o+=r.id+'\t'+k+'\t'+t.replace('{d}',r.domain)+'\n'));
fs.writeFileSync(path.join(AX,'registry/probe.tsv'),o);
console.log('platforms='+rows.length+' facets='+use.length+' probe_rows='+o.trim().split('\n').length);
