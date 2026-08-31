# Key Findings from the Approved Cleaned Dataset

These are aggregate observations from the 7,729 retained records, verified by running the MySQL 8 analytics layer. The reproducible SQL definitions are in `sql/analysis.sql` and the aggregate views in `sql/views.sql`.

## Overall

- Mean CGPA: **7.31**
- Median CGPA: **7.41**
- Standard deviation: **1.18**
- CGPA range: **0.00–10.00**

## CGPA bands

| Band | Students | Share |
|---|---:|---:|
| `<6.0` | 1,069 | 13.83% |
| `6.0–6.99` | 1,803 | 23.33% |
| `7.0–7.99` | 2,484 | 32.14% |
| `8.0–8.99` | 1,923 | 24.88% |
| `9.0+` | 450 | 5.82% |

## Cross-sectional cohort comparison

| Cohort | Students | Mean | Median | SD | At least 8 | At least 9 |
|---|---:|---:|---:|---:|---:|---:|
| Second year | 2,704 | 7.38 | 7.55 | 1.23 | 33.10% | 6.43% |
| Third year | 2,626 | 7.31 | 7.42 | 1.19 | 31.72% | 6.21% |
| Fourth year | 2,399 | 7.24 | 7.26 | 1.08 | 26.89% | 4.71% |

The fourth-year cohort has a lower median CGPA than the second-year cohort in this snapshot. This is a cohort-level difference only and must not be interpreted as individual academic decline.

## Program comparison

Among programs with the largest observed averages, the leading aggregate means were:

- Electronics and Communication Engineering: mean **7.66**, median **7.81**, n = **697**
- Computer Science and Engineering: mean **7.62**, median **7.79**, n = **1,724**
- Computer Science and Engineering (AI & Machine Learning): mean **7.61**, median **7.80**, n = **358**

Program comparisons should always display sample sizes because program cohorts are not equally sized.

## Program × cohort thresholds

The new MySQL view `vw_branch_cohort_thresholds` returns 69 available program-by-cohort groups. It includes mean, median, counts, and percentages at or above 6.0, 7.0, 8.0, and 9.0. Thresholds use `>=`.

| Program/cohort | n | Mean | Median | ≥6 | ≥7 | ≥8 | ≥9 |
|---|---:|---:|---:|---:|---:|---:|---:|
| ECE — second year | 239 | 8.07 | 8.29 | 95.40% | 87.45% | 61.51% | 18.41% |
| ECE — third year | 227 | 7.65 | 7.76 | 90.75% | 75.77% | 43.17% | 11.01% |
| ECE — fourth year | 231 | 7.25 | 7.37 | 88.31% | 62.77% | 22.51% | 3.90% |
| CSE — second year | 1,169 | 7.60 | 7.74 | 91.62% | 74.17% | 40.29% | 7.53% |
| CSE — third year | 295 | 7.89 | 8.20 | 89.83% | 80.68% | 55.25% | 14.92% |
| CSE — fourth year | 260 | 7.41 | 7.49 | 83.85% | 61.54% | 36.92% | 10.77% |
| Information Technology — second year | 1 | 3.98 | 3.98 | 0.00% | 0.00% | 0.00% | 0.00% |
| Information Technology — third year | 256 | 7.56 | 7.76 | 89.45% | 73.05% | 38.67% | 4.69% |
| Information Technology — fourth year | 231 | 7.44 | 7.55 | 87.88% | 66.23% | 35.93% | 6.93% |

The complete 69-row result is available at `dashboard/exports/vw_branch_cohort_thresholds.csv`. Small groups, such as the one-record Information Technology second-year group, should not be used for broad conclusions.

## IQR check

The overall first quartile is **6.55**, the third quartile is **8.18**, and the IQR is **1.63**. The 1.5×IQR lower and upper bounds are **4.105** and **10.625**. This supports treating unusually low/high observations as a statistical review topic rather than assigning labels to students.
