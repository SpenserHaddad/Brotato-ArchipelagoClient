from collections.abc import Iterable
from dataclasses import dataclass, field
from itertools import count
from typing import get_args

from BaseClasses import Location, LocationProgressType, Region

from .constants import (
    ALL_CHARACTERS,
    BASE_ID,
    CHARACTER_GROUPS,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)

# TypeVar that's a union of all character name string literals
CHARACTER_NAMES: tuple[str, ...] = get_args(ALL_CHARACTERS)
_id_generator = count(BASE_ID, step=1)


class BrotatoLocation(Location):
    game = "Brotato"


class BrotatoCommonCrateLocation(Location):
    progress_type: LocationProgressType = LocationProgressType.DEFAULT


class BrotatoLegendaryCrateLocation(Location):
    progress_type: LocationProgressType = LocationProgressType.DEFAULT


@dataclass(frozen=True)
class BrotatoLocationBase:
    name: str
    is_event: bool = False
    id: int = field(init=False)
    progress_type: LocationProgressType = LocationProgressType.DEFAULT

    def __post_init__(self):
        if not self.is_event:
            id_ = BASE_ID + next(_id_generator)
        else:
            id_ = None
        # Necessary to set field on frozen dataclass
        object.__setattr__(self, "id", id_)

    def to_location(self, player: int, parent: Region | None = None) -> BrotatoLocation:
        location = BrotatoLocation(player, name=self.name, address=self.id, parent=parent)
        location.progress_type = self.progress_type
        return location


_wave_count = range(1, NUM_WAVES + 1)


def _get_per_location_characters_for_characters(
    characters: Iterable[str],
) -> tuple[list[BrotatoLocationBase], list[BrotatoLocationBase]]:
    wave_complete_locations: list[BrotatoLocationBase] = []
    run_complete_locations: list[BrotatoLocationBase] = []
    for character in characters:
        wave_complete_locations += [
            BrotatoLocationBase(name=WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=w, char=character))
            for w in _wave_count
        ]
        run_complete_locations.append(BrotatoLocationBase(name=RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)))

    return wave_complete_locations, run_complete_locations


# Get the per-character locations (wave/run complete), separated by the game pack the characters come from.
_character_wave_complete_locations: dict[str, list[BrotatoLocationBase]] = {}
_character_run_won_locations: dict[str, list[BrotatoLocationBase]] = {}
for group_name, group in CHARACTER_GROUPS.items():
    _character_wave_complete_locations[group_name], _character_run_won_locations[group_name] = (
        _get_per_location_characters_for_characters(group.characters)
    )

_loot_crate_drop_locations: list[BrotatoLocationBase] = [
    BrotatoLocationBase(name=CRATE_DROP_LOCATION_TEMPLATE.format(num=i)) for i in range(1, MAX_NORMAL_CRATE_DROPS + 1)
]
_legendary_loot_crate_drop_locations: list[BrotatoLocationBase] = [
    BrotatoLocationBase(
        name=LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i),
    )
    for i in range(1, MAX_LEGENDARY_CRATE_DROPS + 1)
]

_all_locations: list[BrotatoLocationBase] = [
    *[loc for group_locs in _character_wave_complete_locations.values() for loc in group_locs],
    *[loc for group_locs in _character_run_won_locations.values() for loc in group_locs],
    *_loot_crate_drop_locations,
    *_legendary_loot_crate_drop_locations,
]

location_table: dict[str, BrotatoLocationBase] = {loc.name: loc for loc in _all_locations}

location_name_to_id: dict[str, int] = {loc.name: loc.id for loc in _all_locations}
location_name_groups: dict[str, set[str]] = {
    "Normal Crate Drops": {c.name for c in _loot_crate_drop_locations},
    "Legendary Crate Drops": {c.name for c in _legendary_loot_crate_drop_locations},
}

for group_name, group in CHARACTER_GROUPS.items():
    location_name_groups[f"Wave Complete ({group.name} Characters)"] = {
        c.name for c in _character_wave_complete_locations[group_name]
    }
    location_name_groups[f"Run Won ({group.name} Characters)"] = {
        c.name for c in _character_run_won_locations[group_name]
    }
