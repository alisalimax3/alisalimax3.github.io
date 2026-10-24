import fs from 'node:fs';
const SNIP='<!--VN-SW4--><script>(function(){if("serviceWorker" in navigator){navigator.serviceWorker.getRegistrations().then(function(rs){rs.forEach(function(r){var u=(r.active&&r.active.sc'])
const S='<!--VN-SW4--><script>(function(){if("serviceWorker" in navigator){navigator.serviceWorker.getRegistrations().then(function(rs){rs.forEach(function(r){var u=(r.active&&r.active.scriptURL)||"";if(u.indexOf("sw4")<0)r.unregister();});}).then(function(){navigator.serviceWorker.register("/sw4.js?v=4");}).catch(function(){});}})();</script>';
let n=0;
for(const f of fs.readdirSync('.').filter(x=>x.endsWith('.html'))){
  if(['index.html','app.html','watch.html','reset.html','404.html'].includes(f))continue;
  let s=fs.readFileSync(f,'utf8');if(s.includes('sw4.js'))continue;
  const i=s.lastIndexOf('</body>');
  s=i>-1?s.slice(0,i)+S+s.slice(i):s+S;
  fs.writeFileSync(f,s);n++;
}
console.log('✓ sw4 مربوط في '+n+' صفحة');
