USE academic_cohort_analytics;

-- Basic row reconciliation.
SELECT
    (SELECT COUNT(*) FROM students) AS student_count,
    (SELECT COUNT(*) FROM academic_records) AS record_count,
    (SELECT COUNT(DISTINCT student_id) FROM academic_records) AS students_with_records;

-- Expected to return zero rows.
SELECT student_id, cohort_id, COUNT(*) AS duplicate_count
FROM academic_records
GROUP BY student_id, cohort_id
HAVING COUNT(*) > 1;

-- Expected to return zero rows.
SELECT record_id, student_id, cgpa
FROM academic_records
WHERE cgpa IS NULL OR cgpa NOT BETWEEN 0 AND 10;

-- Expected to return zero rows.
SELECT ar.record_id
FROM academic_records AS ar
LEFT JOIN students AS s ON s.student_id = ar.student_id
LEFT JOIN programs AS p ON p.program_id = ar.program_id
LEFT JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
WHERE s.student_id IS NULL OR p.program_id IS NULL OR c.cohort_id IS NULL;

-- Distribution of loaded records by cohort and program.
SELECT c.cohort_name, p.program_name, COUNT(*) AS student_count
FROM academic_records AS ar
JOIN cohorts AS c ON c.cohort_id = ar.cohort_id
JOIN programs AS p ON p.program_id = ar.program_id
GROUP BY c.cohort_name, p.program_name
ORDER BY c.cohort_name, student_count DESC, p.program_name;
