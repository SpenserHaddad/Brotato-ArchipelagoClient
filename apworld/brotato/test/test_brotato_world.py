# from typing import ClassVar

# from test.param import classvar_matrix

from . import BrotatoTestBase
from .data_sets.loot_crates import TEST_DATA_SETS, BrotatoLootCrateTestDataSet

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


# @classvar_matrix(value_and_expected=waves_with_drops_pairs)
# class TestBrotatoWorldWavesWithDrops(BrotatoTestBase):
#     value_and_expected: ClassVar[tuple[int, list[int]]]

#     def test_waves_with_drops_correct(self):
#         option_value, expected_waves_with_checks = self.value_and_expected
#         self._run({"waves_per_drop": option_value})
#         # Coerce to list so the types match
#         assert list(self.world.waves_with_checks) == expected_waves_with_checks


class TestBrotatoWorld(BrotatoTestBase):
    """Test attributes on the BrotatoWorld instance directly."""

    def test_common_loot_crate_groups_correct(self):
        test_data: BrotatoLootCrateTestDataSet
        for test_data in self.data_set_subtests(TEST_DATA_SETS):
            common_crate_groups = self.world.common_loot_crate_groups
            assert len(common_crate_groups) == test_data.expected_results.num_common_crate_regions
            for index, group in enumerate(common_crate_groups):
                assert group.index == index + 1
                if isinstance(test_data.expected_results.common_crates_per_region, int):
                    assert group.num_crates == test_data.expected_results.common_crates_per_region
                else:
                    assert group.num_crates == test_data.expected_results.common_crates_per_region[index]

                assert group.wins_to_unlock == test_data.expected_results.wins_required_per_common_region[index]

    def test_legendary_loot_crate_groups_correct(self):
        test_data: BrotatoLootCrateTestDataSet
        for test_data in self.data_set_subtests(TEST_DATA_SETS):
            legendary_crate_groups = self.world.legendary_loot_crate_groups
            assert len(legendary_crate_groups) == test_data.expected_results.num_legendary_crate_regions
            for index, group in enumerate(legendary_crate_groups):
                assert group.index == index + 1
                if isinstance(test_data.expected_results.legendary_crates_per_region, int):
                    assert group.num_crates == test_data.expected_results.legendary_crates_per_region
                else:
                    assert group.num_crates == test_data.expected_results.legendary_crates_per_region[index]

                assert group.wins_to_unlock == test_data.expected_results.wins_required_per_legendary_region[index]
