from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]


def test_processed_records_are_privacy_safe_and_valid():
    records = pd.read_csv(ROOT / "data/academic_records.csv")
    assert list(records.columns) == ["student_id", "program_name", "cohort", "cgpa"]
    assert records.student_id.is_unique
    assert records.student_id.str.fullmatch(r"STU\d{6}").all()
    assert records.cgpa.notna().all()
    assert records.cgpa.between(0, 10).all()
    assert set(records.cohort) == {"second_year", "third_year", "fourth_year"}


def test_processed_students_match_records():
    records = pd.read_csv(ROOT / "data/academic_records.csv")
    students = pd.read_csv(ROOT / "data/students.csv")
    assert set(records.student_id) == set(students.student_id)
    assert students.student_id.is_unique
