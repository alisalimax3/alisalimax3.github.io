(function(){
  var items=[['/','الرئيسية'],['/movies.html','أفلام'],['/cats.html','تصنيفات'],['/adult.html','للكبار'],['/rewards.html','مكافآت'],['/earn.html','اربح'],['/wallet.html','محفظتي']];
  function go(){
    if(document.getElementById('chnav')) return;
    var p=location.pathname, w=document.createElement('div'); w.id='chnav';
    w.style.cssText='position:fixed;bottom:0;left:0;right:0;z-index:9998;background:#0b1020f2;border-top:1px solid #1e2a44;display:flex;overflow-x:auto';
    w.innerHTML=items.map(function(i){var a=p===i[0]||(i[0]!=='/'&&p.indexOf(i[0])===0);
      return '<a href="'+i[0]+'" style="flex:1;min-width:66px;text-align:center;padding:11px 5px;font:12px system-ui;text-decoration:none;color:'+(a?'#4dd0e1':'#8aa0c0')+'">'+i[1]+'</a>'}).join('');
    document.body.appendChild(w); document.body.style.paddingBottom='66px';
  }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
})();
