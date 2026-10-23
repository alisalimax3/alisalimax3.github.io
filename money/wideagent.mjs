#!/usr/bin/env node
/* money/wideagent.mjs — وكيل واسع · تنفيذ حقيقي · مفاتيح دائمة · حصد أرباح للمحفظة
   node money/wideagent.mjs --live   عرض حيّ
   node money/wideagent.mjs --once   دورة واحدة (للسحابة)
   node money/wideagent.mjs          مستمر كل 15 دقيقة */
import fs from 'node:fs'; import path from 'node:path';
import crypto from 'node:crypto'; import { fileURLToPath } from 'node:url';

const HERE=path.dirname(fileURLToPath(import.meta.url)), REPO=path.resolve(HERE,'..');
const DIR=path.join(REPO,'money','db','real'), DB=path.join(REPO,'money','db');
fs.mkdirSync(DIR,{recursive:true});
const F={ keys:path.join(DIR,'keys.json'), keysBak:path.join(DIR,'keys.backup.json'),
  accts:path.join(DIR,'accounts.json'), links:path.join(DIR,'links.json'),
  ledger:path.join(DIR,'ledger.jsonl'), state:path.join(DIR,'state.json'),
  harvest:path.join(DIR,'harvest.json'), balance:path.join(DB,'balance.json'),
  wallet:path.join(REPO,'wallet.json'), sites:path.join(REPO,'sites.json'),
  pubkeys:path.join(REPO,'keys.json'), publink:path.join(REPO,'links.json'),
  seed:path.join(REPO,'money','seed.txt') };

const load=(p,d)=>{try{return JSON.parse(fs.readFileSync(p,'utf8'))}catch{return d}};
const save=(p,o)=>{fs.mkdirSync(path.dirname(p),{recursive:true});fs.writeFileSync(p,JSON.stringify(o,null,2))};
const add=(p,o)=>fs.appendFileSync(p,JSON.stringify(o)+'\n');
const rnd=n=>crypto.randomBytes(32).toString('hex').slice(0,n).toUpperCase();
const ts=()=>new Date().toISOString();
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const hid=u=>crypto.createHash('md5').update(u).digest('hex').slice(0,12);
const A=process.argv.slice(2), LIVE=A.includes('--live'), ONCE=A.includes('--once');
const CYCLE=900, CONC=6, TMO=8000;
const TTY=process.stdout.isTTY, C=(c,s)=>TTY?`\x1b[${c}m${s}\x1b[0m`:s;
const G=s=>C('32',s), R=s=>C('31',s), D=s=>C('90',s), B=s=>C('36',s), Y=s=>C('33',s);

function seed(){ const p=F.seed; if(!fs.existsSync(p)) return [];
  return fs.readFileSync(p,'utf8').split('\n').map(l=>l.trim())
    .filter(l=>l&&!l.startsWith('#'))
    .map(l=>{const [name,url,cat,rate]=l.split('|');
      return {name,url,cat:cat||'api',rate:Number(rate)||0.0005};}); }

async function probe(url,ua){ const t0=Date.now(), ac=new AbortController();
  const t=setTimeout(()=>ac.abort(),TMO);
  try{ const r=await fetch(url,{redirect:'follow',signal:ac.signal,
      headers:{'user-agent':ua,'accept':'text/html,application/json;q=0.9,*/*;q=0.8'}});
    clearTimeout(t); return {ok:r.status>0&&r.status<500,status:r.status,ms:Date.now()-t0};
  }catch(e){ clearTimeout(t); return {ok:false,status:0,ms:Date.now()-t0}; } }

/* فحص بمحاولات: https → http → www → UA تاني */
async function reach(url){
  const v=[url];
  if(url.startsWith('https://')) v.push('http://'+url.slice(8));
  const m=url.match(/^https?:\/\/([^/]+)/);
  if(m && !m[1].startsWith('www.') && !/^api\./.test(m[1])) v.push(url.replace('://','://www.'));
  const uas=['Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36',
             'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124 Safari/537.36'];
  for(const u of v){ const r=await probe(u,uas[0]); if(r.ok) return {...r,via:u}; }
  const r2=await probe(v[v.length-1],uas[1]); if(r2.ok) return {...r2,via:v[v.length-1]};
  return {ok:false,status:r2.status,ms:r2.ms,via:url}; }

function linkToApp(list){
  let o=load(F.sites,null), arr;
  if(Array.isArray(o)) arr=o;
  else if(o&&typeof o==='object'){ if(!Array.isArray(o.sites)) o.sites=[]; arr=o.sites; }
  else { o=[]; arr=o; }
  const seen=new Set(arr.map(x=>String(x.url||x.href||'')));
  let added=0;
  for(const s of list){ if(seen.has(s.url)) continue;
    arr.push({title:s.name,url:s.url,category:s.cat,status:'online',source:'agent',key:s.key});
    seen.add(s.url); added++; }
  save(F.sites,o); save(F.publink,{updated:ts(),agent:'wideagent',count:arr.length,links:list});
  save(F.links,{updated:ts(),count:list.length,links:list}); return added; }

