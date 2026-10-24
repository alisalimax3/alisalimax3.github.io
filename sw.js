/* CineHub SW v3 */
const V='cinehub-v3';
self.addEventListener('install',e=>self.skipWaiting());
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;
 const u=new URL(r.url);if(u.origin!==location.origin)return;
 const data=/\.json$/i.test(u.pathname)||/\.html$/i.test(u.pathname)||u.pathname==='/';
 if(data){e.respondWith(fetch(r).then(res=>{const c=res.clone();caches.open(V).then(x=>x.put(r,c));return res}).catch(()=>caches.match(r)));}
 else{e.respondWith(caches.match(r).then(c=>c||fetch(r).then(res=>{const cc=res.clone();caches.open(V).then(x=>x.put(r,cc));return res})));}});
