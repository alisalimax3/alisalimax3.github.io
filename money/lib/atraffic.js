#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js");
let ID={brand:"CineHub",handle:"cinehub",desc_short_ar:"منصة أفلام ومسلسلات وأنمي مترجمة بجودة عالية"};
try{ID=Object.assign(ID,JSON.parse(fs.readFileSync(path.join(D,"identity.json"),"utf8")));}catch(e){}
const pub=(K.get("PUBLIC_URL")||"").replace(/\/$/,"");
let KW=[];try{KW=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords||[];}catch(e){}
const KWS=KW.length?KW:["افلام اون لاين","مسلسلات مترجمة","انمي مترجم"];
const LANGS=["ar","en","fr","es","de","tr","pt","id"];
const DIR=path.join(ROOT,"seo");fs.mkdirSync(DIR,{recursive:true});
const slug=s=>s.trim().replace(/\s+/g,"-").replace(/[^\w\u0600-\u06FF\-]/g,"");
function page(q,lang,i){
  const url=pub+"/seo/"+slug(q)+"-"+lang+".html";
  const alt=LANGS.map(l=>'<link rel="alternate" hreflang="'+l+'" href="'+pub+"/seo/"+slug(q)+"-"+l+'.html">').join("\n");
  const ld=JSON.stringify({"@context":"https://schema.org","@type":"WebSite",name:ID.brand,url:pub,
    potentialAction:{"@type":"SearchAction",target:pub+"/?q={search_term_string}","query-input":"required name=search_term_string"}});
  return `<!doctype html><html lang="${lang}" dir="${lang==="ar"?"rtl":"ltr"}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${q} — ${ID.brand}</title>
<meta name="description" content="${q} على ${ID.brand}: ${ID.desc_short_ar}">
<link rel="canonical" href="${url}">
${alt}
<meta property="og:title" content="${q} — ${ID.brand}"><meta property="og:type" content="website"><meta property="og:url" content="${url}">
<meta name="theme-color" content="#2563eb"><link rel="icon" href="/assets/logo.png">
<script type="application/ld+json">${ld}</script>
<style>body{margin:0;font-family:system-ui;background:#0b0e14;color:#e8eef7;line-height:1.8}
.w{max-width:900px;margin:auto;padding:28px}a{color:#7dd3fc}h1{font-size:1.9rem}ul{columns:2}
.card{background:#121826;border:1px solid #1e293b;border-radius:14px;padding:18px;margin:14px 0}</style></head>
<body><div class="w"><h1>${q}</h1>
<div class="card"><p>${ID.desc_short_ar}</p>
<p><a href="/">→ الصفحة الرئيسية</a> · <a href="${pub}/sitemap.xml">خريطة الموقع</a> · <a href="${pub}/rss.xml">RSS</a></p></div>
<div class="card"><h2>تصفّح بـ</h2><ul>${LANGS.map(l=>'<li><a href="'+slug(q)+'-'+l+'.html">'+q+' ('+l+')</a></li>').join("")}</ul></div>
<div class="card" id="ad"><!-- AD-SLOT --></div>
<footer><p>© ${new Date().getFullYear()} ${ID.brand}</p></footer></div></body></html>`;}
const made=[];
for(const q of KWS)for(const l of LANGS){const f=path.join(DIR,slug(q)+"-"+l+".html");fs.writeFileSync(f,page(q,l));made.push(path.relative(ROOT,f).replace(/\\/g,"/"));}
const urls=made.map(u=>pub+"/"+u);
fs.writeFileSync(path.join(ROOT,"sitemap.xml"),'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'+
  [pub+"/"].concat(urls).map(u=>"<url><loc>"+u+"</loc><changefreq>daily</changefreq></url>").join("\n")+"\n</urlset>\n");
fs.writeFileSync(path.join(ROOT,"rss.xml"),'<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>'+ID.brand+'</title><link>'+pub+'</link><description>'+ID.desc_short_ar+'</description>\n'+
  urls.slice(0,50).map(u=>"<item><title>"+u.split("/").pop().replace(/-/g," ")+"</title><link>"+u+"</link></item>").join("\n")+"</channel></rss>\n");
fs.writeFileSync(path.join(ROOT,"atom.xml"),'<?xml version="1.0" encoding="UTF-8"?>\n<feed xmlns="http://www.w3.org/2005/Atom"><title>'+ID.brand+'</title><link href="'+pub+'"/>\n'+
  urls.slice(0,50).map(u=>'<entry><title>'+u.split("/").pop()+'</title><link href="'+u+'"/></entry>').join("\n")+"</feed>\n");
fs.writeFileSync(path.join(ROOT,"robots.txt"),"User-agent: *\nAllow: /\nCrawl-delay: 1\nSitemap: "+pub+"/sitemap.xml\n");
fs.writeFileSync(path.join(ROOT,"security.txt"),"Contact: "+(K.get("CONTACT_EMAIL")||"mailto:")+"\nExpires: "+new Date(Date.now()+31536e6).toISOString()+"\n");
fs.writeFileSync(path.join(ROOT,"humans.txt"),"/* TEAM */ "+ID.brand+"\n/* SITE */ "+(pub||"local")+"\n");
fs.writeFileSync(path.join(ROOT,"opensearch.xml"),'<?xml version="1.0"?><OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/"><ShortName>'+ID.brand+'</ShortName><Url type="text/html" template="'+pub+'/?q={searchTerms}"/></OpenSearchDescription>');
if(!fs.existsSync(path.join(ROOT,"ads.txt")))fs.writeFileSync(path.join(ROOT,"ads.txt"),"# أضف سطور شبكاتك بعد القبول\n");
console.log("  ✔ مولّد الزيارات: "+made.length+" صفحة SEO + sitemap + rss + atom + robots + security + opensearch");
require("./aaudit.js").add("traffic",{pages:made.length});
