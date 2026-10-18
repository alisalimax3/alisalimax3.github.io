#!/usr/bin/env python3
# CineHub 3099 — نشر على Cloudflare Pages بلا npm ولا wrangler
import os, json, base64, mimetypes, uuid, getpass
from urllib.request import Request, urlopen
from urllib.error import HTTPError

API  = "https://api.cloudflare.com/client/v4"
PROJ = os.environ.get("PROJ", "cinehub3099")
HERE = os.path.dirname(os.path.abspath(__file__))
ENVF = os.path.expanduser("~/.cfenv")
SKIP = {"deploy.py", "deploy.sh", "fix-npm.sh", "README.md", "supabase.sql", ".cfenv"}

# ---------- BLAKE3 نقي (بدون أي مكتبة) ----------
IV=[0x6A09E667,0xBB67AE85,0x3C6EF372,0xA54FF53A,0x510E527F,0x9B05688C,0x1F83D9AB,0x5BE0CD19]
PERM=[2,6,3,10,7,0,4,13,1,11,12,5,9,14,15,8]
M32=0xFFFFFFFF; CHUNK_START,CHUNK_END,PARENT,ROOT=1,2,4,8; BLOCK_LEN,CHUNK_LEN=64,1024
def _rotr(x,n): return ((x>>n)|(x<<(32-n)))&M32
def _g(s,a,b,c,d,x,y):
    s[a]=(s[a]+s[b]+x)&M32; s[d]=_rotr(s[d]^s[a],16)
    s[c]=(s[c]+s[d])&M32;   s[b]=_rotr(s[b]^s[c],12)
    s[a]=(s[a]+s[b]+y)&M32; s[d]=_rotr(s[d]^s[a],8)
    s[c]=(s[c]+s[d])&M32;   s[b]=_rotr(s[b]^s[c],7)
def _round(s,m):
    _g(s,0,4,8,12,m[0],m[1]); _g(s,1,5,9,13,m[2],m[3])
    _g(s,2,6,10,14,m[4],m[5]); _g(s,3,7,11,15,m[6],m[7])
    _g(s,0,5,10,15,m[8],m[9]); _g(s,1,6,11,12,m[10],m[11])
    _g(s,2,7,8,13,m[12],m[13]); _g(s,3,4,9,14,m[14],m[15])
def _compress(cv,block,ctr,blen,flags):
    s=list(cv)+IV[0:4]+[ctr&M32,(ctr>>32)&M32,blen,flags]; m=list(block)
    for _ in range(7):
        _round(s,m); m=[m[i] for i in PERM]
    for i in range(8):
        s[i]^=s[i+8]; s[i+8]^=cv[i]
    return s
def _words(b):
    b=b+b"\x00"*(BLOCK_LEN-len(b))
    return [int.from_bytes(b[i:i+4],"little") for i in range(0,BLOCK_LEN,4)]
class _Out:
    __slots__=("cv","bw","ctr","blen","flags")
    def __init__(s,cv,bw,ctr,blen,flags): s.cv,s.bw,s.ctr,s.blen,s.flags=cv,bw,ctr,blen,flags
    def cv8(s): return _compress(s.cv,s.bw,s.ctr,s.blen,s.flags)[:8]
    def root32(s): return b"".join(w.to_bytes(4,"little") for w in _compress(s.cv,s.bw,0,s.blen,s.flags|ROOT)[:8])
def _chunk_out(chunk,idx,flags):
    blocks=[chunk[i:i+BLOCK_LEN] for i in range(0,len(chunk),BLOCK_LEN)] or [b""]; cv=IV
    for i,b in enumerate(blocks):
        fl=flags
        if i==0: fl|=CHUNK_START
        if i==len(blocks)-1: fl|=CHUNK_END
        if i==len(blocks)-1: return _Out(cv,_words(b),idx,len(b),fl)
        cv=_compress(cv,_words(b),idx,len(b),fl)[:8]
def _parent(l,r,flags): return _Out(IV,list(l)+list(r),0,BLOCK_LEN,flags|PARENT)
def _subtree(chunks,start,flags):
    if len(chunks)==1: return _chunk_out(chunks[0],start,flags)
    l=1
    while l*2<len(chunks): l*=2
    return _parent(_subtree(chunks[:l],start,flags).cv8(),_subtree(chunks[l:],start+l,flags).cv8(),flags)
