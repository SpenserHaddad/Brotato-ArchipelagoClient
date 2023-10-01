from __future__ import annotations

from dataclasses import dataclass, field
from itertools import count
from typing import get_args

from BaseClasses import Location

from .Constants import (
    BASE_ID,
    CHARACTERS,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
    MAX_SHOP_LOCATIONS_PER_TIER,
    NUM_WAVES,
)

# TypeVar that's a union of all character name string literals
CHARACTER_NAMES = get_args(CHARACTERS)
_id_generator = count(BASE_ID, step=1)


class BrotatoLocation(Location):
    game = "Brotato"


@dataclass(frozen=True)
class BrotatoLocationBase:
    name: str
    is_event: bool = False
    id: int = field(init=False)

    def __post_init__(self):
        if not self.is_event:
            id_ = BASE_ID + next(_id_generator)
        else:
            id_ = None
        # Necessary to set field on frozen dataclass
        object.__setattr__(self, "id", id_)

    def to_location(self, player: int) -> BrotatoLocation:
        return BrotatoLocation(player, name=self.name, address=self.id)


_wave_count = range(1, NUM_WAVES + 1)

_char_specific_wave_complete_locs: list[BrotatoLocationBase] = []
_char_specific_run_complete_locs: list[BrotatoLocationBase] = []
character_specific_locations: dict[str, dict[str, int | None]] = {}
for char in CHARACTERS:
    _char_wave_complete_locations = [BrotatoLocationBase(name=f"Wave {w} Complete ({char})") for w in _wave_count]
    _char_run_complete_location = BrotatoLocationBase(name=f"Run Complete ({char})")
    _char_specific_wave_complete_locs += _char_wave_complete_locations
    _char_specific_run_complete_locs.append(_char_run_complete_location)

    character_specific_locations[char] = {
        # **{c.name: c.id for c in _char_wave_complete_locations}, # We want to manually add these later
        _char_run_complete_location.name: _char_run_complete_location.id,
    }

_shop_item_locs: list[BrotatoLocationBase] = []
for tier, max_shop_locs in MAX_SHOP_LOCATIONS_PER_TIER.items():
    _shop_item_locs += [BrotatoLocationBase(name=f"{tier.name} Shop Item {i}") for i in range(max_shop_locs)]

_normal_item_drop_locs = [BrotatoLocationBase(name=f"Crate Drop {i}") for i in range(MAX_NORMAL_CRATE_DROPS)]
_legendary_item_drop_locs = [
    BrotatoLocationBase(name=f"Legendary Crate Drop {i}") for i in range(MAX_LEGENDARY_CRATE_DROPS)
]

location_table: list[BrotatoLocationBase] = [
    *_char_specific_wave_complete_locs,
    *_char_specific_run_complete_locs,
    *_shop_item_locs,
    *_normal_item_drop_locs,
    *_legendary_item_drop_locs,
]

location_name_to_id: dict[str, int] = {loc.name: loc.id for loc in location_table}
location_name_groups: dict[str, set[str]] = {
    "Wave Complete Specific Character": set(c.name for c in _char_specific_wave_complete_locs),
    "Run Win Specific Character": set(c.name for c in _char_specific_run_complete_locs),
    "Normal Crate Drops": set(c.name for c in _normal_item_drop_locs),
    "Legendary Crate Drops": set(c.name for c in _legendary_item_drop_locs),
    "Shop Items": set(c.name for c in _shop_item_locs),
}
