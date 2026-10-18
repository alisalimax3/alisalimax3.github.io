#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""فحص كامل: نحوي + روابط محلية + JSON + إحصاء — ويصلح ما يمكن إصلاحه"""
import os, re, json, sys, subprocess, shutil, datetime
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import jsrepair
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
SKIP={".git",".state",".check","node_modules","p","sites",".github"}
rep={"time":datetime.datetime.now(datetime.timezone.utc).isoformat(),"js":[],"json":[],"links":[],"missing":[],"counts":{}}
files=[]
for d,dirs,fs in os.walk("."):
    dirs[:]=[x for x in dirs if x not in SKIP]
    for f in fs: files.append(os.path.join(d,f)[2:])
rep["counts"]["files"]=len(files)
rep["counts"]["html"]=sum(1 for f in files if f.endswith((".html",".htm")))
rep["counts"]["json"]=sum(1 for f in files if f.endswith(".json"))

# JSON
for f in files:
    if not f.endswith(".json"): continue
    try: json.load(open(f,encoding="utf-8"))
    except Exception as e: rep["json"].append({"file":f,"error":str(e)})

# JS نحوي + إصلاح
for f in files:
    if f.endswith((".html",".htm")):
        try: rep["js"]+=jsrepair.fix_file(f)
        except Exception as e: rep["js"].append({"file":f,"status":"خطأ","log":[str(e)]})

# روابط محلية
LOCAL=re.compile(r"""(?:href|src)\s*=\s*["']([^"'#?]+)""",re.I)
present={f for f in files}
for f in files:
    if not f.endswith((".html",".htm")): continue
    h=open(f,encoding="utf-8",errors="replace").read()
    for m in LOCAL.finditer(h):
        u=m.group(1).strip()
        if u.startswith(("http:","https:","//","data:","mailto:","tel:","javascript:")) or u=="": continue
        if u.startswith("/"): u=u[1:]
        if u not in present: rep["missing"].append({"page":f,"ref":u})

bad_js=[x for x in rep["js"] if x["status"]!="سليم"]
rep["counts"]["inline_blocks"]=len(rep["js"])
rep["counts"]["broken_js"]=len(bad_js)
json.dump(rep,open("audit-report.json","w"),ensure_ascii=False,indent=1)
print("ملفات:",rep["counts"]["files"],"| html:",rep["counts"]["html"],"| كتل js:",rep["counts"]["inline_blocks"],"| مكسورة:",rep["counts"]["broken_js"])
print("json معطوب:",len(rep["json"]),"| روابط محلية مفقودة:",len(rep["missing"]))
for x in bad_js: print("   ",x["file"],x["status"]," | ".join(x["log"]))
for x in rep["missing"][:10]: print("    رابط مفقود:",x["ref"],"في",x["page"])
