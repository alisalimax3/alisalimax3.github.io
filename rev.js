/* CineHub 3099 · محرك الأرباح: Smartlink + Offerwall + إحالة + مشاهدة */
(function(){
  var C=null, EP=localStorage.getItem('ch_endpoint') || '';
  function uid(){ return window.CH?CH.uid():'anon'; }
  function load(){ return fetch('/revenue.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){C=j;return j}).catch(function(){return null}); }
  function post(type,payload){ if(!EP) return; try{ fetch(EP,{method:'POST',mode:'no-cors',headers:{'Content-Type':'text/plain'},body:JSON.stringify({type:type,uid:uid(),payload:payload})}); }catch(e){} }
  function fill(s){ return String(s||'').replace('{uid}',uid()).replace('{APP}',(C&&C.cpx_app)||''); }
  window.CHRev={
    ready:function(cb){ if(C) return cb(C); load().then(function(j){ if(j&&window.CH_CAPTCHA){} cb(j||{offerwalls:[],affiliates:[]}); }); },
    smartlink:function(){ return C?C.smartlink:''; },
    openSmartlink:function(){
      var u=C&&C.smartlink; if(!u){ alert('لم يُضبط Smartlink بعد'); return; }
      post('clicks',{kind:'smartlink',url:u});
      window.open(u,'_blank','noopener');
    },
    offerwall:function(el,id){
      window.CHRev.ready(function(c){
        var o=(c.offerwalls||[]).filter(function(x){return x.id===id})[0];
        if(!o||!o.src){ el.innerHTML='<p class="l">لم يُضبط بعد.</p>'; return; }
        var f=document.createElement('iframe');
        f.src=fill(o.src); f.style.cssText='width:100%;min-height:620px;border:0;border-radius:12px;background:#0d1424';
        el.innerHTML=''; el.appendChild(f);
        post('offerwall_open',{id:id});
      });
    },
    watch:function(cb){
      window.CHRev.ready(function(c){
        var pool=(c.affiliates||[]).map(function(a){return a.url}).filter(Boolean);
        if(c.smartlink) pool.push(c.smartlink);
        if(!pool.length){ cb(null); return; }
        var u=pool[Math.floor(Math.random()*pool.length)];
        window.open(u,'_blank','noopener');
        var r=(c.watch&&c.watch.reward_usd)||0.0015;
        if(window.CHLedger) CHLedger.bonus(r,'watch');
        post('watch',{url:u,reward:r});
        cb(u);
      });
    },
    click:function(id,url){ post('clicks',{kind:id,url:url}); }
  };
})();
