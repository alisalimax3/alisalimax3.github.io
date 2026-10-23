#!/usr/bin/env python3
# CineHub 3099 · محرك المحتوى — Archive.org · Ophim · Eporner · YouTube · TMDB
import json, os, re, sys, time, urllib.request, urllib.parse
UA = {'User-Agent': 'Mozilla/5.0 (CineHub3099; +https://alisalimax3.github.io)'}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
def get(url, t=35):
    return json.loads(urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=t).read().decode('utf-8', 'ignore'))
def raw(url, t=35):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=t).read()
def slug(s):
    s = re.sub(r'[^a-zA-Z0-9\u0600-\u06FF ]', ' ', s or '')
    return (re.sub(r'\s+', '-', s.strip().lower())[:60] or 'item').strip('-')
def clean(h, n=230):
    return re.sub(r'\s+', ' ', re.sub('<[^>]+>', '', h or '')).strip()[:n]

def archive(q='collection:(feature_films) AND mediatype:(movies)', rows=48):
    p = [('q', q), ('rows', str(rows)), ('page', '1'), ('output', 'json'), ('sort[]', 'downloads desc')]
    p += [('fl[]', f) for f in ('identifier', 'title', 'year', 'description')]
    out = []
    for x in get('https://archive.org/advancedsearch.php?' + urllib.parse.urlencode(p)).get('response', {}).get('docs', []):
        t = (x.get('title') or '').strip()
        if not t: continue
        out.append({'src': 'archive', 'id': x['identifier'], 'title': t, 'year': x.get('year') or '',
                    'desc': clean(x.get('description')), 'embed': 'https://archive.org/embed/' + x['identifier'],
                    'thumb': 'https://archive.org/services/img/' + x['identifier']})
    return out

def ophim(pages=2, detail=18):
    out = []
    for pg in range(1, pages + 1):
        try: d = get('https://ophim1.com/danh-sach/phim-moi-cap-nhat?page=%d' % pg)
        except Exception: break
        for it in d.get('items', []):
            out.append({'src': 'ophim', 'id': it.get('slug'), 'title': it.get('name') or '',
                        'orig': it.get('origin_name') or '', 'year': (it.get('year') or ''),
                        'desc': clean(it.get('content')), 'embed': '', 'quality': it.get('quality') or '',
                        'lang': it.get('lang') or '', 'type': it.get('type') or '',
                        'thumb': 'https://img.ophim.live/uploads/movies/' + (it.get('thumb_url') or '')})
    for it in out[:detail]:
        try:
            d = get('https://ophim1.com/phim/' + it['id']).get('movie', {})
            eps = d.get('episodes') or []
            if eps and eps[0].get('server_data'):
                it['embed'] = eps[0]['server_data'][0].get('link_embed') or ''
        except Exception: pass
        time.sleep(0.25)
    return out

def eporner(rows=48, order='top-weekly'):
    try: d = get('https://www.eporner.com/api/v2/video/search/?query=&per_page=%d&page=1&thumbsize=big&order=%s&format=json' % (rows, order))
    except Exception: return []
    out = []
    for v in d.get('videos', []):
        out.append({'src': 'eporner', 'id': v['id'], 'title': v['title'],
                    'dur': int(v.get('length_min') or 0) * 60 + int(v.get('length_sec') or 0),
                    'views': v.get('views') or 0, 'thumb': (v.get('default_thumb') or {}).get('src', ''),
                    'embed': 'https://www.eporner.com/embed/%s/' % v['id'], 'keywords': v.get('keywords', '')})
    return out

CH = [('UCQq0F1Z9l2VvHFGRhRFAP7g', 'أفلام عربية'),
      ('UC5Bp7cB7p4G6u4x8n9rXm0Q', 'سينما'),
      ('UC7b0kKk1V6rN1lB0j1M0m6Q', 'وثائقي')]
def yt(cid):
    import xml.etree.ElementTree as ET
    ns = {'a': 'http://www.w3.org/2005/Atom', 'yt': 'http://www.youtube.com/xml/schemas/2015'}
    try: x = ET.fromstring(raw('https://www.youtube.com/feeds/videos.xml?channel_id=' + cid))
    except Exception: return []
    out = []
    for e in x.findall('a:entry', ns)[:14]:
        v = e.find('yt:videoId', ns).text
        out.append({'src': 'yt', 'id': v, 'title': e.find('a:title', ns).text,
                    'embed': 'https://www.youtube.com/embed/' + v, 'thumb': 'https://i.ytimg.com/vi/%s/hqdefault.jpg' % v})
    return out

def tmdb(key):
    if not key: return []
    out = []
    for kind in ('movie', 'tv'):
        try: d = get('https://api.themoviedb.org/3/trending/%s/week?api_key=%s&language=ar' % (kind, key))
        except Exception: continue
        for x in d.get('results', [])[:30]:
            t = x.get('title') or x.get('name') or ''
            if not t: continue
            out.append({'src': 'tmdb', 'id': str(x['id']), 'title': t,
                        'year': (x.get('release_date') or x.get('first_air_date') or '')[:4],
                        'desc': clean(x.get('overview')), 'rating': round(x.get('vote_average') or 0, 1),
                        'thumb': 'https://image.tmdb.org/t/p/w342' + x['poster_path'] if x.get('poster_path') else '',
                        'embed': 'https://www.youtube.com/embed?listType=search&list=' + urllib.parse.quote(t + ' trailer')})
    return out

def main():
    key = os.environ.get('TMDB_KEY', '')
    data = {'movies': [], 'series': [], 'adult': [], 'channels': [], 'updated': time.strftime('%Y-%m-%d %H:%M')}
    for name, fn in (('archive', archive), ('ophim', ophim), ('eporner', eporner)):
        try:
            r = fn(); print('  %-9s %d' % (name, len(r)))
        except Exception as e:
            r = []; print('  %-9s ✗ %s' % (name, e))
        if name == 'eporner': data['adult'] = r
        else: data['movies'] += r
    try:
        r = tmdb(key); data['movies'] += r; print('  %-9s %d' % ('tmdb', len(r)))
    except Exception as e: print('  tmdb ✗', e)
    for cid, label in CH:
        try:
            v = yt(cid)
            for x in v: x['channel'] = label
            data['channels'] += v
            print('  yt %-8s %d' % (label, len(v)))
        except Exception: pass
    os.makedirs('data', exist_ok=True)
    json.dump(data, open('data/index.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for k in ('movies', 'adult', 'channels'):
        json.dump(data[k], open('data/%s.json' % k, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('  المجموع: %d عنصر' % (len(data['movies']) + len(data['adult']) + len(data['channels'])))
    return data

if __name__ == '__main__':
    main()
