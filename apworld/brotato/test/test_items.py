from collections import Counter

from ..items import ItemName
from . import BrotatoTestBase
from .data_sets.shop_slots import SHOP_SLOT_TEST_DATA_SETS


class TestBrotatoItems(BrotatoTestBase):
    auto_construct = False

    def test_create_items_shop_slot_items(self):
        for test_case in SHOP_SLOT_TEST_DATA_SETS:
            with self.subTest(num_starting_shop_slots=test_case.num_starting_shop_slots):
                self._run({"num_starting_shop_slots": test_case.num_starting_shop_slots})
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
