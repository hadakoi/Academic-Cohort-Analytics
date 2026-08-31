USE academic_cohort_analytics;

CREATE OR REPLACE VIEW vw_cohort_summary AS
WITH ranked AS (
    SELECT
        ar.cohort_id,
        ar.cgpa,
        ROW_NUMBER() OVER (PARTITION BY ar.cohort_id ORDER BY ar.cgpa) AS row_num,
        COUNT(*) OVER (PARTITION BY ar.cohort_id) AS cohort_count
    FROM academic_records AS ar
), medians AS (
    SELECT cohort_id, AVG(cgpa) AS median_cgpa
    FROM ranked
    WHERE row_num IN (FLOOR((cohort_count + 1) / 2), CEIL((cohort_count + 1) / 2))
    GROUP BY cohort_id
)
SELECT
    c.cohort_name,
    c.semester_number,
    COUNT(*) AS student_count,
    ROUND(AVG(r.cgpa), 2) AS mean_cgpa,
    ROUND(m.median_cgpa, 2) AS median_cgpa,
    ROUND(MIN(r.cgpa), 2) AS minimum_cgpa,
    ROUND(MAX(r.cgpa), 2) AS maximum_cgpa,
    ROUND(STDDEV_SAMP(r.cgpa), 2) AS cgpa_stddev,
    ROUND(100 * AVG(r.cgpa >= 8), 2) AS pct_at_least_8,
    ROUND(100 * AVG(r.cgpa >= 9), 2) AS pct_at_least_9
FROM ranked AS r
JOIN medians AS m ON m.cohort_id = r.cohort_id
JOIN cohorts AS c ON c.cohort_id = r.cohort_id
GROUP BY c.cohort_id, c.cohort_name, c.semester_number, m.median_cgpa;

CREATE OR REPLACE VIEW vw_branch_summary AS
WITH ranked AS (
    SELECT
        ar.program_id,
        ar.cgpa,
        ROW_NUMBER() OVER (PARTITION BY ar.program_id ORDER BY ar.cgpa) AS row_num,
        COUNT(*) OVER (PARTITION BY ar.program_id) AS program_count
    FROM academic_records AS ar
), medians AS (
    SELECT program_id, AVG(cgpa) AS median_cgpa
    FROM ranked
    WHERE row_num IN (FLOOR((program_count + 1) / 2), CEIL((program_count + 1) / 2))
    GROUP BY program_id
)
SELECT
    p.program_name AS branch_name,
    COUNT(*) AS student_count,
    ROUND(AVG(r.cgpa), 2) AS mean_cgpa,
    ROUND(m.median_cgpa, 2) AS median_cgpa,
    ROUND(MIN(r.cgpa), 2) AS minimum_cgpa,
    ROUND(MAX(r.cgpa), 2) AS maximum_cgpa,
    ROUND(STDDEV_SAMP(r.cgpa), 2) AS cgpa_stddev,
    ROUND(100 * AVG(r.cgpa >= 8), 2) AS pct_at_least_8,
    ROUND(100 * AVG(r.cgpa >= 9), 2) AS pct_at_least_9,
    ROUND(100 * AVG(r.cgpa < 6), 2) AS pct_below_6
FROM ranked AS r
JOIN medians AS m ON m.program_id = r.program_id
JOIN programs AS p ON p.program_id = r.program_id
GROUP BY p.program_id, p.program_name, m.median_cgpa;

CREATE OR REPLACE VIEW vw_branch_cohort_summary AS
SELECT
    p.program_name AS branch_name,
    c.cohort_name,
    c.semester_number,
    COUNT(*) AS student_count,
    ROUND(AVG(ar.cgpa), 2) AS mean_cgpa,
    ROUND(STDDEV_SAMP(ar.cgpa), 2) AS cgpa_stddev,
    ROUND(MIN(ar.cgpa), 2) AS minimum_cgpa,
    ROUND(MAX(ar.cgpa), 2) AS maximum_cgpa,
    ROUND(100 * AVG(ar.cgpa >= 8), 2) AS pct_at_least_8,
    ROUND(100 * AVG(ar.cgpa >= 9), 2) AS pct_at_least_9
FROM academic_records AS ar
JOIN programs AS p ON p.program_id = ar.program_id
JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
GROUP BY p.program_id, p.program_name, c.cohort_id, c.cohort_name, c.semester_number;

