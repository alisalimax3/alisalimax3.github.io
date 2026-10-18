/* CineHub 3099 · live.js v5
   كل مصدر هنا مُختبَر ويعمل بلا مفتاح مدفوع.
   مستقل تمامًا: يبني واجهته بنفسه ولا يعتمد على دوال الصفحة. */
(function () {
"use strict";

var CFG = {
  tmdb: "8265bd1679663a7ea12ac168da84d2e8",
  tmdbAPI: "https://api.themoviedb.org/3",
  tmdbImg: "https://image.tmdb.org/t/p/w342",
  tv:   "https://api.tvmaze.com",
  ani:  "https://graphql.anilist.co",
  epor: "https://www.eporner.com/api/v2",
  rg:   "https://api.redgifs.com/v2"
};

var PLAY = [
  { n:"VidLink",   mv:"https://vidlink.pro/movie/%i",     tv:"https://vidlink.pro/tv/%i/%s/%e",     an:"https://vidlink.pro/anime/%i/%e/sub?fallback=true" },
  { n:"VidSrc.to", mv:"https://vidsrc.to/embed/movie/%i", tv:"https://vidsrc.to/embed/tv/%i/%s/%e" },
  { n:"2Embed",    mv:"https://www.2embed.cc/embed/%i",   tv:"https://www.2embed.cc/embedtv/%i/%s/%e" }
];

var LS = "ch3099.live.v5";
var DB = (function(){ try { return JSON.parse(localStorage.getItem(LS)) || {hist:[]}; } catch(e){ return {hist:[]}; } })();
function keep(){ try { localStorage.setItem(LS, JSON.stringify(DB)); } catch(e){} }

function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c];}); }
function tag(t,c,h){ var d=document.createElement(t); if(c)d.className=c; if(h!=null)d.innerHTML=h; return d; }

function get(url,opt){
  var ac=new AbortController(), tm=setTimeout(function(){ac.abort();},14000);
  var o=opt||{}; o.signal=ac.signal; if(!o.headers)o.headers={};
  return fetch(url,o).then(function(r){
    clearTimeout(tm);
    if(!r.ok) throw new Error("HTTP "+r.status);
    return r.json();
  });
}
function flat(a){ return [].concat.apply([],a); }

/* ───────── المصادر ───────── */

function srcTMDB(q,kind){
  var base=CFG.tmdbAPI+"/";
  var u = q
    ? base+"search/"+kind+"?api_key="+CFG.tmdb+"&language=ar&query="+encodeURIComponent(q)
    : base+kind+"/popular?api_key="+CFG.tmdb+"&language=ar";
  return get(u).then(function(r){
    return (r.results||[]).filter(function(x){return x.poster_path;}).map(function(x){
      return {
        id:"tm"+x.id, tmdb:x.id, type:kind,
        kind: kind==="movie"?"فيلم":"مسلسل",
        title: x.title||x.name||x.original_title||x.original_name,
        year:(x.release_date||x.first_air_date||"").slice(0,4),
        img: CFG.tmdbImg+x.poster_path,
        ov: x.overview||"",
        rate: x.vote_average?x.vote_average.toFixed(1):""
      };
    });
  });
}

function srcTV(q){
  var u = q ? CFG.tv+"/search/shows?q="+encodeURIComponent(q) : CFG.tv+"/shows?page=0";
  return get(u).then(function(r){
    var arr = q ? r : (r||[]).map(function(s){return {show:s};});
    return arr.map(function(x){
      var s=x.show;
      return {
        id:"tv"+s.id, kind:"مسلسل", title:s.name, type:"tv",
        year:(s.premiered||"").slice(0,4),
        img:(s.image&&(s.image.medium||s.image.original))||"",
        ov:(s.summary||"").replace(/<[^>]+>/g,""),
        rate:(s.rating&&s.rating.average)||""
      };
    });
  });
}

