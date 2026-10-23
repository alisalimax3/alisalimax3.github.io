#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data"),F=path.join(D,"apex-ledger.json");
const rd=()=>{try{return JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){return{total:0,rows:[]};}};
const wr=o=>fs.writeFileSync(F,JSON.stringify(o,null,1));
function add(net,amount,meta){const l=rd();const a=Number(amount)||0;
  l.rows.push(Object.assign({net,amount:a,at:new Date().toISOString()},meta||{}));
  l.total=Number(l.total||0)+a;l.updated=new Date().toISOString();wr(l);return l.total;}
const day=()=>{const d=new Date().toISOString().slice(0,10);return rd().rows.filter(r=>r.at.slice(0,10)===d).reduce((a,r)=>a+r.amount,0);};
const week=()=>{const t=Date.now()-864e5*7;return rd().rows.filter(r=>new Date(r.at).getTime()>t).reduce((a,r)=>a+r.amount,0);};
function csv(){return "date,network,amount,note\n"+rd().rows.map(r=>[r.at,r.net,r.amount,(r.note||"")].join(",")).join("\n")+"\n";}
function invoice(){const l=rd();
  return "<!doctype html><meta charset=utf-8><style>body{font-family:system-ui;background:#0b0e14;color:#e8eef7;padding:32px}td,th{border-bottom:1px solid #223;padding:8px;text-align:right}h2{color:#4ade80}</style><h1>CineHub — كشف أرباح</h1><p>"+new Date().toISOString().slice(0,10)+"</p><table><tr><th>الشبكة</th><th>المبلغ</th><th>التاريخ</th></tr>"+
    l.rows.slice(-200).map(r=>"<tr><td>"+r.net+"</td><td>$"+r.amount.toFixed(2)+"</td><td>"+r.at.slice(0,16)+"</td></tr>").join("")+"</table><h2>الإجمالي $"+Number(l.total||0).toFixed(2)+"</h2>";}
module.exports={add,day,week,rd,wr,csv,invoice};
if(require.main===module){const c=process.argv[2]||"show";
  if(c==="csv")console.log(csv());else if(c==="invoice")console.log(invoice());
  else{const l=rd();console.log("  الإجمالي $"+Number(l.total||0).toFixed(2)+" · أسبوع $"+week().toFixed(2)+" · اليوم $"+day().toFixed(2)+" · "+l.rows.length+" قيد");}}
