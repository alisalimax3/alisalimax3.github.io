#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني ads-adult.json من المفاتيح الإباحية ويربطها، ويحقنها في صفحات adult/"""
import json, os, time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
E = {}
if os.path.exists("keys.env"):
    for ln in open("keys.env", encoding="utf-8"):
        s = ln.strip()
        if "=" in s and not s.startswith("#"):
            k, v = s.split("=", 1); E[k.strip()] = v.strip()
ADULT = [
 ("EXOCLICK_ZONE","ExoClick","€20","Paxum/Wire","ملك الإباحي — أعلى RPM",1),
 ("JUICYADS_ZONE","JuicyAds","$50","Paxum/BTC","إباحي صافي",1),
 ("TRAFFICJUNKY_ZONE","TrafficJunky","$100","Wire","حجم عالٍ",2),
 ("PLUGRUSH_ZONE","PlugRush","$25","PayPal/BTC","إباحي",2),
 ("CLICKADU_ZONE","Clickadu","$5","PayPal/Paxum","حد منخفض",2),
 ("HILLTOPADS_ZONE","HilltopAds","$50","PayPal","إباحي/عام",2),
 ("ADMAVEN_ZONE","AdMaven","$5","PayPal","بوب أندر قوي",2),
 ("EVADAV_ZONE","Evadav","$5","PayPal","إباحي",3),
 ("GALAKSION_ZONE","Galaksion","$10","PayPal","إباحي",3),
 ("MYBID_ZONE","MyBid","$25","PayPal","إباحي",3),
 ("TRAFFICSTARS_ZONE","TrafficStars","$100","Wire/Paxum","شبكة إباحية كبرى",2),
 ("STRIPCHAT_AFF","Stripchat","$50","Wire/Paxum","revshare لكل تسجيل",1),
 ("CHATURBATE_AFF","Chaturbate","$50","Wire/Paxum","revshare 20% مدى الحياة",1),
 ("JASMIN_AFF","LiveJasmin","$50","Wire","revshare عالي",2),
 ("BONGA_AFF","BongaCams","$50","Wire","revshare",2),
 ("FLIRT4FREE_AFF","Flirt4Free","$50","Wire","revshare",3),
 ("IMLIVE_AFF","ImLive","$50","Wire","revshare",3),
 ("STREAMATE_AFF","Streamate","$50","Wire","revshare",3),
 ("CAMSODA_AFF","CamSoda","$50","Wire","revshare",3),
 ("FANCENTRO_AFF","FanCentro","$50","Wire","اشتراكات",3),
 ("XHAMSTERLIVE_AFF","xHamsterLive","$50","Wire","revshare",3),
 ("JERKMATE_AFF","Jerkmate","$50","Wire","revshare",3),
 ("LOSPOLLOS","LosPollos","$50","PayPal","CPA إباحي — عائد لكل تسجيل",2),
 ("CRACKREVENUE","CrackRevenue","$50","PayPal","CPA إباحي",2),
 ("MOBIDEA_ADULT","Mobidea","$50","PayPal","CPA",3),
 ("ZEYDOO_ADULT","Zeydoo","$50","Paxum","CPA",3),
]
nets = []
for k, n, mn, pay, note, tier in ADULT:
    nets.append({"k": k, "n": n, "min": mn, "pay": pay, "note": note, "tier": tier, "id": E.get(k, ""), "enabled": bool(E.get(k))})
json.dump({"updated": time.strftime("%F %H:%M"), "count": len(nets),
           "enabled": len([x for x in nets if x["enabled"]]), "networks": nets},
          open("ads-adult.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
# حقن في صفحات adult/
n = 0
if os.path.isdir("adult"):
    for f in os.listdir("adult"):
        if not f.endswith(".html"): continue
        p = os.path.join("adult", f)
        s = open(p, encoding="utf-8").read()
        if "ads-adult.json" in s: continue
        s = s.replace("</body>", """<div class="aad" style="display:flex;justify-content:center;margin:14px 0" id="aad"></div>
<script>fetch('../ads-adult.json').then(r=>r.json()).then(a=>{const on=(a.networks||[]).filter(x=>x.id);
document.getElementById('aad').innerHTML=on.slice(0,2).map(x=>x.k==='EXOCLICK_ZONE'?
'<iframe src="https://s.exoclick.com/ads.php?type=300x250&zone='+x.id+'" width="300" height="250" frameborder="0" scrolling="no"></iframe>':
x.k==='JUICYADS_ZONE'?'<iframe src="https://adserver.juicyads.com/adshow.php?adzone='+x.id+'" width="300" height="250" frameborder="0" scrolling="no"></iframe>':'').join('');}).catch(function(){});</script>
</body>""", 1)
        open(p, "w", encoding="utf-8").write(s); n += 1
print("  ✓ ads-adult.json: %d شبكة (%d مفعّلة) · حُقن في %d صفحة" % (len(nets), len([x for x in nets if x["enabled"]]), n))
