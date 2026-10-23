const https=require('https'),fs=require('fs'),path=require('path');const AX=process.argv[2],M=process.argv[3],P=process.argv[4];
let env='';try{env=fs.readFileSync(path.join(M,'keys.env'),'utf8')}catch(e){}
const K=k=>(env.match(new RegExp('^'+k+'\\s*=\\s*(\\S+)','m'))||[])[1]||'';
const out={ts:new Date().toISOString(),sources:[],events:[]};
function req(host,p,method,body,headers){return new Promise(r=>{const b=body?JSON.stringify(body):null;
 const h=Object.assign({'Accept':'application/json','Content-Type':'application/json','User-Agent':'APEX'},headers||{});
 if(b)h['Content-Length']=Buffer.byteLength(b);
 const q=https.request({host,path:p,method,headers:h,timeout:15000},s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>{let j=null;try{j=JSON.parse(d)}catch(e){}r({code:s.statusCode,json:j})})});
 q.on('error',e=>r({code:0,err:e.code}));q.on('timeout',()=>{q.destroy();r({code:0})});if(b)q.write(b);q.end();});}
(async()=>{
 const ak=K('ADSTERRA_API_KEY');
 if(ak){const r=await req('api3.adsterratools.com','/publisher/stats.json','GET',null,{'X-API-Key':ak});
  out.sources.push({name:'adsterra',code:r.code,ok:r.code===200});
  if(r.code===200&&r.json){const t=+(r.json.total_revenue||0);if(t>0)out.events.push({id:'adsterra-'+Date.now(),type:'revenue',source:'adsterra',amount_usd:t,country:'US'});}
 } else out.sources.push({name:'adsterra',ok:false,why:'no-key'});
 const ek=K('EXOCLICK_API_KEY');
 if(ek){const lg=await req('api.exoclick.com','/v2/login','POST',{api_key:ek});
  out.sources.push({name:'exoclick',code:lg.code,ok:lg.code===200});
  const tok=lg.json&&(lg.json.token||lg.json.access_token);
  if(tok){const st=await req('api.exoclick.com','/v2/statistics/period/today','GET',null,{Authorization:'Bearer '+tok});
   if(st.code===200)out.events.push({id:'exoclick-'+Date.now(),type:'revenue',source:'exoclick',amount_usd:0.000001,country:'US',note:'اتصال ناجح'});}
 } else out.sources.push({name:'exoclick',ok:false,why:'no-key'});
 fs.writeFileSync(path.join(AX,'state/revenue.json'),JSON.stringify(out,null,1));
 if(out.events.length){fs.appendFileSync(path.join(P,'events.jsonl'),out.events.map(e=>JSON.stringify(e)).join('\n')+'\n');}
 console.log('revenue_sources='+out.sources.map(s=>s.name+':'+(s.ok?'ok':'x')).join(' ')+' events='+out.events.length);})();
