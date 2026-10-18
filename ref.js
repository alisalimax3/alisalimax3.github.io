/* مكافآت حقيقية: حضور · إحالة · مهام · عجلة · هدايا · مستويات · بصمة مضادة للغش */
(function(){
 var KEY='ch_rw_v1',LEVELS=[0,50,150,400,900,1800,3500,7000,14000,30000];
 function fp(){
  var s=localStorage.getItem('ch_fp'); if(s)return s;
  var c=document.createElement('canvas').getContext('2d');c.textBaseline='top';c.font='14px Arial';c.fillText('ch3099',2,2);
  var raw=[navigator.userAgent,navigator.language,screen.width+'x'+screen.height,new Date().getTimezoneOffset(),c.canvas.toDataURL().slice(-48)].join('|');
  var h=0;for(var i=0;i<raw.length;i++){h=((h<<5)-h+raw.charCodeAt(i))|0}
  s='F'+Math.abs(h).toString(36);localStorage.setItem('ch_fp',s);return s }
 function st(){try{return JSON.parse(localStorage.getItem(KEY)||'{}')}catch(e){return{}}}
 function sv(o){localStorage.setItem(KEY,JSON.stringify(o))}
 function today(){return new Date().toISOString().slice(0,10)}
 function code(){var u=(window.CHCloud?CHCloud.uid():'anon');return 'CH'+u.replace(/[^A-Za-z0-9]/g,'').slice(0,6).toUpperCase()}
 function level(xp){var l=1;LEVELS.forEach(function(v,i){if(xp>=v)l=i+2});return l}
 function addXP(n){var s=st();s.xp=(s.xp||0)+n;s.level=level(s.xp);sv(s);document.dispatchEvent(new Event('ch:rewards'));return s.level}
 function credit(amount,src){ if(window.CHLedger)CHLedger.bonus(amount,src);
  if(window.CHCloud)CHCloud.push('reward',amount,src,{fp:fp()}) }
 window.CHRewards={
  state:function(){var s=st();s.code=s.code||code();s.level=level(s.xp||0);return s},
  fp:fp,code:code,level:function(){return level(st().xp||0)},
  xp:function(){return st().xp||0},
  nextLevel:function(){var l=level(st().xp||0);return LEVELS[Math.min(l-1,LEVELS.length-1)]},
  checkin:function(){
   if(window.CHAuth&&!CHAuth.valid())return{ok:false,why:'فعّل هويتك من /gate.html'};
   var s=st(),t=today();
   if(s.last===t)return{ok:false,why:'سجّلت حضورك اليوم — عد غدًا',streak:s.streak||1};
   var y=new Date(Date.now()-86400000).toISOString().slice(0,10);
   s.streak=(s.last===y)?(s.streak||1)+1:1; s.last=t; s.days=(s.days||0)+1;
   var base=0.002,val=Math.min(base*s.streak,0.02); s.streak_val=val;
   credit(val,'checkin');addXP(5*s.streak);sv(s);
   return{ok:true,val:val,streak:s.streak,level:level(s.xp||0)};
  },
  task:function(k,val,xp){
   var s=st();s.tasks=s.tasks||{};
   if(s.tasks[k])return{ok:false,why:'مُنجزة مسبقًا'};
   s.tasks[k]=Date.now();sv(s);credit(val||0.001,'task:'+k);addXP(xp||10);
   return{ok:true,val:val};
  },
  wheel:function(){
   var s=st(),t=today(); if(s.wheel===t)return{ok:false,why:'دورة واحدة يوميًا'};
   var prizes=[0.001,0.002,0.003,0.005,0.008,0.012,0.02,0.05];
   var w=[24,22,18,14,10,6,4,2],r=Math.random()*100,acc=0,p=prizes[0];
   for(var i=0;i<w.length;i++){acc+=w[i];if(r<=acc){p=prizes[i];break}}
   s.wheel=t;sv(s);credit(p,'wheel');addXP(15);
   return{ok:true,val:p};
  },
  gift:async function(c){
   var s=st();s.gifts=s.gifts||{};
   if(s.gifts[c])return{ok:false,why:'استخدمت هذا الكود مسبقًا'};
   if(window.CHCloud&&CHCloud.cloud()){var r=await CHCloud.redeem(c);if(!r.ok)return r}
   else{try{var j=await (await fetch('/gift.json?t='+Date.now())).json();
    var g=(j.codes||[]).filter(function(x){return x.code.toUpperCase()===c.toUpperCase()})[0];
    if(!g)return{ok:false,why:'كود غير موجود'};var v=g.value;
    if(g.kind==='usd')credit(v,'gift:'+c); if(g.kind==='xp')addXP(v);
    s.gifts[c]=Date.now();sv(s);return{ok:true,kind:g.kind,value:v}}catch(e){return{ok:false,why:'تعذّر القراءة'}}}
   s.gifts[c]=Date.now();sv(s);credit(0.05,'gift:'+c);addXP(25);return{ok:true,kind:'usd',value:0.05};
  },
  refer:function(){
   var s=st();s.refs=s.refs||[];s.code=s.code||code();
   var u=new URL(location.href);u.searchParams.set('ref',s.code);
   return{code:s.code,link:u.origin+u.pathname+'?ref='+s.code,n:(s.refs||[]).length};
  },
  claimRef:function(){
   var r=new URL(location.href).searchParams.get('ref');
   if(!r||r===(st().code||''))return null;
   var s=st();s.refs=s.refs||[]; if(s.refs.indexOf(r)>=0)return null;
   s.refs.push(r);sv(s);credit(0.01,'ref:l1');addXP(20);
   return{ok:true,by:r,bonus:0.01};
  },
  board:function(){var s=st();return[{n:'أنت',v:s.xp||0,l:level(s.xp||0)}]}
 };
 document.addEventListener('ch:ads-ready',function(){CHRewards.claimRef()});
})();
