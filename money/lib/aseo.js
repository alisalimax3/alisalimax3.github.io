#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
const K=require("./akeys.js"),codes=require("./acodes.js");
const P=path.join(D,"seo-progress.json");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const get=u=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","-w","%{http_code}","--max-time","12","-A","Mozilla/5.0 apex",u],(e,so)=>r(Number(so)||0)));
const post=(u,b)=>new Promise(r=>{const https=require("https"),d=JSON.stringify(b);
  const q=https.request(u,{method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(x.statusCode));});
  q.on("error",()=>r(0));q.write(d);q.end();});
function urls(){try{const s=fs.readFileSync(path.join(require("path").resolve(__dirname,"..",".."),"sitemap.xml"),"utf8");
  return [...s.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m=>m[1]);}catch(e){return[];}}
async function indexnow(){const host=K.get("INDEXNOW_HOST"),key=K.get("INDEXNOW_KEY"),pub=K.get("PUBLIC_URL");
  if(!host||!key||!pub)return 0;
  const list=[pub.replace(/\/$/,"")].concat(urls()).slice(0,500);
  const c=await post("https://api.indexnow.org/indexnow",{host,key,keyLocation:pub.replace(/\/$/,"")+"/"+key+".txt",urlList:list});
  console.log("  "+(c<400?"✔":"○")+" IndexNow: "+c+" ("+list.length+" رابطًا)");
  if(c<400)codes.save("IndexNow",{روابط:list.length,استجابة:c});return c<400?list.length:0;}
async function pings(){const pub=K.get("PUBLIC_URL");if(!pub)return 0;
  const s=encodeURIComponent(pub.replace(/\/$/,"")+"/sitemap.xml");
  const E=["https://www.google.com/ping?sitemap="+s,"https://www.bing.com/ping?sitemap="+s];
  let n=0;for(const u of E){const c=await get(u);if(c&&c<400)n++;}
  console.log("  ✔ ping sitemap: "+n+"/"+E.length);return n;}
async function push(n){const F=path.join(D,"sites-mega.json");if(!fs.existsSync(F))return 0;
  const S=JSON.parse(fs.readFileSync(F,"utf8")).sites,p=rd(P,{cursor:0,ok:0,fail:0,rounds:0});
  const slice=S.slice(p.cursor,p.cursor+n);let ok=0;
  const {pool}=require("./apool.js");
  const res=await pool(slice.map((s,i)=>({name:"s"+i,cmd:"curl",args:["-sL","-o","/dev/null","--max-time","10","-A","Mozilla/5.0 apex",s.url],timeout:20000})),6);
  res.forEach(r=>r.ok?ok++:p.fail++);
  p.cursor=(p.cursor+n)%S.length;p.ok+=ok;p.rounds++;p.at=new Date().toISOString();fs.writeFileSync(P,JSON.stringify(p,null,1));
  console.log("  ✔ دُفعت "+ok+"/"+slice.length+" هدفًا · المؤشر "+p.cursor+"/"+S.length+" · جولات "+p.rounds);return ok;}
(async()=>{const n=Number(process.argv[2]||"300");await indexnow();await pings();await push(n);
  require("./aaudit.js").add("seo",{pushed:n});})();
