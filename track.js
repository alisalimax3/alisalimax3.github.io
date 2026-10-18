/* CineHub 3099 — عدّاد حقيقي: زيارة + ظهور لكل مساحة إعلانية */
(function () {
  "use strict";
  var NS = "ch3099-alkazmybwhwr-dot";
  function hit(k) {
    try {
      fetch("https://abacus.jasoncameron.dev/hit/" + NS + "/" + k, { mode: "cors", cache: "no-store" })
        .catch(function () {
          fetch("https://api.counterapi.dev/v1/" + NS + "/" + k + "/up", { mode: "cors" }).catch(function () {});
        });
    } catch (e) {}
  }
  try {
    if (!sessionStorage.getItem("ch3099_v")) { sessionStorage.setItem("ch3099_v", "1"); hit("visits"); }
  } catch (e) { hit("visits"); }
  function once(k) {
    try { var s = sessionStorage.getItem("ch3099_" + k); if (s) return false; sessionStorage.setItem("ch3099_" + k, "1"); return true; }
    catch (e) { return true; }
  }
  function watch() {
    var slots = document.querySelectorAll("[data-ad], .ad, .adslot, #ad, ins.adsbygoogle");
    if (!slots.length) return;
    if (!("IntersectionObserver" in window)) { if (once("imp")) hit("impressions"); return; }
    var seen = 0;
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (e.isIntersecting && seen < 6 && once("imp" + seen)) { seen++; hit("impressions"); }
      });
    }, { threshold: 0.4 });
    Array.prototype.slice.call(slots).slice(0, 6).forEach(function (s) { io.observe(s); });
  }
  document.addEventListener("click", function (e) {
    var a = e.target && e.target.closest ? e.target.closest("a") : null;
    if (a && /adsterra|monetag|linkvertise|shrink|bitlabs|cpx|offertoro|cpagrip|ogads/i.test(a.href || "")) hit("clicks");
  }, true);
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", watch); else watch();
})();
