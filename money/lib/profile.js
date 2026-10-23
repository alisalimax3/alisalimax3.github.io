#!/usr/bin/env node
"use strict";
const fs=require("fs"),path=require("path");
const HERE=path.resolve(__dirname,".."),DATA=path.join(HERE,"data"),OUT=path.join(DATA,"profiles");
fs.mkdirSync(OUT,{recursive:true});
const id=JSON.parse(fs.readFileSync(path.join(DATA,"identity.json"),"utf8"));
// حدود الأحرف الرسمية — حقيقية
const P={
 twitter:[160,"نبذة"],instagram:[150,"نبذة"],tiktok:[80,"نبذة"],threads:[150,"نبذة"],snapchat:[80,"نبذة"],
 youtube:[1000,"حول"],reddit:[200,"ملف"],pinterest:[500,"حول"],telegram:[255,"وصف القناة"],discord:[190,"عني"],
 linkedin:[220,"العنوان"],medium:[160,"نبذة"],tumblr:[200,"نبذة"],facebook:[255,"حول"],quora:[100,"اعتماد"],
 mastodon:[500,"نبذة"],bluesky:[256,"نبذة"],gab:[300,"نبذة"],minds:[255,"نبذة"],vk:[140,"حالة"],
 substack:[200,"حول"],blogger:[500,"حول"],wordpress:[500,"حول"],ghost:[200,"حول"],github:[160,"نبذة"],
 dailymotion:[250,"وصف"],vimeo:[250,"وصف"],rumble:[250,"وصف"],odysee:[250,"وصف"],bitchute:[250,"وصف"],
 hashnode:[200,"نبذة"],devto:[200,"نبذة"],behance:[200,"نبذة"],patreon:[200,"حول"],kofi:[200,"حول"],
 xhamster:[500,"نبذة"],pornhub:[500,"نبذة"],stripchat:[500,"نبذة"],chaturbate:[500,"نبذة"],
 gumroad:[200,"حول"],buymeacoffee:[200,"حول"]};
const cut=(s,n)=>s.length<=n?s:s.slice(0,n-1).replace(/\s\S*$/,"")+"…";
const links=`${id.email.primary}`;
let n=0;
for(const[p,[lim,label]]of Object.entries(P)){
  const ar=cut(`${id.desc_short_ar} ${id.tagline_ar}`,lim);
  const en=cut(`${id.desc_short_en} ${id.tagline_en}`,lim);
  const body=[
   `# ${p} — ${label} (الحد ${lim} حرفًا)`,
   `## عربي (${ar.length}/${lim})`,ar,``,
   `## English (${en.length}/${lim})`,en,``,
   `## الكلمات المفتاحية`,id.keywords_ar.slice(0,8).join(", "),``,
   `## الروابط`,links,``,
   `## الملاحظات`,
   `- استخدم المعرّف: ${id.handle}`,
   `- الصورة: ${id.assets.logo}`,
   `- البانر: ${id.assets.banner}`,
   `- اللون الأساسي: ${id.colors.primary}`
  ].join("\n");
  fs.writeFileSync(path.join(OUT,p+".txt"),body); n++;
}
fs.writeFileSync(path.join(OUT,"_DESCRIPTIONS.md"),[
 `# الأوصاف الطويلة — انسخ كما هي`,
 `## YouTube / Blogger / WordPress (وصف طويل)`,id.desc_long_ar,``,id.desc_long_en,``,
 `## Telegram / Discord (وصف ثابت)`,id.tagline_ar,``,id.tagline_en
].join("\n"));
console.log("  ✔ وُلّدت "+n+" نبذة منصة-مخصّصة في money/data/profiles/");
console.log("  ✔ ملف الأوصاف الطويلة: money/data/profiles/_DESCRIPTIONS.md");
