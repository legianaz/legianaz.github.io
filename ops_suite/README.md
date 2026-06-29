# Operations Intelligence Suite

A four-page, role-based dashboard in a single self-contained HTML file. Open it
in any browser; no install, no internet, no server. Chart library and data are
bundled inside the file.

## The four pages

Each page answers one question for one audience, and shows only what serves that
question. Nothing is over-populated.

1. **Executive** &mdash; "Is the business healthy?" Revenue, profit, margin, CSAT,
   SLA, QA, with a revenue/profit trend, a CSAT trend, and a team scorecard. No
   agent-level detail; that lives deeper.
2. **Operations** &mdash; "Where is the pressure right now?" Volume, backlog,
   resolution time, escalations, and workload by team. Filterable by priority.
3. **Team Leader** &mdash; "Who on my team needs attention?" Agent ranking, QA,
   attendance, coaching flags, and productivity, scoped to a chosen team.
4. **Employee** &mdash; "How am I doing?" One agent's KPIs, QA trend, CSAT trend,
   and ticket history.

## Data storytelling

- Consistent colour meaning across every page. Priority is always the same four
  colours (Critical clay-red, High amber, Medium blue, Low sage). Categories and
  statuses have fixed colours too, so the colours are a language learned once.
- Health colours (green / amber / red) on KPI cards and QA pills, driven by the
  config below.
- Data labels on charts so values read directly.
- Month names on time axes; short context line under each chart title.
- The data is relational: an agent's numbers roll up to their team, and teams roll
  up to the company, so the same figure is consistent across all four pages.

## Changing thresholds and colours (the config block)

Near the top of the script inside the HTML there is a single block:

```javascript
const KPI_CONFIG = {
  SLA:        {target:85, good:85, warn:70, unit:'%'},
  CSAT:       {target:4.0, good:4.0, warn:3.2, unit:'/5'},
  QA:         {target:80, good:80, warn:70, unit:''},
  ...
};
const COLORS = { accent:'#5b7a99', priority:{C:'#c1796b',...}, ... };
```

To retune any KPI, change its `good` / `warn` numbers (a value at or above `good`
is green, at or above `warn` is amber, otherwise red; metrics where lower is
better use `invert:true`). To recolour anything, edit the `COLORS` block. You do
not need to touch any chart code.

## Data files (in /data)

The suite has the data embedded, but the source CSVs are included so the same
model can be rebuilt in Power BI or Looker Studio:
- agents.csv      roster: agent, team, team leader, tenure
- tickets.csv     one row per ticket, with revenue, profit, CSAT, SLA, etc.
- qa.csv          monthly QA score per agent, with coaching flag
- attendance.csv  monthly attendance per agent

All data is synthetic and for demonstration only.

## Requirements
Any modern browser. Nothing to install.
