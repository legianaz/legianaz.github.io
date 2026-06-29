# Data Profiler (PowerShell)

A standalone data quality health check for any CSV. Point it at a file and it
tells you what is inside, how clean it is, and what to fix before you use it.

Runs locally. No network calls. The source file is only read, never modified.

## What it checks
- Row and column counts
- Duplicate rows
- Missing values and completeness % per column
- Data type per column (number, date, email, text), auto-detected
- Min, max, average, median on numeric columns
- Distinct value counts
- Invalid emails
- Unreadable dates
- Negative values in columns that should not have them (amount, price, hours, etc.)
- Outliers, using the IQR method (values beyond 1.5x the interquartile range)

## Run it
```powershell
.\profile_data.ps1 -CsvPath "C:\data\file.csv"
```
Try the included sample:
```powershell
.\profile_data.ps1 -CsvPath ".\test_data.csv"
```

## Output
A timestamped folder containing:
- data_profile.html    the visual report (double-click to open)
- data_profile.xlsx    native Excel, IF the ImportExcel module is installed
- profile_summary.csv + profile_columns.csv   the fallback if ImportExcel is absent

The HTML report is always produced. The script prints which Excel path it used.

## Dependencies
None required. For native .xlsx output, optionally install ImportExcel once:
```powershell
Install-Module ImportExcel -Scope CurrentUser
```
Without it, you get the same data as CSVs instead.

## A note on outliers
Outliers are flagged with the IQR method: sort the values, take the middle 50%
(between the 25th and 75th percentile), and flag anything sitting more than 1.5x
that range below or above it. It does not assume a bell curve, so it holds up on
the skewed data common in real business files.

## Requirements
PowerShell 5.1 (built into Windows 10/11) or PowerShell 7+.
