#!/usr/bin/env python3
import sys, os, json, csv, html, pathlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = pathlib.Path(__file__).resolve().parent.parent
KEYS = ROOT / "keys.env"

def env():
    d = {}
    if KEYS.exists():
        for l in KEYS.read_text(encoding="utf-8").splitlines():
            if "=" in l and not l.strip().startswith("#"):
                k, _, v = l.partition("="); d[k.strip()] = v.strip()
    return d

def ads(e):
    o = []
    if e.get("ADSTERRA_ZONE"):
        o.append('<script async src="//www.highperformanceformat.com/%s/invoke.js"></script>' % e["ADSTERRA_ZONE"])
    if e.get("MONETAG_MULTITAG"):
        o.append('<script src="//nap5k.com/tag/%s" data-cfasync="false"></script>' % e["MONETAG_MULTITAG"])
    if e.get("POPADS_SITE"):
        o.append('<!-- PopAds site: %s -->' % e["POPADS_SITE"])
    return "\n".join(o)

TPL = """<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — CineHub</title><meta name="description" content="{desc}">
{ads}
<style>body{{font-family:system-ui;max-width:760px;margin:auto;padding:16px;line-height:1.8;background:#111;color:#eee}}a{{color:#6cf}}.ad{{margin:18px 0;text-align:center}}</style>
</head><body><h1>{title}</h1><div class="ad">{ads}</div><p>{desc}</p>
<p><a href="../index.html">← كل الصفحات</a></p><div class="ad">{ads}</div></body></html>
"""

def main():
    n = 50
    if "--count" in sys.argv: n = int(sys.argv[sys.argv.index("--count") + 1])
    out = ROOT / "site" / "pages"
    if "--out" in sys.argv: out = pathlib.Path(sys.argv[sys.argv.index("--out") + 1]).expanduser()
    out.mkdir(parents=True, exist_ok=True)
    A = ads(env())
    src = ROOT / "data" / "titles.csv"; items = []
    if src.exists():
        with src.open(encoding="utf-8") as f:
            for r in csv.DictReader(f): items.append((r.get("title", "").strip(), r.get("desc", "").strip()))
    if not items: items = [("عمل %d" % i, "مراجعة وتفاصيل العمل رقم %d في CineHub." % i) for i in range(1, n + 1)]
    items = (items * ((n // len(items)) + 1))[:n]
    links = []
    for i, (t, d) in enumerate(items, 1):
        slug = "p%04d" % i
        (out / (slug + ".html")).write_text(TPL.format(title=html.escape(t), desc=html.escape(d), ads=A), encoding="utf-8")
        links.append('<li><a href="pages/%s.html">%s</a></li>' % (slug, html.escape(t)))
    (out.parent / "index.html").write_text(
        '<!doctype html><meta charset="utf-8"><title>CineHub</title>\n<h1>CineHub — %d صفحة</h1>\n%s\n%s'
        % (n, A, "<ul>" + "\n".join(links) + "</ul>"), encoding="utf-8")
    print("✓ وُلّدت %d صفحة في %s" % (n, out))

if __name__ == "__main__":
    main()
