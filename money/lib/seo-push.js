#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),{execFile}=require("child_process");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),D=path.join(HERE,"data");
const K=require("./keysfile.js"),codes=require("./codes.js");
const PR=path.join(D,"seo-progress.json");
const rd=(f,d)=>{try{return JSON.parse(fs.readFileSync(f,"utf8"));}catch(e){return d;}};
const wr=(f,o)=>fs.writeFileSync(f,JSON.stringify(o,null,1));
const get=u=>new Promise(r=>execFile("curl",["-sL","-o","/dev/null","-w","%{http_code}","--max-time","12","-A","Mozilla/5.0 cinehub",u],e=>r(0)));
const jpost=(u,b)=>new Promise(r=>{const https=require("https");
  const d=JSON.stringify(b);const q=https.request(u,{method:"POST",headers:{"content-type":"application/json","content-length":Buffer.byteLength(d)}},x=>{x.resume();x.on("end",()=>r(x.statusCode));});
  q.on("error",()=>r(0));q.write(d);q.end();});
async function indexNow(){
  const host=K.get("INDEXNOW_HOST"),key=K.get("INDEXNOW_KEY"),pub=K.get("PUBLIC_URL");
  if(!host||!key||!pub)return 0;
  const st=rd(path.join(D,"targets.json"),{}),pages=(st.surfaces||[]).slice(0,200).map(s=>pub.replace(/\/$/,"")+"/"+s.url.replace(/^\//,""));
  const list=[pub,...pages].slice(0,400);
  const code=await jpost("https://api.indexnow.org/indexnow",{host,key,keyLocation:pub.replace(/\/$/,"")+"/"+key+".txt",urlList:list});
  console.log("  "+(code<400?"✔":"○")+" IndexNow: "+code+" ("+list.length+" رابطًا)");
  if(code<400)codes.save("IndexNow",{روابط:list.length,استجابة:code});
  return code<400?list.length:0;
}
async function pingSitemaps(){
  const pub=K.get("PUBLIC_URL");if(!pub)return;
  const s=pub.replace(/\/$/,"")+"/sitemap.xml";
  for(const u of ["https://www.bing.com/ping?sitemap="+encodeURIComponent(s),
                  "https://www.google.com/ping?sitemap="+encodeURIComponent(s)])await get(u);
  console.log("  ✔ Sitemap ping");
}
async function pushSites(batch){
  const F=path.join(D,"sites3000.json");
  if(!fs.existsSync(F))return 0;
  const S=JSON.parse(fs.readFileSync(F,"utf8")).sites;
  const p=rd(PR,{cursor:0,ok:0,fail:0});
  const slice=S.slice(p.cursor,p.cursor+batch);
  let ok=0;
  for(const s of slice){const c=await get(s.url);c&&c<400?ok++:p.fail++;}
  p.cursor=(p.cursor+batch)%S.length;p.ok+=ok;p.at=new Date().toISOString();
  wr(PR,p);
  console.log("  ✔ دفعتُ "+ok+"/"+slice.length+" موقعًا · المؤشر "+p.cursor+"/"+S.length);
  return ok;
}
(async()=>{
  const a=process.argv[2]||"daily";
  await indexNow();await pingSitemaps();
  await pushSites(a==="full"?300:300);
})();
