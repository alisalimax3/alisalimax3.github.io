/* بانر اشتراك ذكي + دعوة إحالة + تذكير سحب — تظهر حسب حالة المستخدم */
(function(){
 function st(k){try{return JSON.parse(localStorage.getItem(k)||'{}')}catch(e){return{}}}
 function once(k,days){var s=st('ch_ups'),t=Date.now();if(s[k]&&t-s[k]<days*86400000)return false;s[k]=t;localStorage.setItem('ch_ups',JSON.stringify(s));return true}
 function box(html){var d=document.createElement('div');
  d.style.cssText='position:fixed;left:10px;bottom:14px;z-index:9995;max-width:290px;background:#0b1020f2;border:1px solid #1e2a44;border-radius:13px;padding:12px;font:13px/1.7 system-ui;color:#e8f6ff;box-shadow:0 10px 30px #0009';
  d.innerHTML=html+'<div style="margin-top:8px"><button id="chx" style="background:transparent;border:1px solid #1e2a44;color:#8aa0bd;border-radius:8px;padding:4px 9px;cursor:pointer">إغلاق</button></div>';
  document.body.appendChild(d);d.querySelector('#chx').onclick=function(){d.remove()};return d}
 function bal(){return window.CHLedger?CHLedger.balance():0}
 function boot(){
  var t=window.CHAuth?CHAuth.token():null;
  if(!t&&once('auth',7)){box('<b>فعّل هويتك بلا بريد</b><br>كابتشا واحدة وتحفظ رصيدك سنة. <a href="/gate.html">فعّل</a>');return}
  if(bal()>=5&&once('wd',3)){box('<b>رصيدك $'+bal().toFixed(2)+'</b><br>بلغت حدّ السحب — <a href="/withdraw.html">اسحب إلى الكريمي</a>');return}
  if(!window.CHLic||!CHLic.active()){
   if(once('sub',5))box('<b>اشتراك فضي $2.99</b><br>بلا إعلانات + 1080p + إحالة 10%. <a href="/subscribe.html">اشترك</a>');return}
  if(once('ref',10)){var r=window.CHRewards?CHRewards.refer():null;
   if(r)box('<b>اربح من دعوة أصدقائك</b><br>كودك <code>'+r.code+'</code> — انسخ الرابط وشارك.<br><input value="'+r.link+'" style="width:100%;background:#0d1424;border:1px solid #1e2a44;color:#e8f6ff;border-radius:7px;padding:5px;direction:ltr;font-size:11px" onclick="this.select()">')}
 }
 document.addEventListener('ch:ads-ready',function(){setTimeout(boot,2500)});
})();
