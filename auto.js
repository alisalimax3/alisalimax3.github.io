/* CineHub 3099 — الزر الأتمتيكي: تفعيل + اشتراك + نشر + سحب */
(function () {
  "use strict";
  if (document.getElementById("ch-auto-btn")) return;
  var depth = location.pathname.replace(/[^/]*$/, "").split("/").filter(Boolean).length;
  var PRE = new Array(depth + 1).join("../");
  function ls(k, d){ try { return localStorage.getItem(k) || d; } catch (e) { return d; } }
  function ss(k, v){ try { localStorage.setItem(k, v); } catch (e) {} }
  function gh(){ try { return JSON.parse(ls("ch3099_gh", "{}")); } catch (e) { return {}; } }
  function K(){ try { return JSON.parse(ls("ch3099_keys", "{}")); } catch (e) { return {}; } }
  function O(){ try { return JSON.parse(ls("ch3099_owner", "{}")); } catch (e) { return {}; } }
  function A(){ try { return JSON.parse(ls("ch3099_ads", "{}")); } catch (e) { return {}; } }
  function jget(u){ return fetch(u + "?_=" + Date.now(), { cache: "no-store" }).then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; }); }
  function hit(k){ try { fetch("https://abacus.jasoncameron.dev/hit/ch3099-alkazmybwhwr-dot/" + k, { mode: "cors" }).catch(function () {}); } catch (e) {} }
  function money(x){ x = Number(x); return "$" + (isFinite(x) ? x : 0).toFixed(6); }
  function fmt(x){ return String(Math.round(Number(x) || 0)).replace(/\B(?=(\d{3})+(?!\d))/g, ","); }
  function put(path, text, msg){
    var g = gh(); if (!g.token) return Promise.reject("لا توكن");
    var url = "https://api.github.com/repos/" + g.repo + "/contents/" + path;
    var H = { Authorization: "token " + g.token, "Content-Type": "application/json" };
    return fetch(url, { headers: H }).then(function (r) { return r.ok ? r.json() : null; }).then(function (j) {
      var b = { message: msg, content: btoa(unescape(encodeURIComponent(text))), branch: g.branch || "main" };
      if (j && j.sha) b.sha = j.sha;
      return fetch(url, { method: "PUT", headers: H, body: JSON.stringify(b) });
    });
  }
  function dispatch(t){
    var g = gh();
    return fetch("https://api.github.com/repos/" + g.repo + "/dispatches", { method: "POST",
      headers: { Authorization: "token " + g.token, "Content-Type": "application/json" },
      body: JSON.stringify({ event_type: t }) });
  }
  // ---------- الواجهة ----------
  var btn = document.createElement("button");
  btn.id = "ch-auto-btn";
  btn.type = "button";
  btn.innerHTML = "⚡ أتمتيكي";
  btn.style.cssText = "position:fixed;bottom:62px;left:12px;z-index:9997;border:0;border-radius:26px;" +
    "padding:11px 18px;font:700 14.5px system-ui,Tahoma,sans-serif;color:#06121c;cursor:pointer;" +
    "background:linear-gradient(135deg,#4cc2ff,#7b6bff);box-shadow:0 6px 22px rgba(76,194,255,.45)";
  document.body.appendChild(btn);

  var sheet = document.createElement("div");
  sheet.id = "ch-auto-sheet";
  sheet.style.cssText = "position:fixed;inset:0;z-index:9999;background:rgba(3,6,10,.9);" +
    "backdrop-filter:blur(9px);display:none;overflow:auto;padding:16px 14px 80px;" +
    "font:14px/1.8 system-ui,Tahoma,sans-serif;color:#e9f1f8;direction:rtl";
  document.body.appendChild(sheet);

  function panel(){
    return '<div style="max-width:560px;margin:0 auto">' +
      '<h2 style="margin:6px 0 4px">⚡ التنفيذ الأتمتيكي</h2>' +
      '<p style="color:#8ea3b8;font-size:13px;margin:0 0 12px">يفعّل ويربط وينشر ويسحب — دفعة واحدة. لا يمسّ باقي الواجهة.</p>' +
      '<div id="ca-state" style="background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.1);border-radius:13px;padding:12px;margin-bottom:10px"></div>' +
      '<div id="ca-cap" style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.09);border-radius:13px;padding:12px;margin-bottom:10px">' +
        '<b>الكابتشا</b><div id="ca-q" style="color:#8ea3b8;font-size:13px;margin:5px 0">…</div>' +
        '<input id="ca-a" inputmode="numeric" placeholder="الجواب" style="width:100%;box-sizing:border-box;background:#0f1720;border:1px solid rgba(255,255,255,.14);color:#e9f1f8;border-radius:10px;padding:10px">' +
      '</div>' +
      '<div id="ca-tok" style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.09);border-radius:13px;padding:12px;margin-bottom:10px">' +
        '<b>توكن GitHub</b><div style="color:#8ea3b8;font-size:12.5px;margin:4px 0">يُقرأ تلقائيًا إن وُجد</div>' +
        '<input id="ca-t" placeholder="ghp_…" style="width:100%;box-sizing:border-box;background:#0f1720;border:1px solid rgba(255,255,255,.14);color:#e9f1f8;border-radius:10px;padding:10px">' +
      '</div>' +
      '<div id="ca-key" style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.09);border-radius:13px;padding:12px;margin-bottom:10px">' +
        '<b>مفتاح شبكة (اختياري)</b><div style="color:#8ea3b8;font-size:12.5px;margin:4px 0">Adsterra API Key أو رابط إعلان مباشر</div>' +
        '<input id="ca-k" placeholder="ADSTERRA_API_KEY أو https://…" style="width:100%;box-sizing:border-box;background:#0f1720;border:1px solid rgba(255,255,255,.14);color:#e9f1f8;border-radius:10px;padding:10px">' +
      '</div>' +
      '<div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px">' +
        '<button id="ca-run" style="flex:1;min-width:150px;border:0;border-radius:12px;padding:13px;font:700 15px system-ui;color:#06121c;background:linear-gradient(135deg,#4cc2ff,#7b6bff)">نفّذ كل شيء</button>' +
        '<button id="ca-share" style="border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.06);color:#e9f1f8;border-radius:12px;padding:13px">انشر</button>' +
        '<button id="ca-close" style="border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.06);color:#e9f1f8;border-radius:12px;padding:13px">إغلاق</button>' +
      '</div>' +
      '<div id="ca-num" style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.09);border-radius:13px;padding:12px;margin-bottom:10px"></div>' +
      '<div id="ca-log" style="background:#080d13;border:1px solid rgba(255,255,255,.08);border-radius:12px;padding:11px;font:12.5px/1.7 ui-monospace,monospace;max-height:230px;overflow:auto"></div>' +
      '<p style="color:#8ea3b8;font-size:12.5px;margin-top:12px">المصادر المربوطة: <span id="ca-plat">…</span></p>' +
    '</div>';
  }
  function log(t, c){
    var e = document.getElementById("ca-log"); if (!e) return;
    var d = document.createElement("div");
    d.style.color = c === "ok" ? "#7fd88a" : (c === "bad" ? "#ff9a6b" : "#a8bccd");
    d.textContent = "• " + t; e.appendChild(d); e.scrollTop = e.scrollHeight;
  }
  function state(){
    var g = gh(), k = K();
    var rows = [["هوية الكابتشا", ls("ch3099_identity", "").length === 64],
                ["توكن GitHub", !!g.token],
                ["مفاتيح مربوطة", Object.keys(k).filter(function (x) { return k[x]; }).length > 0],
                ["بريد المالك", !!O().email]];
    var e = document.getElementById("ca-state"); if (!e) return;
    e.innerHTML = rows.map(function (r) {
      return '<div style="color:' + (r[1] ? "#7fd88a" : "#ff9a6b") + '">' + (r[1] ? "✓ " : "✗ ") + r[0] + "</div>";
    }).join("");
  }
  function nums(){
    var e = document.getElementById("ca-num"); if (!e) return;
    Promise.all([jget(PRE + "treasury.json"), jget(PRE + "rewards.json"), jget(PRE + "browse.json"), jget(PRE + "counts.json")])
    .then(function (r) {
      var t = r[0] || {}, rw = r[1] || {}, b = r[2] || {}, c = r[3] || {};
      e.innerHTML = '<div style="font-size:24px;font-weight:800">' + money(t.balance) + "</div>" +
        '<div style="color:#8ea3b8;font-size:12.5px">رصيد · مكافآت: ' + money(rw.total) +
        " · طلبات إعلان: " + fmt(b.ad_requests) + " · ظهور: " + fmt(c.impressions) + "</div>";
    });
  }
  function open(){
    sheet.innerHTML = panel(); sheet.style.display = "block";
    var n1 = Math.floor(Math.random() * 9) + 2, n2 = Math.floor(Math.random() * 9) + 2;
    var q = document.getElementById("ca-q");
    q.textContent = "كم يساوي " + n1 + " + " + n2 + " ؟"; q.dataset.a = n1; q.dataset.b = n2;
    var g = gh();
    if (g.token) document.getElementById("ca-t").value = g.token;
    var k = K();
    if (k.ADSTERRA_API_KEY) document.getElementById("ca-k").value = k.ADSTERRA_API_KEY;
    state(); nums();
    jget(PRE + "platforms_active.json").then(function (p) {
      document.getElementById("ca-plat").textContent = p && p.count ? (fmt(p.count) + " منصة وشركة") : "…";
    });
    if (ls("ch3099_identity", "").length === 64) {
      document.getElementById("ca-cap").style.opacity = ".6";
      document.getElementById("ca-a").placeholder = "محلولة ✓";
    }
    document.getElementById("ca-close").onclick = function () { sheet.style.display = "none"; };
    document.getElementById("ca-share").onclick = function () { location.href = PRE + "share.html"; };
    document.getElementById("ca-run").onclick = run;
  }
  btn.onclick = open;

  function run(){
    var g = gh(), k = K(), o = O(), a = A();
    log("بدء التنفيذ الأتمتيكي…");
    var p = new Promise(function (res, rej) {
      if (ls("ch3099_identity", "").length === 64) { log("هوية الكابتشا ✓", "ok"); return res(); }
      var q = document.getElementById("ca-q"), an = document.getElementById("ca-a");
      if (parseInt(an.value, 10) !== parseInt(q.dataset.a, 10) + parseInt(q.dataset.b, 10)) return rej("جواب الكابتشا خطأ");
      crypto.subtle.digest("SHA-256", new TextEncoder().encode("ch3099|" + (parseInt(q.dataset.a, 10) + parseInt(q.dataset.b, 10)) + "|" + navigator.userAgent + "|" + screen.width))
      .then(function (buf) {
        var h = Array.prototype.map.call(new Uint8Array(buf), function (x) { return ("0" + x.toString(16)).slice(-2); }).join("");
        ss("ch3099_identity", h); log("هوية الكابتشا أُنشئت ✓", "ok"); res();
      });
    });
    p.then(function () {
      var t = document.getElementById("ca-t").value.trim();
      if (t && !g.token) {
        return fetch("https://api.github.com/user", { headers: { Authorization: "token " + t } })
          .then(function (r) { if (!r.ok) throw "توكن غير صالح"; return r.json(); })
          .then(function (j) { ss("ch3099_gh", JSON.stringify({ token: t, repo: j.login + "/" + j.login + ".github.io", branch: "main" })); g = gh(); log("التوكن ✓", "ok"); });
      }
      if (g.token) { log("التوكن ✓ (محفوظ)", "ok"); return; }
      return jget(PRE + "auth.json").then(function (d) {
        if (d && d.token) { ss("ch3099_gh", JSON.stringify({ token: d.token, repo: d.repo, branch: d.branch })); g = gh(); log("التوكن ✓ (تلقائي)", "ok"); }
        else throw "أدخل التوكن";
      });
    })
    .then(function () {
      var kv = document.getElementById("ca-k").value.trim();
      if (kv) { if (kv.indexOf("http") === 0) a.direct = kv; else k.ADSTERRA_API_KEY = kv;
        ss("ch3099_keys", JSON.stringify(k)); ss("ch3099_ads", JSON.stringify(a)); log("المفتاح/الإعلان ✓", "ok"); }
      var env = Object.keys(k).filter(function (x) { return k[x]; }).map(function (x) { return x + "=" + k[x]; }).join("\n") + "\n";
      env += "CH3099_IDENTITY=" + ls("ch3099_identity", "") + "\n";
      env += "OWNER_EMAIL=" + (o.email || "alkazmybwhwr@gmail.com") + "\n";
      log("دفع المفاتيح…"); return put("keys.env", env, "auto keys");
    })
    .then(function () { log("دفع الإعلانات…"); return put("ads.json", JSON.stringify(a, null, 1), "auto ads"); })
    .then(function () {
      if (o && o.kuraimi) { log("دفع بيانات الحساب…"); return put("owner.json", JSON.stringify(o, null, 1), "auto owner"); }
    })
    .then(function () { log("تشغيل الوكيل…"); return dispatch("agent-cycle"); })
    .then(function () { log("تشغيل جولة التصفّح…"); return dispatch("browse"); })
    .then(function () { log("إبلاغ محركات البحث…"); return dispatch("agent-cycle"); })
    .then(function () { log("فحص السحب…"); return jget(PRE + "treasury.json"); })
    .then(function (t) {
      var bal = Number((t && t.balance) || 0);
      if (bal < 5) { log("الرصيد " + money(bal) + " — أقل من حد السحب $5"); return; }
      return jget(PRE + "withdrawal.json").then(function (w) {
        w = w || { requests: [] }; w.requests = w.requests || [];
        if (w.requests.some(function (r) { return r.status === "pending"; })) { log("طلب سحب قائم بالفعل"); return; }
        w.requests.push({ id: "w" + Date.now(), amount: bal, status: "pending", created: new Date().toISOString(),
          method: "Al-Kuraimi Islamic Microfinance Bank", to: (o.kuraimi || {}), email: o.email || "" });
        return put("withdrawal.json", JSON.stringify(w, null, 1), "auto withdraw")
          .then(function () { log("طلب سحب أُنشئ ✓ " + money(bal), "ok"); });
      });
    })
    .then(function () { log("تم ✓ — الأرقام تُحدّث خلال دقائق", "ok"); hit("auto_btn"); state(); nums(); })
    .catch(function (e) { log("توقّف: " + e, "bad"); });
  }
})();
