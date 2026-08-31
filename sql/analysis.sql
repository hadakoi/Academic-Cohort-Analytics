USE academic_cohort_analytics;

-- Overall count, mean, range, and median.
WITH ordered AS (
    SELECT
        cgpa,
        ROW_NUMBER() OVER (ORDER BY cgpa) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM academic_records
), median_value AS (
    SELECT AVG(cgpa) AS median_cgpa
    FROM ordered
    WHERE row_num IN (
        FLOOR((total_rows + 1) / 2),
        CEIL((total_rows + 1) / 2)
    )
)
SELECT
    COUNT(*) AS student_count,
    ROUND(AVG(cgpa), 2) AS mean_cgpa,
    ROUND((SELECT median_cgpa FROM median_value), 2) AS median_cgpa,
    ROUND(MIN(cgpa), 2) AS minimum_cgpa,
    ROUND(MAX(cgpa), 2) AS maximum_cgpa,
    ROUND(STDDEV_SAMP(cgpa), 2) AS cgpa_stddev
FROM academic_records;

-- Overall CGPA bands.
SELECT
    CASE
        WHEN cgpa >= 9 THEN '9.0+'
        WHEN cgpa >= 8 THEN '8.0–8.99'
        WHEN cgpa >= 7 THEN '7.0–7.99'
        WHEN cgpa >= 6 THEN '6.0–6.99'
        ELSE '<6.0'
    END AS cgpa_band,
    COUNT(*) AS student_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_students
FROM academic_records
GROUP BY cgpa_band
ORDER BY MIN(cgpa) DESC;

-- Cohort comparison. This is cross-sectional, not longitudinal.
WITH ranked AS (
    SELECT
        c.cohort_name,
        ar.cgpa,
        ROW_NUMBER() OVER (PARTITION BY ar.cohort_id ORDER BY ar.cgpa) AS row_num,
        COUNT(*) OVER (PARTITION BY ar.cohort_id) AS cohort_count
    FROM academic_records AS ar
    JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
), medians AS (
    SELECT cohort_name, AVG(cgpa) AS median_cgpa
    FROM ranked
    WHERE row_num IN (FLOOR((cohort_count + 1) / 2), CEIL((cohort_count + 1) / 2))
    GROUP BY cohort_name
)
SELECT
    r.cohort_name,
    COUNT(*) AS student_count,
    ROUND(AVG(r.cgpa), 2) AS mean_cgpa,
    ROUND(m.median_cgpa, 2) AS median_cgpa,
    ROUND(MIN(r.cgpa), 2) AS minimum_cgpa,
    ROUND(MAX(r.cgpa), 2) AS maximum_cgpa,
    ROUND(STDDEV_SAMP(r.cgpa), 2) AS cgpa_stddev,
    ROUND(100 * AVG(r.cgpa >= 8), 2) AS pct_at_least_8,
    ROUND(100 * AVG(r.cgpa >= 9), 2) AS pct_at_least_9
FROM ranked AS r
JOIN medians AS m ON m.cohort_name = r.cohort_name
GROUP BY r.cohort_name, m.median_cgpa
ORDER BY FIELD(r.cohort_name, 'second_year', 'third_year', 'fourth_year');

-- Program comparison with sample size and threshold rates.
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
    p.program_name,
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
GROUP BY p.program_id, p.program_name, m.median_cgpa
ORDER BY mean_cgpa DESC, student_count DESC;

-- Program × cohort comparison.
SELECT
    p.program_name,
    c.cohort_name,
    COUNT(*) AS student_count,
    ROUND(AVG(ar.cgpa), 2) AS mean_cgpa,
    ROUND(STDDEV_SAMP(ar.cgpa), 2) AS cgpa_stddev,
    ROUND(100 * AVG(ar.cgpa >= 8), 2) AS pct_at_least_8
FROM academic_records AS ar
JOIN programs AS p ON p.program_id = ar.program_id
JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
GROUP BY p.program_id, p.program_name, c.cohort_id, c.cohort_name
HAVING COUNT(*) >= 10
ORDER BY p.program_name, FIELD(c.cohort_name, 'second_year', 'third_year', 'fourth_year');

-- Program/branch × cohort thresholds. Thresholds use >= and are expressed
-- as both counts and percentages so cohort sizes remain visible.
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
GROUP BY p.program_id, p.program_name, c.cohort_id, c.cohort_name, m.median_cgpa
ORDER BY p.program_name, FIELD(c.cohort_name, 'second_year', 'third_year', 'fourth_year');

-- Potential statistical outliers using overall Q1/IQR/Q3. These are unusual
-- observations, not labels about students.
WITH ordered AS (
    SELECT
        cgpa,
        ROW_NUMBER() OVER (ORDER BY cgpa) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM academic_records
), quartiles AS (
    SELECT
        AVG(CASE WHEN row_num IN (FLOOR((total_rows + 1) * 0.25), CEIL((total_rows + 1) * 0.25)) THEN cgpa END) AS q1,
        AVG(CASE WHEN row_num IN (FLOOR((total_rows + 1) * 0.75), CEIL((total_rows + 1) * 0.75)) THEN cgpa END) AS q3
    FROM ordered
), bounds AS (
    SELECT q1, q3, q3 - q1 AS iqr, q1 - 1.5 * (q3 - q1) AS lower_bound, q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM quartiles
)
SELECT q1, q3, iqr, lower_bound, upper_bound
FROM bounds;
