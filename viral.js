(function(){
  var K='ch_viral', INVITE_TARGET=3, UNLOCK_DAYS=7;
  function read(){ try{ return JSON.parse(localStorage.getItem(K)||'null')||{streak:0,last:'',pts:0,unlocks:0}; }catch(e){ return {streak:0,last:'',pts:0,unlocks:0}; } }
  function write(o){ localStorage.setItem(K,JSON.stringify(o)); document.dispatchEvent(new Event('ch:viral')); }
  function d(off){ return new Date(Date.now()-(off||0)*864e5).toISOString().slice(0,10); }
  function claim(){
    var o=read(), t=d(0);
    if(o.last===t) return {ok:false,why:'استلمت اليوم — عد غداً'};
    o.streak = (o.last===d(1)) ? o.streak+1 : 1;
    o.last=t;
    var b = 0.0015 * (1 + Math.min(o.streak,10)*0.3);
    o.pts += b; write(o);
    if(window.CHLedger) CHLedger.bonus(b,'streak');
    return {ok:true, streak:o.streak, bonus:b};
  }
  function invites(){
    var c=0; try{ for(var k in localStorage) if(k.indexOf('ch_refcount_')===0) c+=+localStorage[k]||0; }catch(e){}
    return c;
  }
  function unlockCheck(){
    var o=read(), n=invites();
    if(n>=INVITE_TARGET && !o.unlocks){
      o.unlocks=1; write(o);
      try{ var p={plan:'pro',exp:new Date(Date.now()+UNLOCK_DAYS*864e5).toISOString().slice(0,10)}; localStorage.setItem('ch_plan',JSON.stringify(p)); }catch(e){}
      return true;
    }
    return false;
  }
  window.CHViral={ read:read, claim:claim, invites:invites, unlockCheck:unlockCheck,
    target:INVITE_TARGET, days:UNLOCK_DAYS, done:function(){ return read().last===d(0); },
    points:function(){ return read().pts; } };
  setInterval(unlockCheck,5000); unlockCheck();
})();
