/* كابتشا متعددة المزوّدين + تحقق سيرفري + احتياطي محلي */
(function(){
 var P='turnstile',tok='',mounted=false;
 function cfg(cb){fetch('/owner.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()})
  .then(function(o){P=(o.captcha&&o.captcha.provider)||'turnstile';window.__own=o;cb()}).catch(cb)}
 function math(){
  var a=2+Math.floor(Math.random()*8),b=2+Math.floor(Math.random()*8),op=Math.random()<0.5?'+':'×';
  var ans=op==='+'?a+b:a*b;
  var d=document.getElementById('ch-math');if(!d)return;
  d.innerHTML='<span>أثبت أنك بشر: '+a+' '+op+' '+b+' = </span><input id="ch-mathv" style="width:70px;display:inline-block"> <button id="ch-mathgo" style="padding:4px 10px">تأكيد</button>';
  document.getElementById('ch-mathgo').onclick=function(){
   if(+document.getElementById('ch-mathv').value===ans){tok='math-'+Date.now();d.innerHTML='<span style="color:#22c55e">✓ مُصدَّق</span>';document.dispatchEvent(new Event('ch:captcha'))}
   else{d.innerHTML+='<b style="color:#f87171"> ✗</b>';math()}};
 }
 function mount(sel){
  var el=typeof sel==='string'?document.querySelector(sel):sel; if(!el)return;
  if(mounted){return} mounted=true;
  var c=(window.__own&&window.__own.captcha)||{};
  if(P==='turnstile'&&c.turnstile_site){
   var d=document.createElement('div');d.className='cf-turnstile';d.setAttribute('data-sitekey',c.turnstile_site);
   d.setAttribute('data-callback','__chCap');d.setAttribute('data-theme','dark');el.appendChild(d);
   window.__chCap=function(t){tok=t;document.dispatchEvent(new Event('ch:captcha'))};
   if(!document.querySelector('script[data-cf]')){var s=document.createElement('script');s.setAttribute('data-cf','1');s.async=1;
    s.src='https://challenges.cloudflare.com/turnstile/v0/api.js?onload=__chCapLoad';document.head.appendChild(s)}
   window.__chCapLoad=function(){try{turnstile.render(el.querySelector('.cf-turnstile'))}catch(e){}};
  } else if(P==='hcaptcha'&&c.hcaptcha_site){
   el.innerHTML='<div class="h-captcha" data-sitekey="'+c.hcaptcha_site+'" data-callback="__chCap"></div>';
   window.__chCap=function(t){tok=t;document.dispatchEvent(new Event('ch:captcha'))};
   var s2=document.createElement('script');s2.async=1;s2.src='https://js.hcaptcha.com/1/api.js';document.head.appendChild(s2);
  } else if(P==='recaptcha'&&c.recaptcha_site){
   el.innerHTML='<div class="g-recaptcha" data-sitekey="'+c.recaptcha_site+'" data-callback="__chCap"></div>';
   window.__chCap=function(t){tok=t;document.dispatchEvent(new Event('ch:captcha'))};
   var s3=document.createElement('script');s3.async=1;s3.src='https://www.google.com/recaptcha/api.js';document.head.appendChild(s3);
  } else { el.innerHTML='<div id="ch-math"></div>'; math(); }
 }
 function verify(){
  var o=window.__own||{};
  if(!o.endpoint||o.endpoint.indexOf('script.google')<0||!tok) return Promise.resolve({ok:!!tok,local:true});
  return fetch(o.endpoint,{method:'POST',headers:{'Content-Type':'text/plain'},
   body:JSON.stringify({type:'verify',token:tok,provider:P})}).then(function(r){return r.json()}).catch(function(){return{ok:true,local:true}});
 }
 window.CHCaptcha={mount:mount,token:function(){return tok},reset:function(){tok='';mounted=false},ready:function(){return !!tok},verify:verify,provider:function(){return P}};
 document.addEventListener('DOMContentLoaded',function(){cfg(function(){});});
})();
