# Academic Cohort Analytics — Phase 1 Data Audit

**Audit status:** Read-only audit completed; no source workbook was modified and no cleaned dataset has been created.

## 1. Supplied workbooks

| File | Sheets | Master-sheet student rows | CGPA observations | CGPA range |
|---|---:|---:|---:|---:|
| `III SEM Name List.xlsx` | 23 | 2,785 | 2,704 | 0.00–10.00 |
| `V SEM Name List.xlsx` | 24 | 2,626 | 2,626 | 3.14–9.94 |
| `VII SEM Name List.xlsx` | 22 | 2,399 | 2,399 | 3.55–9.96 |

The master sheets are `III SEM MASTER`, `V SEM Master`, and `VII SEM MASTER`. Each workbook also contains sheets named with numeric program codes. Every non-master sheet checked is a subset of its workbook’s master sheet by `Enrollment ID`; these sheets must not be appended as additional student records.

The numeric program-code sheets are:

- III semester: 713, 902, 903, 904, 905, 906, 907, 909, 911, 924, 929, 931, 932, 933, 934, 953, 957, 958, 959, 961, 962, 968
- V semester: 902, 903, 904, 905, 906, 907, 909, 911, 924, 929, 931, 932, 933, 934, 953, 957, 958, 959, 961, 962, 964, 965, 968
- VII semester: 902, 903, 904, 905, 906, 907, 909, 911, 924, 929, 931, 932, 933, 934, 953, 957, 958, 959, 961, 962, 968

## 2. Columns and apparent types

The III- and V-semester master sheets contain these 11 columns:

`Enrollment ID`, `Current Program Code`, `Person Account: Current Program`, `Name`, `Current Semester`, `Roll Number`, `Status`, `Current Program`, `Lateral Student`, `Learner Id`, `CGPA`

The VII-semester master sheet contains the same columns plus `Type`.

Apparent types are:

- Numeric-looking: `Enrollment ID`, `Current Program Code`, `CGPA`
- Text/boolean-like: all other columns; `Lateral Student` contains `TRUE`/`FALSE`
- `Current Semester` contains one value per workbook: III, V, or VII
- No columns for gender, section, academic year, admission year, campus, SGPA, specialization, or email explicitly named `Email` were found

`Learner Id` contains email-like institutional learner identifiers and is therefore treated as email/identity data even though its header does not say “Email”.

## 3. Privacy-sensitive fields

| Field | Observation | Risk | Initial recommendation for public dataset |
|---|---|---|---|
| `Name` | Direct identity field; repeated names exist | Direct PII; names are not unique | Remove from analytical output; use only internally if needed for reconciliation |
| `Learner Id` | Unique and email-like | Direct contact/identity data | Remove from analytical output; possible private reconciliation key |
| `Enrollment ID` | Unique among populated master-sheet student rows | Institution-issued identifier; re-identification risk | Do not publish; possible private reconciliation key |
| `Roll Number` | Not unique in these exports | Identifier-like and unsuitable as a student key | Remove unless a specific documented use is approved |
| `Status` | Mostly `Regular`; V semester also has 3 `On Probation` records | Academic-status information; footer text is also present | Retain only if explicitly approved; remove export footer artefacts |
| `Lateral Student` | Boolean subgroup flag | Potentially sensitive educational attribute | Retain, transform, or remove only with approval |

The public analytical dataset should expose only anonymous IDs and approved analytical attributes. Individual-level rows should not be published to Tableau Public without an explicit decision.

## 4. Candidate source key for internal reconciliation

`Enrollment ID` is the strongest candidate observed: it is populated and unique for all apparent student rows in each master sheet, with no duplicate values within a master. `Learner Id` is also populated and unique, but it is email-like and should be treated as more sensitive. `Name` is duplicated, and `Roll Number` is heavily duplicated, so neither is safe as a primary matching key.

Across the three master sheets, there were zero overlaps for both `Enrollment ID` and `Learner Id`. This supports treating III, V, and VII as different current cross-sectional cohorts rather than automatically treating them as longitudinal records of the same students.

If approved, the internal process can validate `Enrollment ID` first, use `Learner Id` only as a controlled fallback/review field, flag ambiguous/missing cases, and then assign sequential public IDs such as `STU000001`. No source identifier would appear in the public dataset.

## 5. Data-quality observations

- Each master worksheet contains two blank rows and two export/footer rows after the student data. The footer text includes a confidentiality notice and a copyright notice; these are not student records and will require explicit removal during cleaning.
- No exact duplicate student rows were found within the master sheets during the initial audit.
- III semester has 81 missing CGPA values among 2,785 apparent student rows. V and VII have no missing CGPA values in their apparent student rows. The initial raw-sheet count of 83 also included two non-student/footer rows.
- All parsed CGPA values were numeric and within 0–10. III semester contains one value of exactly 0.00; this should be confirmed as valid rather than silently treated as missing.
- `Status` is not perfectly clean because of the export/footer text; V semester also contains three `On Probation` values.
- `Current Program Code` has 25 distinct codes across the union of the master sheets. Each code mapped to exactly one exact `Current Program` label in the audit, with no detected whitespace or case variants in the non-PII categorical fields.
- There is no explicit `Branch` column. The project will need a decision on whether `Current Program Code`/`Current Program` should serve as the branch/program dimension, and whether broader branch groupings are desired.

## 6. Cohort interpretation

The files represent current semester snapshots: III semester, V semester, and VII semester. For the proposed portfolio analysis these can be labeled second-year, third-year, and fourth-year cohorts, respectively, but comparisons must remain cross-sectional.

> The dataset contains cross-sectional snapshots of different academic cohorts. Differences between academic years therefore represent cohort-level differences and should not be interpreted as longitudinal improvement or decline of individual students.

## 7. Decisions required before cleaning

No transformation, anonymization, record removal, or MySQL load should begin until the owner confirms the field-level decisions and identifier strategy requested in the accompanying message.
