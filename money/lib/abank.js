#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const K=require("./akeys.js"),AL=require("./aledger.js");
const bank={bank:"بنك الكريمي (Al-Kuraimi Islamic Microfinance Bank)",country:"اليمن",
 receive:["حوالة دولية USD عبر SWIFT","مراسل بنكي","Payoneer ثم تحويل محلي","USDT ثم صرافة محلية"],
 fields:["BANK_ACCOUNT_NAME","BANK_ACCOUNT_NUMBER","BANK_BRANCH","BENEFICIARY_PHONE"],
 flow:"حصد → apex-ledger → تجاوز PAYOUT_THRESHOLD → USDC على Base إلى PAYOUT_ADDRESS → تحويل إلى الكريمي"};
function write(){fs.writeFileSync(path.join(D,"bank.json"),JSON.stringify(bank,null,1));return bank;}
function kyc(){const l=AL.rd(),k=K.all();
 const rows=[["الاسم",k.BANK_ACCOUNT_NAME||k.BRAND_NAME||""],["الحساب",k.BANK_ACCOUNT_NUMBER||""],["الفرع",k.BANK_BRANCH||""],
  ["الهاتف",k.BENEFICIARY_PHONE||""],["البريد",k.CONTACT_EMAIL||""],["الموقع",k.PUBLIC_URL||""],
  ["الشبكات",(k.ADS_NETWORKS||"adsterra,monetag,exoclick")],["الأرباح المُسجّلة","$"+Number(l.total||0).toFixed(2)],
  ["المحفظة",k.PAYOUT_ADDRESS||""],["التاريخ",new Date().toISOString().slice(0,10)]];
 const html="<!doctype html><meta charset=utf-8><style>body{font-family:system-ui;background:#fff;color:#111;padding:40px;max-width:820px;margin:auto}td,th{border:1px solid #ccc;padding:10px;text-align:right}table{width:100%;border-collapse:collapse}h1{border-bottom:3px solid #2563eb;padding-bottom:8px}</style>"+
  "<h1>ملف KYC — "+bank.bank+"</h1><table>"+rows.map(r=>"<tr><th>"+r[0]+"</th><td>"+r[1]+"</td></tr>").join("")+"</table>"+
  "<p style='margin-top:24px'>أُنتج آليًا بواسطة APEX — اطبعه بصيغة PDF من المتصفح وأرسله للشبكات/البنك.</p>";
 const f=path.join(D,"kyc.html");fs.writeFileSync(f,html);return f;}
module.exports={write,kyc};
if(require.main===module){write();console.log("  ✔ ملف بنك الكريمي: money/data/bank.json");console.log("  ✔ ملف KYC: "+kyc());}
