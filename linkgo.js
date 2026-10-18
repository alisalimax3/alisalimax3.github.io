/* محرّك تحويل الروابط الخارجية إلى روابط مدفوعة (waterfall بأعلى CPM) */
(function(){
 var S=null,cap=null;
 function load(cb){fetch('/shorteners.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()})
  .then(function(j){S=j;cb()}).catch(function(){S={enabled:false,shorteners:[]};cb()})}
 function pick(){var a=(S.shorteners||[]).filter(function(x){return x.enabled&&x.uid})
  .sort(function(a,b){return (a.prio||99)-(b.prio||99)});return a[0]||null}
 function blocked(h){var r=S.rule||{};if((r.allow_domains||[]).some(function(d){return h.indexOf(d)>=0}))return false;
  return (r.block_domains||[]).some(function(d){return h.indexOf(d)>-1})}
 function build(sh,u){
  var enc=encodeURIComponent(u),h=0;for(var i=0;i<u.length;i++)h=(h*31+u.charCodeAt(i))%99991;
  return sh.tpl.replace('{url}',enc).replace('{uid}',encodeURIComponent(sh.uid)).replace('{hash}',h)}
 function count(id){var k='ch_clicks';var o={};try{o=JSON.parse(localStorage.getItem(k)||'{}')}catch(e){}
  o[id]=(o[id]||0)+1;o._t=Date.now();localStorage.setItem(k,JSON.stringify(o));
  document.dispatchEvent(new CustomEvent('ch:outclick',{detail:{net:id}}))}
 function toast(t){var d=document.createElement('div');d.textContent=t;
  d.style.cssText='position:fixed;bottom:14px;right:14px;z-index:99999;background:#0b1020;border:1px solid #22c55e;color:#e8f6ff;padding:10px 14px;border-radius:11px;font:13px system-ui';
  document.body.appendChild(d);setTimeout(function(){d.remove()},S.toast_ms||1400)}
 function boot(){
  load(function(){
   if(!S.enabled)return;
   document.addEventListener('click',function(e){
    var a=e.target.closest?e.target.closest('a'):null; if(!a)return;
    var href=a.getAttribute('href')||''; if(!href||href.charAt(0)==='#')return;
    if(a.getAttribute('data-noshort')!==null)return;
    var abs; try{abs=new URL(href,location.href)}catch(x){return}
    if(abs.origin===location.origin&&!/^\/b\//.test(abs.pathname)===false)return;
    var ext=abs.origin!==location.origin;
    if(S.only_external&&!ext)return;
    if(ext&&blocked(abs.hostname))return;
    if(!a.hasAttribute('data-short')){a.setAttribute('data-short','1');return}
    var sh=pick(); if(!sh)return;
    e.preventDefault();count(sh.id);toast('↗ تحويل عبر '+sh.name);
    setTimeout(function(){window.open(build(sh,abs.href),'_blank','noopener')},200);
   },true);
   document.dispatchEvent(new CustomEvent('ch:linkgo',{detail:{active:!!pick()}}));
  })}
 document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
 window.CHLink={active:function(){return !!(S&&S.enabled&&pick())},clicks:function(){try{return JSON.parse(localStorage.getItem('ch_clicks')||'{}')}catch(e){return{}}}};
})();