def blake3(data):
    chunks=[data[i:i+CHUNK_LEN] for i in range(0,len(data),CHUNK_LEN)] or [b""]
    return _subtree(chunks,0,0).root32()
def cf_hash(data,path):
    return blake3(base64.b64encode(data)+os.path.splitext(path)[1][1:].encode("ascii")).hex()[:32]

# ---------- شبكة ----------
def call(method,url,headers,data=None,ctype=None,soft=False):
    r=Request(url,data=data,method=method)
    for k,v in headers.items(): r.add_header(k,v)
    if ctype: r.add_header("Content-Type",ctype)
    try:
        with urlopen(r) as resp: raw=resp.read()
    except HTTPError as e:
        raw=e.read()
        if soft:
            print("  (موجود مسبقًا)"); return {}
        try: msg=json.loads(raw).get("errors",raw[:300])
        except Exception: msg=raw[:300]
        print(f"✗ {method} → {e.code}: {msg}"); raise SystemExit(1)
    return json.loads(raw) if raw else {}
def multipart(fields):
    b="----cf"+uuid.uuid4().hex; out=b""
    for n,v in fields:
        out+=f"--{b}\r\nContent-Disposition: form-data; name=\"{n}\"\r\n\r\n{v}\r\n".encode()
    return out+f"--{b}--\r\n".encode(), f"multipart/form-data; boundary={b}"
def creds():
    if os.path.exists(ENVF):
        d={}
        for ln in open(ENVF):
            ln=ln.strip()
            if ln.startswith("export "): ln=ln[7:]
            if "=" in ln:
                k,v=ln.split("=",1); d[k]=v.strip().strip("'\"")
        if d.get("CF_EMAIL") and d.get("CF_GKEY"): return d["CF_EMAIL"],d["CF_GKEY"]
    print("أول مرة فقط — الصق بيانات Cloudflare (تُحفظ محليًا في ~/.cfenv):")
    em=input("  البريد الإلكتروني: ").strip()
    kk=getpass.getpass("  Global API Key: ").strip()
    with open(ENVF,"w") as f: f.write(f"export CF_EMAIL='{em}'\nexport CF_GKEY='{kk}'\n")
    os.chmod(ENVF,0o600); return em,kk

def main():
    em,key=creds(); H={"X-Auth-Email":em,"X-Auth-Key":key}
    acc=call("GET",f"{API}/accounts",H)["result"][0]["id"]; print("→ الحساب:",acc)
    call("POST",f"{API}/accounts/{acc}/pages/projects",H,
         json.dumps({"name":PROJ,"production_branch":"main"}).encode(),"application/json",soft=True)
    jwt=call("GET",f"{API}/accounts/{acc}/pages/projects/{PROJ}/upload-token",H)["result"]["jwt"]
    files=[]
    for root,_,names in os.walk(HERE):
        for n in names:
            if n in SKIP or n.startswith("."): continue
            p=os.path.join(root,n); files.append((os.path.relpath(p,HERE),open(p,"rb").read()))
    if not files: print("✗ لا ملفات للنشر"); raise SystemExit(1)
    payload=[]; manifest={}
    for rel,data in files:
        h=cf_hash(data,rel); manifest["/"+rel]=h
        payload.append({"key":h,"value":base64.b64encode(data).decode(),
                        "metadata":{"contentType":mimetypes.guess_type(rel)[0] or "application/octet-stream"},
                        "base64":True})
    JH={"Authorization":f"Bearer {jwt}","Content-Type":"application/json"}
    hashes=[p["key"] for p in payload]
    missing=call("POST",f"{API}/pages/assets/check-missing",JH,json.dumps({"hashes":hashes}).encode(),"application/json").get("result") or []
    todo=[p for p in payload if p["key"] in missing]
    if todo:
        print(f"→ رفع {len(todo)} ملف…")
        call("POST",f"{API}/pages/assets/upload",JH,json.dumps(todo).encode(),"application/json")
    call("POST",f"{API}/pages/assets/upsert-hashes",JH,json.dumps({"hashes":hashes}).encode(),"application/json")
    print("→ إنشاء النشر…")
    body,ct=multipart([("branch","main"),("manifest",json.dumps(manifest,separators=(",",":")))])
    d=call("POST",f"{API}/accounts/{acc}/pages/projects/{PROJ}/deployments",H,body,ct)
    print("\n✅ تم النشر:", d["result"]["url"])
    print("   الرابط الثابت: https://%s.pages.dev" % PROJ)

if __name__=="__main__": main()
