(function(){
if (window.__ch) return;
function sig(el){
  var p=[];
  ['name','id','placeholder','aria-label','autocomplete','title','data-testid'].forEach(function(a){
    var v = el.getAttribute && el.getAttribute(a); if(v) p.push(String(v).toLowerCase());
  });
  try{ if(el.labels && el.labels.length) p.push(el.labels[0].innerText.toLowerCase()); }catch(e){}
  try{ var pd=el.parentElement; if(pd){ var t=(pd.innerText||'').toLowerCase(); if(t.length<70) p.push(t);} }catch(e){}
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
    var all = document.querySelectorAll('input,textarea,select'), out=[];
    for(var i=0;i<all.length;i++){
      var el=all[i]; el.setAttribute('data-ch', String(i));
      var r=el.getBoundingClientRect(), st=getComputedStyle(el);
      var vis = r.width>1 && r.height>1 && st.visibility!=='hidden' && st.display!=='none' && !el.disabled;
      out.push({ i:i, tag:el.tagName.toLowerCase(), type:(el.type||'').toLowerCase(),
                 sig: vis?sig(el):'', val: el.value||'', checked: !!el.checked, vis: vis,
                 opts: el.tagName==='SELECT' ? Array.prototype.slice.call(el.options,0,400).map(function(o){return o.text;}) : null });
    }
    return out;
  },
  _w: function(fr){
    if(!fr) return window;
    var f = document.querySelectorAll('iframe')[fr-1];
    return (f && f.contentWindow) ? f.contentWindow : window;
  },
  frames: function(){
    var n=0, f=document.querySelectorAll('iframe');
    for(var i=0;i<f.length;i++){ try{ if(f[i].contentWindow && f[i].contentWindow.__ch) n++; }catch(e){} }
    return n;
  },
  scanAll: function(){
    var out = window.__ch.scan();
    for(var i=0;i<out.length;i++) out[i].fr = 0;
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){
      try{
        var w = fr[i].contentWindow; if(!w || !w.__ch) continue;
        var sub = w.__ch.scan();
        for(var j=0;j<sub.length;j++){ sub[j].fr = i+1; out.push(sub[j]); }
      }catch(e){}
    }
    return out;
  },
  put: function(i,v){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; setVal(el,v); return true; },
  putF: function(fr,i,v){ try{ var w=window.__ch._w(fr); if(!w.__ch) return false; return w.__ch.put(i,v); }catch(e){ return false; } },
  putSel: function(i,needle){
    var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return '';
    var n=String(needle).toLowerCase();
    for(var k=0;k<el.options.length;k++){ var o=el.options[k];
      if((o.text||'').toLowerCase().indexOf(n)>=0 || (o.value||'').toLowerCase()===n){
        el.value=o.value; el.dispatchEvent(new Event('change',{bubbles:true})); return o.text; } }
    return '';
  },
  putSelF: function(fr,i,t){ try{ var w=window.__ch._w(fr); return w.__ch.putSel(i,t); }catch(e){ return ''; } },
  check: function(i){ var el=document.querySelector('[data-ch="'+i+'"]'); if(!el) return false; if(!el.checked) el.click(); return true; },
  checkF: function(fr,i){ try{ var w=window.__ch._w(fr); return w.__ch.check(i); }catch(e){ return false; } },
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
  submitAll: function(){
    var t = window.__ch.submitBtn(); if(t) return t;
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){ try{ var w=fr[i].contentWindow; if(w && w.__ch && w.__ch.submitBtn()) return 'frame'; }catch(e){} }
    return '';
  },
  clickBtn: function(){
    var b=document.querySelector('[data-ch-btn]');
    if(b){ try{b.scrollIntoView({block:'center'});}catch(e){} b.click(); return true; }
    var fr = document.querySelectorAll('iframe');
    for(var i=0;i<fr.length;i++){ try{ var w=fr[i].contentWindow; if(w && w.__ch) return w.__ch.clickBtn(); }catch(e){} }
    return false;
  },
  captcha: function(){
    function val(sel){ var e=document.querySelector(sel); return e ? (e.value||'') : ''; }
    if((val('textarea[name="g-recaptcha-response"]')||val('#g-recaptcha-response')).length>20) return 'recaptcha-solved';
    if(val('textarea[name="h-captcha-response"]').length>20) return 'hcaptcha-solved';
    if(val('input[name="cf-turnstile-response"]').length>20) return 'turnstile-solved';
    if(document.querySelector('.g-recaptcha,iframe[src*="recaptcha"],iframe[src*="hcaptcha"],.h-captcha,#cf-turnstile,.cf-turnstile')) return 'present';
    return '';
  },
  captchaBox: function(){
    var sels=['iframe[src*="recaptcha/api2/anchor"]','iframe[title*="reCAPTCHA"]',
              'iframe[src*="hcaptcha"]','iframe[title*="hCaptcha"]','iframe[src*="turnstile"]'];
    for(var s=0;s<sels.length;s++){
      var f=document.querySelector(sels[s]); if(!f) continue;
      var r=f.getBoundingClientRect();
      if(r.width<4||r.height<4||r.top<-60||r.top>4000) continue;
      return {x:r.left+Math.min(28,r.width/2), y:r.top+r.height/2, kind:sels[s]};
    }
    return null;
  },
  cookies: function(){
    var pats=['accept','agree','allow all','got it','ok','accept all','موافق','قبول'];
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
