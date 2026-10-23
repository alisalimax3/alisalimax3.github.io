#!/usr/bin/env bash
# يحقن إعلانات البالغين في صفحات الإباحة فقط (ExoClick + JuicyAds + Adsterra + smartlink)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
cat > "$ROOT/adult-ads.js" <<JS
/* مولّد آليًا بواسطة ADULT-WIRE — إعلانات البالغين */
(function(){
var A={exoclick:"${EXOCLICK_ZONE:-}",juicyads:"${JUICYADS_ZONE:-}",plugrush:"${PLUGRUSH_ZONE:-}",
adsterra:"${ADSTERRA_PUB_ID:-}",smartlink:"${ADULT_SMARTLINK:-}"};
function s(src){var e=document.createElement("script");e.async=true;e.src=src;e.setAttribute("data-cinehub","adult");(document.body||document.documentElement).appendChild(e);}
function box(id){var d=document.createElement("div");d.id=id;d.style.cssText="margin:14px auto;text-align:center;max-width:100%";(document.body||document.documentElement).appendChild(d);return d;}
try{
 if(A.exoclick){box("exo-"+A.exoclick);s("https://syndication.exoclick.com/splash.php?idzone="+A.exoclick);}
 if(A.juicyads){s("https://js.juicyads.com/jp.php?u="+A.juicyads);}
 if(A.plugrush){s("https://js.plugrush.com/"+A.plugrush);}
 if(A.adsterra){box("adt-"+A.adsterra);var f=document.createElement("iframe");f.style.cssText="width:100%;max-width:728px;height:90px;border:0";
   f.setAttribute("data-src","adsterra");box("adt-wrap").appendChild(f);}
 if(A.smartlink){var a=document.createElement("a");a.href=A.smartlink;a.textContent="عرض خاص 🔥";a.style.cssText="display:inline-block;margin:10px;padding:8px 16px;background:#e11d48;color:#fff;border-radius:9px;text-decoration:none";document.body.appendChild(a);}
}catch(e){console.warn("adult-ads",e);}
window.CINEHUB_ADULT=A;
})();
JS
N=0
for f in "$ROOT"/*.html; do b="$(basename "$f")"
  case "$b" in adult*|*cams*|promote-adult*|adult-networks*|pb.html|go.html) ;;
    *) continue;; esac
  grep -q "adult-ads.js" "$f" && continue
  python3 - "$f" <<'PY'
import sys
p=sys.argv[1]; s=open(p,encoding="utf-8",errors="replace").read()
tag='<script src="/adult-ads.js" defer></script>'
s=s.replace("</head>",tag+"\n</head>",1) if "</head>" in s else tag+"\n"+s
open(p,"w").write(s)
PY
  N=$((N+1)); done
echo "  ✔ حقن إعلانات البالغين في $N صفحة"
echo "  ExoClick zone: ${EXOCLICK_ZONE:-غير مضبوط} | JuicyAds: ${JUICYADS_ZONE:-غير مضبوط} | smartlink: ${ADULT_SMARTLINK:-غير مضبوط}"
