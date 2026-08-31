"""Clean and irreversibly anonymize the approved academic cohort workbooks.

The source workbooks remain outside the analytical dataset. This script reads
only each workbook's master sheet and never writes a source-to-anonymous-ID
mapping file.
"""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

import pandas as pd


SEMESTER_TO_COHORT = {
    "iii": "second_year",
    "v": "third_year",
    "vii": "fourth_year",
}

OUTPUT_COLUMNS = ["student_id", "program_name", "cohort", "cgpa"]


def is_blank(value: object) -> bool:
    if pd.isna(value):
        return True
    return str(value).strip().casefold() in {"", "nan", "none", "null", "na", "n/a", "-"}


def normalized_identifier(value: object) -> str | None:
    """Normalize an institution ID for matching without publishing it."""

    if is_blank(value):
        return None
    text = str(value).strip()
    if re.fullmatch(r"\d+\.0", text):
        text = text[:-2]
    return re.sub(r"\s+", " ", text).casefold()


def normalized_label(value: object) -> str | None:
    if is_blank(value):
        return None
    return re.sub(r"\s+", " ", str(value).strip())


def identifier_sort_key(value: str) -> tuple[int, object]:
    if value.isdigit():
        return (0, int(value))
    return (1, value)


def choose_master_sheet(excel: pd.ExcelFile) -> str:
    masters = [sheet for sheet in excel.sheet_names if "master" in sheet.casefold()]
    if len(masters) != 1:
        raise ValueError(f"Expected exactly one master sheet; found {masters}")
    return masters[0]


def read_master(path: Path) -> tuple[pd.DataFrame, str]:
    excel = pd.ExcelFile(path, engine="openpyxl")
    sheet = choose_master_sheet(excel)
    frame = pd.read_excel(path, sheet_name=sheet, dtype=object, engine="openpyxl")
    frame.columns = [str(column).strip() for column in frame.columns]
    return frame, sheet


def build_clean_dataset(raw_files: list[Path]) -> tuple[pd.DataFrame, pd.DataFrame, dict]:
    all_records: list[pd.DataFrame] = []
    source_rows: list[dict] = []
    source_to_record: dict[str, set[tuple]] = {}
    source_cohort_records: dict[tuple[str, str], tuple] = {}
    duplicate_source_ids: list[dict] = []
    ambiguous_source_records: list[dict] = []
    program_labels: dict[str, set[str]] = {}

    required = {"Enrollment ID", "Current Semester", "Current Program", "CGPA"}

    for path in raw_files:
        frame, sheet = read_master(path)
        missing_columns = required - set(frame.columns)
        if missing_columns:
            raise ValueError(f"{path.name}/{sheet} is missing columns: {sorted(missing_columns)}")

        raw_rows = len(frame)
        frame = frame.dropna(how="all").copy()
        frame["_source_key"] = frame["Enrollment ID"].map(normalized_identifier)
        frame["_program_name"] = frame["Current Program"].map(normalized_label)
        frame["_semester"] = frame["Current Semester"].map(
            lambda value: str(value).strip().casefold() if not is_blank(value) else None
        )
        frame["_cgpa"] = pd.to_numeric(frame["CGPA"], errors="coerce")

        keyed = frame[frame["_source_key"].notna()].copy()
        duplicate_groups = keyed[keyed["_source_key"].duplicated(keep=False)]
        if not duplicate_groups.empty:
            for source_key, group in duplicate_groups.groupby("_source_key", sort=False):
                duplicate_source_ids.append(
                    {"file": path.name, "sheet": sheet, "source_key": source_key, "rows": len(group)}
                )

        footer_or_blank = int(frame["_source_key"].isna().sum())
        missing_cgpa = int(keyed["_cgpa"].isna().sum())
        invalid_cgpa = int(((keyed["_cgpa"].notna()) & ~keyed["_cgpa"].between(0, 10)).sum())
        unknown_semesters = sorted(set(keyed["_semester"].dropna()) - set(SEMESTER_TO_COHORT))
        if unknown_semesters:
            raise ValueError(f"Unknown semester labels in {path.name}: {unknown_semesters}")
        if invalid_cgpa:
            raise ValueError(f"Out-of-range CGPA values found in {path.name}; review before loading")

        for _, row in keyed.iterrows():
            source_key = row["_source_key"]
            cohort = SEMESTER_TO_COHORT.get(row["_semester"])
            record_signature = (row["_program_name"], row["_cgpa"])
            source_cohort_key = (source_key, cohort)
            if source_cohort_key in source_cohort_records:
                previous = source_cohort_records[source_cohort_key]
                ambiguous_source_records.append(
                    {
                        "file": path.name,
                        "source_key": source_key,
                        "cohort": cohort,
                        "reason": "duplicate student/cohort record",
                        "conflicting_values": previous != record_signature,
                    }
                )
            else:
                source_cohort_records[source_cohort_key] = record_signature
            source_to_record.setdefault(source_key, set()).add(record_signature + (cohort,))
            if row["_program_name"] is not None:
                program_labels.setdefault(row["_program_name"].casefold(), set()).add(row["_program_name"])

        retained = keyed[keyed["_cgpa"].notna()].copy()
        retained["cohort"] = retained["_semester"].map(SEMESTER_TO_COHORT)
        retained = retained.rename(columns={"_program_name": "program_name", "_cgpa": "cgpa"})
        retained["source_key"] = retained["_source_key"]
        all_records.append(retained[["source_key", "program_name", "cohort", "cgpa"]])

        source_rows.append(
            {
                "file": path.name,
                "master_sheet": sheet,
                "raw_rows": raw_rows,
                "nonempty_rows": len(frame),
                "rows_with_source_key": len(keyed),
                "blank_or_footer_rows": footer_or_blank,
                "missing_cgpa_rows": missing_cgpa,
                "invalid_cgpa_rows": invalid_cgpa,
                "retained_rows": len(retained),
                "duplicate_source_id_groups": len(
                    {entry["source_key"] for entry in duplicate_source_ids if entry["file"] == path.name}
                ),
            }
        )

    if duplicate_source_ids or ambiguous_source_records:
        raise ValueError(
            "Duplicate or ambiguous source records detected; no records were written. "
            f"Duplicate IDs: {duplicate_source_ids}; ambiguous records: {ambiguous_source_records}"
        )

    records = pd.concat(all_records, ignore_index=True)
    records["cgpa"] = records["cgpa"].astype(float).round(2)

    duplicate_record_mask = records.duplicated(subset=["source_key", "cohort"], keep=False)
    if duplicate_record_mask.any():
        raise ValueError("Duplicate student/cohort records detected; no records were written")

    # Only retained records receive public IDs. Students removed for missing
    # CGPA must not remain as empty rows in the analytical student dimension.
    sorted_keys = sorted(records["source_key"].unique(), key=identifier_sort_key)
    student_ids = {source_key: f"STU{index:06d}" for index, source_key in enumerate(sorted_keys, start=1)}
    records["student_id"] = records["source_key"].map(student_ids)
    records = records[OUTPUT_COLUMNS].sort_values(["cohort", "program_name", "student_id"]).reset_index(drop=True)
    records["cgpa"] = records["cgpa"].astype(float)

    students = pd.DataFrame({"student_id": [student_ids[key] for key in sorted_keys]})
    report = {
        "source_rows": source_rows,
        "source_identifier_count": len(source_to_record),
        "retained_student_count": len(students),
        "retained_record_count": len(records),
        "duplicate_source_identifier_groups": len(duplicate_source_ids),
        "ambiguous_source_identifier_count": len(ambiguous_source_records),
        "program_count": records["program_name"].nunique(),
        "cohort_counts": records["cohort"].value_counts().sort_index().to_dict(),
        "cgpa_min": float(records["cgpa"].min()),
        "cgpa_max": float(records["cgpa"].max()),
        "program_label_variant_groups": sum(len(values) > 1 for values in program_labels.values()),
    }
    return records, students, report


