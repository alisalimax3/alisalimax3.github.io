(function(){
 function own(){try{return JSON.parse(localStorage.getItem('ch_owner')||'{}')}catch(e){return{}}}
 fetch('/owner.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()})
  .then(function(o){localStorage.setItem('ch_owner',JSON.stringify(o||{}))}).catch(function(){});
 function ref(){var d=new Date();return 'KW-'+d.getFullYear()+('0'+(d.getMonth()+1)).slice(-2)+('0'+d.getDate()).slice(-2)+'-'+Math.random().toString(36).slice(2,6).toUpperCase()}
 function list(){try{return JSON.parse(localStorage.getItem('ch_payouts')||'[]')}catch(e){return[]}}
 function save(a){localStorage.setItem('ch_payouts',JSON.stringify(a))}
 function txt(r,k){return ['طلب سحب أرباح — CineHub 3099','المرجع: '+r.ref,'المبلغ: $'+r.amount.toFixed(4),
  'الوسيلة: '+r.method_label,'الاسم كما في الهوية: '+r.name,'رقم الحساب/المحفظة: '+r.account,'رقم الهاتف: '+r.phone,
  'يُحوَّل إلى: '+(k.bank||'')+' — '+(k.holder||'')+' — '+(k.account||''),'SWIFT: '+(k.swift||''),
  'المعرّف: '+r.uid,'البصمة: '+(window.CHRewards?CHRewards.fp():''),'التوقيت: '+r.at,'— '+location.origin].join('\n')}
 window.CHPayout={
  balance:function(){return window.CHLedger?CHLedger.balance():0},
  list:list,
  methods:async function(){try{return (await (await fetch('/kuraimi.json?t='+Date.now())).json()).methods||[]}catch(e){return[]}},
  request:async function(o){
   var b=window.CHLedger?CHLedger.balance():0,k={};try{k=await (await fetch('/kuraimi.json?t='+Date.now())).json()}catch(e){}
   var m=(k.methods||[]).filter(function(x){return x.id===o.method})[0]||{label:o.method,min:5};
   if(b<(m.min||5))return{ok:false,why:'أدنى سحب لهذه الوسيلة $'+(m.min||5)+' — رصيدك $'+b.toFixed(4)};
   if(!o.name||o.name.trim().length<5)return{ok:false,why:'اكتب الاسم كما في الهوية'};
   if(!o.account||o.account.trim().length<4)return{ok:false,why:'اكتب رقم الحساب/المحفظة'};
   if(!o.phone||String(o.phone).replace(/\D/g,'').length<8)return{ok:false,why:'اكتب رقم هاتفك مع رمز الدولة'};
   if(window.CHAuth&&!CHAuth.valid())return{ok:false,why:'فعّل هويتك أولًا من /gate.html'};
   if(window.CHCaptcha&&!CHCaptcha.ready())return{ok:false,why:'أكمل التحقق البشري'};
   var r={ref:ref(),uid:(window.CHAuth?CHAuth.id():(window.CHCloud?CHCloud.uid():'anon')),method:o.method,method_label:m.label,
    amount:+(b*(1-((m.fee||0)/100))).toFixed(4),gross:+b.toFixed(4),fee:m.fee||0,cur:m.cur||'USD',
    account:o.account.trim(),name:o.name.trim(),phone:String(o.phone).trim(),at:new Date().toISOString(),
    status:'pending',token:(window.CHCaptcha?CHCaptcha.token():'')};
   var a=list();a.unshift(r);save(a);if(window.CHLedger)CHLedger.pay(r.gross);
   if(window.CHCloud)CHCloud.withdraw(r);
   var o2=own(),t=txt(r,k);
   r.links={whatsapp:o2.whatsapp?'https://wa.me/'+String(o2.whatsapp).replace(/\D/g,'')+'?text='+encodeURIComponent(t):'',
    telegram:o2.telegram?'https://t.me/'+o2.telegram.replace('@','')+'?text='+encodeURIComponent(t):'',
    mail:o2.email?'mailto:'+o2.email+'?subject='+encodeURIComponent('سحب '+r.ref)+'&body='+encodeURIComponent(t):''};
   r.text=t;
   var EP=o2.endpoint&&o2.endpoint.indexOf('script.google')>-1?o2.endpoint:'';
   if(EP){try{await fetch(EP,{method:'POST',mode:'no-cors',headers:{'Content-Type':'text/plain'},
    body:JSON.stringify({type:'payout',uid:r.uid,payload:r})})}catch(e){}}
   try{window.dispatchEvent(new CustomEvent('ch:payout',{detail:r}))}catch(e){}
   return{ok:true,req:r};
  },
  channels:function(r){
   var L=r.links||{},h=[];
   if(L.whatsapp)h.push('<a href="'+L.whatsapp+'" target="_blank" rel="noopener" style="display:inline-block;margin:6px 4px;padding:9px 14px;background:#22c55e;color:#04121a;border-radius:9px;font-weight:800;text-decoration:none">واتساب</a>');
   if(L.telegram)h.push('<a href="'+L.telegram+'" target="_blank" rel="noopener" style="display:inline-block;margin:6px 4px;padding:9px 14px;background:#4dd0e1;color:#04121a;border-radius:9px;font-weight:800;text-decoration:none">تيليجرام</a>');
   if(L.mail)h.push('<a href="'+L.mail+'" style="display:inline-block;margin:6px 4px;padding:9px 14px;background:#a78bfa;color:#04121a;border-radius:9px;font-weight:800;text-decoration:none">بريد</a>');
   h.push('<button onclick="navigator.clipboard.writeText(CHPayout.last.text)" style="margin:6px 4px;padding:9px 14px;border-radius:9px;border:1px solid #1e2a44;background:#0d1424;color:#e8f6ff">نسخ</button>');
   return '<div style="margin-top:10px">'+h.join('')+'<pre style="direction:ltr;text-align:left;font-size:11px;background:#0d1424;border:1px solid #1e2a44;padding:10px;border-radius:9px;margin-top:8px;overflow:auto">'+r.text+'</pre></div>';
  }
 };
})();
