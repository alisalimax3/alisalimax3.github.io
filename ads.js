/* CineHub 3099 — مساحات إعلان: تُنفَّذ فورًا إن وُجد رابط شبكة، وتُعلن بوضوح إن لا */
(function () {
  "use strict";
  var NS = "ch3099-alkazmybwhwr-dot";
  function hit(k){ try{ fetch("https://abacus.jasoncameron.dev/hit/"+NS+"/"+k,{mode:"cors"}).catch(function(){}); }catch(e){} }
  function slots(){ return document.querySelectorAll("[data-ad], .ad, .adslot"); }
  function paint(cfg){
    var ss = slots(); if (!ss.length) return;
    Array.prototype.forEach.call(ss, function (s) {
      if (s.getAttribute("data-ad-done")) return;
      s.setAttribute("data-ad-done", "1");
      if (cfg && cfg.direct) {
        s.innerHTML = "<a href='" + cfg.direct + "' target='_blank' rel='noopener' style='color:#4cc2ff;font-weight:700'>" +
          (cfg.net ? "إعلان " + cfg.net + " — اضغط للدعم" : "إعلان — اضغط للدعم") + "</a>";
        s.style.borderStyle = "solid";
        s.style.borderColor = "rgba(76,194,255,.4)";
      } else {
        s.innerHTML = "<span>مساحة إعلان — بانتظار رابط الشبكة (<a href='subscribe.html' style='color:#4cc2ff'>تفعيل</a>)</span>";
      }
    });
  }
  fetch("ads.json?_=" + Date.now(), { cache: "no-store" })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (c) { paint(c); })
    .catch(function () { paint(null); });
  function watch(){
    var ss = slots(); if (!ss.length || !("IntersectionObserver" in window)) return;
    var seen = 0;
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting && seen < 6) { seen++; hit("impressions"); } });
    }, { threshold: 0.4 });
    Array.prototype.slice.call(ss).slice(0, 6).forEach(function (s) { io.observe(s); });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", watch); else watch();
})();
