# BPO KPI Validation Tool

A universal, browser-based tool for the testing stage of the BI lifecycle. It
independently recalculates common BPO KPIs from a source CSV, showing the full
working, so you can cross-check that a built dashboard's numbers are correct.

Open the HTML in any browser. No install, no internet, no server. Your file is
read locally and never leaves the device.

## The problem it solves
When a dashboard says "SLA = 87.4%", how do you know that measure is right? This
tool recalculates the same KPI straight from the source rows, at the same slice,
and shows its working. If the two numbers match, the dashboard measure is
validated. If they differ, you have caught a bug in the dashboard's logic before
it misleads anyone.

## How it works
1. **Upload** the cleaned source CSV (the same file the dashboard is built from).
2. **Map columns.** The tool auto-detects which column is the SLA flag, the
   timestamp, CSAT, etc., and shows the mapping. Correct any wrong guess; this is
   what makes it work on any company's CSV regardless of column names.
3. **Choose the slice** (agent, team/department, month) to match the view your
   dashboard is showing.
4. **Read the validated KPIs.** Each shows its value and formula. Expand a card to
   see the working (counts and intermediate numbers), paste your dashboard's
   number to get a MATCH / MISMATCH check, and view the exact rows that fed it.

## Adaptive KPI library
A KPI only appears if the columns it needs are mapped. Map an SLA column and you
get SLA Compliance; if the file has no QA column, that KPI is hidden and listed
as unavailable. Covered: Ticket Volume, SLA Compliance, Avg Handle/Resolution
Time, Avg CSAT, Avg QA Score, First Contact Resolution, Escalation Rate.

## Cross-check
Each KPI has an optional "Expected (from dashboard)" field. Type the number your
dashboard shows; the tool flags MATCH (within 0.1) or MISMATCH. This is the
source-vs-dashboard reconciliation at the heart of BI testing.

## Transparency
Every KPI exposes its formula, the counts and intermediate values, and a button
to reveal the actual rows that fed the calculation. Nothing is a black box, which
is the whole point of a validation tool.

## Note on flags
Boolean-style columns (SLA met, FCR, escalated) are read flexibly: true / 1 /
yes / y / met all count as true. If your data uses different markers, the row
drill-down lets you confirm the tool is reading them correctly.

## Files
- kpi_validator.html   the tool
- sample_tickets.csv   a sample file to try it on

## Requirements
Any modern browser. Nothing to install.
