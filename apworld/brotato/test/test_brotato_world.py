# from typing import ClassVar

# from test.param import classvar_matrix

from worlds.brotato.loot_crates import BrotatoLootCrateGroup

from . import BrotatoTestBase
from .data_sets.loot_crates import LOOT_CRATE_GROUP_DATA_SETS

# # There's only 20 valid values for "Waves per Check" option, so we can test every possible value here.
# waves_with_drops_pairs: list[tuple[int, list[int]]] = [
#     (
#         1,
#         [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
#     ),
#     (2, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]),
#     (3, [3, 6, 9, 12, 15, 18]),
#     (4, [4, 8, 12, 16, 20]),
#     (5, [5, 10, 15, 20]),
#     (6, [6, 12, 18]),
#     (7, [7, 14]),
#     (8, [8, 16]),
#     (9, [9, 18]),
#     (10, [10, 20]),
#     (11, [11]),
#     (12, [12]),
#     (13, [13]),
#     (14, [14]),
#     (15, [15]),
#     (16, [16]),
#     (17, [17]),
#     (18, [18]),
#     (19, [19]),
#     (20, [20]),
# ]


class TestBrotatoWorld(BrotatoTestBase):
    """Test attributes on the BrotatoWorld instance directly."""

    def test_common_loot_crate_groups_correct(self):
        for idx, test_data in enumerate(LOOT_CRATE_GROUP_DATA_SETS):
            with self.data_set_subtest(test_data, idx=idx):
                groups: list[BrotatoLootCrateGroup] = self.world.common_loot_crate_groups
                expected_groups: list[BrotatoLootCrateGroup] = test_data.expected_common_groups
                self.assertEqual(len(groups), len(expected_groups))
                for idx, (group, expected_group) in enumerate(zip(groups, expected_groups)):
                    self.assertEqual(group, expected_group, f"Common loot crate group {idx} is not correct.")

    def test_legendary_loot_crate_groups_correct(self):
        for idx, test_data in enumerate(LOOT_CRATE_GROUP_DATA_SETS):
            with self.data_set_subtest(test_data, idx=idx):
                groups: list[BrotatoLootCrateGroup] = self.world.legendary_loot_crate_groups
                expected_groups: list[BrotatoLootCrateGroup] = test_data.expected_legendary_groups
                self.assertEqual(len(groups), len(expected_groups))
                for idx, (group, expected_group) in enumerate(zip(groups, expected_groups)):
                    self.assertEqual(group, expected_group, f"Legendary loot crate group {idx} is not correct.")
