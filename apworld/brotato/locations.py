from dataclasses import dataclass, field
from itertools import count
from typing import Dict, List, Optional, Set, Tuple, get_args

from BaseClasses import Location, LocationProgressType, Region

from .constants import (
    BASE_ID,
    CHARACTERS,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)

# TypeVar that's a union of all character name string literals
CHARACTER_NAMES: Tuple[str, ...] = get_args(CHARACTERS)
_id_generator = count(BASE_ID, step=1)


class BrotatoLocation(Location):
    game = "Brotato"


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

    def to_location(self, player: int, parent: Optional[Region] = None) -> BrotatoLocation:
        location = BrotatoLocation(player, name=self.name, address=self.id, parent=parent)
        location.progress_type = self.progress_type
        return location


_wave_count = range(1, NUM_WAVES + 1)

_character_wave_complete_locations: List[BrotatoLocationBase] = []
_character_run_won_locations: List[BrotatoLocationBase] = []
for char in CHARACTERS:
    _char_wave_complete_locations = [
        BrotatoLocationBase(name=WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=w, char=char)) for w in _wave_count
    ]
    _char_run_complete_location = BrotatoLocationBase(name=RUN_COMPLETE_LOCATION_TEMPLATE.format(char=char))
    _character_wave_complete_locations += _char_wave_complete_locations
    _character_run_won_locations.append(_char_run_complete_location)


_loot_crate_drop_locations: List[BrotatoLocationBase] = [
    BrotatoLocationBase(name=CRATE_DROP_LOCATION_TEMPLATE.format(num=i)) for i in range(1, MAX_NORMAL_CRATE_DROPS + 1)
]
_legendary_loot_crate_drop_locations: List[BrotatoLocationBase] = [
    BrotatoLocationBase(
        name=LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i),
    )
    for i in range(1, MAX_LEGENDARY_CRATE_DROPS + 1)
]

_all_locations: List[BrotatoLocationBase] = [
    *_character_wave_complete_locations,
    *_character_run_won_locations,
    *_loot_crate_drop_locations,
    *_legendary_loot_crate_drop_locations,
]

location_table: Dict[str, BrotatoLocationBase] = {loc.name: loc for loc in _all_locations}

location_name_to_id: Dict[str, int] = {loc.name: loc.id for loc in _all_locations}
location_name_groups: Dict[str, Set[str]] = {
    "Wave Complete Specific Character": set(c.name for c in _character_wave_complete_locations),
    "Run Win Specific Character": set(c.name for c in _character_run_won_locations),
    "Normal Crate Drops": set(c.name for c in _loot_crate_drop_locations),
    "Legendary Crate Drops": set(c.name for c in _legendary_loot_crate_drop_locations),
    # "Shop Items": set(c.name for c in _shop_item_locations),
}
