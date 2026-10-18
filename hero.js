/* قسم ترحيبي + شريط حيّ + زر تثبيت PWA */
(function(){
 function n(v){return Number(v||0).toLocaleString('en')}
 function boot(){
  if(document.querySelector('.hero'))return;
  var w=document.querySelector('.wrap')||document.body;
  var h=document.createElement('div');h.className='hero';
  h.innerHTML='<h2>CineHub 3099 — مكتبة أفلام + طبقة أرباح حقيقية</h2>'+
   '<p>اربح من المشاهدة والاستطلاعات والمكافآت اليومية، واسحب إلى بنك الكريمي من $5. كل رقم مقروء من البلوكتشين أو من واجهات الشبكات.</p>'+
   '<a class="cta" href="/start.html">ابدأ واربح ←</a><a class="cta alt" href="/watch.html">شاهد واقبض</a>'+
   '<div class="livebar"><span><span class="dot"></span>المحرّك السحابي: <b id="h-hb">…</b></span>'+
   '<span>إيراد حقيقي 30 يوم: <b id="h-rev">…</b></span><span>زيارات جهازك: <b id="h-v">0</b></span></div>';
  w.insertBefore(h,w.firstChild);
  Promise.all([fetch('/revenue.json?t='+Date.now()).then(r=>r.json()).catch(()=>({})),
   fetch('/heartbeat.json?t='+Date.now()).then(r=>r.json()).catch(()=>({}))]).then(function(a){
   var r=a[0],hb=a[1];
   document.getElementById('h-rev').textContent='$'+Number(r.revenue||0).toFixed(4);
   document.getElementById('h-hb').textContent=hb.t?(hb.t.slice(5,16)+'Z'):'بانتظار';
   document.getElementById('h-v').textContent=n(localStorage.getItem('ch_impressions'));
  });
  if(localStorage.getItem('ch_visits')==='1'&&!localStorage.getItem('ch_hero_seen')){
   localStorage.setItem('ch_hero_seen','1');
   var p=document.createElement('div');p.className='card';
   p.innerHTML='<b>مرحبًا بك 👋</b> <span class="l">فعّل هويتك بكابتشا واحدة لتحفظ رصيدك، ثم اجمع مكافأة الترحيب.</span> <a href="/gate.html">تفعيل</a>';
   w.insertBefore(p,h.nextSibling);
  }
 }
 document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
 // PWA
 var dp=null;
 addEventListener('beforeinstallprompt',function(e){e.preventDefault();dp=e;
  var b=document.createElement('button');b.textContent='📲 ثبّت التطبيق';
  b.style.cssText='position:fixed;bottom:96px;left:10px;z-index:9996;background:#a78bfa;color:#04121a;border:0;border-radius:999px;padding:9px 14px;font-weight:800;cursor:pointer';
  b.onclick=function(){if(dp){dp.prompt();dp=null;b.remove()}};document.body.appendChild(b)});
})();
