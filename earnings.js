(function(){
  var KEY='ch3099_earn_v3', base=0, t0=Date.now(), rate=0.00002, ready=false;
  function st(){try{return JSON.parse(localStorage.getItem(KEY))||{}}catch(e){return{}}}
  function sv(s){localStorage.setItem(KEY,JSON.stringify(s))}
  function money(v){return '$'+Number(v||0).toFixed(6)}
  function paint(v){
    document.querySelectorAll('[data-earn]').forEach(function(e){e.textContent=money(v)});
    document.querySelectorAll('[data-earn-live]').forEach(function(e){e.textContent=money(v)});
  }
  function smooth(){ if(ready) paint(base + rate*(Date.now()-t0)/1000); }
  fetch('/wallet.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(w){
    base=Number(w.balance||0); rate=Number(w.hourly_rate||0.00002); t0=Date.now(); ready=true;
    document.querySelectorAll('[data-views]').forEach(function(e){e.textContent=w.views||0});
    document.querySelectorAll('[data-imp]').forEach(function(e){e.textContent=w.views||0});
    document.querySelectorAll('[data-hourly]').forEach(function(e){e.textContent='$'+Number(rate).toFixed(5)});
  }).catch(function(){ready=true});
  function hour(){
    var s=st(),now=Date.now(); s.last=s.last||now; s.usd=s.usd||0;
    var h=Math.floor((now-s.last)/3600000);
    if(h>0){ s.usd=+(s.usd+rate*3600*h).toFixed(6); s.last+=h*3600000; sv(s); }
  }
  document.addEventListener('DOMContentLoaded',function(){
    var s=st(); s.views=(s.views||0)+1; s.last=s.last||Date.now(); sv(s);
    hour(); setInterval(hour,60000); setInterval(smooth,1000);
    if('Notification' in window && Notification.permission==='default'){try{Notification.requestPermission()}catch(e){}}
    if(navigator.storage&&navigator.storage.persist){try{navigator.storage.persist()}catch(e){}}
    if('serviceWorker' in navigator){try{navigator.serviceWorker.register('/sw.js')}catch(e){}}
  });
  window.chEarn={state:st,reload:function(){location.reload()}};
})();
