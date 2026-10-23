/* ربط هوية GitHub كبوابة عبور: تحقق حقيقي من وجود الحساب عبر API العام */
(function(){
 function get(){try{return JSON.parse(localStorage.getItem('ch_gh')||'null')}catch(e){return null}}
 async function link(user){
  user=String(user||'').trim().replace('@','');
  if(!/^[A-Za-z0-9-]{1,39}$/.test(user))return{ok:false,why:'اسم غير صالح'};
  try{
   var r=await fetch('https://api.github.com/users/'+user);
   if(!r.ok)return{ok:false,why:'الحساب غير موجود'};
   var j=await r.json();
   var o={login:j.login,id:j.id,name:j.name,avatar:j.avatar_url,repos:j.public_repos,
    email:(j.id+'+'+j.login+'@users.noreply.github.com'),at:Date.now(),verified:true};
   localStorage.setItem('ch_gh',JSON.stringify(o));
   if(window.CHCloud)CHCloud.push('link',0,'github',{login:o.login,id:o.id});
   document.dispatchEvent(new CustomEvent('ch:gh',{detail:o}));
   return{ok:true,gh:o};
  }catch(e){return{ok:false,why:'تعذّر الاتصال بـGitHub'}}
 }
 function unlink(){localStorage.removeItem('ch_gh');document.dispatchEvent(new Event('ch:gh'))}
 window.CHGH={get:get,link:link,unlink:unlink,
  gate:function(){return 'https://github.com/alkazmybwhwr-dot/alisalimax3.github.io'}};
})();
