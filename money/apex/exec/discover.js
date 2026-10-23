const fs=require('fs'),path=require('path');
const roots=process.argv.slice(2);
const SKIP=new Set(['node_modules','.git','.tmp','profiles','.check','.venv','dist','build','backup-html','logs','__pycache__','.cache','apex','.npm','site-packages']);
const NAME=/(gateway|server|serve|hub|agent|auth|static|panel|workflow|entry|main|app)\.(js|mjs|cjs|py)$/i;
const PAT=/\.listen\s*\(|app\.run\s*\(|uvicorn\.run|Flask\s*\(|createServer\s*\(|HTTPServer\s*\(/;
const seen=new Set(),out=[];
function walk(d,depth){if(depth>5)return;let es=[];try{es=fs.readdirSync(d,{withFileTypes:true})}catch(e){return}
 for(const e of es){const f=path.join(d,e.name);
  if(e.isDirectory()){if(SKIP.has(e.name)||e.name.startsWith('.'))continue;walk(f,depth+1);}
  else if(/\.(js|mjs|cjs|py)$/.test(e.name)&&NAME.test(e.name)){
   let rp;try{rp=fs.realpathSync(f)}catch(x){rp=f}
   if(seen.has(rp))continue;seen.add(rp);
   let s='';try{s=fs.readFileSync(f,'utf8')}catch(e){continue}
   if(!PAT.test(s))continue;
   let port='';
   const pats=[/\.listen\s*\(\s*(\d{4,5})/,/\.listen\s*\(\s*[^,)]*?\|\|\s*(\d{4,5})/,
     /AUTH_PORT\s*\|\|\s*(\d{4,5})/,/HUB_PORT\s*\|\|\s*(\d{4,5})/,/AGENT_PORT\s*\|\|\s*(\d{4,5})/,
     /PORT\s*\|\|\s*(\d{4,5})/,/port\s*[=:]\s*(\d{4,5})/,/(?:app\.run|uvicorn\.run)[^\n]*?(\d{4,5})/];
   for(const p of pats){const m=s.match(p);if(m){port=m[1];break;}}
   out.push(f+'|'+port+'|'+(f.endsWith('.py')?'python3':'node'));
  }}}
roots.forEach(r=>{if(fs.existsSync(r))walk(r,0)});
console.log(out.join('\n'));
