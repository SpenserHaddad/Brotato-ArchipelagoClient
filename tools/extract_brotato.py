#!/bin/env python
"""Extracts Brotato and its DLC's into a directory for development.

This extracts the packed Brotato data files into a directory that can be opened,
edited and run with Godot.

To run this script and the project, the following must be configured on your
machine:

    * Brotato must be installed on your computer. This can be either the Steam or
      Epic Games versions (NOT the Xbox version).
    * GDRETools must be downloaded, and gdre_tools.exe must be on your PATH.
        * You can download this from: https://github.com/GDRETools/gdsdecomp
    * You will need the latest build of GodotSteam 3.6 to run the project.
        * You can download this from: https://github.com/GodotSteam/GodotSteam
"""

import argparse
import os
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument(
    "brotato_dir", metavar="brotato-dir", help="The root of the Brotato directory, aka the parent of Brotato.pck."
)
parser.add_argument(
    "output_dir", metavar="output-dir", help="The directory to extract Brotato into. Will be cleared before extracting."
)
parser.add_argument(
    "-g", "--gdre-dir", help="Optional path to the GDRE tools. Will be prepended to the PATH before extracting."
)


def _ensure_gdre_tools():
    if not shutil.which("gdre_tools"):
        raise RuntimeError(
            "Could not find gdre_tools. Ensure that the you have downloaded https://github.com/GDRETools/gdsdecomp and placed it on your PATH."
        )


def _extract_pck(pck_file: Path, output_dir: Path) -> None:
    print(f"Extracting {pck_file} to {output_dir}")
    subprocess.run(["gdre_tools", "--headless", f"--recover={pck_file}", f"--output={output_dir}"], check=True)


def main():
    args = parser.parse_args()
    brotato_dir = Path(args.brotato_dir)
    output_dir = Path(args.output_dir)

    if args.gdre_dir:
        gdre_dir = Path(args.gdre_dir).resolve()
        os.environ["PATH"] = str(gdre_dir) + os.pathsep + os.environ["PATH"]

    breakpoint()
    _ensure_gdre_tools()

    if output_dir.is_dir():
        print(f"Output dir {output_dir} not empty, cleaning first")
        shutil.rmtree(output_dir)

    output_dir.mkdir()

    # Extra files in order to ensure the files in each are overlaid properly
    pck_filenames: list[str] = ["Brotato", "BrotatoAbyssalTerrors"]

    for p in pck_filenames:
        pck_file: Path = brotato_dir / f"{p}.pck"
        _extract_pck(pck_file, output_dir)

    print(f"Successfully extracted {brotato_dir} into {output_dir}")


if __name__ == "__main__":
    main()
