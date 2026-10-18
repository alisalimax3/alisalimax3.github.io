(function(){
  var RPM=1.20, SHARE=0.70;
  function key(){ return 'ch_ledger_'+(window.CH?CH.uid():'anon'); }
  function read(){ try{ return JSON.parse(localStorage.getItem(key())||'null')||{imp:0,days:{},paid:0,bonus:0,src:{}}; }catch(e){ return {imp:0,days:{},paid:0,bonus:0,src:{}}; } }
  function write(o){ localStorage.setItem(key(),JSON.stringify(o)); }
  function add(n){ var o=read(),d=new Date().toISOString().slice(0,10); o.imp+=n; o.days[d]=(o.days[d]||0)+n; write(o); document.dispatchEvent(new Event('ch:ledger')); }
  function bonus(a,src){ var o=read(); o.bonus=(o.bonus||0)+a; o.src=o.src||{}; o.src[src||'misc']=(o.src[src||'misc']||0)+a; write(o); document.dispatchEvent(new Event('ch:ledger')); }
  function gross(o){ return o.imp/1000*RPM; }
  function net(o){ return gross(o)*SHARE+(o.bonus||0); }
  function bal(){ var o=read(); return Math.max(0,net(o)-(o.paid||0)); }
  window.CHLedger={ read:read, write:write, add:add, bonus:bonus, gross:gross, net:net, balance:bal, RPM:RPM, SHARE:SHARE,
    pay:function(a){ var o=read(); o.paid=(o.paid||0)+a; write(o); } };
  document.addEventListener('ch:impression',function(e){ add(e.detail||1); });
  document.addEventListener('ch:ledger',function(){ if(window.CHRef){ var o=read(); if(o.lastCredit!==net(o)){ o.lastCredit=net(o); } } });
})();
