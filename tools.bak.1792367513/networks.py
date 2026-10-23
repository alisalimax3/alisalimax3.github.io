#!/usr/bin/env python3
"""يسحب الإيراد الحقيقي من واجهات الشبكات. كل شبكة بلا مفتاح تُسجّل خطأ واضحًا فقط."""
import os,json,urllib.request,datetime,time
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rd(p,d=None):
    try: return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception: return d
def wr(p,o): json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=2)
now=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None); day=now.strftime('%Y-%m-%d')
start=(now-datetime.timedelta(days=30)).strftime('%Y-%m-%d')
A={'revenue','revenue_usd','earnings','profit','total_revenue','amount'}
I={'impressions','impression','imps','impressions_count','views'}
C={'clicks','click','clicks_count'}
def deep(o,names):
    t=0.0
    if isinstance(o,dict):
        for k,v in o.items():
            if k.lower() in names and isinstance(v,(int,float,str)):
                try: t+=float(v)
                except Exception: pass
            elif isinstance(v,(dict,list)): t+=deep(v,names)
    elif isinstance(o,list):
        for v in o: t+=deep(v,names)
    return t
def api(url,hdr):
    rq=urllib.request.Request(url,headers=hdr)
    return json.load(urllib.request.urlopen(rq,timeout=45))
AD={
 'adsterra':lambda k:'https://api3.adsterratools.com/publisher/stats.json?start_date=%s&finish_date=%s&group_by=date'%(start,day),
 'monetag':lambda k:'https://api.monetag.com/v5/statistics?date_from=%s&date_to=%s&group_by=date'%(start,day),
 'propeller':lambda k:'https://api.propellerads.com/v5/statistics?from=%s&to=%s'%(start,day),
 'popads':lambda k:'https://www.popads.net/api/website_stats?key=%s&startdate=%s&enddate=%s'%(k,start,day),
}
HDR={'adsterra':lambda k:{'Accept':'application/json','X-API-Key':k},
 'monetag':lambda k:{'Accept':'application/json','Authorization':'Bearer '+k},
 'propeller':lambda k:{'Accept':'application/json','X-Api-Key':k},
 'popads':lambda k:{'Accept':'application/json'}}
nets=rd('networks.json',{'networks':[]}) or {'networks':[]}
manual=rd('revenue-manual.json',{}) or {}
res={'fetched_utc':now.strftime('%FT%TZ'),'window_days':30,'networks':{},'impressions':0,'clicks':0,'revenue':0.0,'errors':{}}
for n in nets.get('networks',[]):
    i=n['id']; env=n.get('api_env','%s_API_KEY'%i.upper()); k=(os.environ.get(env) or '').strip()
    rec={'impressions':0,'clicks':0,'revenue':0.0,'source':'none','error':'','enabled':n.get('enabled',False)}
    if i in manual:
        m=manual[i]; rec.update({x:m.get(x,rec[x]) for x in ('impressions','clicks','revenue')}); rec['source']='manual'
    elif k and i in AD:
        try:
            j=api(AD[i](k),HDR[i](k))
            rec.update(source=i,impressions=int(round(deep(j,I))),clicks=int(round(deep(j,C))),revenue=round(deep(j,A),6))
        except Exception as e:
            rec['source']=i; rec['error']='%s: %s'%(type(e).__name__,str(e)[:120]); res['errors'][i]=rec['error']
    elif k: rec['source']='manual-only'
    res['networks'][i]=rec
    if rec['source'] in (i,'manual'): res['impressions']+=rec['impressions'];res['clicks']+=rec['clicks'];res['revenue']+=rec['revenue']
res['revenue']=round(res['revenue'],6)
wr('revenue.json',res)
prev=rd('treasury.json',{}) or {}
wr('treasury.json',{'updated':now.strftime('%FT%TZ'),'total_30d':res['revenue'],
 'all_time_seen':round(max(prev.get('all_time_seen',0),res['revenue']),6),
 'by_network':{k:{'revenue':v['revenue'],'min_payout':(next((x.get('min_payout',5) for x in nets['networks'] if x['id']==k),5)),
  'progress':round(min(1,v['revenue']/max(1,(next((x.get('min_payout',5) for x in nets['networks'] if x['id']==k),5))))*100,1)} for k,v in res['networks'].items()},
 'path':'network -> USDT(TRC20) -> Binance P2P -> Kuraimi (YER)','swift':'KBMFYESAXXX'})
w=rd('wallet.json',{}) or {}; w['updated']=now.strftime('%Y-%m-%d %H:%M:%S'); w['lastTick']=int(time.time())
w['real_revenue']=res['revenue']; w['real_impressions']=res['impressions']; wr('wallet.json',w)
wr('heartbeat.json',{'t':now.strftime('%FT%TZ'),'ok':res['revenue']>0 or not res['errors'],'source':'multi',
 'nets_with_keys':sum(1 for n in nets['networks'] if any((n.get('keys') or {}).values())),
 'errors':res['errors'],'note':'ok=false يعني لا مفتاح واحد صالح بعد'})
print('nets:',len(nets['networks']),'revenue:',res['revenue'],'imp:',res['impressions'],'errors:',len(res['errors']))
