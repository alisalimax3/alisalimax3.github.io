#!/usr/bin/env node
/* money/GO.mjs — الإصلاح النهائي الشامل (v2)
   الاستخدام: node money/GO.mjs   |   node money/GO.mjs --check
*/
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..');
const OWNER = 'alisalimax3';
const NAME  = 'alisalimax3.github.io';
const BR    = 'main';
const REAL  = `https://${OWNER}.github.io`;
const CLEAN = `https://github.com/${OWNER}/${NAME}.git`;
const TARGETS = ['/grid.js','/wallet.js','/grid.css','/tmdb-img-shim.js','/vn-panel.html','/vn-wallet.html','/withdraw.html'];
const CHECK = process.argv.includes('--check');

const ENV = { ...process.env, GIT_TERMINAL_PROMPT: '0' };
const sh  = (c,a,o={}) => spawnSync(c,a,{cwd:REPO,env:ENV,encoding:'utf8',...o});
const run = (c,a,o={}) => sh(c,a,{stdio:'inherit',...o});
const out = (c,a) => (sh(c,a).stdout||'').trim();
const sleep = ms => new Promise(r=>setTimeout(r,ms));
const die = m => { console.log('✗ '+m); process.exit(1); };

const TOKEN = () => out('gh',['auth','token']);

async function http(url){
  if (globalThis.fetch){
    try { const r = await fetch(url,{redirect:'follow'}); return r.status; } catch { return 0; }
  }
  const r = sh('curl',['-s','-o','/dev/null','-w','%{http_code}','-L','--max-time','20',url]);
  return parseInt((r.stdout||'0').trim(),10)||0;
}

console.log('\n═════ GO · إصلاح + مصادقة + رفع + تحقق ═════');
process.chdir(REPO);
if (sh('git',['rev-parse','--git-dir']).status!==0) die('مش مستودع git');
if (sh('gh',['--version']).status!==0) die('gh مش متسطّب');

let USER = OWNER;

