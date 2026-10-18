/* طبقة المالك: تُخفي أدوات الإدارة عن الزوّار، وتفتحها لك بـ ?o=1 أو 5 نقرات على الشعار */
(function(){
 var OWN=['setup.html','accounts.html','apply.html','treasury.html','audit.html','gateway.html','live-dash.html','admin2.html','plan.html','owner.html','credit.html','img.html'];
 function isOwner(){return localStorage.getItem('ch_owner')==='1'}
 function mark(){
  document.querySelectorAll('nav a, .foot a, a').forEach(function(a){
   var h=a.getAttribute('href')||'';
   if(OWN.some(function(x){return h.indexOf(x)>-1})) a.classList.add('owner-only');
  });
  document.documentElement.setAttribute('data-owner',isOwner()?'1':'0');
  var n=document.querySelector('nav');
  if(n&&isOwner()&&!n.querySelector('[data-ownerbtn]')){
   var b=document.createElement('a');b.setAttribute('data-ownerbtn','1');b.href='/owner.html';b.textContent='⚙ المالك';
   b.style.borderColor='#22c55e';n.appendChild(b);
  }
 }
 function gate(){
  if(isOwner())return;
  fetch('/owner.json?t='+Date.now()).then(function(r){return r.json()}).then(function(o){
   var p=prompt('رمز المالك:');
   if(p===(o.admin_pin||'3099')){localStorage.setItem('ch_owner','1');mark();document.dispatchEvent(new Event('ch:owner'));
    if(confirm('دخول لوحة المالك الآن؟'))location.href='/owner.html'}
   else if(p!==null)alert('رمز خاطئ');
  });
 }
 function taps(){
  var logo=document.querySelector('.logo')||document.querySelector('h1'),n=0,t=0;
  if(!logo)return;
  logo.style.cursor='pointer';
  logo.addEventListener('click',function(){
   var now=Date.now(); n=(now-t<900)?n+1:1; t=now;
   if(n>=5){n=0;isOwner()?(localStorage.removeItem('ch_owner'),mark()):gate()}
  });
 }
 document.addEventListener('DOMContentLoaded',function(){
  mark(); taps();
  if(/[?&]o=1/.test(location.search)||location.hash==='#owner')gate();
  if(/[?&]setup=1/.test(location.search)&&location.pathname.indexOf('setup')<0){ if(!isOwner())gate(); else location.href='/setup.html' }
  var s=document.createElement('style');
  s.textContent='.owner-only{display:none!important}html[data-owner="1"] .owner-only{display:inline-block!important}';
  document.head.appendChild(s);
 });
 window.CHOwner={is:isOwner,on:function(){localStorage.setItem('ch_owner','1');mark()},off:function(){localStorage.removeItem('ch_owner');mark()}};
})();
