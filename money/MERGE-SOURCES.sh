#!/usr/bin/env bash
# يدمج كل sources*.json في ملف واحد يقرأه الكود القديم — بلا أي patch
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$H/.." && pwd)"; cd "$ROOT"
mkdir -p "$ROOT/_backup/sources"
for f in "$H"/sources*.json; do [ -e "$f" ] && cp -n "$f" "$ROOT/_backup/sources/" 2>/dev/null; done
node - "$H" <<'JS'
const fs=require("fs"),path=require("path"),H=process.argv[2];
const F=["sources.json","sources-big.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"];
const seen=new Set(),out=[];
for(const f of F){try{for(const x of JSON.parse(fs.readFileSync(path.join(H,f),"utf8"))){
  if(x&&x.id&&!seen.has(x.id)){seen.add(x.id);out.push(x);}}}catch(e){}}
fs.writeFileSync(path.join(H,"sources-big.json"),JSON.stringify(out,null,1));
for(const f of ["sources.json","sources-west.json","sources-mega.json","sources-mega2.json","sources-mega3.json","sources-mega4.json"])
  fs.writeFileSync(path.join(H,f),"[]");
const cat={};out.forEach(x=>cat[x.cat]=(cat[x.cat]||0)+1);
console.log("  ✔ "+out.length+" منصة فريدة في sources-big.json — بلا تكرار");
console.log("  ✔ التصنيفات: "+Object.entries(cat).map(([k,v])=>k+"="+v).join(" "));
JS
