(function(){
if (window.__ch) return;
function sig(el){
  var p=[];
  ['name','id','placeholder','aria-label','autocomplete','title','data-testid'].forEach(function(a){
    var v = el.getAttribute && el.getAttribute(a); if(v) p.push(String(v).toLowerCase());
  });
  try{ if(el.labels && el.labels.length) p.push(el.labels[0].innerText.toLowerCase()); }catch(e){}
  try{
    var pd = el.parentElement;
    if(pd){ var t=(pd.innerText||'').toLowerCase(); if(t.length<70) p.push(t); }
  }catch(e){}
  return p.join(' ');
}
function setVal(el,val){
  var P = el.tagName==='TEXTAREA' ? HTMLTextAreaElement.prototype
        : (el.tagName==='SELECT' ? HTMLSelectElement.prototype : HTMLInputElement.prototype);
  var d = Object.getOwnPropertyDescriptor(P,'value');
  try{ if(d && d.set) d.set.call(el,val); else el.value=val; }catch(e){ el.value=val; }
  el.dispatchEvent(new Event('input',{bubbles:true}));
  el.dispatchEvent(new Event('change',{bubbles:true}));
  el.dispatchEvent(new Event('blur',{bubbles:true}));
}
window.__ch = {
  scan: function(){
    var all = document.querySelectorAll('input,textarea,select');
    var out=[];
    for(var i=0;i<all.length;i++){
      var el=all[i]; el.setAttribute('data-ch', String(i));
      var r=el.getBoundingClientRect(), st=getComputedStyle(el);
      var vis = r.width>1 && r.height>1 && st.visibility!=='hidden' && st.display!=='none' && !el.disabled;
      out.push({ i:i, tag:el.tagName.toLowerCase(), type:(el.type||'').toLowerCase(),
                 sig: vis ? sig(el) : '', val: el.value||'', checked: !!el.checked, vis: vis,
                 opts: el.tagName==='SELECT' ? Array.prototype.slice.call(el.options,0,400).map(function(o){return o.text;}) : null });
    }
    return out;
  },
  put: function(i,v){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; setVal(el,v); return true; },
  putSel: function(i,needle){
    var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return '';
    var n=String(needle).toLowerCase();
    for(var k=0;k<el.options.length;k++){ var o=el.options[k];
      if((o.text||'').toLowerCase().indexOf(n)>=0 || (o.value||'').toLowerCase()===n){
        el.value=o.value; el.dispatchEvent(new Event('change',{bubbles:true})); return o.text; } }
    return '';
  },
  check: function(i){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; if(!el.checked) el.click(); return true; },
  submitBtn: function(){
    var pats=['sign up','signup','register','create account','create','join','submit','continue','next','get started','انشاء','تسجيل'];
    var els=document.querySelectorAll('button,input[type=submit],input[type=button],a[role=button],a.button');
    for(var i=0;i<els.length;i++){
      var el=els[i], r=el.getBoundingClientRect(); if(r.width<2||r.height<2) continue;
      var t=((el.innerText||'')+' '+(el.value||'')+' '+(el.getAttribute('aria-label')||'')).trim().toLowerCase();
      for(var p=0;p<pats.length;p++){ if(t.indexOf(pats[p])>=0){ el.setAttribute('data-ch-btn','1'); return t; } }
    }
    return '';
  },
  clickBtn: function(){ var b=document.querySelector('[data-ch-btn]'); if(!b) return false; try{b.scrollIntoView({block:'center'});}catch(e){} b.click(); return true; },
  captcha: function(){
    function v(sel,attr){ var e=document.querySelector(sel); if(!e) return ''; var x=e.getAttribute(attr)||e.value||''; return x; }
    var g=v('textarea[name="g-recaptcha-response"]','') || v('#g-recaptcha-response','');
    if(g && g.length>20) return 'recaptcha-solved';
    var h=v('textarea[name="h-captcha-response"]','');
    if(h && h.length>20) return 'hcaptcha-solved';
    var t=v('input[name="cf-turnstile-response"]','');
    if(t && t.length>20) return 'turnstile-solved';
    if(document.querySelector('.g-recaptcha,iframe[src*="recaptcha"],iframe[src*="hcaptcha"],.h-captcha,#cf-turnstile,.cf-turnstile')) return 'present';
    return '';
  },
  cookies: function(){
    var pats=['accept','agree','allow all','got it','ok','accept all','موافق','قبول','alright'];
    var els=document.querySelectorAll('button,a');
    for(var i=0;i<els.length;i++){
      var el=els[i], r=el.getBoundingClientRect(); if(r.width<2) continue;
      var t=(el.innerText||'').trim().toLowerCase();
      if(t.length<26){ for(var p=0;p<pats.length;p++){ if(t===pats[p]||t.indexOf(pats[p])>=0){ el.click(); return t; } } }
    }
    return '';
  },
  ready: function(){ return document.readyState; }
};
})();
