from ..Constants import CRATE_DROP_GROUP_REGION_TEMPLATE
from . import BrotatoTestBase


class TestBrotatoRegions(BrotatoTestBase):
    def _run(
        self,
        num_common_crate_drops: int,
        num_common_crate_drop_groups: int,
        num_legendary_crate_drops: int,
        num_legendary_crate_drop_groups: int,
    ):
        self.options = {
            "starting_characters": 1,  # Just use the default five
            "num_common_crate_drops": num_common_crate_drops,
            "num_common_crate_drop_groups": num_common_crate_drop_groups,
            "num_legendary_crate_drops": num_legendary_crate_drops,
            "num_legendary_crate_drop_groups": num_legendary_crate_drop_groups,
        }
        self.world_setup()

    def test_groups_have_correct_number_crates(self):
        self._run(25, 5, 25, 5)
        assert self.can_reach_region(CRATE_DROP_GROUP_REGION_TEMPLATE.format(num=1))
