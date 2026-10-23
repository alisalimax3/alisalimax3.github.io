#!/usr/bin/env node
"use strict";
const path=require("path"),fs=require("fs");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),AL=require("./aledger.js"),codes=require("./acodes.js");
function plan(){const total=Number(AL.rd().total||0),th=Number(K.get("PAYOUT_THRESHOLD")||"20"),addr=K.get("PAYOUT_ADDRESS");
  return{total,threshold:th,addr,chain:K.get("PAYOUT_CHAIN")||"base",due:total>=th&&!!addr,at:new Date().toISOString()};}
async function send(){const p=plan();fs.writeFileSync(path.join(D,"payout.json"),JSON.stringify(p,null,1));
  if(!p.due)return p;
  try{const ethers=require(path.join(ROOT,"node_modules","ethers"));
    const pk=K.get("WALLET_PRIVATE_KEY")||K.get("PRIVATE_KEY");if(!pk){p.note="بلا مفتاح خاص";return p;}
    const prov=new ethers.JsonRpcProvider(K.get("RPC_URL")||"https://mainnet.base.org");
    const w=new ethers.Wallet(pk,prov);
    const tx=await w.sendTransaction({to:p.addr,value:ethers.parseEther(p.total.toFixed(6))});
    p.tx=tx.hash;p.sent=true;codes.save("حوالة",{إلى:p.addr,مبلغ:p.total,tx:tx.hash});
  }catch(e){p.error=String(e.message||e).slice(0,140);}
  fs.writeFileSync(path.join(D,"payout.json"),JSON.stringify(p,null,1));return p;}
module.exports={plan,send};
if(require.main===module){send().then(p=>console.log("  "+(p.sent?"✔ حُوّل":(p.due?"○ جاهز":"○ لم يبلغ الحد"))+" — $"+p.total.toFixed(2)+" / حد $"+p.threshold+(p.tx?" tx:"+p.tx:"")));}
