const V='cinehub4';
self.addEventListener('install',e=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(
  caches.keys().then(k=>Promise.all(k.map(x=>caches.delete(x)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;
 const u=new URL(r.url);if(u.origin!==location.origin)return;
 const d=/\.json$/.test(u.pathname)||/\.html$/.test(u.pathname)||u.pathname==='/';
 if(d){e.respondWith(fetch(r).then(res=>{const c=res.clone();caches.open(V).then(x=>x.put(r,c));return res}).catch(()=>caches.match(r)));}
 else{e.respondWith(caches.match(r).then(c=>c||fetch(r).then(res=>{const cc=res.clone();caches.open(V).then(x=>x.put(r,cc));return res})));}});
