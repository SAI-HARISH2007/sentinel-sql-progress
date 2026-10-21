#!/usr/bin/env python3
"""Turn every generated report (.md) into a PDF.   python3 scripts/build_pdf.py
Run scripts/build_report.py first.  Needs:  pip install markdown weasyprint
Writes report/pdf/week-NN.pdf, report/pdf/PROJECT_REPORT_through_week_N.pdf, report/PROJECT_REPORT.pdf
"""
from pathlib import Path
import re
import markdown
from weasyprint import HTML

ROOT = Path(__file__).resolve().parent.parent
REPORT = ROOT / "report"
(REPORT / "pdf").mkdir(exist_ok=True)

CSS = """
@page { size: A4; margin: 18mm 16mm 18mm 16mm;
        @bottom-center { content: "Sentinel - DBMS mini project   |   page " counter(page); font-size: 8pt; color: #666; } }
body { font-family: 'DejaVu Sans', Arial, sans-serif; font-size: 9.5pt; line-height: 1.4; color: #111; }
h1 { font-size: 19pt; border-bottom: 2px solid #1f3a5f; padding-bottom: 4px; color: #1f3a5f; page-break-before: always; }
h1:first-of-type { page-break-before: avoid; }
h2 { font-size: 13pt; color: #1f3a5f; margin-top: 16px; }
h3 { font-size: 10.5pt; color: #333; }
table { border-collapse: collapse; width: 100%; margin: 8px 0; font-size: 8.5pt; }
th, td { border: 1px solid #bbb; padding: 3px 5px; vertical-align: top; text-align: left; }
th { background: #e8eef6; }
code { font-family: 'DejaVu Sans Mono', monospace; font-size: 8pt; background: #f2f2f2; padding: 0 2px; }
pre { background: #f6f8fa; border: 1px solid #ddd; padding: 5px; font-size: 4.9pt; line-height: 1.25;
      white-space: pre; overflow: hidden; page-break-inside: auto; }
pre code { background: none; padding: 0; font-size: 4.9pt; }
hr { border: 0; border-top: 1px solid #ccc; margin: 14px 0; }
a { color: #1f3a5f; text-decoration: none; }
"""

def render(md_path: Path, pdf_path: Path):
    text = md_path.read_text(encoding="utf-8")
    text = re.sub(r"\]\((?:\.\./)+[^)]*\)", "](#)", text)          # repo-relative links mean nothing inside a PDF
    html = markdown.markdown(text, extensions=["tables", "fenced_code", "sane_lists"])
    HTML(string=f"<html><head><meta charset='utf-8'><style>{CSS}</style></head><body>{html}</body></html>").write_pdf(str(pdf_path))
    print("wrote", pdf_path.relative_to(ROOT))

for p in sorted((REPORT / "pages").glob("week-*.md")):
    render(p, REPORT / "pdf" / (p.stem + ".pdf"))
for p in sorted(REPORT.glob("PROJECT_REPORT_through_week_*.md")):
    render(p, REPORT / "pdf" / (p.stem + ".pdf"))
render(REPORT / "PROJECT_REPORT.md", REPORT / "PROJECT_REPORT.pdf")
