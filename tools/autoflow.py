#!/usr/bin/env python3
import os
import sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, registry, repo, autoreg
T = {0:["adultadworld","trafficshop","exogroup","clickaine","eroadvertising","adspyglass",
        "pinkads","traforama","adamo","lospollos","datify","kmabiz","leadbit","crakrevenue",
        "zeydoo","adcombo","terraleads","adultmoda","porndough","wecamy","adultcams",
        "chaturbate","stripchat","bongacams","livejasmin","cam4","mfc"],
     1:["adsterra","monetag","popads","clickadu","aads","popcash","admaven","evadav"],
     2:[n["id"] for n in registry.by_cat("shortlinks")],
     3:["freecash","timewall","lootably","adgate","adgem","wannads","bitlabs","cpx","attapoll","cointiply","faucetpay"],
     4:["cpagrip","ogads","adworkmedia","adscend","maxbounty"],
     5:[n["id"] for n in registry.by_cat("cpa")]+[n["id"] for n in registry.by_cat("surveys")]}
SKIP_AFTER_FAIL = 2

def run(t=1, show=None, limit=0):
    if show is None: show = core.x11_alive()
    ids=[i for i in T.get(t,[]) if i in registry.BY_ID and not core.env(registry.by_id(i)["key_env"])]
    if limit: ids=ids[:limit]
    if not ids: core.log("لا شيء ناقص في المرحلة %d" % t,"ok"); return
    core.log("مرحلة %d: %d موقع" % (t,len(ids)),"info")
    ok=[];fail=[]
    for k,i in enumerate(ids,1):
        core.log("── [%d/%d] %s ──" % (k,len(ids),i),"info")
        try:
            (ok if autoreg.register(i,show=show) else fail).append(i)
        except KeyboardInterrupt: break
        except Exception as e: core.log("%s: %s" % (i,e),"err"); fail.append(i)
        time.sleep(1)
    core.log("نجح %d | فشل %d" % (len(ok),len(fail)), "ok" if ok else "warn")
    if fail: core.log("فشل: %s" % ", ".join(fail),"warn")
    core.log(repo.push("autoflow t%d +%d" % (t,len(ok)))[1],"info")
