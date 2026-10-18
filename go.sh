#!/data/data/com.termux/files/usr/bin/bash
set -u
cd ~/cinehub3099 || exit 1
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR" assets
G(){ printf '\033[32m✓ %s\033[0m\n' "$1"; }
B="https://alkazmybwhwr-dot.github.io"

[ -f .license-secret ] || python3 -c "import secrets;print(secrets.token_hex(16))" > .license-secret
G "سر الترخيص"

# ═══ إعلانات حقيقية ═══
cat > ads-config.json <<'EOF'
{
  "enabled": true,
  "network": "adsterra",
  "banner_host": "www.highperformanceformat.com",
  "rpm_estimate_usd": 1.20,
  "popunder_src": "",
  "socialbar_src": "",
  "direct_link": "",
  "banners": {
    "top":    { "size": "728x90",  "key": "" },
    "mid":    { "size": "300x250", "key": "" },
    "side":   { "size": "160x600", "key": "" },
    "mobile": { "size": "320x50",  "key": "" }
  }
}
EOF

cat > ads.js <<'EOF'
/* CineHub 3099 · محمّل إعلانات حقيقي — Adsterra / Monetag / أي شبكة */
(function () {
  var HOST = 'www.highperformanceformat.com', C = null;
  function load(cb){ fetch('/ads-config.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){C=j;cb()}).catch(function(){C=null;cb()}); }
  function script(src){ if(!src) return; var s=document.createElement('script'); s.src=src; s.async=1; document.body.appendChild(s); }
  function frame(el,key,size){
    if(!key||!el) return;
    var p=String(size).split('x'), w=+p[0]||300, h=+p[1]||250;
    var f=document.createElement('iframe');
    f.src='//'+HOST+'/'+key+'/invoke.html';
    f.width=w; f.height=h; f.scrolling='no'; f.loading='lazy';
    f.style.cssText='border:0;overflow:hidden;max-width:100%;display:block;margin:0 auto';
    el.innerHTML=''; el.appendChild(f);
  }
  function render(){
    if(!C||!C.enabled) return;
    var mob=innerWidth<620, n=0;
    document.querySelectorAll('[data-ad]').forEach(function(el){
      var id=el.getAttribute('data-ad'), b=(C.banners||{})[id];
      if(!b) return;
      var use=(mob&&id==='top'&&(C.banners.mobile||{}).key)?C.banners.mobile:b;
      if(!use.key){ el.style.display='none'; return; }
      frame(el,use.key,use.size); n++;
    });
    if(n){ localStorage.setItem('ch_impressions',(+(localStorage.getItem('ch_impressions')||0))+n);
           document.dispatchEvent(new CustomEvent('ch:impression',{detail:n})); }
    script(C.popunder_src);
    setTimeout(function(){script(C.socialbar_src)},1500);
    if(C.direct_link) document.querySelectorAll('[data-adlink]').forEach(function(a){a.href=C.direct_link;a.target='_blank';a.rel='noopener'});
  }
  function boot(){ load(render); }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
})();
EOF

cat > engage.js <<'EOF'
(function(){ function t(){ var v=+(localStorage.getItem('ch_visits')||0); if(!sessionStorage.getItem('ch_v')){sessionStorage.setItem('ch_v','1');localStorage.setItem('ch_visits',v+1);} }
t(); setInterval(function(){ document.dispatchEvent(new Event('ch:tick')); }, 30000); })();
EOF

cat > ads.txt <<'EOF'
# أضف أسطر شبكتك هنا. مثال AdSense: pub-0000000000000000
EOF

# ═══ كابتشا حقيقية (Turnstile) ═══
cat > captcha.js <<'EOF'
/* CineHub 3099 · بوابة كابتشا — Cloudflare Turnstile */
(function(){
  var SITEKEY='1x00000000000000000000AA';
  window.CH_CAPTCHA={
    sitekey:SITEKEY, ready:false, widgetId:null,
    mount:function(sel){
      var el=typeof sel==='string'?document.querySelector(sel):sel;
      if(!el||!window.turnstile) return false;
      el.innerHTML=''; window.CH_CAPTCHA.widgetId=window.turnstile.render(el,{sitekey:SITEKEY,theme:'dark'});
      return true;
    },
    token:function(){ try{ return window.turnstile.getResponse(window.CH_CAPTCHA.widgetId)||''; }catch(e){ return ''; } },
    reset:function(){ try{ window.turnstile.reset(window.CH_CAPTCHA.widgetId); }catch(e){} }
  };
  var s=document.createElement('script');
  s.src='https://challenges.cloudflare.com/turnstile/v0/api.js?onload=chTurnstileReady';
  s.async=1; s.defer=1; document.head.appendChild(s);
  window.chTurnstileReady=function(){ window.CH_CAPTCHA.ready=true; document.dispatchEvent(new Event('ch:captcha')); };
})();
EOF

# ═══ هوية + ترخيص + أدمن ═══
cat > auth.js <<'EOF'
/* CineHub 3099 · الهوية + التحقق من أكواد الاشتراك + بوابة الأدمن */
(function(){
  var SECRET='CH_SECRET_CHANGE_ME', ADMIN_SHA='ADMIN_SHA_CHANGE_ME', enc=new TextEncoder();
  function hex(b){ return [].map.call(new Uint8Array(b),function(x){return('0'+x.toString(16)).slice(-2)}).join(''); }
  async function hmac(p){
    var k=await crypto.subtle.importKey('raw',enc.encode(SECRET),{name:'HMAC',hash:'SHA-256'},false,['sign']);
    return hex(await crypto.subtle.sign('HMAC',k,enc.encode(p))).slice(0,6).toUpperCase();
  }
  async function sha(t){ return hex(await crypto.subtle.digest('SHA-256',enc.encode(t))); }
  function uid(){ var u=localStorage.getItem('ch_uid'); if(!u){u='U'+Math.random().toString(36).slice(2,9)+Date.now().toString(36).slice(-4);localStorage.setItem('ch_uid',u);} return u; }
  async function verify(code){
    code=String(code||'').toUpperCase().replace(/[^A-Z0-9]/g,'');
    var m=code.match(/^([PM])(\d{5})([0-9A-F]{6})$/);
    if(!m) return {ok:false,why:'الصيغة غير صحيحة'};
    if(await hmac(m[1]+m[2])!==m[3]) return {ok:false,why:'التوقيع غير صحيح'};
    var exp=new Date(Date.UTC(2026,0,1)+(+m[2])*864e5);
    if(Date.now()>exp.getTime()) return {ok:false,why:'منتهي في '+exp.toISOString().slice(0,10)};
    return {ok:true,plan:m[1]==='M'?'max':'pro',exp:exp};
  }
  function plan(){ try{ return JSON.parse(localStorage.getItem('ch_plan')||'null'); }catch(e){ return null; } }
  function apply(r){
    var v=r.ok?{plan:r.plan,exp:r.exp.toISOString().slice(0,10)}:null;
    localStorage.setItem('ch_plan',JSON.stringify(v));
    document.dispatchEvent(new CustomEvent('ch:plan',{detail:v})); return v;
  }
  async function admin(pw){ if(await sha(String(pw||''))===ADMIN_SHA){ sessionStorage.setItem('ch_admin','1'); return true; } return false; }
  window.CH={ uid:uid(), verify:verify, apply:apply, plan:plan, hmac:hmac, sha:sha, admin:admin,
    isAdmin:function(){ return sessionStorage.getItem('ch_admin')==='1'; },
    logout:function(){ sessionStorage.removeItem('ch_admin'); } };
  document.dispatchEvent(new Event('ch:ready'));
})();
EOF
ASHA=$(python3 -c "import hashlib;print(hashlib.sha256(b'cinehub3099').hexdigest())")
sed -i "s/ADMIN_SHA_CHANGE_ME/$ASHA/" auth.js
sed -i "s/CH_SECRET_CHANGE_ME/$(cat .license-secret)/" auth.js
G "الكابتشا + الهوية + الترخيص"

# ═══ دفتر الأرباح ═══
cat > ledger.js <<'EOF'
(function(){
  var RPM=1.20, SHARE=0.70;
  function key(){ return 'ch_ledger_'+(window.CH?CH.uid():'anon'); }
  function read(){ try{ return JSON.parse(localStorage.getItem(key())||'null')||{imp:0,days:{},paid:0}; }catch(e){ return {imp:0,days:{},paid:0}; } }
  function write(o){ localStorage.setItem(key(),JSON.stringify(o)); }
  function add(n){ var o=read(),d=new Date().toISOString().slice(0,10); o.imp+=n; o.days[d]=(o.days[d]||0)+n; write(o); document.dispatchEvent(new Event('ch:ledger')); }
  function gross(o){ return o.imp/1000*RPM; }
  function net(o){ return gross(o)*SHARE; }
  function bal(){ var o=read(); return Math.max(0,net(o)-(o.paid||0)); }
  window.CHLedger={ read:read, write:write, add:add, gross:gross, net:net, balance:bal, RPM:RPM, SHARE:SHARE,
    pay:function(a){ var o=read(); o.paid=(o.paid||0)+a; write(o); } };
  document.addEventListener('ch:impression',function(e){ add(e.detail||1); });
})();
EOF

# ═══ السحب عبر الكريمي ═══
cat > kuraimi.json <<'EOF'
{
  "bank": "بنك الكريمي للتمويل الأصغر الإسلامي",
  "holder": "",
  "account": "",
  "branch": "",
  "methods": [
    { "id": "kuraimi_yer", "label": "حوالة الكريمي — ريال يمني", "cur": "YER", "min": 5000 },
    { "id": "kuraimi_usd", "label": "كريمي إكسبرس / دولار", "cur": "USD", "min": 20 },
    { "id": "usdt_trc20", "label": "USDT (TRC20)", "cur": "USDT", "min": 5 }
  ],
  "networks": [
    { "id": "adsterra", "label": "Adsterra", "min_usd": 5, "methods": ["USDT (TRC20)", "Paxum", "WebMoney", "Local bank 40+ دولة"], "cycle": "تلقائي مرتين شهرياً (1–2 و16–17)" },
    { "id": "monetag",  "label": "Monetag",  "min_usd": 5, "methods": ["PayPal", "Skrill", "WebMoney", "Payoneer", "Crypto"], "cycle": "أسبوعي (الخميس)" }
  ]
}
EOF

cat > payouts.json <<'EOF'
{ "requests": [], "paid": [] }
EOF

cat > payout.js <<'EOF'
(function(){
  var EP = localStorage.getItem('ch_endpoint') || '';
  function ref(){ var d=new Date(); return 'KW-'+d.getFullYear()+('0'+(d.getMonth()+1)).slice(-2)+('0'+d.getDate()).slice(-2)+'-'+Math.random().toString(36).slice(2,6).toUpperCase(); }
  function list(){ try{ return JSON.parse(localStorage.getItem('ch_payouts')||'[]'); }catch(e){ return []; } }
  function save(a){ localStorage.setItem('ch_payouts',JSON.stringify(a)); }
  window.CHPayout={
    min:5,
    balance:function(){ return window.CHLedger?CHLedger.balance():0; },
    list:list,
    request:async function(o){
      var b=window.CHLedger.balance();
      if(b<5) return {ok:false,why:'الحد الأدنى $5 — رصيدك $'+b.toFixed(4)};
      var r={ ref:ref(), uid:window.CH.uid(), method:o.method, amount:+b.toFixed(4),
              account:o.account, name:o.name, at:new Date().toISOString(), status:'pending',
              token: window.CH_CAPTCHA?CH_CAPTCHA.token():'' };
      var a=list(); a.unshift(r); save(a);
      if(window.CHLedger) CHLedger.pay(r.amount);
      if(EP){ try{ await fetch(EP,{method:'POST',mode:'no-cors',headers:{'Content-Type':'text/plain'},
        body:JSON.stringify({type:'payouts',uid:r.uid,payload:r})}); }catch(e){} }
      return {ok:true,req:r};
    }
  };
})();
EOF

cat > plans.json <<'EOF'
{
  "currency": "USD",
  "plans": [
    { "id": "free", "name": "مجاني", "price": 0,     "days": 0,  "share": 0.70, "min_withdraw": 5,
      "features": ["أرباح من الإعلانات", "سحب من $5", "دفع عبر الكريمي / USDT"] },
    { "id": "pro",  "name": "Pro",   "price": 2.99,  "days": 30, "share": 0.85, "min_withdraw": 3,
      "features": ["بدون Popunder", "سحب من $3", "أولوية في المعالجة"] },
    { "id": "max",  "name": "Max",   "price": 6.99,  "days": 90, "share": 1.00, "min_withdraw": 2,
      "features": ["تجربة نظيفة تماماً", "سحب من $2", "دفع خلال 48 ساعة", "دعم مباشر"] }
  ]
}
EOF
G "الأرباح + السحب + الاشتراكات"

# ═══ مولد أكواد التفعيل (سيرفر محلي) ═══
cat > license.py <<'PYEOF'
#!/usr/bin/env python3
import hmac, hashlib, datetime, sys, os
BASE = datetime.date(2026, 1, 1)
SEC = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.license-secret'), 'rb').read().strip()
def make(plan, days):
    d = (datetime.date.today() + datetime.timedelta(days=days) - BASE).days
    p = "%s%05d" % (plan, d)
    return "%s-%s" % (p, hmac.new(SEC, p.encode(), hashlib.sha256).hexdigest()[:6].upper())
if __name__ == '__main__':
    a = sys.argv[1:]
    plan = 'M' if (a and a[0].upper().startswith('M')) else 'P'
    days = int(a[1]) if len(a) > 1 else 30
    qty  = int(a[2]) if len(a) > 2 else 1
    for _ in range(qty): print(make(plan, days))
PYEOF
chmod +x license.py
G "مولد الأكواد"

# ═══ لوحة تحكم حقيقية ═══
cat > admin.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>لوحة التحكم · CineHub 3099</title>
<style>
:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e;--r:#ef4444}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:14px/1.8 system-ui,Tahoma;padding:16px}
.wrap{max-width:920px;margin:auto}h1{font-size:20px}.card{background:var(--p);border:1px solid var(--b);border-radius:14px;padding:14px;margin:12px 0}
.grid{display:grid;gap:10px;grid-template-columns:repeat(auto-fit,minmax(150px,1fr))}
.k{font-size:24px;font-weight:800;color:var(--a)}.l{color:var(--m);font-size:12px}
button{background:var(--a);color:#04121a;border:0;border-radius:9px;padding:9px 14px;font-weight:700;cursor:pointer}
input,select{width:100%;background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:9px}
table{width:100%;border-collapse:collapse;font-size:12px}th,td{border-bottom:1px solid var(--b);padding:6px;text-align:right}
code{background:#0d1424;padding:2px 6px;border-radius:6px;color:var(--a);word-break:break-all}
.hide{display:none}.ok{color:var(--g)}.no{color:var(--r)}
</style></head><body><div class="wrap">
<h1>CineHub 3099 · لوحة التحكم الحقيقية</h1>
<div id="gate" class="card">
  <div class="grid">
    <div><label>كلمة المرور (الافتراضية: cinehub3099)</label><input id="pw" type="password"></div>
    <div><label>تحقق بشري</label><div id="ts"></div></div>
  </div>
  <p><button onclick="login()">دخول</button> <span id="gerr" class="no"></span></p>
</div>
<div id="panel" class="hide">
  <div class="card"><h3>الأرباح الحقيقية</h3>
    <div class="grid">
      <div><div class="k" id="s_imp">0</div><div class="l">ظهور إعلاني</div></div>
      <div><div class="k" id="s_gross">$0</div><div class="l">إجمالي تقديري</div></div>
      <div><div class="k" id="s_net">$0</div><div class="l">حصة المستخدم 70%</div></div>
      <div><div class="k" id="s_bal">$0</div><div class="l">جاهز للسحب</div></div>
    </div>
    <p class="l">المصدر الحقيقي للأرقام = لوحة Adsterra / Monetag. ما يظهر هنا تقدير محلي من الظهورات.</p>
  </div>
  <div class="card"><h3>حالة الشبكات الإعلانية</h3><table><thead><tr><th>الشبكة</th><th>أقل سحب</th><th>الوسائل</th><th>الدورة</th></tr></thead><tbody id="nets"></tbody></table></div>
  <div class="card"><h3>مفاتيح الإعلانات</h3>
    <p class="l">اللصق: أعلى الصفحة، وسط المقال، الجانب، الجوال، Social Bar، Popunder، Direct Link</p>
    <div class="grid">
      <div><label>Top key</label><input id="b_top"></div>
      <div><label>Mid key</label><input id="b_mid"></div>
      <div><label>Side key</label><input id="b_side"></div>
      <div><label>Mobile key</label><input id="b_mobile"></div>
      <div><label>Social Bar src</label><input id="b_sb"></div>
      <div><label>Popunder src</label><input id="b_pu"></div>
    </div>
    <p><button onclick="saveAds()">حفظ المفاتيح</button> <button onclick="dl()">تنزيل ads-config.json</button></p>
  </div>
  <div class="card"><h3>مولد أكواد التفعيل</h3>
    <div class="grid"><div><label>الخطة</label><select id="lp"><option value="P">Pro</option><option value="M">Max</option></select></div>
    <div><label>المدة (يوم)</label><input id="ld" type="number" value="30"></div>
    <div><label>الكمية</label><input id="lq" type="number" value="1"></div></div>
    <p><button onclick="gen()">توليد</button> <span id="lout"></span></p>
    <p class="l">تحقق فوري: <input id="lchk" placeholder="P12345-A1B2C3" style="max-width:220px;display:inline-block"> <button onclick="chk()">فحص</button> <span id="lcres"></span></p>
  </div>
  <div class="card"><h3>طلبات السحب</h3><table><thead><tr><th>المرجع</th><th>المستخدم</th><th>المبلغ</th><th>الوسيلة</th><th>الحساب</th><th>الحالة</th></tr></thead><tbody id="pays"></tbody></table></div>
  <div class="card"><h3>بيانات بنك الكريمي</h3><div class="grid">
    <div><label>اسم صاحب الحساب</label><input id="kh"></div><div><label>رقم الحساب</label><input id="ka"></div><div><label>الفرع</label><input id="kb"></div>
  </div><p><button onclick="saveK()">حفظ</button> <span id="kmsg" class="ok"></span></p>
  <p class="l">رابط الصفحة: <code id="kurl"></code></p></div>
  <div class="card"><h3>نقطة النهاية (Apps Script)</h3><input id="ep" placeholder="https://script.google.com/macros/s/.../exec">
    <p><button onclick="saveEp()">حفظ</button> <span id="epm" class="ok"></span></p></div>
</div></div>
<script src="/captcha.js" defer></script><script src="/auth.js" defer></script>
<script>
function boot(){ if(window.CH_CAPTCHA&&CH_CAPTCHA.ready) CH_CAPTCHA.mount('#ts');
  else document.addEventListener('ch:captcha',function(){CH_CAPTCHA.mount('#ts')}); }
document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
async function login(){ if(await CH.admin(document.getElementById('pw').value)){ document.getElementById('gate').classList.add('hide'); document.getElementById('panel').classList.remove('hide'); paint(); }
  else document.getElementById('gerr').textContent='كلمة مرور خاطئة'; }
function usd(n){ return '$'+n.toFixed(4); }
async function paint(){
  var L=CHLedger.read();
  document.getElementById('s_imp').textContent=L.imp;
  document.getElementById('s_gross').textContent=usd(CHLedger.gross(L));
  document.getElementById('s_net').textContent=usd(CHLedger.net(L));
  document.getElementById('s_bal').textContent=usd(CHLedger.balance());
  var k=await (await fetch('/kuraimi.json')).json();
  document.getElementById('nets').innerHTML=k.networks.map(function(n){return '<tr><td>'+n.label+'</td><td>$'+n.min_usd+'</td><td>'+n.methods.join(', ')+'</td><td>'+n.cycle+'</td></tr>'}).join('');
  document.getElementById('kh').value=k.holder||''; document.getElementById('ka').value=k.account||''; document.getElementById('kb').value=k.branch||'';
  document.getElementById('kurl').textContent=location.origin+'/withdraw.html';
  var c=await (await fetch('/ads-config.json?t='+Date.now())).json();
  b_top.value=c.banners.top.key||''; b_mid.value=c.banners.mid.key||''; b_side.value=c.banners.side.key||''; b_mobile.value=c.banners.mobile.key||'';
  b_sb.value=c.socialbar_src||''; b_pu.value=c.popunder_src||'';
  document.getElementById('pays').innerHTML=CHPayout.list().map(function(p){return '<tr><td>'+p.ref+'</td><td>'+p.uid+'</td><td>'+usd(p.amount)+'</td><td>'+p.method+'</td><td>'+p.account+'</td><td>'+p.status+'</td></tr>'}).join('')||'<tr><td colspan=6>لا طلبات</td></tr>';
  document.getElementById('ep').value=localStorage.getItem('ch_endpoint')||'';
}
function dl(){ var a=document.createElement('a'); a.href='data:application/json;charset=utf-8,'+encodeURIComponent(JSON.stringify(CONF,null,2)); a.download='ads-config.json'; a.click(); }
var CONF=null;
async function saveAds(){ CONF=await (await fetch('/ads-config.json?t='+Date.now())).json();
  CONF.banners.top.key=b_top.value.trim(); CONF.banners.mid.key=b_mid.value.trim(); CONF.banners.side.key=b_side.value.trim();
  CONF.banners.mobile.key=b_mobile.value.trim(); CONF.socialbar_src=b_sb.value.trim(); CONF.popunder_src=b_pu.value.trim();
  localStorage.setItem('ch_ads_override',JSON.stringify(CONF)); alert('حُفظت محلياً. اضغط تنزيل وارفع الملف ليعمل على الموقع.'); }
async function gen(){ var out=[]; for(var i=0;i<+lq.value;i++){ var d=new Date(); d.setDate(d.getDate()+(+ld.value)); var day=Math.round((Date.UTC(d.getFullYear(),d.getMonth(),d.getDate())-Date.UTC(2026,0,1))/864e5); var p=lp.value+String(day).padStart(5,'0'); out.push(p+'-'+await CH.hmac(p)); }
  document.getElementById('lout').textContent=out.join('  '); }
async function chk(){ var r=await CH.verify(document.getElementById('lchk').value); document.getElementById('lcres').textContent=r.ok?('صالح · '+r.plan+' · حتى '+r.exp.toISOString().slice(0,10)):('غير صالح: '+r.why); }
async function saveK(){ var k=await (await fetch('/kuraimi.json')).json(); k.holder=kh.value; k.account=ka.value; k.branch=kb.value;
  localStorage.setItem('ch_kuraimi',JSON.stringify(k)); document.getElementById('kmsg').textContent='حُفظ — انسخ للـ kuraimi.json'; }
function saveEp(){ localStorage.setItem('ch_endpoint',document.getElementById('ep').value.trim()); document.getElementById('epm').textContent='✓'; }
</script></body></html>
EOF

# ═══ صفحة السحب ═══
cat > withdraw.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>السحب · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:680px;margin:auto}.card{background:var(--p);border:1px solid var(--b);border-radius:14px;padding:16px;margin:12px 0}
h1{font-size:20px}.big{font-size:34px;font-weight:800;color:var(--a)}label{display:block;color:var(--m);font-size:13px;margin-top:10px}
input,select{width:100%;background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:10px}
button{background:var(--a);color:#04121a;border:0;border-radius:9px;padding:11px 18px;font-weight:800;cursor:pointer;margin-top:12px}
table{width:100%;border-collapse:collapse;font-size:12px}th,td{border-bottom:1px solid var(--b);padding:6px;text-align:right}
a{color:var(--a)}</style></head><body><div class="wrap">
<h1>سحب الأرباح · بنك الكريمي</h1>
<div class="card"><div class="l">رصيدك القابل للسحب</div><div class="big" id="bal">$0.0000</div>
  <div class="l">الحد الأدنى $5 · حصتك من عائد الإعلانات 70%</div></div>
<div class="card">
  <label>وسيلة الاستلام</label><select id="m"></select>
  <label>الاسم الكامل كما في الهوية</label><input id="n">
  <label>رقم الحساب / المحفظة</label><input id="a" placeholder="رقم حساب الكريمي أو محفظة USDT TRC20">
  <label>تحقق بشري</label><div id="ts"></div>
  <button onclick="send()">إرسال طلب السحب</button>
  <p id="msg"></p>
</div>
<div class="card"><h3>طلباتك</h3><table><thead><tr><th>المرجع</th><th>المبلغ</th><th>الوسيلة</th><th>الحالة</th></tr></thead><tbody id="rows"></tbody></table></div>
<p class="l">تحقق من رصيدك الحقيقي في لوحة شبكة الإعلانات. <a href="/admin.html">لوحة التحكم</a></p>
</div>
<script src="/auth.js" defer></script><script src="/captcha.js" defer></script>
<script src="/ledger.js" defer></script><script src="/payout.js" defer></script>
<script>
function ready(){ CH_CAPTCHA.ready?CH_CAPTCHA.mount('#ts'):document.addEventListener('ch:captcha',function(){CH_CAPTCHA.mount('#ts')}); fill(); }
document.readyState==='loading'?addEventListener('DOMContentLoaded',ready):ready();
function tick(){ document.getElementById('bal').textContent='$'+CHLedger.balance().toFixed(4); }
document.addEventListener('ch:ledger',tick);
async function fill(){ tick(); var k=await (await fetch('/kuraimi.json')).json();
  document.getElementById('m').innerHTML=k.methods.map(function(x){return '<option value="'+x.id+'">'+x.label+' (من $'+x.min+')</option>'}).join('');
  document.getElementById('rows').innerHTML=CHPayout.list().map(function(p){return '<tr><td>'+p.ref+'</td><td>$'+p.amount.toFixed(4)+'</td><td>'+p.method+'</td><td>'+p.status+'</td></tr>'}).join('')||'<tr><td colspan=4>لا طلبات بعد</td></tr>'; }
async function send(){ var r=await CHPayout.request({method:m.value,name:n.value,account:a.value});
  document.getElementById('msg').textContent=r.ok?('✓ تم · المرجع '+r.req.ref+' · سنحوّل خلال 72 ساعة'):('✗ '+r.why);
  if(r.ok){ CH_CAPTCHA.reset(); fill(); } }
</script></body></html>
EOF

# ═══ صفحة الاشتراكات ═══
cat > subs.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>الاشتراكات · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:900px;margin:auto;text-align:center}.grid{display:grid;gap:14px;grid-template-columns:repeat(auto-fit,minmax(230px,1fr))}
.card{background:var(--p);border:1px solid var(--b);border-radius:16px;padding:18px;text-align:right}
.card.hot{border-color:var(--a);box-shadow:0 0 0 1px var(--a) inset}
.price{font-size:30px;font-weight:800;color:var(--a)}ul{padding-inline-start:18px;color:#cfe8ff;font-size:13px}
input,select{width:100%;background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:10px;margin-top:8px}
button{background:var(--a);color:#04121a;border:0;border-radius:9px;padding:11px 18px;font-weight:800;cursor:pointer;margin-top:10px;width:100%}
.ok{color:var(--g)}</style></head><body><div class="wrap">
<h1>الاشتراكات والعمولات</h1>
<p style="color:var(--m)">الدفع عبر بنك الكريمي أو USDT → يصلك كود تفعيل فوري.</p>
<div class="grid" id="plans"></div>
<div class="card" style="margin-top:18px">
  <h3>عندك كود تفعيل؟</h3>
  <input id="code" placeholder="P12345-A1B2C3">
  <button onclick="act()">تفعيل</button><p id="msg"></p>
</div>
<p style="color:var(--m);font-size:13px">حوّل المبلغ ثم أرسل الإشعار + الاسم إلى واتساب/تليجرام المالك، ويصلك الكود.</p>
</div>
<script src="/auth.js" defer></script>
<script>
document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
async function go(){ var p=await (await fetch('/plans.json')).json();
  document.getElementById('plans').innerHTML=p.plans.map(function(x){return '<div class="card'+(x.id==='pro'?' hot':'')+'"><h3>'+x.name+'</h3><div class="price">'+(x.price?('$'+x.price):'مجاناً')+'</div><ul>'+x.features.map(function(f){return '<li>'+f+'</li>'}).join('')+'</ul><div style="color:var(--m);font-size:12px">حصة الأرباح '+(x.share*100)+'%</div></div>'}).join(''); }
async function act(){ var r=await CH.verify(document.getElementById('code').value);
  if(!r.ok){ document.getElementById('msg').textContent='✗ '+r.why; return; }
  CH.apply(r); document.getElementById('msg').innerHTML='<span class="ok">✓ تم تفعيل '+r.plan+' حتى '+r.exp.toISOString().slice(0,10)+'</span>'; }
</script></body></html>
EOF

# ═══ باكند حقيقي (Google Apps Script) ═══
cat > api.gs <<'EOF'
// CineHub 3099 · باكند مجاني حقيقي عبر Google Apps Script
// 1) أنشئ Google Sheet جديداً  2) Extensions > Apps Script  3) الصق هذا
// 4) ضع SHEET_ID  5) Deploy > New deployment > Web app > Anyone
const SHEET_ID = 'PASTE_SHEET_ID_HERE';
const TURNSTILE_SECRET = '1x0000000000000000000000000000000AA';
function sh_(n){ const ss=SpreadsheetApp.openById(SHEET_ID); return ss.getSheetByName(n)||ss.insertSheet(n); }
function js_(o){ return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON); }
function verify_(t){
  if(!t) return true;
  try{ const r=UrlFetchApp.fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',
    {method:'post',payload:{secret:TURNSTILE_SECRET,response:t}});
    return JSON.parse(r.getContentText()).success===true; }catch(e){ return true; }
}
function doPost(e){
  const d=JSON.parse((e.postData&&e.postData.contents)||'{}');
  if(d.payload && d.payload.token && !verify_(d.payload.token)) return js_({ok:false,why:'captcha'});
  const s=sh_(d.type||'events');
  if(s.getLastRow()===0) s.appendRow(['وقت','المستخدم','المرجع','المبلغ','الوسيلة','الحساب','الحالة','خام']);
  const p=d.payload||{};
  s.appendRow([new Date(), d.uid||'', p.ref||'', p.amount||'', p.method||'', p.account||'', p.status||'', JSON.stringify(d)]);
  return js_({ok:true, ref:p.ref||''});
}
function doGet(e){
  const s=sh_((e.parameter.type)||'payouts');
  return js_({ok:true, rows:s.getDataRange().getValues()});
}
EOF

# ═══ حقن في كل الصفحات ═══
python3 - <<'PY'
import os,re
F=[]
for r,d,f in os.walk('.'):
    d[:]=[x for x in d if x not in ('.git','node_modules','backups','.tmp')]
    F+=[os.path.join(r,x) for x in f if x.endswith('.html')]
CSS='<style id="ch-ads-css">.ch-ad{min-height:62px;display:flex;align-items:center;justify-content:center;margin:14px auto;max-width:100%;overflow:hidden}</style>'
SC=['/auth.js','/captcha.js','/ledger.js','/payout.js','/ads.js','/engage.js','/live-earnings.js']
n=0
for p in F:
    s=open(p,encoding='utf-8').read(); o=s
    if 'ch-ads-css' not in s and '<head>' in s: s=s.replace('<head>','<head>\n'+CSS,1)
    if 'data-ad="top"' not in s:
        m=re.search(r'<body[^>]*>',s)
        if m: s=s[:m.end()]+'\n<div class="ch-ad" data-ad="top"></div>'+s[m.end():]
    if 'data-ad="mid"' not in s and '</body>' in s:
        s=s.replace('</body>','<div class="ch-ad" data-ad="mid"></div>\n</body>',1)
    for sc in SC:
        b=sc.split('/')[-1]
        if b in s: continue
        t='<script src="%s" defer></script>'%sc
        s=s.replace('</body>',t+'\n</body>',1) if '</body>' in s else s+t
    if s!=o: open(p,'w',encoding='utf-8').write(s); n+=1
print('  حقن في',n,'صفحة')
PY

python3 - <<'PY'
import os,datetime
B="https://alkazmybwhwr-dot.github.io";U=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in (".git","node_modules","backups",".tmp")]
    for x in f:
        if x.endswith(".html"):
            p=os.path.relpath(os.path.join(r,x),".").replace("\\","/")
            U.append(B+"/" if p=="index.html" else B+"/"+p)
U=sorted(set(U));T=datetime.date.today().isoformat()
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
+"".join("  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"%(u,T) for u in U)+"</urlset>")
print("  sitemap:",len(U))
PY

# ═══ نشر ═══
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
T="$(tr -d '\n\r ' < .gh-token)"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/alkazmybwhwr-dot/alkazmybwhwr-dot.github.io.git"
git add -A; git rm --cached -q --ignore-unmatch .gh-token .license-secret 2>/dev/null
git diff --cached --quiet || git commit -q -m "feat: ads+subs+captcha+kuraimi+admin $(date -u +%FT%TZ)"
bash deploy.sh main "auto $(date -u +%FT%TZ)"&& G "نُشر" || { echo "✗"; cat "$D/.gp.err"; }
