from ..constants import (
    CRATE_DROP_GROUP_REGION_TEMPLATE,
    CRATE_DROP_LOCATION_TEMPLATE,
    LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE,
    LEGENDARY_CRATE_DROP_LOCATION_TEMPLATE,
    MAX_LEGENDARY_CRATE_DROPS,
    MAX_NORMAL_CRATE_DROPS,
    RUN_COMPLETE_LOCATION_TEMPLATE,
)
from ..items import ItemName
from ..loot_crates import BrotatoLootCrateGroup
from . import BrotatoTestBase
from .data_sets.loot_crates import LOOT_CRATE_GROUP_DATA_SETS


class TestBrotatoRegions(BrotatoTestBase):
    def test_correct_number_of_crate_drop_regions_created(self):
        """Test that only the location groups needed are created.

        It is possible to have one group for every loot crate, but if we have 25 crates and 5 groups, then there should
        only be 5 regions for normal crates and legendary crates.
        """
        total_possible_normal_crate_groups = MAX_NORMAL_CRATE_DROPS
        total_possible_legendary_crate_groups = MAX_LEGENDARY_CRATE_DROPS
        for test_data in LOOT_CRATE_GROUP_DATA_SETS:
            with self.data_set_subtest(test_data):
                player_regions = self.multiworld.regions.region_cache[self.player]
                for common_group in test_data.expected_common_groups:
                    expected_normal_crate_group = CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=common_group.index)
                    self.assertIn(
                        expected_normal_crate_group,
                        player_regions,
                        msg=f"Did not find expected normal loot crate region {expected_normal_crate_group}.",
                    )
                for legendary_group in test_data.expected_legendary_groups:
                    expected_legendary_crate_group = LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE.format(
                        num=legendary_group.index
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
        for test_data in LOOT_CRATE_GROUP_DATA_SETS:
            with self.data_set_subtest(test_data):
                self._test_loot_crate_regions_have_correct_locations(
                    test_data.expected_common_groups,
                    CRATE_DROP_LOCATION_TEMPLATE,
                    CRATE_DROP_GROUP_REGION_TEMPLATE,
                )
                self._test_loot_crate_regions_have_correct_locations(
                    test_data.expected_legendary_groups,
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
        for test_data in LOOT_CRATE_GROUP_DATA_SETS:
            with self.data_set_subtest(test_data):
                self._test_regions_have_correct_access_rules(
                    test_data.expected_common_groups, CRATE_DROP_GROUP_REGION_TEMPLATE
                )

    def test_legendary_crate_drop_region_have_correct_access_rules(self):
        """Check that each of the legendary loot crate drop regions is only unlocked after enough wins are achieved.

        This and the normal loot crate region tests are separate since they both need to incrementally update the
        state and check region access at each step. Splitting the tests, with a common private test method, means less
        duplication and no need to try and clear state within a test.
        """
        for test_data in LOOT_CRATE_GROUP_DATA_SETS:
            with self.data_set_subtest(test_data):
                self._test_regions_have_correct_access_rules(
                    test_data.expected_legendary_groups, LEGENDARY_CRATE_DROP_GROUP_REGION_TEMPLATE
                )

    def _test_regions_have_correct_access_rules(
        self, loot_crate_groups: list[BrotatoLootCrateGroup], region_template: str
    ):
        """Shared test logic for the crate drop region access rules tests."""

        run_won_item_name = ItemName.RUN_COMPLETE.value
        run_won_item = self.world.create_item(run_won_item_name)
        for group in loot_crate_groups:
            region_name = region_template.format(num=group.index)

            # Add Run Won items by getting each character's Run Won location in order
            num_wins = self.count(run_won_item_name)
            character_index = 0
            while num_wins < group.wins_to_unlock:
                # Make sure the region isn't reachable too early
                self.assertFalse(
                    self.can_reach_region(region_name),
                    msg=(
                        f'Region "{region_name}" should be unreachable without {group.wins_to_unlock} wins, have '
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
                msg=f"Could not reach region {region_name} with {group.wins_to_unlock} wins.",
            )

    def _test_loot_crate_regions_have_correct_locations(
        self,
        loot_crate_groups: list[BrotatoLootCrateGroup],
        location_template: str,
        region_template: str,
    ):
        player_regions = self.multiworld.regions.region_cache[self.player]

        loot_crate_counter = 1
        for group in loot_crate_groups:
            num_locations = group.num_crates
            expected_location_names = [
                location_template.format(num=i) for i in range(loot_crate_counter, loot_crate_counter + num_locations)
            ]
            loot_crate_counter += num_locations
            region = player_regions[region_template.format(num=group.index)]
            actual_location_names = [loc.name for loc in region.locations]
            self.assertListEqual(actual_location_names, expected_location_names)

    def test_fill(self):
        return super().test_fill()
