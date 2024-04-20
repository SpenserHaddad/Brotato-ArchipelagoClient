from dataclasses import asdict, dataclass
from typing import List, Optional, Tuple, Union

from ..Constants import (
    CHARACTERS,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROP_GROUPS,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROP_GROUPS,
    MAX_NORMAL_CRATE_DROPS,
    NUM_CHARACTERS,
    RUN_COMPLETE_LOCATION_TEMPLATE,
)
from ..Items import ItemName
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
    num_victories: int = 30


@dataclass(frozen=True)
class _BrotatoTestExpectedResults:
    # An int value means all regions have the same number of crates.
    # A tuple of ints means region "Crate Group {i}" has number of crates in index [i]
    num_common_crate_regions: int
    common_crates_per_region: Union[int, Tuple[int, ...]]
    num_legendary_crate_regions: int
    legendary_crates_per_region: Union[int, Tuple[int, ...]]
    wins_required_per_common_region: Tuple[int, ...]
    wins_required_per_legendary_region: Tuple[int, ...]

    def __post_init__(self):
        """Validate the expected results to make sure the fields are consistent.

        Currently, this just means checking that the expected number of regions matches the number of entries in the
        crates per region fields.
        """

        if isinstance(self.common_crates_per_region, tuple):
            num_common_crate_regions = len(self.common_crates_per_region)
            if num_common_crate_regions != self.num_common_crate_regions:
                raise ValueError(
                    f"common_crates_per_region has {num_common_crate_regions} entries, expected "
                    f"{self.num_common_crate_regions}."
                )

        if len(self.wins_required_per_common_region) != self.num_common_crate_regions:
            num_win_entries = len(self.wins_required_per_common_region)
            raise ValueError(
                f"wins_required_per_common_region has {num_win_entries} entries, expected "
                f"{self.num_common_crate_regions}."
            )

        if isinstance(self.legendary_crates_per_region, tuple):
            num_legendary_crate_regions = len(self.legendary_crates_per_region)
            if num_legendary_crate_regions != self.num_legendary_crate_regions:
                raise ValueError(
                    f"legendary_crates_per_region has {num_legendary_crate_regions} entries, expected "
                    f"{self.num_legendary_crate_regions}."
                )

        if len(self.wins_required_per_legendary_region) != self.num_legendary_crate_regions:
            num_win_entries = len(self.wins_required_per_legendary_region)
            raise ValueError(
                f"wins_required_per_legendary_region has {num_win_entries} entries, expected "
                f"{self.num_legendary_crate_regions}."
            )


@dataclass(frozen=True)
class _BrotatoTestDataSet:
    options: _BrotatoTestOptions
    expected_results: _BrotatoTestExpectedResults
    description: Optional[str] = None

    def test_name(self) -> str:
        options_str = ", ".join(
            [
                f"CD={self.options.num_common_crate_drops}",
                f"CG={self.options.num_common_crate_drop_groups}",
                f"LD={self.options.num_legendary_crate_drops}",
                f"LG={self.options.num_legendary_crate_drop_groups}",
                f"NV={self.options.num_victories}",
            ]
        )
        if self.description:
            name = f"{options_str} ({self.description})"
        else:
            name = options_str

        return name


