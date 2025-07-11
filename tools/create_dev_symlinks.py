#!/bin/env python
"""CLI Utility to create symlinks of the apworld and mod to the Archipelago and Brotato dev areas.

This project is not designed to be run on its own. Instead, it's two main components, the apworld and client mod, are
meant to be symlinked to other dev areas where they can actually run. These are:

    * apworld/brotato is symlinked to Archipelago/worlds/brotato.
    * client_mod/mods-unpacked/RampagingHippy-Archipelago is symlinked to
      <BrotatoRoot>/mods-unpacked/RampagingHippy-Archipelago.

This requires you to have the Archipelago source code cloned somewhere local from
https://github.com/ArchipelagoMW/Archipelago/, and to have an unpacked version of Brotato, such as from running
./extract_brotato.ps1.

The Archipelago and Brotato roots are specified as command line arguments. This only creates symlinks for the arguments
passed in. This allows you to, for example, update the client mod symlink if you rebuild the Brotato area without
changing the apworld's.
"""

import argparse
import shutil
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument(
    "-a",
    "--archipelago-dir",
    help="The root of the Archipelago repo. This is NOT the same as the installed Archipelago application on Windows.",
)
parser.add_argument(
    "-b", "--brotato-dir", help="The root of the *unpacked* Brotato directory. See ./extract_brotato.py for details."
)


def _make_symlink(src: Path, dst: Path) -> None:
    if dst.is_symlink():
        dst.unlink()
    elif dst.is_dir():
        shutil.rmtree(dst)

    print(f"Creating symlink at {dst} pointing to {src}")
    dst.symlink_to(src)


def main() -> None:
    args = parser.parse_args()

    repo_root = Path(__file__).parent.parent.absolute()

    if args.archipelago_dir:
        ap_dir = Path(args.archipelago_dir).absolute().resolve()
        apworld_src = repo_root / "apworld" / "brotato"
        apworld_dst = ap_dir / "worlds" / "brotato"

        if not ap_dir.is_dir():
            raise FileNotFoundError(
                f"Could not find apworld in local repo at {apworld_src}. This means something is very wrong with your repo."
            )

        _make_symlink(apworld_src, apworld_dst)

    if args.brotato_dir:
        brotato_dir = Path(args.brotato_dir).absolute().resolve()
        brotato_mods_dir = brotato_dir / "mods-unpacked"
        brotato_mods_dir.mkdir(exist_ok=True)
        client_mod_src: Path = repo_root / "client_mod" / "mods-unpacked" / "RampagingHippy-Archipelago"
        client_mod_dst: Path = brotato_mods_dir / "RampagingHippy-Archipelago"

        if not client_mod_src.is_dir():
            raise FileNotFoundError(
                f"Could not find client mod in local repo at {client_mod_src}. This means something is very wrong with your repo."
            )

        _make_symlink(client_mod_src, client_mod_dst)


if __name__ == "__main__":
    main()
