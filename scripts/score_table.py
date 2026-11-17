#!/usr/bin/env python3
"""Build the before/after results table from the files `scan.yml` saves.

Each server has reports/<host>/before.score and reports/<host>/after.score,
one line each, for example:  61.52 pass=118 fail=74
"""
from __future__ import annotations

import sys
from pathlib import Path


def read_score(path: Path) -> dict[str, float] | None:
    """Return {'score', 'pass', 'fail'} from a .score file, or None if it is missing or malformed."""
    try:
        parts = path.read_text().split()
        result = {"score": float(parts[0])}
        for part in parts[1:]:
            key, _, value = part.partition("=")
            result[key] = float(value)
        return result
    except (OSError, IndexError, ValueError):
        return None


def cell(score: dict[str, float] | None) -> str:
    if score is None:
        return "not scanned"
    text = f"{score['score']:.1f}%"
    if "pass" in score and "fail" in score:
        text += f" ({int(score['pass'])} pass, {int(score['fail'])} fail)"
    return text


def build_table(reports: Path) -> str:
    hosts = sorted(p for p in reports.iterdir() if p.is_dir()) if reports.is_dir() else []
    if not hosts:
        return "No reports found. Run `make scan-before` first."

    lines = ["| Server | Before | After | Change |", "| --- | --- | --- | --- |"]
    for host in hosts:
        before = read_score(host / "before.score")
        after = read_score(host / "after.score")
        change = "n/a"
        if before and after:
            change = f"{after['score'] - before['score']:+.1f} points"
        lines.append(f"| {host.name} | {cell(before)} | {cell(after)} | {change} |")
    return "\n".join(lines)


if __name__ == "__main__":
    print(build_table(Path(sys.argv[1] if len(sys.argv) > 1 else "reports")))
