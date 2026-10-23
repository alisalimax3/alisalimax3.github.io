const fs=require('fs'),path=require('path');const AX=process.argv[2];
const P=JSON.parse(fs.readFileSync(path.join(AX,'registry/platforms.json'),'utf8'));
let R=[]; try{R=fs.readFileSync(path.join(AX,'registry/verified.jsonl'),'utf8').split('\n').filter(Boolean).map(JSON.parse)}catch(e){}
const byId={};R.forEach(r=>{(byId[r.id]=byId[r.id]||[]).push(r)});
const cats={},live=[],dead=[];
P.platforms.forEach(p=>{const rs=byId[p.id]||[];const reach=rs.filter(x=>x.reachable);
 if(reach.length){live.push({id:p.id,domain:p.domain,cat:p.cat,method:p.method,min:p.min,tier:p.tier,ye:p.ye,points:reach.length,kinds:[...new Set(reach.map(x=>x.kind))]});}
 else dead.push({id:p.id,domain:p.domain});
 cats[p.cat]=(cats[p.cat]||0)+1;});
const points=R.filter(x=>x.reachable).length;
const s={ts:new Date().toISOString(),platforms_total:P.platforms.length,platforms_reachable:live.length,
 platforms_unreachable:dead.length,connection_points_probed:R.length,connection_points_verified:points,
 live_apis:R.filter(x=>['api','api2'].includes(x.kind)&&x.reachable).length,
 by_category:cats, ye_actionable:live.filter(x=>x.ye>=1).length, platforms:live, dead:dead.slice(0,80)};
fs.writeFileSync(path.join(AX,'registry/summary.json'),JSON.stringify(s,null,1));
console.log('platforms='+s.platforms_total+' reachable='+s.platforms_reachable+' points_verified='+points+' ye_actionable='+s.ye_actionable);
