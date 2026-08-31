# Cleaning and Anonymization Report

The approved irreversible-anonymization workflow was run against the master sheet of each supplied workbook.
Original workbooks, names, email-like learner IDs, enrollment IDs, roll numbers, status values, and mapping files were not written to the analytical output.

## File-level results

| File | Master sheet | Raw rows | Rows with source key | Blank/footer rows | Missing CGPA | Retained rows |
|---|---|---:|---:|---:|---:|---:|
| `III SEM Name List.xlsx` | `III SEM MASTER` | 2,789 | 2,785 | 2 | 81 | 2,704 |
| `V SEM Name List.xlsx` | `V SEM Master` | 2,630 | 2,626 | 2 | 0 | 2,626 |
| `VII SEM Name List.xlsx` | `VII SEM MASTER` | 2,403 | 2,399 | 2 | 0 | 2,399 |

## Validation summary

- Source identifiers used internally: 7,810
- Anonymous students generated: 7,729
- Analytical records retained: 7,729
- Source-keyed students excluded for missing CGPA: 81
- Duplicate source-identifier groups: 0
- Ambiguous source identifiers: 0
- Normalized program-label variant groups requiring review: 0
- Retained program categories: 25
- Retained CGPA range: 0.00–10.00

## Approved transformations

- III, V, and VII semester values were transformed to `second_year`, `third_year`, and `fourth_year`.
- `Current Program` was whitespace-normalized and retained as `program_name`; `Current Program Code` was removed.
- Missing CGPA rows were removed at the owner's request.
- CGPA was converted to numeric and validated within 0–10.
- Anonymous IDs are deterministic, sequential, and contain no source attributes.
