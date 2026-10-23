#!/usr/bin/env python3
"""يسحب أرقام الإيراد الحقيقية من Adsterra API ويكتب revenue.json + heartbeat.json + payments.json"""
import os,json,urllib.request,datetime,time
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def rd(p,d=None):
    try: return json.load(open(os.path.join(R,p),encoding='utf-8'))
    except Exception: return d
def wr(p,o): json.dump(o,open(os.path.join(R,p),'w',encoding='utf-8'),ensure_ascii=False,indent=2)
now=datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None); day=now.strftime('%Y-%m-%d'); start=(now-datetime.timedelta(days=30)).strftime('%Y-%m-%d')
key=(os.environ.get('ADSTERRA_API_KEY') or '').strip()
prev=rd('revenue.json',{}) or {}
out={'source':'none','ok':False,'fetched_utc':now.strftime('%FT%TZ'),'window_days':30,
     'impressions':0,'clicks':0,'revenue':0.0,'by_day':[],'total_seen':prev.get('total_seen',0.0),'error':''}
def deep_sum(o,names):
    t=0.0
    if isinstance(o,dict):
        for k,v in o.items():
            if k.lower() in names and isinstance(v,(int,float,str)):
                try: t+=float(v)
                except Exception: pass
            elif isinstance(v,(dict,list)): t+=deep_sum(v,names)
    elif isinstance(o,list):
        for v in o: t+=deep_sum(v,names)
    return t
if key:
    try:
        u='https://api3.adsterratools.com/publisher/stats.json?start_date=%s&finish_date=%s&group_by=date'%(start,day)
        rq=urllib.request.Request(u,headers={'Accept':'application/json','X-API-Key':key})
        j=json.load(urllib.request.urlopen(rq,timeout=40))
        out.update(source='adsterra',ok=True,
          impressions=int(round(deep_sum(j,{'impressions','impression','imps'}))),
          clicks=int(round(deep_sum(j,{'clicks','click'}))),
          revenue=round(deep_sum(j,{'revenue','revenue_usd','earnings','profit'}),6))
        items=j.get('items') if isinstance(j,dict) else None
        if isinstance(items,list):
            for it in items[-31:]:
                if isinstance(it,dict):
                    out['by_day'].append({'d':it.get('date',''),'rev':round(deep_sum(it,{'revenue','revenue_usd','earnings'}),6)})
        out['total_seen']=round(max(out['total_seen'],out['revenue']),6)
    except Exception as e:
        out['source']='adsterra'; out['error']='%s: %s'%(type(e).__name__,e)
wr('revenue.json',out)
w=rd('wallet.json',{}) or {}
w['updated']=now.strftime('%Y-%m-%d %H:%M:%S'); w['lastTick']=int(time.time())
w['real_impressions']=out['impressions']; w['real_revenue']=out['revenue']; w['real_source']=out['source']
wr('wallet.json',w)
wr('heartbeat.json',{'t':now.strftime('%FT%TZ'),'ok':out['ok'],'source':out['source'],
   'note':'ok=يوجد مفتاح API وسُحبت أرقام حقيقية · none=لا مفتاح بعد','error':out['error']})
# ---- سكان سلسلة Base لرصد اشتراكات مدفوعة فعليًا ----
try:
    addr=(w.get('address') or '').strip()
    if addr.startswith('0x'):
        RPCS=['https://mainnet.base.org','https://base.llamarpc.com','https://base-rpc.publicnode.com']
        def rpc(m,p):
            b=json.dumps({'jsonrpc':'2.0','id':1,'method':m,'params':p}).encode(); last=None
            for u in RPCS:
                try:
                    rq=urllib.request.Request(u,data=b,headers={'Content-Type':'application/json'})
                    j=json.load(urllib.request.urlopen(rq,timeout=25))
                    if 'result' in j: return j['result']
                except Exception as e: last=e
            raise last or Exception('rpc')
        toks={'USDT':('0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2',6),'USDC':('0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',6)}
        latest=int(rpc('eth_blockNumber',[]),16); frm=max(0,latest-22000)
        topic2='0x'+addr.lower()[2:].rjust(64,'0')
        old=rd('payments.json',{'payments':[]}) or {'payments':[]}
        seen={p.get('tx') for p in old.get('payments',[])}
        for sym,(t,dec) in toks.items():
            try:
                logs=rpc('eth_getLogs',[{'fromBlock':hex(frm),'toBlock':'latest','address':t,
                  'topics':['0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',None,topic2]}])
                for lg in logs or []:
                    tx=lg.get('transactionHash','')
                    if tx in seen: continue
                    amt=int(lg.get('data','0x0'),16)/10**dec
                    old['payments'].append({'tx':tx,'sym':sym,'amount':round(amt,6),'block':int(lg.get('blockNumber','0x0'),16)})
                    seen.add(tx)
            except Exception: pass
        old['payments']=sorted(old['payments'],key=lambda x:x.get('block',0))[-500:]
        old['updated']=now.strftime('%FT%TZ'); old['address']=addr
        wr('payments.json',old)
except Exception as e:
    wr('payments.json',{'updated':now.strftime('%FT%TZ'),'error':str(e),'payments':[]})
print('stats:',out['source'],out['impressions'],'imp /',out['revenue'],'USD')
