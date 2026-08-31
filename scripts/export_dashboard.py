"""Export only aggregate MySQL views for a public dashboard."""

from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path

import mysql.connector


AGGREGATE_VIEWS = [
    "vw_cohort_summary",
    "vw_branch_summary",
    "vw_branch_cohort_summary",
    "vw_branch_cohort_thresholds",
    "vw_cgpa_distribution",
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("dashboard/exports"))
    parser.add_argument("--database", default=os.getenv("MYSQL_DATABASE", "academic_cohort_analytics"))
    args = parser.parse_args()

    connection = mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=args.database,
    )
    args.output_dir.mkdir(parents=True, exist_ok=True)
    cursor = connection.cursor()
    try:
        for view_name in AGGREGATE_VIEWS:
            cursor.execute(f"SELECT * FROM `{view_name}`")
            headers = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            with (args.output_dir / f"{view_name}.csv").open("w", newline="", encoding="utf-8") as output:
                writer = csv.writer(output)
                writer.writerow(headers)
                writer.writerows(rows)
            print(f"Exported {view_name}: {len(rows):,} aggregate rows")
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    main()
