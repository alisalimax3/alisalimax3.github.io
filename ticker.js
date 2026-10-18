(function(){
  var el;
  function mnt(){ if(el) return; el=document.createElement('div'); el.id='ch-tick';
    el.style.cssText='position:fixed;top:10px;left:10px;z-index:9997;background:#0b1020ee;border:1px solid #1e2a44;color:#9fe8ff;font:11px/1.5 system-ui;padding:6px 10px;border-radius:10px;text-align:right';
    document.body.appendChild(el); }
  function v(){ var i=+(localStorage.getItem('ch_impressions')||0);
    return {i:i, e:(i/1000*1.2*0.7)}; }
  function paint(){ mnt(); var x=v();
    el.innerHTML='ظهور <b>'+x.i+'</b> · أرباحك <b style="color:#7ef0a0">$'+x.e.toFixed(5)+'</b>'; }
  document.addEventListener('ch:impression',paint);
  document.addEventListener('ch:ledger',paint);
  setInterval(paint,1500);
  document.readyState==='loading'?addEventListener('DOMContentLoaded',paint):paint();
})();
