"""Generate fake investment documents as PDFs for testing the classifier.
All names, funds, and figures are fictional. No real entities."""
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
import os, random

OUT = "/home/claude/doc_classifier/sample_pdfs"
os.makedirs(OUT, exist_ok=True)

funds = [
    ("Evergreen Capital Partners III", "Evergreen GP LLC"),
    ("Summit Hedge Opportunities Fund", "Summit Advisors LP"),
    ("Blue Harbor Private Equity II", "Blue Harbor Management LLC"),
    ("Cedar Ridge Venture Fund", "Cedar Ridge Capital LP"),
]

def draw(fname, title, lines):
    c = canvas.Canvas(os.path.join(OUT, fname), pagesize=letter)
    w, h = letter
    c.setFont("Helvetica-Bold", 16)
    c.drawString(1*inch, h-1*inch, title)
    c.setFont("Helvetica", 11)
    y = h - 1.5*inch
    for ln in lines:
        c.drawString(1*inch, y, ln)
        y -= 0.28*inch
        if y < 1*inch:
            c.showPage(); c.setFont("Helvetica", 11); y = h-1*inch
    c.showPage()
    c.save()

# 1. Capital Call Notice
f, e = funds[0]
draw("doc1.pdf", "CAPITAL CALL NOTICE", [
    f"Fund: {f}",
    f"General Partner: {e}",
    "Notice Date: March 15, 2024",
    "Capital Call Number: 7",
    "",
    "Dear Limited Partner,",
    "This Capital Call Notice requests funding pursuant to your",
    "commitment. The amount called is USD 250,000.",
    "Due Date: March 30, 2024",
    "Please remit the called capital to the account below.",
])

# 2. Capital Account Statement
f, e = funds[2]
draw("doc2.pdf", "CAPITAL ACCOUNT STATEMENT", [
    f"Fund: {f}",
    f"Legal Entity: {e}",
    "Statement Date: December 31, 2024",
    "Period: Q4 2024",
    "",
    "Beginning Capital Balance: USD 1,200,000",
    "Contributions: USD 250,000",
    "Distributions: (USD 80,000)",
    "Net Income Allocation: USD 64,500",
    "Ending Capital Account Balance: USD 1,434,500",
])

# 3. Hedge Fund Statement
f, e = funds[1]
draw("doc3.pdf", "HEDGE FUND MONTHLY STATEMENT", [
    f"Fund: {f}",
    f"Investment Manager: {e}",
    "Statement Date: January 31, 2025",
    "",
    "Net Asset Value (NAV) per Unit: USD 1,082.45",
    "Units Held: 1,250.00",
    "Month-to-Date Return: 1.8%",
    "Year-to-Date Return: 1.8%",
    "Management Fee: USD 3,200",
    "Performance Fee Accrual: USD 1,150",
])

# 4. Distribution Notice
f, e = funds[3]
draw("doc4.pdf", "DISTRIBUTION NOTICE", [
    f"Fund: {f}",
    f"General Partner: {e}",
    "Notice Date: June 10, 2024",
    "Distribution Number: 3",
    "",
    "This Distribution Notice informs you of a distribution of",
    "proceeds from a portfolio realization.",
    "Total Distribution Amount: USD 420,000",
    "Return of Capital: USD 300,000",
    "Realized Gain: USD 120,000",
    "Payment Date: June 25, 2024",
])

# 5. K-1
f, e = funds[0]
draw("doc5.pdf", "SCHEDULE K-1 (FORM 1065)", [
    "Partner's Share of Income, Deductions, Credits, etc.",
    f"Partnership: {f}",
    f"Legal Entity: {e}",
    "Tax Year: 2024",
    "",
    "Part III - Partner's Share of Current Year Income",
    "Ordinary Business Income: USD 45,000",
    "Net Rental Real Estate Income: USD 0",
    "Interest Income: USD 2,300",
    "Dividend Income: USD 5,600",
    "Box 20 Code Z - Section 199A information included.",
])

# 6. A second capital call, different fund/date, to test variety
f, e = funds[1]
draw("doc6.pdf", "CAPITAL CALL NOTICE", [
    f"Fund: {f}",
    f"General Partner: {e}",
    "Notice Date: September 02, 2024",
    "Capital Call Number: 2",
    "Drawdown Amount: USD 175,000",
    "Funding Due Date: September 16, 2024",
])

# 7. An ambiguous-ish one: distribution that also mentions capital, to test priority
f, e = funds[2]
draw("doc7.pdf", "DISTRIBUTION NOTICE", [
    f"Fund: {f}",
    f"General Partner: {e}",
    "Notice Date: November 20, 2024",
    "This distribution includes a partial return of capital.",
    "Distribution Amount: USD 90,000",
])

print("Generated PDFs:")
for fn in sorted(os.listdir(OUT)):
    print(" ", fn)
