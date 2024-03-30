from typing import List, Tuple, NamedTuple, Union
from ..Constants import (
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    MAX_NORMAL_CRATE_DROPS,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROPS,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
)
from . import BrotatoTestBase


class _OptionsAndResults(NamedTuple):
    common_crate_locations: int
    common_crate_regions: int
    legendary_crate_locations: int
    legendary_crate_regions: int

    # An int value means all regions have the same number of crates.
    # A tuple of ints means region "Crate Group {i}" has number of crates in index [i]
    common_crates_per_region: Union[int, Tuple[int, ...]]
    legendary_crates_per_region: Union[int, Tuple[int, ...]]


_OPTION_SETS: List[_OptionsAndResults] = [
    _OptionsAndResults(25, 5, 25, 5, 5, 5),
    _OptionsAndResults(30, 6, 30, 6, 5, 5),
    _OptionsAndResults(20, 2, 30, 6, 10, 5),
    _OptionsAndResults(16, 3, 16, 3, [6, 5, 5], [6, 5, 5]),
    _OptionsAndResults(35, 15, 25, 5, [7] + [2] * 14, 5),
    _OptionsAndResults(50, 50, 50, 50, 1, 1),
    _OptionsAndResults(50, 1, 50, 1, 50, 50),
    _OptionsAndResults(1, 1, 1, 1, 1, 1),
    _OptionsAndResults(2, 1, 2, 1, 2, 2),
    _OptionsAndResults(50, 1, 50, 2, 50, 25),
]


class TestBrotatoRegions(BrotatoTestBase):
    def _run(self, options: _OptionsAndResults):
        self.options = {
            "starting_characters": 1,  # Just use the default five
            "num_common_crate_drops": options.common_crate_locations,
            "num_common_crate_drop_groups": options.common_crate_regions,
            "num_legendary_crate_drops": options.legendary_crate_locations,
            "num_legendary_crate_drop_groups": options.legendary_crate_regions,
        }
        self.world_setup()

    def test_correct_number_of_crate_drop_regions_created(self):
        """Test that only the location groups needed are created.

        It is possible to have one group for every loot crate, but if we have 25 crates and 5 groups, then there should
        only be 5 regions for normal crates and legendary crates.
        """
        total_possible_normal_crate_groups = MAX_NORMAL_CRATE_DROPS
        total_possible_legendary_crate_groups = MAX_LEGENDARY_CRATE_DROPS
        for options_set in _OPTION_SETS:
            with self.subTest(options_and_results=options_set):
                self._run(options_set)
                player_regions = self.multiworld.regions.region_cache[self.player]

                for common_region_idx in range(1, options_set.common_crate_regions + 1):
                    expected_normal_crate_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_region_idx)
                    self.assertIn(
                        expected_normal_crate_group,
                        player_regions,
                        msg=f"Did not find expected normal loot crate region {expected_normal_crate_group}.",
                    )
                for legendary_region_idx in range(1, options_set.legendary_crate_regions + 1):
                    expected_legendary_crate_group = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE.format(
                        num=legendary_region_idx
                    )
                    self.assertIn(
                        expected_legendary_crate_group,
                        player_regions,
                        msg=f"Did not find expected legendary loot crate region {expected_legendary_crate_group}.",
                    )

                for common_region_idx in range(
                    options_set.common_crate_regions + 1, total_possible_normal_crate_groups + 1
                ):
                    expected_missing_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_region_idx)
                    self.assertNotIn(
                        expected_missing_group,
                        player_regions,
                        msg=f"Normal loot crate region {expected_missing_group} should not have been created.",
                    )

                for legendary_region_idx in range(
                    options_set.legendary_crate_regions + 1, total_possible_legendary_crate_groups
                ):
                    expected_missing_group = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=legendary_region_idx)
                    self.assertNotIn(
                        expected_missing_group,
                        player_regions,
                        msg=f"Legendary loot crate region {expected_missing_group} should not have been created.",
                    )

    def test_crate_drop_regions_have_correct_locations(self):
        for options_set in _OPTION_SETS:
            with self.subTest(options_and_results=options_set):
                self._run(options_set)
                self._test_regions_have_correct_locations(
                    options_set.common_crates_per_region,
                    options_set.common_crate_regions,
                    CRATE_DROP_LOCATION_TEMPLATE,
                    CRATE_DROP_GROUP_REGION_TEMPLATE,
                )
                self._test_regions_have_correct_locations(
                    options_set.legendary_crates_per_region,
                    options_set.legendary_crate_regions,
                    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
                    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
                )

    def _test_regions_have_correct_locations(
        self,
        locations_per_region: Union[int, Tuple[int, ...]],
        num_regions: int,
        location_template: str,
        region_template: str,
    ):
        player_regions = self.multiworld.regions.region_cache[self.player]
        if isinstance(locations_per_region, int):
            num_locations_per_region = tuple([locations_per_region] * num_regions)
        else:
            num_locations_per_region = locations_per_region

        location_counter = 1
        for region_idx in range(num_regions):
            num_locations = num_locations_per_region[region_idx]
            expected_location_names = [
                location_template.format(num=i) for i in range(location_counter, location_counter + num_locations)
            ]
            location_counter += num_locations
            region = player_regions[region_template.format(num=region_idx + 1)]
            actual_location_names = [loc.name for loc in region.locations]
            self.assertListEqual(actual_location_names, expected_location_names)
