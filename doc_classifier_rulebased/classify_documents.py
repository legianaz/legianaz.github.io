"""
classify_documents.py  -  Rule-based investment document classifier and renamer.

Drop investment PDFs in a folder, run the script, and it will:
  1. Convert each PDF to text
  2. Identify the document type by signature keywords
  3. Detect the document's posted date
  4. Use the fund name and legal entity you provide
  5. Propose a standardized new filename
  6. Write a review CSV so a human can spot-check before anything is renamed

Nothing is renamed automatically unless you pass --apply. By default it runs in
preview mode and only writes the review sheet, keeping a human in the loop.

Local only. Files are read in place; originals are not modified in preview mode.
"""
import argparse
import csv
import os
import re
import sys
from datetime import datetime

try:
    import pdfplumber
except ImportError:
    sys.exit("pdfplumber is required. Install with: pip install pdfplumber")


# --- document type rules ---------------------------------------------------
# Each type has signature phrases. Order matters: more specific types are
# checked first so a distribution that merely mentions "capital" is not
# misread as a capital call. Score = count of matched phrases; highest wins.

DOC_TYPES = [
    ("K-1", [
        r"schedule k-?1", r"form 1065", r"partner'?s share of income",
        r"section 199a",
    ]),
    ("Capital Call Notice", [
        r"capital call", r"capital call notice", r"drawdown",
        r"amount called", r"called capital",
    ]),
    ("Distribution Notice", [
        r"distribution notice", r"distribution amount", r"return of capital",
        r"realized gain", r"payment date",
    ]),
    ("Capital Account Statement", [
        r"capital account statement", r"capital account balance",
        r"beginning capital", r"ending capital",
    ]),
    ("Hedge Fund Statement", [
        r"hedge fund", r"net asset value", r"\bnav\b", r"performance fee",
        r"management fee",
    ]),
]


def extract_text(pdf_path):
    """Return the full text of a PDF, lowercased copy kept for matching."""
    parts = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            parts.append(page.extract_text() or "")
    return "\n".join(parts)


def classify(text):
    """Return (best_type, score, scores_dict) using keyword signatures."""
    low = text.lower()
    scores = {}
    for dtype, patterns in DOC_TYPES:
        hits = sum(1 for p in patterns if re.search(p, low))
        scores[dtype] = hits
    best = max(scores, key=scores.get)
    if scores[best] == 0:
        return ("Unknown", 0, scores)
    return (best, scores[best], scores)


def detect_date(text):
    """Find the most likely document date. Tries a few common formats.
    Prefers a date that follows a 'date' label; falls back to the first date."""
    labeled = re.search(
        r"(?:notice date|statement date|payment date|date)\s*[:\-]?\s*"
        r"([A-Z][a-z]+ \d{1,2},? \d{4}|\d{1,2}/\d{1,2}/\d{4}|\d{4}-\d{2}-\d{2})",
        text, re.IGNORECASE)
    candidate = labeled.group(1) if labeled else None

    if not candidate:
        m = re.search(
            r"([A-Z][a-z]+ \d{1,2},? \d{4}|\d{1,2}/\d{1,2}/\d{4}|\d{4}-\d{2}-\d{2})",
            text)
        candidate = m.group(1) if m else None

    if candidate:
        for fmt in ("%B %d, %Y", "%B %d %Y", "%m/%d/%Y", "%Y-%m-%d"):
            try:
                return (datetime.strptime(candidate.replace(",", "").strip()
                        if "%B" in fmt else candidate.strip(), fmt), False)
            except ValueError:
                continue

    # fallback for documents like K-1s that carry only a tax year.
    # use year-end and mark it as inferred so the reviewer knows.
    ty = re.search(r"tax year\s*[:\-]?\s*(\d{4})", text, re.IGNORECASE)
    if ty:
        return (datetime(int(ty.group(1)), 12, 31), True)

    return (None, False)


def safe(s):
    """Make a string safe for a filename."""
    s = re.sub(r"[^\w\s-]", "", s).strip()
    return re.sub(r"[\s]+", "_", s)


def build_name(date_obj, dtype, fund, entity, ext):
    date_str = date_obj.strftime("%Y-%m-%d") if date_obj else "UNKNOWN-DATE"
    return f"{date_str}_{safe(dtype)}_{safe(fund)}_{safe(entity)}{ext}"


def main():
    ap = argparse.ArgumentParser(description="Classify and rename investment PDFs.")
    ap.add_argument("--folder", required=True, help="folder containing the PDFs")
    ap.add_argument("--fund", help="fund name (prompted if omitted)")
    ap.add_argument("--entity", help="legal entity (prompted if omitted)")
    ap.add_argument("--apply", action="store_true",
                    help="actually rename files (default is preview only)")
    args = ap.parse_args()

    if not os.path.isdir(args.folder):
        sys.exit(f"Not a folder: {args.folder}")

    fund = args.fund or input("Fund name: ").strip()
    entity = args.entity or input("Legal entity: ").strip()

    pdfs = [f for f in sorted(os.listdir(args.folder)) if f.lower().endswith(".pdf")]
    if not pdfs:
        sys.exit("No PDF files found in that folder.")

    rows = []
    for fn in pdfs:
        path = os.path.join(args.folder, fn)
        try:
            text = extract_text(path)
        except Exception as e:
            rows.append({"original": fn, "type": "ERROR", "confidence": "",
                         "date": "", "proposed_name": "", "note": f"read failed: {e}"})
            continue

        dtype, score, scores = classify(text)
        date_obj, date_inferred = detect_date(text)
        ext = os.path.splitext(fn)[1]
        proposed = build_name(date_obj, dtype, fund, entity, ext) if dtype != "Unknown" else ""

        note = ""
        if dtype == "Unknown":
            note = "could not identify type - needs manual review"
        elif score == 1:
            note = "low confidence (only one keyword matched) - check this one"
        if date_obj is None and dtype != "Unknown":
            note = (note + "; " if note else "") + "date not found"
        elif date_inferred:
            note = (note + "; " if note else "") + "date inferred from tax year (year-end)"

        rows.append({
            "original": fn,
            "type": dtype,
            "confidence": score,
            "date": date_obj.strftime("%Y-%m-%d") if date_obj else "",
            "proposed_name": proposed,
            "note": note,
        })

    # write the review sheet
    report = os.path.join(args.folder, "classification_review.csv")
    with open(report, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["original", "type", "confidence",
                                          "date", "proposed_name", "note"])
        w.writeheader()
        w.writerows(rows)

    # print a readable summary
    print(f"\nProcessed {len(rows)} file(s). Fund: {fund} | Entity: {entity}\n")
    for r in rows:
        flag = "  " if not r["note"] else "! "
        print(f"{flag}{r['original']:<14} -> {r['type']:<26} "
              f"{r['date'] or 'no date':<12} {r['proposed_name']}")
        if r["note"]:
            print(f"    note: {r['note']}")

    print(f"\nReview sheet written: {report}")

    if args.apply:
        renamed = 0
        for r in rows:
            if r["proposed_name"] and r["type"] not in ("Unknown", "ERROR"):
                src = os.path.join(args.folder, r["original"])
                dst = os.path.join(args.folder, r["proposed_name"])
                # avoid clobbering: add a counter if needed
                i = 1
                base, ext = os.path.splitext(dst)
                while os.path.exists(dst):
                    dst = f"{base}_{i}{ext}"; i += 1
                os.rename(src, dst)
                renamed += 1
        print(f"Applied: renamed {renamed} file(s).")
    else:
        print("Preview mode. No files were renamed. Re-run with --apply to rename.")


if __name__ == "__main__":
    main()
