#!/usr/bin/env bash
# يحل ENOSPC وينقل كاش npm خارج القسم الممتلئ
set -e
echo "قبل:"; df -h "$HOME" | tail -1
rm -rf "$HOME/.npm/_cacache" "$HOME/.cache/npm" 2>/dev/null || true
mkdir -p "$HOME/.npm-cache" "$HOME/tmp"
npm config set cache "$HOME/.npm-cache" 2>/dev/null || true
export TMPDIR="$HOME/tmp"
grep -q 'TMPDIR' "$HOME/.bashrc" 2>/dev/null || echo 'export TMPDIR=$HOME/tmp' >> "$HOME/.bashrc"
echo "بعد:"; df -h "$HOME" | tail -1
echo "✓ جاهز. جرّب: npx --yes wrangler pages deploy . --project-name=cinehub3099"