_TEST_DATA_SETS: List[_BrotatoTestDataSet] = [
    _BrotatoTestDataSet(
        description="Easily divisible, common and legendary same (25 crates)",
        options=_BrotatoTestOptions(
            num_common_crate_drops=25,
            num_common_crate_drop_groups=5,
            num_legendary_crate_drops=25,
            num_legendary_crate_drop_groups=5,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=5,
            common_crates_per_region=5,
            num_legendary_crate_regions=5,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 6, 12, 18, 24),
            wins_required_per_legendary_region=(0, 6, 12, 18, 24),
        ),
    ),
    _BrotatoTestDataSet(
        description="Easily divisible, common and legendary same (30 crates)",
        options=_BrotatoTestOptions(
            num_common_crate_drops=30,
            num_common_crate_drop_groups=6,
            num_legendary_crate_drops=30,
            num_legendary_crate_drop_groups=6,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=6,
            common_crates_per_region=5,
            num_legendary_crate_regions=6,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 5, 10, 15, 20, 25),
            wins_required_per_legendary_region=(0, 5, 10, 15, 20, 25),
        ),
    ),
    _BrotatoTestDataSet(
        description="Easily divisible, common and legendary are different",
        options=_BrotatoTestOptions(
            num_common_crate_drops=20,
            num_common_crate_drop_groups=2,
            num_legendary_crate_drops=30,
            num_legendary_crate_drop_groups=6,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=2,
            common_crates_per_region=10,
            num_legendary_crate_regions=6,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 15),
            wins_required_per_legendary_region=(0, 5, 10, 15, 20, 25),
        ),
    ),
    _BrotatoTestDataSet(
        description="Unequal groups",
        options=_BrotatoTestOptions(
            num_common_crate_drops=16,
            num_common_crate_drop_groups=3,
            num_legendary_crate_drops=16,
            num_legendary_crate_drop_groups=3,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=3,
            common_crates_per_region=(6, 5, 5),
            num_legendary_crate_regions=3,
            legendary_crates_per_region=(6, 5, 5),
            wins_required_per_common_region=(0, 10, 20),
            wins_required_per_legendary_region=(0, 10, 20),
        ),
    ),
    _BrotatoTestDataSet(
        description="Unequal groups, common and legendary are different",
        options=_BrotatoTestOptions(
            num_common_crate_drops=35,
            num_common_crate_drop_groups=15,
            num_legendary_crate_drops=25,
            num_legendary_crate_drop_groups=5,
        ),
        expected_results=_BrotatoTestExpectedResults(
            # Five "3's" and ten "2's", because the drops don't evenly divide into the groups
            num_common_crate_regions=15,
            common_crates_per_region=tuple(([3] * 5) + ([2] * 10)),
            num_legendary_crate_regions=5,
            legendary_crates_per_region=5,
            wins_required_per_common_region=(0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28),
            wins_required_per_legendary_region=(0, 6, 12, 18, 24),
        ),
    ),
    _BrotatoTestDataSet(
        description="Max possible groups and crates, more groups than req. wins",
        options=_BrotatoTestOptions(
            num_common_crate_drops=MAX_NORMAL_CRATE_DROPS,
            num_common_crate_drop_groups=MAX_NORMAL_CRATE_DROP_GROUPS,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=MAX_LEGENDARY_CRATE_DROP_GROUPS,
        ),
        expected_results=_BrotatoTestExpectedResults(
            # The number of groups will be set to 30 when generating.
            num_common_crate_regions=30,
            common_crates_per_region=tuple(([2] * 20) + ([1] * 10)),
            num_legendary_crate_regions=30,
            legendary_crates_per_region=tuple(([2] * 20) + ([1] * 10)),
            # Every win will unlock a new crate drop group.
            wins_required_per_common_region=tuple(range(30)),
            wins_required_per_legendary_region=tuple(range(30)),
        ),
    ),
    _BrotatoTestDataSet(
        description="Max possible groups and crates",
        options=_BrotatoTestOptions(
            num_victories=NUM_CHARACTERS,
            num_common_crate_drops=MAX_NORMAL_CRATE_DROPS,
            num_common_crate_drop_groups=MAX_NORMAL_CRATE_DROP_GROUPS,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=MAX_LEGENDARY_CRATE_DROP_GROUPS,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=NUM_CHARACTERS,
            common_crates_per_region=tuple(([2] * 6) + ([1] * 38)),
            num_legendary_crate_regions=NUM_CHARACTERS,
            legendary_crates_per_region=tuple(([2] * 6) + ([1] * 38)),
            # Every win will unlock a new crate drop group.
            wins_required_per_common_region=tuple(range(MAX_NORMAL_CRATE_DROP_GROUPS)),
            wins_required_per_legendary_region=tuple(range(MAX_LEGENDARY_CRATE_DROP_GROUPS)),
        ),
    ),
    _BrotatoTestDataSet(
        description="Max number of crates, one group",
        options=_BrotatoTestOptions(
            num_victories=NUM_CHARACTERS,
            num_common_crate_drops=MAX_NORMAL_CRATE_DROPS,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=50,
            num_legendary_crate_regions=1,
            legendary_crates_per_region=50,
            # All the crates should be in the first group which is unlocked by default.
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0,),
        ),
    ),
    _BrotatoTestDataSet(
        description="1 crate and 1 group",
        options=_BrotatoTestOptions(
            num_common_crate_drops=1,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=1,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=1,
            num_legendary_crate_regions=1,
            legendary_crates_per_region=1,
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0,),
        ),
    ),
    _BrotatoTestDataSet(
        description="2 crates, 1 group",
        options=_BrotatoTestOptions(
            num_common_crate_drops=2,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=2,
            num_legendary_crate_drop_groups=1,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=2,
            num_legendary_crate_regions=1,
            legendary_crates_per_region=2,
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0,),
        ),
    ),
    _BrotatoTestDataSet(
        description="Max number of crates, 1 common group, 2 legendary groups",
        options=_BrotatoTestOptions(
            num_common_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_common_crate_drop_groups=1,
            num_legendary_crate_drops=MAX_LEGENDARY_CRATE_DROPS,
            num_legendary_crate_drop_groups=2,
        ),
        expected_results=_BrotatoTestExpectedResults(
            num_common_crate_regions=1,
            common_crates_per_region=50,
            num_legendary_crate_regions=2,
            legendary_crates_per_region=25,
            wins_required_per_common_region=(0,),
            wins_required_per_legendary_region=(0, 15),
        ),
    ),
]


