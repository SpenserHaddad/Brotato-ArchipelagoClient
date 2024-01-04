from __future__ import annotations

from typing import Sequence

from BaseClasses import MultiWorld, Region

from .Constants import (
    CHARACTERS,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from .Locations import (
    BrotatoLocation,
    character_specific_locations,
    location_name_to_id,
)
from .Options import BrotatoOptions
from .Rules import BrotatoLogic


def create_regions(multiworld: MultiWorld, player: int, options: BrotatoOptions, waves_with_drops: Sequence[int]):
    menu_region = Region("Menu", player, multiworld)
    crate_drop_region = Region("Loot Crates", player, multiworld)

    crate_drop_locs_name_to_id = {}
    for i in range(1, options.num_common_crate_drops + 1):
        loc_name = CRATE_DROP_LOCATION_TEMPLATE.format(num=i)
        crate_drop_locs_name_to_id[loc_name] = location_name_to_id[loc_name]

    for i in range(1, options.num_legendary_crate_drops + 1):
        loc_name = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i)
        crate_drop_locs_name_to_id[loc_name] = location_name_to_id[loc_name]

    crate_drop_region.add_locations(crate_drop_locs_name_to_id, location_type=BrotatoLocation)
    menu_region.connect(crate_drop_region, "Drop Loot Crates")

    multiworld.regions += [menu_region, crate_drop_region]

    character_regions = []
    for character in CHARACTERS:
        char_in_game_region = Region(f"In-Game ({character})", player, multiworld)
        char_in_game_locations = character_specific_locations[character]
        char_in_game_region.add_locations(char_in_game_locations, location_type=BrotatoLocation)

        def char_region_access_rule(state) -> bool:
            return BrotatoLogic._brotato_has_character(state, player, character)

        # char_region_access_rule = lambda state: BrotatoLogic._brotato_has_character(state, player, character)
        char_wave_drop_location_names = [
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=w, char=character) for w in waves_with_drops
        ]
        char_in_game_region.add_locations(
            {loc: location_name_to_id[loc] for loc in char_wave_drop_location_names},
            location_type=BrotatoLocation,
        )
        menu_region.connect(
            char_in_game_region,
            f"Start Game ({character})",
            rule=char_region_access_rule,
        )

        # Crates can be gotten with any character
        char_in_game_region.connect(crate_drop_region, f"Drop crates for {character}")
        crate_drop_region.connect(char_in_game_region, f"Exit drop crates for {character}")
        character_regions.append(char_in_game_region)

    multiworld.regions += character_regions