def write_cleaning_report(output_path: Path, report: dict) -> None:
    lines = [
        "# Cleaning and Anonymization Report",
        "",
        "The approved irreversible-anonymization workflow was run against the master sheet of each supplied workbook.",
        "Original workbooks, names, email-like learner IDs, enrollment IDs, roll numbers, status values, and mapping files were not written to the analytical output.",
        "",
        "## File-level results",
        "",
        "| File | Master sheet | Raw rows | Rows with source key | Blank/footer rows | Missing CGPA | Retained rows |",
        "|---|---|---:|---:|---:|---:|---:|",
    ]
    for row in report["source_rows"]:
        lines.append(
            f"| `{row['file']}` | `{row['master_sheet']}` | {row['raw_rows']:,} | "
            f"{row['rows_with_source_key']:,} | {row['blank_or_footer_rows']:,} | "
            f"{row['missing_cgpa_rows']:,} | {row['retained_rows']:,} |"
        )
    lines += [
        "",
        "## Validation summary",
        "",
        f"- Source identifiers used internally: {report['source_identifier_count']:,}",
        f"- Anonymous students generated: {report['retained_student_count']:,}",
        f"- Analytical records retained: {report['retained_record_count']:,}",
        f"- Source-keyed students excluded for missing CGPA: {report['source_identifier_count'] - report['retained_student_count']:,}",
        f"- Duplicate source-identifier groups: {report['duplicate_source_identifier_groups']}",
        f"- Ambiguous source identifiers: {report['ambiguous_source_identifier_count']}",
        f"- Normalized program-label variant groups requiring review: {report['program_label_variant_groups']}",
        f"- Retained program categories: {report['program_count']}",
        f"- Retained CGPA range: {report['cgpa_min']:.2f}–{report['cgpa_max']:.2f}",
        "",
        "## Approved transformations",
        "",
        "- III, V, and VII semester values were transformed to `second_year`, `third_year`, and `fourth_year`.",
        "- `Current Program` was whitespace-normalized and retained as `program_name`; `Current Program Code` was removed.",
        "- Missing CGPA rows were removed at the owner's request.",
        "- CGPA was converted to numeric and validated within 0–10.",
        "- Anonymous IDs are deterministic, sequential, and contain no source attributes.",
    ]
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=Path("."))
    parser.add_argument("--output-dir", type=Path, default=Path("data"))
    parser.add_argument("--report", type=Path, default=Path("reports/cleaning_report.md"))
    args = parser.parse_args()

    raw_files = sorted(args.input_dir.glob("*.xlsx")) + sorted(args.input_dir.glob("*.xlsm"))
    if not raw_files:
        raise SystemExit("No Excel workbooks found in the input directory")

    records, students, report = build_clean_dataset(raw_files)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    records.to_csv(args.output_dir / "academic_records.csv", index=False)
    students.to_csv(args.output_dir / "students.csv", index=False)
    pd.DataFrame(
        {"program_name": sorted(records["program_name"].dropna().unique())}
    ).to_csv(args.output_dir / "programs.csv", index=False)
    pd.DataFrame(
        [
            {"cohort": cohort, "semester_number": semester}
            for semester, cohort in [(3, "second_year"), (5, "third_year"), (7, "fourth_year")]
        ]
    ).to_csv(args.output_dir / "cohorts.csv", index=False)
    write_cleaning_report(args.report, report)
    print(
        f"Wrote {len(students):,} students and {len(records):,} records to {args.output_dir}; "
        f"report: {args.report}"
    )


if __name__ == "__main__":
    main()
