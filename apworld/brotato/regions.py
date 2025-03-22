from collections.abc import Callable
from typing import Literal

from BaseClasses import LocationProgressType, Region

from .constants import (
    CHARACTER_REGION_TEMPLATE,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    RUN_COMPLETE_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from .locations import BrotatoLocation, BrotatoLocationBase, location_table
from .loot_crates import BrotatoLootCrateGroup
from .rules import (
    create_has_character_rule,
    create_has_run_wins_rule,
)

RegionFactory = Callable[[str], Region]


def create_character_region(parent_region: Region, character: str, waves_with_checks: list[int]) -> Region:
    assert parent_region.multiworld is not None
    character_region: Region = Region(
        CHARACTER_REGION_TEMPLATE.format(char=character), parent_region.player, parent_region.multiworld
    )
    character_run_won_location: BrotatoLocationBase = location_table[
        RUN_COMPLETE_LOCATION_TEMPLATE.format(char=character)
    ]
    character_region.locations.append(
        character_run_won_location.to_location(character_region.player, parent=character_region)
    )

    for wave in waves_with_checks:
        wave_complete_location_name = WAVE_COMPLETE_LOCATION_TEMPLATE.format(wave=wave, char=character)
        wave_complete_location = location_table[wave_complete_location_name].to_location(
            character_region.player, parent=character_region
        )
        character_region.locations.append(wave_complete_location)

    has_character_rule = create_has_character_rule(character_region.player, character)
    parent_region.connect(
        character_region,
        f"Start Game ({character})",
        rule=has_character_rule,
    )
    return character_region


def create_regions_for_loot_crate_groups(
    parent_region: Region,
    loot_crate_groups: list[BrotatoLootCrateGroup],
    crate_type: Literal["normal", "legendary"],
) -> list[Region]:
    assert parent_region.multiworld is not None

    if crate_type == "normal":
        location_name_template = CRATE_DROP_LOCATION_TEMPLATE
        region_name_template = CRATE_DROP_GROUP_REGION_TEMPLATE
        progress_type = LocationProgressType.DEFAULT
    else:
        location_name_template = LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE
        region_name_template = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
        progress_type = LocationProgressType.EXCLUDED

    regions: list[Region] = []
    crate_count = 1

    for group_idx, group in enumerate(loot_crate_groups, start=1):
        group_region: Region = Region(
            region_name_template.format(num=group_idx), parent_region.player, parent_region.multiworld
        )
        for _ in range(1, group.num_crates + 1):
            crate_location_name = location_name_template.format(num=crate_count)
            crate_location: BrotatoLocation = location_table[crate_location_name].to_location(
                group_region.player, parent=group_region
            )
            crate_location.progress_type = progress_type

            group_region.locations.append(crate_location)
            crate_count += 1

        group_region_rule = create_has_run_wins_rule(group_region.player, group.wins_to_unlock)
        parent_region.connect(group_region, name=group_region.name, rule=group_region_rule)
        regions.append(group_region)

    return regions
