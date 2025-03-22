from typing import Any
from unittest import TestCase

from BaseClasses import MultiWorld, Region

from ..constants import (
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    WAVE_COMPLETE_LOCATION_TEMPLATE,
)
from ..loot_crates import BrotatoLootCrateGroup
from ..regions import create_character_region, create_loot_crate_group_regions


class TestBrotatoRegions(TestCase):
    multiworld: MultiWorld
    parent_region: Region

    def setUp(self) -> None:
        self.multiworld = MultiWorld(1)
        self.parent_region = Region("Test Region", 1, self.multiworld)
        return super().setUp()

    def test_create_character_region_has_correct_locations(self):
        waves_with_checks = [5, 10, 15, 20]
        expected_location_names = [
            "Run Won (Crazy)",
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(char="Crazy", wave=5),
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(char="Crazy", wave=10),
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(char="Crazy", wave=15),
            WAVE_COMPLETE_LOCATION_TEMPLATE.format(char="Crazy", wave=20),
        ]
        region = create_character_region(self.parent_region, "Crazy", waves_with_checks)
        region_location_names = [loc.name for loc in region.locations]

        self.assertListEqual(region_location_names, expected_location_names)

    def test_create_character_region_invalid_character_fails(self):
        with self.assertRaises(Exception):
            create_character_region(self.parent_region, "Ironclad", [3, 6, 9, 12, 15, 18])

    def test_create_character_region_invalid_waves_with_checks_fails(self):
        """Check that we don't create a region with invalid wave complete locations.

        Mostly a sanity check on creating the waves with checks, but this has historically been an error-prone part of
        the code, so it's worth a bit of redundant testing.
        """
        invalid_waves_with_checks_value: list[Any] = [[1, 2, 3, -1], [0, 5, 10, 15, 20]]
        for invalid_value in invalid_waves_with_checks_value:
            with self.subTest(
                f"Check that create_character_region fails when waves_with_checks={invalid_value}",
                invalid_value=invalid_value,
            ):
                with self.assertRaises(Exception):
                    create_character_region(self.parent_region, "Brawler", invalid_value)

    def test_create_loot_crate_group_regions_common_crates_correct_locations(self):
        # Pretend we have 35 loot crates, 4 groups, and 20 wins needed
        loot_crate_groups: list[BrotatoLootCrateGroup] = [
            BrotatoLootCrateGroup(0, 10, 0),
            BrotatoLootCrateGroup(1, 10, 5),
            BrotatoLootCrateGroup(2, 10, 10),
            BrotatoLootCrateGroup(3, 5, 15),
        ]
        expected_locations_per_region: list[list[str]] = [
            [CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(1, 11)],
            [CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(11, 21)],
            [CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(21, 31)],
            [CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(31, 36)],
        ]

        regions: list[Region] = create_loot_crate_group_regions(self.parent_region, loot_crate_groups, "normal")
        locations_per_region: list[list[str]] = [[loc.name for loc in region.locations] for region in regions]
        self.assertListEqual(locations_per_region, expected_locations_per_region)

    def test_create_loot_crate_group_regions_legendary_crates_correct_locations(self):
        # Pretend we have 35 loot crates, 4 groups, and 20 wins needed
        loot_crate_groups: list[BrotatoLootCrateGroup] = [
            BrotatoLootCrateGroup(0, 10, 0),
            BrotatoLootCrateGroup(1, 10, 5),
            BrotatoLootCrateGroup(2, 10, 10),
            BrotatoLootCrateGroup(3, 5, 15),
        ]
        expected_locations_per_region: list[list[str]] = [
            [LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(1, 11)],
            [LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(11, 21)],
            [LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(21, 31)],
            [LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE.format(num=i) for i in range(31, 36)],
        ]

        regions: list[Region] = create_loot_crate_group_regions(self.parent_region, loot_crate_groups, "legendary")
        locations_per_region: list[list[str]] = [[loc.name for loc in region.locations] for region in regions]
        self.assertListEqual(locations_per_region, expected_locations_per_region)
