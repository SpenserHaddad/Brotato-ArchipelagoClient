from dataclasses import asdict, dataclass
from typing import List, Tuple, Union

from ..Constants import (
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
)
from . import BrotatoTestBase


@dataclass(frozen=True)
class _BrotatoTestOptions:
    """Subset of the full options that we want to control for the test, with defaults.

    This avoids needing to specify all the options for the dataclass, and makes using it in the tests slightly more
    concise.
    """

    num_common_crate_drops: int
    num_common_crate_drop_groups: int
    num_legendary_crate_drops: int
    num_legendary_crate_drop_groups: int


@dataclass(frozen=True)
class _BrotatoTestExpectedResults:
    # An int value means all regions have the same number of crates.
    # A tuple of ints means region "Crate Group {i}" has number of crates in index [i]
    common_crates_per_region: Union[int, Tuple[int, ...]]
    legendary_crates_per_region: Union[int, Tuple[int, ...]]


@dataclass(frozen=True)
class _BrotatoTestDataSet:
    options: _BrotatoTestOptions
    expected_results: _BrotatoTestExpectedResults

    def test_name(self) -> str:
        return ", ".join(
            [
                str(self.options.num_common_crate_drops),
                str(self.options.num_common_crate_drop_groups),
                str(self.options.num_legendary_crate_drops),
                str(self.options.num_legendary_crate_drop_groups),
            ]
        )


_TEST_DATA_SETS: List[_BrotatoTestDataSet] = [
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=25,
            num_common_crate_drop_groups=5,
            num_legendary_crate_drops=25,
            num_legendary_crate_drop_groups=5,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=5, legendary_crates_per_region=5),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=30,
            num_common_crate_drop_groups=6,
            num_legendary_crate_drops=30,
            num_legendary_crate_drop_groups=6,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=5, legendary_crates_per_region=5),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=20,
            num_common_crate_drop_groups=2,
            num_legendary_crate_drops=30,
            num_legendary_crate_drop_groups=6,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=10, legendary_crates_per_region=5),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=16,
            num_common_crate_drop_groups=3,
            num_legendary_crate_drops=16,
            num_legendary_crate_drop_groups=3,
        ),
        expected_results=_BrotatoTestExpectedResults(
            common_crates_per_region=(6, 5, 5), legendary_crates_per_region=(6, 5, 5)
        ),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=35,
            num_common_crate_drop_groups=15,
            num_legendary_crate_drops=25,
            num_legendary_crate_drop_groups=5,
        ),
        expected_results=_BrotatoTestExpectedResults(
            # Five "3's" and ten "2's", because the drops don't evenly divide into the groups
            common_crates_per_region=(*([3] * 5), *([2] * 10)),
            legendary_crates_per_region=5,
        ),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=50,
            num_common_crate_drop_groups=50,
            num_legendary_crate_drops=50,
            num_legendary_crate_drop_groups=50,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=1, legendary_crates_per_region=1),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=50,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=50,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=50, legendary_crates_per_region=50),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=1,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=1,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=1, legendary_crates_per_region=1),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=2,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=2,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=2, legendary_crates_per_region=2),
    ),
    _BrotatoTestDataSet(
        options=_BrotatoTestOptions(
            num_common_crate_drops=50,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=50,
            num_legendary_crate_drop_groups=2,
        ),
        expected_results=_BrotatoTestExpectedResults(common_crates_per_region=50, legendary_crates_per_region=25),
    ),
]


class TestBrotatoRegions(BrotatoTestBase):
    def _run(self, test_data: _BrotatoTestDataSet):
        self.options = asdict(test_data.options)
        self.world_setup()

    def test_correct_number_of_crate_drop_regions_created(self):
        """Test that only the location groups needed are created.

        It is possible to have one group for every loot crate, but if we have 25 crates and 5 groups, then there should
        only be 5 regions for normal crates and legendary crates.
        """
        total_possible_normal_crate_groups = MAX_NORMAL_CRATE_DROPS
        total_possible_legendary_crate_groups = MAX_LEGENDARY_CRATE_DROPS
        for test_data in _TEST_DATA_SETS:
            with self.subTest(msg=test_data.test_name()):
                self._run(test_data)
                player_regions = self.multiworld.regions.region_cache[self.player]
                for common_region_idx in range(1, test_data.options.num_common_crate_drop_groups + 1):
                    expected_normal_crate_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_region_idx)
                    self.assertIn(
                        expected_normal_crate_group,
                        player_regions,
                        msg=f"Did not find expected normal loot crate region {expected_normal_crate_group}.",
                    )
                for legendary_region_idx in range(1, test_data.options.num_legendary_crate_drop_groups + 1):
                    expected_legendary_crate_group = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE.format(
                        num=legendary_region_idx
                    )
                    self.assertIn(
                        expected_legendary_crate_group,
                        player_regions,
                        msg=f"Did not find expected legendary loot crate region {expected_legendary_crate_group}.",
                    )

                for common_region_idx in range(
                    test_data.options.num_common_crate_drop_groups + 1, total_possible_normal_crate_groups + 1
                ):
                    expected_missing_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_region_idx)
                    self.assertNotIn(
                        expected_missing_group,
                        player_regions,
                        msg=f"Normal loot crate region {expected_missing_group} should not have been created.",
                    )

                for legendary_region_idx in range(
                    test_data.options.num_legendary_crate_drop_groups + 1, total_possible_legendary_crate_groups
                ):
                    expected_missing_group = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=legendary_region_idx)
                    self.assertNotIn(
                        expected_missing_group,
                        player_regions,
                        msg=f"Legendary loot crate region {expected_missing_group} should not have been created.",
                    )

    def test_crate_drop_regions_have_correct_locations(self):
        for test_data in _TEST_DATA_SETS:
            with self.subTest(msg=test_data.test_name()):
                self._run(test_data)
                self._test_regions_have_correct_locations(
                    test_data.expected_results.common_crates_per_region,
                    test_data.options.num_common_crate_drop_groups,
                    CRATE_DROP_LOCATION_TEMPLATE,
                    CRATE_DROP_GROUP_REGION_TEMPLATE,
                )
                self._test_regions_have_correct_locations(
                    test_data.expected_results.legendary_crates_per_region,
                    test_data.options.num_legendary_crate_drop_groups,
                    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
                    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
                )

    def test_crate_drop_region_access_rules_correct(self):
        for test_data in _TEST_DATA_SETS:
            with self.subTest(msg=test_data.test_name()):
                self._run(test_data)
                player_regions = self.multiworld.regions.region_cache[self.player]
                for region in range(test_data.common_crate_regions):
                    pass

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
