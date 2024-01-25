from __future__ import annotations

from typing import Callable, Sequence

from BaseClasses import CollectionState, Item, ItemClassification, MultiWorld, Region

from .Constants import (
    CHARACTERS,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from .Locations import location_table
from .Options import BrotatoOptions
from .Rules import BrotatoLogic


def create_regions(multiworld: MultiWorld, player: int, options: BrotatoOptions, waves_with_drops: Sequence[int]):
    menu_region = Region("Menu", player, multiworld)
    crate_drop_region = Region("Loot Crates", player, multiworld)

    for i in range(1, options.num_common_crate_drops + 1):
        location_name = CRATE_DROP_LOCATION_TEMPLATE.format(num=i)
        crate_drop_region.locations.append(location_table[location_name].to_location(player, parent=crate_drop_region))

    # Prevent progression items from being placed at legendary loot crate drops.
    # TODO: Ideally we would make the locations EXCLUDED, but that causes fill problems.
    def legendary_loot_crate_item_rule(item: Item) -> bool:
        return item.classification not in (
            ItemClassification.progression,
            ItemClassification.progression_skip_balancing,
        )

    for i in range(1, options.num_legendary_crate_drops + 1):
        location_name = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i)
        legendary_crate_drop_location = location_table[location_name].to_location(player, parent=crate_drop_region)
        legendary_crate_drop_location.item_rule = legendary_loot_crate_item_rule
        crate_drop_region.locations.append(legendary_crate_drop_location)

    menu_region.connect(crate_drop_region, "Drop Loot Crates")

    multiworld.regions += [menu_region, crate_drop_region]

    character_regions = []
    for character in CHARACTERS:
        character_region = Region(f"In-Game ({character})", player, multiworld)
        has_character_rule = _create_char_region_access_rule(player, character)
        character_run_won_location = location_table[RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)]
        character_region.locations.append(character_run_won_location.to_location(player, parent=character_region))

        char_wave_drop_location_names = [
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=w, char=character) for w in waves_with_drops
        ]
        character_region.locations.extend(
            location_table[loc].to_location(player, parent=character_region) for loc in char_wave_drop_location_names
        )
        menu_region.connect(
            character_region,
            f"Start Game ({character})",
            rule=has_character_rule,
        )

        # Crates can be gotten with any character...
        character_region.connect(crate_drop_region, f"Drop crates for {character}")
        # ...but we need to make sure you don't go to another character's in-game before you have them.
        crate_drop_region.connect(character_region, f"Exit drop crates for {character}", rule=has_character_rule)
        character_regions.append(character_region)

    multiworld.regions += character_regions


def _create_char_region_access_rule(player: int, character: str) -> Callable[[CollectionState], bool]:
    def char_region_access_rule(state: CollectionState):
        return BrotatoLogic._brotato_has_character(state, player, character)

    return char_region_access_rule
