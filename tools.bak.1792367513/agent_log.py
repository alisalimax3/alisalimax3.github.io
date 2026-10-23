#!/usr/bin/env python3
import os
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
src=".state/log.txt"
if os.path.exists(src):
    L=open(src,encoding="utf-8",errors="replace").read().splitlines()[-150:]
    open("agent-log.txt","w",encoding="utf-8").write("\n".join(L))
print("agent-log ok")
