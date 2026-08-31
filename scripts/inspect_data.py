"""Print a privacy-safe structural audit of Excel workbooks.

This script reports metadata and quality counts only; it does not print
student names, email-like values, enrollment IDs, roll numbers, or CGPA rows.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import pandas as pd


PII_PATTERNS = re.compile(
    r"name|email|learner|enrollment|registration|roll|phone|address|student.?id|uid",
    re.IGNORECASE,
)


def blank_mask(series: pd.Series) -> pd.Series:
    return series.isna() | series.astype(str).str.strip().isin({"", "nan", "None", "null", "-"})


def inspect_workbook(path: Path) -> None:
    excel = pd.ExcelFile(path, engine="openpyxl")
    print(f"\nFILE: {path.name}")
    print(f"SHEETS: {len(excel.sheet_names)}")
    for sheet in excel.sheet_names:
        frame = pd.read_excel(path, sheet_name=sheet, dtype=object, engine="openpyxl")
        frame.columns = [str(column).strip() for column in frame.columns]
        nonempty = frame.dropna(how="all")
        print(f"  - {sheet}: rows={len(frame):,}, nonempty_rows={len(nonempty):,}, columns={len(frame.columns)}")
        if "master" not in sheet.casefold():
            continue
        print(f"    columns={list(frame.columns)}")
        for column in frame.columns:
            missing = int(blank_mask(frame[column]).sum())
            inferred = pd.api.types.infer_dtype(frame[column].dropna(), skipna=True)
            privacy = " [sensitive-looking]" if PII_PATTERNS.search(column) else ""
            print(f"    {column}: inferred={inferred}, missing={missing:,}, distinct={frame[column].nunique(dropna=True):,}{privacy}")
        if "CGPA" in frame.columns:
            cgpa = pd.to_numeric(frame["CGPA"], errors="coerce")
            valid = cgpa.dropna()
            print(
                "    CGPA: "
                f"numeric={len(valid):,}, invalid={int(cgpa.isna().sum() - frame['CGPA'].isna().sum()):,}, "
                f"min={valid.min() if not valid.empty else None}, max={valid.max() if not valid.empty else None}, "
                f"out_of_range={int((~valid.between(0, 10)).sum())}"
            )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=Path("."))
    args = parser.parse_args()
    files = sorted(args.input_dir.glob("*.xlsx")) + sorted(args.input_dir.glob("*.xlsm"))
    if not files:
        raise SystemExit("No Excel workbooks found")
    for path in files:
        inspect_workbook(path)


if __name__ == "__main__":
    main()
