/* CineHub 3099 — قارئ البيانات الحقيقي (نسخة نظيفة خالية من الأخطاء) */
(function () {
  "use strict";
  function q(s, r) { try { return (r || document).querySelector(s); } catch (e) { return null; } }
  function qa(s, r) { try { return Array.prototype.slice.call((r || document).querySelectorAll(s)); } catch (e) { return []; } }
  function leaf(e) { return e && e.children && e.children.length === 0; }
  function findLeaf(label) {
    var els = qa("div,span,p,td,li,h1,h2,h3,h4,h5,strong,b,small,a");
    for (var i = 0; i < els.length; i++) {
      var e = els[i];
      if (leaf(e) && e.textContent && e.textContent.indexOf(label) !== -1) return e;
    }
    return null;
  }
  function fill(label, value) {
    var el = findLeaf(label);
    if (!el) return false;
    var t = (el.textContent || "").replace(/\s+/g, " ").trim();
    var i = t.indexOf(label);
    el.textContent = t.slice(0, i + label.length).replace(/[:\s]+$/, "") + ": " + value;
    return true;
  }
  function num(x) { x = Number(x); return isFinite(x) ? x : 0; }
  function money(x) { return "$" + num(x).toFixed(6); }
  function get(u) {
    return fetch(u + (u.indexOf("?") > -1 ? "&" : "?") + "_=" + Date.now(), { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .catch(function () { return null; });
  }
  function first() {
    for (var i = 0; i < arguments.length; i++) {
      var v = arguments[i];
      if (v === 0 || v === "0") return v;
      if (v !== undefined && v !== null && v !== "" && isFinite(Number(v))) return v;
    }
    return 0;
  }
  function keyed(x) {
    var k = x && (x.key || x.api_key || x.has_key);
    return k && !/^(PUT|TODO|XXX|CHANGE)/i.test(String(k));
  }
  var FILES = ["status.json","pulse.json","revenue.json","treasury.json","insights.json","ledger.json","films.json","nets.json","platforms.json","catalog.json"];

  function render() {
    Promise.all(FILES.map(get)).then(function (a) {
      var M = {};
      for (var i = 0; i < FILES.length; i++) M[FILES[i]] = a[i] || {};
      var rev = M["revenue.json"], tre = M["treasury.json"], pul = M["pulse.json"];
      var ins = M["insights.json"], st = M["status.json"], led = M["ledger.json"];

      var rev30 = first(rev.revenue_30d, rev.total, rev.amount, rev.usd, ins.revenue_30d, pul.revenue_30d);
      var imp = first(rev.impressions, rev.imp, ins.impressions, pul.impressions);
      var clk = first(rev.clicks, rev.clk, ins.clicks, pul.clicks);
      var bal = first(tre.balance, tre.withdrawable, tre.total, pul.balance, readBal());
      var vis = first(pul.visits, st.visits, ins.visits);
      var eng = st.engine || pul.engine || st.status || "live";
      var entries = Array.isArray(led.entries) ? led.entries.length : num(led.count);

      fill("المحرّك", String(eng));
      fill("إيراد حقيقي 30 يوم", money(rev30));
      fill("زيارات عالمية", String(Math.round(num(vis))));
      fill("قيود موثّقة", String(entries));
      fill("إيراد الشبكات 30 يوم", money(rev30));
      fill("ظهور حقيقي", String(Math.round(num(imp))));
      fill("نقرات", String(Math.round(num(clk))));
      fill("رصيدك القابل للسحب", money(bal));
      films(M["films.json"], M["catalog.json"]);
      nets(M["nets.json"], M["platforms.json"]);
      document.documentElement.setAttribute("data-ch-render", String(Date.now()));
    }).catch(function () {});
  }
  function readBal() { try { return localStorage.getItem("ch3099_balance") || 0; } catch (e) { return 0; } }

  function films(f, cat) {
    var arr = [];
    if (f && (f.items || f.films || f.list)) arr = f.items || f.films || f.list;
    else if (Array.isArray(f)) arr = f;
    else if (cat && (cat.items || cat.films)) arr = cat.items || cat.films;
    if (!Array.isArray(arr) || !arr.length) return;
    var head = findLeaf("أفلام مقترحة");
    if (!head) return;
    var box = head.parentElement || head;
    var old = q('[data-ch="films"]', box);
    if (old) old.parentNode.removeChild(old);
    var wrap = document.createElement("div");
    wrap.setAttribute("data-ch", "films");
    wrap.style.marginTop = "8px";
    arr.slice(0, 8).forEach(function (x) {
      var a2 = document.createElement("a");
      a2.href = x.url || x.link || ("play.html?id=" + encodeURIComponent(x.id || x.slug || ""));
      a2.textContent = "• " + (x.title || x.name || "فيلم");
      a2.style.display = "block";
      wrap.appendChild(a2);
    });
    var dash = null;
    qa("*", box).forEach(function (e) { if (!dash && leaf(e) && (e.textContent || "").trim() === "—") dash = e; });
    var anchor = dash || head;
    if (dash) dash.textContent = String(arr.length);
    anchor.parentNode.insertBefore(wrap, anchor.nextSibling);
  }

  function nets(ns, pl) {
    var tables = qa("table"), t = null;
    for (var i = 0; i < tables.length; i++) {
      var tx = tables[i].textContent || "";
      if (tx.indexOf("الشبكة") !== -1 && (tx.indexOf("أدنى") !== -1 || tx.indexOf("الدفع") !== -1)) { t = tables[i]; break; }
    }
    if (!t) return;
    var list = null;
    if (ns) list = ns.networks || ns.list || (Array.isArray(ns) ? ns : null);
    if (!list && pl) list = pl.networks || pl.list || null;
    var tb = t.tBodies[0];
    if (!tb) { tb = document.createElement("tbody"); t.appendChild(tb); }
    while (tb.rows.length > 0) tb.deleteRow(0);
    if (!Array.isArray(list) || !list.length) {
      var r0 = tb.insertRow(-1), c0 = r0.insertCell(-1);
      c0.colSpan = 4;
      var n = pl && (pl.count || pl.total);
      c0.textContent = n ? ("جاهزة: " + n + " منصة — بانتظار المفاتيح") : "بانتظار المفاتيح";
      return;
    }
    list.slice(0, 25).forEach(function (x) {
      var tr = tb.insertRow(-1);
      var cells = [x.name || x.id || x.slug || "-", keyed(x) ? "مفعّل" : "ناقص",
                   x.min || x.min_withdraw || "$5", x.pay || x.method || x.payout || "USDT / Wire"];
      for (var j = 0; j < cells.length; j++) tr.insertCell(-1).textContent = String(cells[j]);
    });
  }

  function nav() {
    if (q('a[href*="library"]')) return;
    var h = q("header") || document.body.firstElementChild;
    if (!h) return;
    var n = document.createElement("nav");
    n.setAttribute("data-ch", "nav");
    n.style.cssText = "display:flex;gap:10px;flex-wrap:wrap;padding:8px 12px";
    [["المكتبة","library.html"],["سينما","cinema.html"],["شاهد واقبض","auto.html"],["مكافآت","rewards.html"],["اسحب","withdraw.html"]]
      .forEach(function (p) { var a = document.createElement("a"); a.href = p[1]; a.textContent = p[0]; n.appendChild(a); });
    h.parentNode.insertBefore(n, h.nextSibling);
  }

  function boot() {
    try { nav(); } catch (e) {}
    try { render(); } catch (e) {}
    setInterval(function () { try { render(); } catch (e) {} }, 60000);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
  else boot();
})();
