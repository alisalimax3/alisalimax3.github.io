#!/usr/bin/env python3
"""GitHub API عبر urllib — يتجاوز مشكلة TLS في curl على Termux"""
import json,sys,urllib.request,urllib.error
def call(path,token,method="GET",data=None):
    req=urllib.request.Request("https://api.github.com"+path,method=method,
        data=json.dumps(data).encode() if data is not None else None,
        headers={"Authorization":"Bearer "+token,"Accept":"application/vnd.github+json",
                 "User-Agent":"cinehub-agent","content-type":"application/json"})
    try:
        with urllib.request.urlopen(req,timeout=30) as r: return r.status,json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e: return e.code,{}
    except Exception as e: return 0,{"error":str(e)}
if __name__=="__main__":
    c=sys.argv[1]; t=sys.argv[2]
    if c=="whoami": print(json.dumps(call("/user",t)))
    elif c=="exists": print(call("/repos/"+sys.argv[3],t)[0])
    elif c=="create":
        s,d=call("/user/repos",t,"POST",{"name":sys.argv[3],"private":False,"description":"CineHub monetization + agent"})
        print(s, d.get("full_name",""))
    else: print("?")
