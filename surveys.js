(function(){
 function uid(){return (window.CHCloud?CHCloud.uid():'anon')}
 function render(){
  fetch('/offerwalls.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){
   var host=document.getElementById('walls'); if(!host)return;
   host.innerHTML=(j.walls||[]).map(function(w){
    var url=w.url?w.url.replace('{uid}',uid()).replace('{USER_ID}',uid()):'';
    return '<div class="card"><b>'+w.name+'</b><div class="l">ربح لكل استطلاع: '+w.rpm+' · أدنى سحب $'+w.min+'</div>'+
     (url?'<a href="'+url+'" target="_blank" rel="noopener" style="display:inline-block;margin-top:8px;background:#4dd0e1;color:#04121a;border-radius:9px;padding:8px 14px;font-weight:800;text-decoration:none">افتح الاستطلاعات</a>':'<span class="l"> — ضع الرابط في offerwalls.json</span>')+
     '<div class="l" style="opacity:.7;margin-top:6px">معرّفك للإحالة: <code>'+uid()+'</code></div></div>'
   }).join('')||'<p class="l">لا بوابات مُعدّة</p>';
  }).catch(function(){});
 }
 document.readyState==='loading'?addEventListener('DOMContentLoaded',render):render();
})();
