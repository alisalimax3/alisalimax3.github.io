#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
ask(){ printf '%s' "$2"; read -r v; [ -n "$v" ] && echo "$v"; }
echo "— اترك الفراغ لتخطّي —"
export P=$(ask "" "Adsterra Publisher ID (لـads.txt): ")
for z in top mid side mobile bottom inarticle; do export K_$z=$(ask "" "مفتاح بانر $z: "); done
export PU=$(ask "" "Popunder src: "); export SB=$(ask "" "SocialBar src: "); export IP=$(ask "" "InPage src: ")
export MT=$(ask "" "Monetag MultiTag src: "); export MRZ=$(ask "" "Monetag rewarded zone: ")
export AC=$(ask "" "AdSense client: "); export AS=$(ask "" "AdSense slot: ")
export MON=$(ask "" "Monetag API key: "); export PRO=$(ask "" "PropellerAds API key: ")
export HN=$(ask "" "اسمك كما في الهوية: "); export HA=$(ask "" "رقم حسابك في الكريمي: ")
export HP=$(ask "" "رقم هاتفك (967...): "); export HM=$(ask "" "رقم إم فلوس: ")
export WA=$(ask "" "واتساب الطلبات: "); export TG=$(ask "" "تيليجرام: "); export EM=$(ask "" "بريدك: ")
export UT=$(ask "" "USDT TRC20: "); export EP=$(ask "" "Apps Script URL: ")
export TSS=$(ask "" "Turnstile sitekey: "); export TSK=$(ask "" "Turnstile secret: ")
export SU=$(ask "" "Supabase URL: "); export SA=$(ask "" "Supabase anon key: ")
export TGB=$(ask "" "Telegram bot token: "); export TGC=$(ask "" "Telegram chat id: ")
python3 - <<'PY'
import json,os
def rd(p,d):
    try:return json.load(open(p,encoding='utf-8'))
    except Exception:return d
def wr(p,o):json.dump(o,open(p,'w',encoding='utf-8'),ensure_ascii=False,indent=2)
e=os.environ.get
n=rd('networks.json',{}); a=n.setdefault('networks',[])[0] if n.get('networks') else None
for x in n.get('networks',[]):
    if x['id']=='adsterra':
        for z in ('top','mid','side','mobile','bottom','inarticle'):
            v=e('K_'+z) or ''
            if v:x['keys']['banner_'+z]=v
        for env,k in (('PU','popunder'),('SB','socialbar'),('IP','inpage')):
            if e(env):x['keys'][k]=e(env)
        if any(x['keys'].values()):x['enabled']=True
    if x['id']=='monetag' and e('MT'):x['enabled']=True;x['keys']['multitag']=e('MT')
wr('networks.json',n)
c=rd('ads-config.json',{})
if e('AC'):c['adsense_client']=e('AC')
if e('AS'):c['adsense_slot']=e('AS')
if e('MT'):c['monetag_src']=e('MT')
if e('MRZ'):c['monetag_rewarded_zone']=e('MRZ')
wr('ads-config.json',c)
o=rd('owner.json',{})
for env,k in (('HN','kuraimi_name'),('HA','kuraimi_account'),('HP','kuraimi_phone'),('HM','mfloos'),
 ('WA','whatsapp'),('TG','telegram'),('EM','email'),('UT','usdt_trc20'),('EP','endpoint'),
 ('SU','supabase_url'),('SA','supabase_anon'),('TGB','telegram_bot_token'),('TGC','telegram_chat')):
    if e(env):o[k]=e(env)
cc=o.setdefault('captcha',{})
if e('TSS'):cc['turnstile_site']=e('TSS')
if e('TSK'):cc['turnstile_secret']=e('TSK')
wr('owner.json',o)
k=rd('kuraimi.json',{})
for env,key in (('HN','holder'),('HA','account'),('HP','phone')):
    if e(env):k[key]=e(env)
wr('kuraimi.json',k)
cl=rd('cloud-config.json',{})
if e('SU'):cl['supabase_url']=e('SU')
if e('SA'):cl['supabase_anon']=e('SA')
wr('cloud-config.json',cl)
if e('P'):open('ads.txt','a',encoding='utf-8').write('\nadsterra.com, %s, DIRECT\n'%e('P'))
se={'ADSTERRA_API_KEY':'','MONETAG_API_KEY':e('MON'),'PROPELLER_API_KEY':e('PRO')}
open('secrets.template.env','w',encoding='utf-8').write('\n'.join('%s=%s'%(a,b) for a,b in se.items())+'\n')
print('  ✓ حُدّثت networks/ads-config/owner/kuraimi/cloud-config/ads.txt')
PY
bash deploy.sh main "activate v3 $(date -u +%FT%TZ)"
python3 tools/verify.py
