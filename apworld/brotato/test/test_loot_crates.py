from collections.abc import Sequence
from unittest import TestCase

from ..loot_crates import build_loot_crate_groups
from .data_sets.loot_crates import TEST_DATA_SETS


class TestLootCrateGroups(TestCase):
    def test_common_loot_crate_groups_correct(self):
        for test_data in TEST_DATA_SETS:
            with self.subTest(msg=test_data.description, test_data=test_data):
                common_loot_crate_groups = build_loot_crate_groups(
                    test_data.options.num_common_crate_drops,
                    test_data.options.num_common_crate_drop_groups,
                    test_data.options.num_victories,
                )
                self.assertEqual(len(common_loot_crate_groups), test_data.expected_results.num_common_crate_regions)
                expected_crates_per_region: Sequence[int]
                if isinstance(test_data.expected_results.common_crates_per_region, int):
                    expected_crates_per_region = [
                        test_data.expected_results.common_crates_per_region
                    ] * test_data.expected_results.num_common_crate_regions
                else:
                    expected_crates_per_region = test_data.expected_results.common_crates_per_region

                for group, expected_num_crates, expected_wins_required in zip(
                    common_loot_crate_groups,
                    expected_crates_per_region,
                    test_data.expected_results.wins_required_per_common_region,
                ):
                    self.assertEqual(
                        group.num_crates,
                        expected_num_crates,
                        msg=f"Group {group.index} has the wrong number of crates.",
                    )
                    self.assertEqual(
                        group.wins_to_unlock,
                        expected_wins_required,
                        msg=f"Group {group.index} has the wrong number of wins needed to be in logic.",
                    )

    def test_legendary_loot_crate_groups_correct(self):
        for test_data in TEST_DATA_SETS:
            with self.subTest(msg=test_data.description, test_data=test_data):
                legendary_loot_crate_groups = build_loot_crate_groups(
                    test_data.options.num_legendary_crate_drops,
                    test_data.options.num_legendary_crate_drop_groups,
                    test_data.options.num_victories,
                )
                self.assertEqual(
                    len(legendary_loot_crate_groups), test_data.expected_results.num_legendary_crate_regions
                )
                expected_crates_per_region: Sequence[int]
                if isinstance(test_data.expected_results.legendary_crates_per_region, int):
                    expected_crates_per_region = [
                        test_data.expected_results.legendary_crates_per_region
                    ] * test_data.expected_results.num_legendary_crate_regions
                else:
                    expected_crates_per_region = test_data.expected_results.legendary_crates_per_region

                for group, expected_num_crates, expected_wins_required in zip(
                    legendary_loot_crate_groups,
                    expected_crates_per_region,
                    test_data.expected_results.wins_required_per_legendary_region,
                ):
                    self.assertEqual(
                        group.num_crates,
                        expected_num_crates,
                        msg=f"Group {group.index} has the wrong number of crates.",
                    )
                    self.assertEqual(
                        group.wins_to_unlock,
                        expected_wins_required,
                        msg=f"Group {group.index} has the wrong number of wins needed to be in logic.",
                    )