class TestBrotatoRegions(BrotatoTestBase):
    def _run(self, test_data: _BrotatoTestDataSet):
        self.options = {**asdict(test_data.options)}
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
                for common_region_idx in range(1, test_data.expected_results.num_common_crate_regions + 1):
                    expected_normal_crate_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_region_idx)
                    self.assertIn(
                        expected_normal_crate_group,
                        player_regions,
                        msg=f"Did not find expected normal loot crate region {expected_normal_crate_group}.",
                    )
                for legendary_region_idx in range(1, test_data.expected_results.num_legendary_crate_regions + 1):
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
                    test_data.expected_results.num_common_crate_regions,
                    CRATE_DROP_LOCATION_TEMPLATE,
                    CRATE_DROP_GROUP_REGION_TEMPLATE,
                )
                self._test_regions_have_correct_locations(
                    test_data.expected_results.legendary_crates_per_region,
                    test_data.expected_results.num_legendary_crate_regions,
                    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
                    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
                )

    def test_normal_crate_drop_region_have_correct_access_rules(self):
        """Check that each of the normal loot crate drop regions is only unlocked after enough wins are achieved.

        This and the legendary loot crate region tests are separate since they both need to incrementally update the
        state and check region access at each step. Splitting the tests, with a common private test method, means less
        duplication and no need to try and clear state within a test.
        """
        # run_won_item_name = ItemName.RUN_COMPLETE.value
        # run_won_item = self.world.create_item(run_won_item_name)
        for test_data in _TEST_DATA_SETS:
            with self.subTest(msg=test_data.test_name()):
                self._run(test_data)

                self._test_regions_have_correct_access_rules(
                    test_data.expected_results.wins_required_per_common_region,
                    test_data.expected_results.num_common_crate_regions,
                    CRATE_DROP_GROUP_REGION_TEMPLATE,
                )

    def test_legendary_crate_drop_region_have_correct_access_rules(self):
        """Check that each of the legendary loot crate drop regions is only unlocked after enough wins are achieved.

        This and the normal loot crate region tests are separate since they both need to incrementally update the
        state and check region access at each step. Splitting the tests, with a common private test method, means less
        duplication and no need to try and clear state within a test.
        """
        # run_won_item_name = ItemName.RUN_COMPLETE.value
        # run_won_item = self.world.create_item(run_won_item_name)
        for test_data in _TEST_DATA_SETS:
            with self.subTest(msg=test_data.test_name()):
                self._run(test_data)

                self._test_regions_have_correct_access_rules(
                    test_data.expected_results.wins_required_per_legendary_region,
                    test_data.expected_results.num_legendary_crate_regions,
                    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
                )

    def _test_regions_have_correct_access_rules(
        self, wins_per_region: Tuple[int, ...], num_regions: int, region_template: str
    ):
        """Shared test logic for the crate drop region access rules tests."""

        run_won_item_name = ItemName.RUN_COMPLETE.value
        run_won_item = self.world.create_item(run_won_item_name)
        character_index = 0
        for region_idx, num_wins_to_reach in zip(range(1, num_regions + 1), wins_per_region):
            region_name = region_template.format(num=region_idx)

            # Add Run Won items by getting each character's Run Won location in order
            num_wins = self.count(run_won_item_name)
            while num_wins < num_wins_to_reach:
                # Make sure the region isn't reachable too early
                assert not self.can_reach_region(
                    region_name
                ), f'Region "{region_name}" should be unreachable without {num_wins_to_reach} wins, have {num_wins}.'

                next_character_won = CHARACTERS[character_index]
                character_index += 1
                next_win_location = self.world.get_location(
                    RUN_COMPLETE_LOCATION_TEMPLATE.format(char=next_character_won)
                )
                old_num_wins = self.multiworld.state.count(run_won_item_name, self.player)
                # Set event=True so the state doesn't try to collect more wins and throw off our tests
                self.multiworld.state.collect(run_won_item, event=True, location=next_win_location)
                num_wins = self.multiworld.state.count(run_won_item_name, self.player)
                # Sanity check that the state updated as we intend it to.
                assert (
                    num_wins == old_num_wins + 1
                ), "State added more than 1 'Run Won' item, this is a test implementation error."

            assert self.can_reach_region(
                region_name
            ), f"Could not reach region {region_name} with {num_wins_to_reach} wins."

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
