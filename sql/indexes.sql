USE academic_cohort_analytics;

-- Supports the dashboard's branch/program-by-cohort aggregations.
CREATE INDEX idx_records_cohort_program
    ON academic_records (cohort_id, program_id);

-- Supports program-level filtering and CGPA threshold analysis.
CREATE INDEX idx_records_program_cgpa
    ON academic_records (program_id, cgpa);
