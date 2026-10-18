#!/usr/bin/env python3
import sys,json,subprocess
t,v=sys.argv[1],sys.argv[2]
out=subprocess.run(['python3','tools/validate.py',t,v],capture_output=True,text=True).stdout
try: j=json.loads(out)
except Exception: j={'ok':True}
ex=''
if j.get('login'): ex='الحساب: '+j['login']+' · الصلاحيات: '+(j.get('scopes') or '—')
elif j.get('digits'): ex='الرقم: '+j['digits']
elif j.get('code'): ex='استجابة: '+str(j['code'])
j['extra']=ex
print(json.dumps(j,ensure_ascii=False))
