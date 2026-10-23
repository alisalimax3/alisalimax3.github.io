const https=require('https'),fs=require('fs'),path=require('path');const AX=process.argv[2];
const R=(host,p,m,body,tok)=>new Promise(r=>{const b=body?JSON.stringify(body):null;
 const h={'Accept':'application/json','Content-Type':'application/json','User-Agent':'Mozilla/5.0 APEX'};if(tok)h.Authorization='Bearer '+tok;if(b)h['Content-Length']=Buffer.byteLength(b);
 const q=https.request({host,path:p,method:m,headers:h,timeout:15000},s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>{let j=null;try{j=JSON.parse(d)}catch(e){}r({code:s.statusCode,json:j})})});
 q.on('error',e=>r({code:0,err:e.code}));q.on('timeout',()=>{q.destroy();r({code:0,err:'timeout'})});if(b)q.write(b);q.end();});
const G=u=>new Promise(r=>{https.get(u,{timeout:15000,headers:{'User-Agent':'Mozilla/5.0 APEX'}},s=>{let d='';s.on('data',c=>d+=c);s.on('end',()=>{let j=null;try{j=JSON.parse(d)}catch(e){}r({code:s.statusCode,json:j})})}).on('error',()=>r({code:0})).on('timeout',function(){this.destroy();r({code:0})});});
const rnd=n=>Math.random().toString(36).slice(2,2+n);
(async()=>{
 const st={ts:new Date().toISOString(),providers:[],address:null,messages:[]};
 // 1) 1secmail — بلا تسجيل
 try{
  const dl=await G('https://www.1secmail.com/api/v1/?action=getDomainList');
  if(dl.code===200&&Array.isArray(dl.json)&&dl.json.length){
   const login='cinehub'+rnd(7), dom=dl.json[0];
   const ms=await G('https://www.1secmail.com/api/v1/?action=getMessages&login='+login+'&domain='+dom);
   st.providers.push({host:'1secmail',ok:true,address:login+'@'+dom});
   st.address=login+'@'+dom; st.provider='1secmail'; st.login=login; st.domain=dom;
   if(ms.code===200&&Array.isArray(ms.json))st.messages=ms.json;
  } else st.providers.push({host:'1secmail',code:dl.code});
 }catch(e){st.providers.push({host:'1secmail',err:e.message});}
 // 2) mail.gw / mail.tm
 if(!st.address) for(const host of ['api.mail.gw','api.mail.tm']){
  const dm=await R(host,'/domains','GET');
  if(dm.code!==200||!dm.json||!dm.json['hydra:member']){st.providers.push({host,step:'domains',code:dm.code});continue;}
  const l=dm.json['hydra:member'].filter(x=>x.isActive!==false&&x.isPrivate!==true);
  if(!l.length){st.providers.push({host,step:'no-domain'});continue;}
  const a='cinehub'+rnd(7)+'@'+l[0].domain, pw='Apex'+rnd(8)+'!9';
  const c=await R(host,'/accounts','POST',{address:a,password:pw});
  if(![200,201].includes(c.code)){st.providers.push({host,step:'create',code:c.code});continue;}
  const t=await R(host,'/token','POST',{address:a,password:pw});
  if(t.code!==200||!t.json||!t.json.token){st.providers.push({host,step:'token',code:t.code});continue;}
  st.address=a;st.provider=host;st.password=pw;
  st.providers.push({host,ok:true,address:a});break;}
 // 3) temp-mail.io
 if(!st.address){ try{
  const n=await R('api.internal.temp-mail.io','/api/v3/email/new','POST',{name:'cinehub'+rnd(6),domain:'','expires_in':86400});
  if(n.code===200&&n.json&&n.json.email){st.address=n.json.email;st.provider='temp-mail.io';st.token=n.json.token;
   st.providers.push({host:'temp-mail.io',ok:true,address:st.address});}
 }catch(e){} }
 fs.writeFileSync(path.join(AX,'state/mailbox.json'),JSON.stringify(st,null,1));
 console.log('mailbox='+(st.address||'FAILED')+' via='+(st.provider||'-'));})();
