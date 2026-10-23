/* تفعيل مباشر: اربط GitHub ← املأ من الروابط المباشرة ← كابتشا ← احفظ في مستودعك فورًا */
(function(){
 var O='alkazmybwhwr-dot', R='alisalimax3.github.io', BR='main';
 function LSK(){return 'ch_gh_tok'}
 function tok(){return localStorage.getItem(LSK())||''}
 function h(){return tok()?{'Authorization':'token '+tok(),'Accept':'application/vnd.github+json'}:{'Accept':'application/vnd.github+json'}}
 function b64(s){return btoa(unescape(encodeURIComponent(s)))}
 async function ghGet(p){var r=await fetch('https://api.github.com/repos/'+O+'/'+R+'/contents/'+p+'?ref='+BR,{headers:h()});return r.status===200?r.json():null}
 async function ghPut(p,txt,msg){
  var cur=await ghGet(p);
  var body={message:msg||('setup '+new Date().toISOString()),content:b64(txt),branch:BR};
  if(cur&&cur.sha)body.sha=cur.sha;
  var r=await fetch('https://api.github.com/repos/'+O+'/'+R+'/contents/'+p,{method:'PUT',headers:Object.assign({'Content-Type':'application/json'},h()),body:JSON.stringify(body)});
  if(!r.ok){var e=await r.json().catch(function(){return{}});throw new Error((e.message||r.status)+'')}
  return r.json();
 }
 function link(token){return 'https://api.github.com/repos/'+O+'/'+R+'/dispatches'}
 async function dispatch(payload){
  var r=await fetch(link(),{method:'POST',headers:Object.assign({'Content-Type':'application/json'},h()),
   body:JSON.stringify({event_type:'setup',client_payload:payload||{}})});
  return r.status===204||r.ok;
 }
 function readKV(txt){var o={};String(txt||'').split('\n').forEach(function(l){l=l.trim();if(l&&l[0]!=='#'&&l.indexOf('=')>0){var i=l.indexOf('=');o[l.slice(0,i).trim()]=l.slice(i+1).trim()}});return o}
 function writeKV(o,order){
  var keys=order.slice();Object.keys(o).forEach(function(k){if(keys.indexOf(k)<0)keys.push(k)});
  return '# CineHub 3099 — كُتب من /setup.html\n'+keys.map(function(k){return k+'='+(o[k]||'')}).join('\n')+'\n';
 }
 window.CHSetup={tok:tok,
  connect:async function(t){
   var r=await fetch('https://api.github.com/user',{headers:{'Authorization':'token '+t,'Accept':'application/vnd.github+json'}});
   if(!r.ok)throw new Error('توكن غير صحيح');
   var j=await r.json(),sc=r.headers.get('x-oauth-scopes')||'';
   var miss=['repo','workflow'].filter(function(x){return sc.indexOf(x)<0});
   localStorage.setItem(LSK(),t);
   return {login:j.login,scopes:sc,missing:miss};
  },
  load:async function(p){var c=await ghGet(p);return c?{sha:c.sha,txt:decodeURIComponent(escape(atob(c.content.replace(/\n/g,''))))}:null},
  save:async function(p,txt,msg){return ghPut(p,txt,msg)},
  run:dispatch,readKV:readKV,writeKV:writeKV,
  poll:async function(){var r=await fetch('/setup-status.json?t='+Date.now());return r.ok?r.json():null},
  ORDER:['ADSTERRA_API_KEY','ADSTERRA_PUB_ID','ADSTERRA_BANNER_TOP','ADSTERRA_BANNER_MID','ADSTERRA_BANNER_SIDE','ADSTERRA_BANNER_MOBILE','ADSTERRA_POPUNDER','ADSTERRA_SOCIALBAR','ADSTERRA_INPAGE','MONETAG_API_KEY','MONETAG_MULTITAG','MONETAG_REWARDED_ZONE','PROPELLER_API_KEY','POPADS_API_KEY','LINKVERTISE_UID','WORKINK_UID','SHRINKME_UID','SHRINKERN_UID','CLKSH_UID','GPLINKS_UID','CPAGRIP_SMARTLINK','OGADS_SMARTLINK','ADSENSE_CLIENT','TURNSTILE_SITE','TURNSTILE_SECRET','SUPABASE_URL','SUPABASE_ANON','APPS_SCRIPT_URL','OWNER_WHATSAPP','OWNER_TELEGRAM','OWNER_EMAIL','KURAIMI_NAME','KURAIMI_ACCOUNT','KURAIMI_PHONE','USDT_TRC20']
 };
})();
