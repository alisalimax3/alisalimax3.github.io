#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"; cd "$ROOT"
if grep -q '^WALLET_ADDRESS=0x' keys.env 2>/dev/null; then
  echo "  ✔ محفظة موجودة: $(grep -m1 '^WALLET_ADDRESS=' keys.env | cut -d= -f2)"; exit 0; fi
echo "── إنشاء محفظة EVM حقيقية (Base / USDC / USDT) ──"
[ -d node_modules/ethers ] || { echo "  … تثبيت ethers"; npm i --no-audit --no-fund --silent ethers@6 >/dev/null 2>&1 || { echo "  ✗ فشل npm"; exit 1; }; }
node - "$ROOT" <<'JS'
const fs=require("fs"),path=require("path");
const root=process.argv[2],{Wallet}=require(path.join(root,"node_modules","ethers"));
const KEYS=path.join(root,"keys.env"),w=Wallet.createRandom();
function setkv(k,v){let t="";try{t=fs.readFileSync(KEYS,"utf8");}catch(e){}
  const re=new RegExp("^"+k+"=.*$","m");
  t=re.test(t)?t.replace(re,k+"="+v):(t&&!t.endsWith("\n")?t+"\n":"")+k+"="+v+"\n";
  const tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);}
setkv("WALLET_ADDRESS",w.address);setkv("WALLET_PRIVATE_KEY",w.privateKey);setkv("WALLET_MNEMONIC",w.mnemonic.phrase);
try{fs.chmodSync(KEYS,0o600);}catch(e){}
require(path.join(root,"money","lib","codes.js")).save("محفظة EVM — Base",{
 "العنوان":w.address,"العبارة (12 كلمة)":w.mnemonic.phrase,"المفتاح الخاص":w.privateKey,"الشبكة":"Base mainnet (8453)"});
console.log("  ✔ العنوان : "+w.address);
console.log("  ⚠ اكتب الـ12 كلمة على ورق الآن. لا يوجد استرجاع بدونها.");
JS
