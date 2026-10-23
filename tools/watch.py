#!/usr/bin/env python3
import os
import sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core, repo, registry, ledger
def cycle():
    repo.sync(); core.load_env()
    s = registry.stats()
    core.log("مزامنة | %d مصدر | %d بمفاتيح | %d ناقص | $%.2f" % (s["total"],s["with_key"],s["pending"],ledger.total()), "info")
def main(m=5):
    core.log("مزامنة كل %d دقيقة" % m, "info")
    while True:
        try: cycle()
        except KeyboardInterrupt: return
        except Exception as e: core.log(str(e),"err")
        time.sleep(m*60)
