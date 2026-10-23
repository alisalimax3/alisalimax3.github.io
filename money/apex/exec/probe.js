const fs=require('fs'),https=require('https'),http=require('http');
const inp=process.argv[2],out=process.argv[3];
const CONC=+(process.env.APEX_CONC||32),TO=+(process.env.APEX_TIMEOUT||11000);
const rows=fs.readFileSync(inp,'utf8').split('\n').filter(Boolean).map(l=>{const p=l.split('\t');return{id:p[0],kind:p[1],url:p[2]}});
const res=[];let i=0,done=0;
function probe(u,depth,method){return new Promise(r=>{const t0=Date.now(),lib=u.startsWith('https')?https:http;let fin=false;
 const rq=lib.request(u,{method,timeout:TO,headers:{'User-Agent':'Mozilla/5.0 (Linux; Android 13) APEX/1.0','Accept':'*/*'}},s=>{
  const c=s.statusCode,loc=s.headers.location;
  if([301,302,303,307,308].includes(c)&&loc&&depth<3){s.resume();const n=loc.startsWith('http')?loc:new URL(loc,u).href;return probe(n,depth+1,method).then(r);}
  s.resume();
  if(c>=400&&c!==404&&method==='HEAD')return probe(u,depth,'GET').then(r);
  fin=true;r({code:c,ms:Date.now()-t0});}).on('error',e=>{if(fin)return;fin=true;r({code:0,err:e.code||e.message,ms:Date.now()-t0});});
 rq.on('timeout',()=>{if(fin)return;fin=true;rq.destroy();r({code:0,err:'timeout',ms:Date.now()-t0});});rq.end();});}
(async()=>{await Promise.all(Array.from({length:CONC},async()=>{while(true){const k=i++;if(k>=rows.length)break;
  const w=rows[k],x=await probe(w.url,0,'HEAD');const ok=x.code>=200&&x.code<400,g=[401,403,405,406,429,503].includes(x.code);
  res.push({id:w.id,kind:w.kind,url:w.url,code:x.code,ok:!!ok,reachable:!!(ok||g),err:x.err||null,ms:x.ms});
  if(++done%500===0)process.stderr.write('  probe '+done+'/'+rows.length+'\n');}}));
 fs.writeFileSync(out,res.map(x=>JSON.stringify(x)).join('\n'));
 console.log('probed='+res.length+' reachable='+res.filter(x=>x.reachable).length+' platforms_live='+new Set(res.filter(x=>x.kind==='root'&&x.reachable).map(x=>x.id)).size);})();
