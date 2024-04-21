from . import BrotatoTestBase
from ._data_sets import BrotatoTestDataSet


class TestBrotatoWorld(BrotatoTestBase):
    """Test attributes on the BrotatoWorld instance directly."""

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
