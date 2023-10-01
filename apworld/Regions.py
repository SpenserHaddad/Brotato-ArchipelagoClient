from __future__ import annotations
from typing import Sequence

from BaseClasses import MultiWorld, Region

from .Constants import CHARACTERS
from .Locations import BrotatoLocation, character_specific_locations, location_name_to_id
from .Rules import BrotatoLogic


def create_regions(world: MultiWorld, player: int, waves_with_drops: Sequence[int]):
    menu_region = Region("Menu", player, world)
    crate_drop_region = Region("Loot Crates", player, world)

    crate_drop_locs_name_to_id = {}
    for i in range(getattr(world, "num_common_crate_drops")[player]):
        loc_name = f"Crate Drop {i}"
        crate_drop_locs_name_to_id[loc_name] = location_name_to_id[loc_name]

    for i in range(getattr(world, "num_legendary_crate_drops")[player]):
        loc_name = f"Legendary Crate Drop {i}"
        crate_drop_locs_name_to_id[loc_name] = location_name_to_id[loc_name]

    crate_drop_region.add_locations(crate_drop_locs_name_to_id, location_type=BrotatoLocation)  # type: ignore
    menu_region.connect(crate_drop_region, "Drop Loot Crates")

    world.regions += [menu_region, crate_drop_region]

    character_regions = []
    for character in CHARACTERS:
        char_in_game_region = Region(f"In-Game ({character})", player, world)
        char_in_game_locations = character_specific_locations[character]
        char_in_game_region.add_locations(char_in_game_locations, location_type=BrotatoLocation)
        char_region_access_rule = lambda state: BrotatoLogic._brotato_has_character(  # noqa: E731
            state, player, character
        )
        char_wave_drop_location_names = [f"Wave {w} Complete ({character})" for w in waves_with_drops]
        char_in_game_region.add_locations(
            {loc: location_name_to_id[loc] for loc in char_wave_drop_location_names}, location_type=BrotatoLocation
        )
        menu_region.connect(char_in_game_region, f"Start Game ({character})", rule=char_region_access_rule)

        # Crates can be gotten with any character
        char_in_game_region.connect(crate_drop_region, f"Drop crates for {character}")
        crate_drop_region.connect(char_in_game_region, f"Exit drop crates for {character}")
        character_regions.append(char_in_game_region)

    world.regions += character_regions
