#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
U=alkazmybwhwr-dot; BR=main
echo "1) صلاحيات التوكن الحالي:"
URL=$(git remote get-url origin); TOK=$(echo "$URL" | sed -n 's|https://\([^@]*\)@.*|\1|p' | sed 's/.*://')
[ -n "$TOK" ] && curl -sI -H "Authorization: token $TOK" https://api.github.com/user | tr -d '\r' | sed -n 's/^[Xx]-[Oo]auth-[Ss]copes: /   /p'
echo
echo "2) أنشئ توكنًا جديدًا بهاتين الصلاحيتين (افتح الرابط):"
echo "   https://github.com/settings/tokens/new?scopes=repo,workflow&description=cinehub3099"
echo
printf "الصق التوكن الجديد (ghp_... أو github_pat_...): "; read -r T
[ -z "$T" ] && { echo "بلا تغيير"; exit 0; }
git remote set-url origin "https://$U:$T@github.com/$U/$U.github.io.git"
git config --global credential.helper store
echo "$T" > "$HOME/.git-token"; chmod 600 "$HOME/.git-token"
echo "3) اختبار:"; curl -sI -H "Authorization: token $T" https://api.github.com/user | tr -d '\r' | sed -n 's/^[Xx]-[Oo]auth-[Ss]copes: /   scopes: /p'
bash deploy.sh "$BR" "token refresh $(date -u +%FT%TZ)"
python3 tools/verify.py
