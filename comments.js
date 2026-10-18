/* تعليقات: Supabase إن مُهيّأ، وإلا محلي. + مكافأة صغيرة لكل تعليق */
(function(){
 function key(){return 'ch_cm_'+(location.pathname+location.hash).replace(/[^a-z0-9]/gi,'_').slice(0,60)}
 function read(){try{return JSON.parse(localStorage.getItem(key())||'[]')}catch(e){return[]}}
 function save(a){localStorage.setItem(key(),JSON.stringify(a.slice(-200)))}
 function esc(s){return String(s).replace(/[<>&"]/g,function(c){return{'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;'}[c]})}
 function render(){
  var host=document.getElementById('ch-cm'); if(!host)return;
  var a=read();
  host.innerHTML='<h3 style="font-size:15px">التعليقات ('+a.length+')</h3>'+
   '<div id="ch-cml">'+(a.slice(-40).reverse().map(function(x){
     return '<div style="border-bottom:1px solid #1e2a44;padding:7px 0"><b>'+esc(x.n)+'</b> <span class="l">'+x.t.slice(5,16)+'</span><div>'+esc(x.b)+'</div></div>'}).join('')||'<div class="l">لا تعليقات — كن الأول</div>')+'</div>'+
   '<div style="display:flex;gap:6px;margin-top:8px"><input id="ch-cmn" placeholder="اسمك" style="flex:0 0 110px"><input id="ch-cmb" placeholder="اكتب تعليقًا…" style="flex:1"><button onclick="CHCm.post()">نشر</button></div>'+
   '<div class="l" id="ch-cmm">كل تعليق = +$0.0004 لرصيدك (5 يوميًا)</div>';
 }
 window.CHCm={post:async function(){
  var n=(document.getElementById('ch-cmn').value||'زائر').slice(0,24);
  var b=(document.getElementById('ch-cmb').value||'').trim(); if(b.length<2)return;
  if(window.CHCaptcha&&!CHCaptcha.ready()){CHCaptcha.mount('#ch-cm');return}
  var a=read();a.push({n:n,b:b.slice(0,600),t:new Date().toISOString()});save(a);
  localStorage.setItem('ch_cm_name',n);
  var d=new Date().toISOString().slice(0,10),c=(localStorage.getItem('ch_cm_'+d)||0);
  if(+c<5){localStorage.setItem('ch_cm_'+d,(+c)+1);if(window.CHLedger)CHLedger.bonus(0.0004,'comment')}
  if(window.CHBeacon)CHBeacon.hit('comments');
  if(window.CHCloud&&CHCloud.cloud()){try{await CHCloud.push('comment',0,'page',{b:b.slice(0,200)})}catch(e){}}
  document.getElementById('ch-cmb').value='';render();
  document.getElementById('ch-cmm').innerHTML='<b style="color:#22c55e">✓ نُشر · +$0.0004</b>';
 }};
 document.addEventListener('DOMContentLoaded',function(){
  var w=document.querySelector('.wrap')||document.body;
  var d=document.createElement('div');d.id='ch-cm';d.className='card';w.appendChild(d);
  var nm=localStorage.getItem('ch_cm_name');render();if(nm)setTimeout(function(){var e=document.getElementById('ch-cmn');if(e)e.value=nm},50);
 });
})();
