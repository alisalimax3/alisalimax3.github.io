const https=require('https'),fs=require('fs'),path=require('path');const AX=process.argv[2],M=process.argv[3];
let W='';try{const k=fs.readFileSync(path.join(M,'keys.env'),'utf8');
 const m=k.match(/^WALLET_ADDRESS\s*=\s*(\S+)/m); if(m)W=m[1].trim();}catch(e){}
const CH=[['base','https://mainnet.base.org','0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'],
 ['polygon','https://polygon-rpc.com','0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'],
 ['bsc','https://bsc-dataseed.binance.org','0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d'],
 ['arbitrum','https://arb1.arbitrum.io/rpc','0xaf88d065e77c8cC2239327C5EDb3A432268e5831'],
 ['optimism','https://mainnet.optimism.io','0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85'],
 ['ethereum','https://eth.llamarpc.com','0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48']];
function rpc(u,method,params){return new Promise(r=>{const b=JSON.stringify({jsonrpc:'2.0',id:1,method,params});
 const rq=https.request(u,{method:'POST',timeout:12000,headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(b)}},s=>{
  let d='';s.on('data',c=>d+=c);s.on('end',()=>{try{r(JSON.parse(d).result)}catch(e){r(null)}});});
 rq.on('error',()=>r(null));rq.on('timeout',()=>{rq.destroy();r(null)});rq.write(b);rq.end();});}
function dec(hex,d){if(!hex||hex==='0x')return 0;const v=BigInt(hex);const s=BigInt(10)**BigInt(d);
 return Number(v*10000n/s)/10000;}
(async()=>{
 const out={ts:new Date().toISOString(),wallet:W||null,chains:[],usdt_tron:null};
 if(!W){fs.writeFileSync(path.join(AX,'state/chain.json'),JSON.stringify(out,null,1));console.log('wallet=missing');return;}
 for(const [name,url,usdc] of CH){
  const bal=await rpc(url,'eth_getBalance',[W,'latest']);
  const data='0x70a08231'+W.replace(/^0x/,'').toLowerCase().padStart(64,'0');
  const erc=await rpc(url,'eth_call',[{to:usdc,data},'latest']);
  out.chains.push({chain:name,native:dec(bal,18),usdc:dec(erc,6),ok:bal!==null});
 }
 try{
  const j=await new Promise(r=>{https.get('https://api.trongrid.io/v1/accounts/'+W,{timeout:12000},s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>{try{r(JSON.parse(d))}catch(e){r(null)}})}).on('error',()=>r(null))});
  if(j&&j.data&&j.data[0]){const t=(j.data[0].trc20||[]).find(x=>x['TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t']);
   out.usdt_tron=t?Number(BigInt(t['TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t']))/1e6:0;}
 }catch(e){}
 fs.writeFileSync(path.join(AX,'state/chain.json'),JSON.stringify(out,null,1));
 const tot=out.chains.reduce((a,c)=>a+(c.native>0?1:0),0);
 console.log('wallet='+W.slice(0,10)+'... chains_probed='+out.chains.length+' nonempty='+tot);})();