var ANI_F = 'id idMal title{english romaji} coverImage{large} averageScore startDate{year} description(asHtml:false)';
function srcAni(q){
  var body = q
    ? { query:'query($q:String){Page(perPage:24){media(search:$q,type:ANIME,sort:SEARCH_MATCH){'+ANI_F+'}}}', variables:{q:q} }
    : { query:'{Page(perPage:24){media(type:ANIME,sort:POPULARITY_DESC){'+ANI_F+'}}}' };
  return get(CFG.ani,{
    method:"POST",
    headers:{"Content-Type":"application/json","Accept":"application/json"},
    body: JSON.stringify(body)
  }).then(function(r){
    var m=(r.data&&r.data.Page&&r.data.Page.media)||[];
    return m.map(function(a){
      return {
        id:"an"+a.id, anilist:a.id, mal:a.idMal, kind:"أنمي", type:"anime",
        title:(a.title&&(a.title.english||a.title.romaji))||"أنمي",
        year:(a.startDate&&a.startDate.year)||"",
        img:(a.coverImage&&a.coverImage.large)||"",
        ov:(a.description||"").replace(/<[^>]+>/g,""),
        rate: a.averageScore?(a.averageScore/10).toFixed(1):""
      };
    });
  });
}

function srcEpor(q){
  var u=CFG.epor+"/video/search/?query="+encodeURIComponent(q||"top")+
        "&per_page=24&thumbsize=big&order=top-weekly&format=json";
  return get(u).then(function(r){
    return (r.videos||[]).map(function(v){
      return {
        id:"ep"+v.id, kind:"بالغين", type:"adult", title:v.title,
        year:(v.added||"").slice(0,4),
        img:(v.default_thumb&&v.default_thumb.src)||"",
        rate: v.rate&&v.rate!=="0.00"?v.rate:"",
        embed:v.embed, src:v.url
      };
    });
  });
}

var _rg=null;
function srcRG(q){
  return (_rg?Promise.resolve(_rg)
    : get(CFG.rg+"/auth/temporary").then(function(a){_rg=a.token;return _rg;}))
  .then(function(tok){
    return get(CFG.rg+"/gifs/search?search_text="+encodeURIComponent(q||"hot")+"&count=24&order=trending",
      {headers:{"Accept":"application/json","Authorization":"Bearer "+tok}});
  }).then(function(r){
    return (r.gifs||[]).map(function(g){
      return {
        id:"rg"+g.id, kind:"بالغين", type:"adult",
        title:(g.tags||[]).slice(0,3).join(" ")||"RedGifs",
        year:"", img:g.thumbnail||"", rate:"",
        embed:"https://www.redgifs.com/ifr/"+g.id,
        src:(g.urls&&(g.urls.hd||g.urls.sd))||""
      };
    });
  });
}

/* ───────── التشغيل ───────── */

var TABS=[{k:"all",n:"الكل"},{k:"movie",n:"أفلام"},{k:"tv",n:"مسلسلات"},{k:"anime",n:"أنمي"},{k:"adult",n:"🔞 بالغين"}];
var STATE={mode:"all",q:""};

function run(mode,q){
  q=(q||"").trim();
  var jobs=[];
  var A=(mode==="all"||mode==="movie"), B=(mode==="all"||mode==="tv"),
      C=(mode==="all"||mode==="anime"), D=(mode==="all"||mode==="adult");
  if(A) jobs.push(srcTMDB(q,"movie").catch(function(){return [];}));
  if(B) jobs.push(srcTMDB(q,"tv").catch(function(){return [];}));
  if(B) jobs.push(srcTV(q).catch(function(){return [];}));
  if(C) jobs.push(srcAni(q).catch(function(){return [];}));
  if(D) jobs.push(srcEpor(q).catch(function(){return [];}));
  if(D) jobs.push(srcRG(q).catch(function(){return [];}));
  return Promise.all(jobs).then(flat);
}

