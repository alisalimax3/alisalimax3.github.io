
(function(){
 function q(s){return document.querySelector(s)},N=function(v){return isFinite(+v)?+v:0};
 function paint(){ if(q("#bal"))q("#bal").textContent='$'+(window.CHLedger?CHLedger.balance():0).toFixed(4); }
 paint();setInterval(paint,2000);
 function fill(id,txt){var e=q(id);if(e&&(!e.textContent||e.textContent==='…'||e.textContent==='… يُقرأ'))e.textContent=txt}
 setTimeout(function(){
  fill("#status","… تعذّر قراءة الحالة"); fill("#films","… تعذّر قراءة الأفلام");
  fill("#stamp",new Date().toISOString().slice(0,10));
 },3500);
 Promise.all([
  fetch('/revenue.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/heartbeat.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/ledger-index.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/networks.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/ads-config.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/data/archive.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/kuraimi.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}}),
  fetch('/owner.json?t='+Date.now()).then(function(r){return r.json()}).catch(function(){return{}})
 ]).then(function(a){
  var rev=a[0]||{},hb=a[1]||{},li=a[2]||{},net=a[3]||{},cfg=a[4]||{},ar=a[5]||{},ku=a[6]||{},own=a[7]||{};
  q("#h-rev").textContent='$'+Number(rev.revenue||0).toFixed(6);
  q("#h-hb").textContent=hb.t?hb.t.slice(5,16)+'Z':'بانتظار النبضة';
  q("#h-led").textContent=li.entries||0;
  q("#rev").textContent='$'+Number(rev.revenue||0).toFixed(6);
  q("#imp").textContent=Number(rev.impressions||0).toLocaleString('en');
  q("#clk").textContent=Number(rev.clicks||0).toLocaleString('en');
  var B=cfg.banners||{},keys=0;Object.keys(B).forEach(function(x){if(B[x]&&B[x].key)keys++});
  var mk=(net.networks||[]).filter(function(x){return Object.keys(x.keys||{}).some(function(y){return x.keys[y]})});
  var rows=[["حالة المحرّك",cfg.enabled?"ok":"w",cfg.enabled?"مُفعّل":"موقوف"],
   ["خانات مربوطة",keys?"ok":"w",keys?keys+" خانة — ظهور حقيقي":"لا مفاتيح ⇒ $0.00 حقيقةً"],
   ["شبكات لها مفاتيح",mk.length?"ok":"w",mk.length?mk.map(function(x){return x.name}).join(" · "):"سجّل في Adsterra واملأ keys.env"],
   ["سلسلة السجل",li.broken?"b":"ok",li.broken?li.broken+" مكسور":"سليمة ✓"],
   ["هوية الكابتشا",window.CHAuth&&CHAuth.valid()?"ok":"w",window.CHAuth&&CHAuth.valid()?CHAuth.token().id:"غير مُفعّلة — /gate.html"]];
  q("#status").innerHTML=rows.map(function(x){return '<div class="bn"><span class="pill '+x[1]+'">'+x[2]+'</span><b>'+x[0]+'</b></div>'}).join("");
  var films=[];Object.keys(ar.cols||{}).forEach(function(k){(ar.cols[k]||[]).slice(0,4).forEach(function(f){films.push(f)})});
  films=films.slice(0,8);
  q("#films").innerHTML=films.map(function(f){
   return '<a class="card" href="/cinema.html#'+f.id+'"><b>'+String(f.t).slice(0,44)+'</b><p>'+(f.y||'')+' · '+(f.dl||0).toLocaleString('en')+' تحميل</p></a>'}).join("")||'<div class="card">…</div>';
  q("#nets").innerHTML=(net.networks||[]).filter(function(x){return x.enabled||Object.keys(x.keys||{}).some(function(y){return x.keys[y]})}).slice(0,12).map(function(x){
   var has=Object.keys(x.keys||{}).some(function(y){return x.keys[y]});
   return '<tr><td><b>'+x.name+'</b></td><td><span class="pill '+(has?'ok':'w')+'">'+(has?'مربوط':'—')+'</span></td><td>$'+(x.min_payout||0)+'</td><td>'+((x.methods||[]).join(' · ')||'—')+'</td></tr>'}).join("")||'<tr><td colspan=4>لا شبكات مُفعّلة بعد</td></tr>';
  q("#kuraimi").innerHTML=own.kuraimi_name?('يُحوَّل إلى: <b>'+own.kuraimi_name+'</b> — '+(own.kuraimi_account||'')+' — '+(own.kuraimi_phone||'')):'<span class="w">⚠ لم تُضبط بيانات الكريمي — املأ keys.env</span>';
  q("#stamp").textContent=new Date().toISOString().slice(0,10);
 });
})();
