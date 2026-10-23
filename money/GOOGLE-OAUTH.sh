#!/usr/bin/env bash
# تفويض لمرة واحدة: يحصل على ADSENSE_ACCESS_TOKEN + GOOGLE_REFRESH_TOKEN
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
load(){ [ -f "$1" ] || return 0; while IFS= read -r l || [ -n "$l" ]; do case "$l" in ''|\#*) continue;; esac
 l="${l#export }"; k="${l%%=*}"; v="${l#*=}"; k="$(printf '%s' "$k"|tr -d '[:space:]')"
 case "$k" in ''|*[!A-Za-z0-9_]*) continue;; esac; v="${v%\"}";v="${v#\"}";v="${v%\'}";v="${v#\'}"
 printf -v "$k" '%s' "$v"; export "$k"; done < "$1"; }
load "$ROOT/keys.env"
[ -n "${GOOGLE_CLIENT_ID:-}" ] || { echo "أضف GOOGLE_CLIENT_ID و GOOGLE_CLIENT_SECRET من console.cloud.google.com"; exit 1; }
echo "تأكد أن Redirect URI مسجّل في Google Cloud: http://localhost:5599/"
python3 - "$ROOT" "$GOOGLE_CLIENT_ID" "${GOOGLE_CLIENT_SECRET:-}" <<'PY'
import http.server,socketserver,urllib.parse,urllib.request,json,sys,os,threading,webbrowser
root,cid,csec=sys.argv[1],sys.argv[2],sys.argv[3]; RED="http://localhost:5599/"
u="https://accounts.google.com/o/oauth2/v2/auth?"+urllib.parse.urlencode({"client_id":cid,"redirect_uri":RED,
 "response_type":"code","scope":"https://www.googleapis.com/auth/adsense.readonly","access_type":"offline","prompt":"consent"})
print("\nافتح هذا الرابط وأذن:\n"+u+"\n")
try: webbrowser.open(u)
except Exception: pass
code={}
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(s):
        code.update(urllib.parse.parse_qs(urllib.parse.urlparse(s.path).query))
        s.send_response(200); s.send_header("content-type","text/html; charset=utf-8"); s.end_headers()
        s.wfile.write("<h2>تم، ارجع للطرفية</h2>".encode()); threading.Thread(target=s.server.shutdown).start()
    def log_message(s,*a): pass
with socketserver.TCPServer(("",5599),H) as s: s.serve_forever()
c=(code.get("code") or [None])[0]
if not c: print("لا يوجد code"); raise SystemExit
d=json.load(urllib.request.urlopen(urllib.request.Request("https://oauth2.googleapis.com/token",
 data=urllib.parse.urlencode({"code":c,"client_id":cid,"client_secret":csec,"redirect_uri":RED,"grant_type":"authorization_code"}).encode())))
p=os.path.join(root,"keys.env"); txt=open(p).read() if os.path.exists(p) else ""
def put(k,v):
    global txt
    txt="\n".join(l for l in txt.split("\n") if not l.startswith(k+"="))
    txt+=f"\n{k}={v}"
put("ADSENSE_ACCESS_TOKEN",d.get("access_token","")); put("GOOGLE_REFRESH_TOKEN",d.get("refresh_token",""))
open(p,"w").write(txt.lstrip("\n"))
print("✔ حُفظ التوكن + refresh token في keys.env")
PY
