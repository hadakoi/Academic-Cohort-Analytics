# Dashboard Guide

The dashboard should use aggregate SQL views rather than exposing individual records.

The verified aggregate exports are in `dashboard/exports/`. They contain only cohort, program, program-by-cohort, threshold, and CGPA-band summaries.

## Three-page Tableau design

### 1. Overview

Purpose: establish the scale and overall academic distribution.

- KPI cards: **7,729 students**, mean CGPA **7.31**, median CGPA **7.41**
- Cohort comparison for second year, third year, and fourth year
- Overall CGPA-band distribution
- Cohort distribution chart
- Optional aggregate histogram using approved CGPA bins

Primary sources: `vw_cohort_summary.csv` and `vw_cgpa_distribution.csv`.

### 2. Program Analysis

Purpose: compare programs while keeping sample size visible.

- Program mean CGPA
- Program median CGPA
- Percentage with CGPA ≥8.0
- Cohort filter
- Program × cohort mean-CGPA heatmap
- Student-count labels or a minimum-sample-size filter

Primary sources: `vw_branch_summary.csv`, `vw_branch_cohort_summary.csv`, and `vw_branch_cohort_thresholds.csv`.

### 3. Distribution & Comparison

Purpose: show spread, thresholds, and the strongest program/cohort combinations.

- CGPA-band distribution
- Standard deviation by cohort and program
- Cohort comparison of mean, median, and spread
- Threshold comparison for CGPA ≥6.0, ≥7.0, ≥8.0, and ≥9.0
- Strongest program/cohort combinations, preferably filtered to a meaningful sample size such as n ≥30

Primary sources: `vw_cgpa_distribution.csv`, `vw_branch_cohort_summary.csv`, and `vw_branch_cohort_thresholds.csv`.

## Tableau Public privacy rule

Use only aggregate extracts: `vw_cohort_summary`, `vw_branch_summary`, `vw_branch_cohort_summary`, `vw_branch_cohort_thresholds`, and `vw_cgpa_distribution`. Do not publish `student_id`, individual CGPA rows, rankings, or percentile views without a separate privacy review.

To refresh the aggregate extracts after loading MySQL:

```bash
.venv/bin/python scripts/export_dashboard.py
```
