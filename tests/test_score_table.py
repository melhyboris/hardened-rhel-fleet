import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from score_table import build_table, read_score  # noqa: E402


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def test_read_score_parses_score_and_counts(tmp_path):
    write(tmp_path / "a.score", "61.52 pass=118 fail=74\n")
    assert read_score(tmp_path / "a.score") == {"score": 61.52, "pass": 118.0, "fail": 74.0}


def test_read_score_returns_none_for_missing_or_bad_file(tmp_path):
    assert read_score(tmp_path / "missing.score") is None
    write(tmp_path / "bad.score", "not-a-number\n")
    assert read_score(tmp_path / "bad.score") is None


def test_table_shows_change_per_server(tmp_path):
    write(tmp_path / "fleet-01" / "before.score", "60.00 pass=100 fail=80\n")
    write(tmp_path / "fleet-01" / "after.score", "92.50 pass=170 fail=10\n")
    table = build_table(tmp_path)
    assert "| fleet-01 | 60.0% (100 pass, 80 fail) | 92.5% (170 pass, 10 fail) | +32.5 points |" in table


def test_table_handles_a_server_scanned_only_once(tmp_path):
    write(tmp_path / "fleet-02" / "before.score", "55.10\n")
    table = build_table(tmp_path)
    assert "| fleet-02 | 55.1% | not scanned | n/a |" in table


def test_table_with_no_reports(tmp_path):
    assert "No reports found" in build_table(tmp_path / "nothing-here")