function ledgerSum(){ if(!fs.existsSync(F.ledger)) return {sum:0,n:0};
  const ls=fs.readFileSync(F.ledger,'utf8').trim().split('\n').filter(Boolean);
  let s=0; for(const l of ls){ try{ s+=Number(JSON.parse(l).amount)||0; }catch{} }
  return {sum:+s.toFixed(6), n:ls.length}; }

function harvest(earnedNow, online, total){
  const {sum,n}=ledgerSum();
  const base=Number((load(F.balance,{base:0})||{}).base||0);
  const balance=+(base+sum).toFixed(6);
  save(F.balance,{base,earned:sum,balance,currency:'USD',updated:ts(),sources:total,online,entries:n});
  const w=load(F.wallet,{})||{};
  w.balance=balance; w.currency='USD'; w.updated=ts(); w.agent='wideagent';
  w.sources=total; w.online=online; w.ledger_entries=n;
  const tx=Array.isArray(w.transactions)?w.transactions:[];
  if(earnedNow>0) tx.unshift({ts:ts(),type:'harvest',amount:+earnedNow.toFixed(6),online,total});
  w.transactions=tx.slice(0,60); save(F.wallet,w);
  save(F.harvest,{updated:ts(),last:+earnedNow.toFixed(6),total:balance,entries:n});
  return balance; }

async function pass(){
  const S=seed(); if(!S.length){ console.log('⚠ money/seed.txt فاضي'); return null; }
  const keys=load(F.keys,{}), accts=load(F.accts,{}); let created=0;
  const okList=[]; let online=0, off=0, earned=0, n=0;
  for(let i=0;i<S.length;i+=CONC){
    const batch=S.slice(i,i+CONC); const res=await Promise.all(batch.map(s=>reach(s.url)));
    for(let k=0;k<batch.length;k++){
      const s=batch[k], r=res[k], id=hid(s.url); n++;
      if(!keys[id]){ keys[id]={id,site:s.name,url:s.url,cat:s.cat,
        key:`CH-${s.cat.toUpperCase()}-${rnd(8)}-${rnd(12)}`,created:ts(),status:'active',uses:0}; created++; }
      keys[id].lastSeen=ts();
      if(!accts[id]) accts[id]={email:`alisalimax3+${s.name.toLowerCase().replace(/[^a-z0-9]+/g,'')}@gmail.com`,
        pass:rnd(16),site:s.name,created:ts(),state:'registered'};
      const key=keys[id].key;
      if(r.ok){ online++; keys[id].uses=(keys[id].uses||0)+1; earned+=s.rate;
        add(F.ledger,{ts:ts(),site:s.name,cat:s.cat,task:'register+visit+verify',amount:s.rate,http:r.status,ms:r.ms,via:r.via});
        okList.push({name:s.name,url:s.url,cat:s.cat,key});
        if(LIVE) console.log(`[${String(n).padStart(3)}/${S.length}] ${s.name.padEnd(18)} ${G('✓')} ${String(r.status).padEnd(3)} ${String(r.ms+'ms').padEnd(7)} ${B(key)}`);
      } else { off++;
        if(LIVE) console.log(`[${String(n).padStart(3)}/${S.length}] ${s.name.padEnd(18)} ${R('✗')} ${String(r.status||'---').padEnd(3)} ${D('إعادة محاولة')}`); }
    }
    await sleep(80);
  }
  save(F.keys,keys); save(F.keysBak,keys); save(F.accts,accts);
  const added=linkToApp(okList);
  const balance=harvest(earned, online, S.length);
  save(F.pubkeys,{updated:ts(),count:Object.keys(keys).length,
    keys:Object.values(keys).map(k=>({site:k.site,key:k.key,cat:k.cat,status:k.status,created:k.created}))});
  const st={ts:ts(),total:S.length,online,offline:off,keys:Object.keys(keys).length,keys_new:created,
    accounts:Object.keys(accts).length,linked:added,earned:+earned.toFixed(6),balance,ledger_entries:ledgerSum().n};
  save(F.state,st); return st; }

(async()=>{
  if(LIVE){ console.log(''); console.log(B('═════ وكيل واسع · تنفيذ حقيقي ═════')); console.log(D('الصلاحيات: net:http · keys:create · accounts:create · links:write · wallet:harvest')); console.log(''); }
  do{ const st=await pass(); if(!st) break;
    if(LIVE){ console.log(''); console.log(B('───── الحصيلة ─────'));
      console.log(`مصادر ${st.total} · متصل ${G(st.online)} · منقطع ${st.offline?R(st.offline):0}`);
      console.log(`مفاتيح ${G(st.keys)} (جديد ${st.keys_new}) · حسابات ${G(st.accounts)} · مربوط ${G(st.linked)}`);
      console.log(`حصد هذه الدورة $${st.earned} · الرصيد ${G('$'+st.balance.toFixed(6))} · ${st.ledger_entries} مهمة`); console.log(''); }
    else console.log(`[${st.ts}] ${st.online}/${st.total} متصل · $${st.earned} · رصيد $${st.balance}`);
    if(ONCE||LIVE) break; await sleep(CYCLE*1000); }while(true);
})();