if (!CHECK){
  /* 1 · مصادقة بالمتصفح — بالتوكن مش بحالة gh */
  if (!TOKEN()){
    console.log('\n► هيفتح المتصفح ويظهر كود لمرة واحدة.');
    console.log('  افتح الرابط، الصق الكود، ووافق Authorize. مفيش توكن ولا باسورد بتكتبه.');
    run('gh',['auth','login','--hostname','github.com','--git-protocol','https','--web']);
    if (!TOKEN()) die('المصادقة ماكملتش — جرب: gh auth login --web');
  } else console.log('✓ مسجّل دخول — مفيش كود مطلوب');
  USER = out('gh',['api','user','--jq','.login']) || OWNER;
  console.log('✓ الحساب: '+USER+' · التوكن موجود');

  /* 2 · ربط git + قتل أي credential فاسد */
  console.log('▸ ربط git بتوكن gh…');
  for (const s of ['--system','--global','--local']){
    try { sh('git',['config',s,'--unset-all','credential.helper']); } catch {}
  }
  for (const f of ['.git-credentials', path.join('.config','git','credentials')]){
    try { fs.rmSync(path.join(os.homedir(),f),{force:true}); } catch {}
  }
  run('gh',['auth','setup-git']);
  sh('git',['remote','set-url','origin',CLEAN]);
  const hlp = out('git',['config','--get-all','credential.https://github.com.helper']);
  console.log(hlp ? '✓ git مربوط بـ gh' : '⚠ helper مش مضبوط');

  /* 3 · مزامنة مع الريموت */
  console.log('▸ مزامنة مع الريموت…');
  sh('git',['fetch','origin',BR,'--prune']);
  const behind = parseInt(out('git',['rev-list','--count',`HEAD..origin/${BR}`])||'0',10);
  const ahead  = parseInt(out('git',['rev-list','--count',`origin/${BR}..HEAD`])||'0',10);
  console.log(`  متقدّم محلياً: ${ahead} · الريموت متقدّم: ${behind}`);
  if (behind > 0){
    let r = sh('git',['-c','rebase.autoStash=true','pull','--rebase','origin',BR]);
    if (r.status!==0){
      sh('git',['rebase','--abort']);
      r = sh('git',['pull','--no-rebase','--no-edit','origin',BR]);
      if (r.status!==0){ sh('git',['merge','--abort']); console.log('  ⚠ الدمج تعذّر — هرفع force-with-lease'); }
      else console.log('  ✓ اتعمل merge');
    } else console.log('  ✓ اتعمل rebase');
  }

  /* 4 · خط الإنتاج */
  const one = path.join(HERE,'one.mjs');
  if (fs.existsSync(one)){ console.log('\n▸ تشغيل money/one.mjs …\n'); run('node',[one]); }
  else console.log('⚠ money/one.mjs مش موجود');

  /* 5 · رفع نهائي مضمون */
  console.log('\n▸ رفع نهائي…');
  sh('git',['add','-A']);
  if (out('git',['status','--porcelain'])){
    sh('git',['-c',`user.name=${USER}`,`-c`,`user.email=${USER}@users.noreply.github.com`,'commit','-m','build: go-live final']);
  }
  const tok = TOKEN();
  if (!tok) die('مفيش توكن من gh');
  const AUTH = `https://${USER}:${tok}@github.com/${OWNER}/${NAME}.git`;
  sh('git',['remote','set-url','origin',AUTH]);
  sh('git',['fetch','origin',BR]);
  let p = sh('git',['push','origin',`HEAD:${BR}`]);
  if (p.status!==0 || /rejected|error|fatal/i.test(p.stderr||'')){
    console.log('  ⚠ الرفع العادي اترفض — force-with-lease');
    p = sh('git',['push','--force-with-lease','origin',`HEAD:${BR}`]);
  }
  console.log(p.status===0 ? '✓ اترفع' : '✗ الرفع فشل:\n'+(p.stderr||'').slice(-400));
  sh('git',['remote','set-url','origin',CLEAN]);
}

/* 6 · الوكلاء */
const logdir = path.join(REPO,'money','logs');
fs.mkdirSync(logdir,{recursive:true});
const count = () => (sh('bash',['-lc',"pgrep -af 'money/' | grep -v -e one.mjs -e GO.mjs | wc -l"]).stdout||'').trim();
if (parseInt(count()||'0',10) === 0){
  console.log('▸ تشغيل الوكلاء…');
  for (const [f,ar] of [['heal.mjs',['--watch']],['panel.mjs',[]],['agent.mjs',[]],['tick.mjs',[]]]){
    const fp = path.join(REPO,'money',f);
    if (fs.existsSync(fp)) sh('bash',['-lc',`nohup node "${fp}" ${ar.join(' ')} >> "${path.join(logdir,f.replace('.mjs','.log'))}" 2>&1 &`]);
  }
  await sleep(1500);
}
console.log('✓ الوكلاء: '+count()+' عملية');

/* 7 · تحقق حي */
console.log('\n══ تحقق حي (لحد 5 دقايق) ══');
let good = 0;
for (let r=1; r<=20 && good<TARGETS.length; r++){
  good = 0; const line = [];
  for (const t of TARGETS){ const s = await http(REAL+t); if (s===200) good++; line.push(t.slice(1)+'='+s); }
  console.log(` جولة ${r} [${good}/${TARGETS.length}]  ${line.join('  ')}`);
  if (good<TARGETS.length) await sleep(15000);
}
console.log('');
if (good===TARGETS.length) console.log('✓✓ الموقع حيّ بالكامل — كل الملفات 200');
else console.log(`⚠ ناقص ${TARGETS.length-good} — GitHub Pages بياخد وقت. كرر: node money/GO.mjs --check`);
console.log('► '+REAL);
console.log('► اللوحة '+REAL+'/vn-panel.html · المحفظة '+REAL+'/vn-wallet.html · السحب '+REAL+'/withdraw.html');
