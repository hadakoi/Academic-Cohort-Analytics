"""Load privacy-safe CSV outputs into a MySQL 8 database.

The schema must be created first with sql/schema.sql. The loader refuses to
load into a non-empty schema to avoid accidental duplicate data.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import mysql.connector
import pandas as pd


def connection_config(database: str) -> dict:
    return {
        "host": os.getenv("MYSQL_HOST", "127.0.0.1"),
        "port": int(os.getenv("MYSQL_PORT", "3306")),
        "user": os.getenv("MYSQL_USER", "root"),
        "password": os.getenv("MYSQL_PASSWORD", ""),
        "database": database,
    }


def load(input_dir: Path, database: str) -> None:
    records = pd.read_csv(input_dir / "academic_records.csv")
    students = pd.read_csv(input_dir / "students.csv")
    programs = pd.read_csv(input_dir / "programs.csv")
    cohorts = pd.read_csv(input_dir / "cohorts.csv")

    expected_records = {"student_id", "program_name", "cohort", "cgpa"}
    if set(records.columns) != expected_records:
        raise ValueError(f"academic_records.csv must contain exactly {sorted(expected_records)}")
    if records.duplicated(subset=["student_id", "cohort"]).any():
        raise ValueError("academic_records.csv contains duplicate student/cohort records")
    if not set(records["student_id"]).issubset(set(students["student_id"])):
        raise ValueError("academic_records.csv contains student IDs absent from students.csv")
    if records["cgpa"].isna().any() or (~records["cgpa"].between(0, 10)).any():
        raise ValueError("academic_records.csv contains missing or invalid CGPA values")

    connection = mysql.connector.connect(**connection_config(database))
    cursor = connection.cursor()
    try:
        cursor.execute("SELECT COUNT(*) FROM students")
        if cursor.fetchone()[0] != 0:
            raise RuntimeError("Target schema is not empty; aborting load")

        cursor.executemany(
            "INSERT INTO programs (program_name) VALUES (%s)",
            [(value,) for value in programs["program_name"].drop_duplicates()],
        )
        cursor.executemany(
            "INSERT INTO cohorts (cohort_name, semester_number) VALUES (%s, %s)",
            list(cohorts[["cohort", "semester_number"]].itertuples(index=False, name=None)),
        )
        cursor.executemany(
            "INSERT INTO students (student_id) VALUES (%s)",
            [(value,) for value in students["student_id"]],
        )

        cursor.execute("SELECT program_id, program_name FROM programs")
        program_ids = {program_name: program_id for program_id, program_name in cursor.fetchall()}
        cursor.execute("SELECT cohort_id, cohort_name FROM cohorts")
        cohort_ids = {cohort_name: cohort_id for cohort_id, cohort_name in cursor.fetchall()}
        rows = [
            (
                row.student_id,
                program_ids[row.program_name],
                cohort_ids[row.cohort],
                float(row.cgpa),
            )
            for row in records.itertuples(index=False)
        ]
        cursor.executemany(
            """
            INSERT INTO academic_records (student_id, program_id, cohort_id, cgpa)
            VALUES (%s, %s, %s, %s)
            """,
            rows,
        )
        connection.commit()
        print(f"Loaded {len(students):,} students and {len(rows):,} academic records into {database}.")
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=Path("data"))
    parser.add_argument("--database", default=os.getenv("MYSQL_DATABASE", "academic_cohort_analytics"))
    args = parser.parse_args()
    load(args.input_dir, args.database)


if __name__ == "__main__":
    main()
