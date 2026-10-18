#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
W="${1:-}"
if [ -z "$W" ]; then
  echo "استخدم: bash wallet.sh 0xعنوانك"
  echo "  ↑ اكتب العنوان الفعلي (42 خانة تبدأ 0x) — لا تكتب كلمة عربية"
  echo "  لإنشاء محفظة: ثبّت MetaMask أو Trust Wallet وانسخ عنوان Base"
  exit 1
fi
if ! printf '%s' "$W" | grep -Eq '^0x[0-9a-fA-F]{40}$'; then
  echo "✗ '$W' ليس عنوانًا"
  echo "  المطلوب بالضبط: 0x ثم 40 خانة hex (أرقام 0-9 وحروف a-f)"
  echo "  مثال صحيح: 0x1234567890abcdef1234567890abcdef12345678"
  exit 1
fi
python3 wallet.py "$W"
