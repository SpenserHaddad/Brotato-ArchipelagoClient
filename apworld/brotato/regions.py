from typing import List, Literal, Optional

from BaseClasses import Region
from worlds.generic.Rules import ItemRule, add_item_rule

from . import BrotatoWorld
from .constants import (
    CHARACTERS,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from .locations import BrotatoLocation, location_table
from .rules import (
    create_has_character_rule,
    create_has_run_wins_rule,
    legendary_loot_crate_item_rule,
)


class BrotatoRegionFactory:
    def __init__(self, world: BrotatoWorld) -> None:
        self._world = world
        self._menu_region = Region("Menu", self._world.player, self._world.multiworld)


def create_regions(world: BrotatoWorld) -> List[Region]:
    player = world.player
    multiworld = world.multiworld
    menu_region = Region("Menu", player, multiworld)

    loot_crate_regions = _create_loot_crate_regions(world, menu_region, "normal")
    legendary_crate_regions = _create_loot_crate_regions(world, menu_region, "legendary")

    character_regions: list[Region] = []
    for character in CHARACTERS:
        character_region = _create_character_region(world, menu_region, character)
        character_regions.append(character_region)

        # # Crates can be gotten with any character...
        # character_region.connect(crate_drop_region, f"Drop crates for {character}")
        # # ...but we need to make sure you don't go to another character's in-game before you have them.
        # crate_drop_region.connect(character_region, f"Exit drop crates for {character}", rule=has_character_rule)
        # character_regions.append(character_region)

    return [
        menu_region,
        *loot_crate_regions,
        *legendary_crate_regions,
        *character_regions,
    ]


def _create_character_region(world: BrotatoWorld, parent_region: Region, character: str) -> Region:
    character_region = Region(f"In-Game ({character})", world.player, world.multiworld)
    character_run_won_location = location_table[RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)]
    character_region.locations.append(character_run_won_location.to_location(world.player, parent=character_region))

    character_wave_drop_location_names = [
        WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=w, char=character) for w in world.waves_with_checks
    ]
    character_region.locations.extend(
        location_table[loc].to_location(world.player, parent=character_region)
        for loc in character_wave_drop_location_names
    )

    has_character_rule = create_has_character_rule(world.player, character)
    parent_region.connect(
        character_region,
        f"Start Game ({character})",
        rule=has_character_rule,
    )
    return character_region


def _create_loot_crate_regions(
    world: BrotatoWorld,
    parent_region: Region,
    crate_type: Literal["normal", "legendary"],
) -> List[Region]:
    item_rule: Optional[ItemRule]
    if crate_type == "normal":
        num_items = world.options.num_common_crate_drops.value
        num_groups = world.options.num_common_crate_drop_groups.value
        location_name_template = CRATE_DROP_LOCATION_TEMPLATE
        region_name_template = CRATE_DROP_GROUP_REGION_TEMPLATE
        item_rule = None
    else:
        num_items = world.options.num_legendary_crate_drops.value
        num_groups = world.options.num_legendary_crate_drop_groups.value
        location_name_template = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE
        region_name_template = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
        item_rule = legendary_loot_crate_item_rule

    regions: List[Region] = []
    num_wins_to_unlock_group = world.options.num_victories.value // num_groups
    items_per_group = num_items // num_groups
    crate_count = 1
    wins_count = 1
    for group_idx in range(num_groups):
        crate_group_region = Region(region_name_template.format(num=group_idx), world.player, world.multiworld)
        items_in_group = min(items_per_group, num_items - crate_count)
        for _ in range(items_in_group):
            crate_location_name = location_name_template.format(num=crate_count)
            crate_location: BrotatoLocation = location_table[crate_location_name].to_location(
                world.player, parent=crate_group_region
            )
            if item_rule is not None:
                add_item_rule(crate_location, item_rule)

            crate_group_region.locations.append(crate_location)
            crate_count += 1

        region_wins_required = min(num_wins_to_unlock_group, world.options.num_victories.value - wins_count)
        crate_group_region_rule = create_has_run_wins_rule(world.player, region_wins_required)
        parent_region.connect(
            crate_group_region,
            name=crate_group_region.name,
            rule=crate_group_region_rule,
        )

    return regions
