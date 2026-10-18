/** CineHub 3099 · Google Apps Script backend — انسخه في script.google.com ثم Deploy → Web app (Anyone) */
const SHEET_ID='';            // معرّف جدول Google Sheets
const OWNER_EMAIL='';         // بريدك
const TG_TOKEN=''; const TG_CHAT='';
const TURNSTILE_SECRET='';
function ss_(){return SpreadsheetApp.openById(SHEET_ID)}
function sh_(n){var s=ss_().getSheetByName(n);if(!s){s=ss_().insertSheet(n);s.appendRow(['at','type','uid','ref','amount','method','name','account','phone','status','payload'])}return s}
function notify_(t){if(TG_TOKEN&&TG_CHAT){try{UrlFetchApp.fetch('https://api.telegram.org/bot'+TG_TOKEN+'/sendMessage',
 {method:'post',payload:{chat_id:TG_CHAT,text:t}})}catch(e){}}if(OWNER_EMAIL){try{MailApp.sendEmail(OWNER_EMAIL,'CineHub 3099',t)}catch(e){}}}
function verify_(token){if(!TURNSTILE_SECRET)return true;
 try{var r=UrlFetchApp.fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',
  {method:'post',payload:{secret:TURNSTILE_SECRET,response:token}});return JSON.parse(r.getContentText()).success===true}catch(e){return true}}
function doPost(e){
 var b={};try{b=JSON.parse(e.postData.contents)}catch(x){return out_({ok:false,why:'bad json'})}
 var s=sh_(b.type||'events');
 if(b.type==='verify'){return out_({ok:verify_(b.token)})}
 if(b.type==='payout'){var p=b.payload||{};s.appendRow([new Date(),'payout',p.uid,p.ref,p.amount,p.method_label,p.name,p.account,p.phone,'pending',JSON.stringify(p)]);
  notify_('💸 طلب سحب $'+p.amount+'\n'+p.name+'\n'+p.account+'\n'+p.phone+'\n'+p.method_label+'\n'+p.ref);return out_({ok:true,ref:p.ref})}
 if(b.type==='subscribe'){s.appendRow([new Date(),'subscribe',b.uid,b.ref,b.amount,b.plan,b.name,b.account,b.phone,'pending',JSON.stringify(b.payload||{})]);
  notify_('⭐ اشتراك '+b.plan+' $'+b.amount+'\n'+(b.name||''));return out_({ok:true})}
 if(b.type==='event'){s.appendRow([new Date(),b.kind||'event',b.uid,'','','','','','','',JSON.stringify(b.payload||{})]);return out_({ok:true})}
 return out_({ok:true})}
function doGet(e){var a=(e&&e.parameter&&e.parameter.action)||'ping';
 if(a==='list'){var s=sh_('payout');var v=s.getDataRange().getValues();return out_({ok:true,rows:v.slice(-100)})}
 if(a==='stats'){return out_({ok:true,sheets:ss_().getSheets().map(function(x){return x.getName()})})}
 return out_({ok:true,pong:new Date()})}
function out_(o){return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON)}
