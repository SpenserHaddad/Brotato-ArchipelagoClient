import json
import sys
import zipfile
from pathlib import Path
from typing import cast

import polars as pl
from rich.console import Console
from rich.table import Table

try:
    filename = Path(sys.argv[1])
except IndexError:
    print(f"Usage: {sys.argv[0]} <world_zipfile>")
    sys.exit(-1)


fieldnames = [
    "xp_items",
    "xp_weight",
    "xp",
    "gold_items",
    "gold_weight",
    "gold",
    "locations",
    "waves_per_check",
    "characters",
    "wins",
    "c_crates",
    "l_crates",
]
table = Table()
for field in fieldnames:
    table.add_column(field)

data_rows: list[dict[str, int]] = []
with zipfile.ZipFile(filename, "r") as z:
    for zf in z.filelist:
        if zf.filename.endswith(".json"):
            with z.open(zf.filename) as zff:
                data = cast(dict[str, int], json.load(zff))
                table.add_row(*[str(data[field]) for field in fieldnames])
                data_rows.append(data)
console = Console()
console.print(table)

df = pl.DataFrame(data_rows)
df.write_excel("bdata.xlsx", worksheet=filename.stem)
