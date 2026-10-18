/* عدّاد عالمي حقيقي عبر 3 مزوّدين بلا تسجيل، مع احتياطي محلي */
(function(){
 var NS='cinehub3099', sent={};
 function hit(key){
  if(sent[key])return; sent[key]=1;
  fetch('https://abacus.jasoncameron.dev/hit/'+NS+'/'+key,{mode:'cors'}).catch(function(){
   fetch('https://api.counterapi.dev/v1/'+NS+'/'+key+'/up',{mode:'cors'}).catch(function(){});
  });
 }
 function get(key,cb){
  fetch('https://abacus.jasoncameron.dev/get/'+NS+'/'+key).then(function(r){return r.json()})
   .then(function(j){cb(j.value)}).catch(function(){cb(null)});
 }
 document.addEventListener('DOMContentLoaded',function(){
  hit('views');
  if(window.CHAuth&&!localStorage.getItem('ch_bv')){localStorage.setItem('ch_bv','1');hit('uniques')}
  document.addEventListener('ch:outclick',function(){hit('outclicks')});
  document.addEventListener('ch:rewarded',function(){hit('rewarded')});
  document.addEventListener('ch:impression',function(){if(!localStorage.getItem('ch_bi')){localStorage.setItem('ch_bi','1');hit('imp_sessions')}});
  var t=setInterval(function(){ if(window.CHCloud&&CHCloud.cloud()){clearInterval(t);return}
   get('views',function(v){ if(v==null)return; clearInterval(t);
    document.querySelectorAll('[data-gviews]').forEach(function(e){e.textContent=Number(v).toLocaleString('en')})})},6000);
 });
 window.CHBeacon={hit:hit,get:get};
})();
