const C = 'cinehub-3099-v1';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET') return;
  let u; try { u = new URL(r.url); } catch (x) { return; }
  if (u.origin !== location.origin) return;
  const dyn = /\.(json|xml)$/.test(u.pathname);
  if (dyn) {
    e.respondWith(fetch(r).then(x => { const c = x.clone(); caches.open(C).then(k => k.put(r, c)); return x; })
      .catch(() => caches.match(r)));
  } else {
    e.respondWith(caches.match(r).then(c => c || fetch(r).then(x => {
      const cl = x.clone(); caches.open(C).then(k => k.put(r, cl)); return x;
    })));
  }
});
