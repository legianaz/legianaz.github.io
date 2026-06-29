# Service Operations Dashboard (Web)

An interactive operations KPI dashboard for support-ticket performance. Open the
HTML file in any browser. No install, no internet, no server needed; everything,
including the charting library and the data, is bundled inside the one file.

## What it shows
Six headline KPIs (total tickets, SLA compliance, average resolution time,
average CSAT, escalation rate, first-contact resolution), each with a health
accent (green / amber / red) and a context note, plus seven charts with data
labels:
- Ticket volume by month
- Status breakdown
- SLA compliance by priority
- Average CSAT by priority
- Tickets by channel
- Volume by category
- Average resolution time by priority

## Interactivity
A date range with quick presets (Last 6 months, Last 12 months, All time) plus
custom start/end month dropdowns, and four filters (priority, channel, category,
status). Everything recomputes live in the browser. The footer shows the current
ticket count and date window.

## Design and storytelling choices
- Light, muted, professional palette.
- Consistent colour meaning: each priority keeps the same colour across every
  chart, so the colours are a language the viewer learns once. Categories and
  statuses likewise have fixed colours.
- Data labels on every chart, so values are read directly.
- Month names on the time axis (Jan 2024, not 2024-01).
- An 80% target line on the SLA chart, making pass/fail instant.
- Each chart has a one-line subtitle explaining what it shows.

## How it was built (end to end)
1. Started from a mock ticket dataset (1,000 rows).
2. Profiled it and found five columns had failed to generate.
3. Repaired those columns with realistic, lightly correlated values so the
   metrics tell a believable story (higher priority -> longer resolution ->
   lower CSAT and SLA).
4. Computed the KPI logic and built the dashboard, then verified it renders and
   the filters work using a headless browser.

## The data
ops_data_clean.csv is the cleaned dataset the dashboard is built from. It is
also embedded inside the HTML, so the dashboard runs even without the CSV
present. The CSV is included so the same data can be reused to build the
Power BI and Looker Studio versions.

## Note
All figures are from synthetic mock data and are illustrative only.

## Files
- ops_dashboard.html   the dashboard (open in a browser)
- ops_data_clean.csv   the underlying data
