#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
TASKS=[{"id":"watch","t":"شاهد فيديو 15 ثانية","v":0.0005,"cap":60,"d":"لكل مقطع"},
{"id":"share","t":"شارك فيلمًا","v":0.0010,"cap":30,"d":"رابط حقيقي"},
{"id":"comment","t":"علّق على فيلم","v":0.0004,"cap":10,"d":"تعليق حقيقي"},
{"id":"streak","t":"حضور يومي","v":0.0020,"cap":1,"d":"مرة يوميًا"},
{"id":"key","t":"اربط مفتاح شبكة","v":0.0500,"cap":40,"d":"يُتحقق بوجود المفتاح"},
{"id":"survey","t":"أكمل استطلاعًا","v":0.0200,"cap":10,"d":"بوابة حقيقية"},
{"id":"invite","t":"ادعُ صديقًا","v":0.0100,"cap":50,"d":"بمعرّف الإحالة"}]
json.dump({"tasks":TASKS,"note":"معدلات معلنة","updated":datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("tasks.json","w"),ensure_ascii=False,indent=1)
r={}
try: r=json.load(open("rewards.json",encoding="utf-8"))
except Exception: r={}
t=sum(float(d.get("total") or 0) for d in (r.get("devices") or {}).values())
r["total"]=round(t,6); r["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
json.dump(r,open("rewards.json","w"),ensure_ascii=False,indent=1)
print("مهام",len(TASKS),"| مكافآت %.6f"%t)
