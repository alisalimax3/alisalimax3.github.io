#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data"),DB=require("./z-db.js"),REC=require("./z-recipes.js");
const ENG={google:"https://www.google.com/search?q=",bing:"https://www.bing.com/search?q=",ddg:"https://duckduckgo.com/?q=",
 yandex:"https://yandex.com/search/?text=",brave:"https://search.brave.com/search?q=",startpage:"https://www.startpage.com/sp/search?query=",
 ecosia:"https://www.ecosia.org/search?q=",qwant:"https://www.qwant.com/?q=",mojeek:"https://www.mojeek.com/search?q=",
 searx:"https://searx.be/search?q=",baidu:"https://www.baidu.com/s?wd=",naver:"https://search.naver.com/search.naver?query=",
 seznam:"https://search.seznam.cz/?q=",yep:"https://yep.com/web?q=",presearch:"https://presearch.com/search?q=",
 metager:"https://metager.org/meta/meta.ger3?eingabe=",marginalia:"https://search.marginalia.nu/search?query=",
 wiby:"https://wiby.me/?q=",youtube:"https://www.youtube.com/results?search_query=",tiktok:"https://www.tiktok.com/search?q=",
 pinterest:"https://www.pinterest.com/search/pins/?q=",reddit:"https://www.reddit.com/search/?q=",quora:"https://www.quora.com/search?q=",
 medium:"https://medium.com/search?q=",tumblr:"https://www.tumblr.com/search/",vk:"https://vk.com/search?c[q]=",
 x:"https://x.com/search?q=",threads:"https://www.threads.net/search?q=",mastodon:"https://mastodon.social/search?q=",
 linkedin:"https://www.linkedin.com/search/results/all/?keywords="};
let KW=[];try{KW=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords||[];}catch(e){}
const BASE=KW.length?KW:["افلام اون لاين","مسلسلات مترجمة","انمي مترجم"];
const EXT=["مترجم","اون لاين","hd","مجانا","2026"];
const EN=["watch movies online","streaming","anime english"];
const KWS=[...new Set([].concat(BASE,BASE.flatMap(k=>EXT.map(e=>k+" "+e)),EN))].slice(0,60);
function build(){
  DB.ensure();let n=0,svc=0,dir=0,src=0,sea=0;
  for(const rec of REC.all()){DB.upsert("svc-"+rec.id,{kind:"service",cat:rec.cat,name:rec.name,home:rec.home,signup:rec.signup,
    recipe:rec.id,domain:REC.h(rec.home),stage:"new",conf:rec.conf});svc++;n++;}
  const dirs=new Set(REC.all().map(x=>REC.h(x.home)));
  try{JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8")).forEach(x=>{if(x.url&&x.url!=="-")dirs.add(REC.h(x.url));});}catch(e){}
  for(const d of dirs){if(REC.match(d))continue;DB.upsert("dir-"+d,{kind:"directory",cat:"dir",name:d,home:"https://"+d,signup:"https://"+d,recipe:"",domain:d,stage:"new"});dir++;n++;}
  try{const t=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8"));
    (t.surfaces||[]).forEach((s,i)=>{const u=(s.url||"").replace(/^\//,"");if(!u)return;
      DB.upsert("src-"+i,{kind:"platform",cat:"platform",name:u,home:(t.base||"")+"/"+u,recipe:"",stage:"new"});src++;n++;});}catch(e){}
  for(const[k,u]of Object.entries(ENG))for(const q of KWS){const id="sea-"+k+"-"+q.replace(/\s+/g,"_");
    DB.upsert(id,{kind:"search",cat:"search",name:k+": "+q,engine:k,query:q,home:u+encodeURIComponent(q),signup:u+encodeURIComponent(q),recipe:"",stage:"new"});sea++;n++;}
  const s=DB.stats();
  fs.writeFileSync(path.join(D,"registry-summary.json"),JSON.stringify({at:new Date().toISOString(),services:svc,directories:dir,platforms:src,searches:sea,total:n,byStage:s.by},null,1));
  console.log("  ✔ سجل الأهداف: "+n+" هدفًا — خدمات "+svc+" · أدلة "+dir+" · منصات "+src+" · بحث "+sea);
  DB.jrn("registry",{total:n});return n;}
module.exports={build};
if(require.main===module)build();
