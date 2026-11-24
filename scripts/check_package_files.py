#!/usr/bin/env python3
"""Package-structure check for the TRANSFORM library.

A folder of a Modelica library is a package only if it holds a package.mo.
A folder under TRANSFORM/ that holds Modelica files (*.mo) or a package.order
but no package.mo is loaded by no tool: its classes cannot be used, and the
folder is dead code that looks alive. Eight such folders were removed in
TRANSFORM 1.4.0; this check keeps new ones from appearing.

Folders under TRANSFORM/Resources are not packages and are skipped.

Exit codes:
  0  every folder with Modelica files or a package.order has a package.mo
  1  one or more folders do not (each is printed)
  2  setup error (no TRANSFORM folder)

Python 3, standard library only.
"""

import argparse
import sys
from pathlib import Path


def orphan_folders(root: Path):
    """Folders under root that hold *.mo files or a package.order but no package.mo."""
    found = []
    for folder in sorted(p for p in [root, *root.rglob("*")] if p.is_dir()):
        rel = folder.relative_to(root)
        if rel.parts and rel.parts[0] == "Resources":
            continue
        has_mo = any(f.suffix == ".mo" for f in folder.iterdir() if f.is_file())
        has_order = (folder / "package.order").is_file()
        if (has_mo or has_order) and not (folder / "package.mo").is_file():
            found.append(rel)
    return found


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--library", default=str(Path(__file__).resolve().parents[2] / "TRANSFORM-Library"),
                    help="TRANSFORM-Library checkout (holds TRANSFORM/); default ../TRANSFORM-Library")
    a = ap.parse_args(argv)
    root = Path(a.library) / "TRANSFORM"
    if not (root / "package.mo").is_file():
        print(f"SETUP ERROR: no TRANSFORM/package.mo under {a.library}")
        return 2
    bad = orphan_folders(root)
    if bad:
        print(f"FAIL: {len(bad)} folder(s) hold Modelica files or a package.order but no package.mo "
              "(no tool loads them):")
        for rel in bad:
            print(f"  TRANSFORM/{rel.as_posix()}")
        return 1
    print("PASS: every TRANSFORM folder with Modelica files or a package.order has a package.mo")
    return 0


if __name__ == "__main__":
    sys.exit(main())
