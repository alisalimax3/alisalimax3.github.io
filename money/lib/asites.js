#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const H=path.resolve(__dirname,".."),D=path.join(H,"data");
let KW=[];try{KW=JSON.parse(fs.readFileSync(path.join(D,"targets.json"),"utf8")).keywords||[];}catch(e){}
const BASE=KW.length?KW:["افلام اون لاين","مسلسلات مترجمة","انمي مترجم","سينما","افلام اجنبية"];
const EXT=["مترجم","اون لاين","hd","مجانا","2026","جديد"];
const EN=["watch movies online","streaming","series subtitles","anime english","free movies","cinema online"];
const KWS=[...new Set([].concat(BASE,BASE.flatMap(k=>EXT.map(e=>k+" "+e)),EN))].slice(0,60);
const ENG={google:"https://www.google.com/search?q=",bing:"https://www.bing.com/search?q=",ddg:"https://duckduckgo.com/?q=",
 yandex:"https://yandex.com/search/?text=",brave:"https://search.brave.com/search?q=",startpage:"https://www.startpage.com/sp/search?query=",
 ecosia:"https://www.ecosia.org/search?q=",qwant:"https://www.qwant.com/?q=",mojeek:"https://www.mojeek.com/search?q=",
 searx:"https://searx.be/search?q=",baidu:"https://www.baidu.com/s?wd=",naver:"https://search.naver.com/search.naver?query=",
 seznam:"https://search.seznam.cz/?q=",yep:"https://yep.com/web?q=",presearch:"https://presearch.com/search?q=",
 metager:"https://metager.org/meta/meta.ger3?eingabe=",marginalia:"https://search.marginalia.nu/search?query=",
 wiby:"https://wiby.me/?q=",onesearch:"https://www.onesearch.com/yahoo-search?p=",
 youtube:"https://www.youtube.com/results?search_query=",tiktok:"https://www.tiktok.com/search?q=",
 pinterest:"https://www.pinterest.com/search/pins/?q=",reddit:"https://www.reddit.com/search/?q=",
 quora:"https://www.quora.com/search?q=",medium:"https://medium.com/search?q=",tumblr:"https://www.tumblr.com/search/",
 vk:"https://vk.com/search?c[q]=",x:"https://x.com/search?q=",threads:"https://www.threads.net/search?q=",
 mastodon:"https://mastodon.social/search?q=",linkedin:"https://www.linkedin.com/search/results/all/?keywords="};
const DIR=`producthunt.com betalist.com alternativeto.net capterra.com g2.com crunchbase.com startupbase.io f6s.com saashub.com
toolify.ai theresanaiforthat.com futurepedia.io aitools.fyi topai.tools openfuture.ai aitoolhunt.com insidr.ai aitoolnet.com
aixploria.com startuplist.io land-book.com godly.website designnominees.com awwwards.com cssdesignawards.com thefwa.com
dribbble.com behance.net onepagelove.com httpster.net minimal.gallery siteinspire.com webdesignclip.com pinterest.com tumblr.com
medium.com substack.com hashnode.dev dev.to hackernoon.com freecodecamp.org sitepoint.com smashingmagazine.com css-tricks.com
similarweb.com semrush.com ahrefs.com moz.com majestic.com statshow.com siteworthtraffic.com worthofweb.com urlscan.io
virustotal.com shodan.io censys.io securityheaders.com ssllabs.com mxtoolbox.com dnschecker.org intodns.com whatsmydns.net
pingdom.com gtmetrix.com webpagetest.org pagespeed.web.dev validator.w3.org jigsaw.w3.org jsonformatter.org beautifier.io
tinyjpg.com squoosh.app tinypng.com cloudconvert.com zamzar.com convertio.co ilovepdf.com smallpdf.com remove.bg
photopea.com canva.com figma.com unsplash.com pexels.com pixabay.com freepik.com vecteezy.com flaticon.com iconfinder.com
fontawesome.com fonts.google.com dafont.com coolors.co colorhunt.co fontpair.co typewolf.com layers.to uplabs.com codepen.io
jsfiddle.net jsbin.com codesandbox.io stackblitz.com replit.com glitch.com gitlab.com bitbucket.org sourceforge.net apache.org
mozilla.org w3.org ietf.org rfc-editor.org wikimedia.org wikipedia.org wikidata.org archive.org gutenberg.org openlibrary.org
standardebooks.org annas-archive.org arxiv.org crossref.org openalex.org doaj.org core.ac.uk semanticscholar.org researchgate.net
academia.edu jstor.org springer.com nature.com sciencedirect.com ieee.org acm.org biorxiv.org medrxiv.org ssrn.com osf.io
figshare.com zenodo.org dryad.org imdb.com rottentomatoes.com metacritic.com letterboxd.com trakt.tv tvmaze.com thetvdb.com
simkl.com anilist.co myanimelist.net kitsu.io anime-planet.com mangaupdates.com mydramalist.com justwatch.com reelgood.com
allmovie.com filmweb.pl tmdb.org omdbapi.com kinopoisk.ru the-numbers.com boxofficemojo.com mubi.com indiewire.com variety.com
deadline.com hollywoodreporter.com collider.com slashfilm.com screenrant.com cinemablend.com denofgeek.com ign.com gamespot.com
polygon.com kotaku.com eurogamer.net pcgamer.com rockpapershotgun.com vg247.com destructoid.com giantbomb.com opencritic.com
howlongtobeat.com backloggd.com steamgifts.com isthereanydeal.com cheapshark.com gg.deals humblebundle.com fanatical.com
greenmangaming.com gog.com epicgames.com playstation.com xbox.com nintendo.com neocities.org surge.sh netlify.app vercel.app
render.com railway.app fly.io tiiny.host static.app web.app pages.dev github.io gitlab.io codeberg.org sourcehut.org
pastebin.com hastebin.com termbin.com 0x0.st file.io transfer.sh tmpfiles.org catbox.moe pixeldrain.com mega.nz
drive.google.com dropbox.com onedrive.live.com icedrive.net pcloud.com koofr.net filen.io storj.io backblaze.com
wasabi.com idrive.com ubuntu.com debian.org archlinux.org alpine.org termux.dev f-droid.org apkmirror.com apkpure.com
uptodown.com softonic.com majorgeeks.com fosshub.com ninite.com brew.sh snapcraft.io flatpak.org appimage.github.io`.split(/\s+/).filter(Boolean);
const sites=[];
DIR.forEach(d=>sites.push({t:"دليل",url:"https://"+d}));
for(const[k,u]of Object.entries(ENG))for(const q of KWS)sites.push({t:"محرّك",engine:k,url:u+encodeURIComponent(q)});
for(const q of KWS.slice(0,20))sites.push({t:"هاشتاق",url:"https://www.instagram.com/explore/tags/"+q.replace(/\s+/g,"")});
try{JSON.parse(fs.readFileSync(path.join(H,"sources-big.json"),"utf8")).forEach(x=>{if(x.url&&x.url!=="-")sites.push({t:"منصة",cat:x.cat,url:x.url});});}catch(e){}
const seen=new Set();const out=sites.filter(s=>{const k=s.url.replace(/\/$/,"");if(seen.has(k))return false;seen.add(k);return true;});
const by={};out.forEach(s=>by[s.t]=(by[s.t]||0)+1);
fs.writeFileSync(path.join(D,"sites-mega.json"),JSON.stringify({at:new Date().toISOString(),total:out.length,counts:by,sites:out},null,1));
console.log("  ✔ "+out.length+" هدف حقيقي — "+Object.entries(by).map(([k,v])=>k+"="+v).join(" · "));
