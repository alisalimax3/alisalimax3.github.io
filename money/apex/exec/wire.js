const fs=require('fs'),path=require('path');
const ROOT=process.argv[2],AX=process.argv[3];
const envF=path.join(ROOT,'money','keys.env');
let env='';try{env=fs.readFileSync(envF,'utf8')}catch(e){}
const K=k=>(env.match(new RegExp('^'+k+'\\s*=\\s*(\\S+)','m'))||[])[1]||'';
const Z={adsense:K('ADSENSE_CLIENT'),exoclick:K('EXOCLICK_ZONE'),juicyads:K('JUICYADS_ZONE'),
 monetag:K('MONETAG_ZONE'),adsterra:K('ADSTERRA_HOST'),propeller:K('PROPELLERADS_ZONE')};
const SKIP=new Set(['node_modules','.git','.tmp','.check','apex','profiles','.venv','dist','build','logs']);
function walk(d,depth){if(depth>6)return[];let o=[];
 let es=[];try{es=fs.readdirSync(d,{withFileTypes:true})}catch(e){return[]}
 for(const e of es){const f=path.join(d,e.name);
  if(e.isDirectory()){if(SKIP.has(e.name)||e.name.startsWith('.'))continue;o=o.concat(walk(f,depth+1));}
  else if(e.name.endsWith('.html'))o.push(f);}
 return o;}
const all=walk(ROOT,0);
const cls=p=>{const s=p.toLowerCase();
 if(/adult|xxx|porn|18\+|nswf|nsfw/.test(s))return 'adult';
 if(/movie|film|cinema|watch|serie|tv|show|trailer/.test(s))return 'cinema';
 return 'general';};
function snippet(circle){
 const b=[];
 if(circle==='adult'){
  if(Z.exoclick)b.push('<script async type="text/javascript" src="https://syndication.exoclick.com/splash.php?idzone='+Z.exoclick+'"></script>');
  if(Z.juicyads)b.push('<script async type="text/javascript" src="https://js.juicyads.com/jp.php?c='+Z.juicyads+'"></script>');
  if(Z.adsterra)b.push('<script async src="//'+Z.adsterra+'/invoke.js"></script>');
 }else{
  if(Z.adsense)b.push('<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='+Z.adsense+'" crossorigin="anonymous"></script>');
  if(Z.monetag)b.push('<script src="//libtl.com/sdk.js" data-zone="'+Z.monetag+'" data-sdk="show_'+Z.monetag+'"></script>');
  if(Z.adsterra)b.push('<script async src="//'+Z.adsterra+'/invoke.js"></script>');
 }
 if(Z.propeller)b.push('<script src="//upgulpinon.com/1?z='+Z.propeller+'" async></script>');
 return b.join('\n');
}
const pixel=`<script>(function(){try{
var C=window.__APEX_C||"${''}";var EP="/api/apex/event";
function send(o){o.id=o.id||(Date.now()+"-"+Math.random().toString(36).slice(2,9));
 var body=JSON.stringify(o);try{navigator.sendBeacon(EP,new Blob([body],{type:"application/json"}));return}catch(e){}
 try{fetch(EP,{method:"POST",headers:{"Content-Type":"application/json"},body:body,keepalive:true}).catch(function(){try{fetch("http://127.0.0.1:8792/api/apex/event",{method:"POST",headers:{"Content-Type":"application/json"},body:body}).catch(function(){})}catch(e){}})}catch(e){}}
var c=document.documentElement.getAttribute("data-apex-circle")||"general";
send({type:"pageview",page:location.pathname,circle:c,ref:document.referrer,ua:navigator.userAgent});
if("IntersectionObserver" in window){
 var o=new IntersectionObserver(function(es){es.forEach(function(en){
  if(en.isIntersecting&&en.intersectionRatio>=0.5){send({type:"impression",slot:en.target.getAttribute("data-apex-slot")||"body",page:location.pathname,circle:c});o.unobserve(en.target);}});},{threshold:[0.5]});
 setTimeout(function(){document.querySelectorAll("[data-apex-slot]").forEach(function(el){o.observe(el)})},800);
}})();</script>`;
const O='<!--APEX-ADS-v1-->',C='<!--/APEX-ADS-v1-->';
let n=0,skipped=0;const stats={adult:0,cinema:0,general:0};
const BK=path.join(AX,'backup-html');fs.mkdirSync(BK,{recursive:true});
for(const f of all){
 let h=fs.readFileSync(f,'utf8');
 const c=cls(f);
 if(h.includes(O)){h=h.replace(new RegExp(O+'[\\s\\S]*?'+C),'');skipped++;}
 const block=O+'\n'+snippet(c)+'\n'+pixel+'\n'+C+'\n';
 h=h.replace(/<html([^>]*)>/i,(m,a)=>'<html'+a.replace(/\sdata-apex-circle="[^"]*"/,'')+' data-apex-circle="'+c+'">');
 if(h.includes('</head>'))h=h.replace('</head>',block+'</head>');
 else h=block+h;
 const slot='<div data-apex-slot="'+c+'-footer" style="min-height:100px;margin:12px 0"></div>\n';
 if(h.includes('</body>'))h=h.replace('</body>',slot+'</body>'); else h+=slot;
 if(!fs.existsSync(path.join(BK,path.basename(f))))fs.writeFileSync(path.join(BK,path.basename(f)),h);
 fs.writeFileSync(f,h);n++;stats[c]++;
}
fs.writeFileSync(path.join(AX,'state/wire.json'),JSON.stringify({ts:new Date().toISOString(),pages:all.length,wired:n,refreshed:skipped,by_circle:stats,zones:Z},null,1));
console.log('pages_found='+all.length+' wired='+n+' refreshed='+skipped+' circles='+JSON.stringify(stats));
