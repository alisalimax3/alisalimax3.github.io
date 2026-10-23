#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""لوحة تحكم الأرباح الحقيقية"""
import json, os, sys
from datetime import datetime
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import core

def generate_dashboard():
    """توليد HTML dashboard"""
    
    # تحميل البيانات
    content = core.load("data/content_manifest.json", [])
    traffic = core.load("data/traffic_stats.json", {})
    revenue = core.load("data/revenue_report.json", {})
    registrations = core.load("data/registrations.json", [])
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>CineHub Profit Dashboard - REALITY</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; background: #1a1a2e; color: #eee; }}
        .header {{ background: #16213e; padding: 20px; border-radius: 10px; margin-bottom: 20px; }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }}
        .card {{ background: #0f3460; padding: 20px; border-radius: 10px; }}
        .metric {{ font-size: 2em; color: #e94560; }}
        .warning {{ background: #533; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #e94560; }}
        .success {{ background: #353; border-left: 4px solid #4e4; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
        th, td {{ padding: 10px; text-align: left; border-bottom: 1px solid #444; }}
        th {{ background: #16213e; }}
        .status-pending {{ color: orange; }}
        .status-approved {{ color: #4e4; }}
        .status-rejected {{ color: #e44; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🎬 CineHub Profit Dashboard</h1>
        <p>Reality Check: {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>
    </div>
    
    <div class="warning">
        <strong>⚠️ REALITY CHECK:</strong> This is a real business, not a get-rich-quick scheme.
        Expected first $100: 30-60 days. Full-time income: 12-24 months.
    </div>
    
    <div class="grid">
        <div class="card">
            <h3>📊 Traffic</h3>
            <div class="metric">{traffic.get('total_visits', 0):,}</div>
            <p>Total Visits (Projected)</p>
            <p>Organic: {traffic.get('organic', 0):,}</p>
            <p>Social: {traffic.get('social', 0):,}</p>
        </div>
        
        <div class="card">
            <h3>💰 Revenue (Projected)</h3>
            <div class="metric">${revenue.get('total_revenue', 0):.2f}</div>
            <p>Based on CPM and affiliate models</p>
            <p>RPM: ${revenue.get('total_revenue', 0) / max(traffic.get('total_visits', 1), 1) * 1000:.2f}</p>
        </div>
        
        <div class="card">
            <h3>📝 Content</h3>
            <div class="metric">{len(content)}</div>
            <p>Articles Generated</p>
            <p>Goal: 100 articles for traction</p>
        </div>
        
        <div class="card">
            <h3>🔗 Networks</h3>
            <div class="metric">{len([r for r in registrations if r['status'] == 'pending_approval'])}</div>
            <p>Pending Approval</p>
            <p>Registered: {len(registrations)}</p>
        </div>
    </div>
    
    <div class="card" style="margin-top: 20px;">
        <h3>📋 Network Registration Status</h3>
        <table>
            <tr><th>Network</th><th>Status</th><th>Expected</th><th>Revenue Model</th></tr>
            {''.join(f"<tr><td>{r['network']}</td><td class='status-{r['status'].replace('_', '-')}'>{r['status']}</td><td>{r.get('expected_approval', 'N/A')}</td><td>CPM/CPA</td></tr>" for r in registrations)}
        </table>
    </div>
    
    <div class="card" style="margin-top: 20px;">
        <h3>🎯 Daily Action Plan</h3>
        <ol>
            <li><input type="checkbox"> Create 1 article or video</li>
            <li><input type="checkbox"> Share on Twitter/Reddit</li>
            <li><input type="checkbox"> Check analytics</li>
            <li><input type="checkbox"> Build 1 backlink</li>
            <li><input type="checkbox"> Optimize 1 ad placement</li>
        </ol>
    </div>
    
    <div class="card success" style="margin-top: 20px;">
        <h3>✅ Next Steps</h3>
        <ol>
            <li>Complete registrations (CAPTCHA + email confirm)</li>
            <li>Wait for approvals (24h - 7 days)</li>
            <li>Generate 10 more content pieces</li>
            <li>Start SEO campaign</li>
            <li>Build social media presence</li>
        </ol>
    </div>
</body>
</html>"""
    
    with open("profit_dashboard.html", "w", encoding="utf-8") as f:
        f.write(html)
    
    print("✓ Dashboard generated: profit_dashboard.html")
    core.openurl(f"file://{os.path.abspath('profit_dashboard.html')}")

if __name__ == "__main__":
    generate_dashboard()
