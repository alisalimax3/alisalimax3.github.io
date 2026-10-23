#!/usr/bin/env node
"use strict";
const R=[];const r=o=>{R.push(o);return o;};
const h=d=>{try{return new URL(d).host;}catch(e){return String(d).replace(/^https?:\/\//,"").split("/")[0];}};
// ── شبكات الربح (تحقق بمفتاح API حقيقي) ──
r({id:"adsterra",cat:"ads",name:"Adsterra",home:"https://adsterra.com",signup:"https://publishers.adsterra.com/signup",keysUrl:"https://publishers.adsterra.com/api",env:["ADSTERRA_API_KEY"],regex:"[A-Za-z0-9]{24,64}",needs:["email"],human:["captcha"],method:"http",conf:3,
  verify:{kind:"api",url:"https://api3.adsterratools.com/publisher/stats.json?start_date={FROM}&finish_date={TO}&group_by=date",headers:{"X-API-Key":"{KEY}"},keyEnv:"ADSTERRA_API_KEY"}});
r({id:"monetag",cat:"ads",name:"Monetag",home:"https://monetag.com",signup:"https://monetag.com/signup/",keysUrl:"https://monetag.com/dashboard/settings/api",env:["MONETAG_API_KEY"],regex:"[A-Za-z0-9]{24,80}",needs:["email"],human:["captcha"],method:"browser",conf:2,
  verify:{kind:"api",url:"https://api.monetag.com/v1/statistics?date_from={FROM}&date_to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"MONETAG_API_KEY"}});
r({id:"exoclick",cat:"ads",name:"ExoClick",home:"https://www.exoclick.com",signup:"https://www.exoclick.com/signup/",keysUrl:"https://admin.exoclick.com/api",env:["EXOCLICK_API_TOKEN"],regex:"[A-Za-z0-9]{24,80}",needs:["email"],human:["captcha"],method:"browser",conf:2,
  verify:{kind:"api",url:"https://api.exoclick.com/v2/login",headers:{},keyEnv:"EXOCLICK_API_TOKEN"}});
r({id:"evadav",cat:"ads",name:"Evadav",home:"https://evadav.com",signup:"https://evadav.com/signup",keysUrl:"https://evadav.com/settings",env:["EVADAV_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"api",url:"https://api.evadav.com/v1/statistics?from={FROM}&to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"EVADAV_API_KEY"}});
r({id:"juicyads",cat:"ads",name:"JuicyAds",home:"https://www.juicyads.com",signup:"https://www.juicyads.com/signup.php",keysUrl:"https://www.juicyads.com/publisher/api",env:["JUICYADS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"api",url:"https://api.juicyads.com/api/v1/stats?from={FROM}&to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"JUICYADS_API_KEY"}});
r({id:"lospollos",cat:"ads",name:"LosPollos",home:"https://lospollos.com",signup:"https://lospollos.com/signup",keysUrl:"https://lospollos.com/settings",env:["LOSPOLLOS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"api",url:"https://api.lospollos.com/v1/stats?from={FROM}&to={TO}",headers:{Authorization:"Bearer {KEY}"},keyEnv:"LOSPOLLOS_API_KEY"}});
r({id:"trafficjunky",cat:"ads",name:"TrafficJunky",home:"https://www.trafficjunky.com",signup:"https://www.trafficjunky.com/publisher/signup",keysUrl:"https://admin.trafficjunky.com/reports",env:["TRAFFICJUNKY_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,
  verify:{kind:"http",url:"https://www.trafficjunky.com"}});
r({id:"clickadilla",cat:"ads",name:"ClickAdilla",home:"https://clickadilla.com",signup:"https://clickadilla.com/signup",keysUrl:"https://clickadilla.com/statistics",env:["CLICKADILLA_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://clickadilla.com"}});
r({id:"propellerads",cat:"ads",name:"PropellerAds",home:"https://propellerads.com",signup:"https://publishers.propellerads.com/#/signup",keysUrl:"https://publishers.propellerads.com",env:["PROPELLERADS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],human:["captcha"],method:"browser",conf:1,verify:{kind:"http",url:"https://publishers.propellerads.com"}});
r({id:"pushhouse",cat:"ads",name:"Push.House",home:"https://push.house",signup:"https://push.house/register",keysUrl:"https://push.house/settings",env:["PUSHHOUSE_TOKEN"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://push.house"}});
r({id:"hilltopads",cat:"ads",name:"HilltopAds",home:"https://hilltopads.com",signup:"https://hilltopads.com/register",keysUrl:"https://hilltopads.com/publisher/api",env:["HILLTOPADS_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://hilltopads.com"}});
r({id:"galaksion",cat:"ads",name:"Galaksion",home:"https://galaksion.com",signup:"https://galaksion.com/register",keysUrl:"https://galaksion.com",env:["GALAKSION_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://galaksion.com"}});
r({id:"admaven",cat:"ads",name:"AdMaven",home:"https://admaven.com",signup:"https://admaven.com/register",keysUrl:"https://admaven.com",env:["ADMAVEN_API_KEY"],regex:"[A-Za-z0-9]{20,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://admaven.com"}});
r({id:"cpagrip",cat:"ads",name:"CPAGrip",home:"https://www.cpagrip.com",signup:"https://www.cpagrip.com/signup.php",keysUrl:"https://www.cpagrip.com",env:["CPAGRIP_API_KEY"],regex:"[A-Za-z0-9]{16,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.cpagrip.com"}});
r({id:"bitlabs",cat:"ads",name:"BitLabs",home:"https://bitlabs.ai",signup:"https://dashboard.bitlabs.ai/signup",keysUrl:"https://dashboard.bitlabs.ai",env:["BITLABS_API_KEY"],regex:"[A-Za-z0-9_\\-]{16,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://bitlabs.ai"}});
r({id:"offertoro",cat:"ads",name:"OfferToro",home:"https://www.offertoro.com",signup:"https://www.offertoro.com/signup",keysUrl:"https://www.offertoro.com",env:["OFFERTORO_API_KEY","OFFERTORO_APP_ID"],regex:"[A-Za-z0-9]{8,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.offertoro.com"}});
r({id:"mylead",cat:"ads",name:"MyLead",home:"https://mylead.global",signup:"https://mylead.global/signup",keysUrl:"https://mylead.global",env:["MYLEAD_API_KEY"],regex:"[A-Za-z0-9]{16,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://mylead.global"}});
r({id:"crakrevenue",cat:"ads",name:"CrakRevenue",home:"https://www.crakrevenue.com",signup:"https://www.crakrevenue.com/signup",keysUrl:"https://www.crakrevenue.com",env:["CRAKREVENUE_API_KEY"],regex:"[A-Za-z0-9]{16,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.crakrevenue.com"}});
// ── استضافة ونشر ──
r({id:"surge",cat:"host",name:"Surge",home:"https://surge.sh",signup:"https://surge.sh/signup",keysUrl:"https://surge.sh",env:["SURGE_TOKEN","SURGE_DOMAIN"],regex:"[A-Za-z0-9]{20,80}",needs:["email"],method:"none",conf:3,verify:{kind:"http",url:"https://surge.sh"}});
r({id:"netlify",cat:"host",name:"Netlify",home:"https://netlify.com",signup:"https://app.netlify.com/signup",keysUrl:"https://app.netlify.com/user/applications#personal-access-tokens",env:["NETLIFY_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,80}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.netlify.com/api/v1/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"NETLIFY_TOKEN"}});
r({id:"vercel",cat:"host",name:"Vercel",home:"https://vercel.com",signup:"https://vercel.com/signup",keysUrl:"https://vercel.com/account/tokens",env:["VERCEL_TOKEN"],regex:"[A-Za-z0-9]{24,40}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.vercel.com/v2/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"VERCEL_TOKEN"}});
r({id:"cloudflare",cat:"host",name:"Cloudflare",home:"https://cloudflare.com",signup:"https://dash.cloudflare.com/sign-up",keysUrl:"https://dash.cloudflare.com/profile/api-tokens",env:["CF_TOKEN","CF_PROJECT"],regex:"[A-Za-z0-9_\\-]{35,60}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.cloudflare.com/client/v4/user/tokens/verify",headers:{Authorization:"Bearer {KEY}"},keyEnv:"CF_TOKEN"}});
r({id:"github",cat:"host",name:"GitHub",home:"https://github.com",signup:"https://github.com/signup",keysUrl:"https://github.com/settings/tokens",env:["GITHUB_TOKEN","GH_USER"],regex:"[A-Za-z0-9_]{35,45}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.github.com/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"GITHUB_TOKEN"}});
r({id:"gitlab",cat:"host",name:"GitLab",home:"https://gitlab.com",signup:"https://gitlab.com/users/sign_up",keysUrl:"https://gitlab.com/-/profile/personal_access_tokens",env:["GITLAB_TOKEN"],regex:"[A-Za-z0-9_\\-]{20,30}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://gitlab.com/api/v4/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"GITLAB_TOKEN"}});
r({id:"neocities",cat:"host",name:"Neocities",home:"https://neocities.org",signup:"https://neocities.org/",keysUrl:"https://neocities.org/settings",env:["NEOCITIES_USER","NEOCITIES_PASS"],regex:"[A-Za-z0-9]{8,40}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://neocities.org/api/list",headers:{Authorization:"Basic {KEY}"},keyEnv:"NEOCITIES_USER"}});
r({id:"render",cat:"host",name:"Render",home:"https://render.com",signup:"https://dashboard.render.com/register",keysUrl:"https://dashboard.render.com/u/settings#api-keys",env:["RENDER_API_KEY"],regex:"[A-Za-z0-9]{20,60}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.render.com/v1/owners",headers:{Authorization:"Bearer {KEY}"},keyEnv:"RENDER_API_KEY"}});
r({id:"railway",cat:"host",name:"Railway",home:"https://railway.app",signup:"https://railway.app/login",keysUrl:"https://railway.app/account/tokens",env:["RAILWAY_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://railway.app"}});
r({id:"fly",cat:"host",name:"Fly.io",home:"https://fly.io",signup:"https://fly.io/app/sign-up",keysUrl:"https://fly.io/user/personal_access_tokens",env:["FLY_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,90}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://fly.io"}});
r({id:"deno",cat:"host",name:"Deno Deploy",home:"https://deno.com/deploy",signup:"https://dash.deno.com/signin",keysUrl:"https://dash.deno.com/account#tokens",env:["DENO_TOKEN"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://dash.deno.com"}});
// ── قواعد بيانات وخدمات خلفية ──
r({id:"supabase",cat:"db",name:"Supabase",home:"https://supabase.com",signup:"https://supabase.com/dashboard/sign-up",keysUrl:"https://supabase.com/dashboard/project/_/settings/api",env:["SUPABASE_URL","SUPABASE_ANON_KEY"],regex:"[A-Za-z0-9_.\\-]{30,200}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"http",url:"https://supabase.com"}});
r({id:"neon",cat:"db",name:"Neon",home:"https://neon.tech",signup:"https://console.neon.tech/signup",keysUrl:"https://console.neon.tech/app/settings/api-keys",env:["NEON_API_KEY"],regex:"[A-Za-z0-9_\\-]{30,90}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://console.neon.tech/api/v2/projects",headers:{Authorization:"Bearer {KEY}"},keyEnv:"NEON_API_KEY"}});
r({id:"turso",cat:"db",name:"Turso",home:"https://turso.tech",signup:"https://app.turso.tech/signup",keysUrl:"https://app.turso.tech/settings/api-tokens",env:["TURSO_TOKEN"],regex:"[A-Za-z0-9_.\\-]{30,120}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://turso.tech"}});
r({id:"upstash",cat:"db",name:"Upstash",home:"https://upstash.com",signup:"https://console.upstash.com/login",keysUrl:"https://console.upstash.com/account/api",env:["UPSTASH_EMAIL","UPSTASH_API_KEY"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://upstash.com"}});
r({id:"mongodb",cat:"db",name:"MongoDB Atlas",home:"https://www.mongodb.com/atlas",signup:"https://account.mongodb.com/account/register",keysUrl:"https://cloud.mongodb.com/v2#/account/publicApi",env:["MONGODB_PUBLIC_KEY","MONGODB_PRIVATE_KEY"],regex:"[A-Za-z0-9_\\-]{8,64}",needs:["email"],human:["captcha"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.mongodb.com"}});
r({id:"appwrite",cat:"db",name:"Appwrite",home:"https://appwrite.io",signup:"https://cloud.appwrite.io/register",keysUrl:"https://cloud.appwrite.io",env:["APPWRITE_ENDPOINT","APPWRITE_PROJECT","APPWRITE_KEY"],regex:"[A-Za-z0-9_\\-]{16,120}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cloud.appwrite.io"}});
r({id:"pocketbase",cat:"db",name:"PocketBase",home:"https://pocketbase.io",signup:"https://pocketbase.io/docs/",keysUrl:"https://pocketbase.io",env:[],needs:[],method:"none",conf:1,verify:{kind:"http",url:"https://pocketbase.io"}});
r({id:"nhost",cat:"db",name:"Nhost",home:"https://nhost.io",signup:"https://app.nhost.io/signup",keysUrl:"https://app.nhost.io",env:["NHOST_SUBDOMAIN","NHOST_ADMIN_SECRET"],regex:"[A-Za-z0-9_\\-]{16,120}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://nhost.io"}});
r({id:"cloudflare-d1",cat:"db",name:"Cloudflare D1/R2/KV",home:"https://developers.cloudflare.com/d1/",signup:"https://dash.cloudflare.com/sign-up",keysUrl:"https://dash.cloudflare.com/profile/api-tokens",env:["CF_ACCOUNT_ID"],regex:"[A-Za-z0-9]{32}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://dash.cloudflare.com"}});
r({id:"backblaze",cat:"storage",name:"Backblaze B2",home:"https://www.backblaze.com/cloud-storage",signup:"https://www.backblaze.com/sign-up/cloud-storage",keysUrl:"https://secure.backblaze.com/app_keys.htm",env:["B2_KEY_ID","B2_APP_KEY"],regex:"[A-Za-z0-9]{12,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.backblaze.com"}});
r({id:"cloudinary",cat:"storage",name:"Cloudinary",home:"https://cloudinary.com",signup:"https://cloudinary.com/users/register_free",keysUrl:"https://console.cloudinary.com/settings/api-keys",env:["CLOUDINARY_URL"],regex:"cloudinary://[A-Za-z0-9]+:[A-Za-z0-9_\\-]+@[A-Za-z0-9]+",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cloudinary.com"}});
// ── بريد ومراسلة ──
r({id:"brevo",cat:"mail",name:"Brevo",home:"https://www.brevo.com",signup:"https://onboarding.brevo.com/account/register",keysUrl:"https://app.brevo.com/settings/keys/api",env:["BREVO_API_KEY"],regex:"xkeysib-[A-Za-z0-9_\\-]{40,90}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.brevo.com/v3/account",headers:{"api-key":"{KEY}"},keyEnv:"BREVO_API_KEY"}});
r({id:"mailgun",cat:"mail",name:"Mailgun",home:"https://www.mailgun.com",signup:"https://signup.mailgun.com/new/signup",keysUrl:"https://app.mailgun.com/app/account/security/api_keys",env:["MAILGUN_API_KEY","MAILGUN_DOMAIN"],regex:"[A-Za-z0-9\\-]{24,64}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.mailgun.net/v3/domains",headers:{Authorization:"Basic {KEY}"},keyEnv:"MAILGUN_API_KEY"}});
r({id:"resend",cat:"mail",name:"Resend",home:"https://resend.com",signup:"https://resend.com/signup",keysUrl:"https://resend.com/api-keys",env:["RESEND_API_KEY"],regex:"re_[A-Za-z0-9_]{20,60}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.resend.com/domains",headers:{Authorization:"Bearer {KEY}"},keyEnv:"RESEND_API_KEY"}});
r({id:"sendgrid",cat:"mail",name:"SendGrid",home:"https://sendgrid.com",signup:"https://signup.sendgrid.com/",keysUrl:"https://app.sendgrid.com/settings/api_keys",env:["SENDGRID_API_KEY"],regex:"SG\\.[A-Za-z0-9_\\-]{20,80}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.sendgrid.com/v3/scopes",headers:{Authorization:"Bearer {KEY}"},keyEnv:"SENDGRID_API_KEY"}});
// ── مراقبة وأتمتة وتحليلات ──
r({id:"healthchecks",cat:"monitor",name:"Healthchecks.io",home:"https://healthchecks.io",signup:"https://healthchecks.io/accounts/signup/",keysUrl:"https://healthchecks.io/accounts/profile/",env:["HEALTHCHECK_PING_URL"],regex:"https://hc-ping\\.com/[A-Za-z0-9\\-]+",needs:["email"],method:"http",conf:2,verify:{kind:"http",url:"https://healthchecks.io"}});
r({id:"uptimerobot",cat:"monitor",name:"UptimeRobot",home:"https://uptimerobot.com",signup:"https://uptimerobot.com/signUp",keysUrl:"https://uptimerobot.com/dashboard#mySettings",env:["UPTIMEROBOT_API_KEY"],regex:"u[0-9]{6}-[A-Za-z0-9]{20,40}",needs:["email"],human:["captcha"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.uptimerobot.com/v2/getAccountDetails",headers:{"content-type":"application/x-www-form-urlencoded"},keyEnv:"UPTIMEROBOT_API_KEY"}});
r({id:"cronjob",cat:"automation",name:"cron-job.org",home:"https://cron-job.org",signup:"https://console.cron-job.org/signup",keysUrl:"https://console.cron-job.org/settings",env:["CRONJOB_API_KEY"],regex:"[A-Za-z0-9_\\-]{24,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cron-job.org"}});
r({id:"betterstack",cat:"monitor",name:"Better Stack",home:"https://betterstack.com",signup:"https://betterstack.com/users/sign-up",keysUrl:"https://uptime.betterstack.com/team/0/api-tokens",env:["BETTERSTACK_TOKEN"],regex:"[A-Za-z0-9_]{30,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://betterstack.com"}});
r({id:"umami",cat:"analytics",name:"Umami Cloud",home:"https://umami.is",signup:"https://cloud.umami.is/signup",keysUrl:"https://cloud.umami.is/settings",env:["UMAMI_WEBSITE_ID"],regex:"[a-f0-9\\-]{36}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://cloud.umami.is"}});
r({id:"goatcounter",cat:"analytics",name:"GoatCounter",home:"https://www.goatcounter.com",signup:"https://www.goatcounter.com/signup",keysUrl:"https://www.goatcounter.com/settings",env:["GOATCOUNTER_CODE"],regex:"[a-z0-9\\-]{3,40}",needs:["email"],method:"http",conf:1,verify:{kind:"http",url:"https://www.goatcounter.com"}});
r({id:"plausible",cat:"analytics",name:"Plausible",home:"https://plausible.io",signup:"https://plausible.io/register",keysUrl:"https://plausible.io/settings",env:["PLAUSIBLE_DOMAIN"],regex:"[A-Za-z0-9.\\-]{4,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://plausible.io"}});
r({id:"sentry",cat:"monitor",name:"Sentry",home:"https://sentry.io",signup:"https://sentry.io/signup/",keysUrl:"https://sentry.io/settings/account/api/auth-tokens/",env:["SENTRY_DSN","SENTRY_AUTH_TOKEN"],regex:"https://[a-f0-9]+@[a-z0-9.]+/[0-9]+",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://sentry.io/api/0/",headers:{Authorization:"Bearer {KEY}"},keyEnv:"SENTRY_AUTH_TOKEN"}});
// ── SEO وأدوات ──
r({id:"indexnow",cat:"seo",name:"IndexNow",home:"https://www.indexnow.org",signup:"https://www.indexnow.org/documentation",keysUrl:"https://www.indexnow.org",env:["INDEXNOW_KEY"],regex:"[A-Za-z0-9]{8,64}",needs:[],method:"none",conf:3,verify:{kind:"http",url:"https://api.indexnow.org/indexnow"}});
r({id:"google-search-console",cat:"seo",name:"Google Search Console",home:"https://search.google.com/search-console",signup:"https://search.google.com/search-console/welcome",keysUrl:"https://search.google.com/search-console",env:["GSC_VERIFICATION"],regex:"[A-Za-z0-9_\\-]{20,90}",needs:["email"],human:["identity","dns"],method:"none",conf:1,verify:{kind:"http",url:"https://search.google.com/search-console"}});
r({id:"bing-webmaster",cat:"seo",name:"Bing Webmaster",home:"https://www.bing.com/webmasters",signup:"https://www.bing.com/webmasters/about",keysUrl:"https://www.bing.com/webmasters",env:["BING_API_KEY"],regex:"[A-Za-z0-9]{20,60}",needs:["email"],human:["identity"],method:"none",conf:1,verify:{kind:"http",url:"https://www.bing.com/webmasters"}});
r({id:"cloudflare-pages",cat:"host",name:"Cloudflare Pages",home:"https://pages.cloudflare.com",signup:"https://dash.cloudflare.com/sign-up",keysUrl:"https://dash.cloudflare.com/profile/api-tokens",env:["CF_PAGES_PROJECT"],regex:"[a-z0-9\\-]{3,60}",needs:["email"],method:"none",conf:1,verify:{kind:"http",url:"https://pages.cloudflare.com"}});
// ── دفع وتحويل ──
r({id:"nowpayments",cat:"pay",name:"NOWPayments",home:"https://nowpayments.io",signup:"https://account.nowpayments.io/create-account",keysUrl:"https://account.nowpayments.io/store-settings/api-keys",env:["NOWPAYMENTS_API_KEY","NOWPAYMENTS_IPN"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],human:["kyc"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.nowpayments.io/v1/status",headers:{"x-api-key":"{KEY}"},keyEnv:"NOWPAYMENTS_API_KEY"}});
r({id:"cryptomus",cat:"pay",name:"Cryptomus",home:"https://cryptomus.com",signup:"https://app.cryptomus.com/register",keysUrl:"https://app.cryptomus.com/api",env:["CRYPTOMUS_MERCHANT","CRYPTOMUS_API_KEY"],regex:"[A-Za-z0-9\\-]{30,60}",needs:["email"],human:["kyc"],method:"browser",conf:1,verify:{kind:"http",url:"https://cryptomus.com"}});
r({id:"coingate",cat:"pay",name:"CoinGate",home:"https://coingate.com",signup:"https://account.coingate.com/signup",keysUrl:"https://account.coingate.com/api/auth-tokens",env:["COINGATE_TOKEN"],regex:"[A-Za-z0-9_\\-]{30,80}",needs:["email"],human:["kyc"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.coingate.com/v2/auth/user",headers:{Authorization:"Bearer {KEY}"},keyEnv:"COINGATE_TOKEN"}});
// ── بلوكشين وواجهات ──
r({id:"alchemy",cat:"crypto",name:"Alchemy",home:"https://www.alchemy.com",signup:"https://dashboard.alchemy.com/signup",keysUrl:"https://dashboard.alchemy.com/apps",env:["ALCHEMY_KEY"],regex:"[A-Za-z0-9_\\-]{20,50}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.alchemy.com"}});
r({id:"infura",cat:"crypto",name:"Infura",home:"https://infura.io",signup:"https://app.infura.io/register",keysUrl:"https://app.infura.io/dashboard",env:["INFURA_KEY"],regex:"[a-f0-9]{32}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://infura.io"}});
r({id:"quicknode",cat:"crypto",name:"QuickNode",home:"https://www.quicknode.com",signup:"https://www.quicknode.com/signup",keysUrl:"https://dashboard.quicknode.com/endpoints",env:["QUICKNODE_URL"],regex:"https://[a-z0-9\\-]+\\.quiknode\\.pro/[a-z0-9/]+",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://www.quicknode.com"}});
r({id:"thegraph",cat:"crypto",name:"The Graph",home:"https://thegraph.com",signup:"https://thegraph.com/studio/",keysUrl:"https://thegraph.com/studio/apikeys/",env:["GRAPH_API_KEY"],regex:"[A-Za-z0-9]{30,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://thegraph.com"}});
// ── ذكاء اصطناعي ──
r({id:"groq",cat:"ai",name:"Groq",home:"https://groq.com",signup:"https://console.groq.com/signup",keysUrl:"https://console.groq.com/keys",env:["GROQ_API_KEY"],regex:"gsk_[A-Za-z0-9]{40,60}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://api.groq.com/openai/v1/models",headers:{Authorization:"Bearer {KEY}"},keyEnv:"GROQ_API_KEY"}});
r({id:"openrouter",cat:"ai",name:"OpenRouter",home:"https://openrouter.ai",signup:"https://openrouter.ai/",keysUrl:"https://openrouter.ai/keys",env:["OPENROUTER_API_KEY"],regex:"sk-or-[A-Za-z0-9\\-]{30,80}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://openrouter.ai/api/v1/models",headers:{Authorization:"Bearer {KEY}"},keyEnv:"OPENROUTER_API_KEY"}});
r({id:"huggingface",cat:"ai",name:"HuggingFace",home:"https://huggingface.co",signup:"https://huggingface.co/join",keysUrl:"https://huggingface.co/settings/tokens",env:["HF_TOKEN"],regex:"hf_[A-Za-z0-9]{30,50}",needs:["email"],method:"browser",conf:2,verify:{kind:"api",url:"https://huggingface.co/api/whoami-v2",headers:{Authorization:"Bearer {KEY}"},keyEnv:"HF_TOKEN"}});
r({id:"replicate",cat:"ai",name:"Replicate",home:"https://replicate.com",signup:"https://replicate.com/signin",keysUrl:"https://replicate.com/account/api-tokens",env:["REPLICATE_TOKEN"],regex:"r8_[A-Za-z0-9]{30,50}",needs:["email"],human:["payment"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.replicate.com/v1/account",headers:{Authorization:"Bearer {KEY}"},keyEnv:"REPLICATE_TOKEN"}});
r({id:"deepgram",cat:"ai",name:"Deepgram",home:"https://deepgram.com",signup:"https://console.deepgram.com/signup",keysUrl:"https://console.deepgram.com/project/_/keys",env:["DEEPGRAM_KEY"],regex:"[a-f0-9]{40}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://deepgram.com"}});
r({id:"elevenlabs",cat:"ai",name:"ElevenLabs",home:"https://elevenlabs.io",signup:"https://elevenlabs.io/sign-up",keysUrl:"https://elevenlabs.io/app/settings/api-keys",env:["ELEVENLABS_KEY"],regex:"sk_[a-f0-9]{40,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.elevenlabs.io/v1/user",headers:{"xi-api-key":"{KEY}"},keyEnv:"ELEVENLABS_KEY"}});
// ── أتمتة ونماذج ──
r({id:"formspree",cat:"forms",name:"Formspree",home:"https://formspree.io",signup:"https://formspree.io/register",keysUrl:"https://formspree.io/forms",env:["FORMSPREE_ID"],regex:"[a-z0-9]{8,12}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://formspree.io"}});
r({id:"n8n",cat:"automation",name:"n8n Cloud",home:"https://n8n.io",signup:"https://app.n8n.cloud/register",keysUrl:"https://app.n8n.cloud/manage",env:["N8N_URL","N8N_API_KEY"],regex:"[A-Za-z0-9_\\-]{20,80}",needs:["email"],method:"browser",conf:1,verify:{kind:"http",url:"https://n8n.io"}});
r({id:"airtable",cat:"automation",name:"Airtable",home:"https://airtable.com",signup:"https://airtable.com/signup",keysUrl:"https://airtable.com/create/tokens",env:["AIRTABLE_TOKEN","AIRTABLE_BASE"],regex:"pat[A-Za-z0-9.]{20,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.airtable.com/v0/meta/whoami",headers:{Authorization:"Bearer {KEY}"},keyEnv:"AIRTABLE_TOKEN"}});
r({id:"notion",cat:"automation",name:"Notion",home:"https://www.notion.so",signup:"https://www.notion.so/signup",keysUrl:"https://www.notion.so/my-integrations",env:["NOTION_TOKEN"],regex:"(secret_|ntn_)[A-Za-z0-9]{30,60}",needs:["email"],method:"browser",conf:1,verify:{kind:"api",url:"https://api.notion.com/v1/users/me",headers:{Authorization:"Bearer {KEY}","Notion-Version":"2022-06-28"},keyEnv:"NOTION_TOKEN"}});
// ── مجموعات موسّعة (تحقق وصول مباشر) ──
const BULK=[
 ["producthunt","dir","https://www.producthunt.com","https://www.producthunt.com/"],
 ["betalist","dir","https://betalist.com","https://betalist.com/submit"],
 ["alternativeto","dir","https://alternativeto.net","https://alternativeto.net/"],
 ["crunchbase","dir","https://www.crunchbase.com","https://www.crunchbase.com/"],
 ["f6s","dir","https://www.f6s.com","https://www.f6s.com/join"],
 ["saashub","dir","https://www.saashub.com","https://www.saashub.com/"],
 ["toolify","dir","https://www.toolify.ai","https://www.toolify.ai/"],
 ["futurepedia","dir","https://www.futurepedia.io","https://www.futurepedia.io/"],
 ["theresanaiforthat","dir","https://theresanaiforthat.com","https://theresanaiforthat.com/"],
 ["aitools","dir","https://aitools.fyi","https://aitools.fyi/submit"],
 ["topai","dir","https://topai.tools","https://topai.tools/submit"],
 ["startupbase","dir","https://startupbase.io","https://startupbase.io/"],
 ["indiehackers","dir","https://www.indiehackers.com","https://www.indiehackers.com/"],
 ["devto","blog","https://dev.to","https://dev.to/enter"],
 ["hashnode","blog","https://hashnode.com","https://hashnode.com/onboard"],
 ["medium","blog","https://medium.com","https://medium.com/m/signin"],
 ["substack","blog","https://substack.com","https://substack.com/signup"],
 ["blogger","blog","https://www.blogger.com","https://www.blogger.com/start"],
 ["wordpress","blog","https://wordpress.com","https://wordpress.com/start"],
 ["tumblr","blog","https://www.tumblr.com","https://www.tumblr.com/register"],
 ["reddit","social","https://www.reddit.com","https://www.reddit.com/register"],
 ["pinterest","social","https://www.pinterest.com","https://www.pinterest.com/business/create"],
 ["quora","social","https://www.quora.com","https://www.quora.com/"],
 ["vk","social","https://vk.com","https://vk.com/join"],
 ["mastodon","social","https://mastodon.social","https://mastodon.social/auth/sign_up"],
 ["gravatar","tool","https://gravatar.com","https://gravatar.com/"],
 ["imgbb","storage","https://imgbb.com","https://imgbb.com/signup"],
 ["imagekit","storage","https://imagekit.io","https://imagekit.io/registration"],
 ["statically","cdn","https://statically.io","https://statically.io/"],
 ["jsdelivr","cdn","https://www.jsdelivr.com","https://www.jsdelivr.com/"],
 ["bunny","cdn","https://bunny.net","https://bunny.net/signup"],
 ["gcore","cdn","https://gcore.com","https://gcore.com/signup"],
 ["statcounter","analytics","https://statcounter.com","https://statcounter.com/signup/"],
 ["matomo","analytics","https://matomo.org","https://matomo.org/"],
 ["simpleanalytics","analytics","https://www.simpleanalytics.com","https://www.simpleanalytics.com/signup"],
 ["counter","analytics","https://counter.dev","https://counter.dev/"],
 ["posthog","analytics","https://posthog.com","https://app.posthog.com/signup"],
 ["clarity","analytics","https://clarity.microsoft.com","https://clarity.microsoft.com/"],
 ["logtail","monitor","https://betterstack.com/logs","https://logs.betterstack.com/users/sign-up"],
 ["logflare","monitor","https://logflare.app","https://logflare.app/users/register"],
 ["axiom","monitor","https://axiom.co","https://app.axiom.co/register"],
 ["grafana","monitor","https://grafana.com","https://grafana.com/auth/sign-up/create-user"],
 ["freshping","monitor","https://www.freshworks.com/website-monitoring/","https://www.freshworks.com/website-monitoring/"],
 ["statuspage","monitor","https://www.atlassian.com/software/statuspage","https://www.atlassian.com/software/statuspage"],
 ["uptime","monitor","https://uptime.com","https://uptime.com/signup"],
 ["cloudflare-analytics","analytics","https://www.cloudflare.com/web-analytics/","https://dash.cloudflare.com/sign-up"],
 ["npoint","tool","https://www.npoint.io","https://www.npoint.io/"],
 ["jsonbin","db","https://jsonbin.io","https://jsonbin.io/signup"],
 ["restdb","db","https://restdb.io","https://restdb.io/signup"],
 ["firebase","db","https://firebase.google.com","https://console.firebase.google.com/"],
 ["fauna","db","https://fauna.com","https://dashboard.fauna.com/register"],
 ["xata","db","https://xata.io","https://app.xata.io/signup"],
 ["cockroach","db","https://www.cockroachlabs.com","https://cockroachlabs.cloud/signup"],
 ["aiven","db","https://aiven.io","https://console.aiven.io/signup"],
 ["koyeb","host","https://www.koyeb.com","https://app.koyeb.com/auth/signup"],
 ["deta","host","https://deta.space","https://deta.space/signup"],
 ["valtown","host","https://www.val.town","https://www.val.town/signup"],
 ["glitch","host","https://glitch.com","https://glitch.com/signup"],
 ["heroku","host","https://www.heroku.com","https://signup.heroku.com/"],
 ["azure-static","host","https://azure.microsoft.com/products/app-service/static","https://azure.microsoft.com/free/"],
 ["tiiny","host","https://tiiny.host","https://tiiny.host/signup"],
 ["static","host","https://static.app","https://static.app/"],
 ["onrender","host","https://render.com","https://dashboard.render.com/register"],
 ["surge2","host","https://surge.sh","https://surge.sh/help/getting-started-with-surge"],
 ["byethost","host","https://byet.host","https://byet.host/signup"],
 ["infinityfree","host","https://infinityfree.net","https://infinityfree.net/"],
 ["000webhost","host","https://www.000webhost.com","https://www.000webhost.com/"],
 ["freehostia","host","https://www.freehostia.com","https://www.freehostia.com/signup.html"],
 ["awardspace","host","https://www.awardspace.com","https://www.awardspace.com/free-hosting/"],
 ["netlify2","host","https://www.netlify.com","https://app.netlify.com/signup"],
 ["railway2","host","https://railway.app","https://railway.app/login"],
 ["zeabur","host","https://zeabur.com","https://zeabur.com/signup"],
 ["northflank","host","https://northflank.com","https://app.northflank.com/signup"],
 ["encore","host","https://encore.dev","https://encore.dev/"],
 ["modal","host","https://modal.com","https://modal.com/signup"],
 ["replit","host","https://replit.com","https://replit.com/signup"],
 ["codesandbox","host","https://codesandbox.io","https://codesandbox.io/signup"],
 ["stackblitz","host","https://stackblitz.com","https://stackblitz.com/signup"],
 ["deno-kv","db","https://deno.com/kv","https://dash.deno.com/signin"],
 ["upstash-kafka","db","https://upstash.com/kafka","https://console.upstash.com/login"],
 ["neon2","db","https://neon.tech","https://console.neon.tech/signup"],
 ["supabase2","db","https://supabase.com","https://supabase.com/dashboard/sign-up"],
 ["turso2","db","https://turso.tech","https://app.turso.tech/signup"],
 ["planetscale","db","https://planetscale.com","https://app.planetscale.com/signup"],
 ["tidb","db","https://www.pingcap.com/tidb-cloud/","https://tidbcloud.com/free-trial"],
 ["singlestore","db","https://www.singlestore.com","https://portal.singlestore.com/"],
 ["redis-cloud","db","https://redis.io/cloud/","https://app.redislabs.com/#/sign-up"],
 ["memetria","db","https://memetria.com","https://memetria.com/"],
 ["koyeb2","host","https://www.koyeb.com","https://app.koyeb.com/auth/signup"],
 ["grafana2","monitor","https://grafana.com","https://grafana.com/auth/sign-up/create-user"],
 ["netdata","monitor","https://www.netdata.cloud","https://app.netdata.cloud/sign-up"],
 ["nodeping","monitor","https://nodeping.com","https://nodeping.com/signup"],
 ["pingdom2","monitor","https://www.pingdom.com","https://www.pingdom.com/signup/"],
 ["site24x7","monitor","https://www.site24x7.com","https://www.site24x7.com/signup.html"],
 ["hetrixtools","monitor","https://hetrixtools.com","https://hetrixtools.com/register/"],
 ["cronitor","monitor","https://cronitor.io","https://cronitor.io/signup"],
 ["pipedream","automation","https://pipedream.com","https://pipedream.com/auth/signup"],
 ["make","automation","https://www.make.com","https://www.make.com/en/register"],
 ["zapier","automation","https://zapier.com","https://zapier.com/sign-up"],
 ["ifttt","automation","https://ifttt.com","https://ifttt.com/join"],
 ["pabbly","automation","https://www.pabbly.com/connect/","https://www.pabbly.com/connect/"],
 ["windmill","automation","https://www.windmill.dev","https://app.windmill.dev/user/login"],
 ["triggerdev","automation","https://trigger.dev","https://cloud.trigger.dev/login"],
 ["composio","automation","https://composio.dev","https://app.composio.dev/"],
 ["resend2","mail","https://resend.com","https://resend.com/signup"],
 ["loops","mail","https://loops.so","https://app.loops.so/signup"],
 ["buttondown","mail","https://buttondown.email","https://buttondown.email/register"],
 ["mailtrap","mail","https://mailtrap.io","https://mailtrap.io/register/signup"],
 ["mailersend","mail","https://www.mailersend.com","https://app.mailersend.com/signup"],
 ["postmark","mail","https://postmarkapp.com","https://account.postmarkapp.com/sign_up"],
 ["smtp2go","mail","https://www.smtp2go.com","https://www.smtp2go.com/signup/"],
 ["elasticemail","mail","https://elasticemail.com","https://elasticemail.com/account#/create-account"],
 ["zeptomail","mail","https://www.zoho.com/zeptomail/","https://www.zoho.com/zeptomail/"],
 ["improvmx","mail","https://improvmx.com","https://app.improvmx.com/register"],
 ["forwardemail","mail","https://forwardemail.net","https://forwardemail.net/en/register"],
 ["cloudflare-email","mail","https://www.cloudflare.com/products/email-routing/","https://dash.cloudflare.com/sign-up"],
 ["lark","social","https://www.larksuite.com","https://www.larksuite.com/en_us/"],
 ["discord","social","https://discord.com","https://discord.com/register"],
 ["telegram","social","https://telegram.org","https://web.telegram.org/"],
 ["slack","social","https://slack.com","https://slack.com/get-started"],
 ["mattermost","social","https://mattermost.com","https://mattermost.com/get-started/"],
 ["rocket","social","https://rocket.chat","https://cloud.rocket.chat/trial"],
 ["line","social","https://line.me","https://line.me/en/"],
 ["kakao","social","https://www.kakaocorp.com","https://accounts.kakao.com/weblogin/create_account"],
 ["naver","social","https://www.naver.com","https://nid.naver.com/user2/joinGlobal.naver"],
 ["baidu","social","https://www.baidu.com","https://passport.baidu.com/v2/?reg"],
 ["weibo","social","https://weibo.com","https://weibo.com/signup/signup.php"],
 ["bilibili","social","https://www.bilibili.com","https://passport.bilibili.com/register/phone.html"],
 ["douyin","social","https://www.douyin.com","https://www.douyin.com/"],
 ["xiaohongshu","social","https://www.xiaohongshu.com","https://www.xiaohongshu.com/"],
 ["qq","social","https://www.qq.com","https://ssl.zc.qq.com/v3/index-en.html"],
 ["yandex","social","https://yandex.com","https://passport.yandex.com/registration"],
 ["mailru","social","https://mail.ru","https://account.mail.ru/signup"],
 ["okru","social","https://ok.ru","https://ok.ru/reg"],
 ["dzen","blog","https://dzen.ru","https://dzen.ru/"],
 ["telegraph","blog","https://telegra.ph","https://telegra.ph/"],
 ["ghost","blog","https://ghost.org","https://account.ghost.org/signup/"],
 ["wix","blog","https://www.wix.com","https://users.wix.com/signin"],
 ["weebly","blog","https://www.weebly.com","https://www.weebly.com/signup"],
 ["squarespace","blog","https://www.squarespace.com","https://account.squarespace.com/"],
 ["carrd","blog","https://carrd.co","https://carrd.co/signup"],
 ["linktree","social","https://linktr.ee","https://linktr.ee/register"],
 ["beacons","social","https://beacons.ai","https://beacons.ai/signup"],
 ["aboutme","social","https://about.me","https://about.me/signup"],
 ["notion2","blog","https://www.notion.so","https://www.notion.so/signup"],
 ["super","blog","https://super.so","https://super.so/signup"],
 ["potion","blog","https://www.potion.so","https://www.potion.so/"],
 ["feather","blog","https://feather.so","https://feather.so/"],
 ["typedream","blog","https://typedream.com","https://typedream.com/"],
 ["dorik","blog","https://dorik.com","https://app.dorik.com/register"],
 ["softr","blog","https://www.softr.io","https://studio.softr.io/auth/signup"],
 ["glide","blog","https://www.glideapps.com","https://www.glideapps.com/signup"],
 ["bubble","blog","https://bubble.io","https://bubble.io/"],
 ["adalo","blog","https://www.adalo.com","https://app.adalo.com/signup"],
 ["flutterflow","blog","https://flutterflow.io","https://app.flutterflow.io/"],
 ["bravo","blog","https://www.bravostudio.app","https://www.bravostudio.app/"],
 ["backendless","db","https://backendless.com","https://develop.backendless.com/"],
 ["parse","db","https://parseplatform.org","https://parseplatform.org/"],
 ["directus","db","https://directus.io","https://directus.io/"],
 ["strapi","db","https://strapi.io","https://strapi.io/"],
 ["hasura","db","https://hasura.io","https://cloud.hasura.io/signup"],
 ["baserow","db","https://baserow.io","https://baserow.io/signup"],
 ["nocodb","db","https://nocodb.com","https://app.nocodb.com/#/signup"],
 ["grist","db","https://www.getgrist.com","https://docs.getgrist.com/signup"],
 ["rows","db","https://rows.com","https://rows.com/signup"],
 ["csvbox","db","https://csvbox.io","https://app.csvbox.io/register"],
 ["retool","automation","https://retool.com","https://login.retool.com/auth/signup"],
 ["appsmith","automation","https://appsmith.com","https://app.appsmith.com/user/signup"],
 ["budibase","automation","https://budibase.com","https://account.budibase.app/register"],
 ["tooljet","automation","https://www.tooljet.com","https://www.tooljet.com/"],
 ["illacloud","automation","https://www.illacloud.com","https://cloud.illacloud.com/"],
 ["quickbase","db","https://www.quickbase.com","https://www.quickbase.com/signup"],
 ["smartsheet","db","https://www.smartsheet.com","https://app.smartsheet.com/b/home"],
 ["clickup","automation","https://clickup.com","https://app.clickup.com/signup"],
 ["trello","automation","https://trello.com","https://trello.com/signup"],
 ["asana","automation","https://asana.com","https://app.asana.com/-/signup"],
 ["monday","automation","https://monday.com","https://auth.monday.com/users/sign_up"],
 ["coda","automation","https://coda.io","https://coda.io/signup"],
 ["airtable2","automation","https://airtable.com","https://airtable.com/signup"],
 ["zoho","automation","https://www.zoho.com","https://accounts.zoho.com/signup"],
 ["freshdesk","automation","https://freshdesk.com","https://freshdesk.com/signup"],
 ["hubspot","automation","https://www.hubspot.com","https://app.hubspot.com/signup"],
 ["salesforce","automation","https://www.salesforce.com","https://login.salesforce.com/"],
 ["pipedrive","automation","https://www.pipedrive.com","https://app.pipedrive.com/signup"],
 ["zendesk","automation","https://www.zendesk.com","https://www.zendesk.com/register/"],
 ["intercom","automation","https://www.intercom.com","https://app.intercom.com/"],
 ["crisp","automation","https://crisp.chat","https://app.crisp.chat/initiate/signup/"],
 ["tawk","automation","https://www.tawk.to","https://dashboard.tawk.to/signup"],
 ["tidio","automation","https://www.tidio.com","https://www.tidio.com/"],
 ["chatwoot","automation","https://www.chatwoot.com","https://app.chatwoot.com/"],
 ["formspree2","forms","https://formspree.io","https://formspree.io/register"],
 ["getform","forms","https://getform.io","https://getform.io/signup"],
 ["formcarry","forms","https://formcarry.com","https://app.formcarry.com/signup"],
 ["tally","forms","https://tally.so","https://tally.so/signup"],
 ["typeform","forms","https://www.typeform.com","https://admin.typeform.com/signup"],
 ["jotform","forms","https://www.jotform.com","https://www.jotform.com/signup"],
 ["fillout","forms","https://www.fillout.com","https://www.fillout.com/"],
 ["surveycake","forms","https://www.surveycake.com","https://www.surveycake.com/"],
 ["google-forms","forms","https://docs.google.com/forms","https://docs.google.com/forms/"]
];
BULK.forEach(([id,cat,home,signup,env])=>r({id,cat,name:id,home,signup,keysUrl:signup,env:env?env.split(","):[],regex:"[A-Za-z0-9_\\-]{16,80}",needs:["email"],human:["captcha"],method:"browser",conf:1,verify:{kind:"http",url:home}}));
const byId={};R.forEach(x=>byId[x.id]=x);
function forId(id){return byId[id]||null;}
function match(host){host=String(host).replace(/^www\./,"");return byId[host.split(".")[0]]||null;}
function generic(t){return {id:t.id,cat:t.cat||"dir",name:t.id,home:"https://"+t.id,signup:"https://"+t.id,keysUrl:"https://"+t.id,
  env:[],regex:"[A-Za-z0-9_\\-]{16,80}",needs:[],human:[],method:"none",conf:1,verify:{kind:"http",url:"https://"+t.id}};}
module.exports={all:()=>R,byId:forId,match,generic,h,count:()=>R.length};
if(require.main===module){console.log("  ✔ وصفات الخدمات: "+R.length+" خدمة ("+new Set(R.map(x=>x.cat)).size+" تصنيف)");}
