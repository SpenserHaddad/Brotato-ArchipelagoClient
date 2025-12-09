#!/usr/bin/env python
import sys
from pathlib import Path

from ruamel.yaml import YAML


def remove_ap_version_from_template(template_file: Path):
    yaml = YAML(typ="rt")
    template_data = yaml.load(template_file)

    if "requires" in template_data:
        del template_data["requires"]["version"]

    yaml.dump(template_data, template_file)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <template_file>")  # noqa: T201
        sys.exit(1)

    template_file = Path(sys.argv[1])
    remove_ap_version_from_template(template_file)
