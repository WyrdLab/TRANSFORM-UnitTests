"""Unit tests for check_package_files.py (no Modelica tool needed)."""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_package_files as cpf  # noqa: E402


def make(root: Path, files):
    for rel in files:
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("")


class CheckPackageFiles(unittest.TestCase):
    def run_check(self, files):
        with tempfile.TemporaryDirectory() as d:
            make(Path(d), files)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                rc = cpf.main(["--library", d])
            return rc, out.getvalue()

    def test_clean_library_passes(self):
        rc, out = self.run_check(["TRANSFORM/package.mo", "TRANSFORM/A/package.mo", "TRANSFORM/A/B.mo",
                                  "TRANSFORM/A/package.order"])
        self.assertEqual(rc, 0, out)

    def test_order_without_package_fails(self):
        rc, out = self.run_check(["TRANSFORM/package.mo", "TRANSFORM/A/package.order"])
        self.assertEqual(rc, 1)
        self.assertIn("TRANSFORM/A", out)

    def test_mo_without_package_fails(self):
        rc, out = self.run_check(["TRANSFORM/package.mo", "TRANSFORM/A/package.mo", "TRANSFORM/A/B/C.mo"])
        self.assertEqual(rc, 1)
        self.assertIn("TRANSFORM/A/B", out)

    def test_resources_are_skipped(self):
        rc, out = self.run_check(["TRANSFORM/package.mo", "TRANSFORM/Resources/Scripts/x.mo"])
        self.assertEqual(rc, 0, out)

    def test_folder_with_only_other_files_passes(self):
        rc, out = self.run_check(["TRANSFORM/package.mo", "TRANSFORM/A/package.mo", "TRANSFORM/A/data/table.txt"])
        self.assertEqual(rc, 0, out)

    def test_no_library_is_setup_error(self):
        with tempfile.TemporaryDirectory() as d:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(cpf.main(["--library", d]), 2)


if __name__ == "__main__":
    unittest.main()
