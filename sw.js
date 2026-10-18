/* CineHub 3099 — SW آمن: شبكة أولًا لـHTML/JSON، كاش للأصول، ولا يخزّن ملفات التحكم */
var V = "__VER__";
self.addEventListener("install", function(){ self.skipWaiting(); });
self.addEventListener("activate", function(e){
  e.waitUntil(
    caches.keys().then(function(ks){
      return Promise.all(ks.map(function(k){ return (k === V) ? null : caches.delete(k); }));
    }).then(function(){ return self.clients.claim(); })
  );
});
self.addEventListener("fetch", function(e){
  var req = e.request;
  if (req.method !== "GET") return;
  var u = new URL(req.url);
  if (u.origin !== location.origin) return;
  var p = u.pathname;
  if (/sw2?\.js$|killsw\.js$|boot\.js$|reset\.html$/.test(p)) {
    e.respondWith(fetch(req).catch(function(){ return caches.match(req); }));
    return;
  }
  if (/\.html?$/.test(p) || p === "/" || /\.json$/.test(p)) {
    e.respondWith(
      fetch(req).then(function(r){
        var c = r.clone();
        caches.open(V).then(function(ca){ ca.put(req, c); });
        return r;
      }).catch(function(){ return caches.match(req); })
    );
    return;
  }
  e.respondWith(caches.match(req).then(function(hit){
    return hit || fetch(req).then(function(r){
      if (r && r.status === 200 && r.type === "basic") {
        var c = r.clone();
        caches.open(V).then(function(ca){ ca.put(req, c); });
      }
      return r;
    });
  }));
});
