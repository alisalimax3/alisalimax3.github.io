#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path"),crypto=require("crypto");
const HERE=path.resolve(__dirname,".."),ROOT=path.resolve(HERE,".."),DATA=path.join(HERE,"data");
const KEYS=path.join(ROOT,"keys.env"),ID=path.join(DATA,"identity.json");
const codes=require("./codes.js"),totp=require("./totp.js");
fs.mkdirSync(DATA,{recursive:true});
if(fs.existsSync(ID)){const x=JSON.parse(fs.readFileSync(ID,"utf8"));console.log("  ✔ هوية موجودة: "+x.brand+" ("+x.handle+")");process.exit(0);}
const brand="CineHub";
const suffix=process.env.SUFFIX||String(crypto.randomInt(100,999));
const handle="cinehub"+suffix;
const pass=crypto.randomBytes(9).toString("base64url")+"!Aa9";
const secret=totp.gen();
const id={brand,slug:"cinehub",handle,handleHQ:"CineHubHQ",handleOfficial:"CineHubOfficial",
 tagline_ar:`${brand} — أفلام ومسلسلات بجودة عالية، بلا إعلانات مزعجة.`,
 tagline_en:`${brand} — Movies & series in HD, zero annoying ads.`,
 desc_short_ar:"مشاهدة أفلام ومسلسلات مترجمة أونلاين بجودة عالية وسيرفرات سريعة.",
 desc_short_en:"Watch HD movies and subtitled series online, fast servers, daily updates.",
 desc_long_ar:`${brand} منصة لمشاهدة الأفلام والمسلسلات المترجمة أونلاين بجودة 1080p و4K.\nسيرفرات سريعة، تحديث يومي، ترجمة احترافية، واجهة خفيفة تعمل على أي جهاز.\nيشمل: أفلام أجنبية وعربية، مسلسلات تركية، أنمي، ومسلسلات رمضان.\nبلا تسجيل إجباري — افتح واعرض.`,
 desc_long_en:`${brand} is a streaming index for HD movies and subtitled series.\nFast servers, daily updates, clean UI, works on any device.\nGenres: action, horror, sci-fi, animation, K-drama, anime, Arabic classics.\nNo forced signup.`,
 keywords_ar:["افلام اون لاين","مسلسلات مترجمة","افلام 2026","انمي مترجم","افلام عربية","مسلسلات تركية","مشاهدة مباشرة","افلام 4k"],
 keywords_en:["watch movies online","hd movies","subtitled series","anime","korean drama","free streaming"],
 colors:{primary:"#2563eb",accent:"#7dd3fc",bg:"#0b0e14",text:"#e8eef7"},
 email:{primary:`${handle}@gmail.com`,support:`support.${handle}@gmail.com`,legal:`legal.${handle}@gmail.com`,abuse:`abuse.${handle}@gmail.com`},
 password:pass,totp_secret:secret,totp_url:totp.url(secret,`${brand}:${handle}`,brand),
 security:{pet:"Nile",city:"Cairo",school:"AlNoor",color:"Blue",car:"Toyota"},
 usernames:[handle,"CineHubHQ","CineHubTV","CineHubOfficial","cinehub.app"],
 assets:{logo:"money/assets/logo.png",banner:"money/assets/banner.png"},
 created:new Date().toISOString()};
fs.writeFileSync(ID,JSON.stringify(id,null,2));
const map={BRAND_NAME:brand,BRAND_SLUG:"cinehub",BRAND_HANDLE:handle,BRAND_TAGLINE_AR:id.tagline_ar,BRAND_TAGLINE_EN:id.tagline_en,
 BRAND_DESC_AR:id.desc_long_ar.replace(/\n/g," "),BRAND_DESC_EN:id.desc_long_en.replace(/\n/g," "),
 BRAND_KEYWORDS:id.keywords_ar.join(","),BRAND_KEYWORDS_EN:id.keywords_en.join(","),BRAND_COLOR:id.colors.primary,
 MASTER_PASSWORD:pass,TOTP_SECRET:secret,TOTP_URL:id.totp_url,CONTACT_EMAIL:id.email.primary,SUPPORT_EMAIL:id.email.support,
 SEC_ANSWERS:JSON.stringify(id.security)};
let t="";try{t=fs.readFileSync(KEYS,"utf8");}catch(e){}
for(const[k,v]of Object.entries(map)){const re=new RegExp("^"+k+"=.*$","m");t=re.test(t)?t.replace(re,k+"="+v):t+((t&&!t.endsWith("\n"))?"\n":"")+k+"="+v+"\n";}
const tmp=KEYS+"."+process.pid+".tmp";fs.writeFileSync(tmp,t);fs.renameSync(tmp,KEYS);try{fs.chmodSync(KEYS,0o600);}catch(e){}
codes.save("الهوية التجارية",{العلامة:brand,"المعرّف":handle,"البريد":id.email.primary,"كلمة المرور الرئيسية":pass,
 "سر 2FA":secret,"رابط 2FA":id.totp_url,"الأجوبة الأمنية":JSON.stringify(id.security)});
console.log("  ✔ الهوية: "+brand+" ("+handle+")");
console.log("  ✔ بريد + كلمة مرور رئيسية + سر 2FA — واحد لكل المنصات");
console.log("  ✔ رمز 2FA الحالي (للتحقق): "+totp.code(secret));
console.log("  ⚠ أضف السر في Google Authenticator الآن، وقارن الرمز.");
