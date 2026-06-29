# Local Sales ETL Pipeline (PowerShell)

Turn a raw sales CSV into a finished report in one command. The pipeline cleans
the data, validates it, reshapes it, calculates the numbers, and builds a
self-contained HTML dashboard plus summary CSVs for Excel or Power BI.

Everything runs locally. No network calls, no external tools, no database. The
source file is only ever read, never modified. Every step is written to disk and
logged, so the whole run is transparent and auditable.

---

## Quick start

Try it on the included sample file:

```powershell
.\run_pipeline.ps1 -InputPath ".\sample_sales.csv"
```

Then open the `sales_report.html` file in the new timestamped folder.

---

## The six stages

Data flows top to bottom. Each stage reads the file the previous stage wrote and
produces its own numbered file, so every step can be inspected on disk.

| # | Stage     | What it does                                          | Reads               | Writes                |
|---|-----------|-------------------------------------------------------|---------------------|-----------------------|
| 1 | Extract   | Read the source, check it has rows and columns        | the raw CSV         | 01_extracted.csv      |
| 2 | Clean     | Trim spaces, fill blanks, fix formats, drop empties, dedupe | 01_extracted.csv | 02_cleaned.csv     |
| 3 | Validate  | Quality gate; stops on bad data with a clear reason   | 02_cleaned.csv      | 03_validated.csv      |
| 4 | Transform | Derive the amount, parse dates, reshape to clean records | 03_validated.csv | 04_transformed.csv    |
| 5 | Aggregate | Totals, averages, top 10 products and customers, by month/day | 04_transformed.csv | 05_*.csv (5 files) |
| 6 | Load      | Build the HTML dashboard, copy final CSVs to output   | the 05_ files       | sales_report.html + CSVs |

Stage 3 is the gate. Data that passes continues; data that fails stops the run
with a readable reason so no misleading report is produced.

---

## Files in this folder

```
run_pipeline.ps1       The orchestrator. Runs all six stages in order.
01_extract.ps1         Stage 1
02_clean.ps1           Stage 2
03_validate.ps1        Stage 3 (the gate)
04_transform.ps1       Stage 4
05_aggregate.ps1       Stage 5
06_load.ps1            Stage 6
pipeline_common.ps1    Shared helpers: logging, progress, number/column tools
sample_sales.csv       A messy sample file for testing
README.md              This file
```

**Keep all files in the same folder.** Every stage loads `pipeline_common.ps1`
from its own directory at startup. If that file is not beside the script, the
stage cannot find its helpers and will fail. Move or copy the scripts as a set.

---

## Running the whole pipeline

Basic run:

```powershell
.\run_pipeline.ps1 -InputPath "C:\sales\raw.csv"
```

The pipeline tries to detect your columns automatically by matching common names
(Amount, Revenue, Customer, OrderDate, and so on). If a guess is wrong, name the
columns yourself. Your choices always win over the guessing:

```powershell
.\run_pipeline.ps1 -InputPath "C:\sales\raw.csv" `
    -AmountColumn "Revenue" -ProductColumn "Item" `
    -CustomerColumn "Client" -DateColumn "InvoiceDate" `
    -DateColumns "InvoiceDate" -NumberColumns "Revenue" -NameColumns "Client"
```

---

## Running a single stage

Each stage is a standalone script and can be run on its own, which is useful for
debugging one step or rebuilding just the dashboard.

The one rule: a stage reads the file the previous stage produced, so that input
file must already exist in the work folder. Stage 1 is the exception; it takes
your raw file directly.

Re-run just the cleaning step:

```powershell
.\02_clean.ps1 -WorkDir "C:\sales\run_folder\pipeline_work" `
    -LogPath "C:\sales\run_folder\run.log" `
    -NumberColumns "Amount" -DateColumns "OrderDate"
```

Rebuild only the dashboard after a styling change, without reprocessing:

```powershell
.\06_load.ps1 -WorkDir "C:\sales\run_folder\pipeline_work" `
    -OutputDir "C:\sales\run_folder" `
    -LogPath "C:\sales\run_folder\run.log" -SourceName "raw.csv"
```

---

## Parameters (orchestrator)

| Parameter         | Required | Purpose                                                        |
|-------------------|----------|----------------------------------------------------------------|
| `-InputPath`      | yes      | Path to the raw sales CSV                                       |
| `-OutputDir`      | no       | Where results go (defaults to a timestamped folder)            |
| `-AmountColumn`   | no       | Name of the amount/total column (else auto-detected)           |
| `-QuantityColumn` | no       | Used with -PriceColumn if there is no amount column            |
| `-PriceColumn`    | no       | Used with -QuantityColumn to calculate the amount              |
| `-ProductColumn`  | no       | Name of the product column (else auto-detected)                |
| `-CustomerColumn` | no       | Name of the customer column (else auto-detected)               |
| `-DateColumn`     | no       | Name of the date column (else auto-detected)                   |
| `-DateColumns`    | no       | Columns the cleaner should standardize to yyyy-MM-dd           |
| `-NumberColumns`  | no       | Columns the cleaner should treat as numbers                    |
| `-NameColumns`    | no       | Columns the cleaner should put into Title Case                 |

---

## What a finished run produces

A timestamped output folder containing:

- `sales_report.html` — the dashboard, double-click to open
- `summary.csv`, `top_products.csv`, `top_customers.csv`, `sales_by_month.csv`,
  `sales_by_day.csv` — the data for Excel or Power BI
- `run.log` — the full timestamped audit trail
- `pipeline_work\` — the numbered file from every stage, for inspection

---

## The validation gate

Stage 3 runs three checks:

1. **Can an amount be found?** An amount column, or a quantity + price pair to
   multiply. If neither exists, the run stops.
2. **Are the amounts numeric?** If 20% or more of rows have a non-numeric amount,
   the run stops. Fewer than that only warns, and those rows count as 0.
3. **Are dates readable?** If a date column exists but no value parses, it warns
   that the time breakdowns will be empty, but does not stop.

When a check stops the run, the reason is written to the screen and the log. Fix
the source file and run again.

---

## Governance notes

- **No data leaves the machine.** There are no network calls; all work stays in
  the output folder.
- **The source file is read-only to the pipeline.** It is opened, never modified.
- **Every step is logged and saved**, so the whole run is auditable after the fact.
- **Bad data is refused, not silently processed.** If validation fails, the run
  stops and explains why instead of producing a misleading report.

---

## Requirements

PowerShell 5.1 (built into Windows 10 and 11) or PowerShell 7 and above. Nothing
to install and no internet connection needed.
