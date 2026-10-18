/* CineHub 3099 — كاسر الحصار: يُبطل كل SW وكاش مرة واحدة لكل إصدار */
(function () {
  "use strict";
  var V = "3099-1792196423";
  var SS = window.sessionStorage;
  function g(k){ try { return SS.getItem(k); } catch(e){ return null; } }
  function s(k,v){ try { SS.setItem(k,v); } catch(e){} }
  var force = /[?&](fresh|reset|clean)=1/.test(location.search);
  var prev  = g("ch3099_sw_ver");
  var need  = force || prev !== V;

  function nuke(){
    var jobs = [];
    if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
      jobs.push(navigator.serviceWorker.getRegistrations().then(function(rs){
        return Promise.all(rs.map(function(r){ return r.unregister(); }));
      }).catch(function(){}));
    }
    if (window.caches && caches.keys) {
      jobs.push(caches.keys().then(function(ks){
        return Promise.all(ks.map(function(k){ return caches.delete(k); }));
      }).catch(function(){}));
    }
    return Promise.all(jobs);
  }
  function reg(){
    if (!navigator.serviceWorker || !window.isSecureContext) return;
    navigator.serviceWorker.register("sw2.js?v=" + V, { scope: "./" }).catch(function(){});
  }

  if (need) {
    var tries = parseInt(g("ch3099_sw_tries") || "0", 10);
    nuke().then(function(){
      s("ch3099_sw_ver", V);
      var controlled = navigator.serviceWorker && navigator.serviceWorker.controller;
      if (controlled && tries < 2) {
        s("ch3099_sw_tries", String(tries + 1));
        reg();
        setTimeout(function(){ location.reload(); }, 80);
      } else {
        s("ch3099_sw_tries", "0");
        reg();
      }
    });
  } else {
    reg();
  }
})();
