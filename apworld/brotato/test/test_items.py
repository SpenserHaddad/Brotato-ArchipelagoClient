from collections import Counter

from ..items import ItemName
from . import BrotatoTestBase
from .data_sets.shop_slots import SHOP_SLOT_TEST_DATA_SETS


class TestBrotatoItems(BrotatoTestBase):
    def test_create_items_progressive_wave_cap_increase_items(self):
        num_wave_caps = 4
        expected_num_items = num_wave_caps - 1
        with self._run({"num_wave_caps": num_wave_caps}):
            wave_cap_increase_items = [
                item for item in self.multiworld.itempool if item.name == ItemName.PROGRESSIVE_WAVE_CAP.value
            ]
            self.assertEqual(len(wave_cap_increase_items), expected_num_items)

    def test_create_items_shop_slot_items(self):
        for test_case in SHOP_SLOT_TEST_DATA_SETS:
            with self.data_set_subtest(test_case):
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_SLOT)], test_case.expected_num_shop_slot_items
                )

    def test_create_items_num_starting_lock_buttons(self):
        for test_case in SHOP_SLOT_TEST_DATA_SETS:
            with self.data_set_subtest(test_case):
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)],
                    test_case.expected_num_lock_button_items,
                )
