#!/usr/bin/env node
"use strict";
const path=require("path"),fs=require("fs");
const ROOT=path.resolve(__dirname,"..",".."),KEYS=path.join(ROOT,"keys.env");
const getkv=k=>{try{return (fs.readFileSync(KEYS,"utf8").match(new RegExp("^"+k+"=(.*)$","m"))||[])[1]||"";}catch(e){return"";}};
const TOK={USDC:"0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",USDT:"0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"};
const ABI=["function balanceOf(address) view returns (uint256)","function decimals() view returns (uint8)","function transfer(address,uint256) returns (bool)"];
(async()=>{
  const {ethers}=require(path.join(ROOT,"node_modules","ethers"));
  const pk=getkv("WALLET_PRIVATE_KEY"),to=getkv("PAYOUT_ADDRESS")||getkv("WALLET_ADDRESS");
  if(!pk)return console.log("  ✗ لا محفظة — شغّل bash money/WALLET.sh");
  const p=new ethers.JsonRpcProvider(getkv("BASE_RPC")||"https://mainnet.base.org");
  const w=new ethers.Wallet(pk,p);
  console.log("  المحفظة: "+w.address);
  for(const[n,a]of Object.entries(TOK)){
    try{const c=new ethers.Contract(a,ABI,p),d=await c.decimals(),b=await c.balanceOf(w.address);
      console.log("  "+n+": "+ethers.formatUnits(b,d));}catch(e){console.log("  "+n+": تعذّر القراءة");}
  }
  const amt=getkv("PAYOUT_AMOUNT"),sym=getkv("PAYOUT_TOKEN")||"USDC";
  if(!amt){console.log("  ℹ أضف PAYOUT_AMOUNT=5 و PAYOUT_TOKEN=USDC ثم أعد التشغيل للسحب");return;}
  const c=new ethers.Contract(TOK[sym],ABI,w),d=await c.decimals();
  const tx=await c.transfer(to,ethers.parseUnits(String(amt),d));
  console.log("  ⏳ tx: "+tx.hash);
  console.log("  ✔ أُرسل "+amt+" "+sym+" إلى "+to);
  console.log("  تحقّق: https://basescan.org/tx/"+tx.hash);
})();
