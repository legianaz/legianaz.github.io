# Attendance Analyzer (PowerShell)

Replaces a manual, error-prone attendance spreadsheet with a consistent,
repeatable, auditable tool. Reads a daily attendance CSV and reports hours
worked, late punches, overtime, and absences per employee.

Runs locally. No network calls. The source file is read, never modified.

## Why a script and not a spreadsheet
A spreadsheet can do this once. This tool does it the same way every time, with
the rules applied identically across every employee and every run, logged and
repeatable. It removes the copy-a-formula-wrong class of error and scales to any
number of employees instantly.

## Expected file format
One row per employee per day, with at least:
- an employee/name column
- a date column
- a time-in and a time-out column

Optional columns it will use if present:
- break-start and break-end (subtracted from hours)
- a status column (e.g. "Absent")

Column names are matched flexibly (TimeIn, ClockIn, Start, etc.).

## Rules (all configurable)
- Hours worked = (time-out - time-in) - (break-out - break-in)
- Late = time-in later than shift start + grace window
- Daily overtime = hours over the daily threshold (default 8) in a day
- Weekly overtime = hours over the weekly threshold (default 40) in a week
- Daily and weekly OT are reported separately and not reconciled
- Absence = a status of Absent/Leave/Off/No show, or a day with no work times

## Run it
```powershell
# defaults: 09:00 shift start, 0 grace, 8/day and 40/week OT
.\analyze_attendance.ps1 -CsvPath ".\test_attendance.csv"

# with a 15-minute grace period and an 8:30 shift
.\analyze_attendance.ps1 -CsvPath ".\timesheet.csv" -ShiftStart "08:30" -GraceMinutes 15
```

## Parameters
- -CsvPath          (required) the attendance file
- -ShiftStart       expected start time, 24h HH:mm (default 09:00)
- -GraceMinutes     minutes after start before a punch is late (default 0)
- -DailyOtThreshold hours/day before daily OT (default 8)
- -WeeklyOtThreshold hours/week before weekly OT (default 40)
- -OutputDir        where results go (default: a timestamped folder)

## Output
A timestamped folder containing:
- attendance_report.html   the dashboard (double-click to open)
- attendance_report.xlsx   native Excel, IF the ImportExcel module is installed
  (Summary, Daily detail, Weekly OT sheets)
- attendance_summary.csv + attendance_daily.csv + attendance_weekly_ot.csv
  the fallback if ImportExcel is absent

The HTML report is always produced. The applied rules are printed on the report
itself, so anyone reading it knows exactly how the numbers were derived.

## Dependencies
None required. For native .xlsx, optionally: Install-Module ImportExcel -Scope CurrentUser

## Requirements
PowerShell 5.1 (built into Windows 10/11) or PowerShell 7+.
