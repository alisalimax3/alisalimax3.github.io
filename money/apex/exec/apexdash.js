const http=require('http'),fs=require('fs'),path=require('path');const AX=process.argv[2],PORT=+process.argv[3]||8791;
const R=(p,d)=>{try{return JSON.parse(fs.readFileSync(path.join(AX,p),'utf8'))}catch(e){return d||{}}};
http.createServer((q,s)=>{
 const u=q.url.split('?')[0];
 const j=(o)=>{s.writeHead(200,{'Content-Type':'application/json; charset=utf-8','X-Content-Type-Options':'nosniff'});s.end(JSON.stringify(o))};
 if(u==='/'){s.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});return s.end(fs.readFileSync(path.join(AX,'dash/index.html')))}
 if(u==='/api/state')return j({ts:new Date().toISOString(),registry:R('registry/summary.json'),integrations:R('state/integrations.json'),
   chain:R('state/chain.json'),earnings:R('state/earnings.json'),ledger:R('ledger/rules.json'),mail:R('state/mailbox.json')});
 if(u==='/api/verified')return j({points:R('registry/verified.jsonl')});
 s.writeHead(404);s.end('{}');
}).listen(PORT,'127.0.0.1',()=>console.log('dash http://127.0.0.1:'+PORT));
