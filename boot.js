/* CineHub 3099 — شبكة أمان: يمنع أي شاشة سوداء مهما حدث */
(function () {
  "use strict";
  try {
    var st = document.createElement("style");
    st.id = "ch3099-guard";
    st.textContent = "html{visibility:visible!important;background:#070b10}html,body{opacity:1!important}";
    (document.head || document.documentElement).appendChild(st);
  } catch (e) {}
  function shell(){
    try {
      if (document.getElementById("ch3099_fallback")) return;
      var b = document.body; if (!b) return;
      var txt = (b.innerText || "").replace(/\s/g, "");
      if (b.offsetHeight > 60 && txt.length > 0) return;
      var d = document.createElement("div");
      d.id = "ch3099_fallback";
      d.style.cssText = "position:fixed;inset:0;background:#070b10;color:#e9f1f8;padding:22px;" +
        "font-family:system-ui,Tahoma,sans-serif;z-index:99999;overflow:auto;line-height:1.9";
      var links = [["index.html","الرئيسية"],["library.html","المكتبة"],["sites.html","90 ألف موقع"],
                   ["auto.html","شاهد واقبض"],["subscribe.html","الشبكات"],["withdraw.html","السحب"],
                   ["link.html","ربط الحساب"],["live-dash.html","لوحة المتابعة"],["?fresh=1","تصفير كامل"]];
      d.innerHTML = '<h2 style="margin:0 0 6px">الواجهة تعمل</h2>' +
        '<p style="color:#8ea3b8;margin:0 0 12px">اختر صفحة — لن تبقى الشاشة سوداء بعد الآن.</p>' +
        links.map(function(p){
          return '<a style="display:block;padding:11px;margin:7px 0;background:rgba(255,255,255,.06);' +
                 'border-radius:11px;color:#4cc2ff;text-decoration:none" href="' + p[0] + '">' + p[1] + '</a>';
        }).join("");
      b.appendChild(d);
    } catch (e) {}
  }
  function arm(){
    setTimeout(shell, 5000);
    setTimeout(shell, 9000);
    try { window.addEventListener("error", function(){ setTimeout(shell, 1200); }); } catch (e) {}
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", arm);
  else arm();
})();
