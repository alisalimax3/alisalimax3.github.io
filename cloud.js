/* حسابات ومزامنة حقيقية · Supabase (auth+db) مع احتياطي محلي */
(function(){
 var SB=null,CFG={},USER=null;
 function rd(p){try{return JSON.parse(localStorage.getItem(p)||'null')}catch(e){return null}}
 function wr(p,o){localStorage.setItem(p,JSON.stringify(o))}
 async function init(){
  try{CFG=await (await fetch('/cloud-config.json?t='+Date.now())).json()}catch(e){CFG={}}
  if(!CFG.supabase_url||!CFG.supabase_anon){document.documentElement.setAttribute('data-cloud','off');return}
  try{
   var m=await import('https://esm.sh/@supabase/supabase-js@2');
   SB=m.createClient(CFG.supabase_url,CFG.supabase_anon,{auth:{persistSession:true,autoRefreshToken:true}});
   var s=await SB.auth.getSession(); USER=s.data.session?s.data.session.user:null;
   SB.auth.onAuthStateChange(function(_,ss){USER=ss&&ss.session?ss.session.user:null;document.dispatchEvent(new Event('ch:auth'))});
   document.documentElement.setAttribute('data-cloud','on');
   if(USER){await touch();await pull()}
  }catch(e){document.documentElement.setAttribute('data-cloud','err')}
 }
 function localUid(){var u=rd('ch_uid');if(!u){u='L-'+Math.random().toString(36).slice(2,10);wr('ch_uid',u)}return u}
 async function touch(){
  if(!SB||!USER)return;
  try{await SB.from('profiles').upsert({id:USER.id,email:USER.email,name:(rd('ch_name')||''),phone:(rd('ch_phone')||''),ref_code:(rd('ch_ref')||'')},{onConflict:'id'})}catch(e){}
 }
 async function signUp(email,pass,name,phone,ref){
  wr('ch_name',name||'');wr('ch_phone',phone||'');
  if(!SB)return{ok:false,why:'لا سحابة مُعدّة — حساب محلي فقط',local:true};
  var r=await SB.auth.signUp({email:email,password:pass,options:{data:{name:name,phone:phone,ref:ref||''}}});
  if(r.error)return{ok:false,why:r.error.message};
  USER=r.data.user;await touch();return{ok:true,user:USER};
 }
 async function signIn(email,pass){
  if(!SB)return{ok:false,why:'لا سحابة'};
  var r=await SB.auth.signInWithPassword({email:email,password:pass});
  if(r.error)return{ok:false,why:r.error.message};
  USER=r.data.user;await pull();return{ok:true,user:USER};
 }
 async function signOut(){if(SB)await SB.auth.signOut();USER=null;document.dispatchEvent(new Event('ch:auth'))}
 async function push(kind,amount,src,meta){
  if(!SB||!USER)return;
  try{await SB.from(CFG.tables.ledger).insert({uid:USER.id,kind:kind,amount:amount,src:src||'',meta:meta||{}})}catch(e){}
 }
 async function pull(){
  if(!SB||!USER)return;
  try{var r=await SB.from(CFG.tables.ledger).select('amount,kind').eq('uid',USER.id).limit(5000);
   var s=0;(r.data||[]).forEach(function(x){s+=Number(x.amount)||0});wr('ch_cloud_bal',s);document.dispatchEvent(new Event('ch:cloud'))}catch(e){}
 }
 async function withdraw(req){
  if(!SB||!USER){var a=JSON.parse(localStorage.getItem('ch_payouts')||'[]');a.unshift(req);localStorage.setItem('ch_payouts',JSON.stringify(a));return{ok:true,local:true}}
  var r=await SB.from(CFG.tables.withdrawals).insert({uid:USER.id,ref:req.ref,amount:req.amount,method:req.method,name:req.name,account:req.account,phone:req.phone});
  return r.error?{ok:false,why:r.error.message}:{ok:true};
 }
 async function listWithdrawals(){
  if(!SB||!USER)return JSON.parse(localStorage.getItem('ch_payouts')||'[]');
  var r=await SB.from(CFG.tables.withdrawals).select('*').eq('uid',USER.id).order('at',{ascending:false}).limit(50);
  return r.data||[];
 }
 async function redeem(code){
  if(!SB||!USER){return{ok:true,local:true}}
  var r=await SB.rpc('redeem_code',{p_code:code});return r.error?{ok:false,why:r.error.message}:{ok:true,data:r.data};
 }
 window.CHCloud={init:init,uid:function(){return USER?USER.id:localUid()},user:function(){return USER},cloud:function(){return !!SB},
  signUp:signUp,signIn:signIn,signOut:signOut,push:push,pull:pull,withdraw:withdraw,list:listWithdrawals,redeem:redeem,
  balance:function(){return Number(localStorage.getItem('ch_cloud_bal')||0)}};
 document.addEventListener('DOMContentLoaded',init);
})();
