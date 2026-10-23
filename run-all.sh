#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099"
echo "╔══════════════════════════════════════════════════╗"
echo "║   CineHub — تنفيذ كامل متصل                       ║"
echo "╚══════════════════════════════════════════════════╝"
./run.sh check   || exit 1
./run.sh selftest|| exit 1
./run.sh mailtest
./run.sh captchatest
echo ""
echo "── ربط GitHub ──"
./run.sh ghlink cinehub3099
./run.sh dashboard --push
echo ""
echo "── تسجيل الشبكات الفورية ──"
./run.sh autoflow 1
./run.sh autoflow 2
echo ""
echo "── الحصاد ──"
./run.sh harvest --push
./run.sh table
echo ""
echo "✓ اكتمل — المزامنة: ./run.sh watch &"
