/* عدّاد حقيقي — Abacus، بلا حساب وبلا كود تتبّع. الأرقام حقيقية لا تقديرية. */
(function () {
"use strict";
var NS = "cinehub-alkazmy-3099";
var BASE = "https://abacus.jasoncameron.dev";
function hit(key){ return fetch(BASE + "/hit/" + NS + "/" + key).then(function(r){return r.json();}).catch(function(){return null;}); }
function getv(key){ return fetch(BASE + "/get/" + NS + "/" + key).then(function(r){return r.json();}).catch(function(){return null;}); }

window.TRACK = hit;

/* عدّ الزيارة مرة واحدة لكل جلسة */
if (!sessionStorage.getItem("ch3099.seen")) {
  sessionStorage.setItem("ch3099.seen", "1");
  hit("views");
}
/* عرض الأرقام الحقيقية في أي عنصر [data-live] */
function show() {
  var nodes = document.querySelectorAll("[data-live]");
  if (!nodes.length) return;
  ["views", "plays"].forEach(function (k) {
    getv(k).then(function (r) {
      if (!r || typeof r.value !== "number") return;
      [].forEach.call(nodes, function (n) {
        if (n.getAttribute("data-live") === k) n.textContent = r.value.toLocaleString("ar-EG");
      });
    });
  });
}
if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", show);
else show();
setInterval(show, 60000);
})();
