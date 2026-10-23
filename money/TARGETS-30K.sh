#!/usr/bin/env bash
set -uo pipefail
H="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node - "$H" <<'JS'
const fs=require("fs"),path=require("path"),H=process.argv[2];
const F=path.join(H,"data","targets.json");
let t={};try{t=JSON.parse(fs.readFileSync(F,"utf8"));}catch(e){}
const C=t.countries||["us","gb","de","fr","es","it","eg","sa","ae","in"];
const KW=t.keywords||[];
const P=JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8"));
const MONEY=["adult","ads","pay","crypto","channel"];
const mp=P.filter(x=>MONEY.includes(x.cat));
const SUB=t.subreddits||[],TG=t.telegram||[],YT=t.youtube||[],FO=t.forums||[],DE=t.deals||[],PI=t.pins||[],TU=t.tubes||[],FE=t.feeds||[];
t.surfaces=[];for(const x of P){if(!x.url||x.url==="-")continue;
  for(const p of ["","/login","/signup","/pricing","/docs","/api","/status","/blog","/contact","/about","/rss","/embed"])
    t.surfaces.push({id:x.id,url:x.url.replace(/\/$/,"")+p});}
t.platformsGeo=[];for(const x of mp)for(const c of C)t.platformsGeo.push({id:x.id,cc:c,url:x.url});
t.communities=[];
for(const r of SUB)for(const p of ["","/top","/new","/about.json"])t.communities.push({net:"reddit",url:"https://www.reddit.com/r/"+r+p});
for(const g of TG)for(const p of ["","/s/"])t.communities.push({net:"telegram",url:p==="/s/"?"https://t.me/s/"+g:"https://t.me/"+g});
for(const y of YT)for(const p of ["","/videos","/about"])t.communities.push({net:"youtube",url:"https://www.youtube.com/@"+y+p});
for(const f of FO)for(const p of ["","/latest","/categories"])t.communities.push({net:"forum",url:"https://"+f+p});
for(const d of DE)for(const p of ["","/deals"])t.communities.push({net:"deals",url:"https://"+d+p});
for(const p of PI)for(const p of PI){} 
t.communities.push(...PI.map(x=>({net:"pinterest",url:"https://www.pinterest.com/search/pins/?q="+x})));
for(const u of TU)for(const p of ["","/embed"])t.communities.push({net:"tube",url:"https://"+u+".com"+p});
t.searches=[];const SE=["youtube.com/results?search_query=","tiktok.com/search?q=","twitter.com/search?q=","reddit.com/search/?q=","quora.com/search?q=","medium.com/search?q=","tumblr.com/search/","vk.com/search?c[q]="];
for(const k of KW)for(const e of SE)t.searches.push({q:k,url:"https://www."+e+encodeURIComponent(k)});
t.longtail=[];const LT=["pinterest.com/search/pins/?q=","instagram.com/explore/tags/","tiktok.com/tag/","youtube.com/hashtag/","twitter.com/hashtag/","telegram.me/s/","reddit.com/r/","mastodon.social/tags/","tumblr.com/tagged/","vk.com/tag"];
for(const k of KW)for(const e of LT)t.longtail.push({q:k,url:"https://www."+e+encodeURIComponent(k.replace(/\s+/g,""))});
t.hashtags=KW.map(k=>"#"+k.replace(/\s+/g,"_"));
t.geoSearch=[];for(const c of C)for(const e of ["youtube.com/results?search_query=","google.com/search?q=","reddit.com/search/?q=","pinterest.com/search/pins/?q=","twitter.com/search?q=","tiktok.com/search?q=","bing.com/search?q=","duckduckgo.com/?q="])
  t.geoSearch.push({cc:c,url:"https://www."+e+encodeURIComponent(KW[0]||"movies")});
t.geoKeywords=[];for(const c of C)for(const k of KW)t.geoKeywords.push({cc:c,q:k});
t.feedsGeo=[];for(const c of C)for(const f of FE.slice(0,10))t.feedsGeo.push({cc:c,url:"https://"+f});
t.directories=t.directories||["producthunt.com","betalist.com","alternativeto.net","capterra.com","g2.com","crunchbase.com","startupbase.io","f6s.com","saashub.com","toolify.ai","theresanaiforthat.com","futurepedia.io","aitools.fyi","topai.tools","openfuture.ai","supertools.therundown.ai","aitoolhunt.com","insidr.ai","aitoolnet.com","aixploria.com"].map(d=>({net:"directory",url:"https://www."+d}));
const c={};for(const k of Object.keys(t))if(Array.isArray(t[k]))c[k]=t[k].length;
const total=Object.values(c).reduce((a,b)=>a+b,0);
t.counts=c;t.total=total;t.generated=new Date().toISOString();
fs.mkdirSync(path.dirname(F),{recursive:true});fs.writeFileSync(F,JSON.stringify(t));
console.log("  ✔ أهداف: "+total.toLocaleString()+" نقطة اتصال حقيقية");
JS
