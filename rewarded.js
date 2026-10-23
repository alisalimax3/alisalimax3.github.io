/* إعلان مكافأة — يشاهد المستخدم فيربح هو والتطبيق */
(function(){
 var N=null,busy=false;
 function cfg(cb){fetch('/networks.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){N=j;cb()}).catch(cb)}
 function today(){return new Date().toISOString().slice(0,10)}
 function left(){var d=JSON.parse(localStorage.getItem('ch_rw')||'{}');var t=today();return (d.day===t?(N.rewarded.daily_cap-(d.n||0)):N.rewarded.daily_cap)}
 function credit(){
  var d=JSON.parse(localStorage.getItem('ch_rw')||'{}');var t=today();
  d=(d.day===t)?d:{day:t,n:0};d.n=(d.n||0)+1;localStorage.setItem('ch_rw',JSON.stringify(d));
  var v=(N.rewarded.per_reward||0.004);
  if(window.CHLedger)CHLedger.bonus(v,'rewarded');
  try{window.dispatchEvent(new CustomEvent('ch:rewarded',{detail:v}))}catch(e){}
  return v}
 function show(){
  if(busy)return;if(left()<=0){alert('استنفدت مكافآت اليوم — عد غدًا');return}
  if(!window.CHCaptcha||!CHCaptcha.ready()){ if(window.CHCaptcha)CHCaptcha.mount(); }
  busy=true;
  var o=document.createElement('div');
  o.style.cssText='position:fixed;inset:0;background:#04070fdd;z-index:99999;display:grid;place-items:center;padding:14px';
  o.innerHTML='<div style="background:#111827;border:1px solid #1e2a44;border-radius:16px;max-width:520px;width:100%;padding:16px;text-align:center">'+
   '<h3 style="margin:0 0 8px">إعلان مكافأة</h3><div id="rwbox" style="min-height:120px;display:grid;place-items:center;border:1px solid #1e2a44;border-radius:12px;overflow:hidden"></div>'+
   '<div id="rwmsg" style="color:#8aa0bd;font-size:13px;margin-top:10px">شاهد 15 ثانية…</div>'+
   '<div style="margin-top:10px"><b id="rwleft"></b></div>'+
   '<button id="rwx" style="margin-top:10px;background:#0d1424;color:#e8f6ff;border:1px solid #1e2a44;border-radius:9px;padding:9px 14px">إغلاق</button></div>';
  document.body.appendChild(o);document.getElementById('rwleft').textContent='المتبقي اليوم: '+left();
  var b=document.getElementById('rwbox');
  var nz=N.rewarded&&N.rewarded.zone;
  if(nz){var f=document.createElement('iframe');f.src='//libtl.com/sdk.js'==='x'?'':'https://libtl.com/sdk.js';
   var s=document.createElement('script');s.src='https://libtl.com/sdk.js';s.setAttribute('data-zone',nz);
   s.setAttribute('data-sdk','show_'+nz);document.head.appendChild(s)}
  var nAd=(N.networks||[]).filter(function(n){return n.id==='adsterra'&&n.enabled&&n.keys.popunder;})[0];
  if(nAd){var i2=document.createElement('iframe');i2.src='//www.highperformanceformat.com/'+nAd.keys.banner_mid+'/invoke.html';
   i2.width=300;i2.height=250;i2.setAttribute('frameborder','0');b.appendChild(i2)}
  var t=15;var iv=setInterval(function(){t--;document.getElementById('rwmsg').textContent='شاهد '+t+' ثانية…';
   if(t<=0){clearInterval(iv);var v=credit();document.getElementById('rwmsg').innerHTML='<b style="color:#22c55e">✓ ربحت $'+v.toFixed(4)+'</b>';
    document.getElementById('rwleft').textContent='المتبقي اليوم: '+left();busy=false}},1000);
  document.getElementById('rwx').onclick=function(){o.remove();busy=false;clearInterval(iv)};
 }
 document.addEventListener('ch:ads-ready',function(){
  var btn=document.createElement('button');
  btn.textContent='▶ إعلان مكافأة';
  btn.style.cssText='position:fixed;bottom:58px;left:10px;z-index:9996;background:#22c55e;color:#04121a;border:0;border-radius:999px;padding:9px 14px;font-weight:800;cursor:pointer;box-shadow:0 6px 18px #0008';
  btn.onclick=show;document.body.appendChild(btn);
 });
 window.CHRewarded={show:show,left:function(){return N?left():0}};
})();
