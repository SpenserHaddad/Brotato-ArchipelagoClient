from collections import Counter

from ..items import ItemName
from ..options import ItemWeights
from . import BrotatoTestBase
from .data_sets.shop_slots import SHOP_SLOT_TEST_DATA_SETS


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

        for (
            test_item_rarity,
            expected_populated_item,
        ) in item_rarity_prefix_to_name.items():
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
                "waves_per_drop": 4,  # Increase to have enough locations for all the crates
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
                "waves_per_drop": 4,  # Increase to have enough locations for all the crates
                "item_weight_mode": ItemWeights.option_custom,
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
        for test_case in self.data_set_subtests(SHOP_SLOT_TEST_DATA_SETS):
            self._run({"num_starting_shop_slots": test_case.num_starting_shop_slots})
            item_counts = Counter(self.multiworld.itempool)
            self.assertEqual(
                item_counts[self.world.create_item(ItemName.SHOP_SLOT)],
                test_case.expected_num_shop_slot_items,
            )

    def test_create_items_num_starting_lock_buttons(self):
        for test_case in self.data_set_subtests(SHOP_SLOT_TEST_DATA_SETS):
            item_counts = Counter(self.multiworld.itempool)
            self.assertEqual(
                item_counts[self.world.create_item(ItemName.SHOP_LOCK_BUTTON)],
                test_case.expected_num_lock_button_items,
            )
