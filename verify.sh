#!/data/data/com.termux/files/usr/bin/bash
say(){ printf '%-44s %s\n' "$1" "$2"; }
chk(){ c=$(curl -s -o /dev/null -w '%{http_code}' -m 12 "$1"); [ "$c" = "200" ] && say "$2" "✓ $c" || say "$2" "✗ $c"; }
echo "── فحص المصادر ──"
chk "https://api.themoviedb.org/3/movie/550?api_key=8265bd1679663a7ea12ac168da84d2e8" "TMDB"
chk "https://api.tvmaze.com/search/shows?q=test" "TVMaze"
chk "https://api.redgifs.com/v2/auth/temporary" "RedGifs"
chk "https://www.eporner.com/api/v2/video/search/?query=test&per_page=2&format=json" "EPORNER"
c=$(curl -s -o /dev/null -w '%{http_code}' -m 15 -X POST -H 'Content-Type: application/json' \
 -d '{"query":"{Page(perPage:2){media(type:ANIME,sort:POPULARITY_DESC){id}}}"}' https://graphql.anilist.co)
[ "$c" = "200" ] && say "AniList" "✓ $c" || say "AniList" "✗ $c"
echo "── فحص المشغّلات ──"
for u in https://vidlink.pro/movie/550 https://vidsrc.xyz/embed/movie/550 https://vidsrc.cc/v2/embed/movie/550 https://embed.su/embed/movie/550; do
  chk "$u" "$(echo $u | cut -d/ -f3)"
done
echo "── فحص النشر ──"
for f in index.html live.js sw.js partners.html identity.json; do
  chk "https://alisalimax3.github.io/$f" "/$f"
done
echo "── الميّت ──"
chk "https://api.consumet.org/anime/gogoanime/naruto" "api.consumet.org (متوقع ✗)"
