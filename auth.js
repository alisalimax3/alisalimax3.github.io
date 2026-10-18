/* CineHub 3099 · الهوية + التحقق من أكواد الاشتراك + بوابة الأدمن */
(function(){
  var SECRET='d9b0eadc92da110c43560aa787e16716', ADMIN_SHA='afe4751a95683214ccb8994154ab4f29b50c322785d5778f141a86bbf1155fbd', enc=new TextEncoder();
  function hex(b){ return [].map.call(new Uint8Array(b),function(x){return('0'+x.toString(16)).slice(-2)}).join(''); }
  async function hmac(p){
    var k=await crypto.subtle.importKey('raw',enc.encode(SECRET),{name:'HMAC',hash:'SHA-256'},false,['sign']);
    return hex(await crypto.subtle.sign('HMAC',k,enc.encode(p))).slice(0,6).toUpperCase();
  }
  async function sha(t){ return hex(await crypto.subtle.digest('SHA-256',enc.encode(t))); }
  function uid(){ var u=localStorage.getItem('ch_uid'); if(!u){u='U'+Math.random().toString(36).slice(2,9)+Date.now().toString(36).slice(-4);localStorage.setItem('ch_uid',u);} return u; }
  async function verify(code){
    code=String(code||'').toUpperCase().replace(/[^A-Z0-9]/g,'');
    var m=code.match(/^([PM])(\d{5})([0-9A-F]{6})$/);
    if(!m) return {ok:false,why:'الصيغة غير صحيحة'};
    if(await hmac(m[1]+m[2])!==m[3]) return {ok:false,why:'التوقيع غير صحيح'};
    var exp=new Date(Date.UTC(2026,0,1)+(+m[2])*864e5);
    if(Date.now()>exp.getTime()) return {ok:false,why:'منتهي في '+exp.toISOString().slice(0,10)};
    return {ok:true,plan:m[1]==='M'?'max':'pro',exp:exp};
  }
  function plan(){ try{ return JSON.parse(localStorage.getItem('ch_plan')||'null'); }catch(e){ return null; } }
  function apply(r){
    var v=r.ok?{plan:r.plan,exp:r.exp.toISOString().slice(0,10)}:null;
    localStorage.setItem('ch_plan',JSON.stringify(v));
    document.dispatchEvent(new CustomEvent('ch:plan',{detail:v})); return v;
  }
  async function admin(pw){ if(await sha(String(pw||''))===ADMIN_SHA){ sessionStorage.setItem('ch_admin','1'); return true; } return false; }
  window.CH={ uid:uid(), verify:verify, apply:apply, plan:plan, hmac:hmac, sha:sha, admin:admin,
    isAdmin:function(){ return sessionStorage.getItem('ch_admin')==='1'; },
    logout:function(){ sessionStorage.removeItem('ch_admin'); } };
  document.dispatchEvent(new Event('ch:ready'));
})();