function css(){
  if(document.getElementById("lv-css")) return;
  var s=tag("style"); s.id="lv-css";
  s.textContent =
  "#live3099{margin:0 0 16px;padding:14px;border-radius:16px;background:linear-gradient(180deg,rgba(20,22,32,.94),rgba(12,13,20,.94));border:1px solid rgba(255,255,255,.09);color:#e9ecf5;font-family:system-ui,-apple-system,'Segoe UI',Tahoma,sans-serif;direction:rtl}"+
  "#live3099 h3{margin:0 0 10px;font-size:17px}"+
  ".lv-bar{display:flex;gap:8px;flex-wrap:wrap}"+
  "#lvq{flex:1;min-width:170px;padding:11px 13px;border-radius:11px;border:1px solid rgba(255,255,255,.14);background:rgba(0,0,0,.35);color:#fff;font-size:15px}"+
  ".lv-go{padding:11px 18px;border:0;border-radius:11px;cursor:pointer;font-weight:700;background:linear-gradient(180deg,#6c7cff,#4a5bf0);color:#fff}"+
  ".lv-tabs{display:flex;gap:6px;flex-wrap:wrap;margin:10px 0 6px}"+
  ".lv-tab{padding:7px 14px;border-radius:999px;cursor:pointer;font-size:13px;border:1px solid rgba(255,255,255,.14);background:rgba(255,255,255,.05);color:#cfd4e6}"+
  ".lv-tab.on{background:#6c7cff;border-color:#6c7cff;color:#fff}"+
  ".lv-stat{font-size:12px;opacity:.65;margin-bottom:10px}"+
  ".lv-grid{display:grid;gap:11px;grid-template-columns:repeat(auto-fill,minmax(132px,1fr))}"+
  ".lv-card{border-radius:13px;overflow:hidden;cursor:pointer;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.07);transition:.18s}"+
  ".lv-card:hover{transform:translateY(-3px);border-color:#6c7cff}"+
  ".lv-thumb{position:relative;aspect-ratio:2/3;background:#0b0d14;display:flex;align-items:center;justify-content:center}"+
  ".lv-thumb img{width:100%;height:100%;object-fit:cover;display:block}"+
  ".lv-ph{font-size:30px;opacity:.35}"+
  ".lv-kind,.lv-rate{position:absolute;font-style:normal;font-size:10.5px;padding:3px 7px;border-radius:7px;background:rgba(0,0,0,.72);color:#fff}"+
  ".lv-kind{top:6px;right:6px}.lv-rate{bottom:6px;left:6px;color:#ffd166}"+
  ".lv-meta{padding:8px 9px}"+
  ".lv-meta b{font-size:12.5px;line-height:1.35;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}"+
  ".lv-meta i{font-style:normal;font-size:11px;opacity:.55;display:block}"+
  ".lv-foot{margin-top:10px;font-size:11.5px;opacity:.5}"+
  ".lv-foot a{color:#8ea2ff}"+
  ".lv-modal{position:fixed;inset:0;z-index:99999;background:rgba(4,5,10,.88);display:flex;align-items:center;justify-content:center;padding:12px}"+
  ".lv-box{position:relative;width:100%;max-width:960px;max-height:94vh;overflow:auto;background:#101220;border:1px solid rgba(255,255,255,.12);border-radius:16px;padding:14px;color:#e9ecf5;direction:rtl;font-family:system-ui,sans-serif}"+
  ".lv-box h3{margin:0 0 10px;font-size:16px}.lv-box h3 i{font-style:normal;opacity:.6;font-size:13px}"+
  ".lv-x{position:absolute;top:10px;left:10px;width:32px;height:32px;border-radius:50%;border:0;cursor:pointer;background:rgba(255,255,255,.12);color:#fff;font-size:15px}"+
  ".lv-frame iframe{width:100%;aspect-ratio:16/9;border:0;border-radius:12px;background:#000;display:block}"+
  ".lv-provs{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:9px;font-size:12px}"+
  ".lv-provs span{opacity:.6}"+
  ".lv-provs button{padding:6px 12px;border-radius:999px;cursor:pointer;font-size:12px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.05);color:#cfd4e6}"+
  ".lv-provs button.on{background:#6c7cff;border-color:#6c7cff;color:#fff}"+
  ".lv-ov{font-size:12.5px;line-height:1.7;opacity:.72;margin:10px 0 0}"+
  ".lv-src{display:inline-block;margin-top:8px;font-size:12.5px;color:#8ea2ff;text-decoration:none}"+
  ".lv-load{padding:40px;text-align:center;opacity:.6;font-size:13px}"+".lv-share{display:flex;gap:6px;margin-top:10px;flex-wrap:wrap}"+".lv-share button{padding:7px 13px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.06);color:#cfd4e6;cursor:pointer;font-size:12px}"+
  "@media(max-width:520px){.lv-grid{grid-template-columns:repeat(auto-fill,minmax(106px,1fr))}}";
  document.head.appendChild(s);
}

