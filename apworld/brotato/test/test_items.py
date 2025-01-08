from collections import Counter

from ..constants import MAX_SHOP_SLOTS
from ..items import ItemName
from ..options import ItemWeights, StartingShopLockButtonsMode
from . import BrotatoTestBase


class TestBrotatoItems(BrotatoTestBase):
    auto_construct = False

    def test_create_items_custom_item_weights(self):
        """Check that custom item weights are respected by setting weights for all but one item tier to 0 and confirming
        only items of that tier are made.

        It would be nice to test more option combinations, but there doesn't seem to be a good way to do so without
        patching self.world.random, which makes the test tautological.
        """
        item_rarity_prefix_to_name = {
            "common": ItemName.COMMON_ITEM,
            "uncommon": ItemName.UNCOMMON_ITEM,
            "rare": ItemName.RARE_ITEM,
            "legendary": ItemName.LEGENDARY_ITEM,
        }

        for test_item_rarity, expected_populated_item in item_rarity_prefix_to_name.items():
            with self.subTest(msg=test_item_rarity):
                options = {
                    "item_weight_mode": ItemWeights.option_custom,
                    "num_common_crate_drops": 50,
                    "num_legendary_crate_drops": 0,
                    # Set the number of waves per drop to the max to ensure generate_early doesn't try to reduce the
                    # number of crates.
                    "waves_per_drop": 1,
                }
                for rarity_prefix in item_rarity_prefix_to_name:
                    item_weight_option = f"{rarity_prefix}_item_weight"
                    item_weight = 100 if rarity_prefix == test_item_rarity else 0
                    options[item_weight_option] = item_weight

                self._run(options)

                item_counts = Counter(self.multiworld.itempool)

                for item_name in item_rarity_prefix_to_name.values():
                    if item_name == expected_populated_item:
                        expected_amount = options["num_common_crate_drops"]
                    else:
                        expected_amount = 0

                    world_item_count = item_counts[self.world.create_item(item_name)]
                    self.assertEqual(world_item_count, expected_amount)

    def test_create_items_custom_weight_all_legendary_items(self):
        self._run(
            {
                "waves_per_drop": 5,  # Increase to have enough locations for all the crates
                "item_weight_mode": 2,
                "num_common_crate_drops": 50,
                "num_legendary_crate_drops": 20,
                "common_item_weight": 0,
                "uncommon_item_weight": 0,
                "rare_item_weight": 0,
                "legendary_item_weight": 100,
            }
        )

        item_counts = Counter(self.multiworld.itempool)
        # All crate drop checks (50 common + 20 legendary) should be legendary items
        self.assertEqual(item_counts[self.world.create_item(ItemName.LEGENDARY_ITEM)], 70)

    def test_create_items_custom_weight_legendary_items_weight_zero(self):
        self._run(
            {
                "waves_per_drop": 5,  # Increase to have enough locations for all the crates
                "item_weight_mode": 2,
                "num_common_crate_drops": 50,
                "num_legendary_crate_drops": 20,
                "common_item_weight": 1,
                "uncommon_item_weight": 1,
                "rare_item_weight": 1,
                "legendary_item_weight": 0,
            }
        )

        item_counts = Counter(self.multiworld.itempool)
        # All 20 legendary crate drop checks should be legendary items and nothing more. There's no way to tell how many
        # of each other item there will be.
        self.assertEqual(item_counts[self.world.create_item(ItemName.LEGENDARY_ITEM)], 20)

    def test_create_items_shop_slot_items(self):
        for num_starting_shop_slots in range(MAX_SHOP_SLOTS):
            with self.subTest(num_starting_shop_slots=num_starting_shop_slots):
                expected_num_slot_items = MAX_SHOP_SLOTS - num_starting_shop_slots

                self._run({"num_starting_shop_slots": num_starting_shop_slots})
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(item_counts[self.world.create_item(ItemName.SHOP_SLOT)], expected_num_slot_items)

    def test_create_items_num_starting_lock_buttons(self):
        for num_starting_lock_buttons in range(MAX_SHOP_SLOTS):
            with self.subTest(num_starting_lock_buttons=num_starting_lock_buttons):
                expected_num_lock_button_items = MAX_SHOP_SLOTS - num_starting_lock_buttons

                self._run(
                    {
                        "shop_lock_buttons_mode": StartingShopLockButtonsMode.option_custom,
                        "num_starting_lock_buttons": num_starting_lock_buttons,
                    }
                )
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)], expected_num_lock_button_items
                )

    def test_create_items_shop_lock_buttons_mode_match_num_shop_slots_value(self):
        for num_starting_shop_slots in range(MAX_SHOP_SLOTS):
            with self.subTest(num_starting_shop_slots=num_starting_shop_slots):
                expected_num_lock_button_items = MAX_SHOP_SLOTS - num_starting_shop_slots

                self._run(
                    {
                        "shop_lock_buttons_mode": StartingShopLockButtonsMode.option_match_shop_slots,
                        "num_starting_shop_slots": num_starting_shop_slots,
                    }
                )
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)], expected_num_lock_button_items
                )

    def test_create_items_shop_lock_buttons_mode_no_starting_buttons(self):
        for num_starting_shop_slots in range(MAX_SHOP_SLOTS):
            with self.subTest(num_starting_shop_slots=num_starting_shop_slots):
                expected_num_lock_button_items = MAX_SHOP_SLOTS

                self._run(
                    {
                        "shop_lock_buttons_mode": StartingShopLockButtonsMode.option_none,
                        "num_starting_shop_slots": num_starting_shop_slots,
                    }
                )
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)], expected_num_lock_button_items
                )

    def test_create_items_shop_lock_buttons_mode_all_starting_buttons(self):
        for num_starting_shop_slots in range(MAX_SHOP_SLOTS):
            with self.subTest(num_starting_shop_slots=num_starting_shop_slots):
                expected_num_lock_button_items = 0

                self._run(
                    {
                        "shop_lock_buttons_mode": StartingShopLockButtonsMode.option_all,
                        "num_starting_shop_slots": num_starting_shop_slots,
                    }
                )
                item_counts = Counter(self.multiworld.itempool)
                self.assertEqual(
                    item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)], expected_num_lock_button_items
                )
