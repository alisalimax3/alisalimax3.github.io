/* CineHub 3099 — عدّاد سيرفري (Abacus) · بلا كوكيز · بلا تسجيل */
(function () {
  var NS = "cinehub3099-alisalimax3", API = "https://abacus.jasoncameron.dev";
  function safe(k) { return k.replace(/[^A-Za-z0-9._-]/g, "-").replace(/-{2,}/g, "-"); }
  function vid() { try { var v = localStorage.getItem("ch_vid");
    if (!v) { v = Math.random().toString(36).slice(2, 10) + Date.now().toString(36); localStorage.setItem("ch_vid", v); }
    return v; } catch (e) { return "anon"; } }
  function hit(k) { return fetch(API + "/hit/" + safe(k)).then(function (r) { return r.json(); })
    .then(function (j) { return j && j.value; }).catch(function () { return null; }); }
  function get(k) { return fetch(API + "/get/" + safe(k)).then(function (r) { return r.json(); })
    .then(function (j) { return j && j.value; }).catch(function () { return null; }); }
  var d = new Date().toISOString().slice(0, 10);
  var path = safe(location.pathname.replace(/\/index\.html$/, "/") || "/");
  try { var q = new URLSearchParams(location.search);
    var rf = q.get("ref"); if (rf) localStorage.setItem("ch_ref", rf.slice(0, 24));
    var s1 = q.get("utm_source"); if (s1) localStorage.setItem("ch_src", s1.slice(0, 24));
    var c1 = q.get("utm_campaign"); if (c1) localStorage.setItem("ch_cmp", c1.slice(0, 24)); } catch (e) {}
  window.CH = { ns: NS, vid: vid, hit: hit, get: get, today: d,
    pv: "pv" + path, dv: "dv-" + d, uvtoday: "uniq-" + d, claims: "claims" };
  hit(window.CH.pv); hit(window.CH.dv);
  hit(NS + "/uv-" + d + "-" + vid()).then(function (v) { if (v === 1) hit(NS + "/uniq-" + d); });
  document.addEventListener("DOMContentLoaded", function () {
    var el = document.querySelectorAll("[data-hits]");
    for (var i = 0; i < el.length; i++) (function (n) {
      get(window.CH[n.getAttribute("data-hits")]).then(function (v) {
        if (v !== null && v !== undefined) n.textContent = v; }); })(el[i]);
  });
})();
