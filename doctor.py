#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CineHub Diagnostic System v2.0
نظام تشخيص شامل وذكي للتطبيق
"""

import os
import sys
import json
import ast
import subprocess
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
import hashlib

# الألوان
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

class CineHubDiagnostic:
    def __init__(self):
        self.base_path = Path.home() / "cinehub3099"
        self.reports = []
        self.critical_issues = []
        self.warnings = []
        self.fixed_issues = []
        self.missing_files = []
        self.broken_files = []
        
        # قائمة الملفات الحرجة المطلوبة
        self.required_structure = {
            "directories": [
                "tools", "data", "assets", "logs", 
                ".tmp", ".github/workflows", "content"
            ],
            "critical_files": [
                "tools/core.py",
                "tools/gh.py", 
                "tools/profile.py",
                "tools/selftest.py",
                "tools/agent.py",
                "tools/wizard.py",
            ],
            "config_files": [
                "keys.env",
                "data/profile.json",
                "data/agent_state.json",
                "data/vault.json",
                "ledger.json"
            ],
            "html_files": [
                "index.html",
                "adult.html",
                "adult-networks.html",
                "me.html",
                "rewards.html",
                "income.html"
            ]
        }
        
    def log(self, message: str, level: str = "info"):
        """تسجيل رسالة"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        if level == "error":
            print(f"{Colors.RED}[{timestamp}] ✗ {message}{Colors.END}")
            self.critical_issues.append(message)
        elif level == "warning":
            print(f"{Colors.YELLOW}[{timestamp}] ! {message}{Colors.END}")
            self.warnings.append(message)
        elif level == "success":
            print(f"{Colors.GREEN}[{timestamp}] ✓ {message}{Colors.END}")
            self.fixed_issues.append(message)
        elif level == "info":
            print(f"{Colors.BLUE}[{timestamp}] ℹ {message}{Colors.END}")
        elif level == "section":
            print(f"\n{Colors.CYAN}{Colors.BOLD}{'='*70}{Colors.END}")
            print(f"{Colors.CYAN}{Colors.BOLD}══ {message} ══{Colors.END}")
            print(f"{Colors.CYAN}{Colors.BOLD}{'='*70}{Colors.END}")
    
    def check_directory_structure(self) -> Dict:
        """التحقق من بنية المجلدات"""
        self.log("فحص بنية المجلدات", "section")
        
        results = {
            "existing": [],
            "missing": [],
            "created": []
        }
        
        for dir_name in self.required_structure["directories"]:
            dir_path = self.base_path / dir_name
            if dir_path.exists():
                results["existing"].append(dir_name)
                self.log(f"المجلد موجود: {dir_name}", "success")
            else:
                results["missing"].append(dir_name)
                self.log(f"المجلد مفقود: {dir_name}", "error")
                # إنشاء المجلد تلقائياً
                try:
                    dir_path.mkdir(parents=True, exist_ok=True)
                    results["created"].append(dir_name)
                    self.log(f"تم إنشاء المجلد: {dir_name}", "success")
                except Exception as e:
                    self.log(f"فشل إنشاء المجلد {dir_name}: {e}", "error")
        
        return results
    
    def check_file_exists(self, file_path: Path) -> bool:
        """التحقق من وجود ملف"""
        return file_path.exists() and file_path.is_file()
    
    def check_python_syntax(self, file_path: Path) -> Tuple[bool, Optional[str]]:
        """التحقق من صحة syntax بايثون"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                source = f.read()
            
            # محاولة compile
            compile(source, file_path.name, 'exec')
            return True, None
            
        except SyntaxError as e:
            error_msg = f"Syntax Error في السطر {e.lineno}: {e.msg}"
            return False, error_msg
        except Exception as e:
            return False, str(e)
    
    def check_json_validity(self, file_path: Path) -> Tuple[bool, Optional[str], Optional[dict]]:
        """التحقق من صحة JSON"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read().strip()
            
            # محاولة parse
            data = json.loads(content)
            return True, None, data
            
        except json.JSONDecodeError as e:
            # محاولة الإصلاح
            return False, f"JSON Error: {e.msg} (السطر {e.lineno})", None
        except Exception as e:
            return False, str(e), None
    
    def check_imports(self, file_path: Path) -> List[str]:
        """التحقق من الاستيرادات المفقودة"""
        missing = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                source = f.read()
            
            # استخراج الاستيرادات
            imports = re.findall(r'^(?:from|import)\s+(\w+)', source, re.MULTILINE)
            
            for module in set(imports):
                if module in ['sys', 'os', 'json', 're', 'time', 'datetime', 'random', 'hashlib', 'subprocess', 'ast', 'pathlib', 'typing']:
                    continue  # modules قياسية
                
                try:
                    __import__(module)
                except ImportError:
                    missing.append(module)
                    
        except Exception as e:
            self.log(f"فشل فحص الاستيرادات في {file_path}: {e}", "warning")
        
        return missing
    
    def analyze_file(self, file_path: Path, file_type: str = "python") -> Dict:
        """تحليل شامل لملف"""
        analysis = {
            "path": str(file_path),
            "exists": False,
            "readable": False,
            "size": 0,
            "syntax_valid": False,
            "syntax_error": None,
            "json_valid": False,
            "json_data": None,
            "missing_imports": [],
            "suggested_fix": None
        }
        
        if not self.check_file_exists(file_path):
            analysis["suggested_fix"] = f"إنشاء الملف: {file_path.name}"
            self.missing_files.append(str(file_path))
            return analysis
        
        analysis["exists"] = True
        
        # التحقق من القراءة
        try:
            with open(file_path, 'rb') as f:
                content = f.read()
            analysis["readable"] = True
            analysis["size"] = len(content)
        except Exception as e:
            analysis["suggested_fix"] = f"إصلاح صلاحيات الملف: {e}"
            return analysis
        
        # فحص حسب النوع
        if file_type == "python":
            valid, error = self.check_python_syntax(file_path)
            analysis["syntax_valid"] = valid
            analysis["syntax_error"] = error
            
            if not valid:
                analysis["suggested_fix"] = f"إصلاح خطأ Syntax: {error}"
                self.broken_files.append(str(file_path))
            
            # فحص الاستيرادات
            analysis["missing_imports"] = self.check_imports(file_path)
            
        elif file_type == "json":
            valid, error, data = self.check_json_validity(file_path)
            analysis["json_valid"] = valid
            analysis["syntax_error"] = error
            analysis["json_data"] = data
            
            if not valid:
                analysis["suggested_fix"] = f"إصلاح JSON: {error}"
                self.broken_files.append(str(file_path))
        
        return analysis
    
    def check_critical_files(self) -> Dict[str, Dict]:
        """التحقق من الملفات الحرجة"""
        self.log("فحص الملفات الحرجة", "section")
        
        results = {}
        
        # فحص ملفات Python
        for file_rel in self.required_structure["critical_files"]:
            file_path = self.base_path / file_rel
            self.log(f"فحص: {file_rel}")
            results[file_rel] = self.analyze_file(file_path, "python")
        
        # فحص ملفات JSON
        for file_rel in self.required_structure["config_files"]:
            file_path = self.base_path / file_rel
            self.log(f"فحص: {file_rel}")
            results[file_rel] = self.analyze_file(file_path, "json")
        
        # فحص HTML
        for file_rel in self.required_structure["html_files"]:
            file_path = self.base_path / file_rel
            if file_path.exists():
                self.log(f"فحص: {file_rel}")
        
        return results
    
    def check_dependencies(self) -> Dict:
        """التحقق من الاعتماديات الخارجية"""
        self.log("فحص الاعتماديات", "section")
        
        deps = {
            "python_version": sys.version,
            "required_packages": ["requests", "playwright", "beautifulsoup4"],
            "installed": [],
            "missing": []
        }
        
        for package in deps["required_packages"]:
            try:
                __import__(package)
                deps["installed"].append(package)
                self.log(f"✓ {package} مثبت", "success")
            except ImportError:
                deps["missing"].append(package)
                self.log(f"✗ {package} غير مثبت", "error")
        
        # التحقق من أدوات النظام
        tools = ["git", "curl", "python3"]
        for tool in tools:
            result = subprocess.run(["which", tool], capture_output=True)
            if result.returncode == 0:
                self.log(f"✓ {tool} متوفر", "success")
            else:
                self.log(f"✗ {tool} غير متوفر", "error")
        
        return deps
    
    def attempt_fix(self, file_path: Path, issue_type: str, details: Dict) -> bool:
        """محاولة إصلاح تلقائي"""
        self.log(f"محاولة إصلاح: {file_path.name}")
        
        try:
            if issue_type == "missing":
                # إنشاء ملف افتراضي
                if file_path.suffix == ".py":
                    self.create_default_python_file(file_path)
                elif file_path.suffix == ".json":
                    self.create_default_json_file(file_path)
                return True
                
            elif issue_type == "json_corrupt":
                # محاولة إصلاح JSON
                return self.fix_json_file(file_path, details)
                
            elif issue_type == "syntax_error":
                # لا يمكن إصلاح Syntax Error تلقائياً
                self.log(f"⚠️ خطأ Syntax يحتاج تدخل يدوي في: {file_path}", "warning")
                return False
                
        except Exception as e:
            self.log(f"فشل الإصلاح: {e}", "error")
            return False
    
    def create_default_python_file(self, file_path: Path):
        """إنشاء ملف Python افتراضي"""
        template = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
{file_path.stem} — تم إنشاؤه تلقائياً بواسطة نظام التشخيص
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def main():
    print("🚀 {file_path.stem} يعمل!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
'''
        file_path.write_text(template, encoding='utf-8')
        self.log(f"تم إنشاء ملف افتراضي: {file_path}", "success")
    
    def create_default_json_file(self, file_path: Path):
        """إنشاء ملف JSON افتراضي"""
        default_data = {}
        if "profile" in file_path.name:
            default_data = {
                "first": "Ali",
                "last": "Salim",
                "email": "alkazmybwhwr@gmail.com",
                "country": "MA",
                "city": "Casablanca"
            }
        elif "state" in file_path.name:
            default_data = {"completed": {}, "pending": {}}
        else:
            default_data = {}
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(default_data, f, ensure_ascii=False, indent=2)
        
        self.log(f"تم إنشاء JSON افتراضي: {file_path}", "success")
    
    def fix_json_file(self, file_path: Path, details: Dict) -> bool:
        """إصلاح ملف JSON تالف"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            # محاولات الإصلاح
            fixes = [
                # إزالة الفواصل الزائدة
                lambda x: x.rstrip().rstrip(',').rstrip(),
                # إضافة أقواس
                lambda x: '[' + x + ']' if not x.startswith('[') and not x.startswith('{') else x,
                # إصلاح علامات الاقتباس
                lambda x: x.replace("'", '"'),
            ]
            
            for fix in fixes:
                try:
                    fixed = fix(content)
                    data = json.loads(fixed)
                    # حفظ النسخة المصلحة
                    backup = file_path.with_suffix('.json.backup')
                    file_path.rename(backup)
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, ensure_ascii=False, indent=2)
                    self.log(f"تم إصلاح JSON: {file_path}", "success")
                    return True
                except:
                    continue
            
            return False
            
        except Exception as e:
            self.log(f"فشل إصلاح JSON: {e}", "error")
            return False
    
    def generate_report(self) -> str:
        """توليد تقرير شامل"""
        report = []
        report.append("=" * 70)
        report.append("CineHub Diagnostic Report")
        report.append(f"التاريخ: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("=" * 70)
        report.append("")
        
        # المشاكل الحرجة
        report.append("## المشاكل الحرجة")
        report.append(f"العدد: {len(self.critical_issues)}")
        for issue in self.critical_issues:
            report.append(f"  ✗ {issue}")
        report.append("")
        
        # التحذيرات
        report.append("## التحذيرات")
        report.append(f"العدد: {len(self.warnings)}")
        for warning in self.warnings:
            report.append(f"  ! {warning}")
        report.append("")
        
        # الملفات المكسورة
        report.append("## الملفات المكسورة/التالفة")
        report.append(f"العدد: {len(self.broken_files)}")
        for f in self.broken_files:
            report.append(f"  ✗ {f}")
        report.append("")
        
        # الملفات المفقودة
        report.append("## الملفات المفقودة")
        report.append(f"العدد: {len(self.missing_files)}")
        for f in self.missing_files:
            report.append(f"  ✗ {f}")
        report.append("")
        
        # ما تم إصلاحه
        report.append("## ما تم إصلاحه تلقائياً")
        report.append(f"العدد: {len(self.fixed_issues)}")
        for fix in self.fixed_issues:
            report.append(f"  ✓ {fix}")
        report.append("")
        
        # التوصيات
        report.append("## التوصيات")
        report.append("1. قم بتشغيل الاختبارات للتأكد: python3 tools/selftest.py")
        report.append("2. ثبت الحزم المفقودة: pip3 install requests playwright")
        report.append("3. راجع الملفات التي تحتوي على Syntax Errors يدوياً")
        report.append("4. تأكد من إعدادات GitHub في keys.env")
        report.append("")
        
        return "\n".join(report)
    
    def save_report(self):
        """حفظ التقرير"""
        report = self.generate_report()
        report_path = self.base_path / "logs" / f"diagnostic_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(report, encoding='utf-8')
        self.log(f"تم حفظ التقرير: {report_path}", "success")
        return report_path
    
    def run_full_diagnostic(self):
        """تشغيل التشخيص الكامل"""
        print(f"\n{Colors.MAGENTA}{Colors.BOLD}")
        print("╔" + "═" * 68 + "╗")
        print("║" + " " * 68 + "║")
        print("║" + "  🔍 CineHub Diagnostic System v2.0".center(68) + "║")
        print("║" + "  نظام التشخيص الشامل".center(68) + "║")
        print("║" + " " * 68 + "║")
        print("╚" + "═" * 68 + "╝")
        print(f"{Colors.END}\n")
        
        # 1. فحص البنية
        dir_results = self.check_directory_structure()
        
        # 2. فحص الملفات الحرجة
        file_results = self.check_critical_files()
        
        # 3. فحص الاعتماديات
        deps = self.check_dependencies()
        
        # 4. محاولة الإصلاح التلقائي
        self.log("محاولات الإصلاح التلقائي", "section")
        
        for file_rel, analysis in file_results.items():
            if not analysis["exists"]:
                file_path = self.base_path / file_rel
                self.attempt_fix(file_path, "missing", {})
            elif not analysis.get("json_valid") and file_rel.endswith(".json"):
                file_path = self.base_path / file_rel
                self.attempt_fix(file_path, "json_corrupt", analysis)
            elif not analysis.get("syntax_valid") and file_rel.endswith(".py"):
                file_path = self.base_path / file_rel
                self.attempt_fix(file_path, "syntax_error", analysis)
        
        # 5. حفظ التقرير
        report_path = self.save_report()
        
        # 6. الملخص النهائي
        self.log("الملخص النهائي", "section")
        print(f"\n{Colors.BOLD}الإحصائيات:{Colors.END}")
        print(f"  {Colors.RED}✗{Colors.END} مشاكل حرجة: {len(self.critical_issues)}")
        print(f"  {Colors.YELLOW}!{Colors.END} تحذيرات: {len(self.warnings)}")
        print(f"  {Colors.GREEN}✓{Colors.END} تم إصلاحه تلقائياً: {len(self.fixed_issues)}")
        print(f"  {Colors.RED}✗{Colors.END} ملفات مكسورة: {len(self.broken_files)}")
        print(f"  {Colors.RED}✗{Colors.END} ملفات مفقودة: {len(self.missing_files)}")
        
        print(f"\n{Colors.CYAN}التقرير المحفوظ: {report_path}{Colors.END}")
        
        # حالة النظام
        if len(self.critical_issues) == 0:
            print(f"\n{Colors.GREEN}{Colors.BOLD}✅ النظام يعمل بشكل صحيح!{Colors.END}")
            return 0
        elif len(self.critical_issues) < 3:
            print(f"\n{Colors.YELLOW}{Colors.BOLD}⚠️ النظام يعمل مع بعض المشاكل الطفيفة{Colors.END}")
            return 1
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}❌ النظام يحتاج إلى إصلاحات جوهرية{Colors.END}")
            return 2

def main():
    """النقطة الرئيسية"""
    diagnostic = CineHubDiagnostic()
    
    try:
        exit_code = diagnostic.run_full_diagnostic()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}تم إيقاف التشخيص بواسطة المستخدم{Colors.END}")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Colors.RED}خطأ غير متوقع: {e}{Colors.END}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
