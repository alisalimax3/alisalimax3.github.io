#!/usr/bin/env python3
import sys, os, re, json, subprocess, shutil
SR=re.compile(r"<script\b([^>]*)>(.*?)</script\s*>", re.S|re.I)
NONJS=re.compile(r"""type\s*=\s*["']?(application/(ld\+)?json|text/(plain|template|html|x-template))""", re.I)
HAS_SRC=re.compile(r"""\bsrc\s*=""", re.I)
def blocks(h):
    out=[]
    for m in SR.finditer(h):
        a=m.group(1) or ""
        if HAS_SRC.search(a) or NONJS.search(a): continue
        out.append({"start":m.start(2),"end":m.end(2),"text":m.group(2)})
    return out
def ncheck(txt,p):
    if not shutil.which("node"): return True,""
    open(p,"w",encoding="utf-8").write(txt)
    r=subprocess.run(["node","--check",p],capture_output=True,text=True)
    return r.returncode==0,(r.stderr or "")+(r.stdout or "")
def locate(txt):
    good,err=ncheck(txt,".check/_p.js")
    if good: return None
    L=err.split("\n")
    for i in range(len(L)-2):
        m=re.match(r"^.*?:(\d+)\s*$",L[i])
        if m and "^" in L[i+2]:
            ln=int(m.group(1)); caret=L[i+2].index("^"); msg=""
            for j in range(i+3,len(L)):
                if "SyntaxError" in L[j]: msg=L[j]; break
            lines=txt.split("\n")
            return {"off":sum(len(x)+1 for x in lines[:max(0,ln-1)])+caret,"line":ln,"caret":caret,"msg":msg.strip()}
    for l in L:
        if "SyntaxError" in l: return {"off":None,"line":None,"caret":None,"msg":l.strip()}
    return {"off":None,"line":None,"caret":None,"msg":"unknown"}
def repair(txt):
    log=[]
    for _ in range(8):
        d=locate(txt)
        if d is None: return txt,log
        off=d["off"]
        if off is None or off>len(txt):
            if "end of input" in d["msg"]: txt=txt.rstrip()+"\n)\n"; log.append("أُضيف )"); continue
            return txt,log+["تعذّر: "+d["msg"]]
        ch=txt[off] if off<len(txt) else ""
        txt=txt[:off]+txt[off+1:]
        log.append("حُذف '%s' سطر %s"%(ch,d["line"]))
    return txt,log
def fix_file(path):
    h=open(path,encoding="utf-8",errors="replace").read(); rep=[]
    for b in reversed(blocks(h)):
        good,_=ncheck(b["text"],".check/_b.js")
        if good: rep.append({"file":path,"status":"سليم","log":[]}); continue
        new,log=repair(b["text"]); good2,_=ncheck(new,".check/_b.js")
        if not good2:
            new="/* CineHub3099: كتلة أُزيلت (build %s) */"%os.environ.get("STAMP","")
            log.append("أُزيلت الكتلة")
        h=h[:b["start"]]+new+h[b["end"]:]
        rep.append({"file":path,"status":"أُصلحت" if good2 else "أُزيلت","log":log})
    open(path,"w",encoding="utf-8").write(h)
    return rep
if __name__=="__main__": print(json.dumps(fix_file(sys.argv[1]),ensure_ascii=False))
