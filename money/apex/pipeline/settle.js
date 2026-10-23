const fs=require('fs'),path=require('path'),https=require('https');
const C=require('./crypto.js');const P=process.argv[2],M=process.argv[3],BCAST=process.argv[4]==='1';
let env='';try{env=fs.readFileSync(path.join(M,'keys.env'),'utf8')}catch(e){}
const K=k=>(env.match(new RegExp('^'+k+'\\s*=\\s*(\\S+)','m'))||[])[1]||'';
const PRIV=K('WALLET_PRIVATE_KEY'),ADDR=K('WALLET_ADDRESS');
const RPC='https://mainnet.base.org',USDC='0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',CID=8453n;
const rpc=(m,p)=>new Promise(r=>{const b=JSON.stringify({jsonrpc:'2.0',id:1,method:m,params:p});
 const q=https.request(RPC,{method:'POST',timeout:12000,headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(b)}},s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>{try{r(JSON.parse(d).result)}catch(e){r(null)}})});
 q.on('error',()=>r(null));q.on('timeout',()=>{q.destroy();r(null)});q.write(b);q.end();});
(async()=>{
 const out={ts:new Date().toISOString(),wallet:ADDR||null,chain:'base',built:null,broadcast:false};
 let due=0;try{due=require(path.join(P,'money.json')).wallet_asset||0}catch(e){}
 out.ledger_due_usd=due;
 if(!PRIV||!ADDR){fs.writeFileSync(path.join(P,'settle.json'),JSON.stringify(out,null,1));console.log('settle=no-wallet');return;}
 const priv=BigInt(PRIV);
 const nonce=BigInt(await rpc('eth_getTransactionCount',[ADDR,'pending'])||'0x0');
 const gp=BigInt(await rpc('eth_gasPrice',[])||'0x3b9aca00');
 const data=C.erc20Transfer(ADDR,0n);
 const tx={nonce,gasPrice:gp*2n,gasLimit:120000n,to:USDC,value:0n,data,chainId:CID};
 const sg=C.signTx(tx,priv);
 const selfRecover=C.recover(C.keccak(C.rlp([tx.nonce,tx.gasPrice,tx.gasLimit,Buffer.from(USDC.replace(/^0x/,''),'hex'),tx.value,Buffer.from(data.replace(/^0x/,''),'hex'),CID,0n,0n])),sg.r,sg.s,sg.rec);
 out.built={nonce:nonce.toString(),gasPrice:gp.toString(),txhash:sg.hash,raw:sg.raw};
 out.signer_recovered=selfRecover; out.signer_ok=!!selfRecover&&selfRecover.toLowerCase()===ADDR.toLowerCase();
 out.signed=!!out.signer_ok;
 const bal=BigInt(await rpc('eth_getBalance',[ADDR,'latest'])||'0x0');
 out.native_wei=bal.toString();
 if(BCAST&&bal>gp*200000n){const h=await rpc('eth_sendRawTransaction',[sg.raw]);out.broadcast=!!h;out.txhash_onchain=h||null;}
 fs.writeFileSync(path.join(P,'settle.json'),JSON.stringify(out,null,1));
 console.log('settle signed='+out.signed+' signer_ok='+out.signer_ok+' tx='+sg.hash.slice(0,20)+'... broadcast='+out.broadcast);})();
