#!/usr/bin/env python3
import json,os,html,time
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SITE=os.environ.get("SITE_URL","https://alisalimax3.github.io")
try: it=[x for x in json.load(open("catalog.json",encoding="utf-8")).get("items") or [] if x.get("mp")]
except Exception: print("لا كتالوج"); raise SystemExit
it=it[:300]; E=html.escape
open("feed.xml","w",encoding="utf-8").write(
'<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>CineHub 3099</title>'
'<link>%s</link><description>أفلام مجانية</description><language>ar</language></channel></rss>\n'%SITE
+"".join('<item><title>%s</title><link>%s/m/%s</link><enclosure url="%s" type="image/jpeg"/></item>\n'%(
 E(x.get("t")),SITE,x["mp"],E(x.get("th"))) for x in it))
print("  RSS: %d"%len(it))
