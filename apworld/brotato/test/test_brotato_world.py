from typing import List, Tuple

from . import BrotatoTestBase
from ._data_sets import BrotatoTestDataSet


class TestBrotatoWorld(BrotatoTestBase):
    """Test attributes on the BrotatoWorld instance directly."""

    def test_waves_with_drops_correct(self):
        # There's only 20 valid values for "Waves per Check" option, so we can test every possible value here.
        option_and_expected: List[Tuple[int, List[int]]] = [
            (
                1,
                [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
            ),
            (2, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]),
            (3, [3, 6, 9, 12, 15, 18]),
            (4, [4, 8, 12, 16, 20]),
            (5, [5, 10, 15, 20]),
            (6, [6, 12, 18]),
            (7, [7, 14]),
            (8, [8, 16]),
            (9, [9, 18]),
            (10, [10, 20]),
            (11, [11]),
            (12, [12]),
            (13, [13]),
            (14, [14]),
            (15, [15]),
            (16, [16]),
            (17, [17]),
            (18, [18]),
            (19, [19]),
            (20, [20]),
        ]
        for option_value, expected_waves_with_checks in option_and_expected:
            with self.subTest(msg=f"Waves per check = {option_value}"):
                self._run({"waves_per_drop": option_value})
                # Coerce to list so the types match
                assert list(self.world.waves_with_checks) == expected_waves_with_checks

    def test_common_loot_crate_groups_correct(self):
        test_data: BrotatoTestDataSet
        for test_data in self._test_data_set_subtests():
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
        test_data: BrotatoTestDataSet
        for test_data in self._test_data_set_subtests():
            legendary_crate_groups = self.world.legendary_loot_crate_groups
            assert len(legendary_crate_groups) == test_data.expected_results.num_legendary_crate_regions
            for index, group in enumerate(legendary_crate_groups):
                assert group.index == index + 1
                if isinstance(test_data.expected_results.legendary_crates_per_region, int):
                    assert group.num_crates == test_data.expected_results.legendary_crates_per_region
                else:
                    assert group.num_crates == test_data.expected_results.legendary_crates_per_region[index]

                assert group.wins_to_unlock == test_data.expected_results.wins_required_per_legendary_region[index]
