from collections import Counter

from BaseClasses import Item

from ..items import ItemName
from . import BrotatoTestBase
from .data_sets.shop_slots import SHOP_SLOT_TEST_DATA_SETS
from .data_sets.weapon_slots import WEAPON_SLOT_TEST_DATA_SETS


class TestBrotatoItems(BrotatoTestBase):
    def test_create_items_shop_slot_items(self):
        for test_case in SHOP_SLOT_TEST_DATA_SETS:
            with self.data_set_subtest(test_case):
                item_counts: Counter[Item] = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_SLOT)], test_case.expected_num_shop_slot_items
                )

    def test_create_items_num_starting_lock_buttons(self):
        for test_case in SHOP_SLOT_TEST_DATA_SETS:
            with self.data_set_subtest(test_case):
                item_counts: Counter[Item] = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)],
                    test_case.expected_num_lock_button_items,
                )

    def test_create_items_weapon_slots(self):
        for test_case in WEAPON_SLOT_TEST_DATA_SETS:
            with self.data_set_subtest(test_case):
                item_counts: Counter[Item] = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.WEAPON_SLOT)], test_case.expected_num_weapon_slot_items
                )
