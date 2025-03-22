from collections.abc import Callable
from typing import Literal

from BaseClasses import Region

from .constants import (
    CHARACTER_REGION_TEMPLATE,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    NUM_WAVES,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from .locations import BrotatoCommonCrateLocation, BrotatoLegendaryCrateLocation, BrotatoLocation, location_table
from .loot_crates import BrotatoLootCrateGroup
from .rules import (
    create_has_character_rule,
    create_has_run_wins_rule,
)

RegionFactory = Callable[[str], Region]


def create_character_region(create_region: RegionFactory, character: str, waves_with_checks: list[int]) -> Region:
    character_region: Region = create_region(CHARACTER_REGION_TEMPLATE.format(char=character))
    run_complete_location_name = RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)
    region_locations: dict[str, int | None] = {
        run_complete_location_name: location_table[run_complete_location_name].id
    }

    for wave in waves_with_checks:
        if wave not in range(1, NUM_WAVES + 1):
            raise ValueError(f"Invalid wave number {wave}.")
        wave_complete_location_name = WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=wave, char=character)
        region_locations[wave_complete_location_name] = location_table[wave_complete_location_name].id

    character_region.add_locations(region_locations, BrotatoLocation)
    # has_character_rule = create_has_character_rule(character_region.player, character)
    # parent_region.connect(
    #     character_region,
    #     f"Start Game ({character})",
    #     rule=has_character_rule,
    # )
    return character_region


def create_loot_crate_group_regions(
    create_region: RegionFactory,
    loot_crate_groups: list[BrotatoLootCrateGroup],
    crate_type: Literal["common", "legendary"],
) -> list[Region]:
    if crate_type == "common":
        location_name_template = CRATE_DROP_LOCATION_TEMPLATE
        region_name_template = CRATE_DROP_GROUP_REGION_TEMPLATE
        location_cls = BrotatoCommonCrateLocation
    else:
        location_name_template = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE
        region_name_template = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
        location_cls = BrotatoLegendaryCrateLocation

    regions: list[Region] = []
    crate_count = 1

    for group_idx, group in enumerate(loot_crate_groups, start=1):
        group_region: Region = create_region(region_name_template.format(num=group_idx))
        group_locations: dict[str, int | None] = {}
        for _ in range(1, group.num_crates + 1):
            crate_location_name = location_name_template.format(num=crate_count)
            group_locations[crate_location_name] = location_table[crate_location_name].id
            crate_count += 1

        group_region.add_locations(group_locations, location_cls)
        # group_region_rule = create_has_run_wins_rule(group_region.player, group.wins_to_unlock)
        # parent_region.connect(group_region, name=group_region.name, rule=group_region_rule)
        regions.append(group_region)

    return regions
