/* قفل محتوى — نقرة إعلان تفتح المشاهدة 24 ساعة (دخل CPA مباشر) */
(function(){
  var H='ch_unlock';
  function ok(){ var t=+localStorage.getItem(H)||0; return Date.now()<t; }
  function open24(){ localStorage.setItem(H,Date.now()+864e5); }
  function wrap(){
    if(ok()) return;
    if(!window.CHRev) return;
    CHRev.ready(function(c){
      if(!c.smartlink) return;
      var el=document.createElement('div');
      el.style.cssText='background:#111827;border:1px solid #1e2a44;border-radius:14px;padding:16px;margin:14px 0;text-align:center';
      el.innerHTML='<b>افتح المشاهدة المجانية</b><p style="color:#8aa0c0;font-size:12px;margin:6px 0">نقرة واحدة تفتح كل الأفلام 24 ساعة</p>'
        +'<button id="chul" style="background:#4dd0e1;color:#04121a;border:0;border-radius:9px;padding:11px 18px;font-weight:800;cursor:pointer">افتح الآن</button>';
      var g=document.querySelector('.wrap')||document.body; g.insertBefore(el,g.firstChild.nextSibling||g.firstChild);
      document.getElementById('chul').onclick=function(){
        window.open(c.smartlink,'_blank','noopener'); open24();
        el.innerHTML='<b style="color:#22c55e">✓ مُفتح — استمتع</b>';
      };
    });
  }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',wrap):wrap();
})();
