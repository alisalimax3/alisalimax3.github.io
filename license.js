(function(){
 var SALT='cinehub3099-lic-v1';
 function enc(s){return btoa(unescape(encodeURIComponent(s))).replace(/=+$/,'')}
 function key(plan,exp,ref){return enc(plan+'|'+exp+'|'+ref+'|'+SALT).slice(0,26).toUpperCase()}
 window.CHLic={
  read:function(){try{return JSON.parse(localStorage.getItem('ch_lic')||'null')}catch(e){return null}},
  active:function(){var l=this.read();return !!(l&&l.exp>Date.now())},
  issue:function(plan,ref,days){
   var exp=Date.now()+(days||30)*86400000,o={plan:plan,ref:ref,exp:exp,key:key(plan,exp,ref),at:new Date().toISOString()};
   localStorage.setItem('ch_lic',JSON.stringify(o));document.dispatchEvent(new CustomEvent('ch:license',{detail:o}));return o},
  revoke:function(){localStorage.removeItem('ch_lic')},
  verify:function(o){return o&&o.key===key(o.plan,o.exp,o.ref)&&o.exp>Date.now()}
 };
 document.addEventListener('DOMContentLoaded',function(){
  if(window.CHLic.active())document.documentElement.setAttribute('data-lic','active');
 });
})();
