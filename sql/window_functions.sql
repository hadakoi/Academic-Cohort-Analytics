USE academic_cohort_analytics;

-- Anonymous student-relative metrics. Use aggregate views for public dashboards;
-- this query is intended for local analysis only.
WITH metrics AS (
    SELECT
        ar.student_id,
        p.program_name,
        c.cohort_name,
        ar.cgpa,
        DENSE_RANK() OVER (
            PARTITION BY p.program_id
            ORDER BY ar.cgpa DESC
        ) AS program_rank,
        RANK() OVER (
            PARTITION BY p.program_id
            ORDER BY ar.cgpa DESC
        ) AS program_rank_with_gaps,
        DENSE_RANK() OVER (
            PARTITION BY c.cohort_id
            ORDER BY ar.cgpa DESC
        ) AS cohort_rank,
        DENSE_RANK() OVER (
            PARTITION BY ar.program_id, ar.cohort_id
            ORDER BY ar.cgpa DESC
        ) AS program_cohort_rank,
        PERCENT_RANK() OVER (ORDER BY ar.cgpa) AS overall_percentile_from_bottom,
        PERCENT_RANK() OVER (PARTITION BY p.program_id ORDER BY ar.cgpa) AS program_percentile_from_bottom,
        PERCENT_RANK() OVER (PARTITION BY c.cohort_id ORDER BY ar.cgpa) AS cohort_percentile_from_bottom,
        PERCENT_RANK() OVER (PARTITION BY ar.program_id, ar.cohort_id ORDER BY ar.cgpa) AS program_cohort_percentile_from_bottom,
        NTILE(4) OVER (ORDER BY ar.cgpa DESC) AS overall_quartile,
        NTILE(4) OVER (PARTITION BY p.program_id ORDER BY ar.cgpa DESC) AS program_quartile,
        AVG(ar.cgpa) OVER () AS overall_average,
        AVG(ar.cgpa) OVER (PARTITION BY p.program_id) AS program_average,
        AVG(ar.cgpa) OVER (PARTITION BY c.cohort_id) AS cohort_average,
        AVG(ar.cgpa) OVER (PARTITION BY ar.program_id, ar.cohort_id) AS program_cohort_average
    FROM academic_records AS ar
    JOIN programs AS p ON p.program_id = ar.program_id
    JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
)
SELECT
    student_id,
    program_name,
    cohort_name,
    ROUND(cgpa, 2) AS cgpa,
    program_rank,
    program_rank_with_gaps,
    cohort_rank,
    program_cohort_rank,
    ROUND(100 * overall_percentile_from_bottom, 2) AS overall_percentile,
    ROUND(100 * program_percentile_from_bottom, 2) AS program_percentile,
    ROUND(100 * cohort_percentile_from_bottom, 2) AS cohort_percentile,
    ROUND(100 * program_cohort_percentile_from_bottom, 2) AS program_cohort_percentile,
    overall_quartile,
    program_quartile,
    ROUND(cgpa - overall_average, 2) AS delta_from_overall_average,
    ROUND(cgpa - program_average, 2) AS delta_from_program_average,
    ROUND(cgpa - cohort_average, 2) AS delta_from_cohort_average,
    ROUND(cgpa - program_cohort_average, 2) AS delta_from_program_cohort_average
FROM metrics
ORDER BY cohort_name, program_name, program_rank, student_id;