function host(){ return document.getElementById("main")||document.querySelector("main")||document.body; }

function mount(){
  if(document.getElementById("live3099")) return;
  var s=tag("section","panel"); s.id="live3099";
  s.innerHTML =
    '<h3>⚡ محرّك حيّ — مصادر مباشرة بلا مفاتيح</h3>'+
    '<div class="lv-bar"><input id="lvq" type="search" placeholder="ابحث: فيلم / مسلسل / أنمي / بالغين"><button class="lv-go" id="lvgo">بحث</button></div>'+
    '<div class="lv-tabs" id="lvtabs"></div>'+
    '<div class="lv-stat" id="lvstat">جاهز.</div>'+
    '<div class="lv-grid" id="lvgrid"></div>'+
    '<div class="lv-foot" id="lvfoot"></div>';
  var h=host(); h.insertBefore(s,h.firstChild);

  var tb=document.getElementById("lvtabs");
  TABS.forEach(function(t){
    var b=tag("button","lv-tab",t.n); b.dataset.k=t.k;
    b.onclick=function(){ go(t.k); };
    tb.appendChild(b);
  });
  document.getElementById("lvgo").onclick=function(){ go(STATE.mode, document.getElementById("lvq").value); };
  document.getElementById("lvq").onkeydown=function(e){ if(e.key==="Enter") go(STATE.mode,this.value); };

  adsInit();
  go("all");
}

function mark(){
  var tb=document.getElementById("lvtabs"); if(!tb) return;
  [].forEach.call(tb.children,function(b){ b.classList.toggle("on", b.dataset.k===STATE.mode); });
}

function go(mode,q){
  STATE.mode=mode; if(q!==undefined) STATE.q=q; mark();
  var st=document.getElementById("lvstat"), g=document.getElementById("lvgrid");
  if(!st||!g) return;
  st.textContent="… جارٍ الجلب";
  g.innerHTML="";
  run(mode,STATE.q).then(function(list){
    var seen={}, out=[];
    list.forEach(function(it){ if(it&&it.title&&!seen[it.id]){ seen[it.id]=1; out.push(it); } });
    out.forEach(function(it){ g.appendChild(card(it)); });
    var lbl=(TABS.filter(function(t){return t.k===mode;})[0]||{}).n||"";
    st.textContent = out.length ? (out.length+" نتيجة · "+lbl) : "لا نتائج — جرّب كلمة أخرى.";
    if(STATE.q){ DB.hist.unshift(STATE.q); DB.hist=DB.hist.slice(0,8); keep(); }
  }).catch(function(e){
    st.textContent="فشل الجلب: "+e.message;
  });
}

function card(it){
  var c=tag("div","lv-card");
  c.innerHTML=
    '<div class="lv-thumb">'+
      (it.img?'<img loading="lazy" alt="" src="'+it.img+'">':'<span class="lv-ph">▶</span>')+
      '<em class="lv-kind">'+esc(it.kind)+'</em>'+
      (it.rate?'<em class="lv-rate">★ '+esc(it.rate)+'</em>':'')+
    '</div>'+
    '<div class="lv-meta"><b>'+esc(it.title)+'</b>'+(it.year?'<i>'+esc(it.year)+'</i>':'')+'</div>';
  c.onclick=function(){ play(it); };
  return c;
}

