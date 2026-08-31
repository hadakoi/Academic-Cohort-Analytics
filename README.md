# Academic Cohort Analytics

## Project overview

Academic Cohort Analytics is a privacy-preserving data analytics project built around **7,729 student records across 25 academic programs and three cohorts**. The project uses Python and pandas for data cleaning and anonymization, MySQL for relational storage and analytical querying, and aggregate exports for downstream dashboard visualization.

The analysis focuses on CGPA distributions, program-level performance, cohort comparisons, percentile-based measures, ranking, threshold analysis, and statistical outliers using SQL techniques such as CTEs, views, joins, conditional aggregation, and window functions.

The dataset represents **cross-sectional snapshots of current second-, third-, and fourth-year cohorts**. Differences between cohorts therefore describe differences between groups at the time of collection and should not be interpreted as longitudinal improvement or decline of individual students.

## Privacy and anonymization

All student records used in this project have been anonymized to protect individual privacy. Personally identifiable information such as names, email addresses, roll numbers, enrollment identifiers, and other source-specific identifiers has been removed from the analytical dataset.

Anonymous student IDs are used only to support analysis within the project and do not contain information that can be used to identify the original students. No mapping between the anonymized IDs and the original student identities is retained.

This project is intended purely for academic, learning, and portfolio purposes. The data is used only to demonstrate data cleaning, relational database design, SQL analytics, and visualization techniques, and should not be used to identify, evaluate, or make decisions about individual students.

## Repository structure

```text
academic-cohort-analytics/
├── README.md
├── requirements.txt
├── .gitignore
├── data/
│   ├── academic_records.csv
│   ├── students.csv
│   ├── programs.csv
│   └── cohorts.csv
├── scripts/
│   ├── inspect_data.py
│   ├── clean_data.py       # cleaning + irreversible anonymization
│   └── load_mysql.py
├── sql/
│   ├── schema.sql
│   ├── indexes.sql
│   ├── data_validation.sql
│   ├── analysis.sql
│   ├── window_functions.sql
│   └── views.sql
├── reports/
│   ├── data_audit.md
│   ├── cleaning_report.md
│   └── key_findings.md
└── dashboard/
    ├── README.md
    └── exports/            # aggregate-only dashboard extracts
```

## Dataset and cleaning

The source workbooks contained **7,810 student records** across three master sheets. Additional program-code sheets were duplicated subsets of the master data and were therefore excluded from ingestion.

After validation and cleaning, **7,729 records** were retained. The cleaning pipeline removed blank/footer rows and excluded **81 third-semester records with missing CGPA values**. All retained CGPA values are numeric and validated against the expected **0–10 range**.

The final analytical dataset contains:

* `student_id` — anonymous unique student identifier
* `program_name` — normalized academic program
* `cohort` — `second_year`, `third_year`, or `fourth_year`
* `cgpa` — validated cumulative grade-point average

Detailed audit and cleaning decisions are documented in:

* `reports/data_audit.md`
* `reports/cleaning_report.md`

Aggregate findings from the cleaned dataset are summarized in `reports/key_findings.md`. All reported results are reproducible from the MySQL analytical layer.
