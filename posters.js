(function(){
if(/\/(play|m\/)/.test(location.pathname))return;
var PH='data:image/svg+xml;utf8,'+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="300" height="450"><rect width="300" height="450" fill="#0d151f"/><text x="150" y="230" fill="#4cc2ff" font-size="16" text-anchor="middle" font-family="sans-serif">CineHub</text></svg>');
function esc(s){return String(s==null?'':s).replace(/[&<>"]/g,function(c){return({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'})[c];});}
fetch('catalog.json?_='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(d){
 var it=(d.items||[]).filter(function(x){return (x.th||'').trim()&&x.mp});
 if(!it.length)return;
 it.sort(function(a,b){return (b.v||0)-(a.v||0)});
 var w=document.createElement('div');w.id='chNow';
 w.innerHTML='<style>#chNow{margin:16px 0;font-family:system-ui,Tahoma;color:#e9f1f8}#chNow h2{font-size:17px;margin:0 0 10px}'
 +'#chNow .strip{display:flex;gap:10px;overflow-x:auto;padding-bottom:8px}#chNow .st{flex:0 0 126px;text-decoration:none;color:inherit}'
 +'#chNow .st img{width:126px;height:188px;object-fit:cover;border-radius:12px;display:block;background:#0d151f;border:1px solid rgba(255,255,255,.08)}'
 +'#chNow .st b{display:block;font-size:12px;padding:6px 2px;line-height:1.35;max-height:44px;overflow:hidden}'
 +'#chNow .p{position:relative}#chNow .pl{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:30px;opacity:.85;pointer-events:none}'
 +'#chNow .more{color:#4cc2ff;font-size:13px;text-decoration:none}</style>'
 +'<h2>🎬 يُشاهد الآن <a class="more" href="library.html">كل المكتبة ←</a></h2><div class="strip">'
 +it.slice(0,60).map(function(x){return '<a class="st" href="m/'+encodeURIComponent(x.mp)+'"><span class="p"><img loading="lazy" src="'+esc(x.th)+'" onerror="this.src=\''+PH+'\'"><span class="pl">▶</span></span><b>'+esc(x.t)+'</b></a>';}).join('')
 +'</div>';
 var b=document.body; b.insertBefore(w,b.firstChild?b.firstChild.nextSibling||b.firstChild:b.firstChild);
}).catch(function(){});})();