function tmdbIdFor(it){
  return get(CFG.tmdbAPI+"/search/tv?api_key="+CFG.tmdb+"&query="+encodeURIComponent(it.title))
    .then(function(r){ return r.results&&r.results[0]?r.results[0].id:null; })
    .catch(function(){ return null; });
}

function play(it){
  var old=document.getElementById("lvmodal"); if(old) old.remove();
  var m=tag("div","lv-modal"); m.id="lvmodal";

  var provs="";
  if(it.type!=="adult"){
    provs='<div class="lv-provs"><span>المشغّل:</span>'+
      PLAY.map(function(p,i){
        var ok = it.type==="movie"?p.mv : (it.type==="anime"?p.an:p.tv);
        return ok?'<button data-i="'+i+'">'+p.n+'</button>':'';
      }).join("")+'</div>';
  }

  m.innerHTML=
    '<div class="lv-box">'+
      '<button class="lv-x">✕</button>'+
      '<h3>'+esc(it.title)+(it.year?' <i>('+esc(it.year)+')</i>':'')+'</h3>'+
      provs+
      '<div class="lv-frame" id="lvframe"><div class="lv-load">جارٍ التحضير…</div></div>'+
      (it.ov?'<p class="lv-ov">'+esc(it.ov.slice(0,340))+'</p>':'')+
      '<div class="lv-share"><button data-sh="wa">واتساب</button><button data-sh="tg">تليجرام</button><button data-sh="cp">نسخ الرابط</button></div>'+
      (it.src?'<a class="lv-src" target="_blank" rel="noopener" href="'+it.src+'">فتح المصدر الأصلي ↗</a>':'')+
    '</div>';
  document.body.appendChild(m);
  m.querySelector(".lv-x").onclick=function(){ m.remove(); };
  var deep = location.origin + location.pathname + "?w=" + it.id;
  var txt = it.title + (it.year?(" ("+it.year+")"):"") + " — CineHub 3099\n" + deep;
  [].forEach.call(m.querySelectorAll("[data-sh]"), function(b){
    b.onclick=function(){
      var k=b.dataset.sh;
      if(k==="wa") window.open("https://wa.me/?text="+encodeURIComponent(txt),"_blank","noopener");
      else if(k==="tg") window.open("https://t.me/share/url?url="+encodeURIComponent(deep)+"&text="+encodeURIComponent(it.title),"_blank","noopener");
      else { try{navigator.clipboard.writeText(deep);}catch(e){} b.textContent="✓ تم النسخ"; }
    };
  });
  m.onclick=function(e){ if(e.target===m) m.remove(); };

  function load(i){
    var f=document.getElementById("lvframe"); if(!f) return;
    if(it.type==="adult"){ f.innerHTML=frame(it.embed); }
    else {
      var ready = it.tmdb||it.anilist ? Promise.resolve()
        : tmdbIdFor(it).then(function(id){ it.tmdb=id; });
      f.innerHTML='<div class="lv-load">جارٍ التحضير…</div>';
      ready.then(function(){
        var p=PLAY[i], url;
        if(!p){ f.innerHTML='<div class="lv-load">لا مشغّل متاح</div>'; return; }
        if(it.type==="movie") url=p.mv.replace("%i",it.tmdb);
        else if(it.type==="anime") url=(p.an).replace("%i",it.mal||it.anilist).replace("%e",1);
        else url=p.tv.replace("%i",it.tmdb).replace("%s",1).replace("%e",1);
        f.innerHTML = it.tmdb||it.anilist ? frame(url)
          : '<div class="lv-load">لم يُعثر على معرّف — جرّب مشغّلًا آخر</div>';
      });
    }
    [].forEach.call(m.querySelectorAll(".lv-provs button"),function(b){
      b.classList.toggle("on", +b.dataset.i===i);
    });
  }
  function frame(u){
    return '<iframe src="'+u+'" allowfullscreen allow="autoplay; encrypted-media; picture-in-picture" loading="lazy"></iframe>';
  }

  [].forEach.call(m.querySelectorAll(".lv-provs button"),function(b){
    b.onclick=function(){ load(+b.dataset.i); };
  });
  load(0);
}

