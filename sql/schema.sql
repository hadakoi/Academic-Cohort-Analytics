-- Academic Cohort Analytics — MySQL 8+ schema
-- Run this file first, then load data with scripts/load_mysql.py.

CREATE DATABASE IF NOT EXISTS academic_cohort_analytics;
USE academic_cohort_analytics;

CREATE TABLE IF NOT EXISTS programs (
    program_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    program_name VARCHAR(255) NOT NULL,
    CONSTRAINT uq_program_name UNIQUE (program_name)
);

CREATE TABLE IF NOT EXISTS cohorts (
    cohort_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cohort_name VARCHAR(32) NOT NULL,
    semester_number TINYINT UNSIGNED NOT NULL,
    CONSTRAINT uq_cohort_name UNIQUE (cohort_name),
    CONSTRAINT chk_semester_number CHECK (semester_number IN (3, 5, 7))
);

CREATE TABLE IF NOT EXISTS students (
    student_id CHAR(9) PRIMARY KEY,
    CONSTRAINT chk_anonymous_student_id CHECK (student_id REGEXP '^STU[0-9]{6}$')
);

CREATE TABLE IF NOT EXISTS academic_records (
    record_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id CHAR(9) NOT NULL,
    program_id SMALLINT UNSIGNED NOT NULL,
    cohort_id TINYINT UNSIGNED NOT NULL,
    cgpa DECIMAL(4, 2) NOT NULL,
    CONSTRAINT uq_student_cohort UNIQUE (student_id, cohort_id),
    CONSTRAINT chk_cgpa_range CHECK (cgpa BETWEEN 0 AND 10),
    CONSTRAINT fk_record_student FOREIGN KEY (student_id) REFERENCES students (student_id),
    CONSTRAINT fk_record_program FOREIGN KEY (program_id) REFERENCES programs (program_id),
    CONSTRAINT fk_record_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts (cohort_id)
);
