/* CineHub 3099 — بوابة كابتشا: تُشترط قبل أي مكافأة أو سحب */
(function () {
  "use strict";
  var K = "ch3099_identity";
  function id(){ try{ return localStorage.getItem(K)||""; }catch(e){ return ""; } }
  function set(v){ try{ localStorage.setItem(K,v); }catch(e){} }
  function hash(a,b){
    return crypto.subtle.digest("SHA-256", new TextEncoder().encode("ch3099|"+(a+b)+"|"+navigator.userAgent+"|"+screen.width))
      .then(function(buf){
        return Array.prototype.map.call(new Uint8Array(buf), function(x){ return ("0"+x.toString(16)).slice(-2); }).join("");
      });
  }
  window.CHAuth = {
    id: id, ok: function(){ return id().length === 64; },
    issue: function(a,b){ return hash(a,b).then(function(h){ set(h); return h; }); },
    require: function(cb){
      if (this.ok()) { cb(); return true; }
      if (confirm("الكابتشا مطلوبة أولًا — افتح go.html لحلّها. هل تفتحها الآن؟")) location.href = "go.html";
      return false;
    },
    guard: function(el){
      if (!el) return;
      if (this.ok()) { el.disabled = false; el.textContent = el.dataset.t || el.textContent; }
      else { el.disabled = true; el.textContent = "🔒 " + (el.dataset.t || "حلّ الكابتشا أولًا"); }
    }
  };
})();
