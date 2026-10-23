const https=require('https'),fs=require('fs'),path=require('path');const AX=process.argv[2];
const E=[
 ['yts','https://yts.mx/api/v2/list_movies.json?limit=1'],
 ['tvmaze','https://api.tvmaze.com/search/shows?q=girls'],
 ['jikan','https://api.jikan.moe/v4/anime/1'],
 ['kitsu','https://kitsu.io/api/edge/anime?page[limit]=1'],
 ['coingecko','https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd'],
 ['erapi','https://open.er-api.com/v6/latest/USD'],
 ['fawaz','https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json'],
 ['frankfurter','https://api.frankfurter.app/latest?from=USD&to=EUR'],
 ['wikipedia','https://en.wikipedia.org/api/rest_v1/page/summary/Termux'],
 ['archive','https://archive.org/advancedsearch.php?q=termux&fl[]=identifier&rows=1&output=json'],
 ['defillama','https://api.llama.fi/chains'],
 ['osm','https://nominatim.openstreetmap.org/search?q=Aden&format=json&limit=1'],
 ['itunes','https://itunes.apple.com/search?term=termux&limit=1'],
 ['openlib','https://openlibrary.org/search.json?q=termux&limit=1'],
 ['spacex','https://api.spacexdata.com/v4/launches/latest'],
 ['github','https://api.github.com/repos/termux/termux-app'],
 ['npm','https://registry.npmjs.org/express/latest'],
 ['pypi','https://pypi.org/pypi/requests/json'],
 ['openmeteo','https://api.open-meteo.com/v1/forecast?latitude=12.79&longitude=45.03&current=temperature_2m'],
 ['ipify','https://api.ipify.org?format=json'],
 ['sunsun','https://api.sunrise-sunset.org/json?lat=12.79&lng=45.03'],
 ['restcountries','https://restcountries.com/v3.1/alpha/ye'],
 ['holidays','https://date.nager.at/api/v3/PublicHolidays/2026/YE'],
 ['datamuse','https://api.datamuse.com/words?ml=earn'],
 ['rickmorty','https://rickandmortyapi.com/api/character/1'],
 ['swapi','https://swapi.dev/api/people/1'],
 ['catapi','https://api.thecatapi.com/v1/images/search'],
 ['dogceo','https://dog.ceo/api/breeds/image/random'],
 ['zippo','https://api.zippopotam.us/us/90210'],
 ['freeip','https://freeipapi.com/api/json'],
 ['blockchain','https://blockchain.info/ticker'],
 ['mempool','https://mempool.space/api/blocks/tip/height'],
 ['trongrid','https://api.trongrid.io/wallet/getnowblock'],
 ['dummyjson','https://dummyjson.com/products/1'],
 ['fakestore','https://fakestoreapi.com/products/1'],
 ['jsonph','https://jsonplaceholder.typicode.com/posts/1']
];
function get(u){return new Promise(r=>{const t=Date.now();
 https.get(u,{timeout:12000,headers:{'User-Agent':'APEX/1.0','Accept':'application/json, */*'}},s=>{
  let n=0;s.on('data',c=>n+=c.length);s.on('end',()=>r({code:s.statusCode,ms:Date.now()-t,bytes:n}));
 }).on('error',e=>r({code:0,err:e.code||e.message,ms:Date.now()-t})).on('timeout',function(){this.destroy();r({code:0,err:'timeout',ms:Date.now()-t})});});}
(async()=>{const out=[];
 await Promise.all(E.map(async([k,u])=>{const r=await get(u);out.push({key:k,url:u,code:r.code,ok:!!(r.code>=200&&r.code<400),ms:r.ms,bytes:r.bytes||0});}));
 const ok=out.filter(x=>x.ok).length;
 fs.writeFileSync(path.join(AX,'state/integrations.json'),JSON.stringify({ts:new Date().toISOString(),total:out.length,working:ok,sources:out.sort((a,b)=>a.key.localeCompare(b.key))},null,1));
 console.log('integrations_live='+ok+'/'+out.length);})();
