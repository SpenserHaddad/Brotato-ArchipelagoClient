from typing import Tuple, Union

from ..constants import (
    BASE_GAME_CHARACTERS,
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
    RUN_COMPLETE_LOCATION_TEMPLATE,
)
from ..items import ItemName
from . import BrotatoTestBase
from .data_sets.loot_crates import TEST_DATA_SETS


class TestBrotatoRegions(BrotatoTestBase):
    # For some reason, this option keeps getting overwritten so it is missing the last five base game characters. I
    # suspect this has something to do with "test_num_victories_clamped_to_number_of_characters", which is the only case
    # that alters this option in such a way, but I can't find a good workaround for it.
    options = {"include_base_game_characters": BASE_GAME_CHARACTERS.characters}

    def test_correct_number_of_crate_drop_regions_created(self):
        """Test that only the location groups needed are created.

        It is possible to have one group for every loot crate, but if we have 25 crates and 5 groups, then there should
        only be 5 regions for normal crates and legendary crates.
        """
        total_possible_normal_crate_groups = MAX_NORMAL_CRATE_DROPS
        total_possible_legendary_crate_groups = MAX_LEGENDARY_CRATE_DROPS
        for test_data in self.data_set_subtests(TEST_DATA_SETS):
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
                test_data.options.num_common_crate_drop_groups + 1,
                total_possible_normal_crate_groups + 1,
            ):
                expected_missing_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_region_idx)
                self.assertNotIn(
                    expected_missing_group,
                    player_regions,
                    msg=f"Normal loot crate region {expected_missing_group} should not have been created.",
                )

            for legendary_region_idx in range(
                test_data.options.num_legendary_crate_drop_groups + 1,
                total_possible_legendary_crate_groups,
            ):
                expected_missing_group = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=legendary_region_idx)
                self.assertNotIn(
                    expected_missing_group,
                    player_regions,
                    msg=f"Legendary loot crate region {expected_missing_group} should not have been created.",
                )

    def test_crate_drop_regions_have_correct_locations(self):
        for test_data in self.data_set_subtests(TEST_DATA_SETS):
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
        for test_data in self.data_set_subtests(TEST_DATA_SETS):
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
        for test_data in self.data_set_subtests(TEST_DATA_SETS):
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
        for region_idx, num_wins_to_reach in zip(range(1, num_regions + 1), wins_per_region):
            region_name = region_template.format(num=region_idx)

            # Add Run Won items by getting each character's Run Won location in order
            num_wins = self.count(run_won_item_name)
            character_index = 0
            while num_wins < num_wins_to_reach:
                # Make sure the region isn't reachable too early
                self.assertFalse(
                    self.can_reach_region(region_name),
                    msg=(
                        f'Region "{region_name}" should be unreachable without {num_wins_to_reach} wins, have '
                        f"{num_wins}."
                    ),
                )

                next_character_won = self.world._include_characters[character_index]
                character_index += 1
                try:
                    next_win_location = self.world.get_location(
                        RUN_COMPLETE_LOCATION_TEMPLATE.format(char=next_character_won)
                    )
                except KeyError:
                    self.fail(f"Character {next_character_won} does not have a Run Won location.")
                old_num_wins = self.multiworld.state.count(run_won_item_name, self.player)
                # Set event=True so the state doesn't try to collect more wins and throw off our tests
                self.multiworld.state.collect(run_won_item, prevent_sweep=True, location=next_win_location)
                num_wins = self.multiworld.state.count(run_won_item_name, self.player)
                # Sanity check that the state updated as we intend it to.
                self.assertTrue(
                    num_wins == old_num_wins + 1,
                    msg="State added more than 1 'Run Won' item, this is a test implementation error.",
                )

            self.assertTrue(
                self.can_reach_region(region_name),
                msg=f"Could not reach region {region_name} with {num_wins_to_reach} wins.",
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
