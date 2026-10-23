#!/bin/bash
# AGENT-EU.sh - الوكيل الأوروبي الذكي

set -e

# الألوان
G='\033[1;32m'
Y='\033[1;33m'
R='\033[1;31m'
B='\033[1;34m'
N='\033[0m'

MY_EMAIL="alkazmybwhwr@gmail.com"
STATE_FILE="data/eu_agent_state.json"

hd() { echo -e "\n${B}══ $1 ══${N}"; }
ok() { echo -e "${G}✓ $1${N}"; }
wrn() { echo -e "${Y}! $1${N}"; }
err() { echo -e "${R}✗ $1${N}"; }

check_requirements() {
    hd "التحقق من المتطلبات"
    
    # Python
    if ! command -v python3 &> /dev/null; then
        err "Python3 غير مثبت"
        exit 1
    fi
    ok "Python3 موجود"
    
    # Playwright
    if ! python3 -c "import playwright" 2>/dev/null; then
        wrn "تثبيت Playwright..."
        pip3 install playwright requests
        playwright install chromium
    fi
    ok "Playwright جاهز"
    
    # VPN/Proxy (اختياري لكن مفضل)
    if command -v nordvpn &> /dev/null; then
        ok "NordVPN موجود - يمكن الاتصال بخادم أوروبي"
    elif command -v expressvpn &> /dev/null; then
        ok "ExpressVPN موجود"
    elif pgrep -x "tor" > /dev/null; then
        ok "Tor يعمل على المنفذ 9050"
    else
        wrn "لا يوجد VPN - سيتم استخدام الاتصال المباشر"
        wrn "للحصول على أرباح أعلى، استخدم VPN أوروبي"
    fi
}

setup_vpn() {
    hd "إعداد VPN أوروبي (اختياري)"
    
    echo "اختر خادماً أوروبياً:"
    echo "1) 🇳🇱 هولندا (أعلى أرباح)"
    echo "2) 🇩🇪 ألمانيا"
    echo "3) 🇬🇧 المملكة المتحدة"
    echo "4) 🇫🇷 فرنسا"
    echo "5) تخطي (بدون VPN)"
    
    read -p "الاختيار [1-5]: " choice
    
    case $choice in
        1)
            if command -v nordvpn &> /dev/null; then
                nordvpn connect Netherlands
            elif command -v expressvpn &> /dev/null; then
                expressvpn connect "Netherlands - Amsterdam"
            fi
            ;;
        2)
            nordvpn connect Germany 2>/dev/null || expressvpn connect "Germany - Frankfurt" 2>/dev/null || true
            ;;
        3)
            nordvpn connect "United Kingdom" 2>/dev/null || true
            ;;
        4)
            nordvpn connect France 2>/dev/null || true
            ;;
        *)
            wrn "تخطي VPN"
            ;;
    esac
    
    # التحقق من IP
    sleep 2
    IP_INFO=$(curl -s https://ipinfo.io/json 2>/dev/null || echo "{}")
    COUNTRY=$(echo $IP_INFO | grep -o '"country": "[^"]*' | cut -d'"' -f4)
    CITY=$(echo $IP_INFO | grep -o '"city": "[^"]*' | cut -d'"' -f4)
    
    if [ -n "$COUNTRY" ]; then
        ok "الموقع الحالي: $CITY, $COUNTRY"
        if [ "$COUNTRY" = "NL" ] || [ "$COUNTRY" = "DE" ] || [ "$COUNTRY" = "GB" ]; then
            ok "✅ أنت في أوروبا - الأرباح مضمونة!"
        fi
    fi
}

run_agent() {
    hd "تشغيل الوكيل الأوروبي"
    
    # التحقق من App Password
    if [ -z "$GMAIL_APP_PASSWORD" ]; then
        wrn "GMAIL_APP_PASSWORD غير محدد"
        echo "أنشئ App Password من: https://myaccount.google.com/apppasswords"
        read -sp "أدخل App Password: " app_pass
        echo ""
        export GMAIL_APP_PASSWORD="$app_pass"
    fi
    
    # تشغيل الوكيل
    python3 tools/european_agent.py
    
    # حفظ النتائج
    if [ -f "$STATE_FILE" ]; then
        hd "النتائج المحفوظة"
        cat "$STATE_FILE" | python3 -m json.tool 2>/dev/null | head -30 || cat "$STATE_FILE"
    fi
}

show_status() {
    hd "حالة التسجيلات"
    python3 tools/european_agent.py status
}

# القائمة الرئيسية
case "${1:-menu}" in
    "run"|"start"|"")
        check_requirements
        setup_vpn
        run_agent
        ;;
    "status")
        show_status
        ;;
    "vpn-only")
        setup_vpn
        ;;
    "help"|"-h"|"--help")
        echo "الاستخدام: bash AGENT-EU.sh [run|status|vpn-only|help]"
        echo ""
        echo "  run       - تشغيل الوكيل الأوروبي (افتراضي)"
        echo "  status    - عرض حالة التسجيلات"
        echo "  vpn-only  - إعداد VPN فقط"
        echo ""
        echo "المتطلبات:"
        echo "  - Python3 + Playwright"
        echo "  - Gmail App Password"
        echo "  - VPN أوروبي (موصى به)"
        ;;
    *)
        echo "خيار غير معروف: $1"
        echo "استخدم: bash AGENT-EU.sh help"
        ;;
esac

echo ""
ok "اكتملت العملية!"
echo "📧 البريد المستخدم: $MY_EMAIL"
echo "🌍 للتشغيل مرة أخرى: bash AGENT-EU.sh"
