#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ماسح ومصلح توازن الأقواس للسكربتات الداخلية في HTML (يتخطى النصوص والتعليقات والتعبيرات النمطية)"""
import sys, os, re, json

OPEN="([{"; CLOSE=")]}"; PAIR={")":"(","]":"[","}":"{"}
KW=set("return typeof instanceof in of new delete void do else yield await case".split())
SCRIPT_RE=re.compile(r"<script\b([^>]*)>(.*?)</script\s*>", re.S|re.I)
NONJS=re.compile(r"""type\s*=\s*["']?(application/(ld\+)?json|text/(plain|template|html|x-template))""", re.I)
HAS_SRC=re.compile(r"""\bsrc\s*=""", re.I)

def blocks(html):
    out=[]
    for m in SCRIPT_RE.finditer(html):
        a=m.group(1) or ""
        if HAS_SRC.search(a) or NONJS.search(a): continue
        out.append({"start":m.start(2),"end":m.end(2),"text":m.group(2)})
    return out

def re_ok(ps,pw):
    if ps=="": return True
    if ps in "(,=:[!&|?{};+-*%~^<>": return True
    return pw in KW

def scan(src):
    stack=[]; extra=None; i=0; n=len(src); line=1
    st="code"; ps=""; word=""; pw=""
    while i<n:
        c=src[i]; nx=src[i+1] if i+1<n else ""
        if st=="code":
            if c=="\n": line+=1; i+=1; continue
            if c=="/" and nx=="/": st="lc"; i+=2; continue
            if c=="/" and nx=="*": st="bc"; i+=2; continue
            if c=="'": st="sq"
            elif c=='"': st="dq"
            elif c=="`": st="tpl"
            elif c=="/" and re_ok(ps,pw): st="rx"
            elif c in OPEN: stack.append((c,i,line))
            elif c in CLOSE:
                if not stack:
                    if extra is None: extra=(i,line,c)
                else:
                    o,oi,ol=stack.pop()
                    if PAIR[c]!=o and extra is None: extra=(i,line,c)
            if not c.isspace():
                ps=c
                if c.isalnum() or c in "_$": word+=c
                else:
                    if word: pw=word; word=""
            i+=1; continue
        if st=="lc":
            if c=="\n": st="code"
            i+=1; continue
        if st=="bc":
            if c=="*" and nx=="/": st="code"; i+=2; continue
            if c=="\n": line+=1
            i+=1; continue
        if st in ("sq","dq"):
            if c=="\\": i+=2; continue
            if (st=="sq" and c=="'") or (st=="dq" and c=='"'): st="code"
            if c=="\n": line+=1
            i+=1; continue
        if st=="tpl":
            if c=="\\": i+=2; continue
            if c=="`": st="code"
            if c=="\n": line+=1
            i+=1; continue
        if st=="rx":
            if c=="\\": i+=2; continue
            if c=="[": st="rxclass"
            elif c=="/": st="code"
            if c=="\n": st="code"
            i+=1; continue
        if st=="rxclass":
            if c=="\\": i+=2; continue
            if c=="]": st="rx"
            i+=1; continue
    return {"balanced": extra is None and not stack, "extra": extra, "stack": stack}

def note(r):
    if r["extra"]: return "قوس زائد '%s' في السطر %d" % (r["extra"][2], r["extra"][1])
    if r["stack"]: return "%d قوس غير مغلق (آخره '%s' سطر %d)" % (len(r["stack"]), r["stack"][-1][0], r["stack"][-1][2])
    return "سليم"

def cmd_scan(p):
    h=open(p,encoding="utf-8",errors="replace").read(); bs=blocks(h)
    out={"total":len(bs),"broken":0,"blocks":[]}
    for i,b in enumerate(bs):
        r=scan(b["text"]); ln=h[:b["start"]].count("\n")+1
        out["blocks"].append({"i":i,"line":ln,"balanced":r["balanced"],"note":note(r)})
        if not r["balanced"]: out["broken"]+=1
    print(json.dumps(out,ensure_ascii=False))

def cmd_fix(p):
    h=open(p,encoding="utf-8",errors="replace").read(); reps=[]
    for b in reversed(blocks(h)):
        r=scan(b["text"])
        if r["balanced"]: continue
        if r["extra"]:
            i,ln,c=r["extra"]; new=h[b["start"]:b["end"]][:i-b["start"]]+h[b["start"]:b["end"]][i-b["start"]+1:]
            reps.append("حذف '%s' زائد سطر %d"%(c,ln))
        else:
            tail="".join({"(":")","[":"]","{":"}"}[o] for o,_,_ in reversed(r["stack"]))
            new=h[b["start"]:b["end"]].rstrip()+"\n"+tail+"\n"
            reps.append("إغلاق %d قوس"%len(r["stack"]))
        h=h[:b["start"]]+new+h[b["end"]:]
    open(p,"w",encoding="utf-8").write(h)
    print(json.dumps({"repaired":len(reps),"how":reps},ensure_ascii=False))

def cmd_extract(p,d):
    os.makedirs(d,exist_ok=True)
    h=open(p,encoding="utf-8",errors="replace").read()
    for i,b in enumerate(blocks(h)):
        open(os.path.join(d,"blk%02d.js"%i),"w",encoding="utf-8").write(b["text"])
    print(d)

def cmd_replace_last(p,rp):
    h=open(p,encoding="utf-8",errors="replace").read(); bs=blocks(h); js=open(rp,encoding="utf-8").read()
    if not bs:
        h=h.replace("</body>","<script>\n"+js+"\n</script>\n</body>",1)
        open(p,"w",encoding="utf-8").write(h); print("added"); return
    b=bs[-1]; h=h[:b["start"]]+"\n"+js+"\n"+h[b["end"]:]
    open(p,"w",encoding="utf-8").write(h); print("replaced-last")

def cmd_sanitize(p,rp):
    h=open(p,encoding="utf-8",errors="replace").read(); js=open(rp,encoding="utf-8").read()
    used=False; n=0
    for b in reversed(blocks(h)):
        if scan(b["text"])["balanced"]: continue
        body=js if not used else "/* CineHub 3099 - كتلة مُبسّطة */"
        used=True
        h=h[:b["start"]]+"\n"+body+"\n"+h[b["end"]:]; n+=1
    if n==0:
        h=h.replace("</body>","<script>\n"+js+"\n</script>\n</body>",1); n=1
    open(p,"w",encoding="utf-8").write(h); print(json.dumps({"sanitized":n},ensure_ascii=False))

if __name__=="__main__":
    a=sys.argv[1:]
    {"scan":cmd_scan,"fix":cmd_fix,"extract":cmd_extract}.get(a[0],lambda *_:None)(*a[1:]) if a[0] in ("scan","fix","extract") else None
    if a[0]=="replace-last": cmd_replace_last(a[1],a[2])
    if a[0]=="sanitize": cmd_sanitize(a[1],a[2])
