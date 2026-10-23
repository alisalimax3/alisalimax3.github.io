#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const KEYS=path.join(ROOT,"keys.env"),KS=path.join(DATA,"keys-status.json"),ADS=path.join(DATA,"ads.json"),Q=path.join(DATA,"queue.json");
fs.mkdirSync(DATA,{recursive:true});
const codes=require("./codes.js");
const FILES="sources.json,sources-big.json,sources-west.json,sources-mega.json,sources-mega2.json,sources-mega3.json,sources-mega4.json".split(",");
const load=()=>{const o={};try{fs.readFileSync(KEYS,"utf8").split(/\r?\n/).forEach(l=>{const m=l.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);if(m)o[m[1]]=m[2].trim();});}catch(e){}return o;};
const sources=()=>{const o=[],s=new Set();for(const f of FILES){try{JSON.parse(fs.readFileSync(path.join(HERE,f),"utf8")).forEach(x=>{if(x&&x.id&&!s.has(x.id)){s.add(x.id);o.push(x);}});}catch(e){}}return o;};
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>{const t=f+"."+process.pid+".tmp";fs.writeFileSync(t,JSON.stringify(o,null,2));fs.renameSync(t,f);};
const MONEY=new Set(["adult","ads","pay","channel","crypto"]);
const score=x=>(MONEY.has(x.cat)?3:0)+(x.payout&&x.payout!=="-"?2:0)+(/CPM|PPS|RevShare|CPA|\$/.test(x.payout||"")?2:0)+(x.g?1:0);
const curl=u=>new Promise(r=>execFile("curl",["-sL","--retry","2","-o","/dev/null","-w","%{http_code}","--max-time","12","-A","Mozilla/5.0 cinehub",u],{timeout:20000},(e,so)=>r(String(so||"0").trim())));

async function next(){
  const env=load(),L=sources().sort((a,b)=>score(b)-score(a));
  const miss=L.filter(x=>!x.env.every(e=>env[e]));
  const q=rd(Q,{done:[],skip:[]});
  const x=miss.find(s=>!q.skip.includes(s.id));
  if(!x){console.log("✅ كل المفاتيح مكتملة");return;}
  wr(Q,Object.assign(q,{current:x.id}));
  console.log("\n🎯 التالي: "+x.name+"  ["+x.cat+"]");
  console.log("   ملاحظة : "+(x.note||"-"));
  console.log("   دفع    : "+(x.payout||"-"));
  console.log("   الرابط : "+(x.url==="-"?"— لا يحتاج مفتاح":x.url));
  console.log("   المفاتيح المطلوبة: "+x.env.join(", "));
  console.log("\n   الصق:  bash money/AGENT-RUN.sh set "+x.env.map(e=>e+"=القيمة").join(" "));
  console.log("   أو    : bash money/AGENT-RUN.sh skip\n");
}
function set(kv){
  const env=load();let t="";try{t=fs.readFileSync(KEYS,"utf8");}catch(e){}
  let n=0;
  for(const p of kv){const i=p.indexOf("=");if(i<0)continue;const k=p.slice(0,i),v=p.slice(i+1);
    const re=new RegExp("^"+k+"=.*$","m");t=re.test(t)?t.replace(re,k+"="+v):t+((t&&!t.endsWith("\n"))?"\n":"")+k+"="+v+"\n";n++;}
  const tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);try{fs.chmodSync(KEYS,0o600);}catch(e){}
  console.log("  ✔ حُفظ "+n+" مفتاح");codes.save("مفاتيح",Object.fromEntries(kv.map(p=>p.split(/=(.*)/s).slice(0,2))));
}
async function verify(all){
  const env=load(),L=sources(),st={keys:[],summary:{}};let live=0,blk=0,dead=0;
  const targets=all?L:L.filter(x=>x.env.every(e=>env[e]));
  for(const x of targets){
    const u=x.probe||x.url;
    let code="0";
    if(u&&u!=="-"){code=await curl(u);
      if(code[0]==="2"||code[0]==="3"){live++;}else if(["401","403","429","503"].includes(code)){blk++;}else{dead++;}}
    st.keys.push({id:x.id,name:x.name,cat:x.cat,url:x.url,code,status:(code[0]==="2"||code[0]==="3")?"LIVE":(["403","429","503"].includes(code)?"BLOCKED":(u==="-"?"KEYLESS":"DEAD")),checked_at:new Date().toISOString()});
  }
  st.summary={live,blocked:blk,dead,total:targets.length};
  wr(KS,st);
  // تفعيل الإعلانات للشبكات التي وُجد مفتاحها
  let ads=rd(ADS,[]);
  const map={adsterra:["ADSTERRA_API_KEY"],monetag:["MONETAG_API_KEY"],exoclick:["EXOCLICK_API_TOKEN"],trafficjunky:["TRAFFICJUNKY_API_KEY"],juicyads:["JUICYADS_API_KEY"],clickadilla:["CLICKADILLA_API_KEY"],propellerads:["PROPELLERADS_API_KEY"],evadav:["EVADAV_API_KEY"],pushhouse:["PUSHHOUSE_TOKEN"],lospollos:["LOSPOLLOS_API_KEY"],adsense:["ADSENSE_CLIENT"],analytics:["GOATCOUNTER_CODE","PLAUSIBLE_DOMAIN","UMAMI_WEBSITE_ID"]};
  let on=0;
  ads=ads.map(a=>{const ks=map[a.id]||[];const has=ks.some(k=>env[k]);const e=has&&a.snippet?a.enabled||true:a.enabled;if(e&&a.snippet)on++;return{...a,enabled:!!e};});
  wr(ADS,ads);
  console.log(`  فحص ${targets.length} → ✔${live} يستجيب | ◐${blk} محجوب(curl) | ✗${dead} فشل`);
  console.log(`  إعلانات جاهزة للحقن: ${on}`);
  console.log("  شغّل: bash money/INJECT-ADS.sh");
}
(async()=>{const [c,...a]=process.argv.slice(2);
 if(c==="next")await next(); else if(c==="set")set(a); else if(c==="verify")await verify(a.includes("--all"));
 else if(c==="skip"){const q=rd(Q,{done:[],skip:[]});if(q.current)q.skip.push(q.current);wr(Q,q);await next();}
 else console.log("الأوامر: next | set K=V | verify [--all] | skip");
})();
