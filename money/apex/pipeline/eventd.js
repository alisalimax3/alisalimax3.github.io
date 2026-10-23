const http=require('http'),fs=require('fs'),path=require('path'),crypto=require('crypto');
const P=process.argv[2],PORT=+process.argv[3]||8792,FILE=path.join(P,'events.jsonl');
const seen=new Set();
http.createServer((q,s)=>{
 s.setHeader('Access-Control-Allow-Origin','*');
 s.setHeader('Access-Control-Allow-Headers','content-type');
 if(q.method==='OPTIONS'){s.writeHead(204);return s.end();}
 const u=q.url.split('?')[0];
 if(u==='/api/apex/event'&&q.method==='POST'){let b='';q.on('data',c=>b+=c);
  q.on('end',()=>{let j=null;try{j=JSON.parse(b||'{}')}catch(e){}
   const id=(j&&j.id)||crypto.randomUUID();
   if(seen.has(id)){s.writeHead(200,{'Content-Type':'application/json'});return s.end('{"dup":true}');}
   seen.add(id);
   const ev={id,ts:new Date().toISOString(),recv:Date.now(),...j};
   fs.appendFileSync(FILE,JSON.stringify(ev)+'\n');
   s.writeHead(202,{'Content-Type':'application/json'});s.end('{"ok":true,"id":"'+id+'"}');});
  return;}
 if(u==='/api/apex/stats'){let n=0;try{n=fs.readFileSync(FILE,'utf8').split('\n').filter(Boolean).length}catch(e){}
  s.writeHead(200,{'Content-Type':'application/json'});return s.end(JSON.stringify({events:n}));}
 s.writeHead(404);s.end('{}');
}).listen(PORT,'127.0.0.1',()=>console.log('eventd 127.0.0.1:'+PORT));
