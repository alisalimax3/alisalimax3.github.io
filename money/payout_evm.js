#!/usr/bin/env node
"use strict";
const { JsonRpcProvider, Wallet, Contract, parseUnits, formatUnits } = require("ethers");
(async () => {
  const rpc = process.env.BASE_RPC || "https://mainnet.base.org";
  const pk  = process.env.WALLET_PRIVATE_KEY;
  const to  = process.env.PAYOUT_ADDRESS || process.env.WALLET_ADDRESS;
  const usd = parseFloat(process.argv[2] || "0");
  const token = process.env.PAYOUT_TOKEN_ADDRESS || "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
  const dec = parseInt(process.env.PAYOUT_TOKEN_DECIMALS || "6", 10);
  if (!pk) return console.log(JSON.stringify({ ok:false, reason:"no_WALLET_PRIVATE_KEY" }));
  if (!to) return console.log(JSON.stringify({ ok:false, reason:"no_PAYOUT_ADDRESS" }));
  const w = new Wallet(pk, new JsonRpcProvider(rpc));
  const erc = new Contract(token, ["function balanceOf(address) view returns (uint256)","function transfer(address,uint256) returns (bool)"], w);
  const bal = await erc.balanceOf(w.address);
  const want = parseUnits(usd.toFixed(dec), dec);
  const amt = bal < want ? bal : want;
  if (amt <= 0n) return console.log(JSON.stringify({ ok:false, reason:"zero_balance", from:w.address, balance:formatUnits(bal,dec) }));
  const tx = await erc.transfer(to, amt); const rc = await tx.wait();
  console.log(JSON.stringify({ ok:true, hash:rc.hash, from:w.address, to, sent:formatUnits(amt,dec), token }));
})().catch(e => console.log(JSON.stringify({ ok:false, reason:String(e.message||e) })));
