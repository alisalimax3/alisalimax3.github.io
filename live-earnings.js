(function(){
 var e=document.getElementById('ch-live');
 if(!e){e=document.createElement('div');e.id='ch-live';
  e.style.cssText='position:fixed;top:10px;left:10px;z-index:9997;background:#0b1020ee;border:1px solid #1e2a44;color:#9fe8ff;font:11px/1.7 system-ui;padding:7px 11px;border-radius:10px;max-width:270px';
  addEventListener('DOMContentLoaded',function(){document.body.appendChild(e)})}
 function paint(){
  var imp=+(localStorage.getItem('ch_impressions')||0);
  fetch('/revenue.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(v){
   var hb=0;
   return fetch('/heartbeat.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(h){hb=h}).catch(function(){}).then(function(){
    var live=v.ok;
    e.innerHTML='<b>'+(live?'💰 إيراد حقيقي من الشبكة':'⚠ لا مفتاح API بعد')+'</b><br>'+
     'ظهور الشبكة: <b>'+(v.impressions||0).toLocaleString('en')+'</b> · نقرات: <b>'+(v.clicks||0)+'</b><br>'+
     'إيراد 30 يوم: <b>$'+Number(v.revenue||0).toFixed(4)+'</b>'+(v.error?'<br><span style="color:#fbbf24">'+v.error.slice(0,60)+'</span>':'')+
     '<br><span style="opacity:.7">ظهور جهازك: '+imp.toLocaleString('en')+' · المحرّك: '+(hb.t?hb.t.slice(5,16)+'Z':'—')+'</span>';
   });
  }).catch(function(){e.innerHTML='زيارات <b>'+(+(localStorage.getItem('ch_visits')||0))+'</b> · ظهور جهازك <b>'+imp+'</b>'});
 }
 setInterval(paint,15000);paint();
})();
