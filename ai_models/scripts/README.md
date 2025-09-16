# Step 1 — Synthetic data generation

This generator creates CSVs in `data/` matching the authoritative schema for AI ClassMate.

## Prerequisites
- Windows PowerShell
- Python 3.10+ installed and on PATH

## Setup (PowerShell)
```powershell
cd "D:\classmate ai"
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r scripts\requirements.txt
```

## Generate CSVs
```powershell
python scripts\data_gen.py
```

Outputs will be written to `data/`.

Counts (approx):
- 1000 students, 200 tutors, 5 admins
- 300 classes, weekly sessions, ~2000 enrollments
- invoices/payments/refunds, materials, announcements, messages, notifications, ratings
- event_interaction (~20k+) and weekly_demand aggregates

## Notes
- Fields typed as arrays are stored as JSON strings (e.g., `subjects_of_interest`, `subjects_taught`).
- Timestamps are ISO8601 with trailing `Z`.
- Monetary values are decimals with 2 places.
- Dataset is non-deterministic but seeded for reproducibility.