CREATE OR REPLACE VIEW vw_branch_cohort_thresholds AS
WITH ranked AS (
    SELECT
        ar.program_id,
        ar.cohort_id,
        ar.cgpa,
        ROW_NUMBER() OVER (
            PARTITION BY ar.program_id, ar.cohort_id
            ORDER BY ar.cgpa
        ) AS row_num,
        COUNT(*) OVER (
            PARTITION BY ar.program_id, ar.cohort_id
        ) AS group_count
    FROM academic_records AS ar
), medians AS (
    SELECT
        program_id,
        cohort_id,
        AVG(cgpa) AS median_cgpa
    FROM ranked
    WHERE row_num IN (FLOOR((group_count + 1) / 2), CEIL((group_count + 1) / 2))
    GROUP BY program_id, cohort_id
)
SELECT
    p.program_name AS branch_name,
    c.cohort_name,
    COUNT(*) AS student_count,
    ROUND(AVG(r.cgpa), 2) AS mean_cgpa,
    ROUND(m.median_cgpa, 2) AS median_cgpa,
    SUM(r.cgpa >= 6) AS count_cgpa_at_least_6,
    ROUND(100 * AVG(r.cgpa >= 6), 2) AS pct_cgpa_at_least_6,
    SUM(r.cgpa >= 7) AS count_cgpa_at_least_7,
    ROUND(100 * AVG(r.cgpa >= 7), 2) AS pct_cgpa_at_least_7,
    SUM(r.cgpa >= 8) AS count_cgpa_at_least_8,
    ROUND(100 * AVG(r.cgpa >= 8), 2) AS pct_cgpa_at_least_8,
    SUM(r.cgpa >= 9) AS count_cgpa_at_least_9,
    ROUND(100 * AVG(r.cgpa >= 9), 2) AS pct_cgpa_at_least_9
FROM ranked AS r
JOIN medians AS m ON m.program_id = r.program_id AND m.cohort_id = r.cohort_id
JOIN programs AS p ON p.program_id = r.program_id
JOIN cohorts AS c ON c.cohort_id = r.cohort_id
GROUP BY p.program_id, p.program_name, c.cohort_id, c.cohort_name, m.median_cgpa;

CREATE OR REPLACE VIEW vw_cgpa_distribution AS
SELECT
    c.cohort_name,
    p.program_name AS branch_name,
    CASE
        WHEN ar.cgpa >= 9 THEN '9.0+'
        WHEN ar.cgpa >= 8 THEN '8.0–8.99'
        WHEN ar.cgpa >= 7 THEN '7.0–7.99'
        WHEN ar.cgpa >= 6 THEN '6.0–6.99'
        ELSE '<6.0'
    END AS cgpa_band,
    COUNT(*) AS student_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY c.cohort_id, p.program_id), 2) AS percentage_of_group
FROM academic_records AS ar
JOIN programs AS p ON p.program_id = ar.program_id
JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
GROUP BY c.cohort_id, c.cohort_name, p.program_id, p.program_name, cgpa_band;

CREATE OR REPLACE VIEW vw_student_rankings AS
WITH ranked AS (
    SELECT
        ar.student_id,
        p.program_name AS branch_name,
        c.cohort_name,
        ar.cgpa,
        DENSE_RANK() OVER (PARTITION BY ar.program_id ORDER BY ar.cgpa DESC) AS branch_rank,
        DENSE_RANK() OVER (PARTITION BY ar.cohort_id ORDER BY ar.cgpa DESC) AS cohort_rank,
        DENSE_RANK() OVER (PARTITION BY ar.program_id, ar.cohort_id ORDER BY ar.cgpa DESC) AS branch_cohort_rank
    FROM academic_records AS ar
    JOIN programs AS p ON p.program_id = ar.program_id
    JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
)
SELECT student_id, branch_name, cohort_name, ROUND(cgpa, 2) AS cgpa, branch_rank, cohort_rank, branch_cohort_rank
FROM ranked;

CREATE OR REPLACE VIEW vw_student_percentiles AS
SELECT
    ar.student_id,
    p.program_name AS branch_name,
    c.cohort_name,
    ROUND(ar.cgpa, 2) AS cgpa,
    ROUND(100 * PERCENT_RANK() OVER (ORDER BY ar.cgpa), 2) AS overall_percentile,
    ROUND(100 * PERCENT_RANK() OVER (PARTITION BY ar.program_id ORDER BY ar.cgpa), 2) AS branch_percentile,
    ROUND(100 * PERCENT_RANK() OVER (PARTITION BY ar.cohort_id ORDER BY ar.cgpa), 2) AS cohort_percentile,
    ROUND(100 * PERCENT_RANK() OVER (PARTITION BY ar.program_id, ar.cohort_id ORDER BY ar.cgpa), 2) AS branch_cohort_percentile
FROM academic_records AS ar
JOIN programs AS p ON p.program_id = ar.program_id
JOIN cohorts AS c ON c.cohort_id = ar.cohort_id;

CREATE OR REPLACE VIEW vw_relative_performance AS
SELECT
    ar.student_id,
    p.program_name AS branch_name,
    c.cohort_name,
    ROUND(ar.cgpa, 2) AS cgpa,
    ROUND(ar.cgpa - AVG(ar.cgpa) OVER (), 2) AS delta_from_overall_average,
    ROUND(ar.cgpa - AVG(ar.cgpa) OVER (PARTITION BY ar.program_id), 2) AS delta_from_branch_average,
    ROUND(ar.cgpa - AVG(ar.cgpa) OVER (PARTITION BY ar.cohort_id), 2) AS delta_from_cohort_average,
    ROUND(ar.cgpa - AVG(ar.cgpa) OVER (PARTITION BY ar.program_id, ar.cohort_id), 2) AS delta_from_branch_cohort_average
FROM academic_records AS ar
JOIN programs AS p ON p.program_id = ar.program_id
JOIN cohorts AS c ON c.cohort_id = ar.cohort_id;
