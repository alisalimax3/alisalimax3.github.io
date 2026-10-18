(function(){
  if(!('serviceWorker' in navigator)) return;
  addEventListener('load',function(){ navigator.serviceWorker.register('/sw.js').catch(function(){}); });
  var dp=null;
  addEventListener('beforeinstallprompt',function(e){ e.preventDefault(); dp=e; show(); });
  function show(){ if(document.getElementById('chinst')) return;
    var b=document.createElement('div'); b.id='chinst';
    b.style.cssText='position:fixed;bottom:64px;left:12px;right:12px;z-index:9996;background:#111827;border:1px solid #1e2a44;border-radius:12px;padding:10px;display:flex;gap:8px;align-items:center;font:12px system-ui';
    b.innerHTML='<span style="flex:1;color:#8aa0c0">ثبّت التطبيق على شاشتك — أسرع وأوفر</span><button id="chi" style="background:#4dd0e1;color:#04121a;border:0;border-radius:8px;padding:7px 12px;font-weight:800">تثبيت</button>';
    document.body.appendChild(b);
    document.getElementById('chi').onclick=function(){ if(dp){ dp.prompt(); dp=null; } b.remove(); };
  }
  setTimeout(show,6000);
})();
