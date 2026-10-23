#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),tls=require("tls");
const H=path.resolve(__dirname,".."),ROOT=path.resolve(H,".."),D=path.join(H,"data");
const K=require("./akeys.js"),N=require("./anotify.js"),codes=require("./acodes.js");
const TARGETS=[["youtube.com","يوتيوب"],["reddit.com","ريديت"],["medium.com","ميديوم"],["quora.com","كورا"],["tumblr.com","تمبلر"],["blogger.com","بلوجر"],["wordpress.com","ووردبريس"],["vk.com","VK"],["pinterest.com","بينترست"],["github.com","جيت هب"],["dev.to","ديف"],["hashnode.dev","هاشنود"],["substack.com","سبستاك"],["mastodon.social","ماستودون"],["x.com","إكس"]];
function list(){return TARGETS.map(([h,n])=>({host:h,name:n,
  subject:"مشاهدة أفلام ومسلسلات مترجمة بجودة عالية — CineHub",
  body:"مرحبًا،\n\nأنا "+(K.get("BRAND_NAME")||"CineHub")+" — منصة أفلام ومسلسلات وأنمي مترجم.\n"+
  "الرابط: "+(K.get("PUBLIC_URL")||"")+"\n\nيسعدني تبادل الإشارات/الظهور إن كان لديك محتوى مشابه.\n\nتحياتي"}));}
function write(){const l=list();fs.writeFileSync(path.join(D,"outreach.json"),JSON.stringify({at:new Date().toISOString(),targets:l},null,1));return l;}
function smtpSend(to,subject,body){return new Promise(res=>{
  const host=K.get("SMTP_HOST"),port=Number(K.get("SMTP_PORT")||465),user=K.get("SMTP_USER"),pass=K.get("SMTP_PASS");
  if(!host||!user)return res("○ لا SMTP");
  const from=K.get("CONTACT_EMAIL")||user;let step=0;
  const c=tls.connect({host,port,servername:host},()=>{});
  const send=l=>c.write(l+"\r\n");
  const b64=s=>Buffer.from(s).toString("base64");
  c.on("data",d=>{const s=d.toString();
    if(step===0&&/^220/.test(s)){send("EHLO apex");step=1;return;}
    if(step===1&&/^250/.test(s)&&/AUTH/.test(s)){send("AUTH LOGIN");step=2;return;}
    if(step===1&&/^250/.test(s)){send("AUTH LOGIN");step=2;return;}
    if(step===2&&/^334/.test(s)){send(b64(user));step=3;return;}
    if(step===3&&/^334/.test(s)){send(b64(pass));step=4;return;}
    if(step===4&&/^235/.test(s)){send("MAIL FROM:<"+from+">");step=5;return;}
    if(step===5&&/^250/.test(s)){send("RCPT TO:<"+to+">");step=6;return;}
    if(step===6&&/^250/.test(s)){send("DATA");step=7;return;}
    if(step===7&&/^354/.test(s)){send("Subject: "+subject+"\r\nFrom: "+from+"\r\nTo: "+to+"\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n"+body+"\r\n.");step=8;return;}
    if(step===8&&/^250/.test(s)){send("QUIT");c.end();return res("✔ أُرسل إلى "+to);}
    if(/^5\d\d/.test(s)&&step<5){c.end();return res("✗ "+s.trim().slice(0,60));}});
  c.on("error",e=>res("✗ "+(e.message||e)));
  setTimeout(()=>{try{c.end();}catch(e){}res("○ انتهت المهلة");},30000);});}
(async()=>{const l=write();console.log("  ✔ قائمة تواصل: "+l.length+" منصة → money/data/outreach.json");
  if(process.argv[2]==="send"){for(const t of l){const r=await smtpSend(K.get("CONTACT_EMAIL"),t.subject,t.body);console.log("   "+r);}}
  else console.log("  → للإرسال: أضف SMTP_HOST/SMTP_USER/SMTP_PASS ثم bash money/APEX.sh outreach send");
  codes.save("تواصل خارجي",{عدد:l.length});await N.toast("✔ تواصل خارجي: "+l.length);})();
