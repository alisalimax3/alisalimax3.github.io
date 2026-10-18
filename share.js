(function(){
  function ref(){ try{ return '?ref='+CH.uid(); }catch(e){ return ''; } }
  function data(){
    var t=document.title, u=location.origin+location.pathname;
    return { t:t, u:u+(u.indexOf('?')>-1?'&':'?')+'ref='+(window.CH?CH.uid():'') };
  }
  function wa(){ var d=data(); open('https://wa.me/?text='+encodeURIComponent(d.t+' — '+d.u),'_blank'); }
  function tg(){ var d=data(); open('https://t.me/share/url?url='+encodeURIComponent(d.u)+'&text='+encodeURIComponent(d.t),'_blank'); }
  function cp(){ var d=data(); navigator.clipboard&&navigator.clipboard.writeText(d.u); return d.u; }
  function bar(){
    if(document.getElementById('chshare')) return;
    var w=document.createElement('div'); w.id='chshare';
    w.style.cssText='display:flex;gap:6px;flex-wrap:wrap;margin:12px 0';
    var b='background:#1b2740;border:1px solid #1e2a44;color:#e8f6ff;padding:7px 12px;border-radius:8px;font:12px system-ui;cursor:pointer';
    w.innerHTML='<button style="'+b+'" onclick="CHShare.wa()">واتساب</button>'
      +'<button style="'+b+'" onclick="CHShare.tg()">تليجرام</button>'
      +'<button style="'+b+'" onclick="CHShare.cp()">نسخ الرابط</button>'
      +'<button style="'+b+'" onclick="CHShare.fav()">★ مفضلة</button>';
    var g=document.querySelector('.wrap')||document.body; g.appendChild(w);
  }
  function fav(){
    var f=[]; try{ f=JSON.parse(localStorage.getItem('ch_fav')||'[]'); }catch(e){}
    var u=location.pathname;
    if(f.some(function(x){return x.u===u})){ f=f.filter(function(x){return x.u!==u}); }
    else f.unshift({u:u,n:document.title.split('·')[0].trim(),t:(document.querySelector('meta[property="og:image"]')||{}).content||''});
    localStorage.setItem('ch_fav',JSON.stringify(f.slice(0,120)));
  }
  window.CHShare={ wa:wa, tg:tg, cp:cp, fav:fav };
  document.readyState==='loading'?addEventListener('DOMContentLoaded',bar):bar();
})();