/* ───────── الإعلانات: تُحمّل فقط عند وجود معرّف حقيقي ───────── */
function adsInit(){
  var saved={}; try{ saved=JSON.parse(localStorage.getItem("ch3099.ads"))||{}; }catch(e){}
  var cfg = saved;
  window.SETADS=function(o){ try{ localStorage.setItem("ch3099.ads", JSON.stringify(o)); }catch(e){} location.reload(); };
  var foot=document.getElementById("lvfoot");
  var scripts = cfg.scripts||[];
  scripts.forEach(function(u){
    var sc=document.createElement("script"); sc.async=true; sc.src=u; document.head.appendChild(sc);
  });
  if(foot){
    foot.innerHTML = scripts.length
      ? 'الإعلانات: مُفعّلة ('+scripts.length+' شبكة) · <a href="./partners.html">الشركاء</a>'
      : 'الإعلانات: غير مُفعّلة — أضِف معرّفك بـ SETADS({scripts:["//..."]}) · <a href="./partners.html">كيف؟</a>';
  }
}

/* ───────── الإقلاع ───────── */
function deepOpen(){
  var m=/[?&]w=([^&]+)/.exec(location.search); if(!m) return;
  var id=decodeURIComponent(m[1]); var pre=id.slice(0,2); var num=id.slice(2);
  function fromAni(a){ return {id:"an"+a.id,anilist:a.id,mal:a.idMal,kind:"أنمي",type:"anime",
    title:(a.title&&(a.title.english||a.title.romaji))||"أنمي",year:(a.startDate&&a.startDate.year)||"",
    img:(a.coverImage&&a.coverImage.large)||"",ov:(a.description||"").replace(/<[^>]+>/g,""),
    rate:a.averageScore?(a.averageScore/10).toFixed(1):""}; }
  function fromTm(x,kind){ return {id:"tm"+x.id,tmdb:x.id,type:kind,kind:kind==="movie"?"فيلم":"مسلسل",
    title:x.title||x.name,year:(x.release_date||x.first_air_date||"").slice(0,4),
    img:x.poster_path?CFG.tmdbImg+x.poster_path:"",ov:x.overview||"",
    rate:x.vote_average?x.vote_average.toFixed(1):""}; }
  if(pre==="a"){
    get(CFG.ani,{method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({query:'query($i:Int){Media(id:$i,type:ANIME){id idMal title{english romaji} coverImage{large} averageScore startDate{year} description(asHtml:false)}}',variables:{i:+num}})})
      .then(function(r){ var a=r.data&&r.data.Media; if(a) play(fromAni(a)); }).catch(function(){});
    return;
  }
  if(pre==="ep"||pre==="rg") return;
  get(CFG.tmdbAPI+"/movie/"+num+"?api_key="+CFG.tmdb+"&language=ar")
    .then(function(x){ play(fromTm(x,"movie")); })
    .catch(function(){
      get(CFG.tmdbAPI+"/tv/"+num+"?api_key="+CFG.tmdb+"&language=ar")
        .then(function(x){ play(fromTm(x,"tv")); }).catch(function(){});
    });
}
function boot(){ css(); mount(); deepOpen(); }
if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",boot); else boot();
[500,1500,3000,6000].forEach(function(t){ setTimeout(boot,t); });
new MutationObserver(function(){ if(!document.getElementById("live3099")) mount(); })
  .observe(document.body,{childList:true,subtree:true});

window.LIVE={run:run,go:go,cfg:CFG,play:play};
})();
